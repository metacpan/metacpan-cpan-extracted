#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

package t::Scaffold::Object;

use Moose;

package t::Scaffold;

use Test::More;

use MooseX::Scaffold;

MooseX::Scaffold->setup_scaffolding_import;

sub SCAFFOLD {
    my ($class, %given) = @_;

    $class->extends( 't::Scaffold::Object' );
    $class->class_has( apple => qw/is rw/ );
    $class->class_has( banana => qw/is rw/ );

    is( $given{cherry}, 2 );
}

package t::ScaffoldProject;

use Moose;
use MooseX::ClassAttribute;

t::Scaffold->import( cherry => 2 );

package main;

ok( t::ScaffoldProject->isa( 't::Scaffold::Object' ) );
ok( t::ScaffoldProject->apple( 1 ) );
ok( !t::ScaffoldProject->banana( 0 ) );

1;
