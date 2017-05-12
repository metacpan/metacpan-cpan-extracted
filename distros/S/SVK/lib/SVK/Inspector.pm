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
package SVK::Inspector;

use strict;
use warnings;

use base qw{ Class::Accessor::Fast };

__PACKAGE__->mk_accessors(qw(path_translations));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    
    $self->path_translations([]) unless $self->path_translations; 

    return $self;
}

=head1 NAME

SVK::Inspector - path inspector

=head1 DESCRIPTION

This class provides an interface through which the state of a C<SVK::Path> can
be inspected.

=head1 METHODS

=over

=item exist

Check if the given path exists.

=item rev

Check the revision of the given path.

=item localmod

Called when the merger needs to retrieve the local modification of a
file. Return an arrayref of filename, filehandle, and md5. Return
undef if there is no local modification.

=item localprop

Called when the merger needs to retrieve the local modification of a
property. Return the property value.

=item prop_merged

Called when properties are merged without changes, that is, the C<g>
status.

=item dirdelta

When C<delete_entry> needs to check if everything to be deleted does
not cause conflict on the directory, it calls the callback with path,
base_root, and base_path. The returned value should be a hash with
changed paths being the keys and change types being the values.

=back

=cut


sub push_translation {
    my $self = shift;
    my $transform = shift;
    unless (ref $transform eq 'CODE') {
        die "Path transformations must be code refs";
    }
   
    push @{$self->path_translations}, $transform;
}

sub translate {
    my $self = shift;
    my $path = shift;
    
    return $path unless @{$self->path_translations};

    my $ret = "";
    for (@{$self->path_translations}) {
        $_->($path);
    }    
    
    return $path;
}

1;
