use strict;
use warnings;

use English qw(-no_match_vars);
use PYX::XMLNorm;
use Test::More 'tests' => 4;

# Test.
eval {
	PYX::XMLNorm->new('');
};
ok($EVAL_ERROR, "Unknown parameter ''.");

# Test.
eval {
	PYX::XMLNorm->new(
		'something' => 'value',
	);
};
ok($EVAL_ERROR, "Unknown parameter 'something'.");

# Test.
eval {
	PYX::XMLNorm->new;
};
ok($EVAL_ERROR, "Cannot exist XML normalization rules.");

# Test.
my $obj = PYX::XMLNorm->new(
	'rules' => {
		'*' => ['br'],
	},
);
isa_ok($obj, 'PYX::XMLNorm');
