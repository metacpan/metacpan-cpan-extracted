use strict;
use warnings;

use English qw(-no_match_vars);
use PYX::Optimization;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
eval {
	PYX::Optimization->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n");

# Test.
eval {
	PYX::Optimization->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n");

# Test.
# TODO Regular test.
