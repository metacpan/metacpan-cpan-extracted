use Test::More tests => 8;

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
	usessl => 0,
	timeout => 5,
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
  diag($res->{data}, "\n");
  $heap->{nrped}->shutdown();
  return;
}

sub nrped_client_input {
  my ($kernel,$heap,$id,$input) = @_[KERNEL,HEAP,ARG0,ARG1];
  my @args = unpack "nnNnZ*", $input;
  $args[4]  =~ s/\x00*$//g;
  is( $args[0], '2', 'Version check' );
  is( $args[1], '1', 'Query check' );
  is( $args[4], '_NRPE_CHECK', 'Got a valid command' );
  #my $response = _gen_packet_ver2( 'NRPE v2.8.1' );
  #$heap->{clients}->{ $wheel_id }->put( $response );
  $heap->{nrped}->terminate( $id );
  return;
}

sub _gen_packet_ver2 {
  my $data = shift;
  for ( my $i = length ( $data ); $i < 1024; $i++ ) {
    $data .= "\x00";
  }
  $data .= "SR";
  my $res = pack "n", 0;
  my $packet = "\x00\x02\x00\x02";
  my $tail = $res . $data;
  my $crc = ~POE::Component::Client::NRPE::_crc32( $packet . "\x00\x00\x00\x00" . $tail );
  $packet .= pack ( "N", $crc ) . $tail;
  return $packet;
}

