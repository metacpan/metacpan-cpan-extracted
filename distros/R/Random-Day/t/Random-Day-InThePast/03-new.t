use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Random::Day::InThePast;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Random::Day::InThePast->new;
isa_ok($obj, 'Random::Day::InThePast');

# Test.
eval {
	Random::Day::InThePast->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Random::Day::InThePast->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
eval {
	Random::Day::InThePast->new(
		'dt_from' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'dt_from' must be a 'DateTime' object.\n",
	"Parameter 'dt_from' must be a 'DateTime' object (bad).");
clean();
