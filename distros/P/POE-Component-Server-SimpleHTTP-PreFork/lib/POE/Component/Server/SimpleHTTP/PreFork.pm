package POE::Component::Server::SimpleHTTP::PreFork;

use strict;
use warnings;

our $VERSION = '2.10';

use POE;
use Socket;
use Carp qw( croak );
use HTTP::Date qw( time2str );
use IPC::Shareable qw( :lock );
use POE::Component::Server::SimpleHTTP;

# Set some constants
BEGIN {

   # Interval at which to check spares
   if ( !defined &CHECKSPARES_INTERVAL ) {
      eval "sub CHECKSPARES_INTERVAL () { 1 }";
   }

   # Interval at which to retry preforking
   if ( !defined &PREFORK_INTERVAL ) {
      eval "sub PREFORK_INTERVAL () { 5 }";
   }

   # If true, show the scoreboard every second
   if ( !defined &DEBUGSB ) {
      eval "sub DEBUGSB () { 0 }";
   }
}

use MooseX::POE;
use Moose::Util::TypeConstraints;

extends 'POE::Component::Server::SimpleHTTP';

has 'forkhandlers' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub {{}},
  writer => 'set_forkhandlers',
);

has 'minspareservers' => (
  is => 'ro',
  default => sub { 5 },
  isa => subtype 'Int' => where { $_ > 0 },
);

# maxspareservers must be greater than minspareservers
has 'maxspareservers' => (
  is => 'ro',
  isa => 'Int',
  default => sub { 10 },
);

has 'maxclients' => (
  is => 'ro',
  isa => 'Int',
  default => sub { 256 },
);

has 'maxrequestperchild' => (
  is => 'ro',
  isa => subtype 'Int' => where { $_ > 0 },
);

# startservers must be greater than minspareservers
has 'startservers' => (
  is => 'ro',
  default => sub { 10 },
  isa => subtype 'Int' => where { $_ > 0 },
);

has 'scoreboard' => (
  is => 'ro',
  isa => 'HashRef',
  clearer => 'wipe_scoreboard',
  writer => 'set_scoreboard',
  init_arg => undef,
);

has 'is_child' => (
  is => 'ro',
  isa => 'Bool',
  writer => 'am_child',
  clearer => 'not_child',
  default => sub { 0 },
  init_arg => undef,
);

has 'reqcount' => (
  traits    => ['Counter'],
  is        => 'ro',
  isa       => 'Num',
  default   => sub { 0 },
  handles  => {
    'inc_reqcount', 'inc',
    'dec_reqcount', 'dec',
    'reset_reqcount', 'reset',
  },
);

has 'ipc_glue' => (
  is      => 'ro',
  default => 'scbd',
  isa     => subtype 'Str' => where { $_ =~ /^\d+$/s || length $_ == 4 },
);

sub START {
  $poe_kernel->sig( TERM => '_sig_term' );
  #$poe_kernel->sig( CHLD => '_sig_chld' );
  return;
}

# 'SHUTDOWN'
# Stops the server!
event 'SHUTDOWN' => sub {
   my ($kernel,$self,$session,$graceful) = @_[KERNEL,OBJECT,SESSION,ARG0];
   # Shutdown the SocketFactory wheel
   $self->_clear_factory if $self->_factory;

   # Debug stuff
   warn 'Stopped listening for new connections!'
     if POE::Component::Server::SimpleHTTP::DEBUG;

   my $children;

   if ( $graceful ) {
      # Attempt to gracefully kill the children.
      $children = $kernel->call( $session, 'kill_children', 'TERM' );

      # Check for number of requests, and children.
      if ( keys( %{ $self->_requests } ) == 0 and $children == 0 ) {

         # Alright, shutdown anyway

         # Delete our alias
         $kernel->alias_remove( $_ ) for $kernel->alias_list();
         $kernel->refcount_decrement( $self->get_session_id, __PACKAGE__ )
           unless $self->alias;

         # Destroy all memory segments created by this process.
         IPC::Shareable->clean_up;
         $self->wipe_scoreboard;

         # Debug stuff
         warn 'Stopped SimpleHTTP gracefully, no requests left'
           if POE::Component::Server::SimpleHTTP::DEBUG;

      }

      # All done!
      return 1;
   }

   # CheckSpares need to know that we're shutting down
   $self->scoreboard->{'shutdown'} = 1;

   # Forcefully kill all the children.
   $kernel->call( $session, 'kill_children', 'KILL' );

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

   # Remove any shared memory segments.
   IPC::Shareable->clean_up;
   $self->wipe_scoreboard;

   # Delete our alias
   $kernel->alias_remove( $_ ) for $kernel->alias_list();
   $kernel->refcount_decrement( $self->get_session_id, __PACKAGE__ )
      unless $self->alias;


   warn 'Successfully stopped SimpleHTTP'
      if POE::Component::Server::SimpleHTTP::DEBUG;

   # Return success
   return 1;
};

