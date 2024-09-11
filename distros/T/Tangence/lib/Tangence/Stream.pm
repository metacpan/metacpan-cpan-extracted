#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2020 -- leonerd@leonerd.org.uk

package Tangence::Stream 0.33;

use v5.26;
use warnings;
use experimental 'signatures';

use Carp;

use Tangence::Constants;
use Tangence::Message;

# A map from request codes to method names
# Can't use => operator because it would quote the barewords on the left, but
# we want them as constants
my %REQ_METHOD = (
   MSG_CALL,         'handle_request_CALL',
   MSG_SUBSCRIBE,    'handle_request_SUBSCRIBE',
   MSG_UNSUBSCRIBE,  'handle_request_UNSUBSCRIBE',
   MSG_EVENT,        'handle_request_EVENT',
   MSG_GETPROP,      'handle_request_GETPROP',
   MSG_GETPROPELEM,  'handle_request_GETPROPELEM',
   MSG_SETPROP,      'handle_request_SETPROP',
   MSG_WATCH,        'handle_request_WATCH',
   MSG_UNWATCH,      'handle_request_UNWATCH',
   MSG_UPDATE,       'handle_request_UPDATE',
   MSG_DESTROY,      'handle_request_DESTROY',
   MSG_WATCH_CUSR,   'handle_request_WATCH_CUSR',
   MSG_CUSR_NEXT,    'handle_request_CUSR_NEXT',
   MSG_CUSR_DESTROY, 'handle_request_CUSR_DESTROY',

   MSG_GETROOT,      'handle_request_GETROOT',
   MSG_GETREGISTRY,  'handle_request_GETREGISTRY',
   MSG_INIT,         'handle_request_INIT',
);

=head1 NAME

C<Tangence::Stream> - base class for C<Tangence> stream-handling mixins

=head1 DESCRIPTION

This module provides a base for L<Tangence::Client> and L<Tangence::Server>.
It is not intended to be used directly by C<Tangence> implementation code.

It provides the basic layer of message serialisation, deserialisation, and
dispatching to methods that would handle the messages. Higher level classes
are used to wrap this functionallity, and provide implementations of methods
to handle the messages received.

When a message is received, it will be passed to a method whose name depends
on the code of message received. The name will be C<handle_request_>, followed
by the name of the message code, in uppercase; for example
C<handle_request_CALL>. 

=cut

=head1 REQUIRED METHODS

The following methods are required to be implemented by some class using this
mixin.

=cut

=head2 tangence_write

   $stream->tangence_write( $data );

Write bytes of data to the connected peer. C<$data> will be a plain perl
string.

=cut

=head2 handle_request_$CODE

   $stream->handle_request_$CODE( $token, $message );

Invoked on receipt of a given message code. C<$token> will be some opaque perl
scalar value, and C<$message> will be an instance of L<Tangence::Message>.

The value of the token has no particular meaning, other than to be passed to
the C<respond> method.

=cut

=head1 PROVIDED METHODS

The following methods are provided by this mixin.

=cut

# Accessors for Tangence::Message decoupling
our $BUILTIN_STRUCTIDS;
our %BUILTIN_ID2STRUCT;
our %ALWAYS_PEER_HASSTRUCT;

sub message_state
{
   shift->{message_state} ||= {
      id2struct     => { %BUILTIN_ID2STRUCT },
      next_structid => $BUILTIN_STRUCTIDS,
      next_cursorid => 1,
   }
}

sub peer_hasobj    { shift->{peer_hasobj}    ||= {} }
sub peer_hasclass  { shift->{peer_hasclass}  ||= {} }
sub peer_hasstruct { shift->{peer_hasstruct} ||= { %ALWAYS_PEER_HASSTRUCT } }
sub peer_hascursor { shift->{peer_hascursor} ||= {} }

sub identity
{
   my $self = shift;
   $self->{identity} = shift if @_;
   return $self->{identity};
}

=head2 tangence_closed

   $stream->tangence_closed;

Informs the object that the underlying connection has now been closed, and any
attachments to C<Tangence::Object> or C<Tangence::ObjectProxy> instances
should now be dropped.

=cut

sub tangence_closed
{
   my $self = shift;

   foreach my $id ( keys %{ $self->peer_hasobj } ) {
      my $obj = $self->get_by_id( $id );
      $obj->unsubscribe_event( "destroy", delete $self->peer_hasobj->{$id} );
   }
}

=head2 tangence_readfrom

   $stream->tangence_readfrom( $buffer );

Informs the object that more data has been read from the underlying connection
stream. Whole messages will be removed from the beginning of the C<$buffer>,
which should be passed as a direct scalar (because it will be modified). This
method will invoke the required C<handle_request_*> methods. Any bytes
remaining that form the start of a partial message will be left in the buffer.

=cut

