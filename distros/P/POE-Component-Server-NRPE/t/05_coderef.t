use Test::More tests => 7;

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

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $port = ( unpack_sockaddr_in $nrped->getsockname() )[0];

  is( $nrped->add_command( command => 'check_mofo', program => \&_coderef ), 1, "Added a command handler okay" );

  my $check = POE::Component::Client::NRPE->check_nrpe(
	host  => '127.0.0.1',
	port  => $port,
	event => '_response',
	version => 2,
	usessl => 0,
	context => { thing => 'moo' },
	command => 'check_mofo',
  );

  return;
}

sub _response {
  my ($kernel,$heap,$res) = @_[KERNEL,HEAP,ARG0];
  cmp_ok( $res->{context}->{thing}, 'eq', 'moo', 'Context data was okay' );
  cmp_ok( $res->{version}, 'eq', '2', 'Response version' );
  cmp_ok( $res->{result}, 'eq', '0', 'The result code was okay' );
  cmp_ok( $res->{data}, 'eq', 'OK mofo bleh' ) or diag("Got '$res->{data}', expected 'OK mofo bleh'\n");
  $nrped->shutdown();
  return;
}

sub _coderef {
  print "OK mofo bleh\n";
  return 0;
}
