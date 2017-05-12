#!/usr/bin/perl
#
# Send an audio file to specified address and port
# using PCM u-law payload type (0)
#
# Requires 'sox' command to help transcode the audio file
#

use Net::RTP;
use Time::HiRes qw/ usleep /; 
use strict;

my $DEFAULT_PORT = 5004;	# Default RTP port
my $DEFAULT_TTL = 2;		# Default Time-to-live
my $PAYLOAD_TYPE = 0;		# u-law
my $PAYLOAD_SIZE = 160;		# 160 samples per packet


# Get the command line parameters
my ($filename, $address, $port, $ttl ) = @ARGV;
usage() unless (defined $filename);
usage() unless (defined $address);
$port=$DEFAULT_PORT unless (defined $port);
$ttl=$DEFAULT_TTL unless (defined $ttl);

print "Input Filename: $filename\n";
print "Remote Address: $address\n";
print "Remote Port: $port\n";
print "Multicast TTL: $ttl\n";
print "Payload type: $PAYLOAD_TYPE\n";
print "Payload size: $PAYLOAD_SIZE bytes\n";



# Create RTP socket
my $rtp = new Net::RTP(
		PeerPort=>$port,
		PeerAddr=>$address,
) || die "Failed to create RTP socket: $!";

# Set the TTL
if ($rtp->superclass() =~ /Multicast/) {
	$rtp->mcast_ttl( $ttl );
}

# Create RTP packet
my $packet = new Net::RTP::Packet();
$packet->payload_type( $PAYLOAD_TYPE );


# Open the input file (via sox)
open(PCMU, "sox '$filename' -t raw -b -U -c 1 -r 8000 - |") 
or die "Failed to open input file: $!";

my $data;
while( my $read = read( PCMU, $data, $PAYLOAD_SIZE ) ) {

	# Set payload, and increment sequence number and timestamp
	$packet->payload($data);
	$packet->seq_num_increment();
	$packet->timestamp_increment( $PAYLOAD_SIZE );
	
	my $sent = $rtp->send( $packet );
	#print "Sent $sent bytes.\n";
	
	# This isn't a very good way of timing it
	# but it kinda works
	usleep( 1000000 * $PAYLOAD_SIZE / 8000 );
}

close( PCMU );


sub usage {
	print "usage: rtpsend-pcmu.pl <filename> <dest_addr> [<dest_port>] [<ttl>]\n";
	exit -1;
}


__END__

=pod

=head1 NAME

rtpsend-pcmu.pl - Send an audio file an RTP session as u-law

=head1 SYNOPSIS

rtpsend-pcmu.pl <filename> <dest_addr> [<dest_port>] [<ttl>]

=head1 DESCRIPTION

rtpsend-pcmu.pl sends audio files to an RTP session using PCM u-law (G.711)
payload encoding (RTP payload type 0). 
If no port is specified, then port 5004 is assumed.
If no TTL is specified, then a TTL of 2 is assumed.

Each packet sent contains 160 samples of audio, and as payload type 0 has a
fixed sample rate of 8000Hz, each packet has a duration of 20 miliseconds.

rtpsend-pcmu.pl uses the B<'sox'> command as helper to transcode and resample 
the audio file to u-law, which means that many audio file formats 
are automatically supported (AIFF, WAVE, SUN .au, GSM, ...).


=head1 SEE ALSO

L<Net::RTP>

L<Net::RTP::Packet>

L<http://sox.sourceforge.net/>

=head1 BUGS

Doesn't keep packet sending timing very well - it goes out of sync very quickly.

=head1 AUTHOR

Nicholas J Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 University of Southampton

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut

