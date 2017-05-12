#!/usr/bin/perl
use strict;
use warnings;

my $dev = shift || die("Specify network interface\n");

use Data::Dumper;
use Net::Libdnet6;

my $h = intf_get6($dev);
print Dumper($h)."\n";
