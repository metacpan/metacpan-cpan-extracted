package RPC::Lite::Transport::TCP;

use strict;
use base qw(RPC::Lite::Transport);

use IO::Socket;
use IO::Select;

sub Personality { $_[0]->{personality} = $_[1] if @_ > 1; $_[0]->{personality} }

# Client variables
sub Host         { $_[0]->{host}         = $_[1] if @_ > 1; $_[0]->{host} }
sub Port         { $_[0]->{port}         = $_[1] if @_ > 1; $_[0]->{port} }
sub IsConnected  { $_[0]->{isconnected}  = $_[1] if @_ > 1; $_[0]->{isconnected} }
sub Timeout      { $_[0]->{timeout}      = $_[1] if @_ > 1; $_[0]->{timeout} }
sub IsListening  { $_[0]->{islistening}  = $_[1] if @_ > 1; $_[0]->{islistening} }
sub Selector     { $_[0]->{selector}     = $_[1] if @_ > 1; $_[0]->{selector} }
sub SocketFD     { $_[0]->{socketfd}     = $_[1] if @_ > 1; $_[0]->{socketfd} }

our $maxReadSize = 1024 * 128; # 128kb max read

sub new
{
  my $class     = shift;
  my $argString = shift || ''; # avoid uninitialized value warning

  my $self = {};
  bless $self, $class;

  my @args = split( ',', $argString );
  foreach my $arg ( @args )
  {
    my ($name, $value) = split( '=', $arg );
    
    if ( !$self->can( $name ) )
    {
      die( "Unknown argument: $name" );
    }
    
    $self->$name( $value );
  }
  
  $self->Selector( IO::Select->new );

  return $self;
}

sub ReadData
{
  my $self    = shift;
  my $timeout = shift;

  # FIXME this logic still won't allow undef (infinite timeout) to be passed explicitly
  defined $timeout or $timeout = $self->Timeout;    # defaults to undef if not set by user (see new())
  return undef if !$self->IsConnected;

  my $content = '';
  my $totalBytes = 0;

  # see if we've gotten some data back from the server
  my ($socket) = $self->Selector->can_read( $timeout );

  # if we have got some data ready to be read
  if ($socket)
  {
    # try to read the max read size
    $totalBytes = $socket->sysread( $content, $maxReadSize );

    # if there was an error, return undef
    return undef if $! or !$socket->connected;
  }

  # return the content we read
  return $content;
}

sub WriteData
{
  my $self    = shift;
  my $content = shift;

  return undef if !$self->IsConnected;

  my ($socket) = $self->Selector->handles;

  return undef if !defined( $socket );

  my $bytesWritten = $socket->syswrite($content);
  
  $bytesWritten == length($content) or return undef;

  return $bytesWritten;
}

sub Connect
{
  my $self = shift;

  return 1 if $self->IsConnected;

  # FIXME make sure this times out reasonably on failure
  my $socket = IO::Socket::INET->new(
                                      Proto    => 'tcp',
                                      PeerAddr => $self->Host,
                                      PeerPort => $self->Port,
                                      Blocking => 1,
                                    );
 
  if ($socket)
  {
    $self->Selector->add($socket);
    $self->IsConnected(1);
  }

  return $self->IsConnected;
}

sub Disconnect
{
  my $self = shift;

  return undef if !$self->IsClient;

  $self->IsConnected(0);
  $self->Selector->remove( $self->Selector->handles );
  
  return 1;
}

sub GetNewConnection
{
  my $self = shift;

  my ($socket) = $self->Selector->can_read(.01);    # try to find any ready clients
  return undef if !$socket;

  $socket = $socket->accept();
    
  my $newTransport = RPC::Lite::Transport::TCP->new();
  $newTransport->Timeout( .1 );
  $newTransport->Selector()->add( $socket );
  $newTransport->IsConnected( 1 );
  $newTransport->Timeout(.01); # FIXME propagate this from $self ?  Arbitrarily picking .01 isn't so nice.
  
  return $newTransport;
}

sub Listen
{
  my $self = shift;

  return 1 if $self->IsListening;

  my $socket = IO::Socket::INET->new(
                                      Listen    => 5,
                                      LocalPort => $self->Port,
                                      LocalAddr => defined( $self->Host ) ? $self->Host : 'localhost',
                                      Proto     => 'tcp',
                                      Reuse     => 1,
                                    );

  die ( $! ) if ( !$socket );

  $self->Selector->add( $socket );
  $self->IsListening( 1 );

  return $self->IsListening;
}

1;
