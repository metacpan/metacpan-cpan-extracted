package POE::Component::Server::SimpleHTTP;
$POE::Component::Server::SimpleHTTP::VERSION = '2.28';
#ABSTRACT: Perl extension to serve HTTP requests in POE.

use strict;
use warnings;

use POE;
use POE::Wheel::SocketFactory;
use POE::Wheel::ReadWrite;
use POE::Filter::HTTPD;
use POE::Filter::Stream;

use Carp qw( croak );
use Socket qw( AF_INET AF_INET6 INADDR_ANY IN6ADDR_ANY inet_pton );

use HTTP::Date qw( time2str );

use POE::Component::Server::SimpleHTTP::Connection;
use POE::Component::Server::SimpleHTTP::Response;
use POE::Component::Server::SimpleHTTP::State;

BEGIN {

   # Debug fun!
   if ( !defined &DEBUG ) {
      eval "sub DEBUG () { 0 }";
   }

   # Our own definition of the max retries
   if ( !defined &MAX_RETRIES ) {
      eval "sub MAX_RETRIES () { 5 }";
   }
}

use MooseX::POE;
use Moose::Util::TypeConstraints;


has 'alias' => (
  is => 'ro',
);

has 'domain' => (
  is => 'ro',
);

has 'address' => (
  is => 'ro',
);

has 'port' => (
  is => 'ro',
  default => sub { 0 },
  writer => '_set_port',
);

has 'hostname' => (
  is => 'ro',
  default => sub { require Sys::Hostname; return Sys::Hostname::hostname(); },
);

has 'proxymode' => (
  is => 'ro',
  isa => 'Bool',
  default => sub { 0 },
);

has 'keepalive' => (
  is => 'ro',
  isa => 'Bool',
  default => sub { 0 },
);

has 'sslkeycert' => (
  is => 'ro',
  isa => subtype 'ArrayRef' => where { scalar @$_ == 2 },
);

has 'sslintermediatecacert' => (
  is => 'ro',
  isa => 'Str',
);

has 'headers' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub {{}},
);

has 'handlers' => (
  is => 'ro',
  isa => 'ArrayRef',
  required => 1,
  writer => '_set_handlers',
);

has 'errorhandler' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub {{}},
);

has 'loghandler' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub {{}},
);

has 'log2handler' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub {{}},
);

has 'setuphandler' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub {{}},
);

has 'retries' => (
  traits  => ['Counter'],
  is        => 'ro',
  isa       => 'Num',
  default   => sub { 0 },
  handles   => {
    inc_retry     => 'inc',
    dec_retry     => 'dec',
    reset_retries => 'reset',
  },
);

has '_requests' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub {{}},
  init_arg => undef,
  clearer => '_clear_requests',
);

has '_connections' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub {{}},
  init_arg => undef,
  clearer => '_clear_connections',
);

has '_chunkcount' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub {{}},
  init_arg => undef,
  clearer => '_clear_chunkcount',
);

has '_responses' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub {{}},
  init_arg => undef,
  clearer => '_clear_responses',
);

has '_factory' => (
  is => 'ro',
  isa => 'POE::Wheel::SocketFactory',
  init_arg => undef,
  clearer => '_clear_factory',
  writer =>  '_set_factory',
);

sub BUILDARGS {
  my $class = shift;
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;

  if ( $args{sslkeycert} and ref $args{sslkeycert} eq 'ARRAY'
	and scalar @{ $args{sslkeycert} } == 2 ) {

     eval {
       require POE::Component::SSLify;
       import POE::Component::SSLify
         qw( SSLify_Options SSLify_GetSocket Server_SSLify SSLify_GetCipher SSLify_GetCTX );
       SSLify_Options( @{ $args{sslkeycert} } );
     };
     if ($@) {
        warn "Unable to load PoCo::SSLify -> $@" if DEBUG;
	delete $args{sslkeycert};
     }
     else {
	if ( $args{sslintermediatecacert} ) {
	  my $ctx = SSLify_GetCTX();
	  Net::SSLeay::CTX_load_verify_locations($ctx, $args{sslintermediatecacert}, '');
	}
     }
  }

  return $class->SUPER::BUILDARGS(%args);
}

sub session_id {
  shift->get_session_id;
}

sub getsockname {
  shift->_factory->getsockname;
}

sub shutdown {
   my $self = shift;
   $poe_kernel->call( $self->get_session_id, 'SHUTDOWN', @_ );
}

# This subroutine, when SimpleHTTP exits, will search for leaks
sub STOP {
   my $self = $_[OBJECT];
   # Loop through all of the requests
   foreach my $req ( keys %{ $self->_requests } ) {

      # Bite the programmer!
      warn 'Did not get DONE/CLOSE event for Wheel ID ' 
        . $req
        . ' from IP '
        . $self->_requests->{$req}->response->connection->remote_ip;
   }

   # All done!
   return 1;
}

sub START {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alias_set( $self->alias ) if $self->alias;
  $kernel->refcount_increment( $self->get_session_id, __PACKAGE__ )
	unless $self->alias;
  MassageHandlers( $self->handlers );
  # Start Listener
  $kernel->yield( 'start_listener' );
  return;
}

# 'SHUTDOWN'
# Stops the server!
event 'SHUTDOWN' => sub {
   my ($kernel,$self,$graceful) = @_[KERNEL,OBJECT,ARG0];
   # Shutdown the SocketFactory wheel
   $self->_clear_factory if $self->_factory;

   # Debug stuff
   warn 'Stopped listening for new connections!' if DEBUG;

   # Are we gracefully shutting down or not?
   if ( $graceful ) {

      # Check for existing requests and keep-alive connections
      if ( keys( %{ $self->_requests } ) == 0
         and keys( %{ $self->_connections } ) == 0 )
      {

         # Alright, shutdown anyway

         # Delete our alias
         $kernel->alias_remove( $_ ) for $kernel->alias_list();
         $kernel->refcount_decrement( $self->get_session_id, __PACKAGE__ )
           unless $self->alias;

         # Debug stuff
         warn 'Stopped SimpleHTTP gracefully, no requests left' if DEBUG;
      }

      # All done!
      return 1;
   }

   # Forcibly close all sockets that are open
   foreach my $S ( $self->_requests, $self->_connections ) {
      foreach my $conn ( keys %$S ) {

         # Can't call method "shutdown_input" on an undefined value at
         # /usr/lib/perl5/site_perl/5.8.2/POE/Component/Server/SimpleHTTP.pm line 323.
         if (   defined $S->{$conn}->wheel
            and defined $S->{$conn}->wheel->get_input_handle() )
         {
            $S->{$conn}->close_wheel;
         }

         # Delete this request
         delete $S->{$conn};
      }
   }

   # Delete our alias
   $kernel->alias_remove( $_ ) for $kernel->alias_list();
   $kernel->refcount_decrement( $self->get_session_id, __PACKAGE__ )
     unless $self->alias;

   # Debug stuff
   warn 'Successfully stopped SimpleHTTP' if DEBUG;

   # Return success
   return 1;
};

