use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok('POE::Component::Server::Chargen') };

use Socket;
use POE;

my $self = POE::Component::Server::Chargen->spawn( Alias => 'Chargen-Server', BindPort => 0,
			BindAddress => '127.0.0.1' );

isa_ok ( $self, 'POE::Component::Server::Chargen' );

POE::Session->create(
	inline_states => { _start => \&test_start, _stop => \&test_stop, },
	package_states => [
	  'main' => [qw(_get_datagram)],
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
  undef;
}

sub test_stop {
  pass('Everything stopped');
  return;
}

sub _get_datagram {
  my ($kernel,$heap,$socket) = @_[KERNEL,HEAP,ARG0];
  my $remote_address = recv( $socket, my $message = '', 1024, 0 );
  die "$!\n" unless defined $remote_address;
  #ok( $message eq $heap->{test_string}, $heap->{test_string} );
  pass($message);
  $kernel->select_read( $socket );
  $kernel->post( 'Chargen-Server' => 'shutdown' );
  return;
}
