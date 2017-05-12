#!/usr/bin/perl

use strict;
use warnings;
use Net::Pcap::Easy;

my $dev      = shift || "lo";
my $host     = shift; $host = $host ? "host $host and" : "";
my $SHOW_MAC = 1;

# all arguments to new are optoinal
my $npe = Net::Pcap::Easy->new(
    dev              => $dev,
    filter           => "$host (tcp or icmp)",
    packets_per_loop => 10,
    bytes_to_capture => 1024,
    timeout_in_ms    => 0, # 0ms means forever
    promiscuous      => 0, # true or false

    tcp_callback => sub {
        my ($npe, $ether, $ip, $tcp, $header ) = @_;
        my $xmit = localtime( $header->{tv_sec} );

        print "$xmit TCP: $ip->{src_ip}:$tcp->{src_port}"
         . " -> $ip->{dest_ip}:$tcp->{dest_port}\n";

        print "\t$ether->{src_mac} -> $ether->{dest_mac}\n" if $SHOW_MAC;
    },

    icmp_callback => sub {
        my ($npe, $ether, $ip, $icmp, $header ) = @_;
        my $xmit = localtime( $header->{tv_sec} );

        print "$xmit ICMP: $ether->{src_mac}:$ip->{src_ip}"
         . " -> $ether->{dest_mac}:$ip->{dest_ip}\n";
    },
);

1 while $npe->loop;
