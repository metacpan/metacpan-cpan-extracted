#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;

my $pxs=PortageXS->new();
if ( not $ARGV[0]) {
    die "Need a package to search for 'name' ";
}
print "Search for installed packages named: $ARGV[0]\n\n";
print join("\n",$pxs->searchInstalledPackage($ARGV[0]))."\n";