# Sets up the SocketFactory wheel :)
event 'start_listener' => sub {
   my ($kernel,$self,$noinc) = @_[KERNEL,OBJECT,ARG0];

   warn 'Creating SocketFactory wheel now'
    if POE::Component::Server::SimpleHTTP::DEBUG;

   # Only try to re-establish the listener if we are the parent
   if ( $self->is_child ) {
      warn 'Inside the child. Aborting attempt to reestablish the listener.';
      return 0;
   }

   # Check if we should set up the wheel
   if ( $self->retries == POE::Component::Server::SimpleHTTP::MAX_RETRIES ) {
      die 'POE::Component::Server::SimpleHTTP tried '
        . POE::Component::Server::SimpleHTTP::MAX_RETRIES
        . ' times to create a Wheel and is giving up...';
   }
   else {

      $self->inc_retry unless $noinc;

      # Create our own SocketFactory Wheel :)
      my $factory = POE::Wheel::SocketFactory->new(
         BindPort     => $self->port,
         ( $self->address ? ( BindAddress => $self->address ) : () ),
         Reuse        => 'yes',
         SuccessEvent => 'got_connection',
         FailureEvent => 'listener_error',
      );

      my ( $port, $address ) =
        sockaddr_in( $factory->getsockname );
      $self->_set_port( $port ) if $self->port == 0;

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

      # Pre-fork if that is what was requested
      if ( $self->startservers ) {

         # We don't want to accept socket connections in the parent process
         $self->_factory->pause_accept();

         # Wait a bit and then do the actual forking
         $kernel->yield( 'prefork', $self->_factory );
      }
   }

   return 1;
};

# Stops listening on the socket
event 'STOPLISTEN' => sub {
   my ($kernel,$self,$session) = @_[KERNEL,OBJECT,SESSION];

   if ( $self->is_child ) {

      # If we are the child then we shouldn't really stop listening.
      # Instead, pause accepting on our SocketFactory.
      unless (  $self->_factory ) {
         warn "Cannot StopListen on a non-existant SOCKETFACTORY in child $$";
         return 0;
      }
      else {

         # Pause accepting.
         $self->_factory->pause_accept();
         return 1;
      }
   }
   else {

      # We are in the parent, so truly stop listening.
      # Kill the children because they are still listenning.
      $kernel->call( $session, 'kill_children', 'TERM' );

      # Call the super class method.
      shift;
      return $self->SUPER::STOPLISTEN(@_);
   }
};

event 'STARTLISTEN' => sub {
   my ($kernel,$self) = @_[KERNEL,OBJECT];

   if ( $self->is_child ) {

      # If we are the child then we can't really create a new SOCKETFACTORY.
      # Instead, we can resume accepting on our current SOCKETFACTORY.
      unless (  $self->_factory ) {
         warn "Cannot StartListen on a non-existant SOCKETFACTORY in child $$";
         return 0;
      }
      else {

         # Resume accepting.
         $self->_factory->resume_accept();
         return 1;
      }
   }
   else {

      # We are the parent. Truly start listening again.
      shift;
      return $self->SUPER::STARTLISTEN(@_);
   }
};

# Sets the HANDLERS
event 'SETHANDLERS' => sub {
  my $self = $_[OBJECT];

  # Setting handlers in a child makes little sense, so abort if this is the case
   if ( $self->is_child ) {
      warn "Child $$ tried to set the handlers for SimpleHTTP.";
      return 0;
   }

   # Call the super class method.
   shift;
   return $self->SUPER::SETHANDLERS(@_);
};

