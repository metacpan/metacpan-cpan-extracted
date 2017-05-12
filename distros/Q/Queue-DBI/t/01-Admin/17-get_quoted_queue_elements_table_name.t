#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 4;

use lib 't/';
use LocalTest;

use Queue::DBI;
use Queue::DBI::Admin;


my $dbh = LocalTest::ok_database_handle();

can_ok(
	'Queue::DBI::Admin',
	'get_quoted_queue_elements_table_name',
);

subtest(
	'Test using the default queue elements table name.',
	sub
	{
		plan( tests => 2 );

		my $queue_admin;
		lives_ok(
			sub
			{
				$queue_admin = Queue::DBI::Admin->new(
					'database_handle'   => $dbh,
				);
			},
			'Instantiate a new Queue::DBI::Admin object with "get_queue_elements_table_name" not set.',
		);

		is(
			$queue_admin->get_quoted_queue_elements_table_name(),
			$dbh->quote_identifier( $Queue::DBI::DEFAULT_QUEUE_ELEMENTS_TABLE_NAME ),
			'The method get_quoted_queue_elements_table_name() returns the default queue elements table name (quoted).',
		);
	}
);

subtest(
	'Test setting a custom queues table name.',
	sub
	{
		plan( tests => 2 );

		my $queue_admin;
		lives_ok(
			sub
			{
				$queue_admin = Queue::DBI::Admin->new(
					'database_handle'           => $dbh,
					'queue_elements_table_name' => 'test_queue_elements',
				);
			},
			'Instantiate a new Queue::DBI::Admin object with "queue_elements_table_name" set.',
		);

		is(
			$queue_admin->get_quoted_queue_elements_table_name(),
			$dbh->quote_identifier( 'test_queue_elements' ),
			'The method get_quoted_queue_elements_table_name() returns the queue elements table name passed to new() (quoted).',
		);
	}
);
