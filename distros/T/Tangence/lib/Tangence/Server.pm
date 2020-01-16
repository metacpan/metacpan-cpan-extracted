#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2020 -- leonerd@leonerd.org.uk

package Tangence::Server;

use strict;
use warnings;

use base qw( Tangence::Stream );

our $VERSION = '0.25';

use Carp;

use Scalar::Util qw( weaken );
use Sub::Util 1.40 qw( set_subname );

use Tangence::Constants;
use Tangence::Types;
use Tangence::Server::Context;

use Struct::Dumb;
struct CursorObject => [qw( cursor obj )];

# We will accept any version back to 3
use constant VERSION_MINOR_MIN => 3;

=head1 NAME

C<Tangence::Server> - mixin class for building a C<Tangence> server

=head1 SYNOPSIS

This class is a mixin, it cannot be directly constructed

 package Example::Server;
 use base qw( Base::Server Tangence::Server );

 sub new
 {
    my $class = shift;
    my %args = @_;

    my $registry = delete $args{registry};

    my $self = $class->SUPER::new( %args );

    $self->registry( $registry );

    return $self;
 }

 sub tangence_write
 {
    my $self = shift;
    $self->write( $_[0] );
 }

 sub on_read
 {
    my $self = shift;
    $self->tangence_readfrom( $_[0] );
 }

=head1 DESCRIPTION

This module provides mixin to implement a C<Tangence> server connection. It
should be mixed in to an object used to represent a single connection from a
client. It provides a location for the objects in server to store information
about the client connection, and coordinates passing messages between the
client and the objects in the server.

This is a subclass of L<Tangence::Stream> which provides implementations of
the required C<handle_request_> methods. A class mixing in C<Tangence::Server>
must still provide the C<write> method required for sending data to the
client.

For an example of a class that uses this mixin, see
L<Net::Async::Tangence::ServerProtocol>.

=cut

=head1 PROVIDED METHODS

The following methods are provided by this mixin.

=cut

sub subscriptions { shift->{subscriptions} ||= [] }
sub watches       { shift->{watches} ||= [] }

=head2 registry

   $server->registry( $registry )

   $registry = $server->registry

Accessor to set or obtain the L<Tangence::Registry> object for the server.

=cut

sub registry
{
   my $self = shift;
   $self->{registry} = shift if @_;
   return $self->{registry};
}

sub tangence_closed
{
   my $self = shift;
   $self->SUPER::tangence_closed;

   if( my $subscriptions = $self->subscriptions ) {
      foreach my $s ( @$subscriptions ) {
         my ( $object, $event, $id ) = @$s;
         $object->unsubscribe_event( $event, $id );
      }

      undef @$subscriptions;
   }

   if( my $watches = $self->watches ) {
      foreach my $w ( @$watches ) {
         my ( $object, $prop, $id ) = @$w;
         $object->unwatch_property( $prop, $id );
      }

      undef @$watches;
   }

   if( my $cursors = $self->peer_hascursor ) {
      foreach my $cursorobj ( values %$cursors ) {
         $self->drop_cursorobj( $cursorobj );
      }
   }
}

sub get_by_id
{
   my $self = shift;
   my ( $id ) = @_;

   # Only permit the client to interact with objects they've already been
   # sent, so they cannot gain access by inventing object IDs
   $self->peer_hasobj->{$id} or
      die "Access not allowed to object with id $id\n";

   my $obj = $self->registry->get_by_id( $id ) or
      die "No such object with id $id\n";

   return $obj;
}

sub handle_request_CALL
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $ctx = Tangence::Server::Context->new( $self, $token );

   my $response = eval {
      my $objid = $message->unpack_int();

      my $object = $self->get_by_id( $objid );

      $object->handle_request_CALL( $ctx, $message )
   };
   $@ and return $ctx->responderr( $@ );

   $ctx->respond( $response );
}

sub handle_request_SUBSCRIBE
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $ctx = Tangence::Server::Context->new( $self, $token );

   my $response = eval {
      my $objid = $message->unpack_int();
      my $event = $message->unpack_str();

      my $object = $self->get_by_id( $objid );

      weaken( my $weakself = $self );

      my $id = $object->subscribe_event( $event,
         set_subname "__SUBSCRIBE($event)__" => sub {
            $weakself or return;
            my $object = shift;

            my $message = $object->generate_message_EVENT( $weakself, $event, @_ );
            $weakself->request(
               request     => $message,
               on_response => sub { "IGNORE" },
            );
         }
      );

      push @{ $self->subscriptions }, [ $object, $event, $id ];

      Tangence::Message->new( $self, MSG_SUBSCRIBED )
   };
   $@ and return $ctx->responderr( $@ );

   $ctx->respond( $response );
}

