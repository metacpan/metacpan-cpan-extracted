# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Tags::Output::Structure;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
eval {
	Tags::Output::Structure->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", "Unknown parameter ''.");

# Test.
eval {
	Tags::Output::Structure->new('something' => 'value');
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");

# Test.
eval {
	Tags::Output::Structure->new('output_handler' => '');
};
is($EVAL_ERROR, 'Output handler is bad file handler.'."\n",
	'Output handler is bad file handler.');

# Test.
my $obj = Tags::Output::Structure->new;
isa_ok($obj, 'Tags::Output::Structure');
