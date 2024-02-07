use strict;
use warnings;

use Tags::HTML::Element::Utils qw(tags_data);
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Test::MockObject->new;
$obj->mock('data_type', sub { return 'plain'; });
$obj->mock('data', sub { return ['foo']; });
my $ret = tags_data({
	'tags' => $tags,
}, $obj);
is($ret, undef, 'Return value.');
my @tags = $tags->flush(1);
is_deeply(
	$tags[0],
	[
		['d', 'foo'],
	],
	'Get Tags code for data.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Test::MockObject->new;
$obj->mock('data_type', sub { return 'plain'; });
$obj->mock('data', sub { return ['foo', 'bar']; });
$ret = tags_data({
	'tags' => $tags,
}, $obj);
is($ret, undef, 'Return value.');
@tags = $tags->flush(1);
is_deeply(
	$tags[0],
	[
		['d', 'foo'],
		['d', 'bar'],
	],
	'Get Tags code for data. Multiple data.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Test::MockObject->new;
$obj->mock('data_type', sub { return 'tags'; });
$obj->mock('data', sub { return ( [
	['b', 'element'],
	['d', 'data'],
	['e', 'element'],
] ); });
$ret = tags_data({
	'tags' => $tags,
}, $obj);
is($ret, undef, 'Return value.');
@tags = $tags->flush(1);
is_deeply(
	$tags[0],
	[
		['b', 'element'],
		['d', 'data'],
		['e', 'element'],
	],
	'Get Tags code for Tags structure.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Test::MockObject->new;
$obj->mock('data_type', sub { return 'cb'; });
$obj->mock('data', sub { return [
	sub {
		$tags->put(
			['b', 'element'],
			['d', 'data'],
			['e', 'element'],
		);
		return;
	},
]; });
$ret = tags_data({
	'tags' => $tags,
}, $obj);
is($ret, undef, 'Return value.');
@tags = $tags->flush(1);
is_deeply(
	$tags[0],
	[
		['b', 'element'],
		['d', 'data'],
		['e', 'element'],
	],
	'Get Tags code for callback.',
);
