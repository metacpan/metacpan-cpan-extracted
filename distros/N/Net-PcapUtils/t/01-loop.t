#!/usr/bin/perl -w
#
# Test Net::PcapUtils::loop() function
#
# $Id: 01-loop.t,v 1.1 1999/04/07 01:23:20 tpot Exp $
#

use strict;
use ExtUtils::testlib;

use Net::PcapUtils;

print("1..1\n");

my $count = 0;

sub process_pkt {
    my $pkt = $_[1];

    print("packet\n");
    exit, if ($count++ > 20);
}

my $result = Net::PcapUtils::loop(\&process_pkt);

if (!$result eq "") {
    print("$result\n");
}

END {
    if ($count > 20) {
	print("ok\n");
    } else {
	print("not ok\n");
    }
}
