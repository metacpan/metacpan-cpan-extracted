#!/usr/bin/perl

use strict;
use warnings;
use PortageXS;

my $pxs=PortageXS->new();

if ($pxs->cmdAskUser('Do you really want to execute this example? A package called test/test will be added to the world file and removed afterwards.','y,n') eq 'y') {
	print "Recording package test/test in world..\n";
	$pxs->recordPackageInWorld("test/test");

	print "Removing package test/test from world..\n";
	$pxs->removePackageFromWorld("test/test");
}

