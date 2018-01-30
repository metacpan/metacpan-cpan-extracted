use strict;
use warnings;

use Tags::Output::Raw;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new(
	'xml' => 1,
);
$obj->put(
	['r', '<?xml version="1.1">'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
<?xml version="1.1">
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'element'],
	['r', 'raw'],
	['e', 'element'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<element>raw</element>
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'element'],
	['b', 'other'],
	['r', 'raw'],
	['e', 'other'],
	['e', 'element'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<element><other>raw</other></element>
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'element'],
	['b', 'other'],
	['b', 'xxx'],
	['r', 'raw'],
	['e', 'xxx'],
	['e', 'other'],
	['e', 'element'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<element><other><xxx>raw</xxx></other></element>
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'element'],
	['r', '<![CDATA['],
	['d', 'bla'],
	['r', ']]>'],
	['e', 'element'],
);
$ret = $obj->flush;
$right_ret = '<element><![CDATA[bla]]></element>';
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'element'],
	['a', 'key', 'val'],
	['r', '<![CDATA['],
	['d', 'bla'],
	['r', ']]>'],
	['e', 'element'],
);
$ret = $obj->flush;
$right_ret = '<element key="val"><![CDATA[bla]]></element>';
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'element'],
	['a', 'key', 'val'],
	['r', '<![CDATA['],
	['b', 'other'],
	['d', 'bla'],
	['e', 'other'],
	['r', ']]>'],
	['e', 'element'],
);
$ret = $obj->flush;
$right_ret = '<element key="val"><![CDATA[<other>bla</other>]]></element>';
is($ret, $right_ret);
