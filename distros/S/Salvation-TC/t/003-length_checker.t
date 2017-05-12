#!/usr/bin/perl -w

use strict;
use warnings;

{
    require Carp;

    $SIG{ '__DIE__' } = sub {

        print STDERR Carp::longmess( 'Uncaught die()' );

        Test::More::fail();
    };
};

use Test::More tests => 27;
use Salvation::TC ();

cmp_ok( Salvation::TC -> is( 'asd', 'Str{3}' ), '==', 1 );
cmp_ok( Salvation::TC -> is( 'asd', 'Str{2}' ), '==', 0 );
cmp_ok( Salvation::TC -> is( 'asd', 'Str{4}' ), '==', 0 );

cmp_ok( Salvation::TC -> is( 'asd', 'Str{2,3}' ), '==', 1 );
cmp_ok( Salvation::TC -> is( 'asd', 'Str{1,2}' ), '==', 0 );
cmp_ok( Salvation::TC -> is( 'asd', 'Str{4,5}' ), '==', 0 );

cmp_ok( Salvation::TC -> is( 'asd', 'Str{2,}' ), '==', 1 );
cmp_ok( Salvation::TC -> is( 'asd', 'Str{3,}' ), '==', 1 );
cmp_ok( Salvation::TC -> is( 'asd', 'Str{4,}' ), '==', 0 );

cmp_ok( Salvation::TC -> is( [ 1, 2, 3 ], 'ArrayRef{3}' ), '==', 1 );
cmp_ok( Salvation::TC -> is( [ 1, 2, 3 ], 'ArrayRef{2,}' ), '==', 1 );
cmp_ok( Salvation::TC -> is( [ 1, 2, 3 ], 'ArrayRef{4,7}' ), '==', 0 );
cmp_ok( Salvation::TC -> is( [], 'ArrayRef{1,}' ), '==', 0 );
cmp_ok( Salvation::TC -> is( [], 'ArrayRef{0}' ), '==', 1 );

cmp_ok( Salvation::TC -> is( [ 1, 2, 3 ], 'ArrayRef[Int]{2,3}' ), '==', 1 );
cmp_ok( Salvation::TC -> is( [ 1, 2, 3 ], 'ArrayRef[ArrayRef]{3}' ), '==', 0 );
cmp_ok( Salvation::TC -> is( [ [ 1 ], [ 2 ], [ 3 ] ], 'ArrayRef[ArrayRef[Int]{1}]{3}' ), '==', 1 );
cmp_ok( Salvation::TC -> is( [ [ 1 ], [ 2 ], [] ], 'ArrayRef[ArrayRef[Int]{1}]{3}' ), '==', 0 );

cmp_ok( Salvation::TC -> is( { a => 1, b => 2, c => 3 }, 'HashRef{3}' ), '==', 1 );
cmp_ok( Salvation::TC -> is( { a => 1, b => 2, c => 3 }, 'HashRef{2,}' ), '==', 1 );
cmp_ok( Salvation::TC -> is( { a => 1, b => 2, c => 3 }, 'HashRef{4,7}' ), '==', 0 );
cmp_ok( Salvation::TC -> is( {}, 'HashRef{1,}' ), '==', 0 );
cmp_ok( Salvation::TC -> is( {}, 'HashRef{0}' ), '==', 1 );

cmp_ok( Salvation::TC -> is(
    [ { id => 'asd', qwe => 'zxc' } ],
    'ArrayRef[
        HashRef[Str{3}]
        (Str{3} :id!)
    ]( HashRef[ Str{ 3 } ]( Str{ 3 } :qwe! ) el ){ 1 }'
), '==', 1 );

cmp_ok( Salvation::TC -> is(
    [ { id => 'asd', qwe => 'zxcv' } ],
    'ArrayRef[
        HashRef[Str{3}]
        (Str{3} :id!)
    ]( HashRef[ Str{ 3 } ]( Str{ 3 } :qwe! ) el ){ 1 }'
), '==', 0 );

cmp_ok( Salvation::TC -> is(
    [ { id => 'asdf', qwe => 'zxc' } ],
    'ArrayRef[
        HashRef[Str{3}]
        (Str{3} :id!)
    ]( HashRef[ Str{ 3 } ]( Str{ 3 } :qwe! ) el ){ 1 }'
), '==', 0 );

cmp_ok( Salvation::TC -> is(
    [
        { id => 'asd', qwe => 'zxc' },
        { id => 'asd', qwe => 'zxc' },
    ],
    'ArrayRef[
        HashRef[Str{3}]
        (Str{3} :id!)
    ]( HashRef[ Str{ 3 } ]( Str{ 3 } :qwe! ) el ){ 1 }'
), '==', 0 );

exit 0;

__END__
