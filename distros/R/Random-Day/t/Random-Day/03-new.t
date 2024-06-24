use strict;
use warnings;

use DateTime;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Random::Day;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $obj = Random::Day->new;
isa_ok($obj, 'Random::Day');

# Test.
my $act_dt = DateTime->now;
$obj = Random::Day->new(
	'dt_from' => $act_dt,
	'dt_to' => $act_dt,
);
isa_ok($obj, 'Random::Day');

# Test.
eval {
	Random::Day->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Random::Day->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
eval {
	Random::Day->new(
		'dt_from' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'dt_from' must be a 'DateTime' object.\n",
	"Parameter 'dt_from' must be a 'DateTime' object (bad).");
clean();

# Test.
eval {
	Random::Day->new(
		'dt_to' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'dt_to' must be a 'DateTime' object.\n",
	"Parameter 'dt_to' must be a 'DateTime' object (bad).");
clean();

# Test.
eval {
	Random::Day->new(
		'dt_from' => DateTime->new(
			'year' => '2200',
		),
		'dt_to' => DateTime->new(
			'year' => '2100',
		),
	);
};
is($EVAL_ERROR, "Parameter 'dt_from' must have older or same date than 'dt_to'.\n",
	"Parameter 'dt_from' must have older or same date than 'dt_to'.");
clean();
