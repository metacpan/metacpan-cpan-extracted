#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	if ( not $ENV{PERL_TEST_POD} ) {
		plan skip_all => 'POD test. Sent $ENV{PERL_TEST_POD} to a true value to run.';
	} else {
		eval "use Test::Pod::Coverage";
		if ( $@ ) {
			plan skip_all => "Test::Pod::Coverage required for testing POD coverage";
		} else {
			# FIXME not used now
			#all_pod_coverage_ok( 'lib/');
			plan skip_all => 'not done yet';
		}
	}
}
