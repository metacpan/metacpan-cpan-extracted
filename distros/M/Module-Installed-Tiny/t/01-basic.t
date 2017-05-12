#!perl

use strict;
use warnings;

use Module::Installed::Tiny qw(module_source module_installed);
use Test::More 0.98;

subtest module_installed => sub {
    ok( module_installed("Test::More"), "already loaded -> true");
    ok( module_installed("Test/More.pm"), "Foo/Bar.pm-style accepted");
    ok( module_installed("if"), "'if' is installed");
    ok(!exists($INC{"if.pm"}), "if.pm is not actually loaded");
    ok(!module_installed("Local::Foo"), "not found on filesystem -> false");
};

subtest module_source => sub {
    like(module_source("if"), qr/package if/);
};

done_testing;
