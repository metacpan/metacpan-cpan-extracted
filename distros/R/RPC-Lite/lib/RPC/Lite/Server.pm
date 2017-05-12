package RPC::Lite::Server;

use strict;

use threads;
use threads::shared;

use RPC::Lite::Session;
use RPC::Lite::SessionManager;

use RPC::Lite::Request;
use RPC::Lite::Response;
use RPC::Lite::Error;
use RPC::Lite::Signature;

use Data::Dumper;

my $DEBUG = $ENV{RPC_LITE_DEBUG};

my $systemPrefix         = 'system';
my $workerThreadsDefault = 10;

=pod

=head1 NAME

RPC::Lite::Server - Lightweight RPC server framework.

=head1 SYNOPSIS

  use strict;

  use RPC::Lite::Server;

  my $server = ExampleServer->new(
    {
      Transports  => [ 'TCP:ListenPort=10000,LocalAddr=localhost' ],
      Threaded    => 1,
    }
  );

  $server->Loop;

  ###########################

  package ExampleServer;

  use base qw(RPC::Lite::Server);

  sub Initialize
  {
    my $self = shift;

    $self->AddSignature( 'GetTime=int:' ); # optional signatures
  }

  sub GetTime
  {
    return time();
  }

  ...

=head1 DESCRIPTION

  RPC::Lite::Server implements a very lightweight remote process
communications server framework.  It can use arbitrary Transport
(RPC::Lite::Transport) and Serialization (RPC::Lite::Serializer)
mechanisms.  It supports optional method signatures and threading.

=cut

my %defaultMethods = (
                       "$systemPrefix.Uptime"             => \&_Uptime,
                       "$systemPrefix.RequestCount"       => \&_RequestCount,
                       "$systemPrefix.SystemRequestCount" => \&_SystemRequestCount,
                       "$systemPrefix.GetSignatures"      => \&_GetSignatures,
                       "$systemPrefix.GetSignature"       => \&_GetSignature,
	                 );

sub SessionManager { $_[0]->{sessionmanager} = $_[1] if @_ > 1; $_[0]->{sessionmanager} }
sub StartTime      { $_[0]->{starttime}      = $_[1] if @_ > 1; $_[0]->{starttime} }
sub Threaded       { $_[0]->{threaded}       = $_[1] if @_ > 1; $_[0]->{threaded} }
sub ThreadPool     { $_[0]->{threadpool}     = $_[1] if @_ > 1; $_[0]->{threadpool} }
sub PoolJobs       { $_[0]->{pooljobs}       = $_[1] if @_ > 1; $_[0]->{pooljobs} }
sub WorkerThreads  { $_[0]->{workerthreads}  = $_[1] if @_ > 1; $_[0]->{workerthreads} }
sub Signatures     { $_[0]->{signatures}     = $_[1] if @_ > 1; $_[0]->{signatures} }

sub RequestCount
{
  lock( $_[0]->{requestcount} );
  $_[0]->{requestcount} = $_[1] if @_ > 1;
  return $_[0]->{requestcount};
}

sub SystemRequestCount
{
  lock( $_[0]->{systemrequestcount} );
  $_[0]->{systemrequestcount} = $_[1] if @_ > 1;
  return $_[0]->{systemrequestcount};
}

sub __IncRequestCount       { $_[0]->__IncrementSharedField( 'requestcount' ) }
sub __IncSystemRequestCount { $_[0]->__IncrementSharedField( 'systemrequestcount' ) }

# helper for atomic counters
sub __IncrementSharedField
{
  my $self      = shift;
  my $fieldName = shift;

  lock( $self->{$fieldName} );
  return ++$self->{$fieldName};
}

=pod

=over 4

=item C<new>

Creates a new RPC::Lite::Server object.  Takes a hash reference to specify
arguments.

=over 4

=item Supported Arguments

=over 4

=item Transports

An array reference to transport specifications which will determine which
transport layers are initialized by the Session Manager.

=item Threaded

Boolean value indicating whether or not the server should operate in a
threaded mode where requests are handed to worker threads for completion.

This functionality depends on having the Thread::Pool module installed.

This functionality can also seriously impact the way a server must be
implemented to handle concurrency, etc.  It is not recommended that
this option be used unless you understand the necessary precautions
that must be taken when implementing threaded applications.

=item WortherThreads

Specifies the number of worker threads to use when threading is enabled.
Defaults to 10.

=back

=back

=cut

