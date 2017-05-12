#!perl

use 5.010001;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More 0.98;
use Test::Role::TinyCommons::Tree qw(test_role_tinycommons_tree);
BEGIN {
    unless (eval { require Class::InsideOut; 1 }) {
        plan skip_all => "Class::InsideOut not availalbe";
    }
}

use Local::Node::InsideOut;
use Local::Node::InsideOut::Sub1;
use Local::Node::InsideOut::Sub2;

test_role_tinycommons_tree(
    class     => 'Local::Node::InsideOut',
    subclass1 => 'Local::Node::InsideOut::Sub1',
    subclass2 => 'Local::Node::InsideOut::Sub2',

    test_fromstruct  => 1,
    test_nodemethods => 1,
);
done_testing;
