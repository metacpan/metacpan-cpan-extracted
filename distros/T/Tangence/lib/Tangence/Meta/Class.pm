#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2013 -- leonerd@leonerd.org.uk

package Tangence::Meta::Class;

use strict;
use warnings;

use Carp;

our $VERSION = '0.23';

=head1 NAME

C<Tangence::Meta::Class> - structure representing one C<Tangence> class

=head1 DESCRIPTION

This data structure object stores information about one L<Tangence> class.
Once constructed and defined, such objects are immutable.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $class = Tangence::Meta::Class->new( name => $name )

Returns a new instance representing the given name.

=cut

sub new
{
   my $class = shift;
   my %args = @_;
   my $self = bless { name => delete $args{name} }, $class;
   return $self;
}

=head2 $class->define( %args )

Provides a definition for the class.

=over 8

=item methods => HASH

=item events => HASH

=item properties => HASH

Optional HASH references containing metadata about methods, events and
properties, as instances of L<Tangence::Meta::Method>,
L<Tangence::Meta::Event> or L<Tangence::Meta::Property>.

=item superclasses => ARRAY

Optional ARRAY reference containing superclasses as
C<Tangence::Meta::Class> references.

=back

=cut

sub define
{
   my $self = shift;
   my %args = @_;

   $self->defined and croak "Cannot define ".$self->name." twice";

   $args{superclasses} ||= [];
   $args{methods}      ||= {};
   $args{events}       ||= {};
   $args{properties}   ||= {};
   $self->{$_} = $args{$_} for keys %args;
}

=head1 ACCESSORS

=cut

=head2 $defined = $class->defined

Returns true if a definintion for the class has been provided using C<define>.

=cut

sub defined
{
   my $self = shift;
   return exists $self->{superclasses};
}

=head2 $name = $class->name

Returns the name of the class

=cut

sub name
{
   my $self = shift;
   return $self->{name};
}

=head2 $perlname = $class->perlname

Returns the perl name of the class. This will be the Tangence name, with dots
replaced by double colons (C<::>).

=cut

sub perlname
{
   my $self = shift;
   ( my $perlname = $self->name ) =~ s{\.}{::}g; # s///rg in 5.14
   return $perlname;
}

=head2 @superclasses = $class->direct_superclasses

Return the direct superclasses in a list of C<Tangence::Meta::Class>
references.

=cut

sub direct_superclasses
{
   my $self = shift;
   $self->defined or croak $self->name . " is not yet defined";
   return @{ $self->{superclasses} };
}

=head2 $methods = $class->direct_methods

Return the methods that this class directly defines (rather than inheriting
from superclasses) as a HASH reference mapping names to
L<Tangence::Meta::Method> instances.

=cut

sub direct_methods
{
   my $self = shift;
   $self->defined or croak $self->name . " is not yet defined";
   return $self->{methods};
}

=head2 $events = $class->direct_events

Return the events that this class directly defines (rather than inheriting
from superclasses) as a HASH reference mapping names to
L<Tangence::Meta::Event> instances.

=cut

sub direct_events
{
   my $self = shift;
   $self->defined or croak $self->name . " is not yet defined";
   return $self->{events};
}

=head2 $properties = $class->direct_properties

Return the properties that this class directly defines (rather than inheriting
from superclasses) as a HASH reference mapping names to
L<Tangence::Meta::Property> instances.

=cut

sub direct_properties
{
   my $self = shift;
   $self->defined or croak $self->name . " is not yet defined";
   return $self->{properties};
}

=head1 AGGREGATE ACCESSORS

The following accessors inspect the full inheritance tree of this class and
all its superclasses

=cut

=head2 @superclasses = $class->superclasses

Return all the superclasses in a list of unique C<Tangence::Meta::Class>
references.

=cut

sub superclasses
{
   my $self = shift;
   # This algorithm doesn't have to be particularly good, C3 or whatever.
   # We're not really forming a search order, mearly uniq'ifying
   my %seen;
   return grep { !$seen{$_}++ } map { $_, $_->superclasses } $self->direct_superclasses;
}

=head2 $methods = $class->methods

Return all the methods available to this class as a HASH reference mapping
names to L<Tangence::Meta::Method> instances.

=cut

sub methods
{
   my $self = shift;
   my %methods;
   foreach ( $self, $self->superclasses ) {
      my $m = $_->direct_methods;
      $methods{$_} ||= $m->{$_} for keys %$m;
   }
   return \%methods;
}

=head2 $method = $class->method( $name )

Return the named method as a L<Tangence::Meta::Method> instance, or C<undef>
if no such method exists.

=cut

sub method
{
   my $self = shift;
   my ( $name ) = @_;
   return $self->methods->{$name};
}

=head2 $events = $class->events

Return all the events available to this class as a HASH reference mapping
names to L<Tangence::Meta::Event> instances.

=cut

sub events
{
   my $self = shift;
   my %events;
   foreach ( $self, $self->superclasses ) {
      my $e = $_->direct_events;
      $events{$_} ||= $e->{$_} for keys %$e;
   }
   return \%events;
}

=head2 $event = $class->event( $name )

Return the named event as a L<Tangence::Meta::Event> instance, or C<undef> if
no such event exists.

=cut

sub event
{
   my $self = shift;
   my ( $name ) = @_;
   return $self->events->{$name};
}

=head2 $properties = $class->properties

Return all the properties available to this class as a HASH reference mapping
names to L<Tangence::Meta::Property> instances.

=cut

sub properties
{
   my $self = shift;
   my %properties;
   foreach ( $self, $self->superclasses ) {
      my $p = $_->direct_properties;
      $properties{$_} ||= $p->{$_} for keys %$p;
   }
   return \%properties;
}

=head2 $property = $class->property( $name )

Return the named property as a L<Tangence::Meta::Property> instance, or
C<undef> if no such property exists.

=cut

sub property
{
   my $self = shift;
   my ( $name ) = @_;
   return $self->properties->{$name};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
