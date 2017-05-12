#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 5;

use lib 't/';
use LocalTest;

use Queue::DBI::Admin;


my $dbh = LocalTest::ok_database_handle();

subtest(
	'Check missing queues table.',
	sub
	{
		plan( tests => 3 );

		my $queue_admin;
		lives_ok(
			sub
			{
				$queue_admin = Queue::DBI::Admin->new(
					'database_handle'           => $dbh,
					'queues_table_name'         => 'invalid_table_name',
					'queue_elements_table_name' => 'test_queue_elements',
				);
			},
			'Instantiate a new Queue::DBI::Admin object.',
		);

		dies_ok(
			sub
			{
				$queue_admin->has_tables();
			},
			'Call has_tables().',
		);

		like(
			$@,
			qr/The table 'test_queue_elements' exists, but 'invalid_table_name' is missing/,
			'The queues table is missing.',
		);
	}
);

subtest(
	'Check missing queue elements table.',
	sub
	{
		plan( tests => 3 );

		my $queue_admin;
		lives_ok(
			sub
			{
				$queue_admin = Queue::DBI::Admin->new(
					'database_handle'           => $dbh,
					'queues_table_name'         => 'test_queues',
					'queue_elements_table_name' => 'invalid_table_name',
				);
			},
			'Instantiate a new Queue::DBI::Admin object.',
		);

		dies_ok(
			sub
			{
				$queue_admin->has_tables();
			},
			'Call has_tables().',
		);

		like(
			$@,
			qr/The table 'test_queues' exists, but 'invalid_table_name' is missing/,
			'The queue elements table is missing.',
		);
	}
);

subtest(
	'Check queues table with incorrect fields.',
	sub
	{
		plan( tests => 5 );

		my $create_table_sql =
		{
			SQLite =>
			q|
				CREATE TABLE IF NOT EXISTS queues_incorrect_fields
				(
					queue_id INTEGER PRIMARY KEY AUTOINCREMENT
				)
			|,
			Pg     =>
			q|
				CREATE TABLE IF NOT EXISTS queues_incorrect_fields
				(
					queue_id SERIAL,
					PRIMARY KEY (queue_id)
				)
			|,
			mysql  =>
			q|
				CREATE TABLE IF NOT EXISTS queues_incorrect_fields
				(
					queue_id INT(11) NOT NULL AUTO_INCREMENT,
					PRIMARY KEY (queue_id)
				)
				ENGINE=InnoDB
			|,
		};

		my $database_type = $dbh->{'Driver'}->{'Name'} || '';
		ok(
			defined(
				$create_table_sql->{ $database_type }
			),
			'The SQL for this database type is present.',
		);

		lives_ok(
			sub
			{
				$dbh->do(
					$create_table_sql->{ $database_type }
				);
			},
			'Create a queues table with incorrect fields.',
		);

		my $queue_admin;
		lives_ok(
			sub
			{
				$queue_admin = Queue::DBI::Admin->new(
					'database_handle'           => $dbh,
					'queues_table_name'         => 'queues_incorrect_fields',
					'queue_elements_table_name' => 'test_queue_elements',
				);
			},
			'Instantiate a new Queue::DBI::Admin object.',
		);

		dies_ok(
			sub
			{
				$queue_admin->has_tables();
			},
			'Call has_tables().',
		);

		like(
			$@,
			qr/The table 'queues_incorrect_fields' exists, but is missing mandatory fields/,
			'The queues table exists but is missing mandatory fields.',
		);
	}
);

subtest(
	'Check queue elements table with incorrect fields.',
	sub
	{
		plan( tests => 5 );

		my $create_table_sql =
		{
			SQLite =>
			q|
				CREATE TABLE IF NOT EXISTS queue_elements_incorrect_fields
				(
					queue_element_id INTEGER PRIMARY KEY AUTOINCREMENT,
					data TEXT,
					lock_time INT(10) DEFAULT NULL,
					requeue_count INT(3) DEFAULT '0',
					created INT(10) NOT NULL DEFAULT '0'
				)
			|,
			Pg     =>
			q|
				CREATE TABLE IF NOT EXISTS queue_elements_incorrect_fields
				(
					queue_element_id SERIAL,
					data TEXT,
					lock_time INTEGER DEFAULT NULL,
					requeue_count SMALLINT DEFAULT 0,
					created INTEGER NOT NULL DEFAULT 0,
					PRIMARY KEY (queue_element_id)
				)
			|,
			mysql  =>
			q|
				CREATE TABLE IF NOT EXISTS queue_elements_incorrect_fields
				(
					queue_element_id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
					data TEXT,
					lock_time INT(10) UNSIGNED DEFAULT NULL,
					requeue_count INT(3) UNSIGNED DEFAULT '0',
					created INT(10) UNSIGNED NOT NULL DEFAULT '0',
					PRIMARY KEY (queue_element_id)
				)
				ENGINE=InnoDB
			|,
		};

		my $database_type = $dbh->{'Driver'}->{'Name'} || '';
		ok(
			defined(
				$create_table_sql->{ $database_type }
			),
			'The SQL for this database type is present.',
		);

		lives_ok(
			sub
			{
				$dbh->do(
					$create_table_sql->{ $database_type }
				);
			},
			'Create a queue elements table with incorrect fields.',
		);

		my $queue_admin;
		lives_ok(
			sub
			{
				$queue_admin = Queue::DBI::Admin->new(
					'database_handle'           => $dbh,
					'queues_table_name'         => 'test_queues',
					'queue_elements_table_name' => 'queue_elements_incorrect_fields',
				);
			},
			'Instantiate a new Queue::DBI::Admin object.',
		);

		dies_ok(
			sub
			{
				$queue_admin->has_tables();
			},
			'Call has_tables().',
		);

		like(
			$@,
			qr/The table 'queue_elements_incorrect_fields' exists, but is missing mandatory fields/,
			'The queue elements table exists but is missing mandatory fields.',
		);
	}
);
