#!/usr/bin/perl -w -CSAD

use Test::More tests => 280;
use bytes;
use Cwd ();
use utf8;

$^W = 1;
use warnings;
use strict;

BEGIN { use_ok( 'RayApp' ); }
BEGIN { use_ok( 'POSIX' ); }
BEGIN { use_ok( 'XML::LibXML' ); }

POSIX::setlocale(POSIX::LC_ALL, 'C');

chdir 't' if -d 't';

my $rayapp = new RayApp;
isa_ok($rayapp, 'RayApp');

my $dsd;

ok($dsd = $rayapp->load_dsd("simple1.xml"), 'Loading correct DSD simple1.xml');
is($rayapp->errstr, undef, 'Checking that there was no error');
ok($dsd->can('isdsd'), 'Checking that we loaded DSD');

like($dsd->uri, '/^file:.*simple1.xml$/', 'Checking URI of the DSD');
is($dsd->md5_hex, 'a9eaba3064593944b9141aee064585cf',
	'Checking MD5 of the DSD');

is("@{[ sort keys %{ $dsd->params } ]}", "action id",
	'Checking parameters found');

ok($dsd = $rayapp->load_dsd("simple1.xml"), 'Loading for the second time');
is($rayapp->errstr, undef, 'Checking that there was no error');

like($dsd->uri, '/^file:.*simple1.xml$/', 'Checking URI of the DSD');
is($dsd->md5_hex, 'a9eaba3064593944b9141aee064585cf',
	'Checking MD5 of the DSD');

is("@{[ sort keys %{ $dsd->params } ]}", "action id",
	'Checking parameters found');

my $params = $dsd->params;
is("@{[ map { qq!$_:$params->{$_}{type}! } sort keys %$params ]}",
	"action:string id:int",
	'Checking parameter types');

