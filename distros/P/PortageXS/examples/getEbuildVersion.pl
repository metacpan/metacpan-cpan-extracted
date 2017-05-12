#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;

my $pxs=PortageXS->new();

foreach ($pxs->searchInstalledPackage('*')) {
	my $e=(split(/\//,$_))[1].".ebuild";
	print $e." -> ".$pxs->getEbuildVersion($e)."\n";
}
