package RPC::Lite::Client;

use strict;

use RPC::Lite;
use RPC::Lite::MessageQuantizer;
use RPC::Lite::Request;
use RPC::Lite::Response;
use RPC::Lite::Error;
use RPC::Lite::Notification;

use Data::Dumper;

our $DEFAULTSERIALIZER = 'JSON';

=pod

=head1 NAME

RPC::Lite::Client - Lightweight RPC client framework.

=head1 SYNOPSIS

  use RPC::Lite::Client;

  my $client = RPC::Lite::Client->new(
    {
      Transport  => 'TCP:Host=blah.foo.com,Port=10000',
      Serializer => 'JSON', # JSON is actually the default,
                            # this argument is unnecessary
    }
  );

  my $result = $client->Request('HelloWorld');

=head1 DESCRIPTION

RPC::Lite::Client implements a very lightweight remote process
communications client framework.  It can use arbitrary Transport
(RPC::Lite::Transport) and Serialization (RPC::Lite::Serializer)
mechanisms.

=over 4

=cut

sub SerializerType { $_[0]->{serializertype} = $_[1] if @_ > 1; $_[0]->{serializertype} }
sub Serializer     { $_[0]->{serializer}     = $_[1] if @_ > 1; $_[0]->{serializer} }
sub Transport      { $_[0]->{transport}      = $_[1] if @_ > 1; $_[0]->{transport} }
sub IdCounter      { $_[0]->{idcounter}      = $_[1] if @_ > 1; $_[0]->{idcounter} }
sub CallbackIdMap  { $_[0]->{callbackidmap}  = $_[1] if @_ > 1; $_[0]->{callbackidmap} }
sub Connected      { $_[0]->{connected}      = $_[1] if @_ > 1; $_[0]->{connected} }
sub DieOnError     { $_[0]->{dieonerror}     = $_[1] if @_ > 1; $_[0]->{dieonerror} }
sub MessageQueue     { $_[0]->{messagequeue}  = $_[1] if @_ > 1; $_[0]->{messagequeue} }
sub MessageQuantizer { $_[0]->{messagequantizer}  = $_[1] if @_ > 1; $_[0]->{messagequantizer} }
sub Stream           { $_[0]->{stream}  = $_[1] if @_ > 1; $_[0]->{stream} }

=pod

=item C<new>

Creates a new RPC::Lite::Client object.  Takes a hash reference of arguments.

=over 4

=item Supported Arguments

=over 4

=item Serializer

A string specifying the RPC::Lite::Serializer to use when communicating
with the server.  See 'perldoc RPC::Lite::Serializers' for a list of
supported serializers.

=item Transport

A string specifying the transport layer to use to connect to the server.
The string is of the format:

  <transport type>[:[<argument>=<value>[,<argument>=<value>...]]]
  
Eg, for a TCP connection to the host 'blah.foo.com' on port 10000:

  TCP:Host=blah.foo.com,Port=10000
  
See 'perldoc RPC::Lite::Transports' for a list of supported transport
mechanisms.

=item ManualConnect

A boolean value indicating whether or not you wish to connect manually,
rather than at object instantiation.  If set to true, you are required
to call Connect() on the client object before attempting to make
requests.

=item DieOnError

If true, errors from the server will die().  If false, a warning will
be emitted (warn()) and undef will be returned from C<Request>.  True
by default.

=back

=back

=cut

sub new
{
  my $class = shift;
  my $args  = shift;

  my $self = {};
  bless $self, $class;

  $self->Connected( 0 );
  
  $self->MessageQuantizer( RPC::Lite::MessageQuantizer->new() );
  
  $self->__InitializeSerializer( $args->{Serializer} );
  $self->__InitializeTransport( $args->{Transport} );

  $self->MessageQueue( [] );
  $self->IdCounter( 1 );
  $self->CallbackIdMap( {} );
  $self->Stream( '' );

  # default to death on error
  $self->DieOnError( exists( $args->{DieOnError} ) ? $args->{DieOnError} : 1 );

  $self->Initialize( $args ) if ( $self->can( 'Initialize' ) );

  if ( !$args->{ManualConnect} )
  {
    if ( !$self->Connect() )
    {
      print "Could not connect to server!\n";
      exit 1;
    }
  }
  
  return $self;
}

