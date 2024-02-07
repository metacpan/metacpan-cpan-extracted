use strict;
use warnings;

use Tags::HTML::Element::Utils qw(tags_value);
use Test::MockObject;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Test::MockObject->new;
$obj->mock('foo', sub {
	return 'value';
});
my @ret = tags_value({}, $obj, 'foo');
is_deeply(
	\@ret,
	[
		['a', 'foo', 'value'],
	],
	'Get Tags code for value.',
);

# Test.
$obj = Test::MockObject->new;
$obj->mock('foo', sub {
	return 'value';
});
@ret = tags_value({}, $obj, 'foo', 'bar');
is_deeply(
	\@ret,
	[
		['a', 'bar', 'value'],
	],
	'Get Tags code for value with rewrite of key.',
);

# Test.
$obj = Test::MockObject->new;
$obj->set_false('bad');
@ret = tags_value({}, $obj, 'bad');
is_deeply(
	\@ret,
	[],
	'No method, no Tags code.',
);
