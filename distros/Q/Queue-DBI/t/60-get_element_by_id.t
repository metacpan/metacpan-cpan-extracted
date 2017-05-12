#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 13;

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
	'Instantiate the queue.',
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

# Retrieve data.
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
	'The object returned by next()',
);


# Retrieve the queue element by ID.
my $queue_element_by_id;
lives_ok(
	sub
	{
		$queue_element_by_id = $queue->get_element_by_id( $queue_element->id() );
	},
	'Retrieve a queue element by ID.',
);

isa_ok(
	$queue_element_by_id,
	'Queue::DBI::Element',
	'Object returned by get_element_by_id()',
);

is(
	$queue_element_by_id->id(),
	$queue_element->id(),
	'The ID of the element retrieved is correct.',
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


# Retrieve the queue element by ID after locking.
my $queue_element_by_id_after_lock;
lives_ok(
	sub
	{
		$queue_element_by_id_after_lock = $queue->get_element_by_id( $queue_element->id() );
	},
	'Retrieve the queue element by ID after locking it.',
);

isa_ok(
	$queue_element_by_id_after_lock,
	'Queue::DBI::Element',
	'Object returned by get_element_by_id() after lock()',
);

is(
	$queue_element_by_id_after_lock->id(),
	$queue_element->id(),
	'The ID of the element retrieved is correct.',
);

# Remove.
lives_ok(
	sub
	{
		$queue_element->success()
		||
		die 'Cannot mark as successfully processed';
	},
	'Mark the element as successfully processed.',
);

