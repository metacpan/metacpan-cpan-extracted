use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Random::Day;
use Test::More 'tests' => 14;
use Test::NoWarnings;

# Test.
my $obj = Random::Day->new;
my $ret = $obj->random;
like($ret, qr{^\d\d\d\d-\d\d-\d\dT00:00:00$}, 'Random on default object.');

# Test.
## dt_from and dt_to are in the same day, dt_from is midnight.
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
$ret = $obj->random;
is($ret->day, 7, 'Get day (7).');
is($ret->month, 7, 'Get month (7).');
is($ret->year, 2025, 'Get year (2025).');
is($ret->hour, 0, 'Get hour (0).');
is($ret->minute, 0, 'Get minute (0).');
is($ret->second, 0, 'Get second (0).');

# Test.
## dt_from is a day before dt_to.
$obj = Random::Day->new(
	'dt_from' => DateTime->new(
		'day' => 6,
		'month' => 7,
		'year' => 2025,
		'hour' => 13,
		'minute' => 30,
	),
	'dt_to' => DateTime->new(
		'day' => 7,
		'month' => 7,
		'year' => 2025,
		'hour' => 9,
		'minute' => 10,
	),
);
$ret = $obj->random;
is($ret->day, 7, 'Get day (7).');
is($ret->month, 7, 'Get month (7).');
is($ret->year, 2025, 'Get year (2025).');
is($ret->hour, 0, 'Get hour (0).');
is($ret->minute, 0, 'Get minute (0).');
is($ret->second, 0, 'Get second (0).');
