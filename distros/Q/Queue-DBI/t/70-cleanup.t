#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 11;

use lib 't/';
use LocalTest;

use Queue::DBI;
use Test::Type;


my $dbh = LocalTest::ok_database_handle();

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
my $queue_element_id;
lives_ok(
	sub
	{
		$queue_element_id = $queue->enqueue(
			{
				block1 => 141592653,
				block2 => 589793238,
				block3 => 462643383,
			}
		);
	},
	'Queue data.',
);

# Tweak element's lock time.
lives_ok(
	sub
	{
		$dbh->do(
			q|
				UPDATE queue_elements
				SET lock_time = ?
				WHERE queue_element_id = ?
			|,
			{},
			time() - 3800,
			$queue_element_id,
		);
	},
	'Set lock time to 3800s ago on the element.',
);

# Cleanup.
my $cleaned_up_elements;
lives_ok(
	sub
	{
		$cleaned_up_elements = $queue->cleanup( 3600 );
	},
	'Requeue elements locked for more than 3600s.',
);

ok_arrayref(
	$cleaned_up_elements,
	name => 'cleanup() return value',
);

is(
	scalar( @$cleaned_up_elements ),
	1,
	'One element was requeued.',
);

my $cleaned_up_element = $cleaned_up_elements->[0];
is(
	defined( $cleaned_up_element ) ? $cleaned_up_element->id() : undef,
	$queue_element_id,
	'The cleaned up element matches the ID of the element inserted.',
);

ok(
	$cleaned_up_element->lock(),
	'Lock the element.',
);

ok(
	$cleaned_up_element->success(),
	'Indicate that the element has been successfully processed.',
);

