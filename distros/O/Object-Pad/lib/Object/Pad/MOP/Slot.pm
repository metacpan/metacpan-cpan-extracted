#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2021 -- leonerd@leonerd.org.uk

package Object::Pad::MOP::Slot 0.57;

use v5.14;
use warnings;

# This is an XS-implemented object type provided by Object::Pad itself
require Object::Pad;

=head1 NAME

C<Object::Pad::MOP::Slot> - meta-object representation of data slot of a C<Object::Pad> class

=head1 DESCRIPTION

Instances of this class represent a data slot of a class implemented by
L<Object::Pad>. Accessors provide information about the slot. The special
C<value> method allows access to the value of the given slot on instances of
its class, letting the meta-object be used as a proxy to it.

This API should be considered experimental even within the overall context in
which C<Object::Pad> is expermental.

=cut

=head1 METHODS

=head2 name

   $name = $metaslot->name

Returns the name of the slot, as a plain string including the leading sigil
character.

=head2 sigil

   $sigil = $metaslot->sigil

I<Since version 0.56.>

Returns the first character of the slot name, giving just its leading sigil.

=head2 class

   $metaclass = $metaslot->class

Returns the L<Object::Pad::MOP::Class> instance representing the class of
which this slot is a member.

=head2 value

   $current = $metaslot->value( $instance )
   @current = $metaslot->value( $instance )
   %current = $metaslot->value( $instance )

An accessor method which returns the current value of the slot from an object
instance.

   $metaslot->value( $instance ) = $new

On scalar slots, this method can also act as an lvalue mutator allowing a new
value to be set.

=head2 has_attribute

   $exists = $metaslot->has_attribute( $name )

I<Since version 0.57.>

Returns a boolean indicating whether the named attribute has been attached to
the slot. The attribute name should not include the leading colon (C<:>)
character.

=head2 get_attribute_value

   $value = $metaslot->get_attribute_value( $name )

I<Since version 0.57.>

Returns the stored value of an attached attribute, if one exists. If the
attribute has not been attached then an exception is thrown.

Note that most core-defined attributes will either store no data at all, or
a method name string. This accessor method is provided largely for the benefit
of obtaining data defined by third-party attributes, which may more clearly
define how that data is generated and used.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
