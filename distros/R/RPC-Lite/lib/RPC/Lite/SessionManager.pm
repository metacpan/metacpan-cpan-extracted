package RPC::Lite::SessionManager;

use strict;

=pod

=head1 NAME

RPC::Lite::SessionManager - Manages all sessions for an RPC::Lite::Server.

=head1 SYNOPSIS

  use RPC::Lite::SessionManager;

  my $sessionManager = RPC::Lite::SessionManager->new(
	                       {
                           TransportSpecs =>
                             [
                               'TCP:ListenPort=10000,LocalAddr=localhost',
                               ...
                             ],
                         }
                       );

=head1 DESCRIPTION

RPC::Lite::SessionManager implements a simple session manager for use by RPC::Lite::Server.
The SessionManager handles creating sessions and returning sessions to the server that
are ready to have requests serviced.

=over 12

=cut

sub CurSessionId          { $_[0]->{cursessionid}          = $_[1] if @_ > 1; $_[0]->{cursessionid} }
sub Transports            { $_[0]->{transports}            = $_[1] if @_ > 1; $_[0]->{transports} }
sub Sessions              { $_[0]->{sessions}              = $_[1] if @_ > 1; $_[0]->{sessions} }
sub CurrentTransportIndex { $_[0]->{currentTransportIndex} = $_[1] if @_ > 1; $_[0]->{currentTransportIndex} }
sub Serializers           { $_[0]->{serializers} = $_[1] if @_ > 1; $_[0]->{serializers} }

sub new
{
  my $class = shift;
  my $args  = shift;

  my $self = {};
  bless $self, $class;

  $self->CurSessionId( 0 );
  $self->Sessions( {} );
  $self->Serializers( {} );
  $self->Transports( [] );
  $self->Serializers( {} );
  $self->CurrentTransportIndex( 0 );

  die( "Must specify at least one transport type!" ) if !exists( $args->{TransportSpecs} );

  $self->__InitializeTransports( $args->{TransportSpecs} );

  return $self;
}

sub __InitializeTransports
{
  my $self = shift;
  my $transportSpecs = shift;
  
  foreach my $transportSpec ( @{ $transportSpecs } )
  {
    my ( $transportClassName, $transportArgString ) = split( ':', $transportSpec, 2 );

    my $transportClass = 'RPC::Lite::Transport::' . $transportClassName;

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
    
    push( @{ $self->Transports }, $transport );
  }
}

sub __InitializeSerializer
{
  my $self = shift;
  my $serializer = shift;
  my $serializerVersion = shift;
  
  # if we've already loaded this serializer, just return 1
  return 1 if ( defined ( $self->Serializers->{ $serializer } ) );
  
  my $serializerClass = "RPC::Lite::Serializer::$serializer";

  # try to load the serializer class
  eval "use $serializerClass";
  if ( $@ )
  {
    warn( "Could not load serializer of type [$serializerClass]" );
    return 0;
  }

  # try to instantiate a serializer of this type
  eval { $self->Serializers->{ $serializer } = $serializerClass->new(); };
  if ( $@ )
  {
    warn( "Could not create serializer object of type [$serializerClass]: $@" );
    return 0;
  }
  
  if ( !$self->Serializers->{ $serializer }->VersionSupported( $serializerVersion ) )
  {
    warn( "Serializer [$serializerClass] does not support version [$serializerVersion]" );
    return 0;
  }
  
  # if we got here we loaded that serializer
  return 1;
}

=pod

=item StartListening()

Start listening on all transport layers.

=cut

sub StartListening
{
  my $self = shift;
  
  foreach my $transport ( @{ $self->Transports() } )
  {
    if ( !$transport->Listen() )
    {
      die( "Could not start listening with transport: " . ref( $transport ) );
    }
  }
}

=pod

=item PumpSessions()

Iterates over the active sessions, calling their Pump() routine, which should
read and process any incoming data.

=cut

sub PumpSessions
{
  my $self = shift;
  
  $self->HandleIncomingConnections();
  
  foreach my $session ( values( %{ $self->Sessions } ) )
  {
    $session->Pump();
  }
}

=pod

=item GetReadySessions()

Returns an array of sessions with requests pending.

=cut

sub GetReadySessions
{
  my $self = shift;

  # FIXME this could be better, i bet
  # loop once over them to reap all disconnected sessions
  foreach my $session ( values( %{ $self->Sessions } ) )
  {
    delete $self->Sessions->{ $session->Id() } if ( $session->Disconnected() );
  }

  my @readySessions;
    
  # FIXME fairness problems here
  # loop a second time looking for ready sessions
  foreach my $session ( values( %{ $self->Sessions } ) )
  {
    # return a session if it has queued messages
    push( @readySessions, $session ) if ( @{ $session->MessageQueue() } );
  }

  return @readySessions;
}

sub HandleIncomingConnections
{
  my $self = shift;

  foreach my $transport ( @{ $self->Transports } )  
  {
    my $transportInstance = $transport->GetNewConnection();
    
    if ( defined( $transportInstance ) )
    {
      $self->Sessions()->{ $self->CurSessionId } = RPC::Lite::Session->new( $self->CurSessionId(), $transportInstance, $self );
      $self->CurSessionId( $self->CurSessionId + 1 );
    }
  }
}

sub GetSession
{
  my $self = shift;
  my $sessionId = shift;
  
  return $self->Sessions->{$sessionId};
}

1;
