use strict;
use warnings;
use Test::More tests => 7;
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
  ok( $radiusd->add_client( name => 'localhost', address => '127.0.0.1', secret => 'bogoff' ), 'Added a client' );
  my @authports = $radiusd->acctports();
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
  ok( $data->{'Framed-Protocol'} eq 'PPP', 'Framed-Protocol' );
  ok( $data->{'User-Name'} eq 'bingos', 'User-Name' );
  ok( $data->{'NAS-Identifier'} eq 'PoCoClientRADIUS', 'NAS-Identifier' );
  ok( $data->{'User-Password'} eq 'moocow', 'User-Password' );
  ok( $data->{'Service-Type'} eq 'Framed-User', 'Service-Type' );
  ok( $data->{'NAS-Port'} eq '1234', 'NAS-Port' );
  ok( $data->{'NAS-IP-Address'} eq '192.168.1.87', 'NAS-IP-Address' );
  ok( $data->{'Called-Station-Id'} eq '0000', 'Called-Station-Id' );
  ok( $data->{'Calling-Station-Id'} eq '01234567890', 'Calling-Station-Id' );
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
