use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok('POE::Component::Server::Chargen') };

use Socket;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite);

my $self = POE::Component::Server::Chargen->spawn( Alias => 'Chargen-Server', BindPort => 0,
			BindAddress => '127.0.0.1' );

isa_ok ( $self, 'POE::Component::Server::Chargen' );

POE::Session->create(
	inline_states => { _start => \&test_start },
	package_states => [
	  'main' => [qw(_sock_up _sock_err _input)],
	],
	heap => { test_string => 'Hey I am not fubar', },
);

$poe_kernel->run();
exit 0;

sub test_start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];

  my ($port,$addr) = $self->sockname_tcp();
  ${heap}->{socket} = POE::Wheel::SocketFactory->new(
	RemoteAddress => '127.0.0.1',
	RemotePort => $port,
	SuccessEvent => '_sock_up',
        FailureEvent => '_sock_err',
  );
  undef;
}

sub _sock_up {
  my ($kernel,$heap,$socket) = @_[KERNEL,HEAP,ARG0];
  delete $heap->{socket};
  ok( 1, "Socket is up" );
  $heap->{wheel} = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	InputEvent => '_input',
	ErrorEvent => '_sock_err',
  );
  $kernel->yield( '_sock_err' ) unless $heap->{wheel};
  undef;
}

sub _sock_err {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  delete $heap->{socket};
  delete $heap->{wheel};
  $kernel->post( 'Chargen-Server' => 'shutdown' );
  undef;
}

sub _input {
  my ($kernel,$heap,$input) = @_[KERNEL,HEAP,ARG0];
  pass($input);
  $kernel->yield( '_sock_err' );
  undef;
}
