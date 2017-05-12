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

use Test::More tests => 21;

use Salvation::TC ();
use Salvation::TC::Utils;


subtype 'CustomString',
    as 'Str',
    where { $_ eq 'asd' };

subtype 'ArrayRefOfCustomStrings',
    as 'ArrayRef[CustomString]',
    where { 1 };

coerce 'ArrayRefOfCustomStrings',
    from 'CustomString',
    via { [ $_ ] };

type 'CustomTopLevelType',
    where { ( ref( $_ ) eq 'HASH' ) && exists $_ -> { 'asd' } };

coerce 'CustomTopLevelType',
    from 'Str',
    via { return { $_ => undef } };

foreach my $spec (
    [ 'First', 'ewq' ],
    [ 'Second', 'dsa' ],
    [ 'Third', 'cxz' ],
) {
    my ( $name, $key ) = @$spec;

    subtype "${name}UnionElType",
        as 'HashRef',
        where { exists $_ -> { $key } };

    subtype "Source${name}UnionElType",
        as 'Str',
        where { $_ eq $key };

    coerce "${name}UnionElType",
        from "Source${name}UnionElType",
        via { return { $key => $name } };
}


no Salvation::TC::Utils;


cmp_ok( Salvation::TC -> is( 'asd', 'Str' ), '==', 1, '"asd" is Str' );
cmp_ok( Salvation::TC -> is( 'asd', 'CustomString' ), '==', 1, '"asd" is CustomString' );
cmp_ok( Salvation::TC -> is( 'asd', 'ArrayRef[CustomString]' ), '==', 0, '"asd" is not ArrayRef[CustomString]' );
cmp_ok( Salvation::TC -> is( 'asd', 'ArrayRefOfCustomStrings' ), '==', 0, '"asd" is not ArrayRefOfCustomStrings' );

cmp_ok( Salvation::TC -> is( [ 'asd' ], 'Str' ), '==', 0, '["asd"] is not Str' );
cmp_ok( Salvation::TC -> is( [ 'asd' ], 'CustomString' ), '==', 0, '["asd"] is not CustomString' );
cmp_ok( Salvation::TC -> is( [ 'asd' ], 'ArrayRef[CustomString]' ), '==', 1, '["asd"] is ArrayRef[CustomString]' );
cmp_ok( Salvation::TC -> is( [ 'asd' ], 'ArrayRefOfCustomStrings' ), '==', 1, '["asd"] is ArrayRefOfCustomStrings' );

is_deeply( Salvation::TC -> coerce( 'asd', 'ArrayRefOfCustomStrings' ), [ 'asd' ], '"asd" coerced to ArrayRefOfCustomStrings is ["asd"]' );
is_deeply( Salvation::TC -> coerce( 'asd', 'ArrayRef[CustomString]' ), 'asd', '"asd" coerced to ArrayRef[CustomString] is "asd"' );

cmp_ok(
    Salvation::TC -> is(
        Salvation::TC -> coerce(
            'asd',
            'ArrayRefOfCustomStrings'
        ),
        'ArrayRef[CustomString]'
    ),
    '==', 1,
    '"asd" coerced to ArrayRefOfCustomStrings is ArrayRef[CustomString]'
);

cmp_ok( Salvation::TC -> is( 'asd', 'CustomTopLevelType' ), '==', 0, '"asd" is not CustomTopLevelType' );
cmp_ok( Salvation::TC -> is( { asd => 123 }, 'CustomTopLevelType' ), '==', 1, '{asd=>123} is CustomTopLevelType' );
cmp_ok( Salvation::TC -> is( { asd => 123 }, 'HashRef' ), '==', 1, '{asd=>123} is HashRef' );
cmp_ok( Salvation::TC -> is( { asd => 123 }, 'HashRef[Int]' ), '==', 1, '{asd=>123} is HashRef[Int]' );
is_deeply( Salvation::TC -> coerce( 'asd', 'CustomTopLevelType' ), { asd => undef }, '"asd" coerced to CustomTopLevelType is {asd=>undef}' );
cmp_ok( Salvation::TC -> is( { qwe => 123 }, 'CustomTopLevelType' ), '==', 0, '{qwe=>123} is not CustomTopLevelType' );

cmp_ok(
    Salvation::TC -> is(
        Salvation::TC -> coerce(
            'asd',
            'CustomTopLevelType'
        ),
        'CustomTopLevelType'
    ),
    '==', 1,
    '"asd" coerced to CustomTopLevelType is CustomTopLevelType (obv)'
);

{
    my $union = 'FirstUnionElType|SecondUnionElType|ThirdUnionElType';

    is_deeply( Salvation::TC -> coerce( 'ewq', $union ), { ewq => 'First' }, '"ewq" coerced to ' . $union . ' is {ewq=>"First"}' );
    is_deeply( Salvation::TC -> coerce( 'dsa', $union ), { dsa => 'Second' }, '"dsa" coerced to ' . $union . ' is {dsa=>"Second"}' );
    is_deeply( Salvation::TC -> coerce( 'cxz', $union ), { cxz => 'Third' }, '"cxz" coerced to ' . $union . ' is {cxz=>"Third"}' );
}

exit 0;

__END__
