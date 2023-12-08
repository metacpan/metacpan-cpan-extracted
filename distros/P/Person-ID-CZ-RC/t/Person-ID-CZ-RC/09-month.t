use strict;
use warnings;

use Person::ID::CZ::RC;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Person::ID::CZ::RC->new(
	'rc' => '840501/1330',
);
my $ret = $obj->month;
is($ret, 5, "RC month in normal number.");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '8425011331',
);
$ret = $obj->month;
is($ret, 5, "RC month in alternate number.");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '840229|1330',
);
$ret = $obj->month;
is($ret, '-', 'Cannot parse number.');
