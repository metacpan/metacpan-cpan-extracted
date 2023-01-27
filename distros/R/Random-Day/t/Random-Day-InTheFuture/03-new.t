use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Random::Day::InTheFuture;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
eval {
	Random::Day::InTheFuture->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Random::Day::InTheFuture->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
my $obj = Random::Day::InTheFuture->new;
isa_ok($obj, 'Random::Day::InTheFuture');
