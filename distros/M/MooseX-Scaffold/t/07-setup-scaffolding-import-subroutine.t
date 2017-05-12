#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use MooseX::Scaffold;

MooseX::Scaffold->setup_scaffolding_import(exporting_package => 't::Scaffolder', scaffolder => sub {
    my ( $class, %given ) = @_;

    $class->class_has( fig => qw/is rw/ );
    $class->class_has( lime => qw/is rw/ );

    $class->package->fig( 1 );
    $class->package->lime( 2 );

    TODO: {

        local $TODO = "Need to nail down concepts and names";

        is( $given{exporting_package}, 't::Scaffolder' );

    }

    is( $given{cherry}, 4 );

});

package t::Class;

t::Scaffolder->import(cherry => 4);

package main;

is(t::Class->fig, 1);
is(t::Class->lime, 2);
