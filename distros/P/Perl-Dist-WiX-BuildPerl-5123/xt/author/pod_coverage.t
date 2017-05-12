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
	'Pod::Coverage 0.21',
	'Test::Pod::Coverage 1.08',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

my @modules = all_modules();
my @modules_to_test = sort { $a cmp $b } @modules;
my $test_count = scalar @modules_to_test;
plan tests => $test_count;

foreach my $module (@modules_to_test) {
	pod_coverage_ok($module, { 
#		coverage_class => 'Pod::Coverage::Moose', 
		also_private => [ qr/^[A-Z_]+$/ ],
	});
}

