#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use MooseX::Scaffold;

MooseX::Scaffold->load_or_scaffold(scaffolder => 't::Test::Scaffolder', class => 't::Test::Class');

ok(! t::Test::Class->can('apple'));
ok(! t::Test::Class->can('banana'));
ok(t::Test::Class->can('loaded'));

