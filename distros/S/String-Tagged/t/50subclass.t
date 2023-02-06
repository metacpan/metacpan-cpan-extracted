#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

package STSubclass;
use base qw( String::Tagged );

package main;

my $foo = STSubclass->new( "foo" );
isa_ok( $foo, [ "STSubclass" ], '$foo' );
isa_ok( $foo, [ "String::Tagged" ], '$foo' );

isa_ok( $foo . "bar", [ "STSubclass" ], 'concat plain after' );
isa_ok( "bar" . $foo, [ "STSubclass" ], 'concat plain before' );

my $bar = String::Tagged->new( "bar" );

isa_ok( $foo . $bar, [ "STSubclass" ], 'concat plain after' );
isa_ok( $bar . $foo, [ "STSubclass" ], 'concat plain before' );

done_testing;
