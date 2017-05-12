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
	'delete_queue',
);

subtest(
	'Test using default tables.',
	sub
	{
		test_delete_queue(
			new_args   => {},
			queue_name => 'test_queue',
		);
	}
);

subtest(
	'Test using custom tables.',
	sub
	{
		test_delete_queue(
			new_args   =>
			{
				'queues_table_name'         => 'test_queues',
				'queue_elements_table_name' => 'test_queue_elements',
			},
			queue_name => 'test_queue_custom',
		);
	}
);


sub test_delete_queue
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

	lives_ok(
		sub
		{
			$queue_admin->delete_queue(
				$queue_name,
			);
		},
		"Delete queue >$queue_name<.",
	);

	ok(
		defined(
			my $queues_table_name = $queue_admin->get_queues_table_name()
		),
		'Retrieve the name of the queues table.',
	);

	dies_ok(
		sub
		{
			my $queue = $queue_admin->retrieve_queue(
				$queue_name,
			);
		},
		"Retrieve queue >$queue_name< fails because the queue doesn't exist anymore.",
	);
}
