#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

package t::Scaffolder;

use MooseX::Scaffold;

MooseX::Scaffold->setup_scaffolding_import;

sub SCAFFOLD {
    my ($class, %given) = @_;

    $class->class_has(fig => qw/is rw/);
    $class->class_has(lime => qw/is rw/);

    $class->package->fig(1);
    $class->package->lime(2);
}

package t::Class;

t::Scaffolder->import;

package main;

is(t::Class->fig, 1);
is(t::Class->lime, 2);

package t::UseClass;

use t::Test::UseScaffolder;

package main;

is(t::UseClass->melon, 1);
is(t::UseClass->apricot, 2);