# The actual manager of connections
event 'got_connection' => sub {
   my ($kernel,$self) = @_[KERNEL,OBJECT];
   shift;
   $self->SUPER::got_connection(@_);
   # Update the scoreboard.
   $kernel->call( $_[SESSION], 'UpdateScoreboard' );
   return 1;
};

# Finally got input, set some stuff and send away!
event 'got_input' => sub {
   my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG1];
   # Call the super class method.
   shift;
   my $rv = $self->SUPER::got_input(@_);
   # If the connection died/failed for some reason then the request is deleted.
   # In this case, we have to update the scoreboard.
   $kernel->call( $_[SESSION], 'UpdateScoreboard' )
      unless exists $self->_requests->{$id};
   return $rv;
};

# Finished with a request!
event 'got_flush' => sub {
   my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];

   # Call the super class method.
   shift;
   my $rv = $self->SUPER::got_flush(@_);

   # Deal with maxrequestperchild
   if ( $self->is_child and defined $self->maxrequestperchild ) {
      $self->inc_reqcount;

      if ( $self->reqcount >= $self->maxrequestperchild) {
         warn "Shutting down $$ because it reached MAXREQUESTPERCHILD."
            if POE::Component::Server::SimpleHTTP::DEBUG;

         $kernel->yield( 'SHUTDOWN', 'GRACEFUL' );
         return 1;
      }
   }

   # If the connection died/failed for some reason then the request is deleted.
   # In this case, we have to update the scoreboard.
   $kernel->call( $_[SESSION], 'update_scoreboard' )
      unless exists $self->_requests->{$id};
   return $rv;
};

# Got some sort of error from ReadWrite
event 'got_error' => sub {
   my ($kernel,$self) = @_[KERNEL,OBJECT];
   # Call the super class method.
   # but first shift @_ otherwise $self->SUPER::got_error(@_) results in
   # $self/OBJECT being in the first two values in @_ param array to
   # SimpleHTTP got_error method instead of just the first value
   shift @_;
   my $rv = $self->SUPER::got_error(@_);
   # The connection was probably cleared, so update the scoreboard.
   $kernel->call( $_[SESSION], 'update_scoreboard' );
   return $rv;
};

# Closes the connection
event 'CLOSE' => sub {
   my ($kernel,$self) = @_[KERNEL,OBJECT];
   # Call the super class method.
   my $rv = $self->SUPER::CLOSE(@_);
   # The connection was probably cleared, so update the scoreboard.
   $kernel->call( $_[SESSION], 'update_scoreboard' );
   return $rv;
};

# PreFork the initial instances.
event 'prefork' => sub {
   # ARG0 = SocketFactory
   my ($kernel,$self,$session,$sf) = @_[KERNEL,OBJECT,SESSION,ARG0];
   my ($scoreboard,$mem);

   warn 'Trying to prefork.'
     if POE::Component::Server::SimpleHTTP::DEBUG;

   # Only the parent is allowed to fork
   if ( $self->is_child ) {
      warn "Cannot pre-fork from child $$.";
      return 0;
   }

   # Make that the current SF is the same as the one we were called for.
   # If not, then that means and error occured sometime inbetween.
   unless ( defined $self->_factory and $sf == $self->_factory ) {
      warn 'Aborting pre-fork because the SocketFactory is not the same.';
      return 0;
   }

   # Initialize the scoreboard the first time around.
   unless ( defined $self->scoreboard ) {
      my %temp;

# In order to keep a pool of spare children we need to know how many spares there are.
      $mem = tie %temp, 'IPC::Shareable', $self->ipc_glue,
        { 'create' => 1, 'mode' => 0600 };
      $scoreboard = \%temp;
   }
   else {

      # We already have a scoreboard from a previous listen attempt.
      $scoreboard = $self->scoreboard;
      $mem        = tied %$scoreboard;
   }

   unless ( defined $mem ) {
      warn
        'Cannot tie to the shared memory segment. Will try again in 5 seconds.';
      $kernel->delay_set( 'prefork', PREFORK_INTERVAL, $sf );
      return 0;
   }
   else {

      # Clear the variable and store it for later use.
      %{ $scoreboard } = ( 'spares' => 0, 'actives' => 0 );
      $self->set_scoreboard( $scoreboard );
   }

   for ( 1 .. $self->startservers ) {
      my $pid = fork();

      if ( not defined $pid ) {

         # Make sure this fork succeeded.
         warn "Server $$ fork failed: $!";
         next;
      }
      elsif ($pid) {

         # We are the parent.
         $kernel->sig_child( $pid, '_sig_chld' );
         next;
      }
      else {

         warn "Forked child $$."
            if POE::Component::Server::SimpleHTTP::DEBUG;

         # We are the child. Do something "childish".
         $self->am_child( 1 );
         $kernel->call( $session, 'add_scoreboard' );

         # Notify the other forked sessions that we have forked.
         foreach my $sess ( keys( %{ $self->forkhandlers } ) ) {
            $kernel->call( $sess, $self->forkhandlers->{$sess} );
         }

         # Get to work!
         $sf->resume_accept();
         return 1;
      }
   }

   # Pre-forking is done and our children are happily away!
   # We are the parent, so start monitoring the spare pool.
   $kernel->delay_set( 'check_spares', CHECKSPARES_INTERVAL );

   # Let the developer see the scoreboard if they want.
   if (DEBUGSB) {
      $kernel->delay_set( 'show_scoreboard', 1 );
   }
};

