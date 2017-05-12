use strict;
use Socket;
use Test::More;
use POE qw(Component::Server::POP3 Wheel::SocketFactory Wheel::ReadWrite Filter::Line);

my %data = (
	tests => [
		[ '+OK' => 'cock' ],
		[ '-ERR' => 'quit' ],
	],
);

plan tests => 9;

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start
			_sock_up
			_sock_fail
			_sock_in
			_sock_err
			pop3d_registered
			pop3d_connection
			pop3d_disconnected
			pop3d_cmd_quit
	)],
  ],
  heap => \%data,
);

$poe_kernel->run();
exit 0;

sub _start {
  $_[HEAP]->{pop3d} = POE::Component::Server::POP3->spawn(
	address => '127.0.0.1',
	port => 0,
	options => { trace => 0 },
  );
  isa_ok( $_[HEAP]->{pop3d}, 'POE::Component::Server::POP3' );
  return;
}

sub pop3d_registered {
  my ($heap,$object) = @_[HEAP,ARG0];
  isa_ok( $object, 'POE::Component::Server::POP3' );
  $heap->{port} = ( sockaddr_in( $object->getsockname() ) )[0];
  $heap->{factory} = POE::Wheel::SocketFactory->new(
	RemoteAddress  => '127.0.0.1',
	RemotePort     => $heap->{port},
	SuccessEvent   => '_sock_up',
	FailureEvent   => '_sock_fail',
  );
  return;
}

sub _sock_up {
  my ($heap,$socket) = @_[HEAP,ARG0];
  delete $heap->{factory};
  $heap->{socket} = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	InputEvent => '_sock_in',
	ErrorEvent => '_sock_err',
  );
  return;
}

sub _sock_fail {
  my $heap = $_[HEAP];
  delete $heap->{factory};
  $heap->{pop3d}->shutdown();
  return;
}

sub _sock_in {
  my ($heap,$input) = @_[HEAP,ARG0];
  my @parms = split /\s+/, $input;
  my $test = shift @{ $heap->{tests} };
  if ( $test and $test->[0] eq $parms[0] ) {
	pass($input);
	$heap->{socket}->put( $test->[1] );
	return;
  }
  pass($input);
  return;
}

sub _sock_err {
  delete $_[HEAP]->{socket};
  pass("Disconnected");
  $_[HEAP]->{pop3d}->shutdown();
  return;
}

sub pop3d_connection {
  pass($_[STATE]);
  return;
}

sub pop3d_disconnected {
  pass($_[STATE]);
  return;
}

sub pop3d_cmd_quit {
  pass($_[STATE]);
  $_[SENDER]->get_heap()->send_to_client( $_[ARG0], '+OK POP3 server signing off' );
  return;
}
