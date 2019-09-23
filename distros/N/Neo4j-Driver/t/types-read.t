#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

my $driver;
use Neo4j::Test;
BEGIN {
	unless ($driver = Neo4j::Test->driver) {
		print qq{1..0 # SKIP no connection to Neo4j server\n};
		exit;
	}
}


# The purpose of these tests is to confirm that Neo4j values are correctly
# converted to Perl values. This is an area of concern because two type
# conversions take place here: First a conversion from Neo4j types to JSON
# types, then from JSON to Perl types.

# see also:
# https://neo4j.com/docs/developer-manual/3.3/cypher/syntax/values/
# https://metacpan.org/pod/Cpanel::JSON::XS#JSON-%3E-PERL
# https://metacpan.org/pod/Mojo::JSON::MaybeXS#Upgraded-Numbers

use Test::More 0.96 tests => 4 + 1;
use Test::Exception;
use JSON::PP ();
my $transaction = $driver->session->begin_transaction;


my ($q, $r);


subtest 'Neo4j property types' => sub {
	plan tests => 7;
	$q = <<END;
RETURN 42, 0.5, 'Praise be to the dartmakers.', true, false, null
END
	lives_ok { $r = $transaction->run($q)->list->[0]; } 'get property values';
	
	is $r->get(0), 42, 'integer';
	is $r->get(1), .5, 'float';
	is $r->get(2), 'Praise be to the dartmakers.', 'string';
	is $r->get(3), JSON::PP::true, 'true';
#	ok JSON::PP::is_bool $r->get(3), 'true type';
#	ok $r->get(3), 'true value';
	is $r->get(4), JSON::PP::false, 'false';
#	ok JSON::PP::is_bool $r->get(4), 'false type';
#	ok ! $r->get(4), 'false value';
	is $r->get(5), undef, 'null/undef';
#	diag explain $r;
};


subtest 'Neo4j structural types' => sub {
	plan tests => 14;
	
	# nodes / relationships
	$q = <<END;
CREATE (a:Test {test: 'node1'})-[b:TEST {test: 'rel'}]->(:Test {test: 'node2'})
RETURN a, b, [id(a), id(b)] AS ids
END
	lives_ok { $r = $transaction->run($q)->list->[0]; } 'get node/rel';
	
	is $r->get('a')->{test}, 'node1', 'node property';
	is $r->get('b')->{test}, 'rel', 'rel property';
	SKIP: {
		skip 'no meta data (Neo4j version too old)', 2 unless my $m = $r->{meta};
		is $m->[0]->{id}, $r->get('ids')->[0], 'node id';
		is $m->[1]->{id}, $r->get('ids')->[1], 'rel id';
	}
	
	# paths
	$q = <<END;
MATCH p=(:Test {test: 'node1'})-[:TEST {test: 'rel'}]->(:Test {test: 'node2'})
RETURN p
END
	lives_ok { $r = $transaction->run($q)->list->[0]; } 'get path';
	
	is ref $r->get(0), 'ARRAY', 'path =array';
	is scalar @{$r->get(0)}, 3, 'path length';
	is $r->get(0)->[0]->{test}, 'node1', 'node 1';
	is $r->get(0)->[1]->{test}, 'rel', 'rel';
	is $r->get(0)->[2]->{test}, 'node2', 'node 2';
	SKIP: {
		skip 'no meta data (Neo4j version too old)', 3 unless my $m = $r->{meta};
		is $m->[0]->[0]->{type}, 'node', 'node 1 meta type';
		is $m->[0]->[1]->{type}, 'relationship', 'rel meta type';
		is $m->[0]->[2]->{type}, 'node', 'node 2 meta type';
	}
	
	# node label, rel type, and rel start/end ids are also
	# part of structural types, but checking those would
	# require using return_graph
};


subtest 'Neo4j composite types' => sub {
	plan tests => 18;
	$q = <<END;
MATCH p=(:Test {test: 'node1'})-[:TEST {test: 'rel'}]->(:Test {test: 'node2'})
CREATE (a:Test {test: 'node'}), (b:Test)
RETURN [17, a, p], {first: 23, second: [b, null]}
END
	lives_ok { $r = $transaction->run($q)->list->[0]; } 'get composite types';
	
	is ref $r->get(0), 'ARRAY', 'list =array';
	is scalar @{$r->get(0)}, 3, 'list size';
	is $r->get(0)->[0], 17, 'number in list';
	is $r->get(0)->[1]->{test}, 'node', 'node in list';
	is ref $r->get(0)->[2], 'ARRAY', 'list-path =array';
	is scalar @{$r->get(0)->[2]}, 3, 'list-path length';
	is $r->get(0)->[2]->[0]->{test}, 'node1', 'node 1 in list-path';
	is $r->get(0)->[2]->[1]->{test}, 'rel', 'rel in list-path';
	is $r->get(0)->[2]->[2]->{test}, 'node2', 'node 2 in list-path';
	
	is ref $r->get(1), 'HASH', 'map =hash';
	is scalar keys %{$r->get(1)}, 2, 'map size';
	is $r->get(1)->{first}, 23, 'number in map';
	is ref $r->get(1)->{second}, 'ARRAY', 'list in map =array';
	is scalar @{$r->get(1)->{second}}, 2, 'map-list size';
	is ref $r->get(1)->{second}->[0], 'HASH', 'node in map-list';
	is scalar (grep !/^_/, keys %{$r->get(1)->{second}->[0]}), 0, 'no-prop node in map-list';
	is $r->get(1)->{second}->[1], undef, 'null in map-list';
};


subtest 'Underscore properties' => sub {
	plan tests => 6;
	$q = <<END;
CREATE (a:Test {_node: -1, _labels: 'test,special'})-[b:TEST {_relationship: 'yes', _test: true}]->(c:Test)
RETURN a, b, c
END
	lives_ok { $r = $transaction->run($q)->list->[0]; } 'get underscore props';
	
	is $r->get('b')->{_test}, JSON::PP::true, 'underscore test';
	is $r->get('b')->{_relationship}, 'yes', 'underscore relationship';
	is $r->get('a')->{_labels}, 'test,special', 'underscore labels';
	is $r->get('a')->{_node}, -1, 'underscore node set';
	is $r->get('c')->{_node}, undef, 'underscore node unset';
};


CLEANUP: {
	lives_ok { $transaction->rollback } 'rollback';
}

done_testing;
