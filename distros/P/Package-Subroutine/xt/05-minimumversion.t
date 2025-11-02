#!/usr/bin/perl
# Test that our declared minimum Perl version matches our syntax

use Test2::V0;

# Don't run tests during end-user installs
skip_all( 'Author tests not required for installation' )
	unless ( $ENV{RELEASE_TESTING} or $ENV{AUTOMATED_TESTING} );


my @MODULES = (
	'Perl::MinimumVersion 1.20',
	'Test::MinimumVersion 0.008',
);


# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		$ENV{RELEASE_TESTING}
		? die( "Failed to load required release-testing module $MODULE" )
		: skip_all("$MODULE not available for testing");
	}
}

all_minimum_version_from_metayml_ok();

1;
