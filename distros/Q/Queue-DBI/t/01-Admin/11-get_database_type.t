#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 4;

use lib 't/';
use LocalTest;

use Queue::DBI::Admin;


my $dbh = LocalTest::ok_database_handle();

can_ok(
	'Queue::DBI::Admin',
	'get_database_type',
);

my $queue_admin;
lives_ok(
	sub
	{
		$queue_admin = Queue::DBI::Admin->new(
			'database_handle' => $dbh,
		);
	},
	'Instantiate a new Queue::DBI::Admin object.',
);

like(
	$queue_admin->get_database_type(),
	qr/^(?:SQLite|MySQL|Pg)$/i,
	'The database type is correctly determined.',
);

