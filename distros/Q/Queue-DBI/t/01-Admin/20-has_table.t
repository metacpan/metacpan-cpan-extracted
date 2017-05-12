#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 12;

use lib 't/';
use LocalTest;

use Queue::DBI;
use Queue::DBI::Admin;


my $dbh = LocalTest::ok_database_handle();

can_ok(
	'Queue::DBI::Admin',
	'has_table',
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

dies_ok(
	sub
	{
		$queue_admin->has_table();
	},
	'The table type must be specified',
);

ok(
	!$queue_admin->has_table( 'queues' ),
	'The queues table does not exist.',
);

ok(
	!$queue_admin->has_table( 'queue_elements' ),
	'The queue elements table does not exist.',
);

subtest(
	'Create test queues table.',
	sub
	{
		plan( tests => 2 );

		my $create_table_sql =
		{
			SQLite =>
			q|
				CREATE TABLE IF NOT EXISTS test_has_table_queues
				(
					queue_id INTEGER PRIMARY KEY AUTOINCREMENT
				)
			|,
			Pg     =>
			q|
				CREATE TABLE IF NOT EXISTS test_has_table_queues
				(
					queue_id SERIAL,
					PRIMARY KEY (queue_id)
				)
			|,
			mysql  =>
			q|
				CREATE TABLE IF NOT EXISTS test_has_table_queues
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
			'Create table.',
		);
	}
);

ok(
	$queue_admin->has_table( 'queues' ),
	'The queues table exists.',
);

ok(
	!$queue_admin->has_table( 'queue_elements' ),
	'The queue elements table does not exist.',
);

subtest(
	'Create test queue elements table.',
	sub
	{
		plan( tests => 2 );

		my $create_table_sql =
		{
			SQLite =>
			q|
				CREATE TABLE IF NOT EXISTS test_has_table_queue_elements
				(
					queue_id INTEGER PRIMARY KEY AUTOINCREMENT
				)
			|,
			Pg     =>
			q|
				CREATE TABLE IF NOT EXISTS test_has_table_queue_elements
				(
					queue_id SERIAL,
					PRIMARY KEY (queue_id)
				)
			|,
			mysql  =>
			q|
				CREATE TABLE IF NOT EXISTS test_has_table_queue_elements
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
			'Create table.',
		);
	}
);

ok(
	$queue_admin->has_table( 'queues' ),
	'The queues table exists.',
);

ok(
	$queue_admin->has_table( 'queue_elements' ),
	'The queue elements table exists.',
);
