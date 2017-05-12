#!/usr/bin/perl -Tw

#!perl -d:ptkdb

use Test::More tests => 59;

use warnings;
$^W = 1;
use strict;

BEGIN { use_ok( 'RayApp' ); }

my $rayapp = new RayApp;
isa_ok($rayapp, 'RayApp');

my $dsd;
ok($dsd = $rayapp->load_dsd_string('
<application>
	<x id="a1">
		<id type="int" mandatory="yes"/>
		<value type="struct">
			<id/>
			<name mandatory="yes"/>
			<list multiple="list" mandatory="yes"/>
			<list2 multiple="list" />
		</value>
		<age type="number"/>
	</x>
</application>
'), 'Loading DSD with mandatory values');
is($rayapp->errstr, undef, 'No error message wanted');
is($dsd->uri, 'md5:2e963cd65e06843d8b79ba3caea3cfc5', 'Checking URI/MD5');
is($dsd->out_content, '<?xml version="1.0"?>
<application>
	<x>
		<id/>
		<value>
			<id/>
			<name/>
			<list/>
			<list2/>
		</value>
		<age/>
	</x>
</application>
', 'Checking the content');

is($dsd->serialize_data({ 'id' => 56,
	'value' => [ undef, 'Amanda', [ 'xxx', 'yyy' ] ] }),
'<?xml version="1.0"?>
<application>
	<x>
		<id>56</id>
		<value>
			<name>Amanda</name>
			<list>xxx</list>
			<list>yyy</list>
		</value>
	</x>
</application>
', 'Serializing correct data');



is($dsd->serialize_data({ 'value' => { id => 1, name => 1, list => [ ], } },
		{ RaiseError => 0 }),
'<?xml version="1.0"?>
<application>
	<x>
		<value>
			<id>1</id>
			<name>1</name>
		</value>
	</x>
</application>
',
	'Serializing with missing mandatory top level value, RaiseError => 0');
is($dsd->errstr, 'No value of {id} for mandatory data element defined at line 4',
	'Checking error message for missing mandatory top level value');


is(	eval {
	$dsd->serialize_data({
		'value' => { id => 1, name => 1, list => [ ], }
	} ) },
	undef,
	'Serializing with missing mandatory top level value, RaiseError => 1');
is($dsd->errstr, 'No value of {id} for mandatory data element defined at line 4',
	'Checking errstr');
is($@, "No value of {id} for mandatory data element defined at line 4\n",
	'Checking $@ for error message');



is($dsd->serialize_data({ id => 1, 'value' => { id => 2 }, },
		{ RaiseError => 0 }),
'<?xml version="1.0"?>
<application>
	<x>
		<id>1</id>
		<value>
			<id>2</id>
		</value>
	</x>
</application>
',
	'Serializing with missing mandatory values');
is($dsd->errstr, "No value of {value}{name} for mandatory data element defined at line 7\nNo value of {value}{list} for mandatory data element defined at line 8\n",
	'Error message');



is($dsd->serialize_data({ id => 1, 'value' => [ 123 ], },
		{ RaiseError => 0 }),
'<?xml version="1.0"?>
<application>
	<x>
		<id>1</id>
		<value>
			<id>123</id>
		</value>
	</x>
</application>
',
	'Serializing with missing mandatory values');
is($dsd->errstr, "No value of {value}[1] for mandatory data element defined at line 7\nNo value of {value}[2] for mandatory data element defined at line 8\n",
	'Error message');




is($dsd->serialize_data({ 'id' => 3, 'value' => 5 },
		{ RaiseError => 0} ),
'<?xml version="1.0"?>
<application>
	<x>
		<id>3</id>
	</x>
</application>
',
	'Serializing with scalar instead of structure');
is($dsd->errstr,
	"Scalar data '5' found where structure expected for {value} at line 5",
	'Checking error message');


is($dsd->serialize_data({ 'id' => 3, 'xvalue' => 'Amanda' },
		{ RaiseError => 0} ),
'<?xml version="1.0"?>
<application>
	<x>
		<id>3</id>
	</x>
</application>
',
	'Serializing with extra data');
is($dsd->errstr, 'Data {xvalue} does not match data structure description',
	'Checking error message for extra data');



is(eval { $dsd->serialize_data({ 'id' => 3, 'xvalue' => 'Amanda' }) },
	undef,
	'Serializing with extra data, RaiseError => 1');
is($dsd->errstr, 'Data {xvalue} does not match data structure description',
	'Checking errstr for error message for extra data');
is($@, "Data {xvalue} does not match data structure description\n",
	'Checking $@ for error message for extra data');


is($dsd->serialize_data({ 'id' => 3.5, 'age' => 'Amanda', },
		{ RaiseError => 0} ),
'<?xml version="1.0"?>
<application>
	<x>
	</x>
</application>
',
	'Serializing with incorrect data types, RaiseError => 0');
is($dsd->errstr, "Value '3.5' of {id} is not integer for data element defined at line 4\nValue 'Amanda' of {age} is not numeric for data element defined at line 11\n",
	'Checking error message for extra data');


is(eval { $dsd->serialize_data({ 'id' => 3.5, 'age' => 'Amanda' }) },
	undef,
	'Serializing with extra data, RaiseError => 1');
is($dsd->errstr, "Value '3.5' of {id} is not integer for data element defined at line 4\nValue 'Amanda' of {age} is not numeric for data element defined at line 11\n",
	'Checking errstr for error message for extra data');
is($@, "Value '3.5' of {id} is not integer for data element defined at line 4\nValue 'Amanda' of {age} is not numeric for data element defined at line 11\n",
	'Checking $@ for error message for extra data');




ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<output>
		<person type="hash">
			<id type="int" />
			<name/>
			<age type="number" mandatory="yes"/>
			<car mandatory="yes">
				<color mandatory="yes"/>
				<age type="number"/>
				<type/>
			</car>
		</person>
		<result type="int"/>
	</output>
</application>
'), 'Loading correct DSD from string');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->uri, 'md5:e718f4f7df960c87c7ebfdbc16d0008a',
	'Checking URI/MD5 of the DSD');

my $out_content = <<'EOF';
<?xml version="1.0"?>
<application>
	<output>
		<person>
			<id/>
			<name/>
			<age/>
			<car>
				<color/>
				<age/>
				<type/>
			</car>
		</person>
		<result/>
	</output>
</application>
EOF
is($dsd->out_content, $out_content, 'Checking the current content');



is($dsd->serialize_data({ 'result' => 43,
	'person' => {
		id => 243623,
		name => { 'name' => 'Amanda Reese' },
		age => 23,
		car => 'Honda',
		},
	}, { RaiseError => 0 }), '<?xml version="1.0"?>
<application>
	<output>
		<person>
			<id>243623</id>
			<age>23</age>
		</person>
		<result>43</result>
	</output>
</application>
', 'Checking serializing nonscalar data with hash/scalar errors');
is($dsd->errstr,
	"Scalar expected for {person}{name} defined at line 6, got HASH\nScalar data 'Honda' found where structure expected for {person}{car} at line 8\n",
	'Checking errstr');



is($dsd->serialize_data({ 'result' => 42,
	'person' => {
		id => 'ax 243623',
		name => 'Amanda Reese',
		age => 23,
		car => {
			type => 'Honda',
			age => 'old',
			},
		},
	}, { RaiseError => 0 }), '<?xml version="1.0"?>
<application>
	<output>
		<person>
			<name>Amanda Reese</name>
			<age>23</age>
			<car>
				<type>Honda</type>
			</car>
		</person>
		<result>42</result>
	</output>
</application>
', 'Checking serializing nonscalar data with type and mandatory errors');
is($dsd->errstr, "Value 'ax 243623' of {person}{id} is not integer for data element defined at line 5\nNo value of {person}{car}{color} for mandatory data element defined at line 9\nValue 'old' of {person}{car}{age} is not numeric for data element defined at line 10\n",
	'Checking errstr');


is($dsd->serialize_data({ 'result' => 42,
	'person' => {
		id => 243623,
		name => 'Amanda Reese',
		age => 23,
		},
	}, { RaiseError => 0 }), '<?xml version="1.0"?>
<application>
	<output>
		<person>
			<id>243623</id>
			<name>Amanda Reese</name>
			<age>23</age>
		</person>
		<result>42</result>
	</output>
</application>
', 'Checking serializing nonscalar data with type and mandatory errors');
is($dsd->errstr,
	'No value of {person}{car} for mandatory data element defined at line 8',
	'Checking errstr');





ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<output multiple="list">
		<person>
			<id type="int" />
			<name/>
		</person>
		<result type="int"/>
	</output>
</application>
'), 'Loading correct DSD from string');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->uri, 'md5:e54733f83bb30e4af8244d4a1e3c34c2',
	'Checking URI/MD5 of the DSD');

$out_content = <<'EOF';
<?xml version="1.0"?>
<application>
	<output>
		<person>
			<id/>
			<name/>
		</person>
		<result/>
	</output>
</application>
EOF
is($dsd->out_content, $out_content, 'Checking the current content');
is($dsd->serialize_data({}, { RaiseError => 0 }), '<?xml version="1.0"?>
<application>
</application>
', 'Passing in no list should not fail');
is($dsd->errstr, undef, 'Checking that errstr stayed cool');

is(eval { $dsd->serialize_data({
	'output' => 1,
	} ) }, undef, 'Passing scalar for list should die');
like($@, q!/^Data '1' found where/!, 'Check $@');
is($dsd->errstr,
	"Data '1' found where array reference expected for {output} at line 3",
	'And complain in errstr');


is($dsd->serialize_data({
	'output' => 1,
	}, { RaiseError => 0 }), '<?xml version="1.0"?>
<application>
</application>
', 'It should fail with RaiseError => 0 as well');
is($dsd->errstr,
	"Data '1' found where array reference expected for {output} at line 3",
	'And complain in errstr');


is($dsd->serialize_data({
	output => { krtek => 123 },
	}, { RaiseError => 0 }), '<?xml version="1.0"?>
<application>
</application>
', 'And hash for list should fail as well');
is($dsd->errstr,
	"Data 'HASH' found where array reference expected for {output} at line 3",
	'And complain in errstr, yes');

is($dsd->serialize_data({
	output => [
		{
		person => { id => 888, 'name' => 'Amanda', 'car' => 'Honda'},
		result => 123,
		outcome => 123,
		},
		{
		},
		],
	}, { RaiseError => 0 }), '<?xml version="1.0"?>
<application>
	<output>
		<person>
			<id>888</id>
			<name>Amanda</name>
		</person>
		<result>123</result>
	</output>
	<output>
	</output>
</application>
', 'And hash for list should fail as well');
is($dsd->errstr,
	"Data {output}[0]{person}{car} does not match data structure description\nData {output}[0]{outcome} does not match data structure description\n",
	'Complain in errstr');

is($dsd->serialize_data({
	bad => 1
	}, { RaiseError => 0 }), '<?xml version="1.0"?>
<application>
</application>
', 'Passing bad top-level data');
is($dsd->errstr,
	'Data {bad} does not match data structure description',
	'Complain in errstr');


ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<id type="int"/>
	<_param name="jezek" />
	<_param prefix="xx" />
	<_param name="id" multiple="yes"/>
	<_param name="int" type="int"/>
	<_param name="num" type="num"/>
</application>
'), 'Load DSD with parameters');
is($rayapp->errstr, undef, 'Errstr should not be set');
is($dsd->validate_parameters(
	[
	'jezek' => 'krtek',
	'xx-1' => '14',
	'xx-2' => 34,
	'int' => -56,
	'num' => '+13.6',
	]
	), 1,
	'Check valid parameters, should not fail.');
is($dsd->errstr, undef, 'Errstr should not be set');

