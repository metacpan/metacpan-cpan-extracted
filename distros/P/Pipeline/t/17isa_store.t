#!/usr/bin/perl -w

use lib './lib';
use strict;
use warnings;

use Test::More tests => 5;

use Pipeline::Store::ISA;

my $store = Pipeline::Store::ISA->new();

# scenario 1 - single object in store
my $obj1 = TestObj->new();
is( $store->set( $obj1 ), $store, 'set(obj)' );
is( $store->get( 'TestObj' ), $obj1, 'get(obj)' );

# scenario 2 - can't have two objs of the same type in store
my $obj2 = TestObj->new();
$store->set( $obj2 );
is( $store->get( 'TestObj' ), $obj2, 'set replaces obj' );

# scenario 3 - two objs of diff type, but same base class in store
my $obj3 = TestObj2->new();
$store->set( $obj3 );
isa_ok( $store->get( 'TestObjBase' ), 'ARRAY', 'get(base class)' );
isa_ok( $store->get( 'TestObjBase' ), 'ARRAY', 'get(base class)' );

package TestObjBase;
use base qw( Pipeline::Base );

package TestObj;
use base qw( TestObjBase );

package TestObj2;
use base qw( TestObjBase );
