use strict;
use warnings;
package Net::Inspect;

our $VERSION = "0.326";
1;


=head1 NAME

Net::Inspect - library for inspection of data on various network layers

=head1 SYNOPSIS

    use Net::Pcap 'pcap_loop';
    use Net::Inspect::L2::Pcap;
    use Net::Inspect::L3::IP;
    use Net::Inspect::L4::TCP;
    use Net::Inspect::L7::HTTP;
    use Net::Inspect::L7::HTTP::Request::InspectChain;
    use Net::Inspect::Debug;

    my $pcap = Net::Pcap->new...
    ...
    my $l7 = Net::Inspect::L7::HTTP->new;
    my $l4 = Net::Inspect::L4::TCP->new($l7);
    my $l3 = Net::Inspect::L3::IP->new($l4);
    my $l2 = Net::Inspect::L2::Pcap->new($pcap,$l3);

    pcap_loop($pcap,-1,sub {
	my (undef,$hdr,$data) = @_;
	return $l2->pktin($data,$hdr);
    });

=head1 DESCRIPTION

The idea of L<Net::Inspect> is to plug various layers of network inspection
together to analyze data.
This is kind of what wireshark or IDS do, exept this is in perl and
therefore slower to execute but faster to develop and maybe more flexibel
too.

One can start analysis on some level and stop it at any higher level.
There are various useful tools in tools/ which make use of this library:

=over 4

=item tcpflow

gets data from pcap file or does live capture and extracts tcp connections
into separate files.

=item httpflow

gets data from pcap file or does live capture and extracts http requests
into separate files. Does request unchunking and decompression. Works with
persistant and with pipelined HTTP connections.

=item http_inspection_proxy

simple http(s) proxy with the ability to inspect and transform requests.
Contrary to L<tcpflow> and L<httpflow> it starts analysis at the TCP
layer, not at the pcap layer.

Because of non-blocking DNS lookups and connects and DNS caching the proxy
is fast enough to be used in simple production setups. It can also store
each http connections as a single pcap file for more analysis.

=back

Currently the following modules are implemented:

=over 4

=item L<Net::Inspect::L2::Pcap>

reads from pcap layer

=item L<Net::Inspect::L3::IP>

processes raw IP packets, does defragmentation.

=item L<Net::Inspect::L4::TCP>

handles TCP connections, e.g. connection setup and shutdown and reordering
of packets.

=item L<Net::Inspect::L4::UDP>

handles UDP packets. Can aggregate udp packets in virtual connections.

=item L<Net::Inspect::L5::GuessProtocol>

tries to guess the higher level protocol from TCP connections.

=item L<Net::Inspect::L7::HTTP>

handles HTTP connections. Plugable into L<Net::Inspect::L5::GuessProtocol>.

=item L<Net::Inspect::L5::Null>

handles connections which don't transport any data.
Plugable into L<Net::Inspect::L5::GuessProtocol>.

=item L<Net::Inspect::L5::Unknown>

used together with L<Net::Inspect::L5::GuessProtocol> as a fallback if no
other protocol handler matched.

=back

=head1 BUGS

Probably still a lot.
The HTTP part was tested with a lot of real-life traffic, so it should be
kind of stable. There is currently no support for IPv6.

=head1 SEE ALSO

L<Net::Sharktools>
L<Net::Analysis>

=head1 AUTHOR

Steffen Ullrich, <sullr@cpan.org>

=head1 COPYRIGHT

  Copyright 2011-2013 Steffen Ullrich

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
