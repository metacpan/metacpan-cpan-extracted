#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	eval "use Test::YAML::Meta";
	if ( $@ ) {
		plan skip_all => 'Test::YAML::Meta required for validating the meta.yml file';
	} else {
		meta_yaml_ok();
	}
}
