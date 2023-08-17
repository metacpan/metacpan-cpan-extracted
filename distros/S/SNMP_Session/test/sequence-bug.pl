#!/usr/local/bin/perl -w

use strict;

use SNMP_Session;
use SNMP_util;

my $snmphost = $ARGV[0];

my (%IN, %OUT);
my @ret = &snmpwalk($snmphost, "ipAdEntIfIndex");
foreach my $desc (@ret) {
    my ($ipad, $ifType);
    ($ipad, $desc) = split(':', $desc, 2);
    next if $ipad=~/127.0.0.1/;

    ($ifType,$IN{$ipad},$OUT{$ipad})=&snmpget($snmphost,"ifType.$desc","ifInOctets.$desc","ifOutOctets.$desc");
}

foreach my $ipad (sort keys %IN) {
    printf "%-15s %12d %12d\n", $ipad, $IN{$ipad}, $OUT{$ipad};
}
