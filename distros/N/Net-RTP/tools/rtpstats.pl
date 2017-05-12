#!/usr/bin/perl
#
# Displays packet statistics for an RTP session
#

use 5.008;             # 5.8 required for stable threading
use strict;
use warnings;
use threads;
use threads::shared;

use Net::RTP;
use Time::HiRes qw/ sleep time /;
use Data::Dumper;


my $IP_HEADER_SIZE = 28; 	# 20 bytes of IPv4 header and 8 bytes of UDP header
my $DEFAULT_PORT = 5004;	# Default RTP port


# Make STDOUT unbuffered
$|=1;


# Create RTP socket
my ($address, $port) = @ARGV;
usage() unless (defined $address);
$port = $DEFAULT_PORT unless (defined $port);
my $rtp = new Net::RTP(
		LocalPort=>$port,
		LocalAddr=>$address
) || die "Failed to create RTP socket: $!";



# Shared variable used for collecting statistics
our $all_stats = &share({});
threads->new( \&display_stats );

my $seq=0;
while (1) {

	my $packet = $rtp->recv();
	die "Failed to recieve packet: $!" unless (defined $packet);
	
	# No stats for that SSRC yet?
	my $ssrc = $packet->ssrc();
	unless (exists $all_stats->{$ssrc}) {
		$all_stats->{$ssrc} = init_stats( $packet )
	}
	my $stats = $all_stats->{$ssrc};
	
	# Verfify Source Address
	if ($stats->{'source_ip'} ne $packet->source_ip()) {
		warn "Source IP of SSRC of  '$ssrc' has changed.\n";
		$stats->{'source_ip'} = $packet->source_ip();
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

	my $start = time();
	my $next = $start+1;
	
	print_key();
	
	while (1) {
		# Wait until time for next check
		sleep($next-time()) if ($next-time()>0);

		my ($sec, $min, $hour) = localtime();
		print_key() if ($sec==0);
		
		foreach my $stats ( values %$all_stats ) {
			$stats->{'total_packets'}+=$stats->{'packets'};
			$stats->{'total_bytes'}+=$stats->{'bytes'};
			$stats->{'total_lost'}+=$stats->{'lost'};
			$stats->{'total_late'}+=$stats->{'late'};
			
			printf("%2.2d:%2.2d:%2.2d  %3d  %3d  %3d  %6d | %5d  %4d  %4d %6d  %4d  %s\n",
			$hour, $min, $sec, 
			$stats->{'packets'}, $stats->{'lost'}, $stats->{'late'}, $stats->{'bytes'},
			$stats->{'total_packets'}, $stats->{'total_lost'}, $stats->{'total_late'},
			$stats->{'total_bytes'}/1024, 
			(($stats->{'total_bytes'}*8)/1000)/(time()-$stats->{'first_packet'}), 
			$stats->{'source_ip'}, );
			
			reset_stats( $stats );
		}

		# Report again in 1 second
		$next += 1.0;
	}
	
}

sub print_key {
	print "Time     Pkts Lost Late   Bytes |  Pkts  Lost  Late     kB  kbps  Sender\n";
}

sub init_stats {
	my ($packet) = @_;
	my $stats = &share( {} );

	$stats->{'ssrc'}=$packet->ssrc();
	$stats->{'seq_num'}=$packet->seq_num();
	$stats->{'source_ip'}=$packet->source_ip();
	$stats->{'first_packet'}=time();
	
	$stats->{'total_packets'}=0;
	$stats->{'total_bytes'}=0;
	$stats->{'total_lost'}=0;
	$stats->{'total_late'}=0;
	$stats->{'total_dup'}=0;
	
	reset_stats($stats);

	return $stats;
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
	print "usage: rtpstats.pl <address> [<port>]\n";
	exit -1;
}


__END__

=pod

=head1 NAME

rtpstats.pl - Displays packet statistics for an RTP session

=head1 SYNOPSIS

rtpstats.pl <address> [<port>]

=head1 DESCRIPTION

rtpstats.pl displays packet statistics for an RTP session. It is a 
clone of rtpqual by Matthew B Mathis with a few changes in design. 
If no port is specified, then port 5004 is assumed.

rtpstats.pl uses seperate threads for 
recieving packets and displaying statistics, so version 5.8 or greater 
of perl is recommended for stable threading.

For every second that passes, a row is printed for each transmitter
to the multicast group. The first (left-hand) second displays statistics for 
the current second, and the second (right-hand) second displays the 
cumulative totals for transmitter.

=over

=item 1

The time in hours:minutes:seconds on the local host

=item 2

The number of packets recieved from the transmitter in the past second.

=item 3

The number of packets lost in the past second.

=item 4

The number of packets that arrived late (out-of-order) in the past second.

=item 5

The number of bytes (including estimated IP header size) in the past second.

=item 6

The total number of packets recieved from the transmitter.

=item 7

The total number of packets lost.

=item 8

The total number of packets late (out-of-order).

=item 9

The total number of kilobytes recieved from the transmitter.

=item 10

The average kilobits per second since the first packet was recieved.

=item 11

The IP address of the transmitter.

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

