# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Random::Set;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
eval {
	Random::Set->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Random::Set->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
eval {
	Random::Set->new;
};
is($EVAL_ERROR, "Bad set sum. Must be 1.\n", 'Bad set sum. Must be 1.');
clean();

# Test.
my $obj = Random::Set->new(
         'set' => [
                 [0.5, 'foo'],
                 [0.5, 'bar'],
         ],
);
isa_ok($obj, 'Random::Set');
