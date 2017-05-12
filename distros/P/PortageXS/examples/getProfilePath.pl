#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;

my $pxs=PortageXS->new();
print "Profile: ".$pxs->getProfilePath()."\n";
