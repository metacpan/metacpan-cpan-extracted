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
package SVK::Editor::XD;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use SVN::Delta;
use base qw(SVK::Editor::Checkout);
use SVK::I18N;
use autouse 'File::Path' => qw(rmtree);
use autouse 'SVK::Util'  => qw( get_anchor get_depot_anchor md5_fh );
use Class::Autouse qw( SVK::Editor::Composite );

=head1 NAME

SVK::Editor::XD - An editor for modifying svk checkout copies

=head1 SYNOPSIS

$editor = SVK::Editor::XD->new
    ( path => $path,
      target => $target,
      oldroot => $fs->revision_root ($fromrev),
      newroot => $fs->revision_root ($torev),
      xd => $xd,
      get_copath => sub { ... },
      get_path => sub { ... },
    );


=head1 DESCRIPTION

SVK::Editor::XD modifies existing checkout copies at the paths
translated by the get_copath callback, according to the incoming
editor calls.  The path in the depot is translated with the get_path
callback.

There are two modes, one is for applying changes to checkout copy as
external modification, like merging changes. The other is update mode,
which is used for bringing changes from depot to checkout copies.

=head1 PARAMETERS

In addition to the paramters to L<SVK::Editor::Checkout>:

=over

=item target

The target path of the editor calls.  Used for deciding if the root's
meta data needs to be updated in update mode.

=item xd

L<SVK::XD> object.

=item oldroot

Old root before the editor calls.

=item newroot

New root after the editor calls.

=item update

Working in update mode.

=item get_path

A callback to translate paths in editor calls to path in depot.

=item ignore_keywords

Don't do keyword translations (svn:keywords property).

=back

=cut

sub open_root {
    my ($self, $base_revision) = @_;
    $self->{signature} ||= SVK::XD::Signature->new (root => $self->{xd}->cache_directory)
	if $self->{update};
    return $self->SUPER::open_root($base_revision);
}

sub get_base {
    my ($self, $path, $copath, $checksum) = @_;
    my $dpath = $path;
    $self->{get_path}->($dpath);

    my ($dir,$file) = get_anchor (1, $copath);
    my $basename = "$dir.svk.$file.base";

    rename ($copath, $basename)
	or warn loc("rename %1 to %2 failed: %3", $copath, $basename, $!), return;

    my $base = SVK::XD::get_fh ($self->{oldroot}, '<', $dpath, $basename);
    if (!$self->{ignore_checksum} && $checksum) {
	my $md5 = md5_fh ($base);
	die loc("source checksum mismatch for %1 (%2 vs %3)", $path, $md5, $checksum) if $md5 ne $checksum;
	seek $base, 0, 0;
    }

    return [$base, $basename, -l $basename ? () : [stat($base)]];
}

sub get_fh {
    my ($self, $path, $copath) = @_;
    my ($dpath, $spath) = ($path, $path);
    $self->{get_path}->($dpath);
    $self->{get_store_path}->($spath);
    # XXX: should test merge to co with keywords
    delete $self->{props}{$path}{'svn:keywords'}
	if !$self->{update} or $self->{ignore_keywords};
    my $fh = SVK::XD::get_fh ($self->{newroot}, '>', $spath, $copath,
			      $self->{added}{$path} ? $self->{props}{$path} || {}: undef)
	or warn "can't open $path: $!", return;
    return $fh;
}

sub close_file {
    my $self = shift;
    my $path = shift;
    my $added = $self->{added}{$path};
    $self->SUPER::close_file($path, @_);
    return unless defined $path;
    my $copath = $path;
    $self->{get_copath}($copath);
    if ($self->{update}) {
	my (undef, $file) = get_anchor (1, $copath);
	# populate signature cache for added files only, because
	# modified file might be edited from merge editor, and thus
	# actually unclean.  There should be notification from merge
	# editor in the future, or to update the cache in cb_localmod
	# for modified entries.
	$self->{cursignature}[-1]->changed ($file)
	    if $added;
	$self->{xd}{checkout}->store ($copath, {revision => $self->{revision}}, {override_descendents => 0});
	$self->{xd}->fix_permission ($copath, $self->{exe}{$path})
	    if exists $self->{exe}{$path};
    }

    delete $self->{props}{$path};
}

sub add_file {
    my $self = shift;
    my ($path, $pdir, @arg) = @_;
    my $ret = $self->SUPER::add_file(@_);
    return undef unless defined $ret;
    my $copath = $path;
    $self->{get_copath}->($copath);
    if (!$self->{update} && !$self->{check_only}) {
	my ($anchor, $target, $editor);
	if (defined $arg[0]) {
	    ($anchor, $target) = get_depot_anchor(1, $path);
	    $editor = SVK::Editor::Composite->new
		( anchor => $anchor, anchor_baton => $pdir,
		  target => $target, target_baton => $ret );
	}
	$self->_schedule_entry($copath, $editor, @arg);
	if (defined $arg[0]) {
	    # special treatment to turn this node into something with base
	    delete $self->{added}{$path};
	    delete $self->{iod}{$path};
	}
    }
    return $ret;
}

