#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk

package Object::Pad::MOP::FieldAttr 0.814;

use v5.18;
use warnings;

# This is an XS-implemented object type provided by Object::Pad itself
require Object::Pad;

=head1 NAME

C<Object::Pad::MOP::FieldAttr> - meta-object representation of a field attribute for C<Object::Pad>

=head1 DESCRIPTION

=for highlighter language=perl

This API provides a way for pure-perl implementations of field attributes to be
provided. Pure-perl attributes cannot currently add new I<behaviour> to the
way that fields work, but they do provide a means for class authors to annotate
extra metadata onto fields, that can be queried by other code.

Primilarily this is done by using the L<Object::Pad::MOP::Field/get_attribute_value>
accessor method on a field metadata instance.

This API should be considered B<experimental>, and will emit warnings to that
effect. They can be silenced with

   use Object::Pad qw( :experimental(custom_field_attr) );

=cut

=head1 METHODS

=cut

=head2 register

   Object::Pad::MOP::FieldAttr->register( $name, %args );

I<Since version 0.60.>

Creates a new field attribute of the given name. The name must begin with a
capital letter, in order to distinguish this from any of the built-in core
attributes, whose names are lowercase.

The attribute is only available if the hints hash contains a key of the name
given by the attribute's C<permit_hintkey> argument. This would typically be
set in the hints hash by the C<import> method of the module implementing it,
and would be named based on the name of the module providing the attribute:

   sub import { $^H{"Some::Package::Name/Attrname"} }

Takes the following additional named arguments:

=over 4

=item permit_hintkey => STRING

Required. A string giving a key that must be found in the hints hash (C<%^H>)
for this attribute name to be visible.

=item no_value => BOOL

An optional flag; if set to true then no value is permitted on the attribute's
declaration. A compiletime error will be generated if a value is provided

=item must_value => BOOL

An optional flag; if set to true then a value is required on the attribute's
declaration. A compiletime error will be generated if a value is not provided.

If neither of these flags are provided, then a value is optional. It is not
permitted to set both flags at once.

=item apply => CODE

An optional code reference for a callback function to invoke when the
attribute is applied to a field. If present, it is passed the field metadata
instance as a L<Object::Pad::MOP::Field> reference, and a string containing
the contents of the attribute's parenthesized value. The return value of the
callback will be stored as the attribute's value and can be accessed by the
C<get_attribute_value> method on the field metadata.

   $result = $apply->( $fieldmeta, $value )

If the C<apply> callback is absent then the string value itself is stored.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
