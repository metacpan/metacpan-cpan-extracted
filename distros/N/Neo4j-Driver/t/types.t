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
my $s = $driver->session;  # only for autocommit transactions


# The purpose of these tests is to confirm that Neo4j values are correctly
# converted to Perl values (and vice versa).

# see also:
# https://neo4j.com/docs/cypher-manual/current/syntax/values/
# https://metacpan.org/pod/Cpanel::JSON::XS#JSON-%3E-PERL
# https://metacpan.org/pod/Mojo::JSON::MaybeXS#Upgraded-Numbers

use Test::More 0.96 tests => 4 + 5 + 3 + 1;
use Test::Exception;
use JSON::PP ();
my $transaction = $driver->session->begin_transaction;
$transaction->{return_stats} = 0;  # optimise sim


my ($q, $r, $r0, $ver, $id);


subtest 'Property types: scalar type semantics' => sub {
	plan tests => 1 + 8;
	$q = <<END;
RETURN 42, 0.5, 'yes', 0, '', true, false, null
END
	lives_ok { $r = $s->run($q)->list->[0]; } 'get scalar property values';
	SKIP: {
		skip '(read failed)', 8 if ! $r;
		is $r->get(0), 42, 'integer';
		is $r->get(1), .5, 'float';
		is $r->get(2), 'yes', 'string';
		is $r->get(3), 0, 'zero';
		is $r->get(4), '', 'empty string';
		is $r->get(5), JSON::PP::true, 'true';
		is $r->get(6), JSON::PP::false, 'false';
		is $r->get(7), undef, 'null';  # technically not a Neo4j property type
	}
};


eval { $ver = '??'; $ver = $s->server->version; };


subtest 'Property types: spatial type semantics' => sub {
	# may fail on old Neo4j versions and over Bolt
	plan skip_all => "(spatial types unavailable in server $ver)" if $ver lt 'Neo4j/3.4';
	plan tests => 1 + 1 unless $ver lt 'Neo4j/3.4';
	$q = <<END;
RETURN point({ x:3, y:0 })
END
	lives_ok { $r = 0; $r = $s->run($q)->single; } 'get spatial property values';
	SKIP: {
		skip '(read failed)', 1 if ! $r;
		is ref $r->get(0), 'Neo4j::Driver::Type::Point', 'point blessed';
		# TODO: further tests
	}
};


subtest 'Property types: temporal type semantics' => sub {
	# may fail on old Neo4j versions and over Bolt
	plan skip_all => "(temporal types unavailable in server $ver)" if $ver lt 'Neo4j/3.4';
	plan tests => 1 + 1 unless $ver lt 'Neo4j/3.4';
	$q = <<END;
RETURN
duration.between(date('1984-10-11'), date('2015-06-24'))
END
	lives_ok { $r = 0; $r = $s->run($q)->single; } 'get temporal property values';
	SKIP: {
		skip '(read failed)', 1 if ! $r;
		is ref $r->get(0), 'Neo4j::Driver::Type::Temporal', 'temporal blessed';
		# TODO: further tests
	}
};


subtest 'Property types: use as parameters' => sub {
	plan tests => 1 + 7;
	my $scalar = '47';
	my @params = (
		number =>  0 + $scalar,
		string => '' . $scalar,
		true   => \1,
		false  => \0,
		null   => undef,
		list   => [17, 31],
		map    => {half => .5},
	);
	$q = <<END;
RETURN
{number} = 47,
{string} = '47',
{true} = true,
{false} = false,
{null} IS NULL,
{list} = [17, 31],
{map} = {half: 0.5}
END
	lives_ok { $r = 0; $r = $s->run($q, @params)->single; } 'get write result';
	for my $i (0..6) {
		ok $r->get($i), "param $i ($params[$i*2])";
	}
};


