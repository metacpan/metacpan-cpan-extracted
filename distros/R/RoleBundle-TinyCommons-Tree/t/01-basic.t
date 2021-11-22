#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use FindBin '$Bin';
use lib "$Bin/lib";

use Local::Node::Hash2;
use Code::Includable::Tree::FromStruct;
use Code::Includable::Tree::FromObjArray;
use Code::Includable::Tree::NodeMethods;

my $n1 = Local::Node::Hash2->new(id=>'n1');
my $n2 = Local::Node::Hash2->new(id=>'n2', parent=>$n1);
my $n3 = Local::Node::Hash2->new(id=>'n3', parent=>$n1);
$n1->set_children([$n2, $n3]);
my $n4 = Local::Node::Hash2->new(id=>'n4', parent=>$n2);
$n2->set_children([$n4]);
my $n5 = Local::Node::Hash2->new(id=>'n5', parent=>$n3);
$n3->set_children([$n5]);
#diag explain $n1;

subtest "customize get/set parent/children methods in Code::Includable::Tree::NodeMethods" => sub {
    local $Code::Includable::Tree::NodeMethods::GET_PARENT_METHOD   = 'get_parent';
    local $Code::Includable::Tree::NodeMethods::SET_PARENT_METHOD   = 'set_parent';
    local $Code::Includable::Tree::NodeMethods::GET_CHILDREN_METHOD = 'get_children';
    local $Code::Includable::Tree::NodeMethods::SET_CHILDREN_METHOD = 'set_children';

    my @ancestors = Code::Includable::Tree::NodeMethods::ancestors($n5);
    is_deeply([map {$_->get_id} @ancestors], ['n3', 'n1']);
};

subtest "customize get/set parent/children methods in Code::Includable::Tree::FromStruct" => sub {
    local $Code::Includable::Tree::FromStruct::GET_PARENT_METHOD   = 'get_parent';
    local $Code::Includable::Tree::FromStruct::SET_PARENT_METHOD   = 'set_parent';
    local $Code::Includable::Tree::FromStruct::GET_CHILDREN_METHOD = 'get_children';
    local $Code::Includable::Tree::FromStruct::SET_CHILDREN_METHOD = 'set_children';

    my $struct = {id => 1, _children => [
        {id => 2, _children => [
            {id => 4},
        ]},
        {id => 3, _children => [
            {id => 5},
        ]},
    ]};

    my $tree = Code::Includable::Tree::FromStruct::new_from_struct(
        'Local::Node::Hash2', $struct);
    #diag explain $tree;
    is_deeply($n1->get_children_arrayref->[0], $n2);
    is_deeply($n1->get_children_arrayref->[1], $n3);
    is_deeply($n2->get_children_arrayref->[0], $n4);
    is_deeply($n3->get_children_arrayref->[0], $n5);
    ok 1;
};

subtest "customize set parent/children methods in Code::Includable::Tree::FromObjArray" => sub {
    local $Code::Includable::Tree::FromObjArray::SET_PARENT_METHOD   = 'set_parent';
    local $Code::Includable::Tree::FromObjArray::SET_CHILDREN_METHOD = 'set_children';

    my $n1 = Local::Node::Hash2->new(id=>'n1');
    my $n2 = Local::Node::Hash2->new(id=>'n2', parent=>$n1);
    my $n3 = Local::Node::Hash2->new(id=>'n3', parent=>$n1);
    my $n4 = Local::Node::Hash2->new(id=>'n4', parent=>$n2);
    my $n5 = Local::Node::Hash2->new(id=>'n5', parent=>$n3);

    my $obj_array = [$n1, [
        $n2, [$n4],
        $n3, [$n5],
    ]];

    my $tree = Code::Includable::Tree::FromObjArray->new_from_obj_array($obj_array);
    #diag explain $tree;
    is_deeply($n1->get_children_arrayref->[0], $n2);
    is_deeply($n1->get_children_arrayref->[1], $n3);
    is_deeply($n2->get_children_arrayref->[0], $n4);
    is_deeply($n3->get_children_arrayref->[0], $n5);
    ok 1;
};

done_testing;
