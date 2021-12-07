#!/usr/bin/perl -w
#
# Test for memory leaks in lookup functions
#
# $Id: leaktest2.pl,v 1.3 1999/05/05 02:11:58 tpot Exp $
#

use strict;
use English;

use ExtUtils::testlib;
use Net::Pcap;

my($dev, $net, $mask, $err, $result);

while(1) {
    $dev = Net::Pcap::lookupdev(\$err);
    $result = Net::Pcap::lookupnet($dev, \$net, \$mask, \$err);
}
