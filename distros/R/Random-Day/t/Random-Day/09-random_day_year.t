use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Random::Day;
use Test::More 'tests' => 13;
use Test::NoWarnings;

# Test.
my $obj = Random::Day->new;
my $ret = $obj->random_day_year(10, 2014);
isa_ok($ret, 'DateTime');
like($ret, qr{^2014-\d\d-10T00:00:00$},
	'Right date from day, month and year informations (10-??-2014).');

# Test.
$obj = Random::Day->new(
	'dt_from' => DateTime->new(
		'day' => 1,
		'month' => 7,
		'year' => 2014,
	),
	'dt_to' => DateTime->new(
		'day' => 31,
		'month' => 7,
		'year' => 2014,
	),
);
$ret = $obj->random_day_year(7, 2014);
is($ret, '2014-07-07T00:00:00',
	'Get random date (07-??-2014 defined in 7 month by constructor).');

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_day_year(-10, 2014);
};
is($EVAL_ERROR, "Day isn't positive number.\n",
	"Test on negative number (-10-??-2014).");
clean();

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_day_year(0, 2014);
};
is($EVAL_ERROR, "Day cannot be a zero.\n",
	"Day cannot be a zero (00-??-2014).");
clean();

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_day_year('foo', 2014);
};
is($EVAL_ERROR, "Day isn't positive number.\n",
	"Test on string (foo).");
clean();

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_day_year(40, 2014);
};
is($EVAL_ERROR, "Day is greater than possible day.\n",
	'Day is greater than possible day (40).');
clean();

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_day_year(10, 1899);
};
is($EVAL_ERROR, "Year is lesser than minimal year.\n",
	'Year is lesser than minimal year (10-??-1899).');
clean();

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_day_year(10, 2100);
};
is($EVAL_ERROR, "Year is greater than maximal year.\n",
	'Year is greater than maximal year (10-??-2100).');
clean();

# Test.
$obj = Random::Day->new(
	'dt_from' => DateTime->new(
		'day' => 8,
		'month' => 7,
		'year' => 2014,
	),
	'dt_to' => DateTime->new(
		'day' => 31,
		'month' => 7,
		'year' => 2014,
	),
);
eval {
	$obj->random_day_year(7, 2014);
};
is($EVAL_ERROR, "Day not fit between start and end dates.\n",
	"Day not fit between start and end dates.");

# Test.
$obj = Random::Day->new(
	'dt_to' => DateTime->new(
		'day' => 7,
		'month' => 1,
		'year' => 2014,
	),
);
eval {
	$obj->random_day_year(8, 2014);
};
is($EVAL_ERROR, "Day is greater than maximal possible date.\n",
	"Day is greater than maximal possible date.");

# Test.
$obj = Random::Day->new(
	'dt_from' => DateTime->new(
		'day' => 25,
		'month' => 12,
		'year' => 2014,
	),
);
eval {
	$obj->random_day_year(8, 2014);
};
is($EVAL_ERROR, "Day is lesser than minimal possible date.\n",
	"Day is lesser than minimal possible date.");
