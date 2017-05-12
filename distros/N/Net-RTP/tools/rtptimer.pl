#!/usr/bin/perl
#
# Net::RTP example file
#
# Displays packet arrival timing
#

use Net::RTP;
use Data::Dumper;
use Time::HiRes qw/time/;
use strict;


my $DEFAULT_PORT = 5004;	# Default RTP port


# Create RTP socket
my ($address, $port) = @ARGV;
usage() unless (defined $address);
$port = $DEFAULT_PORT unless (defined $port);

my $rtp = new Net::RTP(
		LocalPort=>$port,
		LocalAddr=>$address
) || die "Failed to create RTP socket: $!";


my $start = time();
my $last = time();
my $ts_last = 0;
while (my $packet = $rtp->recv()) {
	my $this = time();
	
	# Calculate the difference from the last packet
	my $diff = sprintf("%2.2f", ($this-$last)*1000);
	$diff = "+$diff" if ($diff>0);
	
	# Calculate the difference from the last packet
	my $ts_diff = $packet->timestamp()-$ts_last;
	$ts_diff = "+$ts_diff" if ($ts_diff>0);
	
	# Display the packet
	printf("%2.2f", ($this-$start)*1000);
	printf(" (%s)", $diff);
	printf("  SRC=%s", $packet->source_ip());
	printf(", LEN=%u", $packet->payload_size());
	printf(", PT=%u", $packet->payload_type());
	printf(", SEQ=%u", $packet->seq_num());
	printf(", TS=%u", $packet->timestamp());
	printf(" (%s)", $ts_diff);
	printf("\n");

	# Store time of last packet that arrived
	$last = $this;
	$ts_last = $packet->timestamp();
}


sub usage {
	print "usage: rtptimer.pl <address> [<port>]\n";
	exit -1;
}


__END__

=pod

=head1 NAME

rtptimer.pl - Displays arrival times of incoming RTP packet headers

=head1 SYNOPSIS

rtptimer.pl <address> [<port>]

Displays arrival times for incoming RTP packets.
The first column is the time in milliseconds since the tool started,
followed by the time in milliseconds since the last packet.
This is then followed by the source IP, packet length in bytes, 
payload type, sequence number and the packet timestamp. The timestamp 
is then followed by the difference between it and the previous packet.

=head1 SEE ALSO

L<Net::RTP>

L<Net::RTP::Packet>

L<http://www.iana.org/assignments/rtp-parameters>


=head1 BUGS

Unicast addresses aren't currently detected and fail when trying to join 
multicast group.

=head1 AUTHOR

Nicholas J Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 University of Southampton

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut
