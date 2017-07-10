use Test::More;
use Tie::IxHash;
use lib '../lib';
use_ok('Neo4j::Cypher::Pattern');

my %props;
tie %props, 'Tie::IxHash';

my $p = Neo4j::Cypher::Pattern->new();
isa_ok($p, 'Neo4j::Cypher::Pattern');
is $p->as_string, "";
$p->node();
is $p->as_string, "()", "empty node";
ok $p->clear;

is $p->node("a",["boog"])->as_string, "(a:boog)";
$p->clear;
is $p->node("a:boog")->as_string, "(a:boog)";
$p->clear;
%props = (foo=>"bar",baz=>1);
is $p->node("a", ["boog"], \%props)->as_string, "(a:boog {foo:'bar',baz:'1'})",$p->as_string;
$p->clear;
is $p->node("n", {foo=>"this has 'quotes'"})->as_string, "(n {foo:'this has \\'quotes\\''})",$p->as_string;

$p->clear;
is $p->N("a")->R()->N("b")->as_string, "(a)--(b)",$p->as_string;
$p->clear;
is $p->N("a")->R("r")->N("b")->as_string, '(a)-[r]-(b)', $p->as_string;
$p->clear;
is $p->N("a")->R("<r")->N("b")->as_string, '(a)<-[r]-(b)', $p->as_string;
$p->clear;
is $p->N("a")->R("r>")->N("b")->as_string, '(a)-[r]->(b)', $p->as_string;
$p->clear;
is $p->N("a")->R("r>",[])->N("b")->as_string, '(a)-[r*]->(b)', $p->as_string;
$p->clear;
is $p->N("a")->R("r",[1,3])->N("b")->as_string, '(a)-[r*1..3]-(b)', $p->as_string;
$p->clear;
is $p->N("a")->R("r",[2,""])->N("b")->as_string, '(a)-[r*2..]-(b)', $p->as_string;
$p->clear;
is $p->N("a:boog:goob")->R("r",["",3])->N("b")->as_string, '(a:boog:goob)-[r*..3]-(b)', $p->as_string;
$p->clear;
is $p->N("a:boog:goob")->R("r:TYPE",["",3])->N("b")->as_string, '(a:boog:goob)-[r:TYPE*..3]-(b)', $p->as_string;
$p->clear;
is $p->N("a:boog:goob")->R("r","TYPE",["",3])->N("b")->as_string, '(a:boog:goob)-[r:TYPE*..3]-(b)', $p->as_string;
$p->clear;
is $p->N("a:boog:goob")->R("r","TYPE>",["",3])->N("b")->as_string, '(a:boog:goob)-[r:TYPE*..3]->(b)', $p->as_string;
$p->clear;
is $p->N("a:boog:goob")->R("r","TYPE>",["",3], {foo=>"bar"})->N("b")->as_string, '(a:boog:goob)-[r:TYPE*..3 {foo:\'bar\'}]->(b)', $p->as_string;
is "$p", '(a:boog:goob)-[r:TYPE*..3 {foo:\'bar\'}]->(b)', $p->as_string;
$p->clear;
is $p->N("a")->R("<",{foo=>"bar"})->N()->as_string, '(a)<-[{foo:\'bar\'}]-()', $p->as_string;

done_testing;
