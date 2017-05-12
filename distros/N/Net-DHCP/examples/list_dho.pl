#!/usr/bin/perl

use strict;
use warnings;

use Net::DHCP::Constants qw( %REV_DHO_CODES );

for my $key (sort {$a <=> $b} keys %REV_DHO_CODES) {
	printf "  (%03d) %s\n", $key, $REV_DHO_CODES{$key};
}

1;


