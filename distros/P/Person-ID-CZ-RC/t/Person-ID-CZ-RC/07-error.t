# Pragmas.
use strict;
use warnings;

# Modules.
use Person::ID::CZ::RC;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Person::ID::CZ::RC->new(
	'rc' => '840501/1330',
);
my $ret = $obj->error;
is($ret, undef, "No error in right parsing.");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '840229|1330',
);
$ret = $obj->error;
is($ret, "Format of rc identification isn't valid.",
	"Format of rc identification isn't valid.");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '8502291330',
);
$ret = $obj->error;
is($ret, "Checksum isn't valid.", "Checksum isn't valid.");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '8502291336',
);
$ret = $obj->error;
is($ret, "Date isn't valid.", "Date isn't valid.");

# Test.
$obj = Person::ID::CZ::RC->new(
	'rc' => '850229133',
);
$ret = $obj->error;
is($ret, "Format of rc identification hasn't checksum.",
	"Format of rc identification hasn't checksum.");
