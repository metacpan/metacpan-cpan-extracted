package RPC::Lite::Session;

use strict;

use RPC::Lite;
use RPC::Lite::MessageQuantizer;

=pod

=head1 NAME

RPC::Lite::Session - Manages a client session.  Used internally.

=head1 SYNOPSIS

  use RPC::Lite::Session;

  my $session = RPC::Lite::Session->new( $uniqueClientId, $transport, $sessionManager, $extraInfoHash );

  my $request = $session->GetRequest();

=head1 DESCRIPTION

RPC::Lite::Session implements a session for managing clients which are connected
to an RPC::Lite::Server.  Sessions handle receiving requests and sending responses
to clients.  Sessions store information about the connection so that
multiple transports and serializers can be supported by a single server.

=over 12

=cut

sub Id               { $_[0]->{id}               = $_[1] if @_ > 1; $_[0]->{id} }
sub StartTime        { $_[0]->{starttime}        = $_[1] if @_ > 1; $_[0]->{starttime} }
sub SessionManager   { $_[0]->{sessionmanager}   = $_[1] if @_ > 1; $_[0]->{sessionmanager} }
sub SerializerType   { $_[0]->{serializertype}   = $_[1] if @_ > 1; $_[0]->{serializertype} }
sub Transport        { $_[0]->{transport}        = $_[1] if @_ > 1; $_[0]->{transport} }
sub Established      { $_[0]->{established}      = $_[1] if @_ > 1; $_[0]->{established} }
sub Disconnected     { $_[0]->{disconnected}     = $_[1] if @_ > 1; $_[0]->{disconnected} }
sub MessageQuantizer { $_[0]->{messagequantizer} = $_[1] if @_ > 1; $_[0]->{messagequantizer} }
sub Stream           { $_[0]->{stream}           = $_[1] if @_ > 1; $_[0]->{stream} }
sub MessageQueue     { $_[0]->{messagequeue}     = $_[1] if @_ > 1; $_[0]->{messagequeue} }

sub new
{
  my $class          = shift;
  my $id             = shift;
  my $transport      = shift;
  my $sessionManager = shift;
  my $extraInfo      = shift;

  my $self = {};
  bless $self, $class;

  $self->StartTime( $extraInfo->{StartTime} || time() );

  $self->Id( $id );
  $self->Transport( $transport );
  $self->SessionManager( $sessionManager );
  $self->SerializerType( undef );
  $self->Established( 0 );
  $self->Disconnected( 0 );
  $self->MessageQuantizer( RPC::Lite::MessageQuantizer->new() );
  $self->Stream( '' );
  $self->MessageQueue( [] );

  return $self;
}

sub Pump
{
  my $self = shift;
  
  if ( !$self->Established() )
  {
    $self->__EstablishSession();
    return;
  }
  
  # read any new data off the transport stream
  my $newData = $self->Transport->ReadData();

  if ( !defined( $newData ) )
  {
    $self->Disconnected( 1 );
    return;
  }
  
  $self->Stream( $self->Stream() . $newData );

  # now that we've read more data, try to process the stream again
  $self->__ProcessStream();
}

=pod

=item GetRequest()

Returns an RPC::Lite::Request object or undef if there is an error (such
as the client being disconnected).

=cut

sub GetRequest
{
  my $self = shift;

  return undef if $self->Disconnected();
  return undef if !$self->Established();

  my $message = shift @{ $self->MessageQueue };

  return defined( $message ) ? $self->SessionManager->Serializers->{ $self->SerializerType() }->Deserialize( $message ) : undef;
}

sub __EstablishSession
{
  my $self = shift;
  
  # should be the first message, and we'll assume it should all come over the wire

  my $data = $self->Transport->ReadData();

  if ( !defined( $data ) )
  {
    $self->Disconnected( 1 );
    return;
  }
  
  return undef if !length( $data );

  $self->Stream( $self->Stream() . $data );

  # it should come back as our one message here
  $self->__ProcessStream();

  # if we didn't get it in our queue, disconnect
  if ( !@{ $self->MessageQueue() } )
  {
    $self->Disconnected( 1 );
    return undef;
  }
  
  my $message = shift @{ $self->MessageQueue() };

  # handshake string examples:
  #
  #  RPC-Lite 1.0 / JSON 1.1
  #  RPC-Lite 2.2 / XML 3.2
  if ( $message !~ /^RPC-Lite (.*?) \/ (.*?) (.*?)$/ )
  {
    $self->Disconnected( 1 );
    return undef;
  }
  
  my $rpcLiteVersion = $1;
  my $serializerType = $2;
  my $serializerVersion = $3;

  # FIXME return some kind of error to the client about why it's being dropped?
  if (    !RPC::Lite::VersionSupported( $rpcLiteVersion )
       or !$self->SessionManager->__InitializeSerializer( $serializerType, $serializerVersion ) )
  {
    $self->Disconnected( 1 );
    return;
  }

  $self->SerializerType( $serializerType );
  $self->Established( 1 );

  return 1;
}

sub __ProcessStream
{
  my $self = shift;
  
  return undef if ( !length( $self->Stream ) );

  my $quantized = $self->MessageQuantizer->Quantize( $self->Stream );
  
  push( @{$self->MessageQueue}, @{ $quantized->{messages} } );
  
  $self->Stream( $quantized->{remainder} );

  return scalar( @{$self->MessageQueue} );
}

=pod

=item Write( $data )

Serializes (using this particular client's serializer preference) and writes
the data referenced by $data to the client.

=cut

sub Write
{
  my $self = shift;
  my $data = shift;

  my $serializedContent = $self->SessionManager->Serializers->{ $self->SerializerType() }->Serialize( $data );
  my $packedMessage = $self->MessageQuantizer->Pack( $serializedContent );
  return $self->Transport->WriteData( $packedMessage );
}

1;
