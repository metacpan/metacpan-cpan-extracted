#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2016 -- leonerd@leonerd.org.uk

package Tangence::Object;

use strict;
use warnings;

our $VERSION = '0.23';

use Carp;

use Tangence::Constants;

use Tangence::Types;

use Tangence::Class;

Tangence::Class->declare(
   __PACKAGE__,

   events => {
      destroy => {
         args => [],
      },
   },
);

=head1 NAME

C<Tangence::Object> - base class for accessible objects in a C<Tangence> server

=head1 DESCRIPTION

This class acts as a base class for the accessible objects in a L<Tangence>
server. All the objects actually created and made accessible to clients will
be subclasses of this one, including internally-created objects such as
L<Tangence::Registry>.

These objects are not directly constructed by calling the C<new> class method;
instead the C<Tangence::Registry> should be used to construct one.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   defined( my $id = delete $args{id} ) or croak "Need a id";
   my $registry = delete $args{registry} or croak "Need a registry";

   my $self = bless {
      id => $id,
      registry => $registry,
      meta => $args{meta} || Tangence::Class->for_perlname( $class ),

      event_subs => {},   # {$event} => [ @cbs ]

      properties => {}, # {$prop} => T:P::Instance struct
   }, $class;

   my $properties = $self->class->properties;
   foreach my $prop ( keys %$properties ) {
      my $meth = "new_prop_$prop";
      $self->$meth();
   }

   return $self;
}

=head1 METHODS

=cut

=head2 $obj->destroy

Requests that the object destroy itself, informing all clients that are aware
of it. Once they all report that they have dropped the object, the object is
deconstructed for real.

Not to be confused with Perl's own C<DESTROY> method.

=cut

sub destroy
{
   my $self = shift;
   my %args = @_;

   $self->{destroying} = 1;

   my $outstanding = 1;

   my $on_destroyed = $args{on_destroyed};

   my $incsub = sub {
      $outstanding++
   };

   my $decsub = sub {
      --$outstanding and return;
      $self->_destroy_really;
      $on_destroyed->() if $on_destroyed;
   };

   foreach my $cb ( @{ $self->{event_subs}->{destroy} } ) {
      $cb->( $self, $incsub, $decsub );
   }

   $decsub->();
}

sub _destroy_really
{
   my $self = shift;

   $self->registry->destroy_object( $self );

   undef %$self; # Now I am dead
   $self->{destroyed} = 1;
}

=head2 $id = $obj->id

Returns the object's C<Tangence> ID number

=cut

sub id
{
   my $self = shift;
   return $self->{id};
}

=head2 $description = $obj->describe

Returns a textual description of the object, for internal debugging purposes.
Subclasses are encouraged to override this method to return something more
descriptive within their domain of interest

=cut

sub describe
{
   my $self = shift;
   return ref $self;
}

=head2 $registry = $obj->registry

Returns the L<Tangence::Registry> that constructed this object.

=cut

sub registry
{
   my $self = shift;
   return $self->{registry};
}

sub smash
{
   my $self = shift;
   my ( $smashkeys ) = @_;

   return undef unless $smashkeys and @$smashkeys;

   my @keys;
   if( ref $smashkeys eq "HASH" ) {
      @keys = keys %$smashkeys;
   }
   else {
      @keys = @$smashkeys;
   }

   return { map {
      my $m = "get_prop_$_";
      $_ => $self->$m()
   } @keys };
}

=head2 $class = $obj->class

Returns the L<Tangence::Meta::Class> object representing the class of this
object.

=cut

sub class
{
   my $self = shift;
   return ref $self ? $self->{meta} : Tangence::Class->for_perlname( $self );
}

=head2 $method = $obj->can_method( $name )

Returns the L<Tangence::Meta::Method> object representing the named method, or
C<undef> if no such method exists.

=cut

sub can_method
{
   my $self = shift;
   return $self->class->method( @_ );
}

=head2 $event = $obj->can_event( $name )

Returns the L<Tangence::Meta::Event> object representing the named event, or
C<undef> if no such event exists.

=cut

sub can_event
{
   my $self = shift;
   return $self->class->event( @_ );
}

=head2 $property = $obj->can_property( $name )

Returns the L<Tangence::Meta::Property> object representing the named
property, or C<undef> if no such property exists.

=cut

sub can_property
{
   my $self = shift;
   return $self->class->property( @_ );
}

sub smashkeys
{
   my $self = shift;
   return $self->class->smashkeys;
}

=head2 $obj->fire_event( $event, @args )

Fires the named event on the object. Each event subscription function will be
invoked with the given arguments.

=cut

sub fire_event
{
   my $self = shift;
   my ( $event, @args ) = @_;

   $event eq "destroy" and croak "$self cannot fire destroy event directly";

   $self->can_event( $event ) or croak "$self has no event $event";

   my $sublist = $self->{event_subs}->{$event} or return;

   foreach my $cb ( @$sublist ) {
      $cb->( $self, @args );
   }
}

=head2 $id = $obj->subscribe_event( $event, $callback )

