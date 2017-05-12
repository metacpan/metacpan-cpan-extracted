#!/usr/bin/perl

# Test that our declared minimum Perl version matches our syntax
use Test::More;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

my @MODULES = (
	'Perl::MinimumVersion 1.20',
	'Test::MinimumVersion 0.008',
);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		plan( skip_all => "$MODULE not available for testing" );
	}
}

all_minimum_version_from_metayml_ok();

1;
