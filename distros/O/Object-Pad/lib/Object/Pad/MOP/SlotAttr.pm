#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Object::Pad::MOP::SlotAttr 0.57;

use v5.14;
use warnings;

# This is an XS-implemented object type provided by Object::Pad itself
require Object::Pad;

=head1 NAME

C<Object::Pad::MOP::SlotAttr> - meta-object representation of a slot attribute for C<Object::Pad>

=head1 DESCRIPTION

This API provides a way for pure-perl implementations of slot attributes to be
provided. Pure-perl attributes cannot currently add new I<behaviour> to the
way that slots work, but they do provide a means for class authors to annotate
extra metadata onto slots, that can be queried by other code.

Primilarily this is done by using the L<Object::Pad::MOP::Slot/get_attribute_value>
accessor method on a slot metadata instance.

=cut

=head1 METHODS

=cut

=head2 register

   Object::Pad::MOP::SlotAttr->register( $name, %args )

I<Since version 0.57.>

Creates a new slot attribute of the given name. The name must begin with a
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

=item apply => CODE

An optional code reference for a callback function to invoke when the
attribute is applied to a slot. If present, it is passed the slot metadata
instance as a L<Object::Pad::MOP::Slot> reference, and a string containing the
contents of the attribute's parenthesized value. The return value of the
callback will be stored as the attribute's value and can be accessed by the
C<get_attribute_value> method on the slot metadata.

   $result = $apply->( $slotmeta, $value )

If the C<apply> callback is absent then the string value itself is stored.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
