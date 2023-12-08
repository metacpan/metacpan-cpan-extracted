use strict;
use warnings;

use Person::ID::CZ::RC;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Person::ID::CZ::RC->new(
	'rc' => '840501/1330',
);
my $ret = $obj->rc;
is($ret, '840501/1330', "Normal RC number.");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '8425011331',
);
$ret = $obj->rc;
is($ret, '8425011331', "Alternate RC number.");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '840229|1330',
);
$ret = $obj->rc;
is($ret, '840229|1330', 'Unparsable RC number.');
