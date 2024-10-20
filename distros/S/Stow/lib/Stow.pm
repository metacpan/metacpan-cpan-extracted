#!/usr/bin/perl
#
# This file is part of GNU Stow.
#
# GNU Stow is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GNU Stow is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/.

package Stow;

=head1 NAME

Stow - manage farms of symbolic links

=head1 SYNOPSIS

    my $stow = new Stow(%$options);

    $stow->plan_unstow(@pkgs_to_unstow);
    $stow->plan_stow  (@pkgs_to_stow);

    my %conflicts = $stow->get_conflicts;
    $stow->process_tasks() unless %conflicts;

=head1 DESCRIPTION

This is the backend Perl module for GNU Stow, a program for managing
the installation of software packages, keeping them separate
(C</usr/local/stow/emacs> vs. C</usr/local/stow/perl>, for example)
while making them appear to be installed in the same place
(C</usr/local>).

Stow doesn't store an extra state between runs, so there's no danger
of mangling directories when file hierarchies don't match the
database. Also, stow will never delete any files, directories, or
links that appear in a stow directory, so it is always possible to
rebuild the target tree.

=cut

use strict;
use warnings;

use Carp qw(carp cluck croak confess longmess);
use File::Copy qw(move);
use File::Spec;
use POSIX qw(getcwd);

use Stow::Util qw(set_debug_level debug error set_test_mode
                  join_paths restore_cwd canon_path parent
                  adjust_dotfile unadjust_dotfile);

our $ProgramName = 'stow';
our $VERSION = '2.4.1';

our $LOCAL_IGNORE_FILE  = '.stow-local-ignore';
our $GLOBAL_IGNORE_FILE = '.stow-global-ignore';

our @default_global_ignore_regexps =
    __PACKAGE__->get_default_global_ignore_regexps();

# These are the default options for each Stow instance.
our %DEFAULT_OPTIONS = (
    conflicts    => 0,
    simulate     => 0,
    verbose      => 0,
    paranoid     => 0,
    compat       => 0,
    test_mode    => 0,
    dotfiles     => 0,
    adopt        => 0,
    'no-folding' => 0,
    ignore       => [],
    override     => [],
    defer        => [],
);

=head1 CONSTRUCTORS

=head2 new(%options)

=head3 Required options

=over 4

=item * dir - the stow directory

=item * target - the target directory

=back

=head3 Non-mandatory options

See the documentation for the F<stow> CLI front-end for information on these.

=over 4

=item * conflicts

=item * simulate

=item * verbose

=item * paranoid

=item * compat

=item * test_mode

=item * adopt

=item * no-folding

=item * ignore

=item * override

=item * defer

=back

N.B. This sets the current working directory to the target directory.

=cut

sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    my %opts = @_;

    my $new = bless { }, $class;

    $new->{action_count} = 0;

    for my $required_arg (qw(dir target)) {
        croak "$class->new() called without '$required_arg' parameter\n"
            unless exists $opts{$required_arg};
        $new->{$required_arg} = delete $opts{$required_arg};
    }

    for my $opt (keys %DEFAULT_OPTIONS) {
        $new->{$opt} = exists $opts{$opt} ? delete $opts{$opt}
                                          : $DEFAULT_OPTIONS{$opt};
    }

    if (%opts) {
        croak "$class->new() called with unrecognised parameter(s): ",
            join(", ", keys %opts), "\n";
    }

    set_debug_level($new->get_verbosity());
    set_test_mode($new->{test_mode});
    $new->set_stow_dir();
    $new->init_state();

    return $new;
}

sub get_verbosity {
    my $self = shift;

    return $self->{verbose} unless $self->{test_mode};

    return 0 unless exists $ENV{TEST_VERBOSE};
    return 0 unless length $ENV{TEST_VERBOSE};

    # Convert TEST_VERBOSE=y into numeric value
    $ENV{TEST_VERBOSE} = 3 if $ENV{TEST_VERBOSE} !~ /^\d+$/;

    return $ENV{TEST_VERBOSE};
}

=head2 set_stow_dir([$dir])

Sets a new stow directory.  This allows the use of multiple stow
directories within one Stow instance, e.g.

    $stow->plan_stow('foo');
    $stow->set_stow_dir('/different/stow/dir');
    $stow->plan_stow('bar');
    $stow->process_tasks;

If C<$dir> is omitted, uses the value of the C<dir> parameter passed
to the L<new()> constructor.

=cut

sub set_stow_dir {
    my $self = shift;
    my ($dir) = @_;
    if (defined $dir) {
        $self->{dir} = $dir;
    }

    my $stow_dir = canon_path($self->{dir});
    my $target = canon_path($self->{target});

    # Calculate relative path from target directory to stow directory.
    # This will be commonly used as a prefix for constructing and
    # recognising symlinks "installed" in the target directory which
    # point to package files under the stow directory.
    $self->{stow_path} = File::Spec->abs2rel($stow_dir, $target);

    debug(2, 0, "stow dir is $stow_dir");
    debug(2, 0, "stow dir path relative to target $target is $self->{stow_path}");
}

sub init_state {
    my $self = shift;

    # Store conflicts during pre-processing
    $self->{conflicts}      = {};
    $self->{conflict_count} = 0;

    # Store command line packages to stow (-S and -R)
    $self->{pkgs_to_stow}   = [];

    # Store command line packages to unstow (-D and -R)
    $self->{pkgs_to_delete} = [];

    # The following structures are used by the abstractions that allow us to
    # defer operating on the filesystem until after all potential conflicts have
    # been assessed.

    # $self->{tasks}:  list of operations to be performed (in order)
    # each element is a hash ref of the form
    #   {
    #       action => ...  ('create' or 'remove' or 'move')
    #       type   => ...  ('link' or 'dir' or 'file')
    #       path   => ...  (unique)
    #       source => ...  (only for links)
    #       dest   => ...  (only for moving files)
    #   }
    $self->{tasks} = [];

    # $self->{dir_task_for}: map a path to the corresponding directory task reference
    # This structure allows us to quickly determine if a path has an existing
    # directory task associated with it.
    $self->{dir_task_for} = {};

    # $self->{link_task_for}: map a path to the corresponding directory task reference
    # This structure allows us to quickly determine if a path has an existing
    # directory task associated with it.
    $self->{link_task_for} = {};

    # N.B.: directory tasks and link tasks are NOT mutually exclusive due
    # to tree splitting (which involves a remove link task followed by
    # a create directory task).
}

=head1 METHODS

=head2 plan_unstow(@packages)

Plan which symlink/directory creation/removal tasks need to be executed
in order to unstow the given packages.  Any potential conflicts are then
accessible via L<get_conflicts()>.

=cut

sub plan_unstow {
    my $self = shift;
    my @packages = @_;

    return unless @packages;

    debug(2, 0, "Planning unstow of: @packages ...");

    $self->within_target_do(sub {
        for my $package (@packages) {
            my $pkg_path = join_paths($self->{stow_path}, $package);
            if (not -d $pkg_path) {
                error("The stow directory $self->{stow_path} does not contain package $package");
            }
            debug(2, 0, "Planning unstow of package $package...");
            $self->unstow_contents(
                $package,
                '.',
                '.',
            );
            debug(2, 0, "Planning unstow of package $package... done");
            $self->{action_count}++;
        }
    });
}

=head2 plan_stow(@packages)

Plan which symlink/directory creation/removal tasks need to be executed
in order to stow the given packages.  Any potential conflicts are then
accessible via L<get_conflicts()>.

=cut

sub plan_stow {
    my $self = shift;
    my @packages = @_;

    return unless @packages;

    debug(2, 0, "Planning stow of: @packages ...");

    $self->within_target_do(sub {
        for my $package (@packages) {
            my $pkg_path = join_paths($self->{stow_path}, $package);
            if (not -d $pkg_path) {
                error("The stow directory $self->{stow_path} does not contain package $package");
            }
            debug(2, 0, "Planning stow of package $package...");
            $self->stow_contents(
                $self->{stow_path},
                $package,
                '.',
                '.',
            );
            debug(2, 0, "Planning stow of package $package... done");
            $self->{action_count}++;
        }
    });
}

=head2 within_target_do($code)

Execute code within target directory, preserving cwd.

=over 4

=item $code

Anonymous subroutine to execute within target dir.

