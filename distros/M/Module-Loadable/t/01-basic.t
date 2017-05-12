#!perl

use strict;
use warnings;

use Module::Loadable qw(module_source module_loadable);
use Test::More 0.98;

subtest module_loadable => sub {
    ok( module_loadable("Test::More"), "already loaded -> true");
    ok( module_loadable("Test/More.pm"), "Foo/Bar.pm-style accepted");
    ok( module_loadable("if"), "'if' can be loaded");
    ok(!exists($INC{"if.pm"}), "if.pm is not actually loaded");
    ok(!module_loadable("Local::Foo"), "not found on filesystem -> false");
};

subtest module_source => sub {
    like(module_source("if"), qr/package if/);
};

done_testing;
