use strict;
use Data::Dumper;
use Test;


# use a BEGIN block so we print our plan before modules are loaded
BEGIN { plan tests => 5 }

# load modules
use Net::LibLO;

# Create objects
my $client = new Net::LibLO();
ok( $client );

# Add methods
$client->add_method( '/pong', '', \&pong_handler );
ok( 1 );

# Create server to talk to
my $url = fork_server( $client->get_url() );

# Send a message to the server
$client->send( $url, '/ping' );

# Wait for reply
my $result = $client->recv_noblock( 1000 );
ok( $result, 12 );


# Destroy the LibLO client object
undef $client;
ok( 1 );

exit;





sub ping_handler {
	my ($serv, $mesg, $path, $typespec, $userdata, @params) = @_;
	my $from = $mesg->get_source();
	print "# PING from ".$from->get_url()."\n";
	$serv->send( $from, '/pong' );
}

sub pong_handler {
	my ($serv, $mesg, $path, $typespec, $userdata, @params) = @_;
	print "# PONG\n";
	ok( 1 );
}


sub fork_server {
	my ($url) = @_;
	
	# Create a new server
	my $server = new Net::LibLO();
	
	# Send messages from a seperate process
	if (fork()==0) {
		$server->add_method( '/ping', '', \&ping_handler );
		
		# Wait for a single message
		my $result = $server->recv_noblock( 1000 );
		if ($result <= 0) {
			warn "Timed out waiting for ping.";
		}
		
		exit;
	}
	
	return $server->get_url();
}


