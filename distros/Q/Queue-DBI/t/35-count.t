#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 9;

use lib 't/';
use LocalTest;

use Queue::DBI;


my $dbh = LocalTest::ok_database_handle();

# Instantiate the queue object.
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

# Count elements in the queue.
subtest(
	'Count elements in the queue.',
	sub
	{
		plan( tests => 3 );

		is(
			$queue->count(),
			1,
			'count() without parameters.',
		);
		is(
			$queue->count(
				exclude_locked_elements => 0,
			),
			1,
			'count( exclude_locked_elements => 0 ).',
		);
		is(
			$queue->count(
				exclude_locked_elements => 1,
			),
			1,
			'count( exclude_locked_elements => 1 ).',
		);
	}
);

# Retrieve data.
my $queue_element;
lives_ok(
	sub
	{
		$queue_element = $queue->next();
	},
	'Call to retrieve the next item in the queue.',
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

# Count elements in the queue.
subtest(
	'Count elements in the queue.',
	sub
	{
		plan( tests => 3 );

		is(
			$queue->count(),
			1,
			'count() without parameters.',
		);
		is(
			$queue->count(
				exclude_locked_elements => 0,
			),
			1,
			'count( exclude_locked_elements => 0 ).',
		);
		is(
			$queue->count(
				exclude_locked_elements => 1,
			),
			0,
			'count( exclude_locked_elements => 1 ).',
		);
	}
);

# Remove.
lives_ok(
	sub
	{
		$queue_element->success()
		||
		die 'Cannot mark as successfully processed';
	},
	'Mark as successfully processed.',
);

# Count elements in the queue.
subtest(
	'Count elements in the queue.',
	sub
	{
		plan( tests => 3 );

		is(
			$queue->count(),
			0,
			'count() without parameters.',
		);
		is(
			$queue->count(
				exclude_locked_elements => 0,
			),
			0,
			'count( exclude_locked_elements => 0 ).',
		);
		is(
			$queue->count(
				exclude_locked_elements => 1,
			),
			0,
			'count( exclude_locked_elements => 1 ).',
		);
	}
);