# Sets up the SocketFactory wheel :)
event 'start_listener' => sub {
   my ($kernel,$self,$noinc) = @_[KERNEL,OBJECT,ARG0];

   warn "Creating SocketFactory wheel now\n" if DEBUG;

   # Check if we should set up the wheel
   if ( $self->retries == MAX_RETRIES ) {
      die 'POE::Component::Server::SimpleHTTP tried '
        . MAX_RETRIES
        . ' times to create a Wheel and is giving up...';
   }
   else {

      $self->inc_retry unless $noinc;

      my $domain = $self->domain;
      my $bindaddress = $self->address;
      if ( not defined $bindaddress and not defined $domain ) {
         $domain = AF_INET6;
         $bindaddress = IN6ADDR_ANY;
      } elsif ( not defined $bindaddress ) {
         if ( $domain == AF_INET6 ) {
            $bindaddress = IN6ADDR_ANY;
         } elsif ( $domain == AF_INET ) {
            $bindaddress = INADDR_ANY;
         }
      } else {
         if ( defined inet_pton(AF_INET6, $bindaddress) ) {
            $domain = AF_INET6;
         } elsif ( defined inet_pton(AF_INET, $bindaddress) ) {
            $domain = AF_INET;
         }
      }

      # Create our own SocketFactory Wheel :)
      my $factory = POE::Wheel::SocketFactory->new(
         ( $domain ? ( SocketDomain => $domain ) : () ),
         ( $bindaddress ? ( BindAddress => $bindaddress ) : () ),
         BindPort     => $self->port,
         Reuse        => 'yes',
         SuccessEvent => 'got_connection',
         FailureEvent => 'listener_error',
      );

      my ( $family, $address, $port, $straddress ) =
      POE::Component::Server::SimpleHTTP::Connection->get_sockaddr_info(
         $factory->getsockname );
      $self->_set_port( $port ) if ( $self->port == 0 and $port );

      $self->_set_factory( $factory );

      if ( $self->setuphandler ) {
	 my $setuphandler = $self->setuphandler;
         if ( $setuphandler->{POSTBACK} and 
		ref $setuphandler->{POSTBACK} eq 'POE::Session::AnonEvent' ) {
            $setuphandler->{POSTBACK}->( $port, $address );
         }
         else {
            $kernel->post(
               $setuphandler->{'SESSION'},
               $setuphandler->{'EVENT'},
               $port, $address,
	    ) if $setuphandler->{'SESSION'} and $setuphandler->{'EVENT'};
         }
      }
   }

   return 1;
};

