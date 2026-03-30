#!/usr/bin/env perl

use strict;
use warnings;
use Test::NoWarnings;

use Test::Most tests => 5;

BEGIN { use_ok('Readonly::Values::Months') }

# Test constants are properly defined and readonly
subtest 'Constants validation' => sub {
	is($JAN, 1, 'January constant is 1');
	is($FEB, 2, 'February constant is 2');
	is($DEC, 12, 'December constant is 12');

	# Test readonly nature
	eval { $JAN = 99; };
	like($@, qr/read-only/i, 'Constants are readonly');
};

# Test month name arrays
subtest 'Month name arrays' => sub {
	is(scalar(@month_names), 12, 'Full month names array has 12 elements');
	is(scalar(@short_month_names), 12, 'Short month names array has 12 elements');

	is($month_names[0], 'january', 'First month is january');
	is($month_names[11], 'december', 'Last month is december');

	is($short_month_names[0], 'jan', 'First short month is jan');
	is($short_month_names[11], 'dec', 'Last short month is dec');
};

# Test month lookup hash
subtest 'Month lookup hash' => sub {
	is($months{'january'}, 1, 'january maps to 1');
	is($months{'jan'}, 1, 'jan maps to 1');
	is($months{'december'}, 12, 'december maps to 12');
	is($months{'dec'}, 12, 'dec maps to 12');

	# Test case sensitivity
	ok(!exists $months{'JANUARY'}, 'Uppercase keys do not exist');
};
