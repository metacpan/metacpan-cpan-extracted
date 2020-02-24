use Test::More;
use Neo4j::Bolt::NeoValue;

$n1 = bless { id => 236874, labels => ["La", "bels"] }, "Neo4j::Bolt::Node";
$s = { _node => 236874, _labels => ["La", "bels"] };
is_deeply $n1->as_simple(), $s, "simple node, no props";

$n2 = bless { id => 236875, properties => {prop => 42} }, "Neo4j::Bolt::Node";
$s = { _node => 236875, _labels => [], prop => 42 };
is_deeply $n2->as_simple(), $s, "simple node, no labels";

$r1 = bless { id => 15534, start => 236874, end => 236875, type => "EDGE", properties => {prop => 17} }, "Neo4j::Bolt::Relationship";
$s = { _relationship => 15534, _start => 236874, _end => 236875, _type => "EDGE", prop => 17 };
is_deeply $r1->as_simple(), $s, "simple rel, with props";

$v = bless { id => 0, start => 0, end => 1, type => "" }, "Neo4j::Bolt::Relationship";
$s = { _relationship => 0, _start => 0, _end => 1, _type => "" };
is_deeply $v->as_simple(), $s, "simple rel, no props";

$v = bless [$n1, $r1, $n2], "Neo4j::Bolt::Path";
$s = [$n1, $r1, $n2];
is_deeply $v->as_simple(), $s, "simple path";


done_testing;
