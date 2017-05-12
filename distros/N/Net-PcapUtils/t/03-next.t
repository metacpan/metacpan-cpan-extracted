#!/usr/bin/perl -w
#
# Test Net::PcapUtils::next() function
#
# $Id: 03-next.t,v 1.1 1999/04/07 01:23:21 tpot Exp $
#

use strict;
use ExtUtils::testlib;

use Net::PcapUtils;

print("1..2\n");

my $pcap_t = Net::PcapUtils::open();

if (!ref($pcap_t)) {
    print("$pcap_t\nnot ok\n");
    exit;
}

print("ok\n");

my($pkt, %hdr);
my $count = 0;

while(($pkt, %hdr) = Net::PcapUtils::next($pcap_t)) {
    use Data::Dumper;
    print("packet $count: ");
    print Dumper %hdr;
    $count++;

    last, if ($count == 25);
}

($count == 25) ? print("ok\n") : print("not ok\n");
