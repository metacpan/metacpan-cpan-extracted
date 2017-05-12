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

# Make sure we can't enqueue scalars.
throws_ok(
	sub
	{
		$queue->enqueue( 'test' );
	},
	qr/\QThe data passed must be a reference, not a scalar\E/,
	'Scalars are not allowed.',
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
	'Call to retrieve the next item in the queue.',
);
isa_ok(
	$queue_element,
	'Queue::DBI::Element',
	'Object returned by next()',
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

