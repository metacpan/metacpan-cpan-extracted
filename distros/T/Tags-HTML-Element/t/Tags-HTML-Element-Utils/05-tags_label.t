use strict;
use warnings;

use Tags::HTML::Element::Utils qw(tags_label);
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Test::MockObject->new;
$obj->mock('css_class', sub { return; });
$obj->mock('label', sub { return 'Label'; });
$obj->set_false('required');
$obj->mock('id', sub { return; });
my $ret = tags_label({
	'tags' => $tags,
}, $obj);
is($ret, undef, 'Return value.');
my @tags = $tags->flush(1);
is_deeply(
	$tags[0],
	[
		['b', 'label'],
		['d', 'Label'],
		['e', 'label'],
	],
	'Get Tags code for label.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Test::MockObject->new;
$obj->mock('css_class', sub { return; });
$obj->mock('label', sub { return 'Label'; });
$obj->set_false('required');
$obj->mock('id', sub { return 2; });
$ret = tags_label({
	'tags' => $tags,
}, $obj);
is($ret, undef, 'Return value.');
@tags = $tags->flush(1);
is_deeply(
	$tags[0],
	[
		['b', 'label'],
		['a', 'for', 2],
		['d', 'Label'],
		['e', 'label'],
	],
	'Get Tags code for label (with id).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Test::MockObject->new;
$obj->mock('css_class', sub { return 'input'; });
$obj->mock('id', sub { return 2; });
$obj->mock('label', sub { return 'Label'; });
$obj->set_true('required');
$ret = tags_label({
	'tags' => $tags,
}, $obj);
is($ret, undef, 'Return value.');
@tags = $tags->flush(1);
is_deeply(
	$tags[0],
	[
		['b', 'label'],
		['a', 'for', 2],
		['d', 'Label'],
		['b', 'span'],
		['a', 'class', 'input-required'],
		['d', '*'],
		['e', 'span'],
		['e', 'label'],
	],
	'Get Tags code for label (with id and required).',
);
