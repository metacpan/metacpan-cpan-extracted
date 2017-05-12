use Test::More tests => 5;

BEGIN {	use_ok( 'POE::Component::Client::NSCA' ) };

use POE;

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start 
			_response 
	)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];

  my $check = POE::Component::Client::NSCA->send_nsca( 
	host  => 'zxkchzxkchzkxhckjhkzjhckzcxkhzk',
	port  => 5556,
	event => '_response',
	password => 'cow',
	encryption => 1,
	context => { thing => 'moo' },
	message => { 
			host_name => 'bovine',
			return_code => 0,
			plugin_output => 'The cow went moo',
	},
  );

  isa_ok( $check, 'POE::Component::Client::NSCA' );

  return;
}

sub _response {
  my ($kernel,$heap,$res) = @_[KERNEL,HEAP,ARG0];
  diag( $res->{error} );
  ok( $res->{error}, 'Yes it was an error' );
  ok( $res->{context}, 'Yes we got our context' );
  ok( ( $res->{message} and ref $res->{message} eq 'HASH' ), 'Yep, got the message back' );
  return;
}

sub _server_error {
  die "Shit happened\n";
}

sub _server_accepted {
  return;
}
