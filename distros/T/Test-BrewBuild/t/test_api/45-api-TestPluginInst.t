#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Plugin::UnitTestPluginInst;
use Test::More;

my $mod = 'Test::BrewBuild::Plugin::UnitTestPluginInst';

is ($mod->brewbuild_exec(), 'test plugin', "the test plugin returns ok");

done_testing();

