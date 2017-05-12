#!/usr/bin/perl

use strict;
use warnings;

use PortageXS;

my $pxs=PortageXS->new();

my @repos=();

push(@repos,$pxs->portdir());
push(@repos,$pxs->getPortdirOverlay());

foreach (@repos) {
	print "Repo: ".$_.":\n";
	print join("\n",$pxs->searchPackageByMaintainer($ARGV[0],$_))."\n\n";
}