# Got some sort of error from SocketFactory
event listener_error => sub {
   my ($kernel,$self,$operation,$errnum,$errstr,$wheel_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
   warn
     "SocketFactory Wheel $wheel_id generated $operation error $errnum: $errstr\n"
	if DEBUG;

   $self->call( 'start_listener' );
   return 1;
};

# 'STARTLISTEN'
# Starts listening on the socket
event 'STARTLISTEN' => sub {
   warn 'STARTLISTEN called, resuming accepts on SocketFactory'
     if DEBUG;
   $_[OBJECT]->call( 'start_listener', 'noinc' );
   return 1;
};

# 'STOPLISTEN'
# Stops listening on the socket
event 'STOPLISTEN' => sub {
   my $self = $_[OBJECT];
   warn 'STOPLISTEN called, pausing accepts on SocketFactory'
     if DEBUG;
   $self->_clear_factory if $self->_factory;
   return 1;
};

# 'SETHANDLERS'
# Sets the HANDLERS
event 'SETHANDLERS' => sub {
   my ($self,$handlers) = @_[OBJECT,ARG0];
   MassageHandlers($handlers);
   $self->_set_handlers( $handlers );
   return 1;
};

# 'GETHANDLERS'
# Gets the HANDLERS
event 'GETHANDLERS' => sub {
   my ($kernel,$self,$session,$event ) = @_[KERNEL,OBJECT,ARG0,ARG1];
   return unless $session and $event;
   require Storable;
   my $handlers = Storable::dclone( $self->handlers );
   delete $_->{'RE'} for @{ $handlers };
   $kernel->post( $session, $event, $handlers );
   return 1;
};

# This subroutine massages the HANDLERS for internal use
# Should probably support POSTBACK/CALLBACK
sub MassageHandlers {
   my $handler = shift;

   # Make sure it is ref to array
   if ( !ref $handler or ref($handler) ne 'ARRAY' ) {
      croak("HANDLERS is not a ref to an array!");
   }

   # Massage the handlers
   my $count = 0;
   while ( $count < scalar(@$handler) ) {

      # Must be ref to hash
      if ( ref $handler->[$count] and ref( $handler->[$count] ) eq 'HASH' ) {

         # Make sure all the keys are uppercase
         $handler->[$count]->{ uc $_ } = delete $handler->[$count]->{$_}
           for keys %{ $handler->[$count] };

         # Make sure it got the 3 parts necessary
         if (  !exists $handler->[$count]->{'SESSION'}
            or !defined $handler->[$count]->{'SESSION'} )
         {
            croak("HANDLER number $count does not have a SESSION argument!");
         }
         if (  !exists $handler->[$count]->{'EVENT'}
            or !defined $handler->[$count]->{'EVENT'} )
         {
            croak("HANDLER number $count does not have an EVENT argument!");
         }
         if (  !exists $handler->[$count]->{'DIR'}
            or !defined $handler->[$count]->{'DIR'} )
         {
            croak("HANDLER number $count does not have a DIR argument!");
         }

         # Convert SESSION to ID
         if (
            UNIVERSAL::isa( $handler->[$count]->{'SESSION'}, 'POE::Session' ) )
         {
            $handler->[$count]->{'SESSION'} =
              $handler->[$count]->{'SESSION'}->ID;
         }

         # Convert DIR to qr// format
         my $regex = undef;
         eval { $regex = qr/$handler->[ $count ]->{'DIR'}/ };

         # Check for errors
         if ($@) {
            croak("HANDLER number $count has a malformed DIR -> $@");
         }
         else {

            # Store it!
            $handler->[$count]->{'RE'} = $regex;
         }
      }
      else {
         croak("HANDLER number $count is not a reference to a HASH!");
      }

      # Done with this one!
      $count++;
   }

   # Got here, success!
   return 1;
}

# 'Got_Connection'
# The actual manager of connections
event 'got_connection' => sub {
   my ( $kernel, $self, $socket ) = @_[KERNEL, OBJECT, ARG0];

   my ( $family, $address, $port, $straddress ) =
   POE::Component::Server::SimpleHTTP::Connection->get_sockaddr_info(
      getpeername($socket) );

   # Should we SSLify it?
   if ( $self->sslkeycert ) {

      # SSLify it!
      eval { $socket = Server_SSLify($socket) };
      if ($@) {
         warn "Unable to turn on SSL for connection from $straddress -> $@";
         close $socket;
         return 1;
      }
   }

   # Set up the Wheel to read from the socket
   my $wheel = POE::Wheel::ReadWrite->new(
      Handle       => $socket,
      Filter  => POE::Filter::HTTPD->new(),
      InputEvent   => 'got_input',
      FlushedEvent => 'got_flush',
      ErrorEvent   => 'got_error',
   );

   if ( DEBUG and keys %{ $self->_connections } ) {

      # use Data::Dumper;
      warn "conn id=", $wheel->ID, " [",
        join( ', ', keys %{ $self->_connections } ), "]";
   }

   # Save this wheel!
   # 0 = wheel, 1 = Output done?, 2 = SimpleHTTP::Response object, 3 == request, 4 == streaming?
   $self->_requests->{ $wheel->ID } = 
	POE::Component::Server::SimpleHTTP::State->new( wheel => $wheel );

   # Debug stuff
   if (DEBUG) {
      warn "Got_Connection completed creation of ReadWrite wheel ( "
        . $wheel->ID . " )";
   }

   # Success!
   return 1;
};

# 'Got_Input'
# Finally got input, set some stuff and send away!
event 'got_input' => sub {
   my ($kernel,$self,$request,$id) = @_[KERNEL,OBJECT,ARG0,ARG1];
   my $connection;

   # This whole thing is a mess. Keep-Alive was bolted on and it
   # shows. Streaming is unpredictable. There are checks everywhere
   # because it leaks wheels. *sigh*

   # Was this request Keep-Alive?
   if ( $self->_connections->{$id} ) {
      my $state = delete $self->_connections->{$id};
      $state->reset;
      $connection = $state->connection;
      $state->clear_connection;
      $self->_requests->{$id} = $state;
      warn "Keep-alive id=$id next request..." if DEBUG;
   }

   # Quick check to see if the socket died already...
   # Initially reported by Tim Wood
   unless ( $self->_requests->{$id}->wheel_alive ) {
      warn 'Got a request, but socket died already!' if DEBUG;
      # Destroy this wheel!
      $self->_requests->{$id}->close_wheel;
      delete $self->_requests->{$id};
      return;
   }

   SWITCH: {

     last SWITCH if $connection; # connection was kept-alive

     # Directly access POE::Wheel::ReadWrite's HANDLE_INPUT -> to get the socket itself
     # Hmm, if we are SSL, then have to do an extra step!
     if ( $self->sslkeycert ) {
        $connection = POE::Component::Server::SimpleHTTP::Connection->new(
            SSLify_GetSocket(
               $self->_requests->{$id}->wheel->get_input_handle() )
        );
        last SWITCH;
      }
      $connection = POE::Component::Server::SimpleHTTP::Connection->new(
         $self->_requests->{$id}->wheel->get_input_handle()
      );
   }

   # The HTTP::Response object, the path
   my ( $response, $path, $malformed_req );

   # Check if it is HTTP::Request or Response
   # Quoting POE::Filter::HTTPD
   # The HTTPD filter parses the first HTTP 1.0 request from an incoming stream into an
   # HTTP::Request object (if the request is good) or an HTTP::Response object (if the
   # request was malformed).

   if ( $request->isa('HTTP::Response') ) {
      # Make the request nothing
      $response = $request;
      $request  = undef;

      # Mark that this is a malformed request
      $malformed_req = 1;

      # Hack it to simulate POE::Component::Server::SimpleHTTP::Response->new( $id, $conn );
      bless( $response, 'POE::Component::Server::SimpleHTTP::Response' );
      $response->_WHEEL( $id );

      $response->set_connection( $connection );

      # Set the path to an empty string
      $path = '';
   }
   else {
      unless ( $self->proxymode ) {
         # Add stuff it needs!
         my $uri = $request->uri;
         $uri->scheme('http');
         $uri->host( $self->hostname );
         $uri->port( $self->port );

         # Get the path
         $path = $uri->path();
         if ( !defined $path or $path eq '' ) {
            # Make it the default handler
            $path = '/';
         }
      }
      else {
         # We're in PROXYMODE set the path to the full URI
         $path = $request->uri->as_string();
      }

      # Get the response
      $response =
        POE::Component::Server::SimpleHTTP::Response->new( $id, $connection );

      # Stuff the default headers
      $response->header( %{ $self->headers } )
	if keys( %{ $self->headers } ) != 0;
   }

   # Check if the SimpleHTTP::Connection object croaked ( happens when sockets just disappear )
   unless ( defined $response->connection ) {
      # Debug stuff
      warn "could not make connection object" if DEBUG;
      # Destroy this wheel!
      $self->_requests->{$id}->close_wheel;
      delete $self->_requests->{$id};
      return;
   }

   # If we used SSL, turn on the flag!
   if ( $self->sslkeycert ) {
      $response->connection->ssl(1);

      # Put the cipher type for people who want it
      $response->connection->sslcipher(
           SSLify_GetCipher( $self->_requests->{$id}->wheel->get_input_handle() )
      );
   }

   if ( !defined( $request ) ) {
      $self->_requests->{$id}->close_wheel;
      delete $self->_requests->{$id};
      return;
   }

   # Add this response to the wheel
   $self->_requests->{$id}->set_response( $response );
   $self->_requests->{$id}->set_request( $request );
   $response->connection->ID($id);

   # If they have a log handler registered, send out the needed information
   # TODO if we received a malformed request, we will not have a request object
   # We need to figure out what we're doing because they can't always expect to have
   # a request object, or should we keep it from being ?undef'd?

   if ( $self->loghandler and scalar keys %{ $self->loghandler } == 2 ) {
      $! = undef;
      $kernel->post(
         $self->loghandler->{'SESSION'},
         $self->loghandler->{'EVENT'},
         $request, $response->connection->remote_ip()
      );

      # Warn if we had a problem dispatching to the log handler above
      warn(
         "I had a problem posting to event '",
         $self->loghandler->{'EVENT'},
         "' of the log handler alias '",
         $self->loghandler->{'SESSION'},
"'. As reported by Kernel: '$!', perhaps the alias is spelled incorrectly for this handler?"
      ) if $!;
   }

   # If we received a malformed request then
   # let's not try to dispatch to a handler

   if ($malformed_req) {
      # Just push out the response we got from POE::Filter::HTTPD saying your request was bad
      $kernel->post(
         $self->errorhandler->{SESSION},
         $self->errorhandler->{EVENT},
         'BadRequest (by POE::Filter::HTTPD)',
         $response->connection->remote_ip()
      ) if $self->errorhandler and $self->errorhandler->{SESSION} and $self->errorhandler->{EVENT};
      $kernel->yield( 'DONE', $response );
      return;
   }

   # Find which handler will handle this one
   foreach my $handler ( @{ $self->handlers } ) {

      # Check if this matches
      if ( $path =~ $handler->{'RE'} ) {

          # Send this off!
          $kernel->post( $handler->{'SESSION'}, $handler->{'EVENT'}, $request,
               $response, $handler->{'DIR'}, );

            # Make sure we croak if we have an issue posting
            croak(
"I had a problem posting to event $handler->{'EVENT'} of session $handler->{'SESSION'} for DIR handler '$handler->{'DIR'}'",
". As reported by Kernel: '$!', perhaps the session name is spelled incorrectly for this handler?"
            ) if $!;

            # All done!
            return;
      }
   }

   # If we reached here, no handler was able to handle it...
   # Set response code to 404 and tell the client we didn't find anything
   $response->code(404);
   $response->content('404 Not Found');
   $kernel->yield( 'DONE', $response );
   return;
};

# 'Got_Flush'
# Finished with a request!
event 'got_flush' => sub {
   my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];

   return unless defined $self->_requests->{$id};

   # Debug stuff
   warn "Got Flush event for wheel ID ( $id )" if DEBUG;

   if ( $self->_requests->{$id}->streaming ) {
      # Do the stream !
      warn "Streaming in progress ...!" if DEBUG;
      return;
   }

   # Check if we are shutting down
   if ( $self->_requests->{$id}->done ) {

      if ( $self->must_keepalive( $id ) ) {
         warn "Keep-alive id=$id ..." if DEBUG;
	 my $state = delete $self->_requests->{$id};
	 $state->set_connection( $state->response->connection );
	 $state->reset;
         $self->_connections->{$id} = $state;
         delete $self->_chunkcount->{$id};
         delete $self->_responses->{$id};
      }
      else {
         # Shutdown read/write on the wheel
         $self->_requests->{$id}->close_wheel;
         delete $self->_requests->{$id};
      }

   }
   else {

      # Ignore this, eh?
      if (DEBUG) {
         warn
           "Got Flush event for socket ( $id ) when we did not send anything!";
      }
   }

   # Alright, do we have to shutdown?
   unless ( $self->_factory ) {
      # Check to see if we have any more requests
      if (   keys( %{ $self->_requests } ) == 0
         and keys( %{ $self->_connections } ) == 0 )
      {
         # Shutdown!
         $kernel->yield('SHUTDOWN');
      }
   }

   # Success!
   return 1;
};

