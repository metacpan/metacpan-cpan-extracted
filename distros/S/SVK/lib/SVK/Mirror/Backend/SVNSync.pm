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
package SVK::Mirror::Backend::SVNSync;
use strict;
use base 'SVK::Mirror::Backend::SVNRa';
use SVK::I18N;

sub _do_load_fromrev {
    my $self = shift;
    return $self->mirror->repos->fs->youngest_rev;
}

sub load {
    my ( $class, $mirror ) = @_;
    my $self = $class->new( { mirror => $mirror } );
    my $fs = $mirror->depot->repos->fs;
    $mirror->url( $fs->revision_prop( 0,         'svn:svnsync:from-url' ) );
    $mirror->server_uuid( $fs->revision_prop( 0, 'svn:svnsync:from-uuid' ) );
    $mirror->source_uuid( $fs->revision_prop( 0, 'svn:svnsync:from-uuid' ) );

    die loc("%1 is not a mirrored path.\n", "/".$self->mirror->depot->depotname."/")
	unless $mirror->url;
    $self->source_root( $mirror->url );
    $self->source_path('');

    $self->refresh;

    return $self;
}

sub _init_state {
    my ( $self, $txn, $editor ) = @_;
    die loc("Requires newer svn for replay support when mirroring to /.\n")
	unless $self->has_replay;
    my $mirror = $self->mirror;
    die loc( "Must replicate whole repository at %1.\n", $mirror->url )
        if $self->source_path;

    my $fs = $mirror->depot->repos->fs;
    if ( my $from = $fs->revision_prop( 0, 'svn:svnsync:from-url' ) ) {
        die loc( "%1 is already a mirror of %2.\n",
            "/" . $mirror->depot->depotname . "/", $from );
    }
    $fs->change_rev_prop( 0, 'svn:svnsync:from-url',  $mirror->url );
    $fs->change_rev_prop( 0, 'svn:svnsync:from-uuid', $mirror->server_uuid );

    #    $fs->change_rev_prop(0, 'svn:svnsync:last-merged-rev', 0);
    return $self;
}

sub _do_relocate {
    my ($self) = @_;
    $self->mirror->depot->repos->fs->change_rev_prop( 0, 'svn:svnsync:from-url',  $self->mirror->url );
}

sub find_rev_from_changeset { $_[1] }

sub find_changeset { $_[1] }

sub _revmap_prop { }

sub _get_sync_editor {
    my ($self, $editor, $changeset) = @_;

    return SVK::Editor::CopyHandler->new(
        _editor => $editor,
        cb_copy => sub {
            my ( $editor, $path, $rev ) = @_;
            return ( $path, $rev ) if $rev == -1;
            $path =~ s{^\Q/}{};
            return ( $path, $rev );
        }
    )
}

sub _after_replay {
    my ($self, $ra, $editor) = @_;
    $editor->close_edit;
}

sub _relayed { }

1;
