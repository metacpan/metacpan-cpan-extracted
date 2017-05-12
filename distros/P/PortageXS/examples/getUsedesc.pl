#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;

my $pxs=PortageXS->new();
die "Need to specify 'use' flag for arg 0" unless $ARGV[0];
print "Usedesc of '".$ARGV[0]."' is: ".$pxs->getUsedesc($ARGV[0],$pxs->portdir())."\n";
