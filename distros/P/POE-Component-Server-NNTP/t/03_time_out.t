use Test::More tests => 9;

use strict;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line);
use Socket;

require_ok('POE::Component::Server::NNTP');

POE::Session->create(
	inline_states => { _start => \&test_start, },
	package_states => [
		'main' => [qw(_failure 
			      _config_nntpd 
			      _shutdown 
			      _sock_up
			      _sock_failed
			      _sock_down
			      _parseline
			      nntpd_connection
			      nntpd_disconnected
			      nntpd_registered)],
	],
	options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub test_start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];

  my $wheel = POE::Wheel::SocketFactory->new(
	BindAddress => '127.0.0.1',
	BindPort => 0,
	SuccessEvent => '_fake_success',
	FailureEvent => '_failure',
  );

  if ( $wheel ) {
	my $port = ( unpack_sockaddr_in( $wheel->getsockname ) )[0];
	$kernel->yield( '_config_nntpd' => $port );
	$wheel = undef;
	$kernel->delay( '_shutdown' => 60 );
	return;
  }
  return;
}

sub _failure {
  die "Couldn\'t allocate a listening port, giving up\n";
  return;
}

sub _shutdown {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->alarm_remove_all();
  $kernel->post( 'nntpd', 'shutdown' );
  return;
}

sub _config_nntpd {
  my ($kernel,$heap,$port) = @_[KERNEL,HEAP,ARG0];
  my $poco = POE::Component::Server::NNTP->spawn( 
	alias => 'nntpd', 
	address => '127.0.0.1',
	port => $port,
	time_out => 10,
	posting => 0,
	options => { trace => 0 },
  );
  isa_ok( $poco, 'POE::Component::Server::NNTP' );
  isa_ok( $poco, 'POE::Component::Pluggable' );
  $heap->{port} = $port;
  return;
}

sub nntpd_registered {
  my ($kernel,$heap,$poco) = @_[KERNEL,HEAP,ARG0];
  isa_ok( $poco, 'POE::Component::Server::NNTP' );
  isa_ok( $poco, 'POE::Component::Pluggable' );
  $heap->{factory} = POE::Wheel::SocketFactory->new(
	RemoteAddress => '127.0.0.1',
	RemotePort => $heap->{port},
	SuccessEvent => '_sock_up',
        FailureEvent => '_sock_failed',
	BindAddress => '127.0.0.1'
  );
  return;
}

sub nntpd_connection {
  pass("Client connected");
  warn "# Waiting 10 seconds for time out\n";
  return;
}

sub nntpd_disconnected {
  pass("Client disconnected");
  $poe_kernel->yield( '_shutdown' );
  return;
}

sub _sock_up {
  my ($kernel,$heap,$socket) = @_[KERNEL,HEAP,ARG0];

  delete $heap->{factory};

  $heap->{'socket'} = new POE::Wheel::ReadWrite
  (
        Handle => $socket,
        Driver => POE::Driver::SysRW->new(),
        Filter => POE::Filter::Line->new(),
        InputEvent => '_parseline',
        ErrorEvent => '_sock_down',
   );

   return;
}

sub _sock_failed {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my ($operation, $errnum, $errstr, $wheel_id) = @_[ARG0..ARG3];
  warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
  delete $heap->{factory};
  $kernel->yield( '_shutdown' );
  return;
}

sub _sock_down {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  pass("Disconnected by peer");
  delete $heap->{socket};
  return;
}

sub _parseline {
  my ($kernel,$heap,$input) = @_[KERNEL,HEAP,ARG0];
  ok( $input eq '201 server ready - no posting allowed', $input );
  return;
}
