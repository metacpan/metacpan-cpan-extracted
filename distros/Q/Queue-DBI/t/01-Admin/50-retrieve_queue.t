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
	'retrieve_queue',
);

subtest(
	'Test using default tables.',
	sub
	{
		test_retrieve_queue(
			new_args   => {},
			queue_name => 'test_queue',
		);
	}
);

subtest(
	'Test using custom tables.',
	sub
	{
		test_retrieve_queue(
			new_args   =>
			{
				'queues_table_name'         => 'test_queues',
				'queue_elements_table_name' => 'test_queue_elements',
			},
			queue_name => 'test_queue_custom',
		);
	}
);


sub test_retrieve_queue
{
	my ( %args ) = @_;
	my $new_args = delete( $args{'new_args'} ) || {};
	my $queue_name = delete( $args{'queue_name'} );

	die 'The queue name must be specified'
		if !defined( $queue_name ) || ( $queue_name eq '' );

	plan( tests => 4 );

	my $queue_admin;
	lives_ok(
		sub
		{
			$queue_admin = Queue::DBI::Admin->new(
				'database_handle' => $dbh,
				%$new_args,
			);
		},
		'Instantiate a new Queue::DBI::Admin object.',
	);

	my $queue;
	lives_ok(
		sub
		{
			$queue = $queue_admin->retrieve_queue(
				$queue_name,
			);
		},
		"Retrieve queue >$queue_name<.",
	);

	isa_ok(
		$queue,
		'Queue::DBI',
		'retrieve_queue() return value',
	);

	dies_ok(
		sub
		{
			$queue = $queue_admin->retrieve_queue(
				'invalid_queue',
			);
		},
		"Retrieving an invalid queue dies.",
	);
}
