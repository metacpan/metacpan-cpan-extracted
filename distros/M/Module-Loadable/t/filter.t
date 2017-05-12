#!perl

# testing with lib::filter

use strict;
use warnings;

use Module::Loadable qw(module_source module_loadable);
use Test::More 0.98;
use Test::Needs 'lib::disallow';

subtest module_loadable => sub {
    require lib::disallow;
    lib::disallow->import("if");
    ok(!module_loadable("if"), "'if' can't be loaded (filtered)");
};

done_testing;
