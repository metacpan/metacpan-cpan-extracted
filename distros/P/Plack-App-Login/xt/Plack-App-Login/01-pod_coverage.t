use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok(
	'Plack::App::Login',
	{
		'also_private' => ['prepare_app'],
	},
	'Plack::App::Login is covered.',
);
