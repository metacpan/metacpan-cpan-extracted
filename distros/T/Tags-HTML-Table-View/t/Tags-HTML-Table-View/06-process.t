use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Table::View;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Table::View->new(
	'tags' => $tags,
);
$obj->init([
	[
		'Title col #1',
		'Title col #2',
	],
	[
		'Data col #1',
		'Data col #2',
	],
], 'No data.');
my $ret = $obj->process;
is($ret, undef, 'process() returns undef.');
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'table'],
		['a', 'class', 'table'],
		['b', 'tr'],
		['b', 'th'],
		['d', 'Title col #1'],
		['e', 'th'],
		['b', 'th'],
		['d', 'Title col #2'],
		['e', 'th'],
		['e', 'tr'],
		['b', 'tr'],
		['b', 'td'],
		['d', 'Data col #1'],
		['e', 'td'],
		['b', 'td'],
		['d', 'Data col #2'],
		['e', 'td'],
		['e', 'tr'],
		['e', 'table'],
	],
	'Tags code for table with data.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Table::View->new(
	'tags' => $tags,
);
$obj->init([
	[
		'Title col #1',
		'Title col #2',
	],
], 'No data.');
$ret = $obj->process;
is($ret, undef, 'process() returns undef.');
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'table'],
		['a', 'class', 'table'],
		['b', 'tr'],
		['b', 'th'],
		['d', 'Title col #1'],
		['e', 'th'],
		['b', 'th'],
		['d', 'Title col #2'],
		['e', 'th'],
		['e', 'tr'],
		['b', 'tr'],
		['b', 'td'],
		['a', 'colspan', 2],
		['d', 'No data.'],
		['e', 'td'],
		['e', 'tr'],
		['e', 'table'],
	],
	'Tags code for table without data.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Table::View->new(
	'header' => 0,
	'tags' => $tags,
);
$obj->init([
	[
		'Data col #1',
		'Data col #2',
	],
], 'No data.');
$ret = $obj->process;
is($ret, undef, 'process() returns undef.');
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'table'],
		['a', 'class', 'table'],
		['b', 'tr'],
		['b', 'td'],
		['d', 'Data col #1'],
		['e', 'td'],
		['b', 'td'],
		['d', 'Data col #2'],
		['e', 'td'],
		['e', 'tr'],
		['e', 'table'],
	],
	'Tags code for table with data (without header).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Table::View->new(
	'header' => 0,
	'tags' => $tags,
);
$obj->init([
	[
		'Data col #1',
		[['d', 'Data col #2']],
	],
], 'No data.');
$ret = $obj->process;
is($ret, undef, 'process() returns undef.');
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'table'],
		['a', 'class', 'table'],
		['b', 'tr'],
		['b', 'td'],
		['d', 'Data col #1'],
		['e', 'td'],
		['b', 'td'],
		['d', 'Data col #2'],
		['e', 'td'],
		['e', 'tr'],
		['e', 'table'],
	],
	'Tags code for table with data (data are in Tags format).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Table::View->new(
	'header' => 0,
	'tags' => $tags,
);
$obj->init([
	[
		'Data col #1',
		{},
	],
], 'No data.');
eval {
	$obj->process;
};
is($EVAL_ERROR, "Bad value object.\n",
	"Bad value object.");
clean();

# Test.
my $test_obj = Test::MockObject->new;
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Table::View->new(
	'header' => 0,
	'tags' => $tags,
);
$obj->init([
	[
		'Data col #1',
		$test_obj,
	],
], 'No data.');
eval {
	$obj->process;
};
is($EVAL_ERROR, "Bad value object.\n",
	"Bad value object.");
clean();