sub new
{
  my $class = shift;
  my $args  = shift;

  my $self = { requestcount => undef, systemrequestcount => undef };
  bless $self, $class;
  share( $self->{requestcount} );
  share( $self->{systemrequestcount} );

  $self->StartTime( time() );    # no need to share; set once and copied to children
  $self->RequestCount( 0 );
  $self->SystemRequestCount( 0 );

  $self->Threaded( $args->{Threaded} );
  $self->WorkerThreads( defined( $args->{WorkerThreads} ) ? $args->{WorkerThreads} : $workerThreadsDefault );

  $self->Signatures( {} );

  $self->Initialize( $args ) if ( $self->can( 'Initialize' ) );

  $self->__InitializeThreadPool();
  $self->__InitializeSessionManager( $args->{Transports} );
  
  $self->SessionManager->StartListening();
  
  return $self;
}

sub __InitializeSessionManager
{
  my $self           = shift;
  my $transportSpecs = shift;

  my $sessionManager = RPC::Lite::SessionManager->new(
						       {
						         TransportSpecs => $transportSpecs,
						       }
						     );

  die( "Could not create SessionManager!" ) if !$sessionManager;

  $self->SessionManager( $sessionManager );
}

sub __InitializeThreadPool
{
  my $self = shift;

  # abort if threading not requested, or already initialized
  return if !$self->Threaded or $self->ThreadPool;

  if ( __PACKAGE__->IsThreadingSupported )
  {
    __Debug( 'threading enabled' );
    eval "use Thread::Pool";
    my $pool = Thread::Pool->new(
                                  {
                                    'workers' => $self->WorkerThreads,
                                    'do'      => sub { my $result = $self->__DispatchRequest( @_ ); return $result; },
                                  }
                                );
    $self->ThreadPool( $pool );
    $self->PoolJobs( {} );
  }
  else
  {
    __Debug( 'threading requested, but not available' );
    warn "Disabling threading for lack of Thread::Pool module."; # FIXME is this useful, or is the __Debug enough?
    $self->Threaded( 0 );
  }
}

############
# These are public methods that server authors may call.

=pod

=item C<IsThreadingSupported>

Returns true if server multithreading support is available, false otherwise.

This is a class method, eg:

  my $server = RPC::Lite::Server->new(
    {
      ...,
      Threaded => RPC::Lite::Server::IsThreadingSupported() ? 1 : 0,
    }
  );

WARNING: Calling this before forking and doing some threading stuff in the child process
may hang the child.  The ithreads docs even say it doesn't play well with fork().  It is
just mentioned here because it isn't obvious that calling this method does any thread stuff.

=cut

sub IsThreadingSupported
{
  # FIXME need to make 'use threads' conditional on having ithreads available, otherwise a perl compiled without threads will just die when using this module.
  eval "use Thread::Pool";
  return $@ ? 0 : 1;
}


=pod

=item C<Loop>

Loops, calling HandleRequest, and HandleResponses, does not return.  Useful for a trivial server that doesn't need
to do anything else in its event loop.

=cut

sub Loop
{
  my $self = shift;

  while ( 1 )
  {
    $self->HandleRequests();
    $self->HandleResponses();
  }
}

=pod

=item C<HandleRequests>

Handles all pending requests, dispatching them to the underlying RPC implementation class.

Instead of calling C<Loop> some servers may implement their own update loops,
calling C<HandleRequests> repeatedly.

=cut

sub HandleRequests
{
  my $self = shift;

  $self->SessionManager->PumpSessions();

  my @readySessions = $self->SessionManager->GetReadySessions();

  foreach my $session ( @readySessions )
  {
    my $request = $session->GetRequest();
    next if !defined $request;

    if ( $self->Threaded )    # asynchronous operation
    {
      __Debug( "passing request to thread pool" );
      # god, dirty, we need to save this return value or the
      # results will be discarded...
      my $jobId = $self->ThreadPool->job( $request );
      $self->PoolJobs->{$jobId} = $session->Id();
    }
    else                      # synchronous
    {
      my $result = $self->__DispatchRequest( $request );
      $session->Write( $result ) if defined( $result );
    }
  }
}

=pod

=item C<HandleResponses>

When threading is enabled, this method looks for completed requests
and returns them to the requesting client.

=cut

