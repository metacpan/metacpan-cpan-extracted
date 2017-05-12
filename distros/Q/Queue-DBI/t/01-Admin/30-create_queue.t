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
	'create_queue',
);

subtest(
	'Create queue using default tables.',
	sub
	{
		test_create_queue(
			new_args   => {},
			queue_name => 'test_queue',
		);
	}
);

subtest(
	'Create queue using custom tables.',
	sub
	{
		test_create_queue(
			new_args   =>
			{
				'queues_table_name'         => 'test_queues',
				'queue_elements_table_name' => 'test_queue_elements',
			},
			queue_name => 'test_queue_custom',
		);
	}
);


sub test_create_queue
{
	my ( %args ) = @_;
	my $new_args = delete( $args{'new_args'} ) || {};
	my $queue_name = delete( $args{'queue_name'} );

	die 'The queue name must be specified'
		if !defined( $queue_name ) || ( $queue_name eq '' );

	plan( tests => 2 );

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
			$queue_admin->create_queue(
				$queue_name,
			);
		},
		'Create a test queue.',
	);
}