# True if this is a child.
event 'ISCHILD' => sub {
   return $_[OBJECT]->is_child;
};

# Kill all our children, and return the number we sent signals too.
event 'kill_children' => sub {
   my ($kernel,$self,$sig) = @_[KERNEL,OBJECT,ARG0];
   my ($children,$scoreboard,$mem) = 0;

   # By default, kill them nicely.
   $sig = 'TERM' unless defined $sig;

   # Make sure we are the parent AND preforked.
   unless ( $self->is_child ) {
      warn "Killing children from $$ with signal $sig."
         if POE::Component::Server::SimpleHTTP::DEBUG;

      $scoreboard = $self->scoreboard;
      $mem        = tied %$scoreboard;
      if ( not defined $mem ) {

         # There was an error, but there's nothing we can do,
         # so just exit.
         warn "Parent's SCOREBOARD is not tied!";
         $children = 0;
      }
      else {

         # Get a count of the number of children, and start killing them
         $mem->shlock(LOCK_SH);

         # The children haven't already received a signal, so send them one.
         foreach my $pid ( keys %$scoreboard ) {
            if ( ( $pid ne 'actives' ) && ( $pid ne 'spares' ) ) {
               ++$children;
               kill $sig, $pid;
            }
         }
         $mem->shlock(LOCK_UN);

         # Check to make sure it is sane.
         if ( $children < 0 ) {
            warn "The child count is negative: $children.";
            $children = 0;
         }
      }
   }

   #
   $kernel->delay_set('check_spares');

   return $children;
};

# Sets the FORKHANDLERS
event 'SETFORKHANDLERS' => sub {
   # ARG0 = ref to handlers hash
   my ($self,$handlers) = @_[OBJECT,ARG0];

   # Setting handlers in a child makes little sense, so abort if this is the case.
   if ( $self->is_child ) {
      warn "Child $$ tried to set the handlers for SimpleHTTP.";
      return 0;
   }

   # Validate it...
   unless ( defined $handlers and ref $handlers eq 'HASH' ) {
      warn "FORKHANDLERS is not in the proper format.";
      return 0;
   }

   # If we got here, passed tests!
   $self->set_forkhandlers( $handlers );

   # All done!
   return 1;
};

# Gets the FORKHANDLERS
event 'GETFORKHANDLERS' => sub {
   # ARG0 = session, ARG1 = event
   my ($kernel,$self,$session,$event) = @_[KERNEL,OBJECT,ARG0,ARG1];

   # Validation
   return undef unless defined $session and defined $event;

   # Make a deep copy of the handlers
   require Storable;

   my $handlers = Storable::dclone( $self->forkhandlers );

   # All done!
   $kernel->post( $session, $event, $handlers );

   # All done!
   return 1;
};

