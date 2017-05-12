#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 7;

use lib 't/';
use LocalTest;

use Queue::DBI;


my $dbh = LocalTest::ok_database_handle();

can_ok(
	'Queue::DBI',
	'new',
);

# Instantiate the queue object.
subtest(
	'Verify mandatory arguments.',
	sub
	{
		plan( tests => 2 );

		dies_ok(
			sub
			{
				Queue::DBI->new(
					'database_handle' => $dbh,
					'cleanup_timeout' => 3600,
					'verbose'         => 0,
				);
			},
			'The argument "queue_name" is required.',
		);

		dies_ok(
			sub
			{
				Queue::DBI->new(
					'queue_name'      => 'test1',
					'cleanup_timeout' => 3600,
					'verbose'         => 0,
				);
			},
			'The argument "database_handle" is required.',
		);
	}
);

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
isa_ok(
	$queue,
	'Queue::DBI',
	'Object returned by new()',
);

subtest(
	'Verify optional arguments.',
	sub
	{
		plan( tests => 3 );

		dies_ok(
			sub
			{
				Queue::DBI->new(
					'queue_name'      => 'test1',
					'database_handle' => $dbh,
					'cleanup_timeout' => 'test',
					'verbose'         => 0,
				);
			},
			'The argument "cleanup_timeout" must be an integer.',
		);

		lives_ok(
			sub
			{
				Queue::DBI->new(
					'queue_name'      => 'test1',
					'database_handle' => $dbh,
					'cleanup_timeout' => 3600,
				);
			},
			'The argument "verbose" is optional.',
		);

		dies_ok(
			sub
			{
				Queue::DBI->new(
					'queue_name'      => 'test1',
					'database_handle' => $dbh,
					'cleanup_timeout' => 3600,
					'lifetime'        => 'test',
				);
			},
			'The argument "lifetime" must be an integer.',
		);
	}
);

subtest(
	'Verify "freeze" and "thaw" arguments.',
	sub
	{
		plan( tests => 5 );

		throws_ok(
			sub
			{
				Queue::DBI->new(
					'queue_name'        => 'test1',
					'database_handle'   => $dbh,
					'serializer_freeze' => 'test',
				);
			},
			qr/\QArgument "serializer_freeze" must be a code reference\E/,
			'The argument "serializer_freeze" must be a code ref.',
		);

		throws_ok(
			sub
			{
				Queue::DBI->new(
					'queue_name'        => 'test1',
					'database_handle'   => $dbh,
					'serializer_thaw'   => 'test',
				);
			},
			qr/\QArgument "serializer_thaw" must be a code reference\E/,
			'The argument "serializer_thaw" must be a code ref.',
		);

		throws_ok(
			sub
			{
				Queue::DBI->new(
					'queue_name'        => 'test1',
					'database_handle'   => $dbh,
					'serializer_freeze' => undef,
					'serializer_thaw'   => sub { return $_[0] },
				);
			},
			qr/\QArguments "serializer_freeze" and "serializer_thaw" must be defined together\E/,
			'If "serializer_thaw" is defined, "serializer_freeze" must be defined as well.',
		);

		throws_ok(
			sub
			{
				Queue::DBI->new(
					'queue_name'        => 'test1',
					'database_handle'   => $dbh,
					'serializer_freeze' => sub { return $_[0] },
					'serializer_thaw'   => undef,
				);
			},
			qr/\QArguments "serializer_freeze" and "serializer_thaw" must be defined together\E/,
			'If "serializer_freeze" is defined, "serializer_thaw" must be defined as well.',
		);

		lives_ok(
			sub
			{
				Queue::DBI->new(
					'queue_name'        => 'test1',
					'database_handle'   => $dbh,
					'serializer_freeze' => sub { return $_[0] },
					'serializer_thaw'   => sub { return $_[0] },
				);
			},
			'Pass "serializer_freeze" and "serializer_thaw" coderefs.'
		);
	}
);
