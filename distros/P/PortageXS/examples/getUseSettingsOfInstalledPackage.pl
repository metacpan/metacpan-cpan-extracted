#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;

my $package	= "dev-lang/perl";
$package = $ARGV[0] if $ARGV[0];

my $pxs=PortageXS->new();

if (($pxs->searchInstalledPackage($package))[0]) {
	print "Package ".($pxs->searchInstalledPackage($package))[0]." has been compiled with useflags set: ";
	#print join(" ",$pxs->formatUseflags($pxs->getUseSettingsOfInstalledPackage(($pxs->searchInstalledPackage($package))[0])))."\n";
	foreach my $thisUSE ($pxs->sortUseflags($pxs->getUseSettingsOfInstalledPackage(($pxs->searchInstalledPackage($package))[0]))) {
		if (substr($thisUSE,0,1) eq '-') {
			$thisUSE=substr($thisUSE,1,length($thisUSE)-1);
		}
		my $thisUSEDESC=($pxs->getUsedescs($thisUSE,$pxs->portdir(),$package))[0];

		print $thisUSE." --> ";
		if ($thisUSEDESC) {
			print $thisUSEDESC,"\n";
		}
		else {
			print "<unknown>\n";
		}
	}
}
else {
	print "No such package found.\n";
}
