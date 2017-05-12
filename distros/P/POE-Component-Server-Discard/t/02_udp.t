use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok('POE::Component::Server::Discard') };

use Socket;
use POE;

my $self = POE::Component::Server::Discard->spawn( Alias => 'Discard-Server', BindPort => 0,
			BindAddress => '127.0.0.1' );

isa_ok ( $self, 'POE::Component::Server::Discard' );

POE::Session->create(
	inline_states => { _start => \&test_start, _stop => \&test_stop, },
	package_states => [
	  'main' => [qw(_get_datagram _pass)],
	],
	heap => { test_string => 'Hey I am not fubar', },
);

$poe_kernel->run();
exit 0;

sub test_start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];

  my ($port,$addr) = $self->sockname_udp();
  my $socket = IO::Socket::INET->new(
        Proto => 'udp',
  );
  $kernel->select_read( $socket, '_get_datagram' );
  die "Couldn't create client socket: $!" unless $socket;
  my $server_address = pack_sockaddr_in( $port, inet_aton('127.0.0.1') );
  my $message = $heap->{test_string};
  send( $socket, $message, 0, $server_address ) == length($message) or
      die "Trouble sending message: $!";
  diag('Sent data, waiting 5 seconds');
  $kernel->delay( '_pass', 5, $socket );
  undef;
}

sub test_stop {
  pass('Everything stopped');
  return;
}

sub _pass {
  my ($kernel,$socket) = @_[KERNEL,ARG0];
  pass('Got nothing back, hurrah');
  $kernel->select_read( $socket );
  $kernel->post( 'Discard-Server' => 'shutdown' );
  return;
}

sub _get_datagram {
  my ($kernel,$heap,$socket) = @_[KERNEL,HEAP,ARG0];
  my $remote_address = recv( $socket, my $message = '', 1024, 0 );
  die "$!\n" unless defined $remote_address;
  fail('We got something back');
  diag($message);
  $kernel->select_read( $socket );
  $kernel->delay( '_pass' );
  $kernel->post( 'Discard-Server' => 'shutdown' );
  return;
}