sub __InitializeSerializer
{
  my $self           = shift;
  my $serializerType = shift;

  $serializerType = $DEFAULTSERIALIZER if ( !length( $serializerType ) );

  my $serializerClass = 'RPC::Lite::Serializer::' . $serializerType;

  eval "use $serializerClass";
  if ( $@ )
  {
    die( "Could not load serializer of type [$serializerClass]" );
  }

  my $serializer = $serializerClass->new();
  if ( !defined( $serializer ) )
  {
    die( "Could not construct serializer: $serializerClass" );
  }

  $self->SerializerType( $serializerType );
  $self->Serializer( $serializer );
}

sub __InitializeTransport
{
  my $self = shift;

  my $transportSpec = shift;

  my ( $transportType, $transportArgString ) = split( ':', $transportSpec, 2 );

  my $transportClass = 'RPC::Lite::Transport::' . $transportType;

  eval "use $transportClass";
  if ( $@ )
  {
    die( "Could not load transport of type [$transportClass]" );
  }

  my $transport = $transportClass->new( $transportArgString );
  if ( !defined( $transport ) )
  {
    die( "Could not construct transport: $transportClass" );
  }

  $self->Transport( $transport );
}

############
# These are public methods

=pod

=item C<Connect()>

Explicitly connects to the server.  If this method is not called, the client will
attempt to automatically connect when the first request is sent.

=cut

sub Connect
{
  my $self = shift;
  
  return 1 if ( $self->Connected() );

  return 0 if ( !$self->Transport->Connect() );

  my $handshakeContent = sprintf( $RPC::Lite::HANDSHAKEFORMATSTRING, $RPC::Lite::VERSION, $self->SerializerType(), $self->Serializer->GetVersion() );
  $self->Transport->WriteData( $self->MessageQuantizer->Pack( $handshakeContent ) );
  
  $self->Connected( 1 );
  return 1;
}

=pod

=item C<Request($methodName[, param[, ...]])>

Sends a request to the server.  Returns a native object that is the result of the request.

=cut

sub Request
{
  my $self = shift;

  my $response = $self->RequestResponseObject( @_ );

  # if it's an error (user has turned off fatal errors), return undef, otherwise return the result
  return $response->isa( 'RPC::Lite:Error' ) ? undef : $response->Result;
}

=pod

=item C<AsyncRequest($callBack, $methodName[, param[, ...]])>

Sends an asynchronous request to the server.  Takes a callback code
reference.  After calling this, you'll probably want to call
HandleResponse in a loop to check for a response from the server, at
which point your callback will be executed and passed a native object
which is the result of the call.

=cut

sub AsyncRequest
{
  my $self       = shift;
  my $callBack   = shift;
  my $methodName = shift;

  # __SendRequest returns the Id the given request was assigned
  my $requestId = $self->__SendRequest( RPC::Lite::Request->new( $methodName, \@_ ) );
  $self->CallbackIdMap->{$requestId} = [ $callBack, 0 ]; # coderef, bool: wants RPC::Lite::Response object
}

=pod

=item C<RequestResponseObject($methodName[, param[, ...]])>

Sends a request to the server.  Returns an RPC::Lite::Response object.

May be mixed in with calls to AsyncRequest.  Not threadsafe.

=cut

# FIXME better name?
sub RequestResponseObject
{
  my $self = shift;
  my $method = shift;

  my $request = RPC::Lite::Request->new( $method, \@_ ); # pass arrayref of remaining args as method params
  $self->__SendRequest( $request );

  my $response;
  # Loop until the matching response comes back (i.e. this is blocking).
  # We throw away any response with a mismatched Id assuming it was generated
  # by an AsyncRequest call, in which case __GetResponse will run the callback.
  # Note that this isn't threadsafe, because we might throw away a response to a
  # non-async request generated by another thread.  The moral of the story is,
  # separate threads need separate Client objects, or async requests.
  # XXX: Most of the client code will probably not be threadsafe. Maybe we should just state that up front. Or should we make an attempt to be threadsafe?
  do {
    $response = $self->__GetResponse();
  } until (defined $response and $response->Id == $request->Id);

  return $response;
}

=pod
 
=item C<AsyncRequestResponseObject($callBack, $methodName[, param[, ...]])>
 
