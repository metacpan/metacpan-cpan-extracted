#!perl -wT

use strict;
use warnings;
use Test::Most;

unless($ENV{AUTHOR_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

# eval 'use warnings::unused -global';
eval 'use warnings::unused';

if($@ || ($warnings::unused::VERSION < 0.04)) {
	plan(skip_all => 'warnings::unused >= 0.04 needed for testing');
} else {
	use_ok('Sub::Private');
	plan(tests => 1);
}
