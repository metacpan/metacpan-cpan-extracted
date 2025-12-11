use v5.12;
use warnings;
use Test::More;
use Neo4j::Bolt::NeoValue;
use JSON::PP 'decode_json';

#diag "create neo4j_values from SVs";
my $i = 100;
my $v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Integer", "Integer";
is $v->_as_perl, $i, "roundtrip";
ok ! Neo4j::Bolt::NeoValue::is_bool($v->_as_perl), "int is not bool";
$i = 100.5;
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Float", "Float";
is $v->_as_perl, $i, "roundtrip";
$i = "Hey dude";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "String", "String";
is $v->_as_perl, $i, "roundtrip";
SKIP: {
  skip "no stable tracking of IOK/POK flags", 1 if $^V lt "v5.36";
  $i = 200;
  {my $x = "xx $i"}
  $v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
  is $v->_neotype, "Integer", "created as int";
}

$i = decode_json('[true]')->[0];
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Boolean", "Boolean true";
ok $v->_as_perl, "Boolean true is truthy";
ok Neo4j::Bolt::NeoValue::is_bool($v->_as_perl), "Boolean true type";
$i = \0;
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Boolean", "Boolean";
ok ! $v->_as_perl, "Boolean false is not truthy";
ok Neo4j::Bolt::NeoValue::is_bool($v->_as_perl), "Boolean false type";
SKIP: {
  skip "no core bools", 1 if $^V lt "v5.36";
  $v = Neo4j::Bolt::NeoValue->_new_from_perl(!!0);
  is $v->_neotype, "Boolean", "Boolean builtin";
}

$v = Neo4j::Bolt::NeoValue->_new_from_perl(["this", "is",1,"array"]);
is $v->_neotype, "List", "List";
is_deeply $v->_as_perl,["this", "is",1,"array"],"roundtrip";
$v = Neo4j::Bolt::NeoValue->_new_from_perl({ this => "is", a => 5, hash => "map"});
is $v->_neotype, "Map", "Map";
is_deeply $v->_as_perl,{ this => "is", a => 5, hash => "map"}, "roundtrip";
ok ! Neo4j::Bolt::NeoValue::is_bool($v->_as_perl), "map is not bool";

$i = bless { id => 154732534, element_id => "154732534" }, "Neo4j::Bolt::Node";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Node", "Empty node";
is_deeply $v->_as_perl,$i,"Empty node roundtrip";
$i = bless { id => 154732534, element_id => "154732534", properties => {these => "are", some => "props"} }, "Neo4j::Bolt::Node";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Node", "Node with Props";
is_deeply $v->_as_perl,$i,"Node with Props roundtrip";
$i = bless { id => 154732534, element_id => "154732534", labels=>['lab','el'], properties => {these => "are", some => "props"} }, "Neo4j::Bolt::Node";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Node", "Node with Props & Labels";
is_deeply $v->_as_perl,$i,"Node with Props & Labels roundtrip";
ok ! Neo4j::Bolt::NeoValue::is_bool($v->_as_perl), "node is not bool";

$i = bless { id => 154732534, element_id => "154732534", start => 53243, start_element_id => "53243", end => 235367, end_element_id => "235367", type => "IS_THING", properties => {these => "are", some => "props"} }, "Neo4j::Bolt::Relationship";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Relationship", "Relationship with Type and Props";
is_deeply $v->_as_perl,$i,"Rel with Type and Props roundtrip";
$i = bless { id => 154732534, element_id => "154732534", start => 53243, start_element_id => "53243", end => 235367, end_element_id => "235367", type => "IS_THING"}, "Neo4j::Bolt::Relationship";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Relationship", "Relationship with Type only";
is_deeply $v->_as_perl,$i,"Rel with Type only roundtrip";
$i = bless { id => 154732534, element_id => "154732534", start => 53243, start_element_id => "53243", end => 235367, end_element_id => "235367"}, "Neo4j::Bolt::Relationship";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Relationship", "Relationship with no type";
is_deeply $v->_as_perl,$i,"Rel with no type roundtrip";

TODO: {
  local $TODO = "Implement paths";
  $i = bless [
  	bless({ id => 1234 }, "Neo4j::Bolt::Node"),
  	bless({ id => 523, start => 1234, end => 5678, type => "try" }, "Neo4j::Bolt::Relationship"),
  	bless({ id => 5678 }, "Neo4j::Bolt::Node"),
  ], "Neo4j::Bolt::Path";
  $v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
  is $v->_neotype, "Path", "Path";
}


done_testing;
