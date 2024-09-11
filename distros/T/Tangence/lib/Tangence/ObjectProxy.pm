#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Tangence::ObjectProxy 0.33;
class Tangence::ObjectProxy;

use Carp;

use Syntax::Keyword::Match 0.06;

use Future::AsyncAwait;
use Future::Exception;

use Tangence::Constants;

use Tangence::Types;

use Scalar::Util qw( weaken );

=head1 NAME

C<Tangence::ObjectProxy> - proxy for a C<Tangence> object in a
C<Tangence::Client>

=head1 DESCRIPTION

Instances in this class act as a proxy for an object in the
L<Tangence::Server>, allowing methods to be called, events to be subscribed
to, and properties to be watched.

These objects are not directly constructed by calling the C<new> class method;
instead they are returned by methods on L<Tangence::Client>, or by methods on
other C<Tangence::ObjectProxy> instances. Ultimately every object proxy that a
client uses will come from either the proxy to the registry, or the root
object.

=cut

field $_client :param :weak :reader;
field $_id     :param       :reader;
field $_class  :param       :reader;

field $_destroyed;

field %_subscriptions;
field %_props;

method destroy
{
   $_destroyed = 1;

   foreach my $cb ( @{ $_subscriptions{destroy} } ) {
      $cb->();
   }
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

use overload '""' => \&STRING;

method STRING
{
   return "Tangence::ObjectProxy[id=$_id]";
}

=head2 id

   $id = $proxy->id;

Returns the object ID for the C<Tangence> object being proxied for.

=cut

# generated accessor

=head2 classname

   $classname = $proxy->classname;

Returns the name of the class of the C<Tangence> object being proxied for.

=cut

method classname
{
   return $_class->name;
}

=head2 class

   $class = $proxyobj->class;

Returns the L<Tangence::Meta::Class> object representing the class of this
object.

=cut

# generated accessor

=head2 can_method

   $method = $proxy->can_method( $name );

Returns the L<Tangence::Meta::Method> object representing the named method, or
C<undef> if no such method exists.

=cut

method can_method
{
   return $_class->method( @_ );
}

=head2 can_event

   $event = $proxy->can_event( $name );

Returns the L<Tangence::Meta::Event> object representing the named event, or
C<undef> if no such event exists.

=cut

method can_event
{
   return $_class->event( @_ );
}

=head2 can_property

   $property = $proxy->can_property( $name );

Returns the L<Tangence::Meta::Property> object representing the named
property, or C<undef> if no such property exists.

=cut

method can_property
{
   return $_class->property( @_ );
}

# Don't want to call it "isa"
method proxy_isa
{
   if( @_ ) {
      my ( $class ) = @_;
      return !! grep { $_->name eq $class } $_class, $_class->superclasses;
   }
   else {
      return $_class, $_class->superclasses
   }
}

method grab ( $smashdata )
{
   foreach my $property ( keys %{ $smashdata } ) {
      my $value = $smashdata->{$property};
      my $dim = $self->can_property( $property )->dimension;

      if( $dim == DIM_OBJSET ) {
         # Comes across in a LIST. We need to map id => obj
         $value = { map { $_->id => $_ } @$value };
      }

      my $prop = $_props{$property} ||= {};
      $prop->{cache} = $value;
   }
}

=head2 call_method

   $result = await $proxy->call_method( $mname, @args );

Calls the given method on the server object, passing in the given arguments.
Returns a L<Future> that will yield the method's result.

=cut

async method call_method ( $method, @args )
{
   # Detect void-context legacy uses
   defined wantarray or
      croak "->call_method in void context no longer useful - it now returns a Future";

   my $mdef = $self->can_method( $method )
      or croak "Class ".$self->classname." does not have a method $method";

   my $request = Tangence::Message->new( $_client, MSG_CALL )
         ->pack_int( $self->id )
         ->pack_str( $method );

   my @argtypes = $mdef->argtypes;
   $argtypes[$_]->pack_value( $request, $args[$_] ) for 0..$#argtypes;

   my $message = await $_client->request( request => $request );

   my $code = $message->code;

   if( $code == MSG_RESULT ) {
      my $result = $mdef->ret ? $mdef->ret->unpack_value( $message )
                              : undef;
      return $result;
   }
   else {
      Future::Exception->throw( "Unexpected response code $code", tangence => );
   }
}

=head2 subscribe_event

   await $proxy->subscribe_event( $event, %callbacks );

Subscribes to the given event on the server object, installing a callback
function which will be invoked whenever the event is fired.

Takes the following named callbacks:

=over 8

=item on_fire => CODE

Callback function to invoke whenever the event is fired

   $on_fire->( @args );

The returned C<Future> it is guaranteed to be completed before any invocation
of the C<on_fire> event handler.

=back

=cut

async method subscribe_event ( $event, %args )
{
   # Detect void-context legacy uses
   defined wantarray or
      croak "->subscribe_event in void context no longer useful - it now returns a Future";

   ref( my $callback = delete $args{on_fire} ) eq "CODE"
      or croak "Expected 'on_fire' as a CODE ref";

   $self->can_event( $event )
      or croak "Class ".$self->classname." does not have an event $event";

   if( my $cbs = $_subscriptions{$event} ) {
      push @$cbs, $callback;
      return;
   }

   my @cbs = ( $callback );
   $_subscriptions{$event} = \@cbs;

   return if $event eq "destroy"; # This is automatically handled

   my $message = await $_client->request(
      request => Tangence::Message->new( $_client, MSG_SUBSCRIBE )
         ->pack_int( $self->id )
         ->pack_str( $event )
   );

   my $code = $message->code;

   if( $code == MSG_SUBSCRIBED ) {
      return;
   }
   else {
      Future::Exception->throw( "Unexpected response code $code", tangence => );
   }
}

method handle_request_EVENT ( $message )
{
   my $event = $message->unpack_str();
   my $edef = $self->can_event( $event ) or return;

   my @args = map { $_->unpack_value( $message ) } $edef->argtypes;

   if( my $cbs = $_subscriptions{$event} ) {
      foreach my $cb ( @$cbs ) { $cb->( @args ) }
   }
}

=head2 unsubscribe_event

   $proxy->unsubscribe_event( $event );

Removes an event subscription on the given event on the server object that was
previously installed using C<subscribe_event>.

=cut

method unsubscribe_event ( $event )
{
   $self->can_event( $event )
      or croak "Class ".$self->classname." does not have an event $event";

   return if $event eq "destroy"; # This is automatically handled

   $_client->request(
      request => Tangence::Message->new( $_client, MSG_UNSUBSCRIBE )
         ->pack_int( $self->id )
         ->pack_str( $event ),

      on_response => sub {},
   );
}

=head2 get_property

   await $value = $proxy->get_property( $prop );

Requests the current value of the property from the server object.

=cut

async method get_property ( $property )
{
   # Detect void-context legacy uses
   defined wantarray or
      croak "->get_property in void context no longer useful - it now returns a Future";

   my $pdef = $self->can_property( $property )
      or croak "Class ".$self->classname." does not have a property $property";

   my $message = await $_client->request(
      request => Tangence::Message->new( $_client, MSG_GETPROP )
         ->pack_int( $self->id )
         ->pack_str( $property ),
   );

   my $code = $message->code;

   if( $code == MSG_RESULT ) {
      return $pdef->overall_type->unpack_value( $message );
   }
   else {
      Future::Exception->throw( "Unexpected response code $code", tangence => );
   }
}

=head2 get_property_element

   await $value = $proxy->get_property_element( $property, $index_or_key );

Requests the current value of an element of the property from the server
object.

=cut

async method get_property_element ( $property, $index_or_key )
{
   # Detect void-context legacy uses
   defined wantarray or
      croak "->get_property_element in void context no longer useful - it now returns a Future";

   my $pdef = $self->can_property( $property )
      or croak "Class ".$self->classname." does not have a property $property";

   my $request = Tangence::Message->new( $_client, MSG_GETPROPELEM )
      ->pack_int( $self->id )
      ->pack_str( $property );

   match( $pdef->dimension : == ) {
      case( DIM_HASH ) {
         $request->pack_str( $index_or_key );
      }
      case( DIM_ARRAY ), case( DIM_QUEUE ) {
         $request->pack_int( $index_or_key );
      }
      default {
         croak "Cannot get_property_element of a non hash, array or queue";
      }
   }

   my $message = await $_client->request(
      request => $request,
   );

   my $code = $message->code;

   if( $code == MSG_RESULT ) {
      return $pdef->type->unpack_value( $message );
   }
   else {
      Future::Exception->throw( "Unexpected response code $code", tangence => );
   }
}

=head2 prop

   $value = $proxy->prop( $property );

Returns the locally-cached value of a smashed property. If the named property
is not a smashed property, an exception is thrown.

=cut

method prop ( $property )
{
   if( exists $_props{$property}->{cache} ) {
      return $_props{$property}->{cache};
   }

   croak "$self does not have a cached property '$property'";
}

=head2 set_property

   await $proxy->set_property( $prop, $value );

Sets the value of the property in the server object.

=cut

async method set_property ( $property, $value )
{
   # Detect void-context legacy uses
   defined wantarray or
      croak "->set_property in void context no longer useful - it now returns a Future";

   my $pdef = $self->can_property( $property )
      or croak "Class ".$self->classname." does not have a property $property";

   my $request = Tangence::Message->new( $_client, MSG_SETPROP )
         ->pack_int( $self->id )
         ->pack_str( $property );
   $pdef->overall_type->pack_value( $request, $value );

   my $message = await $_client->request(
      request => $request,
   );

   my $code = $message->code;

   if( $code == MSG_OK ) {
      return;
   }
   else {
      Future::Exception->throw( "Unexpected response code $code", tangence => );
   }
}

=head2 watch_property

   await $proxy->watch_property( $property, %callbacks );

=head2 watch_property_with_initial

   await $proxy->watch_property_with_initial( $property, %callbacks );

Watches the given property on the server object, installing callback functions
which will be invoked whenever the property value changes. The latter form
additionally ensures that the server will send the current value of the
property as an initial update to the C<on_set> event, atomically when it
installs the update watches.

Takes the following named arguments:

=over 8

=item on_updated => CODE

Optional. Callback function to invoke whenever the property value changes.

   $on_updated->( $new_value );

If not provided, then individual handlers for individual change types must be
provided.

=back

The set of callback functions that are required depends on the type of the
property. These are documented in the C<watch_property> method of
L<Tangence::Object>.

=cut

sub _watchcbs_from_args ( $pdef, %args )
{
   my $callbacks = {};
   my $on_updated = delete $args{on_updated};
   if( $on_updated ) {
      ref $on_updated eq "CODE" or croak "Expected 'on_updated' to be a CODE ref";
      $callbacks->{on_updated} = $on_updated;
   }

   foreach my $name ( @{ CHANGETYPES->{$pdef->dimension} } ) {
      # All of these become optional if 'on_updated' is supplied
      next if $on_updated and not exists $args{$name};

      ref( $callbacks->{$name} = delete $args{$name} ) eq "CODE"
         or croak "Expected '$name' as a CODE ref";
   }

   return $callbacks;
}

method watch_property              { $self->_watch_property( shift, 0, @_ ) }
method watch_property_with_initial { $self->_watch_property( shift, 1, @_ ) }

async method _watch_property ( $property, $want_initial, %args )
{
   # Detect void-context legacy uses
   defined wantarray or
      croak "->watch_property in void context no longer useful - it now returns a Future";

   my $pdef = $self->can_property( $property )
      or croak "Class ".$self->classname." does not have a property $property";

   my $callbacks = _watchcbs_from_args( $pdef, %args );

   # Smashed properties behave differently
   my $smash = $pdef->smashed;

   if( my $cbs = $_props{$property}->{cbs} ) {
      if( $want_initial and !$smash ) {
         my $value = await $self->get_property( $property );

         $callbacks->{on_set} and $callbacks->{on_set}->( $value );
         $callbacks->{on_updated} and $callbacks->{on_updated}->( $value );
         push @$cbs, $callbacks;
         return;
      }
      elsif( $want_initial and $smash ) {
         my $cache = $_props{$property}->{cache};
         $callbacks->{on_set} and $callbacks->{on_set}->( $cache );
         $callbacks->{on_updated} and $callbacks->{on_updated}->( $cache );
         push @$cbs, $callbacks;
         return;
      }
      else {
         push @$cbs, $callbacks;
         return;
      }

      die "UNREACHED";
   }

   $_props{$property}->{cbs} = [ $callbacks ];

   if( $smash ) {
      if( $want_initial ) {
         my $cache = $_props{$property}->{cache};
         $callbacks->{on_set} and $callbacks->{on_set}->( $cache );
         $callbacks->{on_updated} and $callbacks->{on_updated}->( $cache );
      }

      return;
   }

   my $request = Tangence::Message->new( $_client, MSG_WATCH )
         ->pack_int( $self->id )
         ->pack_str( $property )
         ->pack_bool( $want_initial );

   my $message = await $_client->request( request => $request );

   my $code = $message->code;

   if( $code == MSG_WATCHING ) {
      return;
   }
   else {
      Future::Exception->throw( "Unexpected response code $code", tangence => );
   }
}

=head2 watch_property_with_cursor

   ( $cursor, $first_idx, $last_idx ) =
      await $proxy->watch_property_with_cursor( $property, $from, %callbacks );

A variant of C<watch_property> that installs a watch on the given property of
the server object, and additionally returns an cursor object that can be used
to lazily fetch the values stored in it.

The C<$from> value indicates which end of the queue the cursor should start
from; C<CUSR_FIRST> to start at index 0, or C<CUSR_LAST> to start at the
highest-numbered index. The cursor is created atomically with installing the
watch.

=cut

method watch_property_with_iter
{
   # Detect void-context legacy uses
   defined wantarray or
      croak "->watch_property_with_iter in void context no longer useful - it now returns a Future";

   return $self->watch_property_with_cursor( @_ );
}

async method watch_property_with_cursor ( $property, $from, %args )
{
   match( $from : eq ) {
      case( "first" ) { $from = CUSR_FIRST }
      case( "last"  ) { $from = CUSR_LAST  }
      default         { croak "Unrecognised 'from' value $from" }
   }

   my $pdef = $self->can_property( $property )
      or croak "Class ".$self->classname." does not have a property $property";

   my $callbacks = _watchcbs_from_args( $pdef, %args );

   # Smashed properties behave differently
   my $smashed = $pdef->smashed;

   if( my $cbs = $_props{$property}->{cbs} ) {
      die "TODO: need to synthesize a second cursor for $self";
   }

   $_props{$property}->{cbs} = [ $callbacks ];

   if( $smashed ) {
      die "TODO: need to synthesize an cursor";
   }

   $pdef->dimension == DIM_QUEUE or croak "Can only iterate on queue-dimension properties";

   my $message = await $_client->request(
      request => Tangence::Message->new( $_client, MSG_WATCH_CUSR )
         ->pack_int( $self->id )
         ->pack_str( $property )
         ->pack_int( $from ),
   );

   my $code = $message->code;

   if( $code == MSG_WATCHING_CUSR ) {
      my $cursor_id = $message->unpack_int();
      my $first_idx = $message->unpack_int();
      my $last_idx  = $message->unpack_int();

      my $cursor = Tangence::ObjectProxy::_Cursor->new( $self, $cursor_id, $pdef->type );
      return ( $cursor, $first_idx, $last_idx );
   }
   else {
      Future::Exception->throw( "Unexpected response code $code", tangence => );
   }
}

method handle_request_UPDATE ( $message )
{
   my $prop  = $message->unpack_str();
   my $how   = TYPE_U8->unpack_value( $message );

   my $pdef = $self->can_property( $prop ) or return;
   my $type = $pdef->type;
   my $dim  = $pdef->dimension;

   my $p = $_props{$prop} ||= {};

   my $dimname = DIMNAMES->[$dim];
   if( my $code = $self->can( "_update_property_$dimname" ) ) {
      $code->( $self, $p, $type, $how, $message );
   }
   else {
      croak "Unrecognised property dimension $dim for $prop";
   }

   $_->{on_updated} and $_->{on_updated}->( $p->{cache} ) for @{ $p->{cbs} };
}

method _update_property_scalar ( $p, $type, $how, $message )
{
   match( $how : == ) {
      case( CHANGE_SET ) {
         my $value = $type->unpack_value( $message );
         $p->{cache} = $value;
         $_->{on_set} and $_->{on_set}->( $p->{cache} ) for @{ $p->{cbs} };
      }
      default {
         croak "Change type $how is not valid for a scalar property";
      }
   }
}

method _update_property_hash ( $p, $type, $how, $message )
{
   match( $how : == ) {
      case( CHANGE_SET ) {
         my $value = Tangence::Type->make( dict => $type )->unpack_value( $message );
         $p->{cache} = $value;
         $_->{on_set} and $_->{on_set}->( $p->{cache} ) for @{ $p->{cbs} };
      }
      case( CHANGE_ADD ) {
         my $key   = $message->unpack_str();
         my $value = $type->unpack_value( $message );
         $p->{cache}->{$key} = $value;
         $_->{on_add} and $_->{on_add}->( $key, $value ) for @{ $p->{cbs} };
      }
      case( CHANGE_DEL ) {
         my $key = $message->unpack_str();
         delete $p->{cache}->{$key};
         $_->{on_del} and $_->{on_del}->( $key ) for @{ $p->{cbs} };
      }
      default {
         croak "Change type $how is not valid for a hash property";
      }
   }
}

method _update_property_queue ( $p, $type, $how, $message )
{
   match( $how : == ) {
      case( CHANGE_SET ) {
         my $value = Tangence::Type->make( list => $type )->unpack_value( $message );
         $p->{cache} = $value;
         $_->{on_set} and $_->{on_set}->( $p->{cache} ) for @{ $p->{cbs} };
      }
      case( CHANGE_PUSH ) {
         my @value = $message->unpack_all_sametype( $type );
         push @{ $p->{cache} }, @value;
         $_->{on_push} and $_->{on_push}->( @value ) for @{ $p->{cbs} };
      }
      case( CHANGE_SHIFT ) {
         my $count = $message->unpack_int();
         splice @{ $p->{cache} }, 0, $count, ();
         $_->{on_shift} and $_->{on_shift}->( $count ) for @{ $p->{cbs} };
      }
      default {
         croak "Change type $how is not valid for a queue property";
      }
   }
}

method _update_property_array ( $p, $type, $how, $message )
{
   match( $how : == ) {
      case( CHANGE_SET ) {
         my $value = Tangence::Type->make( list => $type )->unpack_value( $message );
         $p->{cache} = $value;
         $_->{on_set} and $_->{on_set}->( $p->{cache} ) for @{ $p->{cbs} };
      }
      case( CHANGE_PUSH ) {
         my @value = $message->unpack_all_sametype( $type );
         push @{ $p->{cache} }, @value;
         $_->{on_push} and $_->{on_push}->( @value ) for @{ $p->{cbs} };
      }
      case( CHANGE_SHIFT ) {
         my $count = $message->unpack_int();
         splice @{ $p->{cache} }, 0, $count, ();
         $_->{on_shift} and $_->{on_shift}->( $count ) for @{ $p->{cbs} };
      }
      case( CHANGE_SPLICE ) {
         my $start = $message->unpack_int();
         my $count = $message->unpack_int();
         my @value = $message->unpack_all_sametype( $type );
         splice @{ $p->{cache} }, $start, $count, @value;
         $_->{on_splice} and $_->{on_splice}->( $start, $count, @value ) for @{ $p->{cbs} };
      }
      case( CHANGE_MOVE ) {
         my $index = $message->unpack_int();
         my $delta = $message->unpack_int();
         # it turns out that exchanging neighbours is quicker by list assignment,
         # but other times it's generally best to use splice() to extract then
         # insert
         if( abs($delta) == 1 ) {
            @{$p->{cache}}[$index,$index+$delta] = @{$p->{cache}}[$index+$delta,$index];
         }
         else {
            my $elem = splice @{ $p->{cache} }, $index, 1, ();
            splice @{ $p->{cache} }, $index + $delta, 0, ( $elem );
         }
         $_->{on_move} and $_->{on_move}->( $index, $delta ) for @{ $p->{cbs} };
      }
      default {
         croak "Change type $how is not valid for an array property";
      }
   }
}

method _update_property_objset ( $p, $type, $how, $message )
{
   match( $how : == ) {
      case( CHANGE_SET ) {
         # Comes across in a LIST. We need to map id => obj
         my $objects = Tangence::Type->make( list => $type )->unpack_value( $message );
         $p->{cache} = { map { $_->id => $_ } @$objects };
         $_->{on_set} and $_->{on_set}->( $p->{cache} ) for @{ $p->{cbs} };
      }
      case( CHANGE_ADD ) {
         # Comes as object only
         my $obj = $type->unpack_value( $message );
         $p->{cache}->{$obj->id} = $obj;
         $_->{on_add} and $_->{on_add}->( $obj ) for @{ $p->{cbs} };
      }
      case( CHANGE_DEL ) {
         # Comes as ID number only
         my $id = $message->unpack_int();
         delete $p->{cache}->{$id};
         $_->{on_del} and $_->{on_del}->( $id ) for @{ $p->{cbs} };
      }
      default {
         croak "Change type $how is not valid for an objset property";
      }
   }
}

=head2 unwatch_property

   $proxy->unwatch_property( $property );

Removes a property watches on the given property on the server object that was
previously installed using C<watch_property>.

=cut

method unwatch_property ( $property )
{
   $self->can_property( $property )
      or croak "Class ".$self->classname." does not have a property $property";

   # TODO: mark cursors as destroyed and invalid
   delete $_props{$property};

   $_client->request(
      request => Tangence::Message->new( $_client, MSG_UNWATCH )
         ->pack_int( $self->id )
         ->pack_str( $property ),

      on_response => sub {},
   );
}

class Tangence::ObjectProxy::_Cursor
{
   use Carp;
   use Tangence::Constants;

=head1 CURSOR METHODS

The following methods are availilable on the property cursor objects returned
by the C<watch_property_with_cursor> method.

=cut

   field $obj          :param :reader;
   field $id           :param :reader;
   field $element_type :param;

   sub BUILDARGS ( $class, $obj, $id, $element_type )
   {
      return ( obj => $obj, id => $id, element_type => $element_type );
   }

   method client { $obj->client }

   # TODO: Object::Pad probably should do this bit
   method DESTROY
   {
      return unless $obj and my $client = $self->client;

      $client->request(
         request => Tangence::Message->new( $client, MSG_CUSR_DESTROY )
            ->pack_int( $id ),

         on_response => sub {},
      );
   }

=head2 next_forward

   ( $index, @more ) = await $cursor->next_forward( $count );

=head2 next_backward

   ( $index, @more ) = await $cursor->next_backward( $count );

Requests the next items from the cursor. C<next_forward> moves forwards
towards higher-numbered indices, and C<next_backward> moves backwards towards
lower-numbered indices. If C<$count> is unspecified, a default of 1 will
apply.

The returned future wil yield the index of the first element returned, and the
new elements. Note that there may be fewer elements returned than were
requested, if the end of the queue was reached. Specifically, there will be no
new elements if the cursor is already at the end.

=cut

   method next_forward
   {
      $self->_next( CUSR_FWD, @_ );
   }

   method next_backward
   {
      $self->_next( CUSR_BACK, @_ );
   }

   async method _next ( $direction, $count = 1 )
   {
      # Detect void-context legacy uses
      defined wantarray or
         croak "->next_forward/backward in void context no longer useful - it now returns a Future";

      my $client = $self->client;

      my $message = await $client->request(
         request => Tangence::Message->new( $client, MSG_CUSR_NEXT )
            ->pack_int( $id )
            ->pack_int( $direction )
            ->pack_int( $count || 1 ),
      );

      my $code = $message->code;

      if( $code == MSG_CUSR_RESULT ) {
         return (
            $message->unpack_int(),
            $message->unpack_all_sametype( $element_type ),
         );
      }
      else {
         Future::Exception->throw( "Unexpected response code $code", tangence => );
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