# Check to see if we need a new spare.
event 'check_spares' => sub {
   my ($kernel,$self,$session) = @_[KERNEL,OBJECT,SESSION];
   my ($scoreboard,$mem);

   # Make sure that we are not a child.
   if ( $self->is_child ) {
      warn "Child $$ trying to check the spares!";
      return 0;
   }

   # Make sure there is still a socket factory. If not, then this server
   # is shutting down.
   unless ( defined $self->_factory ) {
      warn 'Ending CheckSpares on the parent.'
         if POE::Component::Server::SimpleHTTP::DEBUG;
      return 1;
   }

   # Retrieve the shared memory variable.
   $scoreboard = $self->scoreboard;

   # in the test for maxrequestperchild the only
   # way to have CheckSpare aware that we're shutting down
   # is using this shared variable
   if ( defined $scoreboard->{'shutdown'} ) {
      warn 'Shutdown in progress, checkspare is useless'
         if POE::Component::Server::SimpleHTTP::DEBUG;
      return 1;
   }

   $mem = tied %$scoreboard if defined $scoreboard;
   unless ( defined $mem ) {
      warn 'SCOREBOARD is not tied! Aborting.';
      return 0;
   }

   # Check to see if we need another spare, and if so make sure we don't
   # already have more than enough clients.
   $mem->shlock(LOCK_SH);
   if (  ( $scoreboard->{'spares'} < $self->minspareservers )
      && ( ( keys(%$scoreboard) - 2 ) < $self->maxclients ) )
   {
      $mem->shlock(LOCK_UN);
      my $pid = fork();

      if ( not defined $pid ) {
         warn 'fork failed while creating a new spare.';
      }
      elsif ($pid) {

         # We are the parent.
      }
      else {
         warn "Created spare child $$."
            if POE::Component::Server::SimpleHTTP::DEBUG;

         # We are the child. Do something "childish".
         $self->am_child( 1 );
         $kernel->call( $session, 'add_scoreboard' );

         # Notify the other forked sessions that we have forked.
         foreach my $sess ( keys( %{ $self->forkhandlers } ) ) {
            $kernel->call( $sess, $self->forkhandlers->{$sess} );
         }

         # Get to work!
         $self->_factory->resume_accept();
      }
   }
   else {

      # No new spares were needed.
      $mem->shlock(LOCK_UN);
   }

   # If we are the parent, then reschedule another spare check.
   $kernel->delay_set( 'check_spares', CHECKSPARES_INTERVAL )
      unless $self->is_child;
};

# Debug routine so that we can watch what is happening on the scoreboard.
event 'show_scoreboard' => sub {
   my ($kernel,$self) = @_[KERNEL,OBJECT];
   my ($scoreboard,$mem,$hcount,$pid);

   # Check to make sure we are not a child.
   return 0 if $self->is_child;

   # Check to make sure the scoreboard is still up.
   $scoreboard = $self->scoreboard;
   return 0 unless defined $scoreboard;

   # Retrieve the underlying class.
   $mem = tied %$scoreboard;
   if ( not defined $mem ) {
      warn 'SCOREBOARD is not tied! Aborting.';
      return 0;
   }

   # Lock the scoreboard and print out the entries.
   $mem->shlock(LOCK_SH);
   $hcount = 0;
   print STDERR "[$$] actives = ", $scoreboard->{'actives'}, "\tspares = ",
     $scoreboard->{'spares'}, "\n";
   foreach $pid ( keys %$scoreboard ) {
      next if $pid eq 'actives' or $pid eq 'spares';

      print STDERR $pid, " = ", $scoreboard->{$pid};
      if ( ++$hcount % 5 == 0 ) {
         print STDERR "\n";
      }
      else {
         print STDERR "\t";
      }
   }
   print STDERR "\n\n";
   $mem->shlock(LOCK_UN);

   # If the socketfactory still exists then we should continue looping.
   $kernel->delay_set( 'show_scoreboard', 1 ) if $self->_factory;
};

# A child died :(
event '_sig_chld' => sub {
   my ($kernel,$self,$pid) = @_[KERNEL,OBJECT,ARG1];
   my ($scoreboard,$mem,$children);

   # Check to see if we are in preforked mode and the parent.
   unless ( $self->is_child ) {

      # Retrieve our scoreboard.
      $scoreboard = $self->scoreboard;
      $mem = tied %$scoreboard if defined $scoreboard;
      if ( not defined $mem ) {
         warn 'Cannot get the IPC::Shareable object for the SCOREBOARD!';
         return;
      }

      $mem->shlock(LOCK_EX);

      # Cleanup children here (they should never do it themselves).
      if ( exists $scoreboard->{$pid} ) {
         if ( $scoreboard->{$pid} eq 'S' ) {
            --$scoreboard->{'spares'};
         }
         elsif ( $scoreboard->{$pid} eq 'A' ) {
            --$scoreboard->{'actives'};
         }
         delete $scoreboard->{$pid};
      }

      # Get the number of children.
      $children = keys(%$scoreboard) - 2;

      $mem->shlock(LOCK_UN);

      # If the children are dying and the SOCKETFACTORY no longer exists, then
      # we are probably in a graceful shutdown.
      $kernel->yield( 'SHUTDOWN', 'GRACEFUL' ) if $children <= 0 and !$self->_factory;
   }
   $kernel->sig_handled();
};

