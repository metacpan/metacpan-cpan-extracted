use strict;
use warnings;

use Tags::Output::Raw;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new(
	'xml' => 0,
);
$obj->put(
	['b', 'MAIN'],
	['d', 'data'],
	['e', 'MAIN'],
);
my $ret = $obj->flush;
is($ret, '<MAIN>data</MAIN>',
	'Put and flush element with data (sgml mode).');

# Test.
$obj->reset;
$obj->put(
	['b', 'ELEMENT'], 
	['b', 'ELEMENT2'], 
	['e', 'ELEMENT'],
);
$ret = $obj->flush;
is($ret, '<ELEMENT><ELEMENT2></ELEMENT>',
	'Put and flush nested element (sgml mode).');

# Test.
$obj = Tags::Output::Raw->new(
	'xml' => 0,
);
$obj->put(
	['b', 'MAIN'], 
	['a', 'id', 'id_value'], 
	['d', 'data'], 
	['e', 'MAIN'],
);
$ret = $obj->flush;
is($ret, '<MAIN id="id_value">data</MAIN>',
	'Put and flush element with key/value attribute and data (sgml mode).');

# Test.
$obj = Tags::Output::Raw->new(
	'xml' => 0,
);
$obj->put(
	['b', 'MAIN'],
	['a', 'disabled'],
	['d', 'data'],
	['e', 'MAIN'],
);
$ret = $obj->flush;
is($ret, '<MAIN disabled>data</MAIN>',
	'Put and flush element with key attribute and data (sgml mode).');

# Test.
$obj = Tags::Output::Raw->new(
	'xml' => 0,
);
$obj->put(
	['b', 'MAIN'], 
	['a', 'id', 'id_value'], 
	['d', 'data'], 
	['e', 'MAIN'], 
	['b', 'MAIN'], 
	['a', 'id', 'id_value2'], 
	['d', 'data'], 
	['e', 'MAIN'],
);
$ret = $obj->flush;
is($ret, '<MAIN id="id_value">data</MAIN><MAIN id="id_value2">data</MAIN>',
	'Put and flush two elements with key/value attribute and data (sgml mode).');

# Test.
$obj = Tags::Output::Raw->new(
	'xml' => 1,
);
$obj->put(
	['b', 'main'], 
	['d', 'data'], 
	['e', 'main'],
);
$ret = $obj->flush;
is($ret, '<main>data</main>',
	'Put and flush element with data (xml mode).');

# Test.
$obj = Tags::Output::Raw->new(
	'xml' => 1,
);
$obj->put(
	['b', 'main'], 
	['a', 'id', 'id_value'], 
	['d', 'data'], 
	['e', 'main'],
);
$ret = $obj->flush;
is($ret, '<main id="id_value">data</main>',
	'Put and flush element with key/value attribute and data (xml mode).');

# Test.
$obj->reset;
$obj->put(
	['b', 'main'], 
	['a', 'id', 0], 
	['d', 'data'], 
	['e', 'main'],
);
$ret = $obj->flush;
is($ret, '<main id="0">data</main>',
	'Put and flush element with key/value attribute and data (xml mode, attribute value is 0).');

# Test.
$obj = Tags::Output::Raw->new(
	'xml' => 1,
);
$obj->put(
	['b', 'main'], 
	['a', 'id', 'id_value'], 
	['d', 'data'], 
	['e', 'main'], 
	['b', 'main'], 
	['a', 'id', 'id_value2'], 
	['d', 'data'], 
	['e', 'main'],
);
$ret = $obj->flush;
is($ret, '<main id="id_value">data</main><main id="id_value2">data</main>',
	'Put and flush two elements with key/value attribute and data (xml mode).');

# Test.
my $long_data = 'a' x 1000;
$obj = Tags::Output::Raw->new;
$obj->put(
	['b', 'MAIN'],
	['d', $long_data],
	['e', 'MAIN'],
);
$ret = $obj->flush;
is($ret, "<MAIN>$long_data</MAIN>",
	'Put and flush element with data (xml mode and long data #1).');

# Test.
$long_data = 'aaaa ' x 1000;
$obj = Tags::Output::Raw->new;
$obj->put(
	['b', 'MAIN'],
	['d', $long_data],
	['e', 'MAIN'],
);
$ret = $obj->flush;
is($ret, "<MAIN>$long_data</MAIN>",
	'Put and flush element with data (xml mode and long data #2).');
