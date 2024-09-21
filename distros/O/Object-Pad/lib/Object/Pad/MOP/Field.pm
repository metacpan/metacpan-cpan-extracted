#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2022 -- leonerd@leonerd.org.uk

package Object::Pad::MOP::Field 0.814;

use v5.18;
use warnings;

# This is an XS-implemented object type provided by Object::Pad itself
require Object::Pad;

=head1 NAME

C<Object::Pad::MOP::Field> - meta-object representation of data field of a C<Object::Pad> class

=head1 DESCRIPTION

=for highlighter language=perl

Instances of this class represent a data field of a class implemented by
L<Object::Pad>. Accessors provide information about the field. The special
C<value> method allows access to the value of the given field on instances of
its class, letting the meta-object be used as a proxy to it.

This API should be considered B<experimental>, and will emit warnings to that
effect. They can be silenced with

   use Object::Pad qw( :experimental(mop) );

=cut

=head1 METHODS

=head2 name

   $name = $metafield->name;

Returns the name of the field, as a plain string including the leading sigil
character.

=head2 sigil

   $sigil = $metafield->sigil;

I<Since version 0.56.>

Returns the first character of the field name, giving just its leading sigil.

=head2 class

   $metaclass = $metafield->class;

Returns the L<Object::Pad::MOP::Class> instance representing the class of
which this field is a member.

=head2 value

   $current = $metafield->value( $instance );
   @current = $metafield->value( $instance );
   %current = $metafield->value( $instance );

An accessor method which returns the current value of the field from an object
instance.

   $metafield->value( $instance ) = $new;

On scalar fields, this method can also act as an lvalue mutator allowing a new
value to be set.

=head2 has_attribute

   $exists = $metafield->has_attribute( $name );

I<Since version 0.57.>

Returns a boolean indicating whether the named attribute has been attached to
the field. The attribute name should not include the leading colon (C<:>)
character.

=head2 get_attribute_value

   $value = $metafield->get_attribute_value( $name );

I<Since version 0.57.>

Returns the stored value of an attached attribute, if one exists. If the
attribute has not been attached then an exception is thrown.

Note that most core-defined attributes will either store no data at all, or
a method name string. This accessor method is provided largely for the benefit
of obtaining data defined by third-party attributes, which may more clearly
define how that data is generated and used.

=head2 get_attribute_values

   @values = $metafield->get_attribute_values( $name );

I<Since version 0.66.>

Returns all the stored values of an attached attribute, if one exists. If the
attribute has not been attached then an exception is thrown.

This allows inspection of stored attribute values if it makes meaningful sense
for the attribute to be applied multiple times to the same field. This is
unlikely to be useful for core-defined attributes, but may be meaningful for
third-party attributes.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
