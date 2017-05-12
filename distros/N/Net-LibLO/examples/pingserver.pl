#!/usr/bin/perl
#
# OSC Ping Server
#

use Net::LibLO;
use Data::Dumper;
use strict;

# Create objects
my $lo = new Net::LibLO( 4542 );


# Add method
$lo->add_method( '/ping', '', \&pinghandler , 'userdata');

# Wait for pings
while(1) {
	my $bytes = $lo->recv();
	print "Recieved $bytes byte message.\n";
}



sub pinghandler {
	my ($serv, $mesg, $path, $typespec, $userdata, @params) = @_;
	my $from = $mesg->get_source();
	print "Got ping from ".$from->get_url().".\n";
	
	$serv->send( $from, '/pong' );
}
