use strict;
use warnings;

use English qw(-no_match_vars);
use PYX::Hist;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
eval {
	PYX::Hist->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", "Unknown parameter ''.");

# Test.
eval {
	PYX::Hist->new('something' => 'value');
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");

# Test.
my $obj = PYX::Hist->new;
isa_ok($obj, 'PYX::Hist');
