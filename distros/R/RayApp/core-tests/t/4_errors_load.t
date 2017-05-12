#!/usr/bin/perl -Tw

use Test::More tests => 58;

use warnings;
$^W = 1;
use strict;

BEGIN { use_ok( 'RayApp' ); }

chdir 't' if -d 't';

my $rayapp = new RayApp(
	ua_options => {
		timeout => 5,
		},
	);
isa_ok($rayapp, 'RayApp');



is($rayapp->load_dsd("jezek:///krtek/"), undef,
	'Loading DSD with invalid protocol');
like($rayapp->errstr, '/protocol/i',
	'Checking error message for bad protocol');

is($rayapp->load_dsd("nonwellformed.dsd"), undef,
	'Loading non-well-formed DSD');
like($rayapp->errstr, '/tag/i',
	'Checking error message for bad-formed XML');

is($rayapp->load_dsd('http://www.thisdomainhopefullydoesntexist.domain/file.xml'),
	undef, 'Loading DSD with invalid domain name');
like($rayapp->errstr, '/thisdomainhopefullydoesntexist/',
	'Checking error message for bad domain name');


ok($rayapp->load_dsd("simple1.xml"), 'Loading correct DSD');
is($rayapp->errstr, undef, 'Checking that errstr got cleaned');



is($rayapp->load_dsd("t/nonexistent.xml"), undef,
	'Loading nonexistent DSD file, should fail');
like($rayapp->errstr, '/not exist/',
	'Checking error message for nonexistent file');