# should we keep-alive the connection?
sub must_keepalive {
   my ( $self, $id ) = @_;

   return unless $self->keepalive;

   my $resp = $self->_requests->{$id}->response;
   my $req  = $self->_requests->{$id}->request;

   # error = close
   return 0 if $resp->is_error;

   # Connection is a comma-seperated header
   my $conn = lc ($req->header('Connection') || '');
   return 0 if ",$conn," =~ /,\s*close\s*,/;
   $conn = lc ($req->header('Proxy-Connection') || '');
   return 0 if ",$conn," =~ /,\s*close\s*,/;
   $conn = lc ($resp->header('Connection') || '');
   return 0 if ",$conn," =~ /,\s*close\s*,/;

   # HTTP/1.1 = keep
   return 1 if $req->protocol eq 'HTTP/1.1';
   return 0;
}

# 'Got_Error'
# Got some sort of error from ReadWrite
event 'got_error' => sub {
   my ($kernel,$self,$operation,$errnum,$errstr,$id) = @_[KERNEL,OBJECT,ARG0..ARG3];

   # Only do this for non-EOF on read
   #unless ( $operation eq 'read' and $errnum == 0 ) {
   {

      # Debug stuff
      warn "Wheel $id generated $operation error $errnum: $errstr\n"
	      if DEBUG;

      my $connection;
      if ( $self->_connections->{$id} ) {
         my $c = delete $self->_connections->{$id};
         $connection = $c->connection;
         $c->close_wheel;
      }
      else {

         if( defined $self->_requests->{$id}->response ) {
            $connection = $self->_requests->{$id}->response->connection;
         }   
         else {
            warn "response for $id is undefined" if DEBUG;
         }

         # Delete this connection
         $self->_requests->{$id}->close_wheel;
      }

      delete $self->_requests->{$id};
      delete $self->_responses->{$id};

      # Mark the client dead
      $connection->dead(1) if $connection;
   }

   # Success!
   return 1;
};

