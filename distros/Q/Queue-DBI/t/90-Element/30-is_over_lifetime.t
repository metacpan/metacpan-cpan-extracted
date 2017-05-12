#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 10;

use lib 't/';
use LocalTest;

use Queue::DBI;
use Test::Type;


my $dbh = LocalTest::ok_database_handle();

my $queue;
lives_ok(
	sub
	{
		$queue = Queue::DBI->new(
			'queue_name'      => 'test1',
			'database_handle' => $dbh,
			'cleanup_timeout' => 3600,
			'verbose'         => 0,
			'lifetime'        => 60,
		);
	},
	'Instantiate a new Queue::DBI object.',
);

# Insert data.
my $inserted_queue_element_id;
lives_ok(
	sub
	{
		$inserted_queue_element_id = $queue->enqueue(
			{
				block1 => 141592653,
				block2 => 589793238,
				block3 => 462643383,
			}
		);
	},
	'Queue data.',
);

# Retrieve data.
my $queue_element;
lives_ok(
	sub
	{
		$queue_element = $queue->next();
	},
	'Retrieve the next item in the queue.',
);

is(
	$queue_element->id(),
	$inserted_queue_element_id,
	'The ID of the queue element retrieved matches the element inserted.',
);

ok(
	!$queue_element->is_over_lifetime(),
	'The element is not yet over its lifetime.',
);

# Alter the created time.
ok(
	$queue_element->{'created'} -= 120,
	'Set created timestamp on the element 120 seconds back in time.',
);

# Verify lifetime.
ok(
	$queue_element->is_over_lifetime(),
	'The element is now past its lifetime.',
);

# Remove the element from the queue.
ok(
	$queue_element->lock(),
	'Lock the element.',
);

ok(
	$queue_element->success(),
	'Remove the element from the queue.',
);