sub handle_request_UNSUBSCRIBE
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $ctx = Tangence::Server::Context->new( $self, $token );

   my $response = eval {
      my $objid = $message->unpack_int();
      my $event = $message->unpack_str();

      my $object = $self->get_by_id( $objid );

      my $edef = $object->can_event( $event ) or
         die "Object cannot respond to event $event\n";

      # Delete from subscriptions and obtain id
      my $id;
      @{ $self->subscriptions } = grep { $_->[0] == $object and $_->[1] eq $event and ( $id = $_->[2], 0 ) or 1 }
                                     @{ $self->subscriptions };
      defined $id or
         die "Not subscribed to $event\n";

      $object->unsubscribe_event( $event, $id );

      Tangence::Message->new( $self, MSG_OK )
   };
   $@ and return $ctx->responderr( $@ );

   $ctx->respond( $response );
}

sub handle_request_GETPROP
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $ctx = Tangence::Server::Context->new( $self, $token );

   my $response = eval {
      my $objid = $message->unpack_int();

      my $object = $self->get_by_id( $objid );

      $object->handle_request_GETPROP( $ctx, $message )
   };
   $@ and return $ctx->responderr( $@ );

   $ctx->respond( $response );
}

sub handle_request_GETPROPELEM
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $ctx = Tangence::Server::Context->new( $self, $token );

   my $response = eval {
      my $objid = $message->unpack_int();

      my $object = $self->get_by_id( $objid );

      $object->handle_request_GETPROPELEM( $ctx, $message )
   };
   $@ and return $ctx->responderr( $@ );

   $ctx->respond( $response );
}

sub handle_request_SETPROP
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $ctx = Tangence::Server::Context->new( $self, $token );

   my $response = eval {
      my $objid = $message->unpack_int();

      my $object = $self->get_by_id( $objid );

      $object->handle_request_SETPROP( $ctx, $message )
   };
   $@ and return $ctx->responderr( $@ );

   $ctx->respond( $response );
}

*handle_request_WATCH      = \&_handle_request_WATCHany;
*handle_request_WATCH_CUSR = \&_handle_request_WATCHany;
sub _handle_request_WATCHany
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $ctx = Tangence::Server::Context->new( $self, $token );

   my ( $want_initial, $object, $prop );

   my $response = eval {
      my $objid = $message->unpack_int();
      $prop     = $message->unpack_str();

      $object = $self->get_by_id( $objid );

      my $pdef = $object->can_property( $prop ) or
         die "Object does not have property $prop\n";

      $self->_install_watch( $object, $prop );

      if( $message->code == MSG_WATCH ) {
         $want_initial = $message->unpack_bool();

         Tangence::Message->new( $self, MSG_WATCHING )
      }
      elsif( $message->code == MSG_WATCH_CUSR ) {
         my $from = $message->unpack_int();

         my $m = "cursor_prop_$prop";
         my $cursor = $object->$m( $from );
         my $id = $self->message_state->{next_cursorid}++;

         $self->peer_hascursor->{$id} = CursorObject( $cursor, $object );
         Tangence::Message->new( $self, MSG_WATCHING_CUSR )
            ->pack_int( $id )
            ->pack_int( 0 ) # first index
            ->pack_int( $#{ $object->${\"get_prop_$prop"} } ) # last index
      }
   };
   $@ and return $ctx->responderr( $@ );

   $ctx->respond( $response );

   $self->_send_initial( $object, $prop ) if $want_initial;
}

sub _send_initial
{
   my $self = shift;
   my ( $object, $prop ) = @_;

   my $m = "get_prop_$prop";
   return unless( $object->can( $m ) );

   eval {
      my $value = $object->$m();
      my $message = $object->generate_message_UPDATE( $self, $prop, CHANGE_SET, $value );
      $self->request(
         request     => $message,
         on_response => sub { "IGNORE" },
      );
   };
   warn "$@ during initial property fetch" if $@;
}

sub handle_request_UNWATCH
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $ctx = Tangence::Server::Context->new( $self, $token );

   my $response = eval {
      my $objid = $message->unpack_int();
      my $prop  = $message->unpack_str();

      my $object = $self->get_by_id( $objid );

      my $pdef = $object->can_property( $prop ) or
         die "Object does not have property $prop\n";

      # Delete from watches and obtain id
      my $id;
      @{ $self->watches } = grep { $_->[0] == $object and $_->[1] eq $prop and ( $id = $_->[2], 0 ) or 1 }
                            @{ $self->watches };
      defined $id or
         die "Not watching $prop\n";

      $object->unwatch_property( $prop, $id );

      Tangence::Message->new( $self, MSG_OK );
   };
   $@ and return $ctx->responderr( $@ );

   $ctx->respond( $response );
}

sub handle_request_CUSR_NEXT
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $cursor_id = $message->unpack_int();

   my $ctx = Tangence::Server::Context->new( $self, $token );

   my $cursorobj = $self->peer_hascursor->{$cursor_id} or
      return $ctx->responderr( "No such cursor with id $cursor_id" );

   $cursorobj->cursor->handle_request_CUSR_NEXT( $ctx, $message );
}

sub handle_request_CUSR_DESTROY
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $cursor_id = $message->unpack_int();

   my $ctx = Tangence::Server::Context->new( $self, $token );

   my $cursorobj = delete $self->peer_hascursor->{$cursor_id};
   $self->drop_cursorobj( $cursorobj );

   $ctx->respond( Tangence::Message->new( $self, MSG_OK ) );
}

