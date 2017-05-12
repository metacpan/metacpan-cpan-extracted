#!perl

# Test that modules are documented by their pod.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

# If using Moose, uncomment the appropriate lines below.
my @MODULES = (
#	'Pod::Coverage::Moose 0.01',
	'Pod::Coverage 0.20',
	'Test::Pod::Coverage 1.08',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

plan tests => 1;

pod_coverage_ok('File::List::Object', { 
#  coverage_class => 'Pod::Coverage::Moose', 
  also_private => [ qr/^[A-Z_]+$/ ],
});

