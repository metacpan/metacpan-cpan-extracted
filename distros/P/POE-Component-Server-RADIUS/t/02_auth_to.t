use strict;
use warnings;
use Test::More tests => 16;
BEGIN { use_ok('POE::Component::Server::RADIUS') };

use Socket;
use POE qw(Component::Client::RADIUS);
use Net::Radius::Dictionary;
use Net::Radius::Packet;

my $dict = new Net::Radius::Dictionary 'dictionary'
	or die "Couldn't read dictionary: $!";

my $radiusd = POE::Component::Server::RADIUS->spawn( dict => $dict, authport => 0, acctport => 0 );
my $self = POE::Component::Client::RADIUS->spawn( dict => $dict, options => { trace => 0 }, timeout => 5, );

isa_ok ( $radiusd, 'POE::Component::Server::RADIUS' );

POE::Session->create(
	inline_states => { _start => \&test_start, _stop => \&test_stop, },
	package_states => [
	  'main' => [qw(_response _authevent)],
	],
);

$poe_kernel->run();
exit 0;

sub test_start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->call( $radiusd->session_id, 'register', authevent => '_authevent' );
  ok( $radiusd->add_client( name => 'localhost', address => '127.0.0.1', secret => 'bogoff' ), 'Added a client' );
  my @authports = $radiusd->authports();
  ok( scalar @authports == 1, 'Okay, only one authport defined' );
  my $port = shift @authports;
  $kernel->post( $self->session_id(), 'authenticate', 
	username => 'bingos',
	password => 'moocow',
	attributes => { },
	event => '_response',
	server => '127.0.0.1',
	port => $port,
	secret => 'bogoff',
	_ArbItary => 'bleh',
  );
  diag("Waiting 5 seconds for a timeout");
  undef;
}

sub test_stop {
  pass('Everything stopped');
  return;
}

sub _authevent {
  my ($kernel,$req_id,$data,$client) = @_[KERNEL,ARG0..ARG2];
  is( $data->{'Framed-Protocol'}, 'PPP', 'Framed-Protocol' );
  is( $data->{'User-Name'}, 'bingos', 'User-Name' );
  is( $data->{'NAS-Identifier'}, 'PoCoClientRADIUS', 'NAS-Identifier' );
  is( $data->{'User-Password'}, 'moocow', 'User-Password' );
  is( $data->{'Service-Type'}, 'Framed-User', 'Service-Type' );
  is( $data->{'NAS-Port'}, '1234', 'NAS-Port' );
  ok( defined $data->{'NAS-IP-Address'}, 'NAS-IP-Address' );
  is( $data->{'Called-Station-Id'}, '0000', 'Called-Station-Id' );
  is( $data->{'Calling-Station-Id'}, '01234567890', 'Calling-Station-Id' );
  return;
}

sub _response {
  my ($kernel,$data) = @_[KERNEL,ARG0];
  ok( $data->{timeout} eq 'Timeout waiting for a response', 'Got a timeout' );
  ok( $data->{_ArbItary} eq 'bleh', 'Got our arbitary variable back' );
  $kernel->post( $self->session_id(), 'shutdown' );
  $kernel->post( $radiusd->session_id(), 'shutdown' );
  return;
}
