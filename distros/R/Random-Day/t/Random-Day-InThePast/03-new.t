use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Random::Day::InThePast;
use Test::More 'tests' => 4;
use Test::NoWarnings;

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
my $obj = Random::Day::InThePast->new;
isa_ok($obj, 'Random::Day::InThePast');
