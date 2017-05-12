#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 5;

use lib 't/';
use LocalTest;

use Queue::DBI;
use Queue::DBI::Admin;


my $dbh = LocalTest::ok_database_handle();

can_ok(
	'Queue::DBI::Admin',
	'has_mandatory_fields',
);

my $queue_admin;
lives_ok(
	sub
	{
		$queue_admin = Queue::DBI::Admin->new(
			'database_handle'           => $dbh,
			'queues_table_name'         => 'test_has_table_queues',
			'queue_elements_table_name' => 'test_has_table_queue_elements',
		);
	},
	'Instantiate a new Queue::DBI::Admin object.',
);

subtest(
	'Verify queues table.',
	sub
	{
		plan( tests => 2 );

		ok(
			$queue_admin->has_table( 'queues' ),
			'The queues table exists.',
		);

		ok(
			!$queue_admin->has_mandatory_fields( 'queues' ),
			'The queues table is missing mandatory fields.',
		);
	}
);

subtest(
	'Verify queue elements table.',
	sub
	{
		plan( tests => 2 );

		ok(
			$queue_admin->has_table( 'queue_elements' ),
			'The queue elements table exists.',
		);

		ok(
			!$queue_admin->has_mandatory_fields( 'queue_elements' ),
			'The queue elements table is missing mandatory fields.',
		);
	}
);

note( 'Note: the correct detection of mandatory fields is tested by has_tables() after create_tables().' );
