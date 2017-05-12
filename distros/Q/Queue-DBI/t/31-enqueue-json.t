#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More;

use lib 't/';
use LocalTest;

use Queue::DBI;


# Important: only run this test if a JSON module is available.
my $json_module;

# Check if JSON::MaybeXS is installed, which allows using either
# Cpanel::JSON::XS, JSON::XS, or JSON::PP.
# Important: new() was only added in version 1.001000, so we need to skip
# previous versions of JSON::MaybeXS.
eval "use JSON::MaybeXS 1.001000";
if ( !$@ )
{
	$json_module = 'JSON::MaybeXS';
}
else
{
	# Fall back on JSON::PP if JSON::MaybeXS wasn't found, as it became a core
	# module starting with perl v5.13.9.
	eval "use JSON::PP";
	$json_module = 'JSON::PP'
		if !$@;
}
plan( skip_all => "Neither JSON::MaybeXS nor JSON::PP are installed." )
	if !defined( $json_module );

# Print out some debugging information.
# Since the JSON modules are not explicit prerequisites for the installation of
# this distribution, the version information does not show up in CPAN tester
# reports.
my $json_module_version = $json_module->VERSION;
diag(
	sprintf(
		"Using %s (%s) for testing JSON serialization.",
		$json_module,
		defined( $json_module_version ) ? $json_module_version : 'undef',
	)
);

# Start testing.
plan( tests => 12 );

my $dbh = LocalTest::ok_database_handle();
my $json = $json_module->new();

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
			'serializer_freeze' => sub { $json->encode($_[0]) },
			'serializer_thaw'   => sub { $json->decode($_[0]) },
		);
	},
	'Instantiate a new Queue::DBI object.',
);

# Test data.
ok(
	defined(
		my $data =
		{
			block => 49494494,
		}
	),
	'Define test data.',
);

# Test freezing/unfreezing.
my $frozen_data;
lives_ok(
	sub
	{
		$frozen_data = $queue->freeze( $data );
	},
	'Freeze the data.',
);
like(
	$frozen_data,
	qr/^\{\W*block\W*:\W*49494494\W*\}/,
	'The frozen data looks like a JSON string.',
);
my $thawed_data;
lives_ok(
	sub
	{
		$thawed_data = $queue->thaw( $frozen_data ),
	},
	'Thaw the frozen data.',
);
is_deeply(
	$thawed_data,
	$data,
	'The thawed data matches the original data.',
);

# Insert data.
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
