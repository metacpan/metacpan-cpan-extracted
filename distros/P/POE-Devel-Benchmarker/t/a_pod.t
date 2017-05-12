#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	if ( not $ENV{PERL_TEST_POD} ) {
		plan skip_all => 'POD test. Sent $ENV{PERL_TEST_POD} to a true value to run.';
	} else {
		eval "use Test::Pod";
		if ( $@ ) {
			plan skip_all => 'Test::Pod required for testing POD';
		} else {
			all_pod_files_ok();
		}
	}
}
