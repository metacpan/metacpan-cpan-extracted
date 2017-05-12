use strict;
use warnings;
use Test::More tests => 5;
BEGIN { use_ok('POE::Component::Client::RADIUS') };

use Socket;
use POE;
use Net::Radius::Dictionary;
use Net::Radius::Packet;

my $dict = new Net::Radius::Dictionary 'dictionary'
	or die "Couldn't read dictionary: $!";

POE::Session->create(
	inline_states => { _start => \&test_start, _stop => \&test_stop, },
	package_states => [
	  'main' => [qw(_get_datagram _response)],
	],
);

$poe_kernel->run();
exit 0;

sub test_start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $proto = getprotobyname('udp');
  my $paddr = sockaddr_in( 0, inet_aton('127.0.0.1') );
  socket( my $socket, PF_INET, SOCK_DGRAM, $proto)   || die "socket: $!";
  bind( $socket, $paddr)                          || die "bind: $!";
  my ($port,$addr) = sockaddr_in( getsockname $socket );
  $kernel->select_read( $socket, '_get_datagram' );
  my $self = POE::Component::Client::RADIUS->authenticate(
	dict => $dict,
	username => 'bingos',
	password => 'moocow',
	attributes => { },
	event => '_response',
	server => '127.0.0.1',
	port => $port,
	secret => 'bogoff',
	options => { trace => 0 },
	_ArbItary => 'bleh', 
  );
  isa_ok ( $self, 'POE::Component::Client::RADIUS' );
  diag("Waiting 5 seconds for a timeout");
  undef;
}

sub test_stop {
  pass('Everything stopped');
  return;
}

sub _get_datagram {
  my ($kernel,$heap,$socket) = @_[KERNEL,HEAP,ARG0];
  my $remote_address = recv( $socket, my $message = '', 4096, 0 );
  die "$!\n" unless defined $remote_address;
  $kernel->select_read( $socket );
  return;
}

sub _response {
  my ($kernel,$data) = @_[KERNEL,ARG0];
  ok( $data->{timeout} eq 'Timeout waiting for a response', 'Got a timeout' );
  ok( $data->{_ArbItary} eq 'bleh', 'Got our arbitary variable back' );
  return;
}
