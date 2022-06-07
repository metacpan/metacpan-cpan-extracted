#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.57;

package Tangence::Registry 0.29;
class Tangence::Registry :isa(Tangence::Object);

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

=head2 new

   $registry = Tangence::Registry->new

Returns a new instance of a C<Tangence::Registry> object. An entire server
requires one registry object; it will be shared among all the client
connections to that server.

=cut

sub BUILDARGS ( $class, %args )
{
   return (
      id => 0,
      registry => "BOOTSTRAP",
      meta => Tangence::Class->for_perlname( $class ),
      %args,
   );
}

has $_nextid = 1;
has @_freeids;
has %_objects;

ADJUST
{
   my $id = 0;
   weaken( $self->{registry} = $self );

   %_objects = ( $id => $self );
   weaken( $_objects{$id} );
   $self->add_prop_objects( $id => $self->describe );
}

ADJUSTPARAMS ( $params )
{
   $self->load_tanfile( delete $params->{tanfile} );
}

=head1 METHODS

=cut

=head2 get_by_id

   $obj = $registry->get_by_id( $id )

Returns the object with the given object ID.

This method is exposed to clients.

=cut

method get_by_id ( $id )
{
   return $_objects{$id};
}

method method_get_by_id ( $ctx, $id )
{
   return $self->get_by_id( $id );
}

=head2 construct

   $obj = $registry->construct( $type, @args )

Constructs a new exposed object of the given type, and returns it. Any
additional arguments are passed to the object's constructor.

=cut

method construct ( $type, @args )
{
   my $id = shift @_freeids // ( $_nextid++ );

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

   weaken( $_objects{$id} = $obj );
   $self->add_prop_objects( $id => $obj->describe );

   return $obj;
}

method destroy_object ( $obj )
{
   my $id = $obj->id;

   exists $_objects{$id} or croak "Cannot destroy ID $id - does not exist";

   $self->del_prop_objects( $id );

   $self->fire_event( "object_destroyed", $id );

   push @_freeids, $id; # Recycle the ID
}

=head2 load_tanfile

   $registry->load_tanfile( $tanfile )

Loads additional Tangence class and struct definitions from the given F<.tan>
file.

=cut

method load_tanfile ( $tanfile )
{
   # Merely constructing this has the side-effect of declaring all the classes
   Tangence::Registry::Parser->new->from_file( $tanfile );
}

class Tangence::Registry::Parser :isa(Tangence::Compiler::Parser)
{
   method make_class
   {
      return Tangence::Class->make( @_ );
   }

   method make_struct
   {
      return Tangence::Struct->make( @_ );
   }

   method make_property
   {
      return Tangence::Property->new( @_ );
   }

   method make_type
   {
      return Tangence::Type->make( @_ );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
