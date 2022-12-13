use strict;
use warnings;

use File::Object;
use Pod::Example qw(sections);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Load module.
my $modules_dir;
BEGIN {
	$modules_dir = File::Object->new->up->dir('modules');
	unshift @INC, $modules_dir->s;	
}
use Ex1;

# Test.
my @ret = sections('Ex1');
my @right_ret = (
	'EXAMPLE',
);
is_deeply(
	\@ret,
	\@right_ret,
	'One section from loaded module.',
);

# Test.
@ret = sections($modules_dir->file('Ex2.pm')->s);
@right_ret = (
	'EXAMPLE',
);
is_deeply(
	\@ret,
	\@right_ret,
	'One section from module file.',
);

# Test.
@ret = sections($modules_dir->file('Ex4.pm')->s);
@right_ret = (
	'EXAMPLE1',
	'EXAMPLE2',
);
is_deeply(
	\@ret,
	\@right_ret,
	'Two sections from module file.',
);
