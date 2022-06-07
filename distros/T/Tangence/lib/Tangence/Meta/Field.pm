#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2021 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.41;

package Tangence::Meta::Field 0.29;
class Tangence::Meta::Field :strict(params);

=head1 NAME

C<Tangence::Meta::Field> - structure representing one C<Tangence> structure
field

=head1 DESCRIPTION

This data structure object stores information about one field of a L<Tangence>
structure. Once constructed, such objects are immutable.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $field = Tangence::Meta::Field->new( %args )

Returns a new instance initialised by the given fields.

=over 8

=item name => STRING

Name of the field

=item type => STRING

Type of the field as a L<Tangence::Meta::Type> reference

=back

=cut

has $name :param :reader;
has $type :param :reader;

=head1 ACCESSORS

=cut

=head2 name

   $name = $field->name

Returns the name of the field

=cut

=head2 type

   $type = $field->type

Return the type as a L<Tangence::Meta::Type> reference.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