Sends an asynchronous request to the server.  Takes a callback code
reference.  After calling this, you'll probably want to call
HandleResponse in a loop to check for a response from the server, at
which point your callback will be executed and passed an RPC::Lite::Response
object holding the result of the call.
 
=cut
 
sub AsyncRequestResponseObject
{ 
  my $self       = shift;
  my $callBack   = shift;
  my $methodName = shift;
 
  # __SendRequest returns the Id the given request was assigned
  my $requestId = $self->__SendRequest( RPC::Lite::Request->new( $methodName, \@_ ) );
  $self->CallbackIdMap->{$requestId} = [ $callBack, 1 ]; # coderef, bool: wants RPC::Lite::Response object 
} 


=pod

=item C<Notify($methodName[, param[, ...]])>

Sends a 'notification' to the server.  That is, it makes a request,
but expects no response.

=cut

sub Notify
{
  my $self = shift;
  $self->__SendRequest( RPC::Lite::Notification->new( shift, \@_ ) );    # method and params arrayref
}

# FIXME sub NotifyResponse, for trapping local transport errors cleanly?


=pod

=item C<HandleResponse([$timeout])>

Checks for a response from the server.  Useful mostly in conjunction
with AsyncRequest.  You can pass a timeout, or the Transport's default
timeout will be used.  Returns an Error object if there was an error,
otherwise returns undef.

=cut

sub HandleResponse
{
  my $self       = shift;
  my $timeout    = shift;

  return $self->__GetResponse($timeout);
}

##############
# The following are private methods.

sub __SendRequest
{
  my ( $self, $request ) = @_;    # request could be a Notification

  return -1 if ( !$self->Connected() );

  my $id = $self->IdCounter( $self->IdCounter + 1 );
  $request->Id( $id );
  my $serializedContent = $self->Serializer->Serialize( $request );
  $self->Transport->WriteData( $self->MessageQuantizer->Pack( $serializedContent ) );

  return $id;
}

sub __GetResponse
{
  my $self    = shift;
  my $timeout = shift;

  # if our queue is empty, try to get some new messages
  my $message;
  if ( !@{ $self->MessageQueue } )
  {
    my $newData = $self->Transport->ReadData( $timeout );

    if ( !defined( $newData ) or !length( $newData ) )
    {
      if ( $timeout or $self->Transport->Timeout )
      {
        return;    # no error, just no response yet
      }
      else
      {
        return RPC::Lite::Error->new( " Error reading data from server !" );
      }
    }

    $self->Stream( $self->Stream . $newData );

    $self->__ProcessStream();
  }

  $message= shift @{ $self->MessageQueue() };

  return undef if ( !defined( $message ) );

  my $response = $self->Serializer->Deserialize( $message );

  if ( !defined( $response ) )
  {
    return RPC::Lite::Error->new( " Could not deserialize response !" );
  }

  if ( $response->isa( 'RPC::Lite::Error' ) )
  {
  
    # NOTE: We had some code here that tried to reconstruct Error.pm
    #       objects that came over the wire, but that doesn't work very
    #       well in other languages, along with some other drawbacks in
    #       implementation.  We need to look more at the best way to deal
    #       with errors.
    
    # this is the default, and is simplest for most users
    if ( $self->DieOnError() )
    {
      die( $response->Error );
    }
    else
    {
      warn( $response->Error );
    }
  }

  if ( exists( $self->CallbackIdMap->{ $response->Id } ) )
  {
    my ( $codeRef, $wantsResponseObject ) = @{ $self->CallbackIdMap->{ $response->Id } };

    # wrap the callback in some sanity checking
    if ( defined( $codeRef ) && ref( $codeRef ) eq 'CODE' )
    {
      if ( $wantsResponseObject )
      {
        $codeRef->( $response );
      }
      else
      {
        $codeRef->( $response->Result );
      }
    }

    delete $self->CallbackIdMap->{ $response->Id };
  }
  else
  {
    return $response;
  }
}

# FIXME this is in Session, it's a shame it's cut and pasted here
sub __ProcessStream
{
  my $self = shift;
  
  return undef if ( !length( $self->Stream ) );

  my $quantized = $self->MessageQuantizer->Quantize( $self->Stream );
  
  push( @{$self->MessageQueue}, @{ $quantized->{messages} } );
  
  $self->Stream( $quantized->{remainder} );

  return scalar( @{$self->MessageQueue} );
}
1;