sub add_directory {
    my $self = shift;
    my ($path, $pdir, @arg) = @_;
    my $ret = $self->SUPER::add_directory (@_);
    return undef unless defined $ret;
    my $copath = $path;
    $self->{get_copath}->($copath);
    if (!$self->{update} && !$self->{check_only}) {
	my $editor = SVK::Editor::Composite->new
	    ( anchor => $path, anchor_baton => $pdir );
	$self->_schedule_entry($copath, $editor, @arg);
    }

    push @{$self->{cursignature}}, $self->{signature}->load ($copath)
	if $self->{update};
    return $ret;
}

sub open_directory {
    my ($self, $path, $pdir) = @_;
    my $ret = $self->SUPER::open_directory ($path, $pdir);
    return undef unless defined $ret;
    # XXX: test if directory exists
    if ($self->{update}) {
	my $copath = $path;
	$self->{get_copath}->($copath);
	push @{$self->{cursignature}}, $self->{signature}->load ($copath);
	$self->{cursignature}[-1]{keepold} = 1;
    }
    return $ret;
}

sub do_delete {
    my $self = shift;
    my ($path, $copath) = @_;
    if ($self->{update}) {
	$self->{xd}{checkout}->store
	    ($copath,
	     {revision => $self->{revision},
	      '.deleted' => 1},
            {override_descendents => 0});
	return $self->SUPER::do_delete (@_)
    }

    $self->{get_path}($path);
    $self->{xd}->do_delete( $self->{xd}->create_path_object
			    ( copath_anchor => $copath,
			      path => $path,
			      repos => $self->{repos} ),
			    quiet => 1 );
}

sub close_directory {
    my ($self, $path) = @_;
    return unless defined $path;
    # the root is just an anchor
    return if $self->{target} && !length($path);
    my $copath = $path;
    $self->{get_copath}($copath);
    if ($self->{update}) {
	# XXX: handle unwritable entries and back them up after the store
	$self->{xd}{checkout}->store ($copath,
                                      {revision => $self->{revision},
                                       '.deleted' => undef},
                                      {override_sticky_descendents => 1});
	if (@{$self->{cursignature}}) {
	    $self->{cursignature}[-1]->flush;
	    pop @{$self->{cursignature}};
	}
    }
}

sub change_file_prop {
    my ($self, $path, $name, $value) = @_;
    return unless defined $path;
    $self->{props}{$path}{$name} = $value
	if $self->{added}{$path};
    return if $self->{check_only};

    my $copath = $path;
    $self->{get_copath}($copath);

    $self->{exe}{$path} = $value
        if $name eq 'svn:executable' && $self->{update};

    $self->{get_path}($path);
    $self->{xd}->do_propset(
        $self->{xd}->create_path_object(
            copath_anchor => $copath,
            path          => $path,
            repos         => $self->{repos}
        ),
        quiet     => 1,
        propname  => $name,
        propvalue => $value,
        adjust_only => $self->{update},
    );
}

sub change_dir_prop {
    my ($self, @arg) = @_;
    $self->change_file_prop (@arg);
}

sub close_edit {
    my ($self) = @_;
}

sub abort_edit {
    my ($self) = @_;
}

# XXX: this should be splitted to prepare base and schedule entry
sub _schedule_entry {
    my ($self, $copath, $editor, $copyfrom, $copyfrom_rev) = @_;
    my %copy;
    if (defined $copyfrom) {
	# Note that the delta run through $self here is for preparing
	# the base for subsequent editor calls that operates on top of
	# these.
	my $fs = $self->{oldroot}->fs;
	my $from_root = $fs->revision_root($copyfrom_rev);
	$editor->{master_editor} = SVK::Editor::Checkout->new(%$self);
	if (defined $editor->{target}) {
	    # XXX: depot_delta can't generate single file fulltext.
	    my $handle = $editor->apply_textdelta($editor->{target_baton}, '');
		if ($handle && $#{$handle} >= 0) {
		    SVN::TxDelta::send_stream($from_root->file_contents($copyfrom),
					      @$handle);
		    $editor->close_file($editor->{target_baton}, $from_root->file_md5_checksum($copyfrom));
		}
	}
	else {
	    $self->{xd}->depot_delta
		( oldroot => $fs->revision_root(0),
		  newroot => $from_root,
		  oldpath => ['/', ''],
		  newpath => $copyfrom,
		  editor => $editor );
	}
	%copy = ( scheduleanchor => $copath,
		  '.copyfrom' => $copyfrom,
		  '.copyfrom_rev' => $copyfrom_rev );
    }

    my (undef, $schedule) = $self->{xd}->get_entry($copath, 1);
    $self->{xd}{checkout}->store
	($copath, { %copy, '.schedule' => $schedule eq 'delete' ? 'replace' : 'add' }, {override_descendents => 0});
}


1;
