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

use Moose;
use Test::Exception;

throws_ok {
    t::Scaffolder->import;
} qr/Can't add class attribute: You need to 'use MooseX::ClassAttribute' in t::Class/;
