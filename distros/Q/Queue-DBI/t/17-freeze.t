#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 3;

use lib 't/';
use LocalTest;

use Queue::DBI;


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
		);
	},
	'Instantiate a new Queue::DBI object.',
);

can_ok(
	$queue,
	'freeze',
);
