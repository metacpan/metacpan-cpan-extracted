# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::Raw;
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new(
	'xml' => 0,
);
$obj->put(
	['b', 'MAIN'],
	['e', 'MAIN'],
);
my $ret = $obj->flush;
is($ret, '<MAIN></MAIN>', 'Simple element in SGML mode.');

# Test.
$obj->reset;
$obj->put(
	['b', 'MAIN'],
	['a', 'id', 'id_value'],
	['e', 'MAIN'],
);
$ret = $obj->flush;
is($ret, '<MAIN id="id_value"></MAIN>',
	'Simple element with attribute in SGML mode.');

# Test.
$obj = Tags::Output::Raw->new(
	'attr_delimeter' => q{'},
	'xml' => 0,
);
$obj->put(
	['b', 'MAIN'],
	['a', 'id', 'id_value'],
	['e', 'MAIN'],
);
$ret = $obj->flush;
is($ret, '<MAIN id=\'id_value\'></MAIN>', 'Same as previous with \' quotes.');

# Test.
$obj = Tags::Output::Raw->new(
	'xml' => 0,
);
$obj->put(
	['b', 'MAIN'],
	['a', 'id', 'id_value'],
	['e', 'MAIN'],
	['b', 'MAIN'],
	['a', 'id', 'id_value2'],
	['e', 'MAIN'],
);
$ret = $obj->flush;
is($ret, '<MAIN id="id_value"></MAIN><MAIN id="id_value2"></MAIN>',
	'Multiple simple elements with attributes in SGML mode.');

# Test.
$obj = Tags::Output::Raw->new(
	'attr_delimeter' => q{'},
	'xml' => 0,
);
$obj->put(
	['b', 'MAIN'],
	['a', 'id', 'id_value'],
	['e', 'MAIN'],
	['b', 'MAIN'],
	['a', 'id', 'id_value2'],
	['e', 'MAIN'],
);
$ret = $obj->flush;
is($ret, '<MAIN id=\'id_value\'></MAIN><MAIN id=\'id_value2\'></MAIN>',
	'Same as previous with \' quotes.');

# Test.
$obj = Tags::Output::Raw->new(
	'xml' => 1,
);
$obj->put(
	['b', 'main'],
	['e', 'main'],
);
$ret = $obj->flush;
is($ret, '<main />', 'Simple element in XML mode.');

# Test.
$obj->reset;
$obj->put(
	['b', 'main'],
	['a', 'id', 'id_value'],
	['e', 'main'],
);
$ret = $obj->flush;
is($ret, '<main id="id_value" />',
	'Simple element with attribute in XML mode.');

# Test.
$obj = Tags::Output::Raw->new(
	'attr_delimeter' => q{'},
	'xml' => 1,
);
$obj->put(
	['b', 'main'],
	['a', 'id', 'id_value'],
	['e', 'main'],
);
$ret = $obj->flush;
is($ret, '<main id=\'id_value\' />', 'Same as previous with \' quotes.');

# Test.
$obj = Tags::Output::Raw->new(
	'xml' => 1,
);
$obj->put(
	['b', 'main'],
	['a', 'id', 'id_value'],
	['e', 'main'],
	['b', 'main'],
	['a', 'id', 'id_value2'],
	['e', 'main'],
);
$ret = $obj->flush;
is($ret, '<main id="id_value" /><main id="id_value2" />',
	'Multiple simple elements with attributes in XML mode.');

# Test.
$obj = Tags::Output::Raw->new(
	'attr_delimeter' => q{'},
	'xml' => 1,
);
$obj->put(
	['b', 'main'],
	['a', 'id', 'id_value'],
	['e', 'main'],
	['b', 'main'],
	['a', 'id', 'id_value2'],
	['e', 'main'],
);
$ret = $obj->flush;
is($ret, '<main id=\'id_value\' /><main id=\'id_value2\' />',
	'Same as previous with \' quotes.');
