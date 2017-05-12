#!/usr/bin/perl -T

use strict;
use warnings;

my @MODULES = (
	'Test::Pod::Coverage 1.08',
	'Pod::Coverage::CountParents',
);

# Don't run tests during end-user installs
use Test::More;
plan( skip_all => 'Author tests not required for installation' )
	unless ( $ENV{RELEASE_TESTING} or $ENV{AUTOMATED_TESTING} );

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		$ENV{RELEASE_TESTING}
		? die( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

all_pod_coverage_ok( { coverage_class => 'Pod::Coverage::CountParents' } );

1;
