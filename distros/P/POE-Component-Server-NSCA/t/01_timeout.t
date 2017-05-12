use Test::More tests => 5;

BEGIN {	use_ok( 'POE::Component::Server::NSCA' ) };

use Socket;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Stream);

my $poco = POE::Component::Server::NSCA->spawn(
	address => '127.0.0.1',
	port => 0,
	time_out => 10,
	password => 'moocow',
	encryption => 1,
);

isa_ok( $poco, 'POE::Component::Server::NSCA' );

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start 
			_sock_up
			_sock_failed
			_sock_in
			_sock_down
			_stop
	)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $port = ( unpack_sockaddr_in $poco->getsockname() )[0];
  $heap->{factory} = POE::Wheel::SocketFactory->new(
	RemoteAddress => 'localhost',
	RemotePort    => $port,
	SuccessEvent => '_sock_up',
        FailureEvent => '_sock_failed',
  );
  return;
}

sub _stop {
  pass("Everything went away");
  return;
}

sub _sock_failed {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my ($operation, $errnum, $errstr, $wheel_id) = @_[ARG0..ARG3];
  die "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
}

sub _sock_up {
  my ($kernel,$heap,$socket) = @_[KERNEL,HEAP,ARG0];

  delete $heap->{factory};

  $heap->{'socket'} = new POE::Wheel::ReadWrite
  (
        Handle => $socket,
        Filter => POE::Filter::Stream->new(),
        InputEvent => '_sock_in',
        ErrorEvent => '_sock_down',
   );

   return;
}

sub _sock_in {
  my ($kernel,$heap,$input) = @_[KERNEL,HEAP,ARG0];
  ok( length( $input ) == 132, 'Got an initial packet' );
  warn "# Waiting for timeout\n";
  return;
}

sub _sock_down {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  delete $heap->{socket};
  pass("Socket down");
  $poco->shutdown();
  return;
}