Subscribes an event-handling callback CODE ref to the named event. When the
event is fired by C<fire_event> this callback will be invoked, being passed
the object reference and the event's arguments.

 $callback->( $obj, @args )

Returns an opaque ID value that can be used to remove this subscription by
calling C<unsubscribe_event>.

=cut

sub subscribe_event
{
   my $self = shift;
   my ( $event, $callback ) = @_;

   $self->can_event( $event ) or croak "$self has no event $event";

   my $sublist = ( $self->{event_subs}->{$event} ||= [] );

   push @$sublist, $callback;

   my $ref = \@{$sublist}[$#$sublist];   # reference to last element
   return $ref + 0; # force numeric context
}

=head2 $obj->unsubscribe_event( $event, $id )

Removes an event-handling callback previously registered with
C<subscribe_event>.

=cut

sub unsubscribe_event
{
   my $self = shift;
   my ( $event, $id ) = @_;

   my $sublist = $self->{event_subs}->{$event} or return;

   my $index;
   for( $index = 0; $index < @$sublist; $index++ ) {
      last if \@{$sublist}[$index] + 0 == $id;
   }

   splice @$sublist, $index, 1, ();
}

=head2 $id = $obj->watch_property( $prop, %callbacks )

Watches a named property for changes, registering a set of callback functions
to be invoked when the property changes in certain ways. The set of callbacks
required depends on the dimension of the property being watched.

For all property types:

 $on_set->( $obj, $value )

For hash properties:

 $on_add->( $obj, $key, $value )
 $on_del->( $obj, $key )

For queue properties:

 $on_push->( $obj, @values )
 $on_shift->( $obj, $count )

For array properties:

 $on_push->( $obj, @values )
 $on_shift->( $obj, $count )
 $on_splice->( $obj, $index, $count, @values )
 $on_move->( $obj, $index, $delta )

For objset properties:

 $on_add->( $obj, $added_object )
 $on_del->( $obj, $deleted_object_id )

Alternatively, a single callback may be installed that is invoked after any
change of the property, being passed the new value entirely:

 $on_updated->( $obj, $value )

Returns an opaque ID value that can be used to remove this watch by calling
C<unwatch_property>.

=cut

sub watch_property
{
   my $self = shift;
   my ( $prop, %callbacks ) = @_;

   my $pdef = $self->can_property( $prop ) or croak "$self has no property $prop";

   my $callbacks = {};
   my $on_updated;

   if( $callbacks{on_updated} ) {
      $on_updated = delete $callbacks{on_updated};
      ref $on_updated eq "CODE" or croak "Expected 'on_updated' to be a CODE ref";
      keys %callbacks and croak "Expected no key other than 'on_updated'";
      $callbacks->{on_updated} = $on_updated;
   }
   else {
      foreach my $name ( @{ CHANGETYPES->{$pdef->dimension} } ) {
         ref( $callbacks->{$name} = delete $callbacks{$name} ) eq "CODE"
            or croak "Expected '$name' as a CODE ref";
      }
   }

   my $watchlist = $self->{properties}->{$prop}->callbacks;

   push @$watchlist, $callbacks;

   $on_updated->( $self, $self->{properties}->{$prop}->value ) if $on_updated;

   my $ref = \@{$watchlist}[$#$watchlist];  # reference to last element
   return $ref + 0; # force numeric context
}

=head2 $obj->unwatch_property( $prop, $id )

Removes the set of callback functions previously registered with
C<watch_property>.

=cut

sub unwatch_property
{
   my $self = shift;
   my ( $prop, $id ) = @_;

   my $watchlist = $self->{properties}->{$prop}->callbacks or return;

   my $index;
   for( $index = 0; $index < @$watchlist; $index++ ) {
      last if \@{$watchlist}[$index] + 0 == $id;
   }

   splice @$watchlist, $index, 1, ();
}

### Message handling

sub handle_request_CALL
{
   my $self = shift;
   my ( $ctx, $message ) = @_;

   my $method = $message->unpack_str();

   my $mdef = $self->can_method( $method ) or die "Object cannot respond to method $method\n";

   my $m = "method_$method";
   $self->can( $m ) or die "Object cannot run method $method\n";

   my @args = map { $_->unpack_value( $message ) } $mdef->argtypes;

   my $result = $self->$m( $ctx, @args );

   my $response = Tangence::Message->new( $ctx->stream, MSG_RESULT );
   $mdef->ret->pack_value( $response, $result ) if $mdef->ret;

   return $response;
}

sub generate_message_EVENT
{
   my $self = shift;
   my ( $conn, $event, @args ) = @_;

   my $edef = $self->can_event( $event ) or die "Object cannot respond to event $event";

   my $response = Tangence::Message->new( $conn, MSG_EVENT )
      ->pack_int( $self->id )
      ->pack_str( $event );

   my @argtypes = $edef->argtypes;
   $argtypes[$_]->pack_value( $response, $args[$_] ) for 0..$#argtypes;

   return $response;
}

sub handle_request_GETPROP
{
   my $self = shift;
   my ( $ctx, $message ) = @_;

   my $prop = $message->unpack_str();

   my $pdef = $self->can_property( $prop ) or die "Object does not have property $prop";

   my $m = "get_prop_$prop";
   $self->can( $m ) or die "Object cannot get property $prop\n";

   my $result = $self->$m();

   my $response = Tangence::Message->new( $ctx->stream, MSG_RESULT );
   $pdef->overall_type->pack_value( $response, $result );

   return $response;
}

sub handle_request_GETPROPELEM
{
   my $self = shift;
   my ( $ctx, $message ) = @_;

   my $prop = $message->unpack_str();

   my $pdef = $self->can_property( $prop ) or die "Object does not have property $prop";
   my $dim = $pdef->dimension;

   my $m = "get_prop_$prop";
   $self->can( $m ) or die "Object cannot get property $prop\n";

   my $result;
   if( $dim == DIM_QUEUE or $dim == DIM_ARRAY ) {
      my $idx = $message->unpack_int();
      $result = $self->$m()->[$idx];
   }
   elsif( $dim == DIM_HASH ) {
      my $key = $message->unpack_str();
      $result = $self->$m()->{$key};
   }
   else {
      die "Property $prop cannot fetch elements";
   }

   my $response = Tangence::Message->new( $ctx->stream, MSG_RESULT );
   $pdef->type->pack_value( $response, $result );

   return $response;
}

sub handle_request_SETPROP
{
   my $self = shift;
   my ( $ctx, $message ) = @_;

   my $prop  = $message->unpack_str();

   my $pdef = $self->can_property( $prop ) or die "Object does not have property $prop\n";

   my $value = $pdef->type->unpack_value( $message );

   my $m = "set_prop_$prop";
   $self->can( $m ) or die "Object cannot set property $prop\n";

   $self->$m( $value );

   return Tangence::Message->new( $self, MSG_OK );
}

sub generate_message_UPDATE
{
   my $self = shift;
   my ( $conn, $prop, $how, @args ) = @_;

   my $pdef = $self->can_property( $prop ) or die "Object does not have property $prop\n";
   my $dim = $pdef->dimension;

   my $message = Tangence::Message->new( $conn, MSG_UPDATE )
      ->pack_int( $self->id )
      ->pack_str( $prop );
   TYPE_U8->pack_value( $message, $how );

   my $dimname = DIMNAMES->[$dim];
   if( $how == CHANGE_SET ) {
      my ( $value ) = @args;
      $pdef->overall_type->pack_value( $message, $value );
   }
   elsif( my $code = $self->can( "_generate_message_UPDATE_$dimname" ) ) {
      $code->( $self, $message, $how, $pdef, @args );
   }
   else {
      croak "Unrecognised property dimension $dim for $prop";
   }

   return $message;
}

sub _generate_message_UPDATE_scalar
{
   my $self = shift;
   my ( $message, $how, $pdef, @args ) = @_;

   croak "Change type $how is not valid for a scalar property";
}

sub _generate_message_UPDATE_hash
{
   my $self = shift;
   my ( $message, $how, $pdef, @args ) = @_;

   if( $how == CHANGE_ADD ) {
      my ( $key, $value ) = @args;
      $message->pack_str( $key );
      $pdef->type->pack_value( $message, $value );
   }
   elsif( $how == CHANGE_DEL ) {
      my ( $key ) = @args;
      $message->pack_str( $key );
   }
   else {
      croak "Change type $how is not valid for a hash property";
   }
}

sub _generate_message_UPDATE_queue
{
   my $self = shift;
   my ( $message, $how, $pdef, @args ) = @_;

   if( $how == CHANGE_PUSH ) {
      $message->pack_all_sametype( $pdef->type, @args );
   }
   elsif( $how == CHANGE_SHIFT ) {
      my ( $count ) = @args;
      $message->pack_int( $count );
   }
   else {
      croak "Change type $how is not valid for a queue property";
   }
}

sub _generate_message_UPDATE_array
{
   my $self = shift;
   my ( $message, $how, $pdef, @args ) = @_;

   if( $how == CHANGE_PUSH ) {
      $message->pack_all_sametype( $pdef->type, @args );
   }
   elsif( $how == CHANGE_SHIFT ) {
      my ( $count ) = @args;
      $message->pack_int( $count );
   }
   elsif( $how == CHANGE_SPLICE ) {
      my ( $start, $count, @values ) = @args;
      $message->pack_int( $start );
      $message->pack_int( $count );
      $message->pack_all_sametype( $pdef->type, @values );
   }
   elsif( $how == CHANGE_MOVE ) {
      my ( $index, $delta ) = @args;
      $message->pack_int( $index );
      $message->pack_int( $delta );
   }
   else {
      croak "Change type $how is not valid for an array property";
   }
}

sub _generate_message_UPDATE_objset
{
   my $self = shift;
   my ( $message, $how, $pdef, @args ) = @_;

   if( $how == CHANGE_ADD ) {
      my ( $value ) = @args;
      $pdef->type->pack_value( $message, $value );
   }
   elsif( $how == CHANGE_DEL ) {
      my ( $id ) = @args;
      $message->pack_int( $id );
   }
   else {
      croak "Change type $how is not valid for an objset property";
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
