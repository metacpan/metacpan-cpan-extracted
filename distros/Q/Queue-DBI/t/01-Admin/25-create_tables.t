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
	'create_tables',
);

subtest(
	'Create default tables.',
	sub
	{
		plan( tests => 2 );

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

		lives_ok(
			sub
			{
				$queue_admin->create_tables();
			},
			'Create the default tables.',
		);
	}
);

subtest(
	'Create custom tables.',
	sub
	{
		plan( tests => 2 );

		my $queue_admin;
		lives_ok(
			sub
			{
				$queue_admin = Queue::DBI::Admin->new(
					'database_handle'           => $dbh,
					'queues_table_name'         => 'test_queues',
					'queue_elements_table_name' => 'test_queue_elements',
				);
			},
			'Instantiate a new Queue::DBI::Admin object.',
		);

		lives_ok(
			sub
			{
				$queue_admin->create_tables();
			},
			'Create the custom tables.',
		);
	}
);
