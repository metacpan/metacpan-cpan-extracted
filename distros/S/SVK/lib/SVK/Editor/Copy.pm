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
package SVK::Editor::Copy;
use strict;
use warnings;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use SVK::Logger;

require SVN::Delta;
use base 'SVK::Editor::ByPass';

=head1 NAME

SVK::Editor::Copy - Turn editor calls to calls with history

=head1 SYNOPSIS

  $editor = SVK::Editor::Copy->new
    ( _editor => [$next_editor],
      copyboundry_root => $root,
      copyboundry_rev => \@possible_rev,
      src => $src,
      dst => $dst,
      cb_resolve_copy => sub {},
    );


=head1 DESCRIPTION

This is the magic editor that turns a series of history-unaware editor
calls into history-aware ones.  The main Subversion tree delta API
C<SVN::Repos::dir_delta> generates "expanded" editor calls, mainly to
be used for editors for writing to checkout or showing diff.  However,
it's desired to have history-aware editor calls for the purpose of
replaying revisions which have copies, or displaying diff for
copy-then-modified files.

copyboundry_rev contains an array of possible points to be used as
copyfrom rev to be resolved.  but the logic should be moved to the
resolver.

=cut

use SVK::Util qw( get_depot_anchor );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{ignore_baton} = \(my $dummy);
    return $self;
}

sub should_ignore {
    my ($self, $path, $pbaton) = @_;
    if (defined $pbaton && $pbaton eq $self->{ignore_baton}) {
	return 1;
    }

    if (ref($pbaton) eq 'SVK::Editor::Copy::copied') {
	return 1;
    }

    return;
}

# XXX: This should call a callback to decide if a copy candidate is
# wanted or not
sub find_copy {
    my ($self, $path, $replace) = @_;
    my $target_path = File::Spec::Unix->catdir($self->{src}->path_anchor, $path);

    my ($cur_root, $cur_path) = ($self->{src}->root, $target_path);
    # XXX: this is mostly because file vs file target with different name,
    # should resolve them back to dst name properly.
    return unless $cur_root->check_path($cur_path);

    my $copyboundry_rev = $self->{copyboundry_rev};
    $copyboundry_rev = [ $copyboundry_rev ] unless ref $copyboundry_rev;
    unless ($self->{_roots}) {
	# initialise and cache roots to be used.
	my $pool = $self->{_pool} = SVN::Pool->new;
	$self->{_roots}{$_} = $self->{copyboundry_root}->fs->revision_root($_, $pool)
	    for @$copyboundry_rev;
    }
    my $ppool = SVN::Pool->new;
    my $pool = SVN::Pool->new_default;
    while (1) {
	$pool->clear;
	my ($toroot, $fromroot, $src_frompath) =
	    SVK::Path::nearest_copy($cur_root, $cur_path, $ppool);
	$logger->debug("===> $cur_path => ".($src_frompath||''));
	return unless defined $src_frompath;

	# don't use the same copy twice
	if (exists $self->{incopy}[-1]) {
	    if ($src_frompath =~ m{^\Q$self->{incopy}[-1]{src_frompath}/}) {
		return;
		# XXX: It doesn't seem right to fallback to previous
		# copies from the one we don't want.  But make sure
		# this is the case.
#		($cur_root, $cur_path) = ($fromroot, $src_frompath);
#		next;
	    }
	}

	my ($src_from, $to) = map {$_->revision_root_revision}
	    ($fromroot, $toroot);

	# Make sure the copy happens not solely within the range of this merge.
	my ($base_rev);
	for my $try (@$copyboundry_rev) {
	    $logger->debug("to $to, from $src_from, try $try");
	    if ($try < $to) {
		$base_rev = $try;
		last;
	    }
	}
	return unless $base_rev;

	{ # if the copy source is out side of our branch, and is in the same source
	my $hate_path = $self->{src}->path_anchor;
	if ($src_frompath !~ m{^\Q$hate_path/} &&
	    $self->{dst}->same_source($self->{dst}->mclone( path_anchor => $src_frompath))) {
	    if (my ($frompath, $from) = $self->{cb_resolve_copy}->($path, $replace, $src_frompath, $src_from)) {
		push @{$self->{incopy}}, { path => $path,
					   fromrev => $from,
					   src_frompath => $src_frompath,
					   frompath => $frompath };
		return $self->copy_source($src_frompath, $src_from);
	    }
	    return;
	}

	return unless $src_frompath =~ m{^\Q$hate_path/};
        }

	if ($self->{merge}->_is_merge_from
	    ($self->{src}->path, $self->{dst}, $to)) {
	    ($cur_root, $cur_path) = ($fromroot, $src_frompath);
	    next;
	}


	# XXX: Document this condition

	my $id = $fromroot->node_id($src_frompath);
	if ($self->{_roots}{$base_rev}->check_path($src_frompath) &&
	    SVN::Fs::check_related($id, $self->{_roots}{$base_rev}->node_id($src_frompath))) {
	    my $src = $self->{src}->new(revision => $base_rev, path => $src_frompath);
	    $src->normalize;
	    $src_from = $src->revision;
	}
	else {
	    ($cur_root, $cur_path) = ($fromroot, $src_frompath);
	    next;
	}

	# GRR! cleanup this!
	$logger->debug("==> $path(:$to) is copied from $src_frompath:$src_from");
	if (my ($frompath, $from) = $self->{cb_resolve_copy}->($path, $replace, $src_frompath, $src_from)) {
	    push @{$self->{incopy}}, { path => $path,
				       fromrev => $from,
				       src_frompath => $src_frompath,
				       frompath => $frompath };
	    $logger->debug("==> resolved to $frompath:$from");
	    return $self->copy_source($src_frompath, $src_from);
	}
	else {
	    ($cur_root, $cur_path) = ($fromroot, $src_frompath);
	    next;
	}
    }
    return;
}