is($rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<invoice>
		<_param type="int" />
	</id>
</application>
'), undef, 'Loading DSD with non-wellformed XML, should fail');

like($rayapp->errstr, '/tag/', 'Checking error message for bad XML');



is($rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<_param type="int" />
	<_param name="action" />

	<name />
	<result type="int" />
</application>
'), undef, 'Loading DSD with wrong _param specification, should fail');

is($rayapp->errstr, 'Parameter specification lacks attribute name at line 3',
	'Checking error message for missing name');



is($rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<_param name="id" type="int" />
	<_param name="action" />
	<invoice>
		<_param name="host" />
		<_param name="id" />
		<result type="int" />
	</invoice>
</application>
'), undef, 'Loading DSD with duplicate _param specification, should fail');

is($rayapp->errstr,
	'Duplicate specification of parameter id at line 7, previous at line 3',
	'Checking error message for duplicate name');



is($rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<go type="number"/>
	<_type id="one" type="hash">
		<car/>
	</_type>
	<invoice>
		<_type id="one" type="hash">
			<xcar/>
		</_type>
		<_param name="host" />
		<_param name="id" />
		<result type="one" />
	</invoice>
</application>
'), undef, 'Loading DSD with duplicate id specification, should fail');
is($rayapp->errstr,
	'Duplicate id specification at line 8, previous at line 4',
	'Checking error message for duplicate name');



is($rayapp->load_dsd_string('<?xml version="1.0"?>
<_param name="id" type="int" />
'), undef, 'Loading DSD with _param root element');

is($rayapp->errstr, 'Root element cannot be parameter element at line 2',
	'Checking error message for root parameter element');


is($rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<_param name="id" xtype="int"/>
	<name />
</application>
'), undef, 'Loading DSD with _param with broken attribute');

is($rayapp->errstr,
	'Unsupported attribute xtype in parameter id at line 3',
	'Checking error message for _param with broken attribute');



is($rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<_param name="id" xtype="int" jezek="krtek"/>
	<_param name="action" />
	<name />
	<result type="int" />
</application>
'), undef, 'Loading DSD with _param with broken attributes');

is($rayapp->errstr,
	'Unsupported attributes jezek, xtype in parameter id at line 3',
	'Checking error message for parameter with broken attributes');



is($rayapp->load_dsd_string('
<application>
	<name />
	<_data type="int" />
</application>
'), undef, 'Loading DSD with _data with no name');
is($rayapp->errstr, 'Data specification lacks attribute name at line 4',
	'Checking error message for _data with no name');



is($rayapp->load_dsd_string('
<application>
	<_type id="a1">
		<id type="int"/>
		<value type="a2"/>
	</_type>
	<_type id="a2">
		<id type="int"/>
		<value type="a1"/>
	</_type>
</application>
'), undef, 'Loading DSD with bad _type definition');
is($rayapp->errstr, 'Unknown type a2 for data value at line 5',
	'Checking error message for undefined types');

is($rayapp->load_dsd_string('
<application>
	<m id="a1">
		<id type="int"/>
		<value typeref="#a2"/>
	</m>
	<n id="a2">
		<id type="int"/>
		<value typeref="#a1"/>
	</n>
</application>
'), undef, 'Loading DSD with circular typeref definition');
like($rayapp->errstr, '/^(Loop detected while expanding typeref a2 from line 5|Loop detected while expanding typeref a1 from line 9)$/',
	'Checking error message for undefined _type');


is($rayapp->load_dsd_string('
<r>
	<_type id="a2">
		<id type="int"/>
	</_type>
	<x>
		<id type="int"/>
		<value typeref="#a1"/>
	</x>
</r>
'), undef, 'Loading DSD with invalid local typeref');
is($rayapp->errstr, 'No local id a1 found for reference from line 8',
	'Checking error message for invalid local typeref');


is($rayapp->load_dsd_string('
<r>
	<x>
		<id typeref="nonexistent.dsd"/>
	</x>
</r>
'), undef, 'Loading DSD with invalid remote typeref');
like($rayapp->errstr, '/^Error loading DSD .*file.*nonexistent.dsd/i',
	'Checking error message for invalid remote typeref');

is($rayapp->load_dsd_string('
<r>
	<x>
		<id typeref="person.xml#ppp"/>
		<value type="int"/>
	</x>
</r>
'), undef, 'Loading DSD with typehref without type');
like($rayapp->errstr, '/^Remote DSD .*person.xml does not provide id ppp referenced from line 4$/',
	'Checking error message data with typehref without type');


ok($rayapp->load_dsd_string('
<r>
	<x>
		<id type="int"/>
	</x>
</r>
'), 'Loading correct DSD');
is($rayapp->errstr, undef, 'Checking the errstr was cleared');



is($rayapp->load_dsd_string('
<r>
	<x>
		<id typeref="http://www.thisdomainhopefullydoesntexist.domain/file.xml" />
	</x>
</r>
'), undef, 'Loading DSD with bad http typeref');
like($rayapp->errstr,
	'/^Error loading DSD .*thisdomainhopefullydoesntexist/',
	'Checking error message data with typeref pointing to nonexistent domain');


is($rayapp->load_dsd_string('
<x>
	<x>
		<x typeref="jezek:krtek"/>
	</x>
</x>
'), undef, 'Loading DSD with bad typeref');
like($rayapp->errstr,
	'/^Error loading DSD jezek:krtek referenced from line 4: .*jezek/',
	'Checking error message data with typeref with bad protocol');





is($rayapp->load_dsd_string('
<r typeref="circular1.xml#circular1"/>
'), undef, 'Loading DSD with remote circular typerefs');
like($rayapp->errstr,
	'/^Error loading DSD .*circular1.xml .* Error loading/',
	'Checking error message for circular remote typerefs');


is($rayapp->load_dsd_string('
<r typeref="wrong1.xml#rrr"/>
'), undef, 'Loading DSD that referenced bad DSD');
like($rayapp->errstr,
	'/^Error loading.*Unknown type int1/',
	'Checking error message for bad remode DSD');


is($rayapp->load_dsd_string('
<r>
	<_param type="jezek" prefix="p-" />
</r>
'), undef, 'Loading DSD with bad parameter type');
is($rayapp->errstr,
	'Unknown type jezek for parameter with prefix p- at line 3',
	'Checking error message for bad prefix parameter');


is($rayapp->load_dsd_string('
<r multiple="list"/>
'), undef, 'Loading DSD with list root');
is($rayapp->errstr,
	'Root element cannot be list without listelement at line 2',
	'Checking error message for root list node');


is($rayapp->load_dsd_string('<?xml version="1.0"?>
<p if="result">
	<result type="int"/>
	<name />
</p>
'), undef, 'Loading correct DSD with condition on root, should fail');
is($rayapp->errstr, 'Root element cannot be conditional at line 2',
	 'Checking errstr');


is($rayapp->load_dsd_string('<?xml version="1.0"?>
<g>
	<p type="hash" if="result">
		<result type="int"/>
		<name />
	</p>
</g>
'), undef, 'Loading correct DSD with condition on type, should fail');
is($rayapp->errstr, 'Unsupported attribute if in data p at line 3',
	 'Checking errstr');

is($rayapp->load_dsd_string('<?xml version="1.0"?>
<g>
        <p if="result">
                <result type="int"/>
                <car type="struct">
                        <engine if="result">
                                <name />
                        </engine>
                </car>
        </p>
</g>
'), undef, 'Loading correct DSD with condition in deep structure, should fail');
is($rayapp->errstr,
	'Unsupported attribute if in data engine at line 6',
	'Checking errstr');

