#!/usr/bin/perl

# t/05.scalar.t - check scalar manipulation object

use Test::More qw( no_plan );
use strict;
use warnings;
use lib './lib';

BEGIN { use_ok( 'Module::Generic::Iterator' ) || BAIL_OUT( "Unable to load Module::Generic::Iterator" ); }

my $a = Module::Generic::Iterator->new( [qw( John Jack Paul Peter Simon )], { debug => 0 } );

isa_ok( $a, 'Module::Generic::Iterator', 'Iterator object' );

is( $a->length, 5, 'Iterator size' );

is( $a->pos, 0, "Initial iterator position" );

ok( !$a->eof, "Iterator is not at the end of the stack" );

my $elem = $a->find( 'Jack' );
isa_ok( $elem, 'Module::Generic::Iterator::Element', 'Iterator element object' );

is( $elem->value, 'Jack', 'Element value' );

my $not_found = $a->find( 'Bob' );
ok( !defined( $not_found ), 'Element not found is undefined' );

my $first = $a->first;
isa_ok( $first, 'Module::Generic::Iterator::Element', 'First iterator element object' );

is( $first->value, 'John', 'Correct first element value' );

ok( $a->has_next, "Next element exists" );

ok( !$a->has_prev, "No previous element at begining of stack" );

my $last = $a->last;

isa_ok( $last, 'Module::Generic::Iterator::Element', 'Last iterator element object' );

is( $last->value, 'Simon', 'Correct first element value' );

ok( !$a->has_next, "No next element at end of stack" );

ok( $a->has_prev, "Previous element exists" );

is( $a->pos, 4, "Position is at the end of stack" );

$a->pos = 3;

is( $a->pos, 3, "Position set as lvalue" );

$a->reset;

is( $a->pos, 0, "Position is now back at the beginning of stack" );

# Checking Module::Generic::Iterator::Element methods

ok( $first->has_next, "First element has next element" );

ok( !$last->has_next, "Last element has no next element" );

ok( !$first->has_prev, "First element has no next previous" );

ok( $last->has_prev, "Last element has previous element" );

isa_ok( $first->parent, 'Module::Generic::Iterator', 'Element parent object class' );

is( $first->pos, 0, "First element position" );

is( $last->pos, 4, "Last element position" );
