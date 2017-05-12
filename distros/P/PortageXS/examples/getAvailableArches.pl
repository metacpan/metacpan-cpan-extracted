#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;

my $pxs=PortageXS->new();
print "List of available arches:\n";
print join("\n",$pxs->getAvailableArches())."\n";
