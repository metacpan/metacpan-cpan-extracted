use strict;
use warnings;

use English qw(-no_match_vars);
use PYX::Stack;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
eval {
	PYX::Stack->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n",
	"Unknown parameter ''.");

# Test.
eval {
	PYX::Stack->new('something' => 'value');
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");

# Test.
my $obj = PYX::Stack->new;
isa_ok($obj, 'PYX::Stack');