# 'DONE'
# Output to the client!
event 'DONE' => sub {
   my ($kernel,$self,$response) = @_[KERNEL,OBJECT,ARG0];

   # Check if we got it
   if ( !defined $response or !UNIVERSAL::isa( $response, 'HTTP::Response' ) ) {
      warn 'Did not get a HTTP::Response object!' if DEBUG;
      # Abort...
      return;
   }

   # Get the wheel ID
   my $id = $response->_WHEEL;

   # Check if the wheel exists ( sometimes it gets closed by the client, but the application doesn't know that... )
   unless ( exists $self->_requests->{$id} ) {

      # Debug stuff
       warn
         'Wheel disappeared, but the application sent us a DONE event, discarding it'
  	    if DEBUG;

      $kernel->post(
         $self->errorhandler->{SESSION},
         $self->errorhandler->{EVENT},
         'Wheel disappeared !'
      ) if $self->errorhandler and $self->errorhandler->{SESSION} and $self->errorhandler->{EVENT};

      # All done!
      return 1;
   }


   # Check if we have already sent the response
   if ( $self->_requests->{$id}->done ) {
      # Tried to send twice!
      die 'Tried to send a response to the same connection twice!';
   }

   # Quick check to see if the wheel/socket died already...
   # Initially reported by Tim Wood
   unless ( $self->_requests->{$id}->wheel_alive ) {
      warn 'Tried to send data over a closed/nonexistant socket!' if DEBUG;
      $kernel->post(
         $self->errorhandler->{SESSION},
         $self->errorhandler->{EVENT},
         'Socket closed/nonexistant !'
      ) if $self->errorhandler and $self->errorhandler->{SESSION} and $self->errorhandler->{EVENT};
      return;
   }

   # Check if we were streaming. 

   if ( $self->_requests->{$id}->streaming ) {
      $self->_requests->{$id}->set_streaming(0);
      $self->_requests->{$id}->set_done(1); # Finished streaming
      # TODO: We might not get a flush, trigger it ourselves.
      if ( !$self->_requests->{$id}->wheel->get_driver_out_messages ) {
         $kernel->yield( 'got_flush', $id );
      }
      return;
   }
   

   $self->fix_headers( $response );

   # Send it out!
   $self->_requests->{$id}->wheel->put($response);

   # Mark this socket done
   $self->_requests->{$id}->set_done(1);

   # Log FINALLY If they have a logFinal handler registered, send out the needed information
   if ( $self->log2handler and scalar keys %{ $self->log2handler } == 2 ) {
      $! = undef;
      $kernel->call(
         $self->log2handler->{'SESSION'},
         $self->log2handler->{'EVENT'},
         $self->_requests->{$id}->request, $response
      );

      # Warn if we had a problem dispatching to the log handler above
      warn(
         "I had a problem posting to event '",
         $self->log2handler->{'EVENT'},
         "' of the log handler alias '",
         $self->log2handler->{'SESSION'},
"'. As reported by Kernel: '$!', perhaps the alias is spelled incorrectly for this handler?"
      ) if $!;
   }

   # Debug stuff
   warn "Completed with Wheel ID $id" if DEBUG;

   # Success!
   return 1;
};

# 'STREAM'
# Stream output to the client
event 'STREAM' => sub {
   my ($kernel,$self,$response) = @_[KERNEL,OBJECT,ARG0];

   # Check if we got it
   unless ( defined $response and UNIVERSAL::isa( $response, 'HTTP::Response' ) ) {
      warn 'Did not get a HTTP::Response object!' if DEBUG;
      # Abort...
      return;
   }

   # Get the wheel ID
   my $id = $response->_WHEEL;
   $self->_chunkcount->{$id}++;

   if ( defined $response->STREAM ) {

      # Keep track if we plan to stream ...
      if ( $self->_responses->{$id} ) {
         warn "Restoring response from HEAP and id $id " if DEBUG;
         $response = $self->_responses->{$id};
      }
      else {
         warn "Saving HEAP response to id $id " if DEBUG;
         $self->_responses->{$id} = $response;
      }
   }
   else {
      warn
        'Can\'t push on a response that has not been not set as a STREAM!'
	   if DEBUG;
      # Abort...
      return;
   }

   # Check if the wheel exists ( sometimes it gets closed by the client, but the application doesn't know that... )
   unless ( exists $self->_requests->{$id} ) {

      # Debug stuff
       warn
         'Wheel disappeared, but the application sent us a DONE event, discarding it'
  	    if DEBUG;

      $kernel->post(
         $self->errorhandler->{SESSION},
         $self->errorhandler->{EVENT},
         'Wheel disappeared !'
      ) if $self->errorhandler and $self->errorhandler->{SESSION} and $self->errorhandler->{EVENT};

      # All done!
      return 1;
   }

   # Quick check to see if the wheel/socket died already...
   # Initially reported by Tim Wood
   unless (  $self->_requests->{$id}->wheel_alive ) {
      warn 'Tried to send data over a closed/nonexistant socket!' if DEBUG;
      $kernel->post(
         $self->errorhandler->{SESSION},
         $self->errorhandler->{EVENT},
         'Socket closed/nonexistant !'
      ) if $self->errorhandler and $self->errorhandler->{SESSION} and $self->errorhandler->{EVENT};
      return;
   }

   $self->fix_headers( $response, 1 );

   # Sets the correct POE::Filter
   unless ( defined $response->IS_STREAMING ) {

      # Mark this socket done
      $self->_requests->{$id}->set_streaming(1);
      $response->set_streaming(1);
   }

   if (DEBUG) {
      warn "Sending stream via "
        . $response->STREAM_SESSION . "/"
        . $response->STREAM
        . " with id $id \n";
   }

   if ( $self->_chunkcount->{$id} > 1 ) {
      my $wheel = $self->_requests->{ $response->_WHEEL }->wheel;
      $wheel->set_output_filter( POE::Filter::Stream->new() );
      $wheel->put( $response->content );
   }
   else {
      my $wheel = $self->_requests->{ $response->_WHEEL }->wheel;
      $wheel->set_output_filter( $wheel->get_input_filter() );
      $wheel->put($response);
   }

   # we send the event to stream with wheels request and response to the session
   # that has registered the streaming event
   unless ( $response->DONT_FLUSH ) {
      $kernel->post(
         $response->STREAM_SESSION,    # callback session
         $response->STREAM,            # callback event
         $self->_responses->{ $response->_WHEEL }
      );
   }

   # Success!
   return 1;
};

# Add required headers to a response
sub fix_headers {
   my ( $self, $response, $stream ) = @_;

   # Set the date if needed
   if ( !$response->header('Date') ) {
      $response->header( 'Date', time2str(time) );
   }

   # Set the Content-Length if needed
   if (   !$stream and !$self->proxymode
      and !defined $response->header('Content-Length')
      and my $len = length $response->content )
   {
      use bytes;
      $response->header( 'Content-Length', $len );
   }

   # Set the Content-Type if needed
   if ( !$response->header('Content-Type') ) {
      $response->header( 'Content-Type', 'text/plain' );
   }

   if ( !$response->protocol ) {
      my $request = $self->_requests->{ $response->_WHEEL }->request;
      return unless $request and $request->isa('HTTP::Request');
      unless ( $request->method eq 'HEAD' ) {
         $response->protocol( $request->protocol );
      }
   }
}

