#!/usr/bin/perl

# Ensure pod coverage in your distribution
use Test::More;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

my @MODULES = (
	'Pod::Coverage 0.18',
	'Test::Pod::Coverage 1.08',
);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		plan( skip_all => "$MODULE not available for testing" );
	}
}

all_pod_coverage_ok();

1;
