#-*-perl-*-
#$Id$
use Test::More tests => 35;
use Module::Build;
use lib '../lib';
use lib 't/lib';
use Neo4p::Connect;
use strict;
use warnings;

#$SIG{__DIE__} = sub { print $_[0] };

no warnings qw(once);
my $build;
my ($user,$pass) = @ENV{qw/REST_NEO4P_TEST_USER REST_NEO4P_TEST_PASS/};

eval {
    $build = Module::Build->current;
    $user = $build->notes('user');
    $pass = $build->notes('pass');
};
my $TEST_SERVER = $build ? $build->notes('test_server') : $ENV{REST_NEO4P_TEST_SERVER} // 'http://127.0.0.1:7474';
my $num_live_tests = 34;


use_ok('REST::Neo4p');

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;

SKIP : {
    skip 'no connection to neo4j',$num_live_tests if $not_connected;
    ok my $node = REST::Neo4p::Node->new(), 'create new node';
    isa_ok($node, 'REST::Neo4p::Entity');
    isa_ok($node, 'REST::Neo4p::Node');
    ok $node->remove, "remove the node";

    ok my $node2 = REST::Neo4p::Node->new({ a => 1 }), 'create node with props';
    is $node2->get_property('a'), 1, 'property created';
    1;
    ok $node2->set_property( { foo => 'bar', goob => 12 } ), 'set props';
    is_deeply [$node2->get_property('foo','goob')], ['bar',12], 'get props singly';
    is_deeply $node2->get_properties, { a => 1, foo => 'bar', goob => 12 }, 'get all props at once';
    ok my $node1 = REST::Neo4p::Node->new(), 'make node1';
    ok my $rel12 = $node1->relate_to($node2, 'is_a'), 'relate n1 to n2';
    ok my $rel21 = $node2->relate_to($node1, 'parent', { type => 'adoptive' }), 'relate n2 to n1, with property';
    is $rel12->type, 'is_a', 'get rel12 type';
    is $rel21->type, 'parent', 'get rel21 type';
    is $rel21->get_property('type'), 'adoptive', 'rel21 property retrieved';
    is_deeply $rel21->get_properties, { type => 'adoptive' }, 'rel21 all props at once';

    ok my @relns = $node1->get_relationships, 'get all relationships on n1';
    is scalar @relns, 2, '1 in and 1 out';
    for (@relns) {
	isa_ok($_, 'REST::Neo4p::Relationship');
    }
    ok @relns = $node1->get_relationships('in'), 'get incoming relationships';
    is ${$relns[0]}, $$rel21, 'got incoming reln';
    ok @relns = $node1->get_relationships('out'), 'get outgoing relationships';
    is ${$relns[0]}, $$rel12, 'got outgoing reln';

    # start_node, end_node (0.127)
    isa_ok($rel21->start_node, 'REST::Neo4p::Node');
    isa_ok($rel21->end_node, 'REST::Neo4p::Node');
    is $rel21->start_node->id, $node2->id, 'got start node';
    is $rel21->end_node->id, $node1->id, 'got end node';
    is $rel12->start_node->id, $node1->id, 'got start node';
    is $rel12->end_node->id, $node2->id, 'got end node';
    
    CLEANUP : {    
	ok $rel12->remove, 'remove relationship n1 to n2';
	ok $rel21->remove, 'remove relationship n2 to n1';
	ok $node1->remove, 'remove n1';
	ok $node2->remove, 'remove n2';
    }


}
