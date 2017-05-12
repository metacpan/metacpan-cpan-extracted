#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::Role::TinyCommons::Tree qw(test_role_tinycommons_tree);
#use Test::Requires 'Class::Build::Array::Glob'; # can't be used
BEGIN {
    unless (eval { require Tree::Object::Array::Glob; 1 }) {
        plan skip_all => "Tree::Object::Array::Glob not availalbe";
    }
}

use Local::Node::Array;
use Local::Node::Array::Sub1;
use Local::Node::Array::Sub2;

test_role_tinycommons_tree(
    class     => 'Local::Node::Array',
    subclass1 => 'Local::Node::Array::Sub1',
    subclass2 => 'Local::Node::Array::Sub2',

    test_fromstruct  => 1,
    test_nodemethods => 1,
);
done_testing;
