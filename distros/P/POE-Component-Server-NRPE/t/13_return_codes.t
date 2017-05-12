use Test::More tests => 2 + 6 * 5;

use warnings;
use strict;

BEGIN {	use_ok( 'POE::Component::Server::NRPE' ) };

use Socket;
use POE qw(Wheel::SocketFactory Filter::Stream Component::Client::NRPE);

my $nrped = POE::Component::Server::NRPE->spawn(
	address => '127.0.0.1',
	port => 0,
	version => 2,
	usessl => 0,
	verstring => 'NRPE v2.8.1',
	options => { trace => 0 },
);

isa_ok( $nrped, 'POE::Component::Server::NRPE' );

POE::Session->create(
  package_states => [
	'main' => [qw(_start _response)],
  ],
);

$poe_kernel->run();
exit 0;

my $total = 0;
sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $port = ( unpack_sockaddr_in $nrped->getsockname() )[0];

  my %tests = (
    OK => [0, 0],
    WARNING => [1, 1],
    CRITICAL => [2, 2],
    UNKNOWN => [3, 3],
    HIGHER => [5, 3],
    LOWER => [-1, 3],
    );
  while(my ($state, $values) = each %tests) {
    $total++;
    is( $nrped->add_command( command => 'check_' . lc($state), program => \&_coderef, args => [ $state => $values->[0] ] ), 1, "Added $state command handler" );

  my $check = POE::Component::Client::NRPE->check_nrpe(
	host  => '127.0.0.1',
	port  => $port,
	event => '_response',
	version => 2,
	usessl => 0,
	context => [ $state => $values ],
	command => 'check_' . lc($state),
  );
  }

  return;
}

sub _response {
  my ($kernel,$heap,$res) = @_[KERNEL,HEAP,ARG0];
  ok( $res->{context}, 'Context data was okay' );
  my ($state, $values) = @{$res->{context}};
  cmp_ok( $res->{version}, 'eq', '2', 'Response version' );
  cmp_ok( $res->{result}, 'eq', $values->[1], "The result code was '$res->{result}', expected '$values->[1]'\n" );
  cmp_ok( $res->{data}, 'eq', "$state mofo bleh" ) or diag("Got '$res->{data}', expected '$state mofo bleh'\n");
  $total--;
  $nrped->shutdown() if $total == 0;
  return;
}

sub _coderef {
  my ($status, $rc) = @_;
  print "$status mofo bleh\n";
  exit $rc;
}
