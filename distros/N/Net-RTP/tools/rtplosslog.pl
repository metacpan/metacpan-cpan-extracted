#!/usr/bin/perl
#
# Log packet loss for a RTP session every minute
#

use 5.008;             # 5.8 required for stable threading
use strict;
use warnings;
use threads;
use threads::shared;

use Net::RTP;
use Time::Local;
use Time::HiRes qw/ sleep /;
use Data::Dumper;


my $IP_HEADER_SIZE = 28; 	# 20 bytes of IPv4 header and 8 bytes of UDP header
my $DEFAULT_PORT = 5004;	# Default RTP port


# Make STDOUT unbuffered
$|=1;


# Create RTP socket
my ($address, $port, $src_ip) = @ARGV;
usage() unless (defined $address);
$port = $DEFAULT_PORT unless (defined $port);
my $rtp = new Net::RTP(
		LocalPort=>$port,
		LocalAddr=>$address
) || die "Failed to create RTP socket: $!";


# Shared variable used for collecting statistics
our $stats = &share( {} );
reset_stats($stats);
threads->new( \&display_stats );


while (1) {

	my $packet = $rtp->recv();
	die "Failed to recieve packet: $!" unless (defined $packet);
	
	# No chosen source IP yet?
	my $src = $packet->source_ip();
	unless (defined $src_ip) {
		print STDERR "# Using $src as source IP address.\n"; 
		$src_ip = $src;
	}
	next if ($src ne $src_ip);
	
	# First packet ?
	unless (defined $stats->{'first_packet'}) {
		$stats->{'first_packet'}=time();
		$stats->{'ssrc'}=$packet->ssrc();
		$stats->{'seq_num'}=$packet->seq_num();
	}
	
	# Verfify Source Identifier
	if ($stats->{'ssrc'} ne $packet->ssrc()) {
		warn "# SSRC of packets from '$src' has changed.\n";
		$stats->{'ssrc'} = $packet->ssrc();
	}
	
	# Update statistics
	$stats->{'bytes'} += $packet->size()+$IP_HEADER_SIZE;
	$stats->{'packets'} += 1;
	
	# Lost or OutOfOrder packet?
	if ($stats->{'seq_num'} != $packet->seq_num()) {
		if ($stats->{'seq_num'}-1 == $packet->seq_num()) {
			# Duplicated
			$stats->{'dup'}++;
		} elsif ($stats->{'seq_num'} > $packet->seq_num()) {
			# Out Of Order
			$stats->{'late'}++;
			$stats->{'lost'}--;
		} else {
			# Lost
			$stats->{'lost'}+=($packet->seq_num()-$stats->{'seq_num'});
		}
	}
	
	# Calculate next number in sequence
	$stats->{'seq_num'} = $packet->seq_num()+1;
	if ($stats->{'seq_num'} > 65535) {
		$stats->{'seq_num'}=0;
	}
}


sub display_stats {

	# Wait until the first second of a minute
	my $start = start_of_next_minute();
	print STDERR "# Waiting until start of next minute.\n";
	sleep( $start-time() );
	print STDERR "# Timestamp\tPackets\tBytes\tLost\tLate\n";

	my $next = $start+60;
	
	while (1) {
		# Set everything back to Zero
		reset_stats( $stats );
		
		# Wait until time for next check
		sleep($next-time()) if ($next-time()>0);

		printf("%d\t%d\t%d\t%d\t%d\n", time()-60, $stats->{'packets'}, $stats->{'bytes'}, $stats->{'lost'}, $stats->{'late'} );
		
		# Report again in 1 minute
		$next += 60.0;
	}
	
}

sub start_of_next_minute {
	my ($sec,$min,$hour,$mday,$mon,$year) = gmtime();
	$sec=0;
	$min++;
	return timegm($sec,$min,$hour,$mday,$mon,$year);
}

sub reset_stats {
	my ($stats) = @_;

	$stats->{'packets'}=0;	# Packets in past second
	$stats->{'bytes'}=0;	# Bytes in past second
	$stats->{'lost'}=0;		# Packets lost in past second
	$stats->{'late'}=0;		# Out of order
	$stats->{'dup'}=0;		# Duplicated packets in past second

}


sub usage {
	print "usage: rtplosslog.pl <address> [<port>] [<src_ip>]\n";
	exit -1;
}


__END__

=pod

=head1 NAME

rtplosslog.pl - Log packet loss for a RTP session every minute

=head1 SYNOPSIS

rtplosslog.pl <address> [<port>] [<src_ip>]

=head1 DESCRIPTION

rtplosslog.pl displays the packet loss summary for a specific transmitter 
for each minute that passes. 
If no port is specified, then port 5004 is assumed.
If no source address is specified, then the source address of the 
first packet recieved is used.

rtplosslog.pl uses seperate threads for 
recieving packets and displaying statistics, so version 5.8 or greater 
of perl is recommended for stable threading.

When rtplosslog.pl is started, it waits until the start of a minute before
starting to log packet loss. Thereafter a row is displayed for each minute 
that passes (even if no packets have been recieved).  The log data is sent, 
with each field seperated by a tab, to STDOUT.
Additional messages are sent to STDERR.

The fields in each row are as follows:

=over

=item

The first column is the UNIX timestamp for the start of the 
reported minute. 

=item

The second column is the number of packets that were recieved in that minute.

=item

The third column is the number of bytes that were recieved in that 
minute (including estimated IP packet headers).

=item

The fourth column is the number of packets that were lost in the minute.

=item

The fifth column is the number of packets that arrived late (out of order).

=back


=head1 SEE ALSO

L<Net::RTP>

L<Net::RTP::Packet>

=head1 BUGS

Unicast addresses aren't currently detected and fail when trying to join 
multicast group.

=head1 AUTHOR

Nicholas J Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 University of Southampton

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.008 or,
at your option, any later version of Perl 5 you may have available.

=cut