sub copy_source {
    my ($self, @arg) = @_;
    my $cb = $self->{cb_copyfrom};
    @arg = $cb->(@arg) if $cb;
    return @arg;
}

sub outcopy {
    my ($self, $path) = @_;
    return unless exists $self->{incopy}[-1];
    return unless $self->{incopy}[-1]{path} eq $path;
    pop @{$self->{incopy}};
}

sub add_directory {
    my ($self, $path, $pbaton, $from_path, $from_rev, $pool) = @_;
    return $self->{ignore_baton} if $self->should_ignore($path, $pbaton);
    if (my @ret = $self->find_copy($path)) {
	return $self->replay_add_history('directory', $path, $pbaton,
					 @ret, $pool);
    }

    $self->SUPER::add_directory($path, $pbaton, $from_path, $from_rev, $pool);
}

sub add_file {
    my ($self, $path, $pbaton, $from_path, $from_rev, $pool) = @_;
    return $self->{ignore_baton} if $self->should_ignore($path, $pbaton);

    if (my @ret = $self->find_copy($path)) {
	return $self->replay_add_history('file', $path, $pbaton,
					 @ret, $pool);
    }

    $self->SUPER::add_file($path, $pbaton, $from_path, $from_rev, $pool);
}

sub open_directory {
    my ($self, $path, $pbaton, @arg) = @_;
    return $self->{ignore_baton} if $self->should_ignore($path, $pbaton);
    if (my @ret = $self->find_copy($path, 1)) {
	$logger->debug("==> turn $path into replace: ".join(',',@ret));
	$self->SUPER::delete_entry($path, $arg[0], $pbaton, $arg[1]);
	return $self->replay_add_history('directory', $path, $pbaton, @ret, $arg[1])
    }

    $self->SUPER::open_directory($path, $pbaton, @arg);
}

sub open_file {
    my ($self, $path, $pbaton, @arg) = @_;
    return $self->{ignore_baton} if $self->should_ignore($path, $pbaton);
    if (my @ret = $self->find_copy($path, 1)) {
	$logger->debug("==> turn file $path into replace");
	$self->SUPER::delete_entry($path, $arg[0], $pbaton, $arg[1]);
	return $self->replay_add_history('file', $path, $pbaton, @ret, $arg[1])
    }

    $self->SUPER::open_file($path, $pbaton, @arg);
}

