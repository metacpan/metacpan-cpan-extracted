#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2014 -- leonerd@leonerd.org.uk

package Tangence::Registry;

use strict;
use warnings;
use base qw( Tangence::Object );

our $VERSION = '0.24';

use Carp;

use Tangence::Constants;
use Tangence::Class;
use Tangence::Property;
use Tangence::Struct;
use Tangence::Type;

use Tangence::Compiler::Parser;

use Scalar::Util qw( weaken );

Tangence::Class->declare(
   __PACKAGE__,

   methods => {
      get_by_id => {
         args => [ [ id => 'int' ] ],
         ret  => 'obj',
      },
   },

   events => {
      object_constructed => {
         args => [ [ id => 'int' ] ],
      },
      object_destroyed => {
         args => [ [ id => 'int' ] ],
      },
   },

   props => {
      objects => {
         dim  => DIM_HASH,
         type => 'str',
      }
   },
);

=head1 NAME

C<Tangence::Registry> - object manager for a C<Tangence> server

=head1 DESCRIPTION

This subclass of L<Tangence::Object> acts as a container for all the exposed
objects in a L<Tangence> server. The registry is used to create exposed
objects, and manages their lifetime. It maintains a reference to all the
objects it creates, so it can dispatch incoming messages from clients to them.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $registry = Tangence::Registry->new

Returns a new instance of a C<Tangence::Registry> object. An entire server
requires one registry object; it will be shared among all the client
connections to that server.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $tanfile = $args{tanfile};
   croak "Expected 'tanfile'" unless defined $tanfile;

   my $id = 0;

   my $self = $class->SUPER::new(
      id => $id,
      registry => "BOOTSTRAP",
      meta => Tangence::Class->for_perlname( $class ),
   );
   weaken( $self->{registry} = $self );

   $self->{objects} = { $id => $self };
   weaken( $self->{objects}{$id} );
   $self->add_prop_objects( $id => $self->describe );

   $self->{nextid}  = 1;
   $self->{freeids} = []; # free'd ids we can reuse

   $self->load_tanfile( $tanfile );

   return $self;
}

=head1 METHODS

=cut

=head2 $obj = $registry->get_by_id( $id )

Returns the object with the given object ID.

This method is exposed to clients.

=cut

sub get_by_id
{
   my $self = shift;
   my ( $id ) = @_;

   return $self->{objects}->{$id};
}

sub method_get_by_id
{
   my $self = shift;
   my ( $ctx, $id ) = @_;
   return $self->get_by_id( $id );
}

=head2 $obj = $registry->construct( $type, @args )

Constructs a new exposed object of the given type, and returns it. Any
additional arguments are passed to the object's constructor.

=cut

sub construct
{
   my $self = shift;
   my ( $type, @args ) = @_;

   my $id = shift @{ $self->{freeids} } || ( $self->{nextid}++ );

   Tangence::Class->for_perlname( $type ) or
      croak "Registry cannot construct a '$type' as no class definition exists";

   eval { $type->can( "new" ) } or
      croak "Registry cannot construct a '$type' as it has no ->new() method";

   my $obj = $type->new(
      registry => $self,
      id       => $id,
      @args
   );

   $self->fire_event( "object_constructed", $id );

   weaken( $self->{objects}->{$id} = $obj );
   $self->add_prop_objects( $id => $obj->describe );

   return $obj;
}

sub destroy_object
{
   my $self = shift;
   my ( $obj ) = @_;

   my $id = $obj->id;

   exists $self->{objects}->{$id} or croak "Cannot destroy ID $id - does not exist";

   $self->del_prop_objects( $id );

   $self->fire_event( "object_destroyed", $id );

   push @{ $self->{freeids} }, $id; # Recycle the ID
}

=head2 $registry->load_tanfile( $tanfile )

Loads additional Tangence class and struct definitions from the given F<.tan>
file.

=cut

sub load_tanfile
{
   my $self = shift;
   my ( $tanfile ) = @_;

   # Merely constructing this has the side-effect of declaring all the classes
   Tangence::Registry::Parser->new->from_file( $tanfile );
}

package # hide from CPAN
   Tangence::Registry::Parser;
use base qw( Tangence::Compiler::Parser );

sub make_class
{
   my $self = shift;
   return Tangence::Class->new( @_ );
}

sub make_struct
{
   my $self = shift;
   return Tangence::Struct->new( @_ );
}

sub make_property
{
   my $self = shift;
   return Tangence::Property->new( @_ );
}

sub make_type
{
   my $self = shift;
   return Tangence::Type->new( @_ );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
