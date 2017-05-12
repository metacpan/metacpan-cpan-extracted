#!/usr/bin/perl

use 5.006;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
BEGIN {
	$DB::single = 1;
}

use Politics::AU::Geo;





######################################################################
# Basic Query

SCOPE: {
	my @electorates = Politics::AU::Geo->geo2electorates( -33.895922, 151.110022 );
	is( scalar(@electorates), 4, 'Found 4 electorates for a NSW point' );
}