# Someone is asking us to quit...
event '_sig_term' => sub {
   my ($kernel,$sig) = @_[KERNEL,ARG0];

   warn "Caught signal ", $sig, " inside $$. Initiating graceful shutdown."
      if POE::Component::Server::SimpleHTTP::DEBUG;

   # Shutdown gracefully, and tell POE we handled the signal.
   $kernel->yield( 'SHUTDOWN', 'GRACEFUL' );
   $kernel->sig_handled();
};

# Add the scoreboard entry for this child.
event 'add_scoreboard' => sub {
   my $self = $_[OBJECT];
   my ($scoreboard,$mem);

   # Check to see if we are preforked.
   if ( $self->is_child ) {
      $scoreboard = $self->scoreboard;
      $mem = tied %$scoreboard if defined $scoreboard;
      if ( not defined $mem ) {

         # Don't do anyting if we can't lock stuff.
         warn "SCOREBOARD is not tied to IPC::Shareable in child $$!";
      }
      else {

         # Lock the scoreboard and record ourself properly.
         $mem->shlock(LOCK_EX);
         if ( not exists $scoreboard->{$$} ) {
            $scoreboard->{$$} = 'S';
            ++$scoreboard->{'spares'};
         }
         $mem->shlock(LOCK_UN);
      }
   }

   return 1;
};

# Set the scoreboard entry for this child.
event 'update_scoreboard' => sub {
   my ($kernel,$self) = @_[KERNEL,OBJECT];
   my ($scoreboard,$mem);

   # Check to see if we are preforked.
   if ( $self->is_child ) {
      $scoreboard = $self->scoreboard;
      $mem = tied %$scoreboard if defined $scoreboard;
      if ( not defined $mem ) {

         # Don't do anyting if we can't lock stuff.
         warn "SCOREBOARD is not tied to IPC::Shareable in child $$!";
      }
      else {

         # Lock the scoreboard and record ourself properly.
         $mem->shlock(LOCK_EX);
         if ( keys( %{ $self->_requests } ) == 0
            and $scoreboard->{$$} eq 'A'  )
         {
            $scoreboard->{$$} = 'S';
            ++$scoreboard->{'spares'};
            --$scoreboard->{'actives'};

            # If we have too many spares then ask this one to shutdown.
            if ( $scoreboard->{'spares'} > $self->maxspareservers ) {
               warn "Shutting down $$ because of too many spares."
                  if POE::Component::Server::SimpleHTTP::DEBUG;

               $kernel->yield( 'SHUTDOWN', 'GRACEFUL' );
            }
         }
         elsif ( keys( %{ $self->_requests } ) != 0
                 and $scoreboard->{$$} eq 'S' )
         {
            $scoreboard->{$$} = 'A';
            --$scoreboard->{'spares'};
            ++$scoreboard->{'actives'};
         }
         $mem->shlock(LOCK_UN);
      }
   }

   return 1;
};

no MooseX::POE;

__PACKAGE__->meta->make_immutable;

# End of module
1;

__END__

=head1 NAME

POE::Component::Server::SimpleHTTP::PreFork - PreForking support for SimpleHTTP

=head1 SYNOPSIS

	use POE;
	use POE::Component::Server::SimpleHTTP::PreFork;

	# Start the server!
	POE::Component::Server::SimpleHTTP::PreFork->new(
		'ALIAS'		=>	'HTTPD',
		'ADDRESS'	=>	'192.168.1.1',
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

		# In the testing phase...
		'SSLKEYCERT'		=>	[ 'public-key.pem', 'public-cert.pem' ],

		# In the testing phase...
		'FORKHANDLERS'		=>	{ 'HTTP_GET' => 'FORKED' },
		'MINSPARESERVERS'	=>	5,
		'MAXSPARESERVERS'	=>	10,
		'MAXCLIENTS'		=>	256,
		'STARTSERVERS'		=>	10,
		'IPC_GLUE'		=>	'uniq',
	) or die 'Unable to create the HTTP Server';

