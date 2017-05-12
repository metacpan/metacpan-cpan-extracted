package TestServer;
# test server for proxy test - Andrew V. Purshottam
# accepts lines of form count: text 
# to do:
#   (done) fix same error as in proxy! the shutdown state variable is server wide,
#     not per client connectection! Ok, fixed it, now shutdown is in heap,
#     so per client connection. This was easy, because the PoCo::Server::TCP
#     had all the state already in the per connection session. I am begining to 
#     appreciate POE...

use warnings;
use strict;
use diagnostics;

# sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE;
use POE::Filter::Stream;
use POE::Filter::Line;
use POE qw(Component::Server::TCP);
use POE::Component::Proxy::TCP::PoeDebug;

use fields qw(port );

sub new {
  my TestServer $self = shift;
  unless (ref $self) {
    $self = fields::new($self);
  }

  # private instance variables init...

  # Extract parameters...
  my %param = @_;

  $self->{port} = delete $param{Port};
  $self->{port} = 8000 unless defined ($self->{port});
  my $base_delay = 0;
  # Create TCP server and start listener session.
  POE::Component::Server::TCP->new
      ( Alias => "proxy_test_server",
	Port => $self->{port},
	Args => [$self], # so handle_client_connect_to_server gets $self
	ClientConnected    => \&handle_client_connect_to_server,
	ClientFilter => "POE::Filter::Line",
	ClientInput => sub {
	  my ( $kernel, $session, $heap, $input ) = @_[ KERNEL, SESSION, HEAP, ARG0 ];
	  dbprint(3, "Session ", $session->ID(), " got input: $input");
	  if ($input =~ m/^END/) {
	    dbprint(2,"TEST SERVER GOT END REQUEST\n");
	    $heap->{_shutting_down} = 1;
	    check_for_shutdown();
	  } else {
	    my ($count, $text) = split /:/, $input;
	    dbprint(2, "got request count:", $count, " text:", $text);
	    for (my $i = 0; $i < $count; $i++) {
	      reply_after_delay($i + $base_delay, "$i:$text:" );
	      dbprint(3, "sent $i:$text:");
	    }
	    $base_delay += $count;
	  }
	},

	InlineStates => {send => sub {
			   my ( $heap, $message ) = @_[ HEAP, ARG0 ];
			   $heap->{client}->put($message);
			 },
			 send_delayed => sub {
			   my ( $heap, $message ) = @_[ HEAP, ARG0 ];
			   $heap->{client}->put($message);
			   $heap->{_pending_self_requests}--;
			   check_for_shutdown();
			   
			 }},
	Args => [$self], 
	
      );
  
  return $self;
}


# Called inside per client connection session 
# sets up $heap->{self} to be the TestServer instance
# a pure OO approach to POE where one could subclass
# the per connection session and put instance data
# there might have been nicer?

sub handle_client_connect_to_server {
  my ( $kernel, $session, $heap, $self ) = @_[ KERNEL, SESSION, HEAP, ARG0 ];
  my $session_id = $session->ID;
  $heap->{self} = $self;
  $heap->{_pending_self_requests} = 0;
  $heap->{_shutting_down} = 0;

  dbprint(1, "Client connected.");
}

# hack to support sending lines to the client, and 
# make sure the client connection session is kept running
# until all pending lines have been set.
# If we had access to the event queue, we could look
# to see if any send events for the per client connection
# session were available. Q for POE[tr]s: should this be possible?

# reply_after_delay($delay_secs, $text)
# does crap to get env without having to pass,
# then updates pend and posts a delayed event.
sub reply_after_delay {
  my $delay_secs = shift;
  my $text = shift;
  my $kernel = $poe_kernel;
  my $session = $kernel->get_active_session();
  my $heap = $session->get_heap();
  my $self = $heap->{self};
  $heap->{_pending_self_requests}++;
  $kernel->delay_add( "send_delayed", $delay_secs, $text);
}

# check_for_shutdown() - ask TestServer per client session 
#   if it should shut down.
sub check_for_shutdown {
  my $kernel = $poe_kernel;
  my $session = $kernel->get_active_session();
  my $heap = $session->get_heap();
  my $self = $heap->{self}; 
  dbprint(10, "check_for_shutdown: sd:$heap->{_shutting_down} psr:$heap->{_pending_self_requests}");
  if ($heap->{_shutting_down}) {
    if ($heap->{_pending_self_requests}) {
      dbprint(10, "can't shut down");
    } else {
      dbprint(1, "test server per client connection session shutting down");
      # reply_after_delay(1, "END");
      $kernel->yield( "shutdown" );
    }
  }
}

  
1;
