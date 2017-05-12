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
package SVK::Editor::Composite;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use base 'SVK::Editor';

__PACKAGE__->mk_accessors(qw(master_editor));

=head1 NAME

SVK::Editor::Composite - composite editor

=head1 SYNOPSIS



=head1 DESCRIPTION

This editor is constructed with C<anchor> and C<anchor_baton>.  It
then takes incoming editor calls, replay to C<master_editor> with
paths prefixed with C<anchor>.

=cut

sub AUTOLOAD {
    my ($self, @arg) = @_;
    my $func = our $AUTOLOAD;
    $func =~ s/^.*:://;
    return if $func =~ m/^[A-Z]/;

    if ($func eq 'open_root') {
    }
    elsif ($func =~ m/^(?:add|open|delete)/) {
	return $self->{target_baton}
	    if defined $self->{target} && $arg[0] eq $self->{target};
	$arg[0] = length $arg[0] ?
	    "$self->{anchor}/$arg[0]" : $self->{anchor}
                if defined $self->{anchor};
    }
    elsif ($func =~ m/^close_(?:file|directory)/) {
	if (defined $arg[0]) {
	    return if defined $self->{anchor_baton} &&
		$arg[0] eq $self->{anchor_baton};
	    return if defined $self->{target_baton} &&
		$arg[0] eq $self->{target_baton};
	}
    }

    $self->master_editor->$func(@arg);
}

sub set_target_revision {}

sub open_root {
    my $self = shift;
    return $self->{anchor_baton} if exists $self->{anchor_baton};

    return $self->master_editor->open_root(@_)
}

sub close_edit {}

1;