=head1 ABSTRACT

	Subclass of SimpleHTTP for PreForking support

=head1 New Constructor Options

=over 5

=item C<MINSPARESERVERS>

	An integer that tells the server how many spares should be in the pool at any given
	time. Processes are forked off at a rate of 1 a second until this limit is met.

=item C<MAXSPARESERVERS>

	An integer that tells the server the maximum number of spares that may be in the pool
	at any given time. It is possible for more than this number of spares to exist, but at the very
	least the parent will stop forking requests off and the children will start to die eventually.

	If this value is less than MINSPARESERVERS then it is set to MINSPARESERVERS + 1.

=item C<MAXCLIENTS>

	An integer that tells the server the maximum number of clients that will be
	created. After this limit is reached, no more spares will be forked, even if the number drops below
	MINSPARESERVERS.

=item C<STARTSERVERS>

	An integer that tells the server how many processes to prefork at startup.

=item C<FORKHANDLERS>

	A HASH where the keys are sessions and the values are events. When a child forks,
	before it begins accepting connections it will call these events on the specified
	sessions. This allows you to setup per-process resources (such as database
	connections, ldap connects, etc). These events will never be called for the
	parent.

=item C<IPC_GLUE>

	A string containing either an integer or 4 characters specifying the key/glue
	for the underlying parent/child IPC communication.
	Running multiple instances of POE::Component::Server::SimpleHTTP::PreFork
	on the same host without using this option with different values
	almost guarantees some chaos.

=back

=head2 New Events

=over 4

=item C<ISCHILD>

	Returns true if you are inside a child, false if you are in the parent.

=item C<GETFORKHANDLERS>

	This event accepts 2 arguments: the session + event to send the response to.

	This even will send back the current FORKHANDLERS hash ( deep-closed via
	Storable::dclone ).

	The resulting hash can be played around to your tastes, then once you are done...

=item C<SETFORKHANDLERS>

	This event accepts only one argument: reference to FORKHANDLERS hash.

	BEWARE: this event is disabled in a forked child.

=back

=head1 Miscellaneous Notes

	BEWARE: HANDLERS munging is disabled in a forked child. Also, handlers changed in
	the parent will not appear in the already forked children.

	BEWARE: for a child, calling {STOP,START}LISTEN does not {destroy,recreate} the
	SOCKETFACTORY like it does in the parent. Instead, the child will {pause,resume}
	accepting connections on the current SOCKETFACTORY. Also, {STOP,START}LISTEN does
	not have any effect on the scoreboard calculations: this child will still
	be marked a spare if it finishes all its requests.

	The shutdown event is altered a little bit
		GRACEFUL -> sends a TERM signal to all remaining children and waits for their death
		NOARGS -> kills all remaining children with prejudice

	Keep in mind that being forked means any global data is not shared between processes and etc. Please see perlfork for all the implications on your platform.

=head1 New Compile-time constants

Checking spares every second may be a bit too much for you.
You can override this behavior by doing this:

	sub POE::Component::Server::SimpleHTTP::PreFork::CHECKSPARES_INTERVAL () { 10 }
	use POE::Component::Server::SimpleHTTP::PreFork;

If the prefork failed because it could not obtain shared memory for the scoreboard,
then if retries after 5 seconds. You can override this behavior by doing this:

	sub POE::Component::Server::SimpleHTTP::PreFork::PREFORK_INTERVAL () { 10 }
	use POE::Component::Server::SimpleHTTP::PreFork;

If you would like to see the contents of the scoreboard every second then do this:

	sub POE::Component::Server::SimpleHTTP::PreFork::DEBUGSB () { 1 }
	use POE::Component::Server::SimpleHTTP::PreFork;

=head2 EXPORT

Nothing.

=head1 SEE ALSO

	L<POE::Component::Server::SimpleHTTP>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>
Stephen Butler E<lt>stephen.butler@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Apocalypse + Stephen Butler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
