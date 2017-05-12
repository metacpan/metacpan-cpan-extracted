#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Requires 'Moose';

use FindBin '$Bin';
use lib "$Bin/lib";

use Local::Node::Moose;
use Local::Node::Moose::Sub1;
use Local::Node::Moose::Sub2;
use Test::Role::TinyCommons::Tree qw(test_role_tinycommons_tree);

test_role_tinycommons_tree(
    class     => 'Local::Node::Moose',
    subclass1 => 'Local::Node::Moose::Sub1',
    subclass2 => 'Local::Node::Moose::Sub2',

    test_fromstruct  => 1,
    test_nodemethods => 1,
);
done_testing;
