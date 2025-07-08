use strict;
use warnings;

use DateTime;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Random::Day;
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Test.
my $obj = Random::Day->new;
isa_ok($obj, 'Random::Day');

# Test.
## Different dates.
$obj = Random::Day->new(
	'dt_from' => DateTime->new(
		'year' => 2025,
		'month' => 7,
		'day' => 1,
	),
	'dt_to' => DateTime->new(
		'year' => 2025,
		'month' => 7,
		'day' => 20,
	),
);
isa_ok($obj, 'Random::Day');

# Test.
## The same day, dt_from is on the begin of day.
$obj = Random::Day->new(
	'dt_from' => DateTime->new(
		'day' => 7,
		'month' => 7,
		'year' => 2025,
		'hour' => 0,
		'minute' => 0,
		'second' => 0,
	),
	'dt_to' => DateTime->new(
		'day' => 7,
		'month' => 7,
		'year' => 2025,
		'hour' => 9,
		'minute' => 10,
		'second' => 10,
	),
);
isa_ok($obj, 'Random::Day');

# Test.
## The same day, different month.
$obj = Random::Day->new(
	'dt_from' => DateTime->new(
		'day' => 7,
		'month' => 6,
		'year' => 2025,
		'hour' => 1,
		'minute' => 10,
		'second' => 20,
	),
	'dt_to' => DateTime->new(
		'day' => 7,
		'month' => 7,
		'year' => 2025,
		'hour' => 9,
		'minute' => 10,
		'second' => 10,
	),
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

# Test.
eval {
	Random::Day->new(
		'dt_from' => DateTime->new(
			'year' => 2025,
			'month' => 7,
			'day' => 7,
			'hour' => 10,
			'minute' => 0,
			'second' => 0,
		),
		'dt_to' => DateTime->new(
			'year' => 2025,
			'month' => 7,
			'day' => 7,
			'hour' => 12,
			'minute' => 10,
			'second' => 10,
		),
	);
};
is($EVAL_ERROR, "Parameters 'dt_from' and 'dt_to' are in the same day and not on begin.\n",
	"Parameters 'dt_from' and 'dt_to' are in the same day and not on begin (2025-07-07 10:00:00 and 2025-07-07 12:00:00).");
clean();
