#!perl

use Test2::V0;

use String::Interpolate::RE qw( strinterp );

my %vars = ( a => '1', b => '2' );

for my $test ( [ var => \%vars ], [ function => sub { $vars{ $_[0] } } ] ) {

    my ( $label, $vars ) = @$test;

    subtest $label => sub {

        local %ENV;

        $ENV{a} = '11';
        $ENV{b} = '22';


        is( strinterp( '$a', $vars ), '1',  'defined in %vars' );
        is( strinterp( '$a' ),        '11', 'defined in %ENV' );
        is( strinterp( '${a}' ),      '11', 'use {}' );

        # make sure both $a and ${a} work


        # undefined
        is( strinterp( '$c' ),                          '$c', 'not defined' );
        is( strinterp( '$c', {}, { EmptyUndef => 1 } ), '',   'not defined; EmptyUndef' );

        eval { strinterp( '$c', {}, { RaiseUndef => 1 } ); };

        ok( $@, 'not defined; RaiseUndef' );

        # don't use %ENV

        $ENV{c} = '33';
        is( strinterp( '$a', $vars, { UseEnv => 0 } ), '1',  'defined; UseENV => 0' );
        is( strinterp( '$c', {},    { UseEnv => 0 } ), '$c', 'not defined; UseENV => 0' );


        # test effect on the rest of the string
        is( strinterp( '$c/b' ),   '33/b',   'side effects: front' );
        is( strinterp( 'a/$c/b' ), 'a/33/b', 'side effects: middle' );
        is( strinterp( 'a/$c' ),   'a/33',   'side effects: end' );


        # test multiple substitutions
        is( strinterp( '$a/$b/$c', $vars ), '1/2/33', 'multiple substitutions' );
        is( strinterp( '$a/$a/$a', $vars ), '1/1/1',  'multiple identical substitutions' );

    }

}

subtest 'fallback ' => sub {

    # $vars is a hashref
    is( strinterp( '$a/$b/$c/$d', { a => 1, b => 2 }, { fallback => sub { { c => 3 }->{ $_[0] } } }, ),
        '1/2/3/$d' );

    # $vars is a coderef, fallback is ignored.
    is(
        strinterp(
            '$a/$b/$c/$d',
            sub { { a => 1, b => 2 }->{ $_[0] } },
            { fallback => sub { { c => 3 }->{ $_[0] } } },
        ),
        '1/2/$c/$d',
    );

};


done_testing;
