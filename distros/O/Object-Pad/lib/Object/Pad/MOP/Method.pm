#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Object::Pad::MOP::Method 0.56;

use v5.14;
use warnings;

# This is an XS-implemented object type provided by Object::Pad itself
require Object::Pad;

=head1 NAME

C<Object::Pad::MOP::Method> - meta-object representation of a method of a C<Object::Pad> class

=head1 DESCRIPTION

Instances of this class represent a method of a class implemented by
L<Object::Pad>. Accessors provide information about the method.

This API should be considered experimental even within the overall context in
which C<Object::Pad> is expermental.

=cut

=head1 METHODS

=head2 name

   $name = $metamethod->name

Returns the name of the method, as a plain string.

=head2 class

Returns the L<Object::Pad::MOP::Class> instance representing the class of
which this method is a member.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
