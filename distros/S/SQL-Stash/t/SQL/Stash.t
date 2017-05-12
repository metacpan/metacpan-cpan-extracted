#!/usr/bin/perl
use strict;
use warnings;

use Test::Exception;
use Test::MockModule;
use Test::More 'tests' => 2;

BEGIN {
	use_ok('SQL::Stash') or BAIL_OUT('Unable to use SQL::Stash');
};

subtest "Given the SQL::Stash class" => sub {
	plan tests => 2;
	my $mock_dbi = Test::MockModule->new('DBI');
	$mock_dbi->mock('connect', sub {return bless({}, shift)});
	throws_ok(sub {SQL::Stash->new()}, qr/DBI handle missing/,
		"when the class is instantiated and a DBI handle is not provided ".
		"then an exception should be thrown");
	lives_ok(sub {SQL::Stash->new('dbh' => DBI->connect())},
		"when the class is instantiated and a DBI handle is provided ".
		"then an an instance should be created");
};