$q = <<END;
CREATE (n1:Test {test: 'node1'}), (n2:Test {test: 'node2'})
CREATE p1=(n1)-[e1:TEST]->(n2)<-[e2:TEST]-(n1)
CREATE (n3:Test {_node: -1, _labels: 'special'})
CREATE p2=(n3)-[e3:TEST {_relationship: 'yes', _test: 1}]->(n4)
SET e1.test = 'rel1', e2.test = 'rel2'
RETURN n1, n2, e1, e2, id(n1), id(e1), p1, n3, n4, e3
END
lives_ok { $r0 = 0; $r0 = $transaction->run($q)->single; } 'run query (structural types)';


subtest 'Structural types: node meta data and props' => sub {
	plan skip_all => '(query failed)' if ! $r0;
	plan tests => 10 if $r0;
	ok my $n1 = $r0->get('n1'), 'get node 1';
	ok my $n2 = $r0->get('n2'), 'get node 2';
	ok $id = $r0->get('id(n1)'), 'get node 1 id';
	is ref $n1, 'Neo4j::Driver::Type::Node', 'node 1 blessed';
	is ref $n2, 'Neo4j::Driver::Type::Node', 'node 2 blessed';
	is $n1->id, $id, 'node 1 id matches';
	isnt $n2->id, $n1->id, 'node 2 id distinct';
	is $n1->get('test'), 'node1', 'node 1 get';
	is $n2->properties->{test}, 'node2', 'node 2 properties';
	ok grep(m/^Test$/, $n1->labels), 'node 1 label';
};


subtest 'Structural types: relation meta data and props' => sub {
	plan skip_all => '(query failed)' if ! $r0;
	plan tests => 13 if $r0;
	ok my $n1 = $r0->get('n1'), 'get node 1';
	ok my $n2 = $r0->get('n2'), 'get node 2';
	ok my $e1 = $r0->get('e1'), 'get rel 1';
	ok my $e2 = $r0->get('e2'), 'get rel 2';
	is ref $e1, 'Neo4j::Driver::Type::Relationship', 'rel 1 blessed';
	is ref $e2, 'Neo4j::Driver::Type::Relationship', 'rel 2 blessed';
	is $e1->id, $r0->get('id(e1)'), 'rel 1 id matches';
	isnt $e2->id, $e1->id, 'rel 2 id distinct';
	is $e1->properties->{test}, 'rel1', 'rel 1 properties';
	is $e2->get('test'), 'rel2', 'rel 2 get';
	is $e1->start_id, $n1->id, 'rel 1 start id';
	is $e2->end_id, $n2->id, 'rel 2 end id';
	is $e1->type, 'TEST', 'rel 1 type';
};


subtest 'Structural types: path accessors' => sub {
	plan skip_all => '(query failed)' if ! $r0;
	plan tests => 8 if $r0;
	ok my $p = $r0->get('p1'), 'get path';
	is ref $p, 'Neo4j::Driver::Type::Path', 'path blessed';
	SKIP: {
		skip '(path not blessed)', 6 unless ref $p eq 'Neo4j::Driver::Type::Path';
		ok my @nodes = $p->nodes, 'get nodes';
		ok my @rels = $p->relationships, 'get rels';
		is scalar @nodes, 3, 'node count';
		is scalar @rels, 2, 'rels count';
		is $nodes[0]->id, $nodes[2]->id, 'path circular';
		isnt $rels[0]->id, $rels[1]->id, 'rels distinct';
	}
};


subtest 'Structural types: underscore properties' => sub {
	plan skip_all => '(query failed)' if ! $r0;
	plan tests => 8 if $r0;
	ok my $n3 = $r0->get('n3'), 'get node 3';
	ok my $n4 = $r0->get('n4'), 'get node 4';
	ok my $e3 = $r0->get('e3'), 'get rel 3';
	is $n3->get('_labels'), 'special', 'underscore labels';
	is $n3->get('_node'), -1, 'underscore node set';
	is $e3->get('_test'), 1, 'underscore test';
	is $e3->get('_relationship'), 'yes', 'underscore relationship';
	is $n4->get('_node'), undef, 'underscore node unset';
};