# pump the thread pool and write out responses to clients
sub HandleResponses
{
  my $self = shift;

  return if !$self->Threaded;

  my @readyJobs = $self->ThreadPool->results();
  __Debug( "jobs finished: " . scalar( @readyJobs ) ) if @readyJobs;
  foreach my $jobId ( @readyJobs )
  {
    my $response = $self->ThreadPool->result( $jobId );
    my $sessionId = $self->PoolJobs->{$jobId};
    my $session = $self->SessionManager->GetSession( $sessionId );
    if ( defined( $session ) )
    {
      $session->Write( $response );
      __Debug( "  id:$jobId" );
    }
    delete $self->PoolJobs->{$jobId};
  }
}

=pod

=item C<AddSignature>

Adds a signature for the given method.  Signatures can be used to verify
that clients and servers agree on method specifications.  However, they
are optional because most RPC implementations are done with close
coupling of server and client development where developers are unlikely
to need verification of server/client agreement.

See RPC::Lite::Signature for details on the format for specifying
signatures.

=cut

sub AddSignature
{
  my $self            = shift;
  my $signatureString = shift;

  my $signature = RPC::Lite::Signature->new( $signatureString );

  if ( !$self->can( $signature->MethodName() ) )
  {
    warn( "Attempted to add a signature for a method [" . $signature->MethodName . "] we are not capable of!" );
    return;
  }

  $self->Signatures->{ $signature->MethodName } = $signature;
}

#
#############

##############
# The following are private methods.

sub __FindMethod
{
  my ( $self, $methodName ) = @_;

  __Debug( "looking for method in: " . ref( $self ) );
  my $coderef = $self->can( $methodName ) || $defaultMethods{$methodName};

  return $coderef;
}

sub __DispatchRequest
{
  my $self = shift;
  my $request = shift;

  my $method = $self->__FindMethod( $request->Method );
  my $response = undef;

  if ( $method )
  {

    # implementation package has the method, so we call it with the params
    __Debug( "dispatching to: " . $request->Method );
    eval { $response = $method->( $self, @{ $request->Params } ) };    # may return a pre-encoded Response, or just some data
    __Debug( "  returned:\n\n" );
    __Debug( Dumper $response );
    if ( $@ )
    {
      __Debug( "method died" );

      # attempt to detect an Error.pm object
      my $error = $@;
      if ( UNIVERSAL::isa( $@, 'Error' ) )
      {
        $error = { %{$@} };                                            # copy the blessed hashref into a ref to a plain one
      }

      $response = RPC::Lite::Error->new( $error );                     # FIXME security issue - exposing implementation details to the client
    }
    elsif ( !UNIVERSAL::isa( $response, 'RPC::Lite::Response' ) )
    {

      # method just returned some plain data, so we construct a Response object with it
      
      $response = RPC::Lite::Response->new( $response );
    }

    # else, the method returned a Response object already so we just let it be
  }
  else
  {

    # implementation package doesn't have the method
    $response = RPC::Lite::Error->new( "unknown method: " . $request->Method );
  }

  $response->Id( $request->Id );    # make sure the response's id matches the request's id

  use Data::Dumper;
  __Debug( "returning:\n\n" );
  __Debug(  Dumper $response ); 

  ###########################################################
  ## keep track of how many method calls we've handled...
  if ( $request->Method !~ /^$systemPrefix\./ )
  {
    $self->__IncRequestCount();
  }
  else
  {
    $self->__IncSystemRequestCount();
  }

  return $response;
}

#=============

sub __Debug
{
  return if !$DEBUG;

  my $message = shift;
  my ( $package, $filename, $line, $subroutine ) = caller( 1 );
  my $threadId = threads->tid;
  print STDERR "[$threadId] $subroutine: $message\n";
}

#=============

sub _Uptime
{
  my $self = shift;

  return time() - $self->StartTime;
}

sub _RequestCount
{
  my $self = shift;

  return $self->RequestCount;
}

sub _SystemRequestCount
{
  my $self = shift;

  return $self->SystemRequestCount;
}

sub _GetSignatures
{
  my $self = shift;

  my @signatures;

  foreach my $methodName ( keys( %{ $self->Signatures } ) )
  {
    my $signature = $self->Signatures->{$methodName};

    push( @signatures, $signature->AsString() );
  }

  return \@signatures;
}

sub _GetSignature
{
  my $self       = shift;
  my $methodName = shift;

  return $self->Signatures->{$methodName}->AsString();
}

=pod

=back

=head1 AUTHORS

  Andrew Burke (aburke@bitflood.org)
  Jeremy Muhlich (jmuhlich@bitflood.org)

=cut

1;
