#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 9;

use lib 't/';
use LocalTest;

use Queue::DBI::Admin;


my $dbh = LocalTest::ok_database_handle();

can_ok(
	'Queue::DBI::Admin',
	'new',
);

dies_ok(
	sub
	{
		Queue::DBI::Admin->new();
	},
	'The argument "database_handle" is required.',
);

dies_ok(
	sub
	{
		Queue::DBI::Admin->new(
			database_handle => {},
		);
	},
	'The argument "database_handle" must be a DBI::db object.',
);

dies_ok(
	sub
	{
		Queue::DBI::Admin->new(
			invalid_test_argument => 1,
		);
	},
	'Unknown arguments are correctly detected when calling new().',
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
isa_ok(
	$queue_admin,
	'Queue::DBI::Admin',
	'Object returned by new()',
);

lives_ok(
	sub
	{
		Queue::DBI::Admin->new(
			'database_handle'   => $dbh,
			'queues_table_name' => 'test_queues',
		);
	},
	'"queues_table_name" is a valid optional argument.',
);

lives_ok(
	sub
	{
		Queue::DBI::Admin->new(
			'database_handle'           => $dbh,
			'queue_elements_table_name' => 'test_queue_elements',
		);
	},
	'"queue_elements_table_name" is a valid optional argument.',
);
