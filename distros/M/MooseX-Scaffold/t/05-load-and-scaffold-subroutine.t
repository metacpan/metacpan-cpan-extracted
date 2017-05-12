#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use MooseX::Scaffold;

MooseX::Scaffold->scaffold(class => 't::Test::Class', scaffolder => sub {

    my ($class, %given) = @_;

    $class->class_has(cherry => qw/is rw/);
    $class->class_has(grape => qw/is rw/);

    $class->package->cherry(4);
    $class->package->grape(5);

});

ok(! t::Test::Class->can('apple'));
ok(! t::Test::Class->can('banana'));
is(t::Test::Class->cherry, 4);
is(t::Test::Class->grape, 5);
ok(t::Test::Class->loaded);

