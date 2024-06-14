use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Random::Day::InTheFuture;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Random::Day::InTheFuture->new;
isa_ok($obj, 'Random::Day::InTheFuture');

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
eval {
	Random::Day::InTheFuture->new(
		'dt_to' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'dt_to' must be a 'DateTime' object.\n",
	"Parameter 'dt_to' must be a 'DateTime' object (bad).");
clean();
