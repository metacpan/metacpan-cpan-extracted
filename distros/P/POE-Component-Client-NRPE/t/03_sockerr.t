use Test::More tests => 5;

BEGIN {	use_ok( 'POE::Component::Client::NRPE' ) };

use Socket;
use POE qw(Filter::Stream);
use Test::POE::Server::TCP;

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start
			nrped_connected
			_response
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

  $heap->{nrped}->shutdown();
  delete $heap->{nrped};

  my $check = POE::Component::Client::NRPE->check_nrpe(
	host  => '127.0.0.1',
	port  => $port,
	event => '_response',
	usessl => 0,
	context => { thing => 'moo' },
  );

  isa_ok( $check, 'POE::Component::Client::NRPE' );

  return;
}

sub _response {
  my ($kernel,$heap,$res) = @_[KERNEL,HEAP,ARG0];
  is( $res->{context}->{thing}, 'moo', 'Context data was okay' );
  is( $res->{version}, '2', 'Response version' );
  is( $res->{result}, '3', 'The result code was okay' );
  diag( $res->{data}, "\n" );
  return;
}

sub nrped_connected {
  $_[SENDER]->get_heap()->terminate( $_[ARG0] );
  return;
}
