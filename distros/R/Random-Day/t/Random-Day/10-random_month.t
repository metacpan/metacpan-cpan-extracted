use strict;
use warnings;

use DateTime;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Random::Day;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Random::Day->new;
my $ret = $obj->random_month(10);
isa_ok($ret, 'DateTime');
like($ret, qr{^\d\d\d\d-10-\d\dT00:00:00$},
	'Random date for concrete month.');

# Test.
$obj = Random::Day->new(
	'dt_from' => DateTime->new(
		'day' => 1,
		'month' => 1,
		'year' => 2023,
	),
	'dt_to' => DateTime->new(
		'day' => 1,
		'month' => 6,
		'year' => 2024,
	),
);
$ret = $obj->random_month(10);
isa_ok($ret, 'DateTime');
like($ret, qr{^2023-10-\d\dT00:00:00$},
	'Random date for concrete month (in 2023 defined by dt_from and dt_to).');

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_month(40);
};
is($EVAL_ERROR, "Cannot create DateTime object.\n",
	'Cannot create DateTime object.');
clean();
