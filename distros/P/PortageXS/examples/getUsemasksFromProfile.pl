#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;

$|=1;

my $pxs=PortageXS->new();
print "uses masked in profile:\n";
print join("\n",$pxs->getUsemasksFromProfile())."\n";

print "\nExecuting getUsemasksFromProfile() 500 times uncached:\n";
for (1..500) { $pxs->resetCaches(); $pxs->getUsemasksFromProfile(); print "."; }
print "done\n";

$pxs->resetCaches();

print "\nExecuting getUsemasksFromProfile() 500 times cached:\n";
for (1..500) { $pxs->getUsemasksFromProfile(); print "."; }
print "done\n";

