#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 6;

use lib 't/';
use LocalTest;

use Queue::DBI;


my $dbh = LocalTest::ok_database_handle();

# Clean up the tables.
foreach my $table_name ( qw( queues queue_elements ) )
{
	lives_ok(
		sub
		{
			$dbh->do(
				sprintf(
					q| DELETE FROM %s |,
					$dbh->quote_identifier( $table_name ),
				)
			);
		},
		"Empty table >$table_name<.",
	);
}

# Test creating queues.
foreach my $queue_name ( qw( test1 test2 ) )
{
	lives_ok(
		sub
		{
			$dbh->do(
				q|
					INSERT INTO queues( name )
					VALUES( ? )
				|,
				{},
				$queue_name,
			);
		},
		"Create queue >$queue_name<.",
	);
}

# Make sure duplicate queue names are handled properly.
dies_ok(
	sub
	{
		# Disable printing errors out since we expect the test to fail.
		local $dbh->{'PrintError'} = 0;

		$dbh->do(
			q|
				INSERT INTO queues( name )
				VALUES( ? )
			|,
			{},
			'test1',
		);
	},
	"Reject duplicate queue name.",
);

