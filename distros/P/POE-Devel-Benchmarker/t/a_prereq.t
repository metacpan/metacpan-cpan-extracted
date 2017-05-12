#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	if ( not $ENV{PERL_TEST_PREREQ} ) {
		plan skip_all => 'PREREQ test ( warning: LONG! ) Sent $ENV{PERL_TEST_PREREQ} to a true value to run.';
	} else {
		eval "use Test::Prereq";
		if ( $@ ) {
			plan skip_all => 'Test::Prereq required to test perl module deps';
		} else {
			prereq_ok();
		}
	}
}
