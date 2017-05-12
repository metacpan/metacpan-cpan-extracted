#!/usr/bin/perl

use strict;
use warnings;

use PortageXS;

my $pxs=PortageXS->new();

my @repos=();

if ( not $ARGV[0] ) {
    die "Specify a herd to search for packages";
}

push(@repos,$pxs->portdir());
push(@repos,$pxs->getPortdirOverlay());

foreach (@repos) {
	print "Repo: ".$_.":\n";
	print join("\n",$pxs->searchPackageByHerd($ARGV[0],$_))."\n\n";
}
