# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package SVK::Command::Copy;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use base qw( SVK::Command::Mkdir );
use SVK::Util qw( get_anchor abs2rel splitdir is_uri make_path is_path_inside);
use SVK::I18N;
use SVK::Logger;

sub options {
    ($_[0]->SUPER::options,
     'q|quiet'         => 'quiet',
     'r|revision=s' => 'rev');
}

sub parse_arg {
    my ($self, @arg) = @_;
    return if @arg < 1;

    push @arg, '' if @arg == 1;

    my $dst = pop(@arg);
    die loc ("Copy destination can't be URI.\n")
	if is_uri ($dst);

    die loc ("More than one URI found.\n")
	if (grep {is_uri($_)} @arg) > 1;
    my @src;

    if ( my $target = eval { $self->{xd}->target_from_copath_maybe($dst) }) {
        $dst = $target;
	# don't allow new uri in source when target is copath
	@src = (map {$self->arg_co_maybe
			 ($_, $dst->isa('SVK::Path::Checkout')
			  ? loc ("path '%1' is already a checkout", $dst->report)
			  : undef)} @arg);
    }
    else {
	@src = (map {$self->arg_co_maybe ($_)} @arg);
        # Asking the user for copy destination.
        # In this case, first magically promote ourselves to "cp -p".
        # (otherwise it hurts when user types //deep/directory/name)
        $self->{parent} = 1;

        # -- make a sane default here for mirroring --
        my $default = undef;
        if (@src == 1 and $src[0]->path =~ m{/mirror/([^/]+)$}) {
            $default = "/" . $src[0]->depotname . "/$1";
        }

        my $path = $self->prompt_depotpath("copy", $default);

        if ($dst eq '.') {
            $self->{_checkout_path} = (splitdir($path))[-1];
        }
        else {
            $self->{_checkout_path} = $dst;
        }

        $dst = $self->arg_depotpath("$path/");
    }

    return (@src, $dst);
}

sub lock {
    my $self = shift;
    $self->lock_coroot($_[-1]);
}

sub handle_co_item {
    my ($self, $src, $dst) = @_;
    $src = $src->as_depotpath;
    die loc ("Path %1 does not exist.\n", $src->path_anchor)
	if $src->root->check_path ($src->path_anchor) == $SVN::Node::none;
    my ($copath, $report) = ($dst->copath, $dst->report);
    die loc ("Path %1 already exists.\n", $copath)
	if -e $copath;
    my ($entry, $schedule) = $self->{xd}->get_entry($copath, 1);
    $src->normalize; $src->anchorify;
    $self->ensure_parent($dst);
    $dst->anchorify;

    my $notify = $self->{quiet} ? SVK::Notify->new(quiet => 1) : undef;
    # if SVK::Merge could take src being copath to do checkout_delta
    # then we have 'svk cp copath... copath' for free.
    # XXX: use editor::file when svkup branch is merged
    my ($editor, $inspector, %cb) = $dst->get_editor
	( ignore_checksum => 1, quiet => 1,
	  check_only => $self->{check_only},
	  update => 1, ignore_keywords => 1,
	);
    SVK::Merge->new (%$self, repos => $dst->repos, nodelay => 1,
		     report => $report, notify => $notify,
		     base => $src->new (path => '/', revision => 0),
		     src => $src, dst => $dst)
	    ->run
		($editor, %cb, inspector => $inspector);

    $self->{xd}{checkout}->store
	($copath, { revision => undef });
    # XXX: can the schedule be something other than delete ?
    $self->{xd}{checkout}->store ($copath, {'.schedule' => $schedule ? 'replace' : 'add',
					    scheduleanchor => $copath,
					    '.copyfrom' => $src->path,
					    '.copyfrom_rev' => $src->revision});
}

sub handle_direct_item {
    my ($self, $editor, $anchor, $m, $src, $dst, $other_call) = @_;
    $src->normalize;
    # if we have targets, ->{path} must exist
    if (!$self->{parent} && $dst->{targets} && !$dst->root->check_path ($dst->path_anchor)) {
	die loc ("Parent directory %1 doesn't exist, use -p.\n", $dst->report);
    }
    my ($path, $rev) = ($src->path, $src->revision);
    my $baton = $editor->add_directory (abs2rel ($dst->path, $anchor => undef, '/'), 0, $path, $rev);
    $other_call->($baton) if $other_call;
    $editor->close_directory($baton);
    $editor->adjust_last_anchor;
}

