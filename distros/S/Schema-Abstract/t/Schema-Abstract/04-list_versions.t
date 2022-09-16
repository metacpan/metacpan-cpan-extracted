use strict;
use warnings;

use File::Object;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
unshift @INC, $data->dir('ex1')->s;
require Schema::Foo;
my $obj = Schema::Foo->new;
my @ret = $obj->list_versions;
is_deeply(
	\@ret,
	[
		'0.1.0',
		'0.1.1',
		'0.2.0',
	],
	'Fetch list of versions.',
);
