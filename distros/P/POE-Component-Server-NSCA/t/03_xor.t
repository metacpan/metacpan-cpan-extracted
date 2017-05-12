use Test::More tests => 10;

BEGIN {	use_ok( 'POE::Component::Server::NSCA' ) };

use Socket;
use POE qw(Component::Client::NSCA);

my $poco = POE::Component::Server::NSCA->spawn(
	address => '127.0.0.1',
	port => 0,
	time_out => 10,
	password => 'moocow',
	encryption => 1,
	options => { trace => 0 },
);

isa_ok( $poco, 'POE::Component::Server::NSCA' );

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start 
			_stop
			_alert
			_result
	)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $port = ( unpack_sockaddr_in $poco->getsockname() )[0];
  $kernel->call( $poco->session_id(), 'register', { event => '_alert' } );
  POE::Component::Client::NSCA->send_nsca(
	host => 'localhost',
	port => $port,
	event => '_result',
	password => 'moocow',
	encryption => 1,
        message => {
          host_name => 'bovine',
          svc_description => 'chews',
          return_code => 0,
          plugin_output => 'Chewing okay',
        },
  );
  return;
}

sub _stop {
  pass("Everything went away");
  return;
}

sub _alert {
  my ($kernel,$result) = @_[KERNEL,ARG0];
  
  ok( $result->{'plugin_output'} eq 'Chewing okay', 'Chewing okay' );
  ok( $result->{'version'} == 3, 'Right version number' );
  ok( $result->{'return_code'} == 0, 'Return code is fine' );
  ok( $result->{'svc_description'} eq 'chews', 'svc description' );
  ok( $result->{'host_name'} eq 'bovine', 'Hostname is okay' );
  TODO: {
	  local $TODO = 'Vaguely flakey on some platforms';
          ok( $result->{'checksum'} == $result->{'crc32'}, 'Checksum was okay' );
  }
  $poco->shutdown();
  return;
}

sub _result {
  my ($kernel,$result) = @_[KERNEL,ARG0];
  ok( $result->{success}, 'Result was a success' );
  return;
}

