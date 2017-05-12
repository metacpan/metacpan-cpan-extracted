#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;

$|=1;

my $pxs=PortageXS->new();
my $color = $pxs->colors;

if (!-f $ARGV[0]) {
	$color->printColored('RED',"Given file does not exist - Aborting!\n");
}
else {
	$color->printColored('LIGHTGREEN',"Searching for '".$ARGV[0]."'..");

	my @results = $pxs->fileBelongsToPackage($ARGV[0]);

	if ($#results>-1) {
		print " done!\n\n";
		$color->printColored('LIGHTGREEN',"The file '".$ARGV[0]."' was installed by these packages:\n");
		print "   ".join("\n   ",@results)."\n";
	}
	else {
		$color->printColored('RED',"This file has not been installed by portage.\n");
	}
}

exit(0);