sub drop_cursorobj
{
   my $self = shift;
   my ( $cursorobj ) = @_;

   my $m = "uncursor_prop_" . $cursorobj->cursor->prop->name;
   $cursorobj->obj->$m( $cursorobj->cursor );
}

sub handle_request_INIT
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $major = $message->unpack_int();
   my $minor_max = $message->unpack_int();
   my $minor_min = $message->unpack_int();

   my $ctx = Tangence::Server::Context->new( $self, $token );

   if( $major != VERSION_MAJOR ) {
      return $ctx->responderr( "Major version $major not available" );
   }

   # Don't accept higher than the minor version we recognise
   $minor_max = VERSION_MINOR if $minor_max > VERSION_MINOR;
   $minor_min = VERSION_MINOR_MIN if $minor_min < VERSION_MINOR_MIN;

   if( $minor_max < $minor_min ) {
      return $ctx->responderr( "No suitable minor version available" );
   }

   # For unit tests or other synchronous cases, we need to set the version
   # -before- we send the message. But we'd better construct the response
   # message before setting the version, in case it makes a difference.
   my $response = Tangence::Message->new( $self, MSG_INITED )
      ->pack_int( $major )
      ->pack_int( $minor_max );

   $self->minor_version( $minor_max );

   $ctx->respond( $response );
}

sub handle_request_GETROOT
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $identity = TYPE_ANY->unpack_value( $message );

   my $ctx = Tangence::Server::Context->new( $self, $token );

   $self->identity( $identity );

   my $root = $self->rootobj( $identity );

   my $response = Tangence::Message->new( $self, MSG_RESULT );
   TYPE_OBJ->pack_value( $response, $root );

   $ctx->respond( $response );
}

sub handle_request_GETREGISTRY
{
   my $self = shift;
   my ( $token ) = @_;

   my $ctx = Tangence::Server::Context->new( $self, $token );

   $self->permit_registry or
      return $ctx->responderr( "This client is not permitted access to the registry" );

   my $response = Tangence::Message->new( $self, MSG_RESULT );
   TYPE_OBJ->pack_value( $response, $self->registry );

   $ctx->respond( $response );
}

my %change_values = (
   on_set    => CHANGE_SET,
   on_add    => CHANGE_ADD,
   on_del    => CHANGE_DEL,
   on_push   => CHANGE_PUSH,
   on_shift  => CHANGE_SHIFT,
   on_splice => CHANGE_SPLICE,
   on_move   => CHANGE_MOVE,
);

sub _install_watch
{
   my $self = shift;
   my ( $object, $prop ) = @_;

   my $pdef = $object->can_property( $prop );
   my $dim = $pdef->dimension;

   weaken( my $weakself = $self );

   my %callbacks;
   foreach my $name ( @{ CHANGETYPES->{$dim} } ) {
      my $how = $change_values{$name};
      $callbacks{$name} = set_subname "__WATCH($prop:$name)__" => sub {
         $weakself or return;
         my $object = shift;

         my $message = $object->generate_message_UPDATE( $weakself, $prop, $how, @_ );
         $weakself->request(
            request     => $message,
            on_response => sub { "IGNORE" },
         );
      };
   }

   my $id = $object->watch_property( $prop, %callbacks );

   push @{ $self->watches }, [ $object, $prop, $id ];
}

sub object_destroyed
{
   my $self = shift;
   my ( $obj ) = @_;

   if( my $subs = $self->subscriptions ) {
      my $i = 0;
      while( $i < @$subs ) {
         my $s = $subs->[$i];

         $i++, next unless $s->[0] == $obj;

         my ( undef, $event, $id ) = @$s;
         $obj->unsubscribe_event( $event, $id );

         splice @$subs, $i, 1;
         # No $i++
      }
   }

   if( my $watches = $self->watches ) {
      my $i = 0;
      while( $i < @$watches ) {
         my $w = $watches->[$i];

         $i++, next unless $w->[0] == $obj;

         my ( undef, $prop, $id ) = @$w;
         $obj->unwatch_property( $prop, $id );

         splice @$watches, $i, 1;
         # No $i++
      }
   }

   $self->SUPER::object_destroyed( @_ );
}

=head1 OVERRIDEABLE METHODS

The following methods are provided but intended to be overridden if the
implementing class wishes to provide different behaviour from the default.

=cut

=head2 rootobj

   $rootobj = $server->rootobj( $identity )

Invoked when a C<GETROOT> message is received from the client, this method
should return a L<Tangence::Object> as root object for the connection.

The default implementation will return the object with ID 1; i.e. the first
object created in the registry.

=cut

sub rootobj
{
   my $self = shift;

   return $self->registry->get_by_id( 1 );
}

=head2 permit_registry

   $allow = $server->permit_registry

Invoked when a C<GETREGISTRY> message is received from the client, this method
should return a boolean to indicate whether the client is allowed to access
the object registry.

The default implementation always permits this, but an overridden method may
decide to disallow it in some situations. When disabled, a client will not be
able to gain access to any serverside objects other than the root object, and
(recursively) any other objects returned by methods, events or properties on
objects already known. This can be used as a security mechanism.

=cut

sub permit_registry { 1; }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
