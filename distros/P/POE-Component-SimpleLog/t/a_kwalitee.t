#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	eval "require Test::Kwalitee";
	if ( $@ ) {
		plan skip_all => 'Test::Kwalitee required for measuring the kwalitee';
	} else {
		Test::Kwalitee->import();
	}
}
