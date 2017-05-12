#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 7;

use lib 't/';
use LocalTest;

use Queue::DBI;


my $dbh = LocalTest::ok_database_handle();

can_ok(
	'Queue::DBI',
	'purge',
);

my $queue;
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
	'Instantiate a new Queue::DBI object.',
);

dies_ok(
	sub
	{
		$queue->purge();
	},
	'purge() must be called with at least one valid parameter.',
);

dies_ok(
	sub
	{
		$queue->purge(
			lifetime          => 10,
			max_requeue_count => 5,
		);
	},
	'purge() cannot be called with both "lifetime" and "max_requeue_count" parameters.',
);

subtest(
	'Test purge() with "lifetime" argument.',
	sub
	{
		plan( tests => 7 );

		# Make sure we start with an empty queue.
		is(
			$queue->count(),
			0,
			'The queue is empty.',
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

		my $elements_purged;
		lives_ok(
			sub
			{
				$elements_purged = $queue->purge(
					lifetime => 60,
				);
			},
			'Purge elements older than 60 seconds.',
		);
		is(
			$elements_purged,
			0,
			'Purged 0 elements.',
		);

		lives_ok(
			sub
			{
				$elements_purged = $queue->purge(
					lifetime => 5,
				);
			},
			'Purge elements older than 5 seconds.',
		);
		is(
			$elements_purged,
			1,
			'Purged 1 element.',
		);
	}
);

subtest(
	'Test purge() with "max_requeue_count" argument.',
	sub
	{
		plan( tests => 9 );

		# Make sure we start with an empty queue.
		is(
			$queue->count(),
			0,
			'The queue is empty.',
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
						SET requeue_count = 10
						WHERE queue_element_id = ?
					|,
					{},
					$inserted_queue_id,
				);
			},
			'Set max_requeue_count on the element to 10.',
		);

		my $elements_purged;
		lives_ok(
			sub
			{
				$elements_purged = $queue->purge(
					max_requeue_count => 20,
				);
			},
			'Purge elements requeued more than 20 times.',
		);
		is(
			$elements_purged,
			0,
			'Purged 0 elements.',
		);

		lives_ok(
			sub
			{
				$elements_purged = $queue->purge(
					max_requeue_count => 10,
				);
			},
			'Purge elements requeued more than 10 times.',
		);
		is(
			$elements_purged,
			0,
			'Purged 0 elements.',
		);

		lives_ok(
			sub
			{
				$elements_purged = $queue->purge(
					max_requeue_count => 9,
				);
			},
			'Purge elements requeued more than 9 times.',
		);
		is(
			$elements_purged,
			1,
			'Purged 1 element.',
		);
	}
);
