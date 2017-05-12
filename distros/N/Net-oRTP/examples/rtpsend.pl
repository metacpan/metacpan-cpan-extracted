#!/usr/bin/perl
#
# Net::oRTP example file
#
# Send a file containing PCMU audio 
# to specified address and port
#
# File can be generated using:
# sox input.aiff -t raw -b -U -c 1 -r 8000 output.raw
#

use Net::oRTP;
use strict;


my $PACKET_SIZE = 160;		# 160 samples per packet


# Unbuffered
$|=1;

# Check the number of arguments
if ($#ARGV != 2) {
	print "usage: rtpsend.pl filename dest_addr dest_port\n";
	exit;
}

# Get the command line parameters
my ($filename, $address, $port ) = @ARGV;
print "Input Filename: $filename\n";
print "Remote Address: $address\n";
print "Remote Port: $port\n";



# Create a send object
my $rtp = new Net::oRTP('SENDONLY');

# Set it up
$rtp->set_blocking_mode( 1 );
$rtp->set_remote_addr( $address, $port );
$rtp->set_send_payload_type( 0 );


# Open the input file
open(PCMU, $filename) or die "Failed to open input file: $!";


my $data;
my $user_ts = 0;
while( my $read = read( PCMU, $data, $PACKET_SIZE ) ) {
	#print "Read $read bytes.\n";
	
	my $sent = $rtp->send_with_ts( $data, $user_ts );
	#print "Sent $sent bytes.\n";
	
	# Increment the timestamp
	$user_ts+=$PACKET_SIZE;
	
	print ".";
}


close( PCMU );
