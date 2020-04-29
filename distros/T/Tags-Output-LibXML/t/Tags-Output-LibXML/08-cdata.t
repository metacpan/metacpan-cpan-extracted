use strict;
use warnings;

use Tags::Output::LibXML;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::LibXML->new;
$obj->put(
	['b', 'tag'],
	['cd', 'aaaaa<dddd>dddd'],
	['e', 'tag'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<tag><![CDATA[aaaaa<dddd>dddd]]></tag>
END
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'tag'],
	['cd', (('aaaaa<dddd>dddd') x 10)],
	['e', 'tag'], 
);
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<tag><![CDATA[aaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>dddd]]></tag>
END
is($ret, $right_ret);

# Test.
$obj = Tags::Output::LibXML->new;
$obj->put(
	['b', 'tag'],
	['cd', 'aaaaa<dddd>dddd', ']]>'],
	['e', 'tag'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<tag><![CDATA[aaaaa<dddd>dddd]]]]><![CDATA[>]]></tag>
END
is($ret, $right_ret);
