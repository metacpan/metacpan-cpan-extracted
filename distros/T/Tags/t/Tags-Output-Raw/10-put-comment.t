# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::Raw;
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new(
	'xml' => 1,
);
$obj->put(
	['c', 'comment'],
	['c', ' comment '],
);
my $ret = $obj->flush;
my $right_ret = '<!--comment--><!-- comment -->';
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['c', 'comment-'],
);
$ret = $obj->flush;
$right_ret = '<!--comment- -->';
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['c', '<element>comment</element>'],
);
$ret = $obj->flush;
$right_ret = '<!--<element>comment</element>-->';
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'element'],
	['c', '<element>comment</element>'],
	['e', 'element'],
);
$ret = $obj->flush;
$right_ret = '<element><!--<element>comment</element>--></element>';
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'element'],
	['a', 'par', 'val'],
	['c', '<element>comment</element>'],
	['e', 'element'],
);
$ret = $obj->flush;
$right_ret = '<element par="val"><!--<element>comment</element>--></element>';
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'element'],
	['c', '<element>comment</element>'],
	['a', 'par', 'val'],
	['d', 'data'],
	['e', 'element'],
);
$ret = $obj->flush;
$right_ret = '<!--<element>comment</element>--><element par="val">data</element>';
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'element'],
	['c', '<element>comment</element>'],
	['a', 'par', 'val'],
	['cd', 'data'],
	['e', 'element'],
);
$ret = $obj->flush;
$right_ret = '<!--<element>comment</element>--><element par="val"><![CDATA[data]]></element>';
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'element'],
	['c', '<element>comment</element>'],
	['a', 'par', 'val'],
	['e', 'element'],
);
$ret = $obj->flush;
$right_ret = '<!--<element>comment</element>--><element par="val" />';
is($ret, $right_ret);