sub apply_textdelta {
    my ($self, $path, @arg) = @_;
    return if $self->should_ignore(undef, $path);
    return $self->SUPER::apply_textdelta($path, @arg);
}

sub close_file {
    my ($self, $baton, @arg) = @_;
    if (ref($baton) eq 'SVK::Editor::Copy::copied') {
	$self->outcopy($baton->{path});
	return $self->SUPER::close_file($baton->{baton}, @arg);

    }
    return if $self->should_ignore(undef, $baton);

    return $self->SUPER::close_file($baton, @arg);
}


sub change_file_prop {
    my ($self, $path, @arg) = @_;
    return if $self->should_ignore(undef, $path);

    return $self->SUPER::change_file_prop($path, @arg);
}

sub change_dir_prop {
    my ($self, $path, @arg) = @_;
    return if $self->should_ignore(undef, $path);
    return $self->SUPER::change_dir_prop($path, @arg);

}

sub delete_entry {
    my ($self, $path, $revision, $pdir, @arg) = @_;
    return if $self->should_ignore($path, $pdir);
    return $self->SUPER::delete_entry($path, $revision, $pdir, @arg);
}

sub close_directory {
    my ($self, $baton, @arg) = @_;
    if (ref($baton) eq 'SVK::Editor::Copy::copied') {
	$self->outcopy($baton->{path});
	return $self->SUPER::close_directory($baton->{baton}, @arg);
    }
    return if $self->should_ignore(undef, $baton);

    $self->SUPER::close_directory($baton, @arg);
}

sub replay_add_history {
    my ($self, $type, $path, $pbaton, $src_path, $src_rev, $pool) = @_;
    my $func = "SUPER::add_$type";
    my $baton = $self->$func($path, $pbaton, $src_path, $src_rev, $pool);

    my ($anchor, $target) = ($path, '');
    my ($src_anchor, $src_target) = ($self->{incopy}[-1]{frompath}, '');

    my %arg = ( anchor => $anchor, anchor_baton => $baton );
    if ($type eq 'file') {
	($anchor, $target) = get_depot_anchor(1, $anchor);
	($src_anchor, $src_target) = get_depot_anchor(1, $src_anchor);
	%arg = ( anchor => $anchor, anchor_baton => $pbaton,
		 target => $target, target_baton => $baton );
    }

    require SVK::Editor::Composite;
    my $editor = SVK::Editor::Composite->new
	( master_editor => $self, %arg );

    $editor = SVK::Editor::Translate->new
	(_editor => [$editor],
	 translate => sub { $_[0] =~ s/^\Q$src_target/$target/ })
	    if $type eq 'file';

    $logger->debug("****==> to delta $src_anchor / $src_target @ $self->{incopy}[-1]{fromrev} vs $self->{src}{path} / $path");
    $logger->debug("==> sample");
    require SVK::Editor::Delay;
    SVK::XD->depot_delta
	    ( oldroot => $self->{copyboundry_root}->fs->
	      revision_root($self->{incopy}[-1]{fromrev}),
	      newroot => $self->{src}->root,
	      oldpath => [$src_anchor, $src_target],
	      newpath => File::Spec::Unix->catdir($self->{src}->path_anchor, $path),
	      editor => SVK::Editor->new(_debug => 1)) if $logger->is_debug();
    $logger->debug("==> done sample");
    SVK::XD->depot_delta
	    ( oldroot => $self->{copyboundry_root}->fs->
	      revision_root($self->{incopy}[-1]{fromrev}),
	      newroot => $self->{src}->root,
	      oldpath => [$src_anchor, $src_target],
	      newpath => File::Spec::Unix->catdir($self->{src}->path_anchor, $path),
	      editor => SVK::Editor::Delay->new(_editor => [$editor]) );
    $logger->debug("***=>done delta");
    # close file is done by the delta;
    return bless { path => $path,
		   baton => $baton,
		 }, __PACKAGE__.'::copied';

    $self->{ignore_baton};
}


1;
