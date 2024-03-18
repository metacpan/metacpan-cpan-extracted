use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Random::Day;
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $obj = Random::Day->new;
my $ret = $obj->get;
like($ret, qr{^\d\d\d\d-\d\d-\d\dT00:00:00$}, 'Get random date (default object).');

# Test.
$obj = Random::Day->new(
	'day' => 7,
);
$ret = $obj->get;
like($ret, qr{^\d\d\d\d-\d\d-07T00:00:00$}, 'Get random date (defined day).');

# Test.
$obj = Random::Day->new(
	'month' => 7,
);
$ret = $obj->get;
like($ret, qr{^\d\d\d\d-07-\d\dT00:00:00$}, 'Get random date (defined month).');

# Test.
$obj = Random::Day->new(
	'year' => 1977,
);
$ret = $obj->get;
like($ret, qr{^1977-\d\d-\d\dT00:00:00$}, 'Get random date (defined year).');

# Test.
$obj = Random::Day->new(
	'day' => 7,
	'month' => 7,
);
$ret = $obj->get;
like($ret, qr{^\d\d\d\d-07-07T00:00:00$}, 'Get random date (defined day and month).');

# Test.
$obj = Random::Day->new(
	'day' => 7,
	'year' => 1977,
);
$ret = $obj->get;
like($ret, qr{^1977-\d\d-07T00:00:00$}, 'Get random date (defined day and year).');

# Test.
$obj = Random::Day->new(
	'month' => 7,
	'year' => 1977,
);
$ret = $obj->get;
like($ret, qr{^1977-07-\d\dT00:00:00$}, 'Get random date (defined month and year).');

# Test.
$obj = Random::Day->new(
	'day' => 7,
	'month' => 7,
	'year' => 1977
);
$ret = $obj->get;
like($ret, qr{^1977-07-07T00:00:00$}, 'Get random date (defined day, month and year).');
