#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	eval "use Test::Fixme";
	if ( $@ ) {
		plan skip_all => 'Test::Fixme required for checking for presence of FIXMEs';
	} else {
		run_tests(
			'where'		=> 'lib',
			'match'		=> qr/FIXME|TODO/,
		);
	}
}
