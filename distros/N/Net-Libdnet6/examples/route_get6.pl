#!/usr/bin/perl
use strict;
use warnings;

my $dst = shift || die("Specify target host\n");

use Net::Frame::Layer qw(:subs);

$dst = getHostIpv6Addr($dst) or die("Lookup\n");

use Data::Dumper;
use Net::Libdnet6;

my $h = route_get6($dst);
print Dumper($h)."\n";
