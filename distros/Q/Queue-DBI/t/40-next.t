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
	'Instantiate a new Queue::DBI object.',
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
for ( my $i = 0; $i < 5; $i++ )
{
	my $data =
	{
		'count' => $i,
	};

	lives_ok(
		sub
		{
			$queue->enqueue( $data );
		},
		"Queue data - Element $i.",
	);
};

# Retrieve data.
for ( my $i = 0; $i < 5; $i++ )
{
	subtest(
		"Retrieve element $i.",
		sub
		{
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

			my $data;
			lives_ok(
				sub
				{
					$data = $queue_element->data();
				},
				'Extract data.',
			);
			ok(
				defined( $data ),
				'Data defined.',
			);

			ok(
				defined( $data->{'count'} ) && ( $data->{'count'} == $i ),
				'Find expected item.',
			) || diag( "Data:\n" . explain( $data ) );
		}
	);
}
