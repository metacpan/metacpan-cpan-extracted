#!perl

use 5.010001;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Local::Node::Hash;
use Local::Node::Hash::Sub1;
use Local::Node::Hash::Sub2;
use Test::More 0.98;
use Test::Role::TinyCommons::Tree qw(test_role_tinycommons_tree);

test_role_tinycommons_tree(
    class     => 'Local::Node::Hash',
    subclass1 => 'Local::Node::Hash::Sub1',
    subclass2 => 'Local::Node::Hash::Sub2',

    test_fromstruct  => 1,
    test_nodemethods => 1,
);
done_testing;
