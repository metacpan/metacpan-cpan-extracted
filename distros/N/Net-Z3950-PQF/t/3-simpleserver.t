# $Id: 3-simpleserver.t,v 1.1 2007/10/05 12:12:10 mike Exp $

use strict;
use warnings;

use strict;
use warnings;
use Test::More tests => 52;
BEGIN { use_ok('Net::Z3950::PQF') };

my $parser = new Net::Z3950::PQF();
ok(defined $parser, "created parser");
my $top = $parser->parse(
'@and @or @set 123 @attr 1=1023 frog @attr 2=3 @attr zthes 1=magic bar');

my $ss = $top->toSimpleServer();
check_node($ss, "top node", "Net::Z3950::RPN::And", "an AND node");
is(@$ss, 2, "top has two subtrees");

my $sub = $ss->[0];
check_node($sub, "first subtree", "Net::Z3950::RPN::Or", "an OR node");
is(@$sub, 2, "first subnode has two subtrees");

my $subsub = $sub->[0];
check_node($subsub, "first subsubtree", "Net::Z3950::RPN::RSID", "an RSID");
is($subsub->{id}, 123, "RSID value");
check_attributes($subsub->{attributes}, "first subsubtree", 0);

$subsub = $sub->[1];
check_node($subsub, "second subsubtree", "Net::Z3950::RPN::Term", "a Term");
is($subsub->{term}, "frog", "term value");
check_attributes($subsub->{attributes}, "second subsubtree", 1);
check_attribute($subsub->{attributes}->[0],
		"second subsubtree, only attribute", "bib-1", 1 => 1023);

$sub = $ss->[1];
check_node($sub, "second subtree", "Net::Z3950::RPN::Term", "a Term");
is($sub->{term}, "bar", "term value");
check_attributes($sub->{attributes}, "second subtree", 2);
check_attribute($sub->{attributes}->[0],
		"second subtree, second attribute", "bib-1", 2 => 3);
check_attribute($sub->{attributes}->[1],
		"second subtree, first attribute", "zthes", 1 => "magic");

#use YAML; print Dump($ss);


sub check_node {
    my($node, $caption, $class, $description) = @_;

    ok(defined $node, "$caption is defined");
    ok(ref $node, "$caption is a reference");
    ok($node->isa($class), "$caption is $description");
}


sub check_attributes {
    my($attrs, $caption, $count) = @_;

    ok(defined $attrs, "$caption has attributes");
    ok(ref $attrs, "$caption attributes are a reference");
    ok($attrs->isa("Net::Z3950::RPN::Attributes"), "$caption attributes type");
    is(@{ $attrs }, $count, "$caption attribute count = $count");
}


sub check_attribute {
    my($attr, $caption, $set, $type, $value) = @_;

    ok(defined $attr, "$caption is defined");
    ok(ref $attr, "$caption is a reference");
    ok($attr->isa("Net::Z3950::RPN::Attribute"), "$caption type");
    is($attr->{attributeSet}, $set, "$caption attribute set");
    is($attr->{attributeType}, $type, "$caption attribute set");
    is($attr->{attributeValue}, $value, "$caption attribute set");
}
