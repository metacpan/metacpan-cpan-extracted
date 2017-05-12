#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 10;

use lib 't/';
use LocalTest;

use Queue::DBI;


my $dbh = LocalTest::ok_database_handle();

can_ok(
	'Queue::DBI',
	'lifetime',
);

my $queue;
subtest(
	'Test no lifetime set.',
	sub
	{
		plan( tests => 4 );

		lives_ok(
			sub
			{
				$queue = Queue::DBI->new(
					'queue_name'      => 'test1',
					'database_handle' => $dbh,
					'cleanup_timeout' => 3600,
					'verbose'         => 0,
				);
			},
			'Instantiate a new Queue::DBI object without a lifetime.',
		);

		is(
			$queue->get_lifetime(),
			undef,
			'get_lifetime() returns undef.',
		);

		lives_ok(
			sub
			{
				$queue->set_lifetime( 5 );
			},
			'Change the lifetime to 5 seconds.',
		);

		is(
			$queue->get_lifetime(),
			5,
			'get_lifetime() returns the new lifetime value.',
		);
	}
);
subtest(
	'Test setting the lifetime value.',
	sub
	{
		plan( tests => 4 );

		lives_ok(
			sub
			{
				$queue = Queue::DBI->new(
					'queue_name'      => 'test1',
					'database_handle' => $dbh,
					'cleanup_timeout' => 3600,
					'verbose'         => 0,
					'lifetime'        => 10,
				);
			},
			'Instantiate a new Queue::DBI object with lifetime=10s.',
		);

		is(
			$queue->get_lifetime(),
			10,
			'get_lifetime() returns the correct lifetime value.',
		);

		lives_ok(
			sub
			{
				$queue->set_lifetime( 5 );
			},
			'Change the lifetime to 5 seconds.',
		);

		is(
			$queue->get_lifetime(),
			5,
			'get_lifetime() returns the new lifetime value.',
		);
	}
);

# Insert data.
my $inserted_queue_id;
lives_ok(
	sub
	{
		$inserted_queue_id = $queue->enqueue(
			{
				block1 => 141592653,
				block2 => 589793238,
				block3 => 462643383,
			}
		);
	},
	'Queue data.',
);

lives_ok(
	sub
	{
		$dbh->do(
			q|
				UPDATE queue_elements
				SET created = created - 10
				WHERE queue_element_id = ?
			|,
			{},
			$inserted_queue_id,
		);
	},
	'Set created timestamp on the element 10 seconds back in time.',
);

subtest(
	'Test retrieving with lifetime=2s.',
	sub
	{
		plan( tests => 2 );

		my $subtest_queue;
		lives_ok(
			sub
			{
				$subtest_queue = Queue::DBI->new(
					'queue_name'      => 'test1',
					'database_handle' => $dbh,
					'cleanup_timeout' => 3600,
					'verbose'         => 0,
					'lifetime'        => 2,
				);
			},
			'Instantiate a new Queue::DBI object with lifetime=2s.',
		);

		# Retrieve data.
		ok(
			!defined(
				my $queue_element = $subtest_queue->next()
			),
			'next() returns no element.',
		);
	}
);

subtest(
	'Test retrieving with lifetime=60s.',
	sub
	{
		plan( tests => 3 );

		my $subtest_queue;
		lives_ok(
			sub
			{
				$subtest_queue = Queue::DBI->new(
					'queue_name'      => 'test1',
					'database_handle' => $dbh,
					'cleanup_timeout' => 3600,
					'verbose'         => 0,
					'lifetime'        => 60,
				);
			},
			'Instantiate a new Queue::DBI object with lifetime=5s.',
		);

		# Retrieve data.
		ok(
			defined(
				my $queue_element = $subtest_queue->next()
			),
			'Retrieve the next item in the queue.',
		);

		is(
			$inserted_queue_id,
			defined( $queue_element )
				? $queue_element->id()
				: undef,
			'The ID of the retrieved queue element matches the inserted ID.'
		);
	}
);

subtest(
	'Test retrieving with lifetime not set.',
	sub
	{
		plan( tests => 3 );

		my $subtest_queue;
		lives_ok(
			sub
			{
				$subtest_queue = Queue::DBI->new(
					'queue_name'      => 'test1',
					'database_handle' => $dbh,
					'cleanup_timeout' => 3600,
					'verbose'         => 0,
				);
			},
			'Instantiate a new Queue::DBI object with lifetime=5s.',
		);

		# Retrieve data.
		ok(
			defined(
				my $queue_element = $subtest_queue->next()
			),
			'Retrieve the next item in the queue.',
		);

		is(
			defined( $queue_element )
				? $queue_element->id()
				: undef,
			$inserted_queue_id,
			'The ID of the retrieved queue element matches the inserted ID.'
		);
	}
);

# Clean up queue.
subtest(
	'Clean up queue.',
	sub
	{
		plan( tests => 2 );
		my $cleanup_queue;
		lives_ok(
			sub
			{
				$cleanup_queue = Queue::DBI->new(
					'queue_name'      => 'test1',
					'database_handle' => $dbh,
					'cleanup_timeout' => 3600,
					'verbose'         => 0,
				);
			},
			'Instantiate a new Queue::DBI object.',
		);

		my $removed_elements = 0;
		lives_ok(
			sub
			{
				while ( my $queue_element = $cleanup_queue->next() )
				{
					$queue_element->lock() || die 'Could not lock the queue element';
					$queue_element->success() || die 'Could not mark as processed the queue element';
					$removed_elements++;
				}
			},
			'Remove queue elements.',
		);
		note( "Removed >$removed_elements< element(s)." );
	}
);