# 'CLOSE'
# Closes the connection
event 'CLOSE' => sub {
   my ($kernel,$self,$response) = @_[KERNEL,OBJECT,ARG0];

   # Check if we got it
   unless ( defined $response and UNIVERSAL::isa( $response, 'HTTP::Response' ) ) {
      warn 'Did not get a HTTP::Response object!' if DEBUG;
      # Abort...
      return;
   }

   # Get the wheel ID
   my $id = $response->_WHEEL;

   if ( $self->_connections->{$id} ) {
      $self->_requests->{$id} = delete $self->_connections->{$id};
   }

   # Check if the wheel exists ( sometimes it gets closed by the client, but the application doesn't know that... )
   unless ( exists $self->_requests->{$id} ) {
      warn
        'Wheel disappeared, but the application sent us a CLOSE event, discarding it'
	    if DEBUG;
      return 1;
   }

   # Kill it!
   $self->_requests->{$id}->close_wheel if $self->_requests->{$id}->wheel_alive;

   # Delete it!
   delete $self->_requests->{$id};
   delete $self->_responses->{$id};

   warn 'Delete references to the connection done.' if DEBUG;

   # All done!
   return 1;
};

# Registers a POE inline state (primarly for streaming)
event 'REGISTER' => sub {
   my ( $session, $state, $code_ref ) = @_[ SESSION, ARG0 .. ARG1 ];
   warn 'Registering state in POE session' if DEBUG;
   return $session->register_state( $state, $code_ref );
};

