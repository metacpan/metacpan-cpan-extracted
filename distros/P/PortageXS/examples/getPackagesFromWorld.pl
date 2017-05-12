#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;

my $pxs=PortageXS->new();

print "Packages recorded in ".$pxs->{'PATH_TO_WORLDFILE'}."\n";
print join("\n",$pxs->getPackagesFromWorld())."\n";

