#!/usr/bin/perl
#
# Net::oRTP example file
#
# Send a file containing PCMU audio 
# to specified address and port
#
# The raw output file can be converted to an AIFF using
# sox -t raw -b -U -c 1 -r 8000 recording.raw output.aiff
#

use Net::oRTP;
use strict;


my $DEBUG = 1;

# Unbuffered
$|=1;

# Check the number of arguments
if ($#ARGV != 2) {
	print "usage: rtprecv.pl filename local_addr local_port\n";
	exit;
}

# Get the command line parameters
my ($filename, $address, $port ) = @ARGV;
print "Output Filename: $filename\n";
print "Remote Address: $address\n";
print "Remote Port: $port\n";



# Create a receive object
my $rtp = new Net::oRTP('RECVONLY');

# Set it up
$rtp->set_blocking_mode( 1 );
$rtp->set_local_addr( $address, $port );
$rtp->set_jitter_compensation( 40 );
$rtp->set_adaptive_jitter_compensation( 1 );
$rtp->set_recv_payload_type( 0 );


# Open the input file
open(PCMU, ">$filename") or die "Failed to open output file: $!";


my $data;
my $user_ts = 0;
while( 1 ) {
	my $data = $rtp->recv_with_ts( 10, $user_ts );
	if (defined $data) {
		my $string = substr($data,0,32);
		$string=~s/(.)/sprintf("%02X ",ord($1))/gse;
		warn "Got ".length($data)." bytes:  $string\n" if ($DEBUG);
		
		
		print PCMU $data;
		$user_ts+=160;
	} else {
		warn "Failed to recieve packet\n" if ($DEBUG);
	}

}	


close( PCMU );
