#!/usr/bin/perl

use strict;
use warnings;
use Net::Pcap::Easy;

my $npe = Net::Pcap::Easy->new(
    dev              => "eth0",
    filter           => "icmp",
    packets_per_loop => 10,

    icmp_callback => sub { warn "ping or something!\n" },
);

1 while $npe->loop; # loop() returns 10, 10, 10, until you hit ^C
exit 0;