# SETCLOSEHANDLER
event 'SETCLOSEHANDLER' => sub {
   my ($self,$sender) = @_[OBJECT,SENDER ];
   my ($connection,$state,@params) = @_[ARG0..$#_];

   # turn connection ID into the connection object
   unless ( ref $connection ) {
      my $id = $connection;
      if ( $self->_connections->{$id} ) {
         $connection = $self->_connections->{$id}->connection;
      }
      elsif ($self->_requests->{$id}
         and $self->_requests->{$id}->response )
      {
         $connection = $self->_requests->{$id}->response->connection;
      }
      unless ( ref $connection ) {
         die "Can't find connection object for request $id";
      }
   }

   if ($state) {
      $connection->_on_close( $sender->ID, $state, @params );
   }
   else {
      $connection->_on_close($sender->ID);
   }
};

no MooseX::POE;

__PACKAGE__->meta->make_immutable( );

"Simple In'it";

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::SimpleHTTP - Perl extension to serve HTTP requests in POE.

=head1 VERSION

version 2.28

=head1 SYNOPSIS

	use POE;
	use POE::Component::Server::SimpleHTTP;

	# Start the server!
	POE::Component::Server::SimpleHTTP->new(
		'ALIAS'		=>	'HTTPD',
		'PORT'		=>	11111,
		'HOSTNAME'	=>	'MySite.com',
		'HANDLERS'	=>	[
			{
				'DIR'		=>	'^/bar/.*',
				'SESSION'	=>	'HTTP_GET',
				'EVENT'		=>	'GOT_BAR',
			},
			{
				'DIR'		=>	'^/$',
				'SESSION'	=>	'HTTP_GET',
				'EVENT'		=>	'GOT_MAIN',
			},
			{
				'DIR'		=>	'^/foo/.*',
				'SESSION'	=>	'HTTP_GET',
				'EVENT'		=>	'GOT_NULL',
			},
			{
				'DIR'		=>	'.*',
				'SESSION'	=>	'HTTP_GET',
				'EVENT'		=>	'GOT_ERROR',
			},
		],

		'LOGHANDLER' => { 'SESSION' => 'HTTP_GET',
				  'EVENT'   => 'GOT_LOG',
		},

		'LOG2HANDLER' => { 'SESSION' => 'HTTP_GET',
				  'EVENT'   => 'POSTLOG',
		},

		# In the testing phase...
		'SSLKEYCERT'	=>	[ 'private-key.pem', 'public-cert.pem' ],
		'SSLINTERMEDIATECACERT'	=>	'intermediate-ca-cert.pem',
	) or die 'Unable to create the HTTP Server';

	# Create our own session to receive events from SimpleHTTP
	POE::Session->create(
		inline_states => {
			'_start'	=>	sub {	$_[KERNEL]->alias_set( 'HTTP_GET' );
							$_[KERNEL]->post( 'HTTPD', 'GETHANDLERS', $_[SESSION], 'GOT_HANDLERS' );
						},

			'GOT_BAR'	=>	\&GOT_REQ,
			'GOT_MAIN'	=>	\&GOT_REQ,
			'GOT_ERROR'	=>	\&GOT_ERR,
			'GOT_NULL'	=>	\&GOT_NULL,
			'GOT_HANDLERS'	=>	\&GOT_HANDLERS,
			'GOT_LOG'       =>      \&GOT_LOG,
		},
	);

	# Start POE!
	POE::Kernel->run();

	sub GOT_HANDLERS {
		# ARG0 = HANDLERS array
		my $handlers = $_[ ARG0 ];

		# Move the first handler to the last one
		push( @$handlers, shift( @$handlers ) );

		# Send it off!
		$_[KERNEL]->post( 'HTTPD', 'SETHANDLERS', $handlers );
	}

	sub GOT_NULL {
		# ARG0 = HTTP::Request object, ARG1 = HTTP::Response object, ARG2 = the DIR that matched
		my( $request, $response, $dirmatch ) = @_[ ARG0 .. ARG2 ];

		# Kill this!
		$_[KERNEL]->post( 'HTTPD', 'CLOSE', $response );
	}

	sub GOT_REQ {
		# ARG0 = HTTP::Request object, ARG1 = HTTP::Response object, ARG2 = the DIR that matched
		my( $request, $response, $dirmatch ) = @_[ ARG0 .. ARG2 ];

		# Do our stuff to HTTP::Response
		$response->code( 200 );
		$response->content( 'Some funky HTML here' );

		# We are done!
		# For speed, you could use $_[KERNEL]->call( ... )
		$_[KERNEL]->post( 'HTTPD', 'DONE', $response );
	}

	sub GOT_ERR {
		# ARG0 = HTTP::Request object, ARG1 = HTTP::Response object, ARG2 = the DIR that matched
		my( $request, $response, $dirmatch ) = @_[ ARG0 .. ARG2 ];

		# Check for errors
		if ( ! defined $request ) {
			$_[KERNEL]->post( 'HTTPD', 'DONE', $response );
			return;
		}

		# Do our stuff to HTTP::Response
		$response->code( 404 );
		$response->content( "Hi visitor from " . $response->connection->remote_ip . ", Page not found -> '" . $request->uri->path . "'" );

		# We are done!
		# For speed, you could use $_[KERNEL]->call( ... )
		$_[KERNEL]->post( 'HTTPD', 'DONE', $response );
	}

	sub GOT_LOG {
		# ARG0 = HTTP::Request object, ARG1 = remote IP
		my ($request, $remote_ip) = @_[ARG0,ARG1];

		# Do some sort of logging activity.
		# If the request was malformed, $request = undef
		# CHECK FOR A REQUEST OBJECT BEFORE USING IT.
        if( $request ) {
        {
       		warn join(' ', time(), $remote_ip, $request->uri ), "\n";
        } else {
       		warn join(' ', time(), $remote_ip, 'Bad request' ), "\n";
        }

		return;
	}

=head1 DESCRIPTION

This module makes serving up HTTP requests a breeze in POE.

The hardest thing to understand in this module is the HANDLERS. That's it!

The standard way to use this module is to do this:

	use POE;
	use POE::Component::Server::SimpleHTTP;

	POE::Component::Server::SimpleHTTP->new( ... );

	POE::Session->create( ... );

	POE::Kernel->run();

=head2 Starting SimpleHTTP

To start SimpleHTTP, just call it's new method:

	POE::Component::Server::SimpleHTTP->new(
		'ALIAS'		=>	'HTTPD',
		'ADDRESS'	=>	'192.168.1.1',
		'PORT'		=>	11111,
		'HOSTNAME'	=>	'MySite.com',
		'HEADERS'	=>	{},
		'HANDLERS'	=>	[ ],
	);

This method will die on error or return success.

This constructor accepts only 7 options.

=over 4

=item C<ALIAS>

This will set the alias SimpleHTTP uses in the POE Kernel.
This will default to "SimpleHTTP"

=item C<ADDRESS>

This value will be passed to POE::Wheel::SocketFactory to bind to, will use
INADDR_ANY if it is nothing is provided (or IN6ADDR_ANY if DOMAIN is AF_INET6).
For UNIX domain sockets, it should be a path describing the socket's filename.

If neither DOMAIN nor ADDRESS are specified, it will use IN6ADDR_ANY and
AF_INET6.

=item C<PORT>

This value will be passed to POE::Wheel::SocketFactory to bind to.

=item C<DOMAIN>

This value will be passed to POE::Wheel::SocketFactory to define the socket
domain used (AF_INET, AF_INET6, AF_UNIX).

=item C<HOSTNAME>

This value is for the HTTP::Request's URI to point to.
If this is not supplied, SimpleHTTP will use Sys::Hostname to find it.

=item C<HEADERS>

This should be a hashref, that will become the default headers on all HTTP::Response objects.
You can override this in individual requests by setting it via $request->header( ... )

For more information, consult the L<HTTP::Headers> module.

=item C<HANDLERS>

This is the hardest part of SimpleHTTP :)

You supply an array, with each element being a hash. All the hashes should contain those 3 keys:

DIR	->	The regexp that will be used, more later.

SESSION	->	The session to send the input

EVENT	->	The event to trigger

The DIR key should be a valid regexp. This will be matched against the current request path.
Pseudocode is: if ( $path =~ /$DIR/ )

NOTE: The path is UNIX style, not MSWIN style ( /blah/foo not \blah\foo )

Now, if you supply 100 handlers, how will SimpleHTTP know what to do? Simple! By passing in an array in the first place,
you have already told SimpleHTTP the order of your handlers. They will be tried in order, and if a match is not found,
SimpleHTTP will return a 404 response.

This allows some cool things like specifying 3 handlers with DIR of:
'^/foo/.*', '^/$', '.*'

Now, if the request is not in /foo or not root, your 3rd handler will catch it, becoming the "404 not found" handler!

NOTE: You might get weird Session/Events, make sure your handlers are in order, for example: '^/', '^/foo/.*'
The 2nd handler will NEVER get any requests, as the first one will match ( no $ in the regex )

Now, here's what a handler receives:

ARG0 -> HTTP::Request object

ARG1 -> POE::Component::Server::SimpleHTTP::Response object

ARG2 -> The exact DIR that matched, so you can see what triggered what

NOTE: If ARG0 is undef, that means POE::Filter::HTTPD encountered an error parsing the client request, simply modify the HTTP::Response
object and send some sort of generic error. SimpleHTTP will set the path used in matching the DIR regexes to an empty string, so if there
is a "catch-all" DIR regex like '.*', it will catch the errors, and only that one.

NOTE: The only way SimpleHTTP will leak memory ( hopefully heh ) is if you discard the SimpleHTTP::Response object without sending it
back to SimpleHTTP via the DONE/CLOSE events, so never do that!

=item C<KEEPALIVE>

Set to true to enable HTTP keep-alive support.  Connections will be
kept alive until the client closes the connection.  All HTTP/1.1 connections
are kept-open, unless you set the response C<Connection> header to C<close>.

    $response->header( Connection => 'close' );

If you want more control, use L<POE::Component::Server::HTTP::KeepAlive>.

=item C<LOGHANDLER>

Expects a hashref with the following key, values:

SESSION	->	The session to send the input

EVENT	->	The event to trigger

You will receive an event for each request to the server from clients.  Malformed client requests will not be passed into the handler.  Instead
undef will be passed.
Event is called before ANY content handler is called.

The event will have the following parameters:

ARG0 -> HTTP::Request object/undef if client request was malformed.

ARG1 -> the IP address of the client

=item C<LOG2HANDLER>

Expect a hashref with the following key, values:

SESSION	->	The session to send the input

EVENT	->	The event to trigger

You will receive an event for each response that hit DONE call. Malformed client requests will not be passed into the handler.
Event is after processing all content handlers.

The event will have the following parameters:

ARG0 -> HTTP::Request object

ARG1 -> HTTP::Response object

That makes possible following code:

	my ($login, $password) = $request->authorization_basic();
	printf STDERR "%s - %s [%s] \"%s %s %s\" %d %d\n",
		$response->connection->remote_ip, $login||'-', POSIX::strftime("%d/%b/%Y:%T %z",localtime(time())),
		$request->method(), $request->uri()->path(), $request->protocol(),
		$response->code(), length($response->content());

Emulate apache-like logs for PoCo::Server::SimpleHTTP

=item C<SETUPHANDLER>

Expects a hashref with the following key, values:

SESSION	->	The session to send the input

EVENT	->	The event to trigger

You will receive an event when the listener wheel has been setup.

Currently there are no parameters returned.

=item C<SSLKEYCERT>

This should be an arrayref of only 2 elements - the private key and public certificate locations. Now, this is still in the experimental stage, and testing
is greatly welcome!

Again, this will automatically turn every incoming connection into a SSL socket. Once enough testing has been done, this option will be augmented with more SSL stuff!

=item C<SSLINTERMEDIATECACERT>

This option is needed in case the SSL certificate references an intermediate certification authority certificate.

=item C<PROXYMODE>

Set this to a true value to enable the server to act as a proxy server, ie. it won't mangle the HTTP::Request
URI.

=back

=head2 Events

SimpleHTTP is so simple, there are only 8 events available.

=over 4

=item C<DONE>

	This event accepts only one argument: the HTTP::Response object we sent to the handler.

	Calling this event implies that this particular request is done, and will proceed to close the socket.

	NOTE: This method automatically sets those 3 headers if they are not already set:
		Date		->	Current date stringified via HTTP::Date->time2str
		Content-Type	->	text/html
		Content-Length	->	length( $response->content )

	To get greater throughput and response time, do not post() to the DONE event, call() it!
	However, this will force your program to block while servicing web requests...

=item C<CLOSE>

	This event accepts only one argument: the HTTP::Response object we sent to the handler.

	Calling this event will close the socket, not sending any output

=item C<GETHANDLERS>

	This event accepts 2 arguments: The session + event to send the response to

	This event will send back the current HANDLERS array ( deep-cloned via Storable::dclone )

	The resulting array can be played around to your tastes, then once you are done...

=item C<SETHANDLERS>

	This event accepts only one argument: pointer to HANDLERS array

	BEWARE: if there is an error in the HANDLERS, SimpleHTTP will die!

=item C<SETCLOSEHANDLER>

    $_[KERNEL]->call( $_[SENDER], 'SETCLOSEHANDLER', $connection,
                      $event, @args );

Calls C<$event> in the current session when C<$connection> is closed.  You
could use for persistent connection handling.

Multiple session may register close handlers.

Calling SETCLOSEHANDLER without C<$event> to remove the current session's
handler:

   $_[KERNEL]->call( $_[SENDER], 'SETCLOSEHANDLER', $connection );

You B<must> make sure that C<@args> doesn't cause a circular
reference.  Ideally, use C<$connection->ID> or some other unique value
associated with this C<$connection>.

=item C<STARTLISTEN>

	Starts the listening socket, if it was shut down

=item C<STOPLISTEN>

	Simply a wrapper for SHUTDOWN GRACEFUL, but will not shutdown SimpleHTTP if there is no more requests

=item C<SHUTDOWN>

	Without arguments, SimpleHTTP does this:
		Close the listening socket
		Kills all pending requests by closing their sockets
		Removes it's alias

	With an argument of 'GRACEFUL', SimpleHTTP does this:
		Close the listening socket
		Waits for all pending requests to come in via DONE/CLOSE, then removes it's alias

=item C<STREAM>

	With a $response argument it streams the content and calls back the streaming event
	of the user's session (or with the dont_flush option you're responsible for calling
        back your session's streaming event).

	To use the streaming feature see below.

=back

=head2 Streaming with SimpleHTTP

It's possible to send data as a stream to clients (unbuffered and integrated in the
POE loop).

