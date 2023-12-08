use strict;
use warnings;

use Person::ID::CZ::RC;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Person::ID::CZ::RC->new(
	'rc' => '845501/1334',
);
my $ret = $obj->sex;
is($ret, 'female', "RC sex in normal number (female).");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '8455011334',
);
$ret = $obj->sex;
is($ret, 'female', "RC sex in alternate number (female).");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '840501/1330',
);
$ret = $obj->sex;
is($ret, 'male', "RC sex in normal number (male).");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '8425011331',
);
$ret = $obj->sex;
is($ret, 'male', "RC sex in alternate number (male).");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '840229|1330',
);
$ret = $obj->sex;
is($ret, '-', 'Cannot parse number.');