sub _unmodified {
    my ($self, $target) = @_;
    my (@modified, @unknown);
    $target = $self->{xd}->target_condensed($target); # anchor
    $self->{xd}->checkout_delta
	( $target->for_checkout_delta,
	  xdroot => $target->create_xd_root,
	  editor => SVK::Editor::Status->new
	  ( notify => SVK::Notify->new
	    ( cb_flush => sub { push @modified, $_[0] })),
	  cb_unknown => sub { push @unknown, $_[1] } );

    if (@modified || @unknown) {
	my @reports = sort map { loc ("%1 is modified.\n", $target->report_copath ($_)) } @modified;
	push @reports, sort map { loc ("%1 is unknown.\n", $target->report_copath ($_)) } @unknown;
	die join("", @reports);
    }
}

sub check_src {
    my ($self, @src) = @_;
    for my $src (@src) {
	$src->revision($self->resolve_revision($src, $self->{rev})) if defined $self->{rev};
	$self->apply_revision($src);
	next unless $src->isa('SVK::Path::Checkout');
	$self->_unmodified ($src->new);
    }
}

sub run {
    my ($self, @src) = @_;
    my $dst = pop @src;

    return loc("Different depots.\n") unless $dst->same_repos(@src);
    my $m = $self->under_mirror($dst);
    if ( $m && !$dst->same_source(@src) ) {
        $logger->error(loc("You are trying to copy across different mirrors."));
        die loc( "Create an empty directory %1, and run smerge --baseless %2 %3.\n",
            $dst->report, $src[0]->report, $dst->report )
          if $#src == 0 && $dst->isa('SVK::Path');
        return 1;
    }
    $self->check_src (@src);
    # XXX: check dst to see if the copy is obstructured or missing parent
    my $fs = $dst->repos->fs;
    if ($dst->isa('SVK::Path::Checkout')) {
	return loc("%1 is not a directory.\n", $dst->report)
	    if $#src > 0 && !-d $dst->copath;
	return loc("%1 is not a versioned directory.\n", $dst->report)
	    if -d $dst->copath && $dst->root->check_path($dst->path) != $SVN::Node::dir;

	my @cpdst;
	for (@src) {
	    my $cpdst = $dst->new;
	    # implicit target for "cp x y z dir/"
	    if (-d $cpdst->copath) {
		if ($_->path_anchor eq $cpdst->path_anchor) {
		    $logger->warn(loc("Ignoring %1 as source.", $_->report));
		    next;
		}
		if ( is_path_inside($cpdst->path_anchor, $_->path_anchor) ) {
		    die loc("Invalid argument: copying directory %1 into itself.\n", $_->report);
		}
		$cpdst->descend ($_->path_anchor =~ m|/([^/]+)/?$|)
	    }
	    die loc ("Path %1 already exists.\n", $cpdst->report)
		if -e $cpdst->copath;
	    push @cpdst, [$_, $cpdst];
	}
	$self->handle_co_item(@$_) for @cpdst;
    }
    else {
	if ($dst->root->check_path($dst->path_anchor) != $SVN::Node::dir) {
	    die loc ("Copying more than one source requires %1 to be directory.\n", $dst->report)
		if $#src > 0;
	    $dst->anchorify;
	}
	$self->get_commit_message ();
	my ($anchor, $editor) = $self->get_dynamic_editor ($dst);
	for (@src) {
            eval {
                $self->handle_direct_item ($editor, $anchor, $m, $_,
                                           $dst->{targets} ? $dst :
                                           $dst->new (targets => [$_->path_anchor =~ m|/([^/]+)/?$|]));
            };
            if ($@) {
                my $err = $@; # make sure not to lose it
                # Clean up transaction.
                $editor->abort_edit;
                die $err;
            }
	}
	$self->finalize_dynamic_editor ($editor);
    }

    if (defined( my $copath = $self->{_checkout_path} )) {
        my $checkout = $self->command ('checkout');
	$checkout->getopt ([]);
        my @arg = $checkout->parse_arg ('/'.$dst->depotname.$dst->path, $copath);
        $checkout->lock (@arg);
        $checkout->run (@arg);
    }

    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Copy - Make a versioned copy

=head1 SYNOPSIS

 copy DEPOTPATH1 DEPOTPATH2
 copy DEPOTPATH [PATH]

=head1 OPTIONS

 -r [--revision] REV    : act on revision REV instead of the head revision
 -p [--parent]          : create intermediate directories as required
 -q [--quiet]           : print as little as possible
 -m [--message] MESSAGE : specify commit message MESSAGE
 -F [--file] FILENAME   : read commit message from FILENAME
 --template             : use the specified message as the template to edit
 --encoding ENC         : treat -m/-F value as being in charset encoding ENC
 -P [--patch] NAME      : instead of commit, save this change as a patch
 -S [--sign]            : sign this change
 -C [--check-only]      : try operation but make no changes
 --direct               : commit directly even if the path is mirrored

