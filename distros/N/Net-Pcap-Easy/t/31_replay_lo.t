#!/usr/bin/perl

use strict;
use Net::Pcap::Easy;
use File::Slurp qw(slurp);

use Test;

plan tests => 6*2 + 4;

my $npe = Net::Pcap::Easy->new(
    dev              => "file:dat/lo.data",
    promiscuous      => 0,
    packets_per_loop => 3,

    icmp_callback => sub {
        my ($npe, $ether, $ip, $icmp) = @_;

        ok( $ip->{src_ip},  "127.0.0.1" );
        ok( $ip->{dest_ip}, "127.0.0.1" );
    },
);

ok( $npe->loop, 3 ) for 1 .. 2;
ok( $npe->loop, 0 );
ok( $npe->loop, 0 );

__END__
bash$ tcpdump -nr ../lo.data 
reading from file ../lo.data, link-type EN10MB (Ethernet)
16:56:54.508250 IP 127.0.0.1 > 127.0.0.1: ICMP echo request, id 64876, seq 1, length 64
16:56:54.508275 IP 127.0.0.1 > 127.0.0.1: ICMP echo reply, id 64876, seq 1, length 64

16:56:55.507257 IP 127.0.0.1 > 127.0.0.1: ICMP echo request, id 64876, seq 2, length 64
16:56:55.507283 IP 127.0.0.1 > 127.0.0.1: ICMP echo reply, id 64876, seq 2, length 64

16:56:56.506259 IP 127.0.0.1 > 127.0.0.1: ICMP echo request, id 64876, seq 3, length 64
16:56:56.506286 IP 127.0.0.1 > 127.0.0.1: ICMP echo reply, id 64876, seq 3, length 64

