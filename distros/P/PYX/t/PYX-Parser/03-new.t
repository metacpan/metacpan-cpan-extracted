# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use PYX::Parser;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
eval {
	PYX::Parser->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", "Unknown parameter ''.");
clean();

# Test.
eval {
	PYX::Parser->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");
clean();

# Test.
my $obj = PYX::Parser->new;
isa_ok($obj, 'PYX::Parser');
