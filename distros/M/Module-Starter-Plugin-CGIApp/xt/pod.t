#!/usr/bin/perl

# Test that the syntax of our POD documentation is valid
use Test::More;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

my @MODULES = (
	'Pod::Simple 3.07',
	'Test::Pod 1.26',
);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		plan( skip_all => "$MODULE not available for testing" );
	}
}

all_pod_files_ok();

1;
