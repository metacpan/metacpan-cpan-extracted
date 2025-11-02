#!/usr/bin/perl

use Test2::V0;

my @MODULES = (
	'Test::DistManifest 1.003',
);

# Don't run tests during end-user installs
skip_all('Author tests not required for installation')
	unless ( $ENV{RELEASE_TESTING} );

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		$ENV{RELEASE_TESTING}
		? die( "Failed to load required release-testing module $MODULE" )
		: skip_all("$MODULE not available for testing" );
	}
}

manifest_ok();

1;
