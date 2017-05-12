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
package SVK::Editor::Combine;
use strict;

use SVK::Version;  our $VERSION = $SVK::VERSION;

require SVN::Delta;
use base 'SVK::Editor';

use autouse 'SVK::Util' => qw( tmpfile );

=head1 NAME

SVK::Editor::Combine - An editor combining several editor calls to one

=head1 SYNOPSIS

 $editor = SVK::Editor::Combine->new
    ( base_root => $fs->revision_root ($rev),
    );

 # feed several sets of editor calls to $editor

 # drive $other_editor with the combined editor calls
 $editor->replay ($other_editor);

=cut

sub replay {
    my ($self, $editor, $base_rev) = @_;
    require SVN::Simple::Edit;
	my $edit = SVN::Simple::Edit->new
	    (_editor => [$editor],
	     pool => SVN::Pool->new ($self->{pool}),
	     missing_handler => sub { my ($self, $path) = @_;
				      $self->{added}{$path} ?
					  $self->add_directory ($path) : $self->open_directory($path);
				  });

    $edit->open_root ($base_rev);

    for (sort keys %{$self->{files}}) {
	my $fname = $self->{files}{$_}->filename;
	my $fh;
	$edit->add_file ($_)
	    if $self->{added}{$_};
	open $fh, '<:raw', $fname or die $!;
	$edit->modify_file ($_, $fh, $self->{md5}{$_});
    }
    $edit->close_edit;
}

sub callbacks {
    my $self = shift;
    ( cb_exist => sub { $self->cb_exist (@_) },
      cb_localmod => sub { $self->cb_localmod (@_) },
      cb_localprop => sub { $self->cb_localprop (@_) },
    );
}

sub cb_exist {
    my ($self, $path) = @_;
    return $SVN::Node::file if exists $self->{files}{$path};
    $path = $self->{tgt_anchor}.'/'.$path;;
    return $self->{base_root}->check_path ($path);
}

sub cb_localmod {
    my ($self, $path, $checksum, $pool) = @_;
    if (exists $self->{files}{$path}) {
	return if $self->{md5}{$path} eq $checksum;
	my $fname = $self->{files}{$path}->filename;
	open my ($fh), '<:raw', $fname or die $!;
	return [$fh, $fname, $self->{md5}{$path}];
    }

    $path = $self->{tgt_anchor}.'/'.$path;;
    my $md5 = $self->{base_root}->file_md5_checksum ($path, $pool);
    return if $md5 eq $checksum;
    return [$self->{base_root}->file_contents ($path, $self->{pool}), undef, $md5];
}

sub cb_localprop {
    my ($self, $path, $propname, $pool) = @_;
    $path = $self->{tgt_anchor}.'/'.$path;
    return $self->{base_root}->node_prop ($path, $propname, $pool);
}

sub add_file {
    my ($self, $path, $pdir, @arg) = @_;
    $self->{added}{$path} = 1;
    return $path;
}

sub open_file {
    my ($self, $path, $pdir, @arg) = @_;
    return $path;
}

sub apply_textdelta {
    my ($self, $path, $checksum) = @_;
#    my $pool = $self->{pool};
#    $pool->default if $pool && $pool->can ('default');
    my $base;

    if (exists $self->{files}{$path}) {
	$base = $self->{files}{$path};
	my $fname = ${*$base};
	open $base, '<:raw', $fname or die $!;
    }
    else {
	$base = $self->{base_root}->file_contents ("$self->{tgt_anchor}/$path")
	    unless $self->{added}{$path};
    }

    $self->{files}{$path} = tmpfile ('combine');
    $self->{base}{$path} = $base;

    $base ||= SVN::Core::stream_empty();
    return [SVN::TxDelta::apply ($base, $self->{files}{$path}, undef, undef)];
}

sub close_file {
    my ($self, $path, $md5) = @_;
    delete $self->{base}{$path};
    $self->{md5}{$path} = $md5;
}


1;
