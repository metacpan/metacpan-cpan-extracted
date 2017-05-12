#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	if ( not $ENV{PERL_TEST_POD} ) {
		plan skip_all => 'POD test. Sent $ENV{PERL_TEST_POD} to a true value to run.';
	} else {
		eval "use Test::Spelling";
		if ( $@ ) {
			plan skip_all => 'Test::Spelling required to test POD for spelling errors';
		} else {
			#all_pod_files_spelling_ok();
			plan skip_all => 'need to figure out how to add custom vocabulary to dictionary';
		}
	}
}
