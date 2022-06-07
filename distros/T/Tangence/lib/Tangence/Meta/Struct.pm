#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2021 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.43;

package Tangence::Meta::Struct 0.29;
class Tangence::Meta::Struct :strict(params);

use Carp;

=head1 NAME

C<Tangence::Meta::Struct> - structure representing one C<Tangence> structure
type

=head1 DESCRIPTION

This data structure stores information about one L<Tangence> structure type.
Once constructed and defined, such objects are immutable.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $struct = Tangence::Meta::Struct->new( name => $name )

Returns a new instance representing the given name.

=cut

has $name    :param :reader;
has $defined        :reader = 0;

has @fields;

=head2 define

   $struct->define( %args )

Provides a definition for the structure.

=over 8

=item fields => ARRAY

ARRAY reference containing metadata about the structure's fields, as instances
of L<Tangence::Meta::Field>.

=back

=cut

method define ( %args )
{
   $defined and croak "Cannot define $name twice";

   $defined++;
   @fields = @{ $args{fields} };
}

=head1 ACCESSORS

=cut

=head2 defined

   $defined = $struct->defined

Returns true if a definition of the structure has been provided using
C<define>.

=cut

=head2 name

   $name = $struct->name

Returns the name of the structure

=cut

=head2 fields

   @fields = $struct->fields

Returns a list of the fields defined on the structure, in their order of
definition.

=cut

method fields
{
   $self->defined or croak $self->name . " is not yet defined";
   return @fields;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
