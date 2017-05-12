#!/usr/bin/perl
#
# OSC Ping Client
#

use Net::LibLO;
use strict;

# Create objects
my $lo = new Net::LibLO();
my $addr = new Net::LibLO::Address( 'localhost', 4542 );


# Add reply handler
$lo->add_method( '/pong', '', \&ponghandler );

# Send the ping message
my $result = $lo->send( $addr, '/ping' );
if ($result <= 0) {
	print "Pinging ".$addr->get_url()." failed: $result\n";
} else {
	print "Sent $result bytes to ".$addr->get_url()." from ".$lo->get_url()."\n";
}

# Wait for reply
my $reply = $lo->recv_noblock( 2000 );
if (!$reply) {
	warn "Timed out after 2 seconds.\n"; 
}




sub ponghandler {
	my ($serv, $mesg, $path, $typespec, $userdata, @params) = @_;
	my $from = $mesg->get_source();
	print "Got pong from '".$from->get_url()."'.\n";
}
