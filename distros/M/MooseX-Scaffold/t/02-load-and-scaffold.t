#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use MooseX::Scaffold;

MooseX::Scaffold->scaffold(scaffolder => 't::Test::Scaffolder', class => 't::Test::Class');

is(t::Test::Class->apple, 1);
is(t::Test::Class->banana, 2);
ok(t::Test::Class->loaded);
