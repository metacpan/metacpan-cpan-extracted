# Pragmas.
use strict;
use warnings;

# Modules.
use Person::ID::CZ::RC;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Person::ID::CZ::RC->new(
	'rc' => '840501/1330',
);
my $ret = $obj->checksum;
is($ret, 0, "RC checksum in normal number.");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '8425011331',
);
$ret = $obj->checksum;
is($ret, 1, "RC checksum in alternate number.");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '840229|1330',
);
$ret = $obj->checksum;
is($ret, '-', 'Cannot parse number.');
