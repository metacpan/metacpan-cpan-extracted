#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 8;

use lib 't/';
use LocalTest;

use Queue::DBI;


my $dbh = LocalTest::ok_database_handle();

dies_ok(
	sub
	{
		# Disable printing errors out since we expect the test to fail.
		local $dbh->{'PrintError'} = 0;

		$dbh->selectrow_array( q| SELECT * FROM queues | );
	},
	'The queues table does not exist yet.',
);

dies_ok(
	sub
	{
		# Disable printing errors out since we expect the test to fail.
		local $dbh->{'PrintError'} = 0;

		$dbh->selectrow_array( q| SELECT * FROM queue_elements | );
	},
	'The queue elements table does not exist yet.',
);

use_ok( 'Queue::DBI::Admin' );

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
		$queue_admin->create_tables(
			drop_if_exist => 1,
		);
	},
	'Create tables.',
);

lives_ok(
	sub
	{
		$dbh->selectrow_array( q| SELECT * FROM queues | );
	},
	'The queues table exists.',
);

lives_ok(
	sub
	{
		$dbh->selectrow_array( q| SELECT * FROM queue_elements | );
	},
	'The queue elements table exists.',
);