subtest 'Composite types: flat' => sub {
	plan tests => 20;
	$q = <<END;
CREATE p=(a:Test)-[b:TEST]->(c:Test)
RETURN [17, a, null, p], {first: null, second: b, third: 23}, [], {}
END
	lives_ok { $r = $transaction->run($q)->list->[0]; } 'get composite types';
	ok my $l = $r->get(0), 'get list';
	is ref $l, 'ARRAY', 'list =array';
	is scalar @$l, 4, 'list size';
	is $l->[0], 17, 'number in list';
	is ref $l->[1], 'Neo4j::Driver::Type::Node', 'blessed node in list';
	is $l->[2], undef, 'null in list';
	is ref $l->[3], 'Neo4j::Driver::Type::Path', 'blessed path in list';
	ok my $m = $r->get(1), 'get map';
	is ref $m, 'HASH', 'map =hash';
	is scalar keys %$m, 3, 'map size';
	is $m->{first}, undef, 'null in map';
	is ref $m->{second}, 'Neo4j::Driver::Type::Relationship', 'blessed rel in map';
	is $m->{third}, 23, 'number in map';
	ok $l = $r->get(2), 'get empty list';
	is ref $l, 'ARRAY', 'empty list =array';
	is scalar @$l, 0, 'empty list size';
	ok $m = $r->get(3), 'get empty map';
	is ref $m, 'HASH', 'empty map =hash';
	is scalar keys %$m, 0, 'empty map size';
};


subtest 'Composite types: nested' => sub {
	plan skip_all => '(query failed)' if ! $r0;
	plan tests => 16 if $r0;
	# verify that deeply nested entities are properly blessed
	$q = <<END;
MATCH p=(n1:Test)-[:TEST]->(:Test)
WHERE id(n1) = {id}
CREATE (a:Test {test: 'node'}), (b:Test {list:[17,23]})
RETURN [{node: a}, {path: p}, b], {node: b, list: [p, a]}, b
LIMIT 1
END
	lives_ok { $r = $transaction->run($q, id => $id)->list->[0]; } 'get composite types';
	my ($a1, $b1, $p1, $a2, $b2, $p2);
	lives_ok { $a1 = $r->get(0)->[0]->{node}; } 'list: get node "a"';
	lives_ok { $b1 = $r->get(0)->[2]; } 'list: get node "b"';
	lives_ok { $p1 = $r->get(0)->[1]->{path}; } 'list: get path "p"';
	is ref $a1, 'Neo4j::Driver::Type::Node', 'list: blessed node "a"';
	is ref $b1, 'Neo4j::Driver::Type::Node', 'list: blessed node "b"';
	is ref $p1, 'Neo4j::Driver::Type::Path', 'list: blessed path "p"';
	lives_ok { $a2 = $r->get(1)->{list}->[1]; } 'map: get node "a"';
	lives_ok { $b2 = $r->get(1)->{node}; } 'map: get node "b"';
	lives_ok { $p2 = $r->get(1)->{list}->[0]; } 'map: get node "p"';
	is ref $a2, 'Neo4j::Driver::Type::Node', 'map: blessed node "a"';
	is ref $b2, 'Neo4j::Driver::Type::Node', 'map: blessed node "b"';
	is ref $p2, 'Neo4j::Driver::Type::Path', 'map: blessed path "p"';
	lives_and { is $a1->id, $a2->id } 'node "a": id match';
	lives_and { is $b1->id, $b2->id } 'node "b": id match';
	lives_and { isnt $a1->id, $b1->id } 'nodes "a"/"b" distinct';
};


subtest 'Composite types: homogeneous lists as props' => sub {
	# technically not a composite type check
	plan skip_all => '(query failed)' if ! $r;
	plan tests => 3 if $r;
	ok my $c = $r->get(2), 'get node';
	is ref $c->get('list'), 'ARRAY', 'list =array';
	lives_and { is $c->get('list')->[0], 17 } 'value check';
};


CLEANUP: {
	lives_ok { $transaction->rollback } 'rollback';
}


done_testing;