sub tangence_readfrom
{
   my $self = shift;

   while( length $_[0] ) {
      last unless length $_[0] >= 5;
      my ( $code, $len ) = unpack( "CN", $_[0] );
      last unless length $_[0] >= 5 + $len;

      substr( $_[0], 0, 5, "" );
      my $payload = substr( $_[0], 0, $len, "" );

      my $message = Tangence::Message->new( $self, $code, $payload );

      if( $code < 0x80 ) {
         push @{ $self->{request_queue} }, undef;
         my $token = \$self->{request_queue}[-1];

         if( !$self->minor_version and $code != MSG_INIT ) {
            $self->respondERROR( $token, "Cannot accept any message except MSG_INIT before MSG_INIT" );
            next;
         }

         if( my $method = $REQ_METHOD{$code} ) {
            if( $self->can( $method ) ) {
               $self->$method( $token, $message );
            }
            else {
               $self->respondERROR( $token, sprintf( "Cannot respond to request code 0x%02x", $code ) );
            }
         }
         else {
            $self->respondERROR( $token, sprintf( "Unrecognised request code 0x%02x", $code ) );
         }
      }
      else {
         my $on_response = shift @{ $self->{responder_queue} };
         $on_response->( $message );
      }
   }
}

sub object_destroyed ( $self, $obj, $startsub, $donesub )
{
   $startsub->();

   my $objid = $obj->id;

   delete $self->peer_hasobj->{$objid};

   $self->request(
      request => Tangence::Message->new( $self, MSG_DESTROY )
         ->pack_int( $objid ),

      on_response => sub {
         my ( $message ) = @_;
         my $code = $message->code;

         if( $code == MSG_OK ) {
            $donesub->();
         }
         elsif( $code == MSG_ERROR ) {
            my $msg = $message->unpack_str();
            print STDERR "Cannot get connection $self to destroy object $objid - error $msg\n";
         }
         else {
            print STDERR "Cannot get connection $self to destroy object $objid - code $code\n";
         }
      },
   );
}

=head2 request

   $stream->request( %args );

Serialises a message object to pass to the C<tangence_write> method, then
enqueues a response handler to be invoked when a reply arrives. Takes the
following named arguments:

=over 8

=item request => Tangence::Message

The message body

=item on_response => CODE

CODE reference to the callback to be invoked when a response to the message is
received. It will be passed the response message:

   $on_response->( $message );

=back

=head2 request (non-void)

   $response = await $stream->request( request => $request );

When called in non-void context, this method returns a L<Future> that will
yield the response instead. In this case it should not be given an
C<on_response> callback.

In this form, a C<MSG_ERROR> response will automatically turn into a failed
Future; the subsequent C<then> or C<on_done> code will not have to handle this
case.

=cut

sub request ( $self, %args )
{
   my $request = $args{request} or croak "Expected 'request'";

   my $f;
   my $on_response;
   if( defined wantarray ) {
      $args{on_response} and croak "TODO: Can't take 'on_response' and return a Future";

      $f = $self->new_future;
      $on_response = sub {
         my ( $response ) = @_;
         if( $response->code == MSG_ERROR ) {
            $f->fail( $response->unpack_str(), tangence => );
         }
         else {
            $f->done( $response );
         }
      };
   }
   else {
      $on_response = $args{on_response} or croak "Expected 'on_response'";
   }

   push @{ $self->{responder_queue} }, $on_response;

   my $payload = $request->payload;
   $self->tangence_write(
      pack "CNa*", $request->code, length($payload), $payload
   );

   return $f;
}

=head2 respond

   $stream->respond( $token, $message );

Serialises a message object to be sent to the C<tangence_write> method. The
C<$token> value that was passed to the C<handle_request_> method ensures that
it is sent at the correct position in the stream, to allow the peer to pair it
with the corresponding request.

=cut

sub respond ( $self, $token, $message )
{
   my $payload = $message->payload;
   my $response = pack "CNa*", $message->code, length($payload), $payload;

   $$token = $response;

   while( defined $self->{request_queue}[0] ) {
      $self->tangence_write( shift @{ $self->{request_queue} } );
   }
}

sub respondERROR ( $self, $token, $string )
{
   $self->respond( $token, Tangence::Message->new( $self, MSG_ERROR )
      ->pack_str( $string )
   );
}

=head2 minor_version

   $ver = $stream->minor_version;

Returns the minor version negotiated by the C<MSG_INIT> / C<MSG_INITED>
initial message handshake.

=cut

sub minor_version
{
   my $self = shift;
   ( $self->{tangence_minor_version} ) = @_ if @_;
   return $self->{tangence_minor_version} // 0;
}

# Some (internal) methods that control new protocol features

# wire protocol uses typed smash data
sub _ver_can_typed_smash { shift->minor_version >= 4 }

# wire protocol understands FLOAT* types
sub _ver_can_num_float { shift->minor_version >= 4 }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
