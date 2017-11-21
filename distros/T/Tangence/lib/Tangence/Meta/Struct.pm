#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012 -- leonerd@leonerd.org.uk

package Tangence::Meta::Struct;

use strict;
use warnings;

use Carp;

our $VERSION = '0.24';

=head1 NAME

C<Tangence::Meta::Struct> - structure representing one C<Tangence> structure
type

=head1 DESCRIPTION

This data structure stores information about one L<Tangence> structure type.
Once constructed and defined, such objects are immutable.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $struct = Tangence::Meta::Struct->new( name => $name )

Returns a new instance representing the given name.

=cut

sub new
{
   my $class = shift;
   my %args = @_;
   my $self = bless { name => delete $args{name} }, $class;
   return $self;
}

=head2 $struct->define( %args )

Provides a definition for the structure.

=over 8

=item fields => ARRAY

ARRAY reference containing metadata about the structure's fields, as instances
of L<Tangence::Meta::Field>.

=back

=cut

sub define
{
   my $self = shift;
   my %args = @_;

   $self->defined and croak "Cannot define ".$self->name." twice";

   $self->{fields} = $args{fields};
}

=head1 ACCESSORS

=cut

=head2 $defined = $struct->defined

Returns true if a definition of the structure has been provided using
C<define>.

=cut

sub defined
{
   my $self = shift;
   return exists $self->{fields};
}

=head2 $name = $struct->name

Returns the name of the structure

=cut

sub name
{
   my $self = shift;
   return $self->{name};
}

=head2 @fields = $struct->fields

Returns a list of the fields defined on the structure, in their order of
definition.

=cut

sub fields
{
   my $self = shift;
   $self->defined or croak $self->name . " is not yet defined";
   return @{ $self->{fields} };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
