#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 14;

use lib 't/';
use LocalTest;

use Queue::DBI;


my $dbh = LocalTest::ok_database_handle();

# Note: the queue object is designed to never backtrack, so we need to re-create
# the queue object everytime to be able to pick the element we just requeued.

# First part, insert the element.
{
	# Instantiate the queue object.
	my $queue;
	lives_ok(
		sub
		{
			$queue = Queue::DBI->new(
				'queue_name'        => 'test1',
				'database_handle'   => $dbh,
				'cleanup_timeout'   => 3600,
				'verbose'           => 0,
				'max_requeue_count' => 5,
			);
		},
		'Create the queue object.',
	);

	# Clean up queue if needed.
	my $removed_elements = 0;
	lives_ok(
		sub
		{
			while ( my $queue_element = $queue->next() )
			{
				$queue_element->lock() || die 'Could not lock the queue element';
				$queue_element->success() || die 'Could not mark as processed the queue element';
				$removed_elements++;
			}
		},
		'Queue is empty.',
	);
	note( "Removed >$removed_elements< elements." )
		if $removed_elements != 0;

	# Insert data.
	my $data =
	{
		block1 => 141592653,
		block2 => 589793238,
		block3 => 462643383,
	};
	lives_ok(
		sub
		{
			$queue->enqueue( $data );
		},
		'Queue data.',
	);
}

# Second part: retrieve, lock and requeue the element. The element should not be
# retrievable the seventh time, as it will have been requeued six times.
#
# Note: we needto re-instantiate the queue each time as the dequeueing algorithm
# prevents loops and we wouldn't be able to retrieve the element again.
foreach my $try ( 1..6 )
{
	subtest(
		"Round $try.",
		sub
		{
			plan( tests => 6 );

			# Instantiate the queue object.
			my $queue;
			lives_ok(
				sub
				{
					$queue = Queue::DBI->new(
						'queue_name'        => 'test1',
						'database_handle'   => $dbh,
						'cleanup_timeout'   => 3600,
						'verbose'           => 0,
						'max_requeue_count' => 5,
					);
				},
				'Create the queue object.',
			);

			# Retrieve element.
			my $queue_element;
			lives_ok(
				sub
				{
					$queue_element = $queue->next();
				},
				'Retrieve the next element in the queue.',
			);
			isa_ok(
				$queue_element,
				'Queue::DBI::Element',
				'Object returned by next()',
			);

			# Verify the number of times the element was requeued.
			my $expected_requeue_count = $try - 1;
			is(
				$queue_element->requeue_count(),
				$expected_requeue_count,
				'The element was requeued $expected_requeue_count time(s).',
			);

			# Lock.
			lives_ok(
				sub
				{
					$queue_element->lock()
					||
					die 'Cannot lock element';
				},
				'Lock element.',
			);

			# Requeue.
			lives_ok(
				sub
				{
					$queue_element->requeue()
					||
					die 'Cannot requeue element';
				},
				'Requeue element.',
			);
		}
	);
}

# Now, the seventh time we try to retrieve the element, it should not be returned.
{
	# Instantiate the queue object.
	my $queue;
	lives_ok(
		sub
		{
			$queue = Queue::DBI->new(
				'queue_name'        => 'test1',
				'database_handle'   => $dbh,
				'cleanup_timeout'   => 3600,
				'verbose'           => 0,
				'max_requeue_count' => 5,
			);
		},
		'Create the queue object.',
	);

	# Retrieve element.
	my $queue_element;
	lives_ok(
		sub
		{
			$queue_element = $queue->next();
		},
		'Retrieve the next element in the queue.',
	);
	ok(
		!defined( $queue_element ),
		'No element returned.',
	) || diag( "Queue element returned:\n" . explain( $queue_element ) );
}

# Clean up queue.
subtest(
	'Empty the queue.',
	sub
	{
		plan( tests => 2 );

		my $queue;
		lives_ok(
			sub
			{
				$queue = Queue::DBI->new(
					'queue_name'        => 'test1',
					'database_handle'   => $dbh,
					'cleanup_timeout'   => 3600,
					'verbose'           => 0,
				);
			},
			'Create the queue object.',
		);

		my $removed_elements = 0;
		lives_ok(
			sub
			{
				while ( my $queue_element = $queue->next() )
				{
					$queue_element->lock() || die 'Could not lock the queue element';
					$queue_element->success() || die 'Could not mark as processed the queue element';
					$removed_elements++;
				}
			},
			'Remove queue elements.',
		);
		note( "Removed >$removed_elements< elements." )
			if $removed_elements != 0;
	}
);

