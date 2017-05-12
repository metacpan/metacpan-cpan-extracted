#!/usr/bin/perl
#
# Net::oRTP example file
#
# Send 800Hz beeps to specified address and port
#
#

use Net::oRTP;
use strict;


my $PACKET_SIZE = 240;		# 240 samples per packet



# Nice crunchy 800Hz tone in PCMU:
my @pcmu_tone = (0x01, 0x0D, 0xFF, 0x8D, 0x81, 0x81, 0x8D, 0xFF, 0x0D, 0x01);
my @pcmu_silence = (0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F);

# 0.5 second tone followed by 1.0 seconds of silence
my @pcmu = ();
for(1..400) { push(@pcmu, @pcmu_tone); }
for(1..800) { push(@pcmu, @pcmu_silence ); }



# Check the number of arguments
if ($#ARGV != 1) {
	print "usage: rtpsendbeeps.pl dest_addr dest_port\n";
	exit;
}

# Get the command line parameters
my ($address, $port ) = @ARGV;
print "Remote Address: $address\n";
print "Remote Port: $port\n";



# Create a send object
my $rtp = new Net::oRTP('SENDONLY');

# Set it up
$rtp->set_blocking_mode( 1 );
$rtp->set_remote_addr( $address, $port );
$rtp->set_send_payload_type( 0 );


my $timestamp = 0;
while( 1 ) {
	
	my $offset = ($timestamp % scalar(@pcmu));
	my $payload = pack('C*', @pcmu[$offset..($offset+$PACKET_SIZE-1)]);
	#print "\@pcmu[$offset..".($offset+$PACKET_SIZE-1)."]\n";
	
	my $sent = $rtp->send_with_ts( $payload, $timestamp );
	if ($sent<=0) {
		warn "Failed to send packet";
		last;
	}
	
	# Increment the timestamp
	$timestamp+=$PACKET_SIZE;
}

