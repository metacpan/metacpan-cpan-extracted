use strict;
use warnings;
use Test::More tests => 9;
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
	  'main' => [qw(_response _acctevent)],
	],
);

$poe_kernel->run();
exit 0;

sub test_start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->call( $radiusd->session_id, 'register', acctevent => '_acctevent' );
  ok( $radiusd->add_client( name => 'localhost', address => '127.0.0.1', secret => 'bogoff' ), 'Added a client' );
  my @acctports = $radiusd->acctports();
  ok( scalar @acctports == 1, 'Okay, only one acctport defined' );
  my $port = shift @acctports;
  $kernel->post( $self->session_id(), 'accounting', 
	type => 'Start',
	attributes => { },
	event => '_response',
	server => '127.0.0.1',
	port => $port,
	secret => 'bogoff',
	_ArbItary => 'bleh',
  );
  #diag("Waiting 5 seconds for a timeout");
  undef;
}

sub test_stop {
  pass('Everything stopped');
  return;
}

sub _acctevent {
  my ($kernel,$req_id,$data,$client) = @_[KERNEL,ARG0..ARG2];
  ok( $data->{'Acct-Status-Type'} eq 'Start', 'Acct-Status-Type' );
  return;
}

sub _response {
  my ($kernel,$data) = @_[KERNEL,ARG0];
  ok( $data->{response}, 'Got a response' );
  ok( $data->{response}->{Code} eq 'Accounting-Response', 'Accounting-Response' );
  ok( $data->{_ArbItary} eq 'bleh', 'Got our arbitary variable back' );
  $kernel->post( $self->session_id(), 'shutdown' );
  $kernel->post( $radiusd->session_id(), 'shutdown' );
  return;
}
