#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;

my $pxs=PortageXS->new();
print "Home: ".$pxs->getHomedir()."\n";
