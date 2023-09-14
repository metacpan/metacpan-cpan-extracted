use strict;
use warnings;

use English qw(-no_match_vars);
use PYX::Sort;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
eval {
	PYX::Sort->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n");

# Test.
eval {
	PYX::Sort->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n");

# Test.
my $obj = PYX::Sort->new;
isa_ok($obj, 'PYX::Sort');
