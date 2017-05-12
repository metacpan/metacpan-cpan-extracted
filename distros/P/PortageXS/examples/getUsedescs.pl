#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;

my $pxs=PortageXS->new();
die 'Need to specify argument 0' unless $ARGV[0];
print "Usedesc of '".$ARGV[0]."':\n".join("\n",$pxs->getUsedescs($ARGV[0],$pxs->portdir()))."\n";
