use strict;
use warnings;
use Net::Z3950::PQF;

BEGIN {
    use vars qw(@tests);
    @tests = (
	# Simple term
	[ 'water', 'keyword=water' ],

	# Result-set ID
	[ '@set foo', 'cql.resultSetId="bar"' ], # Uses dummy result-set: see below

	# Simple booleans
	[ '@and water air', '(keyword=water and keyword=air)' ],
	[ '@or fire earth', '(keyword=fire or keyword=earth)' ],
	[ '@not water earth', '(keyword=water not keyword=earth)' ],

	# Boolean combinations
	[ '@and water @or fire earth', '(keyword=water and (keyword=fire or keyword=earth))' ],
	[ '@and @or fire earth air', '((keyword=fire or keyword=earth) and keyword=air)' ],
	[ '@or water @and fire earth', '(keyword=water or (keyword=fire and keyword=earth))' ],
	[ '@or @and fire earth air', '((keyword=fire and keyword=earth) or keyword=air)' ],
	[ '@and @or water air @or fire earth', '((keyword=water or keyword=air) and (keyword=fire or keyword=earth))' ],
	[ '@or @and water air @and fire earth', '((keyword=water and keyword=air) or (keyword=fire and keyword=earth))' ],

	# Access points
	[ '@attr 1=1 kernighan', 'contributors =/@name kernighan' ],
	[ '@attr 1=4 unix', 'title=unix' ],
	[ '@attr 1=7 9780253357014', 'identifiers =/@value/@identifierTypeId="8261054f-be78-422d-bd51-4ed9f33c3422" 9780253357014' ],
	[ '@attr 1=8 2167-8359', 'identifiers =/@value/@identifierTypeId="913300b2-03ed-469a-8179-c1092c991227" 2167-8359' ],
	[ '@attr 1=12 12345', 'hrid == 12345' ], # Tests non-standard default relation
	[ '@attr 1=21 palaeontology', 'subjects=palaeontology' ],
	[ '@attr 1=31 2007', 'publication.dateOfPublication=2007' ],
	[ '@attr 1=1003 ritchie', 'contributors =/@name ritchie' ],
	[ '@attr 1=9999 churchill', '(contributors =/@name churchill or title=churchill or hrid=churchill or subjects=churchill)' ],
	[ '@attr 1=1019 marc', 'source=marc' ],
	[ '@attr 1=1108 marc', 'source=marc' ],
	[ '@attr 1=1155 marc', 'source=marc' ],
	[ '@attr 1=1211 793828439', 'identifiers =/@value/@identifierTypeId="439bfbae-75bc-4f74-9fc7-b2a2d47ce3ef" 793828439' ],

	# Relation attributes
	[ '@attr 1=12 @attr 2=1 42', 'hrid < 42' ],
	[ '@attr 1=12 @attr 2=2 42', 'hrid <= 42' ],
	[ '@attr 1=12 @attr 2=3 42', 'hrid = 42' ],
	[ '@attr 1=12 @attr 2=4 42', 'hrid >= 42' ],
	[ '@attr 1=12 @attr 2=5 42', 'hrid > 42' ],
	[ '@attr 1=12 @attr 2=6 42', 'hrid <> 42' ],
	[ '@attr 1=12 @attr 2=100 42', 'hrid =/phonetic 42' ],
	[ '@attr 1=12 @attr 2=101 42', 'hrid =/stem 42' ],
	[ '@attr 1=12 @attr 2=102 42', 'hrid =/relevant 42' ],

	# Position attributes
	[ '@attr 3=1 42', 'keyword=^42' ],
	[ '@attr 3=2 42', 'keyword=^42' ],
	[ '@attr 3=3 42', 'keyword=42' ],

	# Structure attributes are simply ignored, so no tests for these

	# Truncation attributes
	[ '@attr 5=1 42', 'keyword=42*' ],
	[ '@attr 5=2 42', 'keyword=*42' ],
	[ '@attr 5=3 42', 'keyword=*42*' ],
	[ '@attr 5=100 42', 'keyword=42' ],
	[ '@attr 5=101 42#39#5abc', 'keyword=42?39?5abc' ],
	[ '@attr 5=104 42#39?5abc', 'keyword=42?39*abc' ],

	# Completeness attributes
	[ '@attr 6=1 42', 'keyword=42' ],
	[ '@attr 6=2 42', 'keyword=^42^' ],
	[ '@attr 6=3 42', 'keyword=^42^' ],

	# Complex combinations
	[ '@and @attr 1=1003 kernighan @attr 1=4 unix', '(contributors =/@name kernighan and title=unix)' ],
    );
}

use Test::More tests => 2*scalar(@tests) + 2;

BEGIN { use_ok('Net::Z3950::FOLIO') };

# Avoid warnings from failed variable substitution
$ENV{OKAPI_URL} = $ENV{OKAPI_TENANT} = $ENV{OKAPI_USER} = $ENV{OKAPI_PASSWORD} = 'x';

my $service = new Net::Z3950::FOLIO('etc/config.json');
ok(defined $service, 'made FOLIO service object');
my $parser = new Net::Z3950::PQF();

foreach my $test (@tests) {
    my($input, $output) = @$test;

    my $node = $parser->parse($input);
    ok(defined $node, "parsed PQF: $input");

    my $ss = $node->toSimpleServer();
    my $args = { GHANDLE => $service, HANDLE => { resultsets => { foo => { rsid => 'bar' } } } };
    my $cql = $ss->_toCQL($args);
    is($cql, $output, "generated correct CQL: $output");
}
