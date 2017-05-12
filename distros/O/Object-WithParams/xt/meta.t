#!/usr/bin/perl

# Test that our META.yml file matches the specification
use Test::More;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

my @MODULES = (
	'Test::CPAN::Meta 0.12',
);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		plan( skip_all => "$MODULE not available for testing" );
	}
}

meta_yaml_ok();

1;
