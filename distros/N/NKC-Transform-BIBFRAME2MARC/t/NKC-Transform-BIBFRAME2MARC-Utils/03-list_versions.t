use strict;
use warnings;

use File::Object;
use NKC::Transform::BIBFRAME2MARC::Utils qw(list_versions);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Data directory.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my @ret = list_versions($data_dir->dir('xsl_files')->s);
is_deeply(
	\@ret,
	[
		'2.6.0',
		'2.7.0',
		'2.9.0',
		'3.0.0',
	],
	'Fetch list of versions.',
);