=back

This is done to ensure that the consumer of the Stow interface doesn't
have to worry about (a) what their cwd is, and (b) that their cwd
might change.

=cut

sub within_target_do {
    my $self = shift;
    my ($code) = @_;

    my $cwd = getcwd();
    chdir($self->{target})
        or error("Cannot chdir to target tree: $self->{target} ($!)");
    debug(3, 0, "cwd now $self->{target}");

    $self->$code();

    restore_cwd($cwd);
    debug(3, 0, "cwd restored to $cwd");
}

=head2 stow_contents($stow_path, $package, $pkg_subdir, $target_subdir)

Stow the contents of the given directory.

=over 4

=item $stow_path

Relative path from current (i.e. target) directory to the stow dir
containing the package to be stowed.  This can differ from
C<$self->{stow_path}> when unfolding a (sub)tree which is already
stowed from a package in a different stow directory (see the "Multiple
Stow Directories" section of the manual).

=item $package

The package whose contents are being stowed.

=item $pkg_subdir

Subdirectory of the installation image in the package directory which
needs stowing as a symlink which points to it.  This is relative to
the top-level package directory.

=item $target_subdir

Subdirectory of the target directory which either needs a symlink to the
corresponding package subdirectory in the installation image, or if
it's an existing directory, it's an unfolded tree which may need to
be folded or recursed into.

=back

C<stow_node()> and C<stow_contents()> are mutually recursive.

=cut

sub stow_contents {
    my $self = shift;
    my ($stow_path, $package, $pkg_subdir, $target_subdir) = @_;

    return if $self->should_skip_target($pkg_subdir);

    my $cwd = getcwd();
    my $msg = "Stowing contents of $stow_path / $package / $pkg_subdir (cwd=$cwd)";
    $msg =~ s!$ENV{HOME}(/|$)!~$1!g;
    debug(3, 0, $msg);
    debug(4, 1, "target subdir is $target_subdir");

    # Calculate the path to the package directory or sub-directory
    # whose contents need to be stowed, relative to the current
    # (target directory).  This is needed so that we can check it's a
    # valid directory, and can read its contents to iterate over them.
    my $pkg_path_from_cwd = join_paths($stow_path, $package, $pkg_subdir);

    error("stow_contents() called with non-directory target: $target_subdir")
        unless $self->is_a_node($target_subdir);

    opendir my $DIR, $pkg_path_from_cwd
        or error("cannot read directory: $pkg_path_from_cwd ($!)");
    my @listing = readdir $DIR;
    closedir $DIR;

    NODE:
    for my $node (sort @listing) {
        next NODE if $node eq '.';
        next NODE if $node eq '..';

        my $package_node_path = join_paths($pkg_subdir, $node);
        my $target_node = $node;
        my $target_node_path = join_paths($target_subdir, $target_node);
        next NODE if $self->ignore($stow_path, $package, $target_node_path);

        if ($self->{dotfiles}) {
            my $adjusted = adjust_dotfile($node);
            if ($adjusted ne $node) {
                debug(4, 1, "Adjusting: $node => $adjusted");
                $target_node = $adjusted;
                $target_node_path = join_paths($target_subdir, $target_node);
            }
        }

        $self->stow_node(
            $stow_path,
            $package,
            $package_node_path,
            $target_node_path
        );
    }
}

=head2 stow_node($stow_path, $package, $pkg_subpath, $target_subpath)

Stow the given node

=over 4

=item $stow_path

Relative path from current (i.e. target) directory to the stow dir
containing the node to be stowed.  This can differ from
C<$self->{stow_path}> when unfolding a (sub)tree which is already
stowed from a package in a different stow directory (see the "Multiple
Stow Directories" section of the manual).

=item $package

The package containing the node being stowed.

=item $pkg_subpath

Subpath of the installation image in the package directory which needs
stowing as a symlink which points to it.  This is relative to the
top-level package directory.

=item $target_subpath

Subpath of the target directory which either needs a symlink to the
corresponding package subpathectory in the installation image, or if
it's an existing directory, it's an unfolded tree which may need to
be folded or recursed into.

=back

C<stow_node()> and C<stow_contents()> are mutually recursive.

=cut

sub stow_node {
    my $self = shift;
    my ($stow_path, $package, $pkg_subpath, $target_subpath) = @_;

    debug(3, 0, "Stowing entry $stow_path / $package / $pkg_subpath");
    # Calculate the path to the package directory or sub-directory
    # whose contents need to be stowed, relative to the current
    # (target directory).  This is needed so that we can check it's a
    # valid directory, and can read its contents to iterate over them.
    my $pkg_path_from_cwd = join_paths($stow_path, $package, $pkg_subpath);

    # Don't try to stow absolute symlinks (they can't be unstowed)
    if (-l $pkg_path_from_cwd) {
        my $link_dest = $self->read_a_link($pkg_path_from_cwd);
        if ($link_dest =~ m{\A/}) {
            $self->conflict(
                'stow',
                $package,
                "source is an absolute symlink $pkg_path_from_cwd => $link_dest"
            );
            debug(3, 0, "Absolute symlinks cannot be unstowed");
            return;
        }
    }

    # How many directories deep are we?
    my $level = ($pkg_subpath =~ tr,/,,);
    debug(2, 1, "level of $pkg_subpath is $level");

    # Calculate the destination of the symlink which would need to be
    # installed within this directory in the absence of folding.  This
    # is relative to the target (sub-)directory where the symlink will
    # be installed when the plans are executed, so as we descend down
    # into the package hierarchy, it will have extra "../" segments
    # prefixed to it.
    my $link_dest = join_paths('../' x $level, $pkg_path_from_cwd);
    debug(4, 1, "link destination $link_dest");

    # Does the target already exist?
    if ($self->is_a_link($target_subpath)) {
        # Where is the link pointing?
        my $existing_link_dest = $self->read_a_link($target_subpath);
        if (not $existing_link_dest) {
            error("Could not read link: $target_subpath");
        }
        debug(4, 1, "Evaluate existing link: $target_subpath => $existing_link_dest");

        # Does it point to a node under any stow directory?
        my ($existing_pkg_path_from_cwd, $existing_stow_path, $existing_package) =
            $self->find_stowed_path($target_subpath, $existing_link_dest);
        if (not $existing_pkg_path_from_cwd) {
            $self->conflict(
                'stow',
                $package,
                "existing target is not owned by stow: $target_subpath"
            );
            return;
        }

        # Does the existing $target_subpath actually point to anything?
        if ($self->is_a_node($existing_pkg_path_from_cwd)) {
            if ($existing_link_dest eq $link_dest) {
                debug(2, 0, "--- Skipping $target_subpath as it already points to $link_dest");
            }
            elsif ($self->defer($target_subpath)) {
                debug(2, 0, "--- Deferring installation of: $target_subpath");
            }
            elsif ($self->override($target_subpath)) {
                debug(2, 0, "--- Overriding installation of: $target_subpath");
                $self->do_unlink($target_subpath);
                $self->do_link($link_dest, $target_subpath);
            }
            elsif ($self->is_a_dir(join_paths(parent($target_subpath), $existing_link_dest)) &&
                   $self->is_a_dir(join_paths(parent($target_subpath), $link_dest)))
            {

                # If the existing link points to a directory,
                # and the proposed new link points to a directory,
                # then we can unfold (split open) the tree at that point

                debug(2, 0, "--- Unfolding $target_subpath which was already owned by $existing_package");
                $self->do_unlink($target_subpath);
                $self->do_mkdir($target_subpath);
                $self->stow_contents(
                    $existing_stow_path,
                    $existing_package,
                    $pkg_subpath,
                    $target_subpath,
                );
                $self->stow_contents(
                    $self->{stow_path},
                    $package,
                    $pkg_subpath,
                    $target_subpath,
                );
            }
            else {
                $self->conflict(
                    'stow',
                    $package,
                    "existing target is stowed to a different package: "
                    . "$target_subpath => $existing_link_dest"
                );
            }
        }
        else {
            # The existing link is invalid, so replace it with a good link
            debug(2, 0, "--- replacing invalid link: $target_subpath");
            $self->do_unlink($target_subpath);
            $self->do_link($link_dest, $target_subpath);
        }
    }
    elsif ($self->is_a_node($target_subpath)) {
        debug(4, 1, "Evaluate existing node: $target_subpath");
        if ($self->is_a_dir($target_subpath)) {
            if (! -d $pkg_path_from_cwd) {
                # FIXME: why wasn't this ever needed before?
                $self->conflict(
                    'stow',
                    $package,
                    "cannot stow non-directory $pkg_path_from_cwd over existing directory target $target_subpath"
                );
            }
            else {
                $self->stow_contents(
                    $self->{stow_path},
                    $package,
                    $pkg_subpath,
                    $target_subpath,
                );
            }
        }
        else {
            # If we're here, $target_subpath is not a current or
            # planned directory.

            if ($self->{adopt}) {
                if (-d $pkg_path_from_cwd) {
                    $self->conflict(
                        'stow',
                        $package,
                        "cannot stow directory $pkg_path_from_cwd over existing non-directory target $target_subpath"
                    );
                }
                else {
                    $self->do_mv($target_subpath, $pkg_path_from_cwd);
                    $self->do_link($link_dest, $target_subpath);
                }
            }
            else {
                $self->conflict(
                    'stow',
                    $package,
                    "cannot stow $pkg_path_from_cwd over existing target $target_subpath since neither a link nor a directory and --adopt not specified"
                );
            }
        }
    }
    elsif ($self->{'no-folding'} && -d $pkg_path_from_cwd && ! -l $pkg_path_from_cwd) {
        $self->do_mkdir($target_subpath);
        $self->stow_contents(
            $self->{stow_path},
            $package,
            $pkg_subpath,
            $target_subpath,
        );
    }
    else {
        $self->do_link($link_dest, $target_subpath);
    }
    return;
}

=head2 should_skip_target($target_subdir)

Determine whether C<$target_subdir> is a stow directory which should
not be stowed to or unstowed from.  This mechanism protects stow
directories from being altered by stow, and is a necessary safety
check because the stow directory could live beneath the target
directory.

=over 4

=item $target_subdir => relative path to symlink target from the current directory

=back

Returns true iff target is a stow directory

cwd must be the top-level target directory, otherwise
C<marked_stow_dir()> won't work.

=cut

sub should_skip_target {
    my $self = shift;
    my ($target) = @_;

    # Don't try to remove anything under a stow directory
    if ($target eq $self->{stow_path}) {
        warn "WARNING: skipping target which was current stow directory $target\n";
        return 1;
    }

    if ($self->marked_stow_dir($target)) {
        warn "WARNING: skipping marked Stow directory $target\n";
        return 1;
    }

    if (-e join_paths($target, ".nonstow")) {
        warn "WARNING: skipping protected directory $target\n";
        return 1;
    }

    debug(4, 1, "$target not protected; shouldn't skip");
    return 0;
}

# cwd must be the top-level target directory, otherwise
# marked_stow_dir() won't work.
sub marked_stow_dir {
    my $self = shift;
    my ($dir) = @_;
    if (-e join_paths($dir, ".stow")) {
        debug(5, 5, "> $dir contained .stow");
        return 1;
    }
    return 0;
}

=head2 unstow_contents($package, $pkg_subdir, $target_subdir)

Unstow the contents of the given directory

=over 4

=item $package

The package whose contents are being unstowed.

=item $pkg_subdir

Subdirectory of the installation image in the package directory which
may need a symlink pointing to it to be unstowed.  This is relative to
the top-level package directory.

=item $target_subdir

Subdirectory of the target directory which either needs unstowing of a
symlink to the corresponding package subdirectory in the installation
image, or if it's an existing directory, it's an unfolded tree which
may need to be recursed into.

=back

C<unstow_node()> and C<unstow_contents()> are mutually recursive.
Here we traverse the package tree, rather than the target tree.

=cut

sub unstow_contents {
    my $self = shift;
    my ($package, $pkg_subdir, $target_subdir) = @_;

    return if $self->should_skip_target($target_subdir);

    my $cwd = getcwd();
    my $msg = "Unstowing contents of $self->{stow_path} / $package / $pkg_subdir (cwd=$cwd" . ($self->{compat} ? ', compat' : '') . ")";
    $msg =~ s!$ENV{HOME}/!~/!g;
    debug(3, 0, $msg);
    debug(4, 1, "target subdir is $target_subdir");

    # Calculate the path to the package directory or sub-directory
    # whose contents need to be unstowed, relative to the current
    # (target directory).  This is needed so that we can check it's a
    # valid directory, and can read its contents to iterate over them.
    my $pkg_path_from_cwd = join_paths($self->{stow_path}, $package, $pkg_subdir);

    if ($self->{compat}) {
        # In compat mode we traverse the target tree not the source tree,
        # so we're unstowing the contents of /target/foo, there's no
        # guarantee that the corresponding /stow/mypkg/foo exists.
        error("unstow_contents() in compat mode called with non-directory target: $target_subdir")
            unless -d $target_subdir;
    }
    else {
        # We traverse the package installation image tree not the
        # target tree, so $pkg_path_from_cwd must exist.
        error("unstow_contents() called with non-directory path: $pkg_path_from_cwd")
            unless -d $pkg_path_from_cwd;

        # When called at the top level, $target_subdir should exist.  And
        # unstow_node() should only call this via mutual recursion if
        # $target_subdir exists.
        error("unstow_contents() called with invalid target: $target_subdir")
            unless $self->is_a_node($target_subdir);
    }

    my $dir = $self->{compat} ? $target_subdir : $pkg_path_from_cwd;
    opendir my $DIR, $dir
        or error("cannot read directory: $dir ($!)");
    my @listing = readdir $DIR;
    closedir $DIR;

    NODE:
    for my $node (sort @listing) {
        next NODE if $node eq '.';
        next NODE if $node eq '..';

        my $package_node = $node;
        my $target_node = $node;
        my $target_node_path = join_paths($target_subdir, $target_node);

        next NODE if $self->ignore($self->{stow_path}, $package, $target_node_path);

        if ($self->{dotfiles}) {
            if ($self->{compat}) {
                # $node is in the target tree, so we need to reverse
                # adjust any .* files in case they came from a dot-*
                # file.
                my $adjusted = unadjust_dotfile($node);
                if ($adjusted ne $node) {
                    debug(4, 1, "Reverse adjusting: $node => $adjusted");
                    $package_node = $adjusted;
                }
            }
            else {
                # $node is in the package tree, so adjust any dot-*
                # files for the target.
                my $adjusted = adjust_dotfile($node);
                if ($adjusted ne $node) {
                    debug(4, 1, "Adjusting: $node => $adjusted");
                    $target_node = $adjusted;
                    $target_node_path = join_paths($target_subdir, $target_node);
                }
            }
        }
        my $package_node_path = join_paths($pkg_subdir, $package_node);

        $self->unstow_node(
            $package,
            $package_node_path,
            $target_node_path
        );
    }

    if (! $self->{compat} && -d $target_subdir) {
        $self->cleanup_invalid_links($target_subdir);
    }
}

=head2 unstow_node($package, $pkg_subpath, $target_subpath)

Unstow the given node.

=over 4

=item $package

The package containing the node being unstowed.

=item $pkg_subpath

Subpath of the installation image in the package directory which needs
stowing as a symlink which points to it.  This is relative to the
top-level package directory.

=item $target_subpath

Subpath of the target directory which either needs a symlink to the
corresponding package subpathectory in the installation image, or if
it's an existing directory, it's an unfolded tree which may need to
be folded or recursed into.

=back

C<unstow_node()> and C<unstow_contents()> are mutually recursive.

=cut

sub unstow_node {
    my $self = shift;
    my ($package, $pkg_subpath, $target_subpath) = @_;

    debug(3, 0, "Unstowing entry from target: $target_subpath");
    debug(4, 1, "Package entry: $self->{stow_path} / $package / $pkg_subpath");
    # Calculate the path to the package directory or sub-directory
    # whose contents need to be unstowed, relative to the current
    # (target directory).
    # Does the target exist?
    if ($self->is_a_link($target_subpath)) {
        $self->unstow_link_node($package, $pkg_subpath, $target_subpath);
    }
    elsif (-d $target_subpath) {
        $self->unstow_contents($package, $pkg_subpath, $target_subpath);

        # This action may have made the parent directory foldable
        if (my $parent_in_pkg = $self->foldable($target_subpath)) {
            $self->fold_tree($target_subpath, $parent_in_pkg);
        }
    }
    elsif (-e $target_subpath) {
        debug(2, 1, "$target_subpath doesn't need to be unstowed");
    }
    else {
        debug(2, 1, "$target_subpath did not exist to be unstowed");
    }
}

sub unstow_link_node {
    my $self = shift;
    my ($package, $pkg_subpath, $target_subpath) = @_;
    debug(4, 2, "Evaluate existing link: $target_subpath");

    # Where is the link pointing?
    my $link_dest = $self->read_a_link($target_subpath);
    if (not $link_dest) {
        error("Could not read link: $target_subpath");
    }

    if ($link_dest =~ m{\A/}) {
        warn "Ignoring an absolute symlink: $target_subpath => $link_dest\n";
        return;
    }

    # Does it point to a node under any stow directory?
    my ($existing_pkg_path_from_cwd, $existing_stow_path, $existing_package) =
        $self->find_stowed_path($target_subpath, $link_dest);
    if (not $existing_pkg_path_from_cwd) {
        # The user is unstowing the package, so they don't want links to it.
        # Therefore we should allow them to have a link pointing elsewhere
        # which would conflict with the package if they were stowing it.
        debug(5, 3, "Ignoring unowned link $target_subpath => $link_dest");
        return;
    }

    my $pkg_path_from_cwd = join_paths($self->{stow_path}, $package, $pkg_subpath);

    # Does the existing $target_subpath actually point to anything?
    if (-e $existing_pkg_path_from_cwd) {
        if ($existing_pkg_path_from_cwd eq $pkg_path_from_cwd) {
            # It points to the package we're unstowing, so unstow the link.
            $self->do_unlink($target_subpath);
        }
        else {
            debug(5, 3, "Ignoring link $target_subpath => $link_dest");
        }
    }
    else {
        debug(2, 0, "--- removing invalid link into a stow directory: $pkg_path_from_cwd");
        $self->do_unlink($target_subpath);
    }
}

=head2 link_owned_by_package($target_subpath, $link_dest)

Determine whether the given link points to a member of a stowed
package.

=over 4

=item $target_subpath

Path to a symbolic link under current directory.

=item $link_dest

Where that link points to.

=back

Lossy wrapper around find_stowed_path().

Returns the package iff link is owned by stow, otherwise ''.

=cut

sub link_owned_by_package {
    my $self = shift;
    my ($target_subpath, $link_dest) = @_;

    my ($pkg_path_from_cwd, $stow_path, $package) =
        $self->find_stowed_path($target_subpath, $link_dest);
    return $package;
}

=head2 find_stowed_path($target_subpath, $link_dest)

Determine whether the given symlink within the target directory is a
stowed path pointing to a member of a package under the stow dir, and
if so, obtain a breakdown of information about this stowed path.

=over 4

=item $target_subpath

Path to a symbolic link somewhere under the target directory, relative
to the top-level target directory (which is also expected to be the
current directory).

=item $link_dest

Where that link points to (needed because link might not exist yet due
to two-phase approach, so we can't just call C<readlink()>).  If this
is owned by Stow, it will be expressed relative to (the directory
containing) C<$target_subpath>.  However if it's not, it could of course be
relative or absolute, point absolutely anywhere, and could even be
dangling.

=back

Returns C<($pkg_path_from_cwd, $stow_path, $package)> where
C<$pkg_path_from_cwd> and C<$stow_path> are relative from the
top-level target directory.  C<$pkg_path_from_cwd> is the full
relative path to the member of the package pointed to by
C<$link_dest>; C<$stow_path> is the relative path to the stow
directory; and C<$package> is the name of the package; or C<('', '',
'')> if link is not owned by stow.

cwd must be the top-level target directory, otherwise
C<find_containing_marked_stow_dir()> won't work.  Allow for stow dir
not being under target dir.

=cut

sub find_stowed_path {
    my $self = shift;
    my ($target_subpath, $link_dest) = @_;

    if (substr($link_dest, 0, 1) eq '/') {
        # Symlink points to an absolute path, therefore it cannot be
        # owned by Stow.
        return ('', '', '');
    }

    # Evaluate softlink relative to its target, without relying on
    # what's actually on the filesystem, since the link might not
    # exist yet.
    debug(4, 2, "find_stowed_path(target=$target_subpath; source=$link_dest)");
    my $pkg_path_from_cwd = join_paths(parent($target_subpath), $link_dest);
    debug(4, 3, "is symlink destination $pkg_path_from_cwd owned by stow?");

    # First check whether the link is owned by the current stow
    # directory, in which case $pkg_path_from_cwd will be a prefix of
    # $self->{stow_path}.
    my ($package, $pkg_subpath) = $self->link_dest_within_stow_dir($pkg_path_from_cwd);
    if (length $package) {
        debug(4, 3, "yes - package $package in $self->{stow_path} may contain $pkg_subpath");
        return ($pkg_path_from_cwd, $self->{stow_path}, $package);
    }

    # If no .stow file was found, we need to find out whether it's
    # owned by the current stow directory, in which case
    # $pkg_path_from_cwd will be a prefix of $self->{stow_path}.
    my ($stow_path, $ext_package) = $self->find_containing_marked_stow_dir($pkg_path_from_cwd);
    if (length $stow_path) {
        debug(5, 5, "yes - $stow_path in $pkg_path_from_cwd was marked as a stow dir; package=$ext_package");
        return ($pkg_path_from_cwd, $stow_path, $ext_package);
    }

    return ('', '', '');
}

=head2 link_dest_within_stow_dir($link_dest)

Detect whether symlink destination is within current stow dir

=over 4

=item $link_dest - destination of the symlink relative

=back

Returns C<($package, $pkg_subpath)> - package within the current stow
dir and subpath within that package which the symlink points to.

=cut

sub link_dest_within_stow_dir {
    my $self = shift;
    my ($link_dest) = @_;

    debug(4, 4, "common prefix? link_dest=$link_dest; stow_path=$self->{stow_path}");

    my $removed = $link_dest =~ s,^\Q$self->{stow_path}/,,;
    if (! $removed) {
        debug(4, 3, "no - $link_dest not under $self->{stow_path}");
        return ('', '');
    }

    debug(4, 4, "remaining after removing $self->{stow_path}: $link_dest");
    my @dirs = File::Spec->splitdir($link_dest);
    my $package = shift @dirs;
    my $pkg_subpath = File::Spec->catdir(@dirs);
    return ($package, $pkg_subpath);
}

=head2 find_containing_marked_stow_dir($pkg_path_from_cwd)

Detect whether path is within a marked stow directory

=over 4

=item $pkg_path_from_cwd => path to directory to check

=back

Returns C<($stow_path, $package)> where C<$stow_path> is the highest
directory (relative from the top-level target directory) which is
marked as a Stow directory, and C<$package> is the containing package;
or C<('', '')> if no containing directory is marked as a stow
directory.

cwd must be the top-level target directory, otherwise
C<marked_stow_dir()> won't work.

=cut

sub find_containing_marked_stow_dir {
    my $self = shift;
    my ($pkg_path_from_cwd) = @_;

    # Search for .stow files - this allows us to detect links
    # owned by stow directories other than the current one.
    my @segments = File::Spec->splitdir($pkg_path_from_cwd);
    for my $last_segment (0 .. $#segments) {
        my $pkg_path_from_cwd = join_paths(@segments[0 .. $last_segment]);
        debug(5, 5, "is $pkg_path_from_cwd marked stow dir?");
        if ($self->marked_stow_dir($pkg_path_from_cwd)) {
            if ($last_segment == $#segments) {
                # This should probably never happen.  Even if it did,
                # there would be no way of calculating $package.
                internal_error("find_stowed_path() called directly on stow dir");
            }

            my $package = $segments[$last_segment + 1];
            return ($pkg_path_from_cwd, $package);
        }
    }
    return ('', '');
}

=head2 cleanup_invalid_links($dir)

Clean up orphaned links that may block folding

=over 4

=item $dir

Path to directory to check

=back

This is invoked by C<unstow_contents()>.  We only clean up links which
are both orphaned and owned by Stow, i.e. they point to a non-existent
location within a Stow package.  These can block tree folding, and
they can easily occur when a file in Stow package is renamed or
removed, so the benefit should outweigh the low risk of actually
someone wanting to keep an orphaned link to within a Stow package.

=cut

sub cleanup_invalid_links {
    my $self = shift;
    my ($dir) = @_;

    my $cwd = getcwd();
    debug(2, 0, "Cleaning up any invalid links in $dir (pwd=$cwd)");

    if (not -d $dir) {
        internal_error("cleanup_invalid_links() called with a non-directory: $dir");
    }

    opendir my $DIR, $dir
        or error("cannot read directory: $dir ($!)");
    my @listing = readdir $DIR;
    closedir $DIR;

    NODE:
    for my $node (sort @listing) {
        next NODE if $node eq '.';
        next NODE if $node eq '..';

        my $node_path = join_paths($dir, $node);

        next unless -l $node_path;

        debug(4, 1, "Checking validity of link $node_path");

        if (exists $self->{link_task_for}{$node_path}) {
            my $action = $self->{link_task_for}{$node_path}{action};
            if ($action ne 'remove') {
                warn "Unexpected action $action scheduled for $node_path; skipping clean-up\n";
            }
            else {
                debug(4, 2, "$node_path scheduled for removal; skipping clean-up");
            }
            next;
        }

        # Where is the link pointing?
        # (don't use read_a_link() here)
        my $link_dest = readlink($node_path);
        if (not $link_dest) {
            error("Could not read link $node_path");
        }

        my $target_subpath = join_paths($dir, $link_dest);
        debug(4, 2, "join $dir $link_dest");
        if (-e $target_subpath) {
            debug(4, 2, "Link target $link_dest exists at $target_subpath; skipping clean up");
            next;
        }
        else {
            debug(4, 2, "Link target $link_dest doesn't exist at $target_subpath");
        }

        debug(3, 1,
              "Checking whether valid link $node_path -> $link_dest is " .
              "owned by stow");

        my $owner = $self->link_owned_by_package($node_path, $link_dest);
        if ($owner) {
            # owned by stow
            debug(2, 0, "--- removing link owned by $owner: $node_path => " .
                  join_paths($dir, $link_dest));
            $self->do_unlink($node_path);
        }
    }
    return;
}


=head2 foldable($target_subdir)

Determine whether a tree can be folded

=over 4

=item $target_subdir

Path to the target sub-directory to check for foldability, relative to
the current directory (the top-level target directory).

=back

Returns path to the parent dir iff the tree can be safely folded.  The
path returned is relative to the parent of C<$target_subdir>, i.e. it
can be used as the source for a replacement symlink.

=cut

sub foldable {
    my $self = shift;
    my ($target_subdir) = @_;

    debug(3, 2, "Is $target_subdir foldable?");
    if ($self->{'no-folding'}) {
        debug(3, 3, "Not foldable because --no-folding enabled");
        return '';
    }

    opendir my $DIR, $target_subdir
        or error(qq{Cannot read directory "$target_subdir" ($!)\n});
    my @listing = readdir $DIR;
    closedir $DIR;

    # We want to see if all the symlinks in $target_subdir point to
    # files under the same parent subdirectory in the package
    # (e.g. ../../stow/pkg1/common_dir/file1).  So remember which
    # parent subdirectory we've already seen, and if we come across a
    # second one which is different,
    # (e.g. ../../stow/pkg2/common_dir/file2), then $target_subdir
    # common_dir which contains file{1,2} cannot be folded to be
    # a symlink to (say) ../../stow/pkg1/common_dir.
    my $parent_in_pkg = '';

    NODE:
    for my $node (sort @listing) {
        next NODE if $node eq '.';
        next NODE if $node eq '..';

        my $target_node_path = join_paths($target_subdir, $node);

        # Skip nodes scheduled for removal
        next NODE if not $self->is_a_node($target_node_path);

        # If it's not a link then we can't fold its parent
        if (not $self->is_a_link($target_node_path)) {
            debug(3, 3, "Not foldable because $target_node_path not a link");
            return '';
        }

        # Where is the link pointing?
        my $link_dest = $self->read_a_link($target_node_path);
        if (not $link_dest) {
            error("Could not read link $target_node_path");
        }
        my $new_parent = parent($link_dest);
        if ($parent_in_pkg eq '') {
            $parent_in_pkg = $new_parent;
        }
        elsif ($parent_in_pkg ne $new_parent) {
            debug(3, 3, "Not foldable because $target_subdir contains links to entries in both $parent_in_pkg and $new_parent");
            return '';
        }
    }
    if (not $parent_in_pkg) {
        debug(3, 3, "Not foldable because $target_subdir contains no links");
        return '';
    }

    # If we get here then all nodes inside $target_subdir are links,
    # and those links point to nodes inside the same directory.

    # chop of leading '..' to get the path to the common parent directory
    # relative to the parent of our $target_subdir
    $parent_in_pkg =~ s{\A\.\./}{};

    # If the resulting path is owned by stow, we can fold it
    if ($self->link_owned_by_package($target_subdir, $parent_in_pkg)) {
        debug(3, 3, "$target_subdir is foldable");
        return $parent_in_pkg;
    }
    else {
        debug(3, 3, "$target_subdir is not foldable");
        return '';
    }
}

=head2 fold_tree($target_subdir, $pkg_subpath)

Fold the given tree

=over 4

=item $target_subdir

Directory that we will replace with a link to $pkg_subpath.

=item $pkg_subpath

link to the folded tree source

=back

Only called iff foldable() is true so we can remove some checks.

=cut

sub fold_tree {
    my $self = shift;
    my ($target_subdir, $pkg_subpath) = @_;

    debug(3, 0, "--- Folding tree: $target_subdir => $pkg_subpath");

    opendir my $DIR, $target_subdir
        or error(qq{Cannot read directory "$target_subdir" ($!)\n});
    my @listing = readdir $DIR;
    closedir $DIR;

    NODE:
    for my $node (sort @listing) {
        next NODE if $node eq '.';
        next NODE if $node eq '..';
        next NODE if not $self->is_a_node(join_paths($target_subdir, $node));
        $self->do_unlink(join_paths($target_subdir, $node));
    }
    $self->do_rmdir($target_subdir);
    $self->do_link($pkg_subpath, $target_subdir);
    return;
}


=head2 conflict($package, $message)

Handle conflicts in stow operations

=over 4

=item $package

the package involved with the conflicting operation

=item $message

a description of the conflict

=back

=cut

sub conflict {
    my $self = shift;
    my ($action, $package, $message) = @_;

    debug(2, 0, "CONFLICT when ${action}ing $package: $message");
    $self->{conflicts}{$action}{$package} ||= [];
    push @{ $self->{conflicts}{$action}{$package} }, $message;
    $self->{conflict_count}++;

    return;
}

=head2 get_conflicts()

Returns a nested hash of all potential conflicts discovered: the keys
are actions ('stow' or 'unstow'), and the values are hashrefs whose
keys are stow package names and whose values are conflict
descriptions, e.g.:

    (
        stow => {
            perl => [
                "existing target is not owned by stow: bin/a2p"
                "existing target is neither a link nor a directory: bin/perl"
            ]
        }
    )

=cut

sub get_conflicts {
    my $self = shift;
    return %{ $self->{conflicts} };
}

=head2 get_conflict_count()

Returns the number of conflicts found.

=cut

sub get_conflict_count {
    my $self = shift;
    return $self->{conflict_count};
}

=head2 get_tasks()

Returns a list of all symlink/directory creation/removal tasks.

=cut

sub get_tasks {
    my $self = shift;
    return @{ $self->{tasks} };
}

=head2 get_action_count()

Returns the number of actions planned for this Stow instance.

=cut

sub get_action_count {
    my $self = shift;
    return $self->{action_count};
}

=head2 ignore($stow_path, $package, $target)

Determine if the given path matches a regex in our ignore list.

=over 4

=item $stow_path

the stow directory containing the package

=item $package

the package containing the path

=item $target

the path to check against the ignore list relative to its package
directory

=back

Returns true iff the path should be ignored.

=cut

sub ignore {
    my $self = shift;
    my ($stow_path, $package, $target) = @_;

    internal_error(__PACKAGE__ . "::ignore() called with empty target")
        unless length $target;

    for my $suffix (@{ $self->{ignore} }) {
        if ($target =~ m/$suffix/) {
            debug(4, 1, "Ignoring path $target due to --ignore=$suffix");
            return 1;
        }
    }

    my $package_dir = join_paths($stow_path, $package);
    my ($path_regexp, $segment_regexp) =
        $self->get_ignore_regexps($package_dir);
    debug(5, 2, "Ignore list regexp for paths:    " .
             (defined $path_regexp ? "/$path_regexp/" : "none"));
    debug(5, 2, "Ignore list regexp for segments: " .
             (defined $segment_regexp ? "/$segment_regexp/" : "none"));

    if (defined $path_regexp and "/$target" =~ $path_regexp) {
        debug(4, 1, "Ignoring path /$target");
        return 1;
    }

    (my $basename = $target) =~ s!.+/!!;
    if (defined $segment_regexp and $basename =~ $segment_regexp) {
        debug(4, 1, "Ignoring path segment $basename");
        return 1;
    }

    debug(5, 1, "Not ignoring $target");
    return 0;
}

sub get_ignore_regexps {
    my $self = shift;
    my ($dir) = @_;

    # N.B. the local and global stow ignore files have to have different
    # names so that:
    #   1. the global one can be a symlink to within a stow
    #      package, managed by stow itself, and
    #   2. the local ones can be ignored via hardcoded logic in
    #      GlobsToRegexp(), so that they always stay within their stow packages.

    my $local_stow_ignore  = join_paths($dir,       $LOCAL_IGNORE_FILE);
    my $global_stow_ignore = join_paths($ENV{HOME}, $GLOBAL_IGNORE_FILE);

    for my $file ($local_stow_ignore, $global_stow_ignore) {
        if (-e $file) {
            debug(5, 1, "Using ignore file: $file");
            return $self->get_ignore_regexps_from_file($file);
        }
        else {
            debug(5, 1, "$file didn't exist");
        }
    }

    debug(4, 1, "Using built-in ignore list");
    return @default_global_ignore_regexps;
}

my %ignore_file_regexps;

sub get_ignore_regexps_from_file {
    my $self = shift;
    my ($file) = @_;

    if (exists $ignore_file_regexps{$file}) {
        debug(4, 2, "Using memoized regexps from $file");
        return @{ $ignore_file_regexps{$file} };
    }

    if (! open(REGEXPS, $file)) {
        debug(4, 2, "Failed to open $file: $!");
        return undef;
    }

    my @regexps = $self->get_ignore_regexps_from_fh(\*REGEXPS);
    close(REGEXPS);

    $ignore_file_regexps{$file} = [ @regexps ];
    return @regexps;
}

=head2 invalidate_memoized_regexp($file)

For efficiency of performance, regular expressions are compiled from
each ignore list file the first time it is used by the Stow process,
and then memoized for future use.  If you expect the contents of these
files to change during a single run, you will need to invalidate the
memoized value from this cache.  This method allows you to do that.

=cut

sub invalidate_memoized_regexp {
    my $self = shift;
    my ($file) = @_;
    if (exists $ignore_file_regexps{$file}) {
        debug(4, 2, "Invalidated memoized regexp for $file");
        delete $ignore_file_regexps{$file};
    }
    else {
        debug(2, 1, "WARNING: no memoized regexp for $file to invalidate");
    }
}

sub get_ignore_regexps_from_fh {
    my $self = shift;
    my ($fh) = @_;
    my %regexps;
    while (<$fh>) {
        chomp;
        s/^\s+//;
        s/\s+$//;
        next if /^#/ or length($_) == 0;
        s/\s+#.+//; # strip comments to right of pattern
        s/\\#/#/g;
        $regexps{$_}++;
    }

    # Local ignore lists should *always* stay within the stow directory,
    # because this is the only place stow looks for them.
    $regexps{"^/\Q$LOCAL_IGNORE_FILE\E\$"}++;

    return $self->compile_ignore_regexps(%regexps);
}

sub compile_ignore_regexps {
    my $self = shift;
    my (%regexps) = @_;

    my @segment_regexps;
    my @path_regexps;
    for my $regexp (keys %regexps) {
        if (index($regexp, '/') < 0) {
            # No / found in regexp, so use it for matching against basename
            push @segment_regexps, $regexp;
        }
        else {
            # / found in regexp, so use it for matching against full path
            push @path_regexps, $regexp;
        }
    }

    my $segment_regexp = join '|', @segment_regexps;
    my $path_regexp    = join '|', @path_regexps;
    $segment_regexp = @segment_regexps ?
        $self->compile_regexp("^($segment_regexp)\$") : undef;
    $path_regexp    = @path_regexps    ?
        $self->compile_regexp("(^|/)($path_regexp)(/|\$)") : undef;

    return ($path_regexp, $segment_regexp);
}

sub compile_regexp {
    my $self = shift;
    my ($regexp) = @_;
    my $compiled = eval { qr/$regexp/ };
    die "Failed to compile regexp: $@\n" if $@;
    return $compiled;
}

sub get_default_global_ignore_regexps {
    my $class = shift;
    # Bootstrap issue - first time we stow, we will be stowing
    # .cvsignore so it might not exist in ~ yet, or if it does, it could
    # be an old version missing the entries we need.  So we make sure
    # they are there by hardcoding some crucial entries.
    return $class->get_ignore_regexps_from_fh(\*DATA);
}

=head2 defer($path)

Determine if the given path matches a regex in our C<defer> list

=over 4

=item $path

=back

Returns boolean.

=cut

sub defer {
    my $self = shift;
    my ($path) = @_;

    for my $prefix (@{ $self->{defer} }) {
        return 1 if $path =~ m/$prefix/;
    }
    return 0;
}

=head2 override($path)

Determine if the given path matches a regex in our C<override> list

=over 4

=item $path

=back

Returns boolean

=cut

sub override {
    my $self = shift;
    my ($path) = @_;

    for my $regex (@{ $self->{override} }) {
        return 1 if $path =~ m/$regex/;
    }
    return 0;
}

##############################################################################
#
# The following code provides the abstractions that allow us to defer operating
# on the filesystem until after all potential conflcits have been assessed.
#
##############################################################################

=head2 process_tasks()

Process each task in the tasks list

=over 4

=item none

=back

Returns : n/a
Throws    : fatal error if tasks list is corrupted or a task fails

=cut

sub process_tasks {
    my $self = shift;

    debug(2, 0, "Processing tasks...");

    # Strip out all tasks with a skip action
    $self->{tasks} = [ grep { $_->{action} ne 'skip' } @{ $self->{tasks} } ];

    if (not @{ $self->{tasks} }) {
        return;
    }

    $self->within_target_do(sub {
        for my $task (@{ $self->{tasks} }) {
            $self->process_task($task);
        }
    });

    debug(2, 0, "Processing tasks... done");
}

=head2 process_task($task)

Process a single task.

=over 4

=item $task => the task to process

=back

Returns : n/a
Throws    : fatal error if task fails
# #
Must run from within target directory.  Task involve either creating
or deleting dirs and symlinks an action is set to 'skip' if it is
found to be redundant

=cut

sub process_task {
    my $self = shift;
    my ($task) = @_;

    if ($task->{action} eq 'create') {
        if ($task->{type} eq 'dir') {
            mkdir($task->{path}, 0777)
                or error("Could not create directory: $task->{path} ($!)");
            return;
        }
        elsif ($task->{type} eq 'link') {
            symlink $task->{source}, $task->{path}
                or error(
                    "Could not create symlink: %s => %s ($!)",
                    $task->{path},
                    $task->{source}
            );
            return;
        }
    }
    elsif ($task->{action} eq 'remove') {
        if ($task->{type} eq 'dir') {
            rmdir $task->{path}
                or error("Could not remove directory: $task->{path} ($!)");
            return;
        }
        elsif ($task->{type} eq 'link') {
            unlink $task->{path}
                or error("Could not remove link: $task->{path} ($!)");
            return;
        }
    }
    elsif ($task->{action} eq 'move') {
        if ($task->{type} eq 'file') {
            # rename() not good enough, since the stow directory
            # might be on a different filesystem to the target.
            move $task->{path}, $task->{dest}
                or error("Could not move $task->{path} -> $task->{dest} ($!)");
            return;
        }
    }

    # Should never happen.
    internal_error("bad task action: $task->{action}");
}

=head2 link_task_action($path)

Finds the link task action for the given path, if there is one

=over 4

=item $path

=back

Returns C<'remove'>, C<'create'>, or C<''> if there is no action.
Throws a fatal exception if an invalid action is found.

=cut

sub link_task_action {
    my $self = shift;
    my ($path) = @_;

    if (! exists $self->{link_task_for}{$path}) {
        debug(4, 4, "| link_task_action($path): no task");
        return '';
    }

    my $action = $self->{link_task_for}{$path}->{action};
    internal_error("bad task action: $action")
        unless $action eq 'remove' or $action eq 'create';

    debug(4, 1, "link_task_action($path): link task exists with action $action");
    return $action;
}

=head2 dir_task_action($path)

Finds the dir task action for the given path, if there is one.

=over 4

=item $path

=back

Returns C<'remove'>, C<'create'>, or C<''> if there is no action.
Throws a fatal exception if an invalid action is found.

=cut

sub dir_task_action {
    my $self = shift;
    my ($path) = @_;

    if (! exists $self->{dir_task_for}{$path}) {
        debug(4, 4, "| dir_task_action($path): no task");
        return '';
    }

    my $action = $self->{dir_task_for}{$path}->{action};
    internal_error("bad task action: $action")
        unless $action eq 'remove' or $action eq 'create';

    debug(4, 4, "| dir_task_action($path): dir task exists with action $action");
    return $action;
}

=head2 parent_link_scheduled_for_removal($target_path)

Determine whether the given path or any parent thereof is a link
scheduled for removal

=over 4

=item $target_path

=back

Returns boolean

=cut

sub parent_link_scheduled_for_removal {
    my $self = shift;
    my ($target_path) = @_;

    my $prefix = '';
    for my $part (split m{/+}, $target_path) {
        $prefix = join_paths($prefix, $part);
        debug(5, 4, "| parent_link_scheduled_for_removal($target_path): prefix $prefix");
        if (exists $self->{link_task_for}{$prefix} and
             $self->{link_task_for}{$prefix}->{action} eq 'remove') {
            debug(4, 4, "| parent_link_scheduled_for_removal($target_path): link scheduled for removal");
            return 1;
        }
    }

    debug(4, 4, "| parent_link_scheduled_for_removal($target_path): returning false");
    return 0;
}

=head2 is_a_link($target_path)

Determine if the given path is a current or planned link.

=over 4

=item $target_path

=back

Returns false if an existing link is scheduled for removal and true if
a non-existent link is scheduled for creation.

=cut

sub is_a_link {
    my $self = shift;
    my ($target_path) = @_;
    debug(4, 2, "is_a_link($target_path)");

    if (my $action = $self->link_task_action($target_path)) {
        if ($action eq 'remove') {
            debug(4, 2, "is_a_link($target_path): returning 0 (remove action found)");
            return 0;
        }
        elsif ($action eq 'create') {
            debug(4, 2, "is_a_link($target_path): returning 1 (create action found)");
            return 1;
        }
    }

    if (-l $target_path) {
        # Check if any of its parent are links scheduled for removal
        # (need this for edge case during unfolding)
        debug(4, 2, "is_a_link($target_path): is a real link");
        return $self->parent_link_scheduled_for_removal($target_path) ? 0 : 1;
    }

    debug(4, 2, "is_a_link($target_path): returning 0");
    return 0;
}

=head2 is_a_dir($target_path)

Determine if the given path is a current or planned directory

=over 4

=item $target_path

=back

Returns false if an existing directory is scheduled for removal and
true if a non-existent directory is scheduled for creation.  We also
need to be sure we are not just following a link.

=cut

sub is_a_dir {
    my $self = shift;
    my ($target_path) = @_;
    debug(4, 1, "is_a_dir($target_path)");

    if (my $action = $self->dir_task_action($target_path)) {
        if ($action eq 'remove') {
            return 0;
        }
        elsif ($action eq 'create') {
            return 1;
        }
    }

    return 0 if $self->parent_link_scheduled_for_removal($target_path);

    if (-d $target_path) {
        debug(4, 1, "is_a_dir($target_path): real dir");
        return 1;
    }

    debug(4, 1, "is_a_dir($target_path): returning false");
    return 0;
}

=head2 is_a_node($target_path)

Determine whether the given path is a current or planned node.

=over 4

=item $target_path

=back

Returns false if an existing node is scheduled for removal, or true if
a non-existent node is scheduled for creation.  We also need to be
sure we are not just following a link.

=cut

sub is_a_node {
    my $self = shift;
    my ($target_path) = @_;
    debug(4, 4, "| Checking whether $target_path is a current/planned node");

    my $laction = $self->link_task_action($target_path);
    my $daction = $self->dir_task_action($target_path);

    if ($laction eq 'remove') {
        if ($daction eq 'remove') {
            internal_error("removing link and dir: $target_path");
            return 0;
        }
        elsif ($daction eq 'create') {
            # Assume that we're unfolding $target_path, and that the link
            # removal action is earlier than the dir creation action
            # in the task queue.  FIXME: is this a safe assumption?
            return 1;
        }
        else { # no dir action
            return 0;
        }
    }
    elsif ($laction eq 'create') {
        if ($daction eq 'remove') {
            # Assume that we're folding $target_path, and that the dir
            # removal action is earlier than the link creation action
            # in the task queue.  FIXME: is this a safe assumption?
            return 1;
        }
        elsif ($daction eq 'create') {
            internal_error("creating link and dir: $target_path");
            return 1;
        }
        else { # no dir action
            return 1;
        }
    }
    else {
        # No link action
        if ($daction eq 'remove') {
            return 0;
        }
        elsif ($daction eq 'create') {
            return 1;
        }
        else { # no dir action
            # fall through to below
        }
    }

    return 0 if $self->parent_link_scheduled_for_removal($target_path);

    if (-e $target_path) {
        debug(4, 3, "| is_a_node($target_path): really exists");
        return 1;
    }

    debug(4, 3, "| is_a_node($target_path): returning false");
    return 0;
}

=head2 read_a_link($link)

Return the destination of a current or planned link.

=over 4

=item $link

Path to the link target.

=back

Returns the destination of the given link.  Throws a fatal exception
if the given path is not a current or planned link.

=cut

sub read_a_link {
    my $self = shift;
    my ($link) = @_;

    if (my $action = $self->link_task_action($link)) {
        debug(4, 2, "read_a_link($link): task exists with action $action");

        if ($action eq 'create') {
            return $self->{link_task_for}{$link}->{source};
        }
        elsif ($action eq 'remove') {
            internal_error(
                "read_a_link() passed a path that is scheduled for removal: $link"
            );
        }
    }
    elsif (-l $link) {
        debug(4, 2, "read_a_link($link): is a real link");
        my $link_dest = readlink $link or error("Could not read link: $link ($!)");
        return $link_dest;
    }
    internal_error("read_a_link() passed a non-link path: $link\n");
}

=head2 do_link($link_dest, $link_src)

Wrap 'link' operation for later processing

=over 4

=item $link_dest

the existing file to link to

=item $link_src

the file to link

=back

Throws an error if this clashes with an existing planned operation.
Cleans up operations that undo previous operations.

=cut

sub do_link {
    my $self = shift;
    my ($link_dest, $link_src) = @_;

    if (exists $self->{dir_task_for}{$link_src}) {
        my $task_ref = $self->{dir_task_for}{$link_src};

        if ($task_ref->{action} eq 'create') {
            if ($task_ref->{type} eq 'dir') {
                internal_error(
                    "new link (%s => %s) clashes with planned new directory",
                    $link_src,
                    $link_dest,
                );
            }
        }
        elsif ($task_ref->{action} eq 'remove') {
            # We may need to remove a directory before creating a link so continue.
        }
        else {
            internal_error("bad task action: $task_ref->{action}");
        }
    }

    if (exists $self->{link_task_for}{$link_src}) {
        my $task_ref = $self->{link_task_for}{$link_src};

        if ($task_ref->{action} eq 'create') {
            if ($task_ref->{source} ne $link_dest) {
                internal_error(
                    "new link clashes with planned new link: %s => %s",
                    $task_ref->{path},
                    $task_ref->{source},
                )
            }
            else {
                debug(1, 0, "LINK: $link_src => $link_dest (duplicates previous action)");
                return;
            }
        }
        elsif ($task_ref->{action} eq 'remove') {
            if ($task_ref->{source} eq $link_dest) {
                # No need to remove a link we are going to recreate
                debug(1, 0, "LINK: $link_src => $link_dest (reverts previous action)");
                $self->{link_task_for}{$link_src}->{action} = 'skip';
                delete $self->{link_task_for}{$link_src};
                return;
            }
            # We may need to remove a link to replace it so continue
        }
        else {
            internal_error("bad task action: $task_ref->{action}");
        }
    }

    # Creating a new link
    debug(1, 0, "LINK: $link_src => $link_dest");
    my $task = {
        action  => 'create',
        type    => 'link',
        path    => $link_src,
        source  => $link_dest,
    };
    push @{ $self->{tasks} }, $task;
    $self->{link_task_for}{$link_src} = $task;

    return;
}

=head2 do_unlink($file)

Wrap 'unlink' operation for later processing

=over 4

=item $file

the file to unlink

=back

Throws an error if this clashes with an existing planned operation.
Will remove an existing planned link.

=cut

sub do_unlink {
    my $self = shift;
    my ($file) = @_;

    if (exists $self->{link_task_for}{$file}) {
        my $task_ref = $self->{link_task_for}{$file};
        if ($task_ref->{action} eq 'remove') {
            debug(1, 0, "UNLINK: $file (duplicates previous action)");
            return;
        }
        elsif ($task_ref->{action} eq 'create') {
            # Do need to create a link then remove it
            debug(1, 0, "UNLINK: $file (reverts previous action)");
            $self->{link_task_for}{$file}->{action} = 'skip';
            delete $self->{link_task_for}{$file};
            return;
        }
        else {
            internal_error("bad task action: $task_ref->{action}");
        }
    }

    if (exists $self->{dir_task_for}{$file} and $self->{dir_task_for}{$file} eq 'create') {
        internal_error(
            "new unlink operation clashes with planned operation: %s dir %s",
            $self->{dir_task_for}{$file}->{action},
            $file
        );
    }

    # Remove the link
    debug(1, 0, "UNLINK: $file");

    my $source = readlink $file or error("could not readlink $file ($!)");

    my $task = {
        action  => 'remove',
        type    => 'link',
        path    => $file,
        source  => $source,
    };
    push @{ $self->{tasks} }, $task;
    $self->{link_task_for}{$file} = $task;

    return;
}

=head2 do_mkdir($dir)

Wrap 'mkdir' operation

=over 4

=item $dir

the directory to remove

=back

Throws a fatal exception if operation fails.  Outputs a message if
'verbose' option is set.  Does not perform operation if 'simulate'
option is set.  Cleans up operations that undo previous operations.

=cut

sub do_mkdir {
    my $self = shift;
    my ($dir) = @_;

    if (exists $self->{link_task_for}{$dir}) {
        my $task_ref = $self->{link_task_for}{$dir};

        if ($task_ref->{action} eq 'create') {
            internal_error(
                "new dir clashes with planned new link (%s => %s)",
                $task_ref->{path},
                $task_ref->{source},
            );
        }
        elsif ($task_ref->{action} eq 'remove') {
            # May need to remove a link before creating a directory so continue
        }
        else {
            internal_error("bad task action: $task_ref->{action}");
        }
    }

    if (exists $self->{dir_task_for}{$dir}) {
        my $task_ref = $self->{dir_task_for}{$dir};

        if ($task_ref->{action} eq 'create') {
            debug(1, 0, "MKDIR: $dir (duplicates previous action)");
            return;
        }
        elsif ($task_ref->{action} eq 'remove') {
            debug(1, 0, "MKDIR: $dir (reverts previous action)");
            $self->{dir_task_for}{$dir}->{action} = 'skip';
            delete $self->{dir_task_for}{$dir};
            return;
        }
        else {
            internal_error("bad task action: $task_ref->{action}");
        }
    }

    debug(1, 0, "MKDIR: $dir");
    my $task = {
        action  => 'create',
        type    => 'dir',
        path    => $dir,
        source  => undef,
    };
    push @{ $self->{tasks} }, $task;
    $self->{dir_task_for}{$dir} = $task;

    return;
}

=head2 do_rmdir($dir)

Wrap 'rmdir' operation

=over 4

=item $dir

the directory to remove

=back

Throws a fatal exception if operation fails.  Outputs a message if
'verbose' option is set.  Does not perform operation if 'simulate'
option is set.

=cut

sub do_rmdir {
    my $self = shift;
    my ($dir) = @_;

    if (exists $self->{link_task_for}{$dir}) {
        my $task_ref = $self->{link_task_for}{$dir};
        internal_error(
            "rmdir clashes with planned operation: %s link %s => %s",
            $task_ref->{action},
            $task_ref->{path},
            $task_ref->{source}
        );
    }

    if (exists $self->{dir_task_for}{$dir}) {
        my $task_ref = $self->{link_task_for}{$dir};

        if ($task_ref->{action} eq 'remove') {
            debug(1, 0, "RMDIR $dir (duplicates previous action)");
            return;
        }
        elsif ($task_ref->{action} eq 'create') {
            debug(1, 0, "MKDIR $dir (reverts previous action)");
            $self->{link_task_for}{$dir}->{action} = 'skip';
            delete $self->{link_task_for}{$dir};
            return;
        }
        else {
            internal_error("bad task action: $task_ref->{action}");
        }
    }

    debug(1, 0, "RMDIR $dir");
    my $task = {
        action  => 'remove',
        type    => 'dir',
        path    => $dir,
        source  => '',
    };
    push @{ $self->{tasks} }, $task;
    $self->{dir_task_for}{$dir} = $task;

    return;
}

=head2 do_mv($src, $dst)

Wrap 'move' operation for later processing.

=over 4

=item $src

the file to move

=item $dst

the path to move it to

=back

Throws an error if this clashes with an existing planned operation.
Alters contents of package installation image in stow dir.

=cut

sub do_mv {
    my $self = shift;
    my ($src, $dst) = @_;

    if (exists $self->{link_task_for}{$src}) {
        # I don't *think* this should ever happen, but I'm not
        # 100% sure.
        my $task_ref = $self->{link_task_for}{$src};
        internal_error(
            "do_mv: pre-existing link task for $src; action: %s, source: %s",
            $task_ref->{action}, $task_ref->{source}
        );
    }
    elsif (exists $self->{dir_task_for}{$src}) {
        my $task_ref = $self->{dir_task_for}{$src};
        internal_error(
            "do_mv: pre-existing dir task for %s?! action: %s",
            $src, $task_ref->{action}
        );
    }

    # Remove the link
    debug(1, 0, "MV: $src -> $dst");

    my $task = {
        action  => 'move',
        type    => 'file',
        path    => $src,
        dest    => $dst,
    };
    push @{ $self->{tasks} }, $task;

    # FIXME: do we need this for anything?
    #$self->{mv_task_for}{$file} = $task;

    return;
}


#############################################################################
#
# End of methods; subroutines follow.
# FIXME: Ideally these should be in a separate module.


# ===== PRIVATE SUBROUTINE ===================================================
# Name      : internal_error()
# Purpose   : output internal error message in a consistent form and die
=over 4

=item $message => error message to output

=back

Returns : n/a
Throws    : n/a

=cut

sub internal_error {
    my ($format, @args) = @_;
    my $error = sprintf($format, @args);
    my $stacktrace = Carp::longmess();
    die <<EOF;

$ProgramName: INTERNAL ERROR: $error$stacktrace

This _is_ a bug. Please submit a bug report so we can fix it! :-)
See http://www.gnu.org/software/stow/ for how to do this.
EOF
}

=head1 BUGS

=head1 SEE ALSO

=cut

1;

# Local variables:
# mode: perl
# end:
# vim: ft=perl

#############################################################################
# Default global list of ignore regexps follows
# (automatically appended by the Makefile)

__DATA__
# Comments and blank lines are allowed.

RCS
.+,v

CVS
\.\#.+       # CVS conflict files / emacs lock files
\.cvsignore

\.svn
_darcs
\.hg

\.git
\.gitignore
\.gitmodules

.+~          # emacs backup files
\#.*\#       # emacs autosave files

^/README.*
^/LICENSE.*
^/COPYING
