#!/usr/bin/perl

##
## Tests for Pangloss::Collection
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Error qw( :try );
use Test::More 'no_plan';

BEGIN { use_ok("Pangloss::Collection"); }
BEGIN { use_ok('TestCollection'); }
BEGIN { use_ok('TestCollectionObject'); }

my $col = new TestCollection()
  || fail('new') && die("cannot proceed\n");

is( $col->size, 0,  'size' );
ok( $col->is_empty, 'is_empty' );

is( scalar @{ $col->keys },   0, 'keys' );
is( scalar @{ $col->values }, 0, 'values' );
is( scalar @{ $col->list },   0, 'list' );

{
    my $e;
    try { $col->get( 'non-existent' ); }
    catch Error with { $e = shift; };
    isa_ok( $e, 'Error', 'get non-existent' );
}

my $obj  = TestCollectionObject->new->id( 1 );
my $obj0 = TestCollectionObject->new->id( 0 );
is( $col->add( $obj, $obj0 ), $col, 'add' );

is( $col->size, 2,   'size' );
ok( $col->not_empty, 'not_empty' );

is( scalar @{ $col->keys },   2,   'keys' );
is( scalar @{ $col->values }, 2,   'values' );
is( scalar @{ $col->list },   2,   'list' );
is( $col->sorted_list->[0], $obj0, 'sorted_list' );

my $iterator = $col->iterator;
isa_ok( $iterator, 'CODE', 'iterator' );
isa_ok( $iterator->(), 'TestCollectionObject', 'iterator->()' );

ok( $col->exists( $obj->id ),    'exists' );
is( $col->get( $obj->id ), $obj, 'get' );
ok( $col->exists( $obj ),        'exists(obj)' );
is( $col->get( $obj ), $obj,     'get(obj)' );

my $clone = $col->clone;
isa_ok( $clone, $col->class, 'clone class' );
isnt( $clone, $col,          'clone collection' );

my $deep_clone = $col->deep_clone;
isa_ok( $deep_clone, $col->class, 'deep_clone class' );
isnt( $deep_clone, $col,          'deep_clone collection' );
my $obj2;
try { $obj2 = $deep_clone->get( $obj->key ) }
catch Error with { fail('deep_clone->get: ' . shift) };
if (isa_ok( $obj2, $obj->class, 'deep_clone->get(key)' )) {
    isnt( $obj2, $obj, 'deep_clone obj copied' );
}

{
    my $e;
    try { $col->add( $obj ); }
    catch Error with { $e = shift; };
    isa_ok( $e, 'Error', 'add existing' );
}

is( $col->remove( $obj ), $col, 'remove' );

{
    my $e;
    try { $col->remove( $obj->{id} ); }
    catch Error with { $e = shift; };
    isa_ok( $e, 'Error', 'remove non-existent' );
}

ok(! $col->exists( $obj->{id} ), 'does not exist' );