is($dsd->out_content, '<?xml version="1.0"?>
<application>
	<name/>
	<result/>
</application>
', 'Checking the current content');

my $txt;
is($txt = $dsd->serialize_data({ 'result' => 56, 'name' => 'Amanda' },
	{ RaiseError => 0 }),
'<?xml version="1.0"?>
<application>
	<name>Amanda</name>
	<result>56</result>
</application>
', 'Checking serialization of data');
is($dsd->errstr, undef, 'There should be no errstr');

=comment

my $dtd = $dsd->get_dtd;
is($dtd, '<!ELEMENT application ((name?, result?))>
<!ELEMENT name (#PCDATA)*>
<!ELEMENT result (#PCDATA)*>
', 'Checking the DTD');
my $parsed_dtd = XML::LibXML::Dtd->parse_string($dtd);

my $parser = XML::LibXML->new();
ok($parser, 'Loading XML::LibXML parser');

my $doc = $parser->parse_string($txt);
ok($doc, 'Parse the serialized XML back');

is($doc->is_valid($parsed_dtd), 1, 'Check against the DTD');

=cut


is($dsd->serialize_data({ 'result' => -56 },
	{ RaiseError => 0, validate => 1 }),
'<?xml version="1.0"?>
<application>
	<result>-56</result>
</application>
', 'Checking serialization of data with validate');
is($dsd->errstr, undef, 'There should be no errstr');


is($dsd->serialize_data({ }, { RaiseError => 0, validate => 1 }),
'<?xml version="1.0"?>
<application>
</application>
', 'Checking serialization of data with no data');
is($dsd->errstr, undef, 'There should be no errstr');

is($txt = $dsd->serialize_data({ 'result' => 34, 'name' => 'Peter'},
	{ RaiseError => 0, doctype => 'simple1.dtd' }),
'<?xml version="1.0"?>
<!DOCTYPE application SYSTEM "simple1.dtd">
<application>
	<name>Peter</name>
	<result>34</result>
</application>
', 'Serialize with doctype');



is($dsd->serialize_data({ 'result' => 34, 'name' => 'Peter'},
	{ RaiseError => 0, doctype_ext => '.DTD' }),
'<?xml version="1.0"?>
<!DOCTYPE application SYSTEM "simple1.DTD">
<application>
	<name>Peter</name>
	<result>34</result>
</application>
', 'Serialize with doctype_ext');



ok($dsd = $rayapp->load_dsd("simple2.xml"),
	'Loading correct DSD t/simple2.xml');
is($rayapp->errstr, undef, 'Checking that there was no error');

like($dsd->uri, '/^file:.*simple2.xml$/', 'Checking URI of the DSD');
is($dsd->md5_hex, '0d3f3778c0d5aeb5d574ef12a790f7e8',
	'Checking MD5 of the DSD');

is("@{[ sort keys %{ $dsd->params } ]}", "_param id",
	'Checking parameters found');

$params = $dsd->params;
is("@{[ map { qq!$_->$params->{$_}{type}! } sort keys %$params ]}",
	"_param->string id->int",
	'Checking parameter types');


is($dsd->out_content, '<?xml version="1.0" encoding="UTF-8"?>
<application>
	<mám>
		<_param/>

		<record>
			<name/>
			<result/>
		</record>
	</mám>
</application>
', 'Checking the current content');



ok($dsd = $rayapp->load_dsd("../../httpd-tests/t/htdocs/ray/app1.dsd"),
	'Loading correct DSD ../../httpd-tests/t/htdocs/ray/app1.dsd');
is($rayapp->errstr, undef, 'No error, please');
like($dsd->uri, '/^file:.*app1.dsd$/', 'Checking URI of the DSD');
is($dsd->md5_hex, '1d0461098a35c558d237003e5d5ca52f',
	'Checking MD5 of the DSD');
is("@{[ sort keys %{ $dsd->params } ]}", "id",
	'Checking parameters found');



ok($dsd = $rayapp->load_dsd("../../httpd-tests/t/htdocs/ray/app1.dsd"),
	'Load it again');
is($rayapp->errstr, undef, 'Again, no error');


ok($dsd = $rayapp->load_dsd_string(<<'EOF'), 'Loading correct DSD from string');
<?xml version="1.0" standalone="no"?>
<root>
	<child>
		<child mandatory="yes">
		</child>
		<_param name='mix'></_param>
	</child>
</root>
EOF
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->uri, 'md5:9411809f5b9cd8bf682360b1243f00c5',
	'Checking URI of the DSD');
is($dsd->md5_hex, '9411809f5b9cd8bf682360b1243f00c5',
	'Checking MD5 of the DSD');

is("@{[ sort keys %{ $dsd->params } ]}", "mix",
	'Checking parameters found');

is($dsd->out_content, '<?xml version="1.0" standalone="no"?>
<root>
	<child>
		<child/>
	</child>
</root>
', 'Checking the current content');

### print STDERR $dsd->get_dtd;

is($dsd->serialize_data({ 'child' => 'Tom & Jerry' },
	{ RaiseError => 0, validate => 1 }),
'<?xml version="1.0" standalone="no"?>
<root>
	<child>
		<child>Tom &amp; Jerry</child>
	</child>
</root>
', 'Checking serialization of data');
is($dsd->errstr, undef, 'No errstr should materialize');



ok($dsd = $rayapp->load_dsd("simple3.xml"),
	'Loading correct DSD t/simple3.xml');
is($rayapp->errstr, undef, 'Checking that there was no error');

like($dsd->uri, '/^file:.*simple3.xml$/', 'Checking URI of the DSD');
is($dsd->md5_hex, 'e9ff60dcae73d65bda23145346b580df',
	'Checking MD5 of the DSD');

my $out_content = <<'EOF';
<?xml version="1.0"?>
<application>
	<found>
		<dept/>
		<date/>
		<list>
			<person>
		<id/>
		<first_name/>
		<middle_name/>
		<last_name/>
	</person>
		</list>
	</found>

	<auth_user>
		<id/>
		<first_name/>
		<middle_name/>
		<last_name/>
	</auth_user>
</application>
EOF
is($dsd->out_content, $out_content, 'Checking the current content');


ok($dsd = $rayapp->load_dsd("complex_param1.xml"),
	'Loading correct DSD t/complex_param1.xml');
is($rayapp->errstr, undef, 'Checking that there was no error');

like($dsd->uri, '/^file:.*complex_param1.xml$/', 'Checking URI of the DSD');
is($dsd->md5_hex, 'f8cdb7a4e520d3d8bff857d0ee27e804',
	'Checking MD5 of the DSD');
is("@{[ sort keys %{ $dsd->params } ]}", 'action id ns',
	'Checking parameters found');
$params = $dsd->params;
is("@{[ map { qq!$_:$params->{$_}{type}! } sort keys %$params ]}",
	"action:string id:int ns:struct",
	'Checking parameter types');



ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<aftype id="affiliation" multiple="list">
		<id type="int" />
		<name/>
	</aftype>

	<perstype id="person">
		<id type="int"/>
		<first_name/>
		<middle_name/>
		<last_name/>
		<affiliation typeref="#affiliation"/>
	</perstype>

	<output>
		<people typeref="#person" />
		<result type="int"/>
	</output>
</application>
'), 'Loading correct DSD from string');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->uri, 'md5:d8de3b6b5337a4ca0b312133fbb58966',
	'Checking URI/MD5 of the DSD');

$out_content = <<'EOF';
<?xml version="1.0"?>
<application>
	<aftype>
		<id/>
		<name/>
	</aftype>

	<perstype>
		<id/>
		<first_name/>
		<middle_name/>
		<last_name/>
		<affiliation>
		<id/>
		<name/>
	</affiliation>
	</perstype>

	<output>
		<people>
		<id/>
		<first_name/>
		<middle_name/>
		<last_name/>
		<affiliation>
		<id/>
		<name/>
	</affiliation>
	</people>
		<result/>
	</output>
</application>
EOF
is($dsd->out_content, $out_content, 'Checking the current content');



ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<output>
		<person type="hash" attrs="type gold">
			<id type="int" />
			<name gold="yes"/>
			<age type="number"/>
			<car>
				<color />
				<age type="number"/>
				<type/>
			</car>
		</person>
		<result type="int"/>
	</output>
</application>
'), 'Loading correct DSD from string');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->uri, 'md5:aeed5595d4ab07dce072ce1c65625535',
	'Checking URI/MD5 of the DSD');

$out_content = <<'EOF';
<?xml version="1.0"?>
<application>
	<output>
		<person type="hash">
			<id type="int"/>
			<name gold="yes"/>
			<age type="number"/>
			<car>
				<color/>
				<age type="number"/>
				<type/>
			</car>
		</person>
		<result/>
	</output>
</application>
EOF
is($dsd->out_content, $out_content, 'Checking the current content');
is($dsd->serialize_data({ 'result' => 42,
	'person' => {
		id => 243623,
		name => 'Amanda Reese',
		age => 23,
		car => {
			type => 'Honda',
			color => 'white',
			age => 3.5,
			},
		},
	}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<application>
	<output>
		<person type="hash">
			<id type="int">243623</id>
			<name gold="yes">Amanda Reese</name>
			<age type="number">23</age>
			<car>
				<color>white</color>
				<age type="number">3.5</age>
				<type>Honda</type>
			</car>
		</person>
		<result>42</result>
	</output>
</application>
', 'Checking serializing nonscalar data');
is($dsd->errstr, undef, 'Any errstr means bad');

is($dsd->serialize_data({ 'result' => 42,
	'person' => {
		id => 243623,
		name => 'Amanda Reese',
		age => 23,
		},
	}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<application>
	<output>
		<person type="hash">
			<id type="int">243623</id>
			<name gold="yes">Amanda Reese</name>
			<age type="number">23</age>
		</person>
		<result>42</result>
	</output>
</application>
', 'Checking serializing nonscalar data');
is($dsd->errstr, undef, 'Null errstr');

is($dsd->serialize_data({ 'result' => 42,
	'person' => {
		id => 243623,
		name => 'Amanda Reese',
		age => 23,
		car => [ 'white', 6, 'Jeep', ],
		},
	}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<application>
	<output>
		<person type="hash">
			<id type="int">243623</id>
			<name gold="yes">Amanda Reese</name>
			<age type="number">23</age>
			<car>
				<color>white</color>
				<age type="number">6</age>
				<type>Jeep</type>
			</car>
		</person>
		<result>42</result>
	</output>
</application>
', 'Checking serializing nonscalar data');
is($dsd->errstr, undef, 'No errstr');



ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<people multiple="list">
		<id type="int" />
		<name/>
		<age type="number"/>
		<car xattrs="type x">
			<color />
			<age type="number"/>
			<type/>
		</car>
	</people>
</application>
'), 'Loading correct DSD from string');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->uri, 'md5:88303aec4b7b818f8c35f5f9ce8fa512',
	'Checking URI/MD5 of the DSD');

$out_content = <<'EOF';
<?xml version="1.0"?>
<application>
	<people>
		<id/>
		<name/>
		<age/>
		<car>
			<color/>
			<age x="number"/>
			<type/>
		</car>
	</people>
</application>
EOF
is($dsd->out_content, $out_content, 'Checking the current content');
is($dsd->serialize_data({
	'people' => [
			{
			id => 243623,
			name => 'Amanda Reese',
			age => 23,
			car => {
				type => 'Honda',
				color => 'white',
				age => 3.5,
				},
			},
			{
			id => 2413,
			name => 'Harry Burns',	
			age => 25,
			},
			{
			name => 'Sally Allbright',
			car => [ undef, undef, 'Volvo' ],
			id => 882413,
			age => 24,
			},
		]
	}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<application>
	<people>
		<id>243623</id>
		<name>Amanda Reese</name>
		<age>23</age>
		<car>
			<color>white</color>
			<age x="number">3.5</age>
			<type>Honda</type>
		</car>
	</people>
	<people>
		<id>2413</id>
		<name>Harry Burns</name>
		<age>25</age>
	</people>
	<people>
		<id>882413</id>
		<name>Sally Allbright</name>
		<age>24</age>
		<car>
			<type>Volvo</type>
		</car>
	</people>
</application>
', 'Checking serializing nonscalar data');
is($rayapp->errstr, undef, 'Checking that there was no error');
is($dsd->serialize_data({ }), '<?xml version="1.0"?>
<application>
</application>
', 'Serialize data with no people');
is($rayapp->errstr, undef, 'No errstr');
is($dsd->serialize_data({
	people => [],
 }), '<?xml version="1.0"?>
<application>
</application>
', 'Serialize data with empty people');
is($rayapp->errstr, undef, 'No errstr');




ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<people multiple="listelement">
		<person>
			<id type="int" />
			<name/>
			<age type="number"/>
			<car>
				<color />
				<age type="number"/>
				<type/>
			</car>
		</person>
	</people>
</application>
'), 'Loading correct DSD from string');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->uri, 'md5:007b01e09a946e8912b667ab38804b78',
	'Checking URI/MD5 of the DSD');

$out_content = <<'EOF';
<?xml version="1.0"?>
<application>
	<people>
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
	</people>
</application>
EOF
is($dsd->out_content, $out_content, 'Checking the current content');
is($dsd->serialize_data({
	'people' => [
			{
			id => 243623,
			name => 'Amanda Reese',
			age => 23,
			car => {
				type => 'Honda',
				color => 'white',
				age => 3.5,
				},
			},
			{
			id => 2413,
			name => 'Harry Burns',	
			age => 25,
			},
			{
			name => 'Sally Allbright',
			car => [ undef, undef, 'Volvo' ],
			id => 882413,
			age => 24,
			},
		]
	}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<application>
	<people>
		<person>
			<id>243623</id>
			<name>Amanda Reese</name>
			<age>23</age>
			<car>
				<color>white</color>
				<age>3.5</age>
				<type>Honda</type>
			</car>
		</person>
		<person>
			<id>2413</id>
			<name>Harry Burns</name>
			<age>25</age>
		</person>
		<person>
			<id>882413</id>
			<name>Sally Allbright</name>
			<age>24</age>
			<car>
				<type>Volvo</type>
			</car>
		</person>
	</people>
</application>
', 'Checking serializing nonscalar data');
is($rayapp->errstr, undef, 'Checking that there was no error');


ok($dsd = $rayapp->load_dsd('person.xml'),
	'Loading DSD with type personname');
is($rayapp->errstr, undef, 'Should be no errstr');
is($dsd->md5_hex, '5b29696f64657d411d1c13fe40669de3', 'Checking MD5');
is($dsd->out_content, '<?xml version="1.0"?>
<person>
	<_personname>
		<id/>
		<firstname/>
		<middlename/>
		<lastname/>
		<lineage/>
	</_personname>

	<person>
		<personname>
		<id/>
		<firstname/>
		<middlename/>
		<lastname/>
		<lineage/>
	</personname>
	</person>
</person>
', 'Checking content');


ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>

<record>
	<car type="hash">
		<make/>
		<year type="integer"/>
	</car>
	<person typeref="person.xml#personname" />
</record>
'), 'Loading DSD that uses typehref');
is($rayapp->errstr, undef, 'Should be no errstr');
is($dsd->md5_hex, '93048e118ad6af4ab53457d1fe283a63', 'Checking MD5');
is($dsd->out_content, '<?xml version="1.0"?>
<record>
	<car>
		<make/>
		<year/>
	</car>
	<person>
		<id/>
		<firstname/>
		<middlename/>
		<lastname/>
		<lineage/>
	</person>
</record>
', 'Checking content');


is($dsd->serialize_data({
	person => {
		id => 1,
		firstname => 'Amanda',
		lastname => 'Reese',
		},
	car => { make => 'Jeep', year => 1962 },
	}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<record>
	<car>
		<make>Jeep</make>
		<year>1962</year>
	</car>
	<person>
		<id>1</id>
		<firstname>Amanda</firstname>
		<lastname>Reese</lastname>
	</person>
</record>
', 'Checking serializing');
is($dsd->errstr, undef, 'No error message');


is($dsd->serialize_data({
	person => [ 1, 'Amanda', undef, 'Reese' ],
	car => [ 'Jeep', 1962 ],
	}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<record>
	<car>
		<make>Jeep</make>
		<year>1962</year>
	</car>
	<person>
		<id>1</id>
		<firstname>Amanda</firstname>
		<lastname>Reese</lastname>
	</person>
</record>
', 'Checking serializing 2');
is($dsd->errstr, undef, 'No error expected');


ok($dsd = $rayapp->load_dsd('person1.xml'),
	'Loading DSD that uses typehref, from file');
is($rayapp->errstr, undef, 'Should be no errstr');
is($dsd->md5_hex, '1054f4d6b855e175f823b5f6347979e3', 'Checking MD5');
is($dsd->out_content, '<?xml version="1.0"?>
<record>
	<car>
		<make/>
		<year/>
	</car>
	<person>
		<id/>
		<firstname/>
		<middlename/>
		<lastname/>
		<lineage/>
	</person>
</record>
', 'Checking content');
is($dsd->serialize_data({
	person => {
		id => 1,
		firstname => 'Amanda',
		lastname => 'Reese',
		},
	car => { make => 'Jeep', year => 1962 },
	}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<record>
	<car>
		<make>Jeep</make>
		<year>1962</year>
	</car>
	<person>
		<id>1</id>
		<firstname>Amanda</firstname>
		<lastname>Reese</lastname>
	</person>
</record>
', 'Checking serializing');
is($dsd->errstr, undef, 'Errstr should not be set');


is($dsd->serialize_data({
	person => [ 42, 'Amanda', undef, 'Reese' ],
	car => [ 'Jeep', 1962 ],
	}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<record>
	<car>
		<make>Jeep</make>
		<year>1962</year>
	</car>
	<person>
		<id>42</id>
		<firstname>Amanda</firstname>
		<lastname>Reese</lastname>
	</person>
</record>
', 'Checking serializing');
is($dsd->errstr, undef, 'No errstr');


ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<x>
	<record multiple="list">
		<person typeref="person2.xml#person"/>
		<cars multiple="list">
			<make/>
			<year/>
		</cars>
	</record>
</x>
'), 'Load DSD with remote typeref');
is($rayapp->errstr, undef, 'Keep errstr silent');
is($dsd->md5_hex, 'f20cbc941b08b8498dd7906e57cd1192', 'Checking MD5');
is($dsd->out_content, '<?xml version="1.0"?>
<x>
	<record>
		<person>
		<personname>
		<id/>
		<firstname/>
		<middlename/>
		<lastname/>
		<lineage/>
	</personname>
		<age/>
	</person>
		<cars>
			<make/>
			<year/>
		</cars>
	</record>
</x>
', 'Checking content');
is($dsd->serialize_data({
	record => [
		[
			[
				[ 13, 'Amanda', 'X.', 'Reese' ],
				23
			],
			[
				[	'Volvo', 1980	],
				[	'Honda', 1990	],
			],
		],
		undef,
		{
			person => {
				personname => [ 15, 'Sally', undef, 'Albright' ],
				age => 23,
				},
			cars => [
					{
					make => 'GMC',
					year => 1952,
					},
				],
		},
	],
	}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<x>
	<record>
		<person>
		<personname>
		<id>13</id>
		<firstname>Amanda</firstname>
		<middlename>X.</middlename>
		<lastname>Reese</lastname>
	</personname>
		<age>23</age>
	</person>
		<cars>
			<make>Volvo</make>
			<year>1980</year>
		</cars>
		<cars>
			<make>Honda</make>
			<year>1990</year>
		</cars>
	</record>
	<record>
		<person>
		<personname>
		<id>15</id>
		<firstname>Sally</firstname>
		<lastname>Albright</lastname>
	</personname>
		<age>23</age>
	</person>
		<cars>
			<make>GMC</make>
			<year>1952</year>
		</cars>
	</record>
</x>
', 'Checking serializing, lists and all');
is($dsd->errstr, undef, 'No errstr');



ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<text cdata="yes"/>
	<text1 />
	<result type="int"/>
</application>
'), 'Loading DSD with CDATA specifications');
is($rayapp->errstr, undef, 'Should be not error');

is($dsd->md5_hex, '34d45a0fd87b715fb3a34ace820d0597',
	'Checking MD5 of the DSD');
is($dsd->serialize_data({
	'text' => "hola<b>\n']]>hoj<",
	'text1' => "hola<b>\n']]>hoj<",
	'result' => -1
}, { RaiseError => 0, validate => 1 }), q#<?xml version="1.0"?>
<application>
	<text><![CDATA[hola<b>
']]]><![CDATA[]>hoj<]]></text>
	<text1>hola&lt;b&gt;
']]&gt;hoj&lt;</text1>
	<result>-1</result>
</application>
#, 'Serializing');
is($dsd->errstr, undef, 'Want no error message');


ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<p typeref="person3.xml"/>
</application>
'), 'Loading DSD with root typeref leading to another remote typeref');
is($rayapp->errstr, undef, 'Should be not error');
is($dsd->md5_hex, '85f1e21edc3e61422cc157ec7f22612d',
	'Checking MD5 of the DSD');
is($dsd->out_content, '<?xml version="1.0"?>
<application>
	<p>
	<person>
		<id/>
		<firstname/>
		<middlename/>
		<lastname/>
		<lineage/>
	</person>
	<num_of_children/>
</p>
</application>
', 'Checking the content');

is($dsd->serialize_data({
	'p' => {
		num_of_children => 'sixteen',
		person => {
			id => '0987654321',
			firstname => 'Amanda',
			middlename => 'Carol',
			lastname => 'Reese',
			}
		}
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<application>
	<p>
	<person>
		<id>0987654321</id>
		<firstname>Amanda</firstname>
		<middlename>Carol</middlename>
		<lastname>Reese</lastname>
	</person>
	<num_of_children>sixteen</num_of_children>
</p>
</application>
', 'Serializing');
is($dsd->errstr, undef, 'Errstr expected undef');


ok($dsd = $rayapp->load_dsd_string('
<r>
	<_param name="a"/>
	<_param prefix="xxx:"/>
</r>
'), 'Loading DSD with prefix parameter');
is($rayapp->errstr, undef, 'Should be not error');
is($dsd->uri, 'md5:c7c3b1f2a38c0ceae4dd8d1950c5a621',
	'Checking URI/MD5 of the DSD');
is($dsd->out_content, '<?xml version="1.0"?>
<r>
</r>
', 'Checking the structure');

is("@{[ sort keys %{ $dsd->params } ]}", "a",
	'Checking parameter found');
is("@{[ sort keys %{ $dsd->param_prefixes } ]}", "xxx:",
	'Checking parameter prefix found');



ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<output multiple="listelement">
	<rec>
		<person type="hash">
			<id type="int" />
			<name/>
		</person>
		<result type="int"/>
	</rec>
</output>
'), 'Loading correct DSD from string, with list data');
is($rayapp->errstr, undef, 'Checking that there was no error');
is($dsd->uri, 'md5:b417c682d4c94a80e42b97d48827c35b',
        'Checking URI/MD5 of the DSD');
is($dsd->serialize_data({
	'output' => [
		{ person => [ 1234, 'Sally' ], result => 4321 },
		[ [ 4567, 'Harry' ], 7654 ],
		{ },
		[ ],
		{ person => [ 9876, 'Amanda' ], result => 6789 },
		[ { name => 'Marie', id => 7777 } ],
		[ undef, 3645 ],
		{ result => 3645 },
		]
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<output>
	<rec>
		<person>
			<id>1234</id>
			<name>Sally</name>
		</person>
		<result>4321</result>
	</rec>
	<rec>
		<person>
			<id>4567</id>
			<name>Harry</name>
		</person>
		<result>7654</result>
	</rec>
	<rec>
	</rec>
	<rec>
	</rec>
	<rec>
		<person>
			<id>9876</id>
			<name>Amanda</name>
		</person>
		<result>6789</result>
	</rec>
	<rec>
		<person>
			<id>7777</id>
			<name>Marie</name>
		</person>
	</rec>
	<rec>
		<result>3645</result>
	</rec>
	<rec>
		<result>3645</result>
	</rec>
</output>
', 'Checking with various list data');
is($dsd->errstr, undef, 'Errstr should stay unset');

ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<g>
	<p if="result">
		<result type="int"/>
		<name />
	</p>
</g>
'), 'Loading correct DSD from string, with conditions');
is($rayapp->errstr, undef, 'Checking that there was no error');
is($dsd->uri, 'md5:dc455c5cc77fe48d8ab9fa2e896e024c',
        'Checking URI/MD5 of the DSD');
is($dsd->serialize_data({
	'result' => 12,
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<g>
	<p>
		<result>12</result>
	</p>
</g>
', 'Checking serialization with condition matched');
is($dsd->errstr, undef, 'Is errstr still cool?');


is($dsd->serialize_data({
	'result' => 12,
	'name' => 16,
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<g>
	<p>
		<result>12</result>
		<name>16</name>
	</p>
</g>
', 'Checking another serialization with condition matched');
is($dsd->errstr, undef, 'Want errstr unset');

is($dsd->serialize_data({
	'name' => 16,
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<g>
</g>
', 'Checking serialization with condition failed');
is($dsd->errstr, undef, 'No errstr');


ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<g>
	<p if="_data">
		<result type="int"/>
		<_data name="_data" />
		<_data name="name" />
	</p>
</g>
'), 'Loading correct DSD from string, with conditions and _data');
is($rayapp->errstr, undef, 'Checking that there was no error');
is($dsd->uri, 'md5:b91a94c07931932fb92d6416dc0a23ca',
        'Checking URI/MD5 of the DSD');
is($dsd->serialize_data({
	'result' => 12,
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<g>
</g>
', 'Checking serialization with condition failed');
is($dsd->errstr, undef, 'No errstr set');

is($dsd->serialize_data({
	'result' => 12,
	'name' => 16,
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<g>
</g>
', 'Checking another serialization with condition failed');
is($dsd->errstr, undef, 'Errstr should stay unset');

is($dsd->serialize_data({
	'_data' => '_data',
	'name' => 16,
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<g>
	<p>
		<_data>_data</_data>
		<name>16</name>
	</p>
</g>
', 'Checking serialization with condition matched');
is($dsd->errstr, undef, 'Errstr should stay unset');


ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<g>
	<p if="result">
		<result type="int"/>
		<car type="struct">
			<engine>
				<name />
			</engine>
		</car>
	</p>
</g>
'), 'Loading correct DSD with condition and deep structure');
is($rayapp->errstr, undef, 'Checking that there was no error');
is($dsd->uri, 'md5:73e48b24b6a1a1415c70a60979034eeb',
        'Checking URI/MD5 of the DSD');

ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<g>
	<p if="result">
		<result type="int"/>
		<name />
	</p>
	<q if="name">
		<result type="int"/>
		<name />
	</q>
</g>
'), 'Loading correct DSD with conditions');
is($rayapp->errstr, undef, 'Checking that there was no error');
is($dsd->uri, 'md5:09840ed0c31fb6d6fce9164561cde959',
        'Checking URI/MD5 of the DSD');

ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<g>
	<a>
		<p if="result">
			<result type="int"/>
			<name />
		</p>
		<q if="name">
			<result type="int"/>
			<name />
		</q>
	</a>
	<r if="name">
		<result type="int"/>
		<name />
	</r>
</g>
'), 'Loading correct DSD with conditions');
is($rayapp->errstr, undef, 'Checking that there was no error');
is($dsd->uri, 'md5:abd0a829b8cd322bc01a8d89becd5d94',
        'Checking URI/MD5 of the DSD');

ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<g>
	<a multiple="list" />
</g>
'), 'Loading correct DSD with simple simple list');
is($rayapp->errstr, undef, 'Checking that there was no error');
is($dsd->uri, 'md5:9d4ab423fe8144b08ed02745250528fc',
        'Checking URI/MD5 of the DSD');
is($dsd->serialize_data({
	'a' => [ 1, "45", 45, "Amanda" ],
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<g>
	<a>1</a>
	<a>45</a>
	<a>45</a>
	<a>Amanda</a>
</g>
', 'Checking serialization with simple simple list');
is($rayapp->errstr, undef, 'Checking no error message');






ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<g>
	<p if="a">
		<a multiple="list" />
	</p>
</g>
'), 'Loading correct DSD with condition about list');
is($rayapp->errstr, undef, 'Checking that there was no error');
is($dsd->uri, 'md5:70d800af3565547031ed2725556abdcd',
        'Checking URI/MD5 of the DSD');
is($dsd->serialize_data({
        'a' => [ 1, "45", 45, "Amanda" ],
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<g>
	<p>
		<a>1</a>
		<a>45</a>
		<a>45</a>
		<a>Amanda</a>
	</p>
</g>
', 'Checking serialization with simple list');
is($rayapp->errstr, undef, 'Checking no error message');
                                                                                                                                                                   
is($dsd->serialize_data({
        'a' => [ ],
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<g>
</g>
', 'Checking serialization with empty list');
is($rayapp->errstr, undef, 'Checking no error message');
                                                                                                                                                                   
is($dsd->serialize_data({
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<g>
</g>
', 'Checking serialization with undef list');
is($rayapp->errstr, undef, 'Checking no error message');
                                                                                                                                                                   
                                                                                                                                                                   

ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<g>
	<p if="tst">
		<result type="int"/>
		<name />
	</p>
</g>
'),
'Loading correct DSD from string, with tst not being a top-level placeholder');
is($rayapp->errstr, undef, 'Checking that there was no error');
is($dsd->uri, 'md5:b8b0a12e2f020098493e04ba7c0bacca',
	'Checking URI/MD5 of the DSD');
is($dsd->serialize_data({
	'result' => 12,
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<g>
</g>
', 'Checking serialization with condition failed');
is($dsd->errstr, undef, 'No error expected');
is($dsd->serialize_data({
	'tst' => 23,
}, { RaiseError => 0, validate => 1 }), '<?xml version="1.0"?>
<g>
	<p>
	</p>
</g>
', 'Checking serialization with condition failed');
is($dsd->errstr, undef, 'No error expected');



ok($dsd = $rayapp->load_dsd('example_findpeople.xml'),
	'Loading correct DSD with findpeople example');
is($rayapp->errstr, undef, 'Checking that there was no error');
is($dsd->md5_hex, '4a0344ee86916145d7ed1ecc23fa2a93',
	'Checking MD5');
like($dsd->uri, '/^file:.*t\/example_findpeople.xml$/',
        'Checking URI');
is($dsd->out_content, '<?xml version="1.0"?>
<findpeople>
	<people>
		<person>
			<id/>
			<fullname/>
			<affiliation>
				<id/>
				<deptname/>
				<function/>
			</affiliation>
		</person>
	</people>

	<person>
		<id/>
		<fullname/>
		<major_affiliation>
				<id/>
				<deptname/>
				<function/>
			</major_affiliation>
		<studies>
			<id/>
			<deptid/>
			<deptname/>
			<programid/>
			<programcode/>
			<programname/>
		</studies>
	</person>
</findpeople>
', 'Checking the content');



is($dsd->serialize_data( {
        'people' => [
                {
                        'id' => 25132,
                        'fullname' => 'Rebeca Milton',
                },
                {
                        'id' => 63423,
                        'fullname' => 'Amanda Reese',
                        'affiliation' => [
                                        [ 1323, 'Department of Medieval History' ],
                                ],
                },
                {
                        'id' => 1883,
                        'fullname' => "John O'Reilly",
                        'affiliation' => [
                                        [ 2534, 'Department of Chemistry' ],
                                        [ 15, 'Microbiology Institute' ],
                                ],
                },
                ]
        }, { RaiseError => 0, validate => 1 }
), qq!<?xml version="1.0"?>
<findpeople>
	<people>
		<person>
			<id>25132</id>
			<fullname>Rebeca Milton</fullname>
		</person>
		<person>
			<id>63423</id>
			<fullname>Amanda Reese</fullname>
			<affiliation>
				<id>1323</id>
				<deptname>Department of Medieval History</deptname>
			</affiliation>
		</person>
		<person>
			<id>1883</id>
			<fullname>John O'Reilly</fullname>
			<affiliation>
				<id>2534</id>
				<deptname>Department of Chemistry</deptname>
			</affiliation>
			<affiliation>
				<id>15</id>
				<deptname>Microbiology Institute</deptname>
			</affiliation>
		</person>
	</people>
</findpeople>
!, 'Checking serialization with list data');
is($dsd->errstr, undef, 'No errstr');

is($dsd->serialize_data( {
        'id' => 1883,
        'fullname' => "John O'Reilly",
        'major_affiliation' =>
		{
			'id' => 2534,
			'deptname' => 'Department of Chemistry',
			'function' => 'Head of department',
		},
}, { RaiseError => 0, validate => 1 }), q!<?xml version="1.0"?>
<findpeople>
	<person>
		<id>1883</id>
		<fullname>John O'Reilly</fullname>
		<major_affiliation>
				<id>2534</id>
				<deptname>Department of Chemistry</deptname>
				<function>Head of department</function>
			</major_affiliation>
	</person>
</findpeople>
!, 'Checking serialization with one person data');
is($dsd->errstr, undef, 'Check errstr');


is($dsd->serialize_data( {}, { RaiseError => 0, validate => 1 } ),
'<?xml version="1.0"?>
<findpeople>
</findpeople>
', 'Checking serialization with no data');
is($dsd->errstr, undef, 'Check error message');

ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<root>
	<id type="int" id="id"/>
	<a typeref="#id"/>
</root>
'), 'Load DSD with typeref');
is($rayapp->errstr, undef, 'No errstr expected');

is($dsd->serialize_data({ 'a' => 56 }, { RaiseError => 0, validate => 1 }),
'<?xml version="1.0"?>
<root>
	<a>56</a>
</root>
', 'Serialize the data');
is($dsd->errstr, undef, 'No errstr expected for serialization');

is($dsd->serialize_data({ 'a' => 'x' }, { RaiseError => 0, validate => 1 }),
'<?xml version="1.0"?>
<root>
</root>
', 'Now, give it a string (where integer expected)');
is($dsd->errstr,
	"Value 'x' of {a} is not integer for data element defined at line 4",
	'It should complain');


ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<root>
	<v multiple="hash" hashorder="num">
		<name/>
		<age type="int"/>
	</v>
	<w multiple="hashelement" hashorder="string">
		<el>
			<name/>
			<age type="int"/>
		</el>
	</w>
	<x multiple="hash" type="int" hashorder="num"/>
	<y multiple="hash" hashorder="string"/>
</root>
'), 'Loading DSD with hash and hashelements from string');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->uri, 'md5:818e3c7acefa4a8a824d813722616669',
	'Checking URI/MD5 of the DSD');

$out_content = <<'EOF';
<?xml version="1.0"?>
<root>
	<v>
		<name/>
		<age/>
	</v>
	<w>
		<el>
			<name/>
			<age/>
		</el>
	</w>
	<x/>
	<y/>
</root>
EOF
is($dsd->out_content, $out_content, 'Checking the current content');
is($dsd->serialize_data({
	'y' => { 'a' => 'ax', 'b' => 'bx', 'c' => 'cx', },
	'x' => { '46' => 46, '3.4' => 34, '16' => 16, },
	'w' => {
		-45 => [ 'Peter', 16, ],
		'g' => [ 'John', 17 ],
		'-4.5' => {
			'age' => 3, 'name' => 'Kate',
			},
		},
	'v' => {
		-45 => [ 'Peter', 16, ],
		'g' => [ 'John', 17 ],
		'-4.5' => {
			'age' => 3, 'name' => 'Kate',
			},
		},
	}, { RaiseError => 0, validate => 1 }),
'<?xml version="1.0"?>
<root>
	<v id="-45">
		<name>Peter</name>
		<age>16</age>
	</v>
	<v id="-4.5">
		<name>Kate</name>
		<age>3</age>
	</v>
	<v id="g">
		<name>John</name>
		<age>17</age>
	</v>
	<w>
		<el id="-4.5">
			<name>Kate</name>
			<age>3</age>
		</el>
		<el id="-45">
			<name>Peter</name>
			<age>16</age>
		</el>
		<el id="g">
			<name>John</name>
			<age>17</age>
		</el>
	</w>
	<x id="3.4">34</x>
	<x id="16">16</x>
	<x id="46">46</x>
	<y id="a">ax</y>
	<y id="b">bx</y>
	<y id="c">cx</y>
</root>
', 'Check multiple hash serialization');
is($dsd->errstr, undef, 'Expecting no error');


ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<root><v multiple="hash"/></root>
'), 'Loading DSD with hashes with natural order from string');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->uri, 'md5:e457b01b94cecfcdb25b4e0abf3ca63f',
	'Checking URI/MD5 of the DSD');

$out_content = <<'EOF';
<?xml version="1.0"?>
<root>
  <v/>
</root>
EOF
is($dsd->out_content, $out_content, 'Checking the current content');
like($dsd->serialize_data({
	'v' => { -1 => 1, -2 => 2 }
	}, { RaiseError => 0, validate => 1 }),
'/^(<\?xml version="1.0"\?>
<root>\s*<v id="-1">1<\\/v>\s*<v id="-2">2<\\/v>\s*<\\/root>|<\?xml version="1.0"\?>
<root>\s*<v id="-2">2<\\/v>\s*<v id="-1">1<\\/v>\s*<\\/root>)
$/',
	'Check result serialization');
is($dsd->errstr, undef, 'Still no error');




ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<root>
	<r idattr="j" multiple="hash" type="int" hashorder="num"/>
	<v idattr="i" multiple="hashelement" hashorder="string">
		<w type="num"/>
	</v>
</root>
'), 'Loading DSD with hashes with idattr');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->uri, 'md5:05b830d5221596387afbf1f8a81bc4c7',
	'Checking URI/MD5 of the DSD');

$out_content = <<'EOF';
<?xml version="1.0"?>
<root>
	<r/>
	<v>
		<w/>
	</v>
</root>
EOF
is($dsd->out_content, $out_content, 'Checking the current content');
is($dsd->serialize_data({
	'r' => { -1 => 1, -2 => 2 },
	'v' => { 'a' => 1, 'b' => 2 },
	}, { RaiseError => 0, validate => 1 }),
'<?xml version="1.0"?>
<root>
	<r j="-2">2</r>
	<r j="-1">1</r>
	<v>
		<w i="a">1</w>
		<w i="b">2</w>
	</v>
</root>
',
	'Check serialization');
is($rayapp->errstr, undef, 'No error');

ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<root>
	<r if="a"><ma/></r>
	<s ifdef="b"><mb/></s>
	<t ifnot="c"><mc/></t>
	<u ifnotdef="d"><md/></u>
</root>
'), 'Loading DSD with hashes with conditions');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->uri, 'md5:01676d650f6fdcf25fafc775a24446a5',
	'Checking URI/MD5 of the DSD');

$out_content = <<'EOF';
<?xml version="1.0"?>
<root>
	<r><ma/></r>
	<s><mb/></s>
	<t><mc/></t>
	<u><md/></u>
</root>
EOF
is($dsd->out_content, $out_content, 'Checking the current content');
is($dsd->serialize_data({
	a => 1, ma => 9,
	b => 1, mb => 9,
	c => 1, mc => 9,
	d => 1, md => 9,
	}, { RaiseError => 0, validate => 1 }),
'<?xml version="1.0"?>
<root>
	<r><ma>9</ma></r>
	<s><mb>9</mb></s>
</root>
',
	'Check serialization with 1');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->serialize_data({
	a => undef, ma => 9,
	b => undef, mb => 9,
	c => undef, mc => 9,
	d => undef, md => 9,
	}, { RaiseError => 0, validate => 1 }),
'<?xml version="1.0"?>
<root>
	<t><mc>9</mc></t>
	<u><md>9</md></u>
</root>
',
	'Check serialization with undef');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->serialize_data({
	a => 0, ma => 9,
	b => 0, mb => 9,
	c => 0, mc => 9,
	d => 0, md => 9,
	}, { RaiseError => 0, validate => 1 }),
'<?xml version="1.0"?>
<root>
	<s><mb>9</mb></s>
	<t><mc>9</mc></t>
</root>
',
	'Check serialization with zero');
is($rayapp->errstr, undef, 'Checking that there was no error');



ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<root application="1" xmlns="urn:x-x">
	<html:b xmlns:html="http://www.w3.org/1999/xhtml" />
	<s type="struct"><mb/></s>
</root>
'), 'Loading DSD with hashes with namespaces');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->uri, 'md5:170ef84d02264e6c7b0b8169365e31d5',
	'Checking URI/MD5 of the DSD');

is($dsd->out_content, '<?xml version="1.0"?>
<root xmlns="urn:x-x">
	<html:b xmlns:html="http://www.w3.org/1999/xhtml"/>
	<s><mb/></s>
</root>
', 'Checking the current content');
is($dsd->serialize_data({
	'html:b' => 'X',
	s => { mb => 34 },
	}, { RaiseError => 0, validate => 1 }),
'<?xml version="1.0"?>
<root xmlns="urn:x-x">
	<html:b xmlns:html="http://www.w3.org/1999/xhtml">X</html:b>
	<s><mb>34</mb></s>
</root>
', 'Serialization with data with colons');
is($rayapp->errstr, undef, 'No error still?');


ok($dsd = $rayapp->load_dsd('create_domain.dsd'),
	'Loading DSD for CZ-NIC create domain command');
is($rayapp->errstr, undef, 'Check errstr');
is($dsd->serialize_data({
	'dsdDomain:name' => 'asdf.cz',
	'dsdDomain:description' => 'The ASDF is core of it all',
	'dsdDomain:idadm' => 'ASDF',
	'dsdDomain:idtech' => 'ASDF',
	'dsdDomain:period' => 2,
	'dsdDomain:nserver' => [
		[ 'ns.asdf.cz', [ '111.111.111.111', '222.222.222.222' ], 'P' ],
		[ 'ns.server.cz', undef, 'S' ],
		],
	'clTRID' => 'Ticket-1',
	}, { RaiseError => 0, validate => 1 }),
'<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">
  <command>
    <create>
      <dsdDomain:create xmlns:dsdDomain="urn:cznic:params:xml:ns:dsdDomain-1.0" xsi:schemaLocation="urn:cznic:params:xml:ns:dsdDomain-1.0 dsdDomain-1.0.xsd">
        <dsdDomain:name>asdf.cz</dsdDomain:name>
        <dsdDomain:description>The ASDF is core of it all</dsdDomain:description>
        <dsdDomain:idadm>ASDF</dsdDomain:idadm>
        <dsdDomain:idtech>ASDF</dsdDomain:idtech>
        <dsdDomain:period unit="y">2</dsdDomain:period>
        <dsdDomain:dns>
          <dsdDomain:nserver>
            <dsdDomain:ns>ns.asdf.cz</dsdDomain:ns>
            <dsdDomain:IPaddress ip="v4">111.111.111.111</dsdDomain:IPaddress>
            <dsdDomain:IPaddress ip="v4">222.222.222.222</dsdDomain:IPaddress>
            <dsdDomain:typ>P</dsdDomain:typ>
          </dsdDomain:nserver>
          <dsdDomain:nserver>
            <dsdDomain:ns>ns.server.cz</dsdDomain:ns>
            <dsdDomain:typ>S</dsdDomain:typ>
          </dsdDomain:nserver>
        </dsdDomain:dns>
      </dsdDomain:create>
    </create>
    <clTRID>Ticket-1</clTRID>
  </command>
</epp>
', 'Serialization with domain data');
is($rayapp->errstr, undef, 'No error still?');

ok($dsd = $rayapp->load_dsd('create_domain.dsd'),
	'Loading DSD for CZ-NIC create domain command');


ok($dsd = $rayapp->load_uri('nonxml.xml'),
	'Loading file which is not DSD and should not be processed as one');
is($rayapp->errstr, undef, 'Check errstr');
is($dsd->content, "This file is not XML.\n", 'Test the text content');

is(scalar keys %{ $rayapp->{uris} }, 37,
	'Total number of distinct URIs processed');


ok($dsd = $rayapp->load_dsd('script1.dsd'), 'Loading correct DSD from string');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($dsd->md5_hex, '113833fe853620287de9005698e3066a',
	'Checking MD5 of the DSD');

like($dsd->application_name, '/t\/script1\.pl/', 'Checking application name');

my $appretval = $rayapp->execute_application_handler($dsd);
ok($appretval, 'Executing the application -- checking true return value');
ok(ref $appretval,
	'Executing the application -- checking that the return is a reference');

my $outxml = $dsd->serialize_data($appretval,
	{ RaiseError => 0, validate => 1 });
is ($outxml, '<?xml version="1.0" standalone="yes"?>
<list>
	<students>
		<student>
			<lastname>Peter</lastname>
			<firstname>Wolf</firstname>
		</student>
		<student>
			<lastname>Brian</lastname>
			<firstname>Fox</firstname>
		</student>
		<student>
			<lastname>Leslie</lastname>
			<firstname>Child</firstname>
		</student>
		<student>
			<lastname>Barbara</lastname>
			<firstname>Bailey</firstname>
		</student>
		<student>
			<lastname>Russell</lastname>
			<firstname>King</firstname>
		</student>
		<student>
			<lastname>Michael</lastname>
			<firstname>Johnson</firstname>
		</student>
		<student>
			<lastname>Michael</lastname>
			<firstname>Shell</firstname>
		</student>
		<student>
			<lastname>Tim</lastname>
			<firstname>Jasmine</firstname>
		</student>
	</students>

	<program>
		<id>1523</id>
		<code>8234B</code>
		<name>&#x160;&#xED;len&#xE9; lan&#x11B;</name>
	</program>
</list>
', 'Checking that the output values are correct by serializing');
is($dsd->errstr, undef, 'No errstr');

$outxml = $dsd->serialize_data_dom($appretval,
	{ RaiseError => 0, validate => 1 });
ok($outxml, 'Checking that the serialization to DOM is also OK.');
is(ref $outxml, 'XML::LibXML::Document', 'Checking that the ref is correct.');
is($dsd->errstr, undef, 'No errstr?');


use XML::LibXSLT;
my $xslt = new XML::LibXSLT;
ok($xslt, 'Checking that the XML::LibXSLT parser was created OK.');
my $style = $xslt->parse_stylesheet_file('script1.xsl');
ok($style, 'Loading the t/script1.xsl stylesheet');

my $results = $style->transform($outxml);
ok($results, 'Running transformation');
is($results->toString, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<html><head><title/></head><body><h1>A list of students</h1><p>
Study program:
<b>Šílené laně</b>
(<tt>8234B</tt>)
</p><ul>
		<li>Wolf Peter</li>
		<li>Fox Brian</li>
		<li>Child Leslie</li>
		<li>Bailey Barbara</li>
		<li>King Russell</li>
		<li>Johnson Michael</li>
		<li>Shell Michael</li>
		<li>Jasmine Tim</li>
	</ul></body></html>
', 'Checking the output HTML');

TODO: {

todo_skip 'No Storable thingies', 5;

$appretval = $rayapp->execute_application_process_storable($dsd);
ok($appretval, 'Executing the application -- checking true return value');
ok(ref $appretval,
	'Executing the application -- checking that the return is a reference');

$outxml = $dsd->serialize_data($appretval, { RaiseError => 0, validate => 1 });
is($outxml, '<?xml version="1.0" standalone="yes"?>
<list>
	<students>
		<student>
			<lastname>Peter</lastname>
			<firstname>Wolf</firstname>
		</student>
		<student>
			<lastname>Brian</lastname>
			<firstname>Fox</firstname>
		</student>
		<student>
			<lastname>Leslie</lastname>
			<firstname>Child</firstname>
		</student>
		<student>
			<lastname>Barbara</lastname>
			<firstname>Bailey</firstname>
		</student>
		<student>
			<lastname>Russell</lastname>
			<firstname>King</firstname>
		</student>
		<student>
			<lastname>Michael</lastname>
			<firstname>Johnson</firstname>
		</student>
		<student>
			<lastname>Michael</lastname>
			<firstname>Shell</firstname>
		</student>
		<student>
			<lastname>Tim</lastname>
			<firstname>Jasmine</firstname>
		</student>
	</students>

	<program>
		<id>1523</id>
		<code>8234B</code>
		<name>Biology</name>
	</program>
</list>
', 'Checking that the output values are correct by serializing');
is($dsd->errstr, undef, 'Check no error message appeared');

$outxml = $dsd->serialize_data_dom($appretval,
	{ RaiseError => 0, validate => 1 });
ok($outxml, 'Checking that the serialization to DOM is also OK.');
is(ref $outxml, 'XML::LibXML::Document', 'Checking that the ref is correct.');
is($dsd->errstr, undef, 'Look at errstr');

$results = $style->transform($outxml);
ok($results, 'Running transformation');
is($results->toString, '<?xml version="1.0" standalone="yes"?>
<html><head><title/></head><body><h1>A list of students</h1><p>
Study program:
<b>Biology</b>
(<tt>8234B</tt>)
</p><ul>
		<li>Wolf Peter</li>
		<li>Fox Brian</li>
		<li>Child Leslie</li>
		<li>Bailey Barbara</li>
		<li>King Russell</li>
		<li>Johnson Michael</li>
		<li>Shell Michael</li>
		<li>Jasmine Tim</li>
	</ul></body></html>
', 'Checking the output HTML');

}

$appretval = $rayapp->execute_application_handler_reuse($dsd);
ok($appretval, 'Executing the application -- checking true return value');
ok(ref $appretval,
	'Executing the application -- checking that the return is a reference');
$outxml = $dsd->serialize_data_dom($appretval,
	{ RaiseError => 0, validate => 1 });
ok($outxml, 'Checking that the serialization to DOM is also OK.');
is(ref $outxml, 'XML::LibXML::Document', 'Checking that the ref is correct.');
is($dsd->errstr, undef, 'No errstr?');

$results = $style->transform($outxml);
ok($results, 'Running transformation');
is(Encode::decode('utf-8', $results->toString),
'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<html><head><title/></head><body><h1>A list of students</h1><p>
Study program:
<b>Šílené laně</b>
(<tt>8234B</tt>)
</p><ul>
		<li>Wolf Peter</li>
		<li>Fox Brian</li>
		<li>Child Leslie</li>
		<li>Bailey Barbara</li>
		<li>King Russell</li>
		<li>Johnson Michael</li>
		<li>Shell Michael</li>
		<li>Jasmine Tim</li>
	</ul></body></html>
', 'Checking the output HTML');

$appretval = $rayapp->execute_application_handler_reuse($dsd);
ok($appretval, 'Executing the application -- checking true return value');
ok(ref $appretval,
	'Executing the application -- checking that the return is a reference');
$outxml = $dsd->serialize_data_dom($appretval,
	{ RaiseError => 0, validate => 1 });
ok($outxml, 'Checking that the serialization to DOM is also OK.');
is(ref $outxml, 'XML::LibXML::Document', 'Checking that the ref is correct.');
is($dsd->errstr, undef, 'Expected clear error message');

$results = $style->transform($outxml);
ok($results, 'Running transformation');
is(Encode::decode('utf-8', $results->toString),
'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<html><head><title/></head><body><h1>A list of students</h1><p>
Study program:
<b>Šílené laně</b>
(<tt>8234B</tt>)
</p><ul>
		<li>Wolf Peter</li>
		<li>Fox Brian</li>
		<li>Child Leslie</li>
		<li>Bailey Barbara</li>
		<li>King Russell</li>
		<li>Johnson Michael</li>
		<li>Shell Michael</li>
		<li>Jasmine Tim</li>
	</ul></body></html>
', 'Checking the output HTML');

my $out = $dsd->serialize_style(
	{
	program => [ 2534, 'X' ],
	students => [ [ 'A', 'B' ] ],
	}, {}, 'script1.xsl');
is($out, '<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title></title>
</head>
<body>
<h1>A list of students</h1>
<p>
Study program:
<b></b>
(<tt>X</tt>)
</p>
<ul>
		<li>B A</li>
	</ul>
</body>
</html>
', 'Serializing and styling');
is($dsd->errstr, undef, 'Check errstr');


=comment

TODO: {
local $TODO = 'rayapp_cgi_wrapper not ready for prime time yet';

$ENV{RAYAPP_DIRECTORY} = Cwd::getcwd();
if (${^TAINT}) {
	$^X =~ /^(.+)$/ and $^X = $1;
	delete @ENV{'PATH', 'ENV'};
}
my $extout = `$^X ../../bin/rayapp_cgi_wrapper script2.xml`;
is($extout, 'Pragma: no-cache
Cache-control: no-cache
Status: 200
Content-Type: text/xml; charset=UTF-8

<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<list>
	<students>
		<student>
			<lastname>Peter</lastname>
			<firstname>Wolf</firstname>
		</student>
		<student>
			<lastname>Brian</lastname>
			<firstname>Fox</firstname>
		</student>
		<student>
			<lastname>Leslie</lastname>
			<firstname>Child</firstname>
		</student>
		<student>
			<lastname>Barbara</lastname>
			<firstname>Bailey</firstname>
		</student>
		<student>
			<lastname>Russell</lastname>
			<firstname>King</firstname>
		</student>
		<student>
			<lastname>Michael</lastname>
			<firstname>Johnson</firstname>
		</student>
		<student>
			<lastname>Michael</lastname>
			<firstname>Shell</firstname>
		</student>
		<student>
			<lastname>Tim</lastname>
			<firstname>Jasmine</firstname>
		</student>
	</students>

	<program>
		<id>1523</id>
		<code>8234B</code>
		<name>Šílené laně</name>
	</program>
</list>
', 'Running rayapp_cgi_wrapper');




$extout = `../../bin/rayapp_cgi_wrapper script2.xml`;
is($extout, 'Pragma: no-cache
Cache-control: no-cache
Status: 200
Content-Type: text/xml

<?xml version="1.0" standalone="yes"?>
<list>
	<students>
		<student>
			<lastname>Peter</lastname>
			<firstname>Wolf</firstname>
		</student>
		<student>
			<lastname>Brian</lastname>
			<firstname>Fox</firstname>
		</student>
		<student>
			<lastname>Leslie</lastname>
			<firstname>Child</firstname>
		</student>
		<student>
			<lastname>Barbara</lastname>
			<firstname>Bailey</firstname>
		</student>
		<student>
			<lastname>Russell</lastname>
			<firstname>King</firstname>
		</student>
		<student>
			<lastname>Michael</lastname>
			<firstname>Johnson</firstname>
		</student>
		<student>
			<lastname>Michael</lastname>
			<firstname>Shell</firstname>
		</student>
		<student>
			<lastname>Tim</lastname>
			<firstname>Jasmine</firstname>
		</student>
	</students>

	<program>
		<id>1523</id>
		<code>8234B</code>
		<name>&#x160;&#xED;len&#xE9; lan&#x11B;</name>
	</program>
</list>
', 'Running RayApp::CGI without stylesheets');

$ENV{RAYAPP_HTML_STYLESHEETS} = 'script1.xsl';
$extout = `../../bin/rayapp_cgi_wrapper script1.html`;
utf8::encode($extout);
is($extout, 'Pragma: no-cache
Cache-control: no-cache
Status: 200
Content-Type: text/html; charset=UTF-8

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title></title>
</head>
<body>
<h1>A list of students</h1>
<p>
Study program:
<b>Šílené laně</b>
(<tt>8234B</tt>)
</p>
<ul>
		<li>Wolf Peter</li>
		<li>Fox Brian</li>
		<li>Child Leslie</li>
		<li>Bailey Barbara</li>
		<li>King Russell</li>
		<li>Johnson Michael</li>
		<li>Shell Michael</li>
		<li>Jasmine Tim</li>
	</ul>
</body>
</html>
', 'Running RayApp::CGI with implicit stylesheet');

$extout = `../../bin/rayapp_cgi_wrapper script2.html`;
is($extout, 'Pragma: no-cache
Cache-control: no-cache
Status: 200
Content-Type: text/html; charset=UTF-8

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title></title>
</head>
<body>
<h1>A list of students</h1>
<p>
Study program:
<b>Šílené laně</b>
(<tt>8234B</tt>)
</p>
<ul>
		<li>Wolf Peter</li>
		<li>Fox Brian</li>
		<li>Child Leslie</li>
		<li>Bailey Barbara</li>
		<li>King Russell</li>
		<li>Johnson Michael</li>
		<li>Shell Michael</li>
		<li>Jasmine Tim</li>
	</ul>
</body>
</html>
', 'Running RayApp::CGI with a stylesheet');

}

=cut

