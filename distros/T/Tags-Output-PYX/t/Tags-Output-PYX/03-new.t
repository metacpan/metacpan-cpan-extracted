use strict;
use warnings;

use English qw(-no_match_vars);
use Tags::Output::PYX;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
eval {
	Tags::Output::PYX->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", "Unknown parameter ''.");

# Test.
eval {
	Tags::Output::PYX->new('something' => 'value');
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");

# Test.
eval {
	Tags::Output::PYX->new('output_handler' => '');
};
is($EVAL_ERROR, 'Output handler is bad file handler.'."\n",
	'Output handler is bad file handler.');

# Test.
my $obj = Tags::Output::PYX->new;
isa_ok($obj, 'Tags::Output::PYX');