Just create your session to receive events from SimpleHTTP as usually and add a
streaming event, this event will be triggered over and over each time you set the
$response to a streaming state and once you trigger it:

   # sets the response as streamed within our session which alias is HTTP_GET
   # with the event GOT_STREAM
   $response->stream(
      session     => 'HTTP_GET',
      event       => 'GOT_STREAM',
      dont_flush  => 1
   );

   # then you can simply yield your streaming event, once the GOT_STREAM event
   # has reached its end it will be triggered again and again, until you
   # send a CLOSE event to the kernel with the appropriate response as parameter
   $kernel->yield('GOT_STREAM', $response);

The optional dont_flush option gives the user the ability to control the callback
to the streaming event, which means once your stream event has reached its end
it won't be called, you have to call it back.

You can now send data by chunks and either call yourself back (via POE) or
shutdown when your streaming is done (EOF for example).

   sub GOT_STREAM {
      my ( $kernel, $heap, $response ) = @_[KERNEL, HEAP, ARG0];

      # sets the content of the response
      $response->content("Hello World\n");

      # send it to the client
      POE::Kernel->post('HTTPD', 'STREAM', $response);

      # if we have previously set the dont_flush option
      # we have to trigger our event back until the end of
      # the stream like this (that can be a yield, of course):
      #
      # $kernel->delay('GOT_STREAM', 1, $stream );

      # otherwise the GOT_STREAM event is triggered continuously until
      # we call the CLOSE event on the response like that :
      #
      if ($heap{'streaming_is_done'}) {
         # close the socket and end the stream
         POE::Kernel->post('HTTPD', 'CLOSE', $response );
      }
   }

The dont_flush option is there to be able to control the frequency of flushes
to the client.

=head2 SimpleHTTP Notes

You can enable debugging mode by doing this:

	sub POE::Component::Server::SimpleHTTP::DEBUG () { 1 }
	use POE::Component::Server::SimpleHTTP;

Also, this module will try to keep the Listening socket alive.
if it dies, it will open it again for a max of 5 retries.

You can override this behavior by doing this:

	sub POE::Component::Server::SimpleHTTP::MAX_RETRIES () { 10 }
	use POE::Component::Server::SimpleHTTP;

For those who are pondering about basic-authentication, here's a tiny snippet to put in the Event handler

	# Contributed by Rocco Caputo
	sub Got_Request {
		# ARG0 = HTTP::Request, ARG1 = HTTP::Response
		my( $request, $response ) = @_[ ARG0, ARG1 ];

		# Get the login
		my ( $login, $password ) = $request->authorization_basic();

		# Decide what to do
		if ( ! defined $login or ! defined $password ) {
			# Set the authorization
			$response->header( 'WWW-Authenticate' => 'Basic realm="MyRealm"' );
			$response->code( 401 );
			$response->content( 'FORBIDDEN.' );

			# Send it off!
			$_[KERNEL]->post( 'SimpleHTTP', 'DONE', $response );
		} else {
			# Authenticate the user and move on
		}
	}

=head2 EXPORT

Nothing.

=for Pod::Coverage        MassageHandlers
       START
       STOP
       fix_headers
       getsockname
       must_keepalive
       session_id
       shutdown

=head1 ABSTRACT

	An easy to use HTTP daemon for POE-enabled programs

=head1 SEE ALSO

	L<POE>

	L<POE::Filter::HTTPD>

	L<HTTP::Request>

	L<HTTP::Response>

	L<POE::Component::Server::SimpleHTTP::Connection>

	L<POE::Component::Server::SimpleHTTP::Response>

	L<POE::Component::Server::SimpleHTTP::PreFork>

	L<POE::Component::SSLify>

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Apocalypse, Chris Williams, Eriam Schaffter, Marlon Bailey and Philip Gwyn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
