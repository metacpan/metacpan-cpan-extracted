use Test::More tests => 10;

BEGIN {	use_ok( 'POE::Component::Client::NRPE' ) };

use Socket;
use POE qw(Filter::Stream);
use Test::POE::Server::TCP;

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start
			_response
			nrped_client_input
	)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{nrped} = Test::POE::Server::TCP->spawn(
	filter => POE::Filter::Stream->new(),
	prefix => 'nrped',
  );
  my $port = $heap->{nrped}->port();

  my $check = POE::Component::Client::NRPE->check_nrpe(
	host  => '127.0.0.1',
	port  => $port,
	event => '_response',
	version => 1,
	context => { thing => 'moo' },
  );

  isa_ok( $check, 'POE::Component::Client::NRPE' );

  return;
}

sub _response {
  my ($kernel,$heap,$res) = @_[KERNEL,HEAP,ARG0];
  is( $res->{context}->{thing}, 'moo', 'Context data was okay' );
  is( $res->{version}, '1', 'Response version' );
  is( $res->{result}, '0', 'The result code was okay' );
  is( $res->{data}, 'NRPE v1.9', 'And the data was cool' );
  $heap->{nrped}->shutdown();
  return;
}

sub nrped_client_input {
  my ($kernel,$heap,$id,$input) = @_[KERNEL,HEAP,ARG0,ARG1];
  my @args = unpack "NNNNa*", $input;
  $args[4]  =~ s/\x00*$//g;
  is( $args[0], '1', 'Version check' );
  is( $args[1], '1', 'Query check' );
  is( $args[3], length($args[4]), 'Data length check' );
  is( $args[4], '_NRPE_CHECK', 'Got a valid command' );
  $args[0] = 2;
  $args[4] = 'NRPE v1.9';
  $args[2] = 0;
  $args[3] = length $args[4];
  my $response = pack "NNNNa[1024]", @args;
  $heap->{nrped}->disconnect( $id );
  $heap->{nrped}->send_to_client( $id, $response );
  return;
}
