use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Tags::Output;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
eval {
	Tags::Output->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", "Unknown parameter ''.");
clean();

# Test.
eval {
	Tags::Output->new('something' => 'value');
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");
clean();

# Test.
my $obj = Tags::Output->new;
isa_ok($obj, 'Tags::Output');
