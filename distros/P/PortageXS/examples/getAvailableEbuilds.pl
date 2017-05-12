#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;

my $pxs=PortageXS->new();
print "List of available ebuilds from dev-lang/perl:\n";
print join("\n",$pxs->getAvailableEbuilds("dev-lang/perl"))."\n";
