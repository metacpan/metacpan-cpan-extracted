#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 4;

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
			'queue_name'        => 'test1',
			'database_handle'   => $dbh,
			'cleanup_timeout'   => 3600,
			'verbose'           => 0,
			'max_requeue_count' => 5,
		);
	},
	'Instantiate a new Queue::DBI object.',
);
isa_ok(
	$queue,
	'Queue::DBI',
	'Object returned by Queue::DBI->new()',
);

# Verify that max_requeue_count() returns the correct result.
is(
	$queue->get_max_requeue_count(),
	5,
	'Retrieve the max_requeue_count.',
);
