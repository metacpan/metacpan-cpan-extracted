#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2017 -- leonerd@leonerd.org.uk

package Tangence::Meta::Field;

use strict;
use warnings;

our $VERSION = '0.25';

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

sub new
{
   my $class = shift;
   my %args = @_;
   bless \%args, $class;
}

=head1 ACCESSORS

=cut

=head2 name

   $name = $field->name

Returns the name of the field

=cut

sub name
{
   my $self = shift;
   return $self->{name};
}

=head2 type

   $type = $field->type

Return the type as a L<Tangence::Meta::Type> reference.

=cut

sub type
{
   my $self = shift;
   return $self->{type};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
