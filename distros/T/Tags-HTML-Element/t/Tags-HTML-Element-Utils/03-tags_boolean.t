use strict;
use warnings;

use Tags::HTML::Element::Utils qw(tags_boolean);
use Test::MockObject;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Test::MockObject->new;
$obj->set_true('foo');
my @ret = tags_boolean({}, $obj, 'foo');
is_deeply(
	\@ret,
	[
		['a', 'foo', 'foo'],
	],
	'Get Tags code for boolean value.',
);

# Test.
$obj = Test::MockObject->new;
$obj->set_false('bad');
@ret = tags_boolean({}, $obj, 'bad');
is_deeply(
	\@ret,
	[],
	'No method, no Tags code.',
);
