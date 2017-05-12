#!perl

# testing with lib::filter

use strict;
use warnings;

use Module::Installed::Tiny qw(module_source module_installed);
use Test::More 0.98;
use Test::Needs 'lib::disallow';

subtest module_installed => sub {
    require lib::disallow;
    lib::disallow->import("if");
    ok(!module_installed("if"), "'if' not installed (filtered)");
};

done_testing;
