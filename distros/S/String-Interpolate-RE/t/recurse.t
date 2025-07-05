#!perl

use Test2::V0;

use String::Interpolate::RE qw( strinterp );

my %vars = ( a => '$b', b => '$c', c => '$d', d => 'the_end' );


# check that the recursion limit failures work
foreach ( [ 0 => 0 ], [ 1 => 1 ], [ 2 => 1 ], [ 3 => 1 ], [ 4 => 0 ] ) {

    my ( $limit, $exp ) = @$_;

    if ( $exp ) {

        like(
            dies { strinterp( '$a', \%vars, { recurse => 1, recurse_fail_limit => $limit } ) },
            qr/recursion fail-safe limit/,
            "recursion fail limit = $limit"
        ) or BAIL_OUT( "fail-safe recursion limit doesn't work! Must Abort!\n" );
    }

    else {
        ok( lives { strinterp( '$a', \%vars, { recurse => 1, recurse_fail_limit => $limit } ) },
            "recursion fail limit = $limit" )
          or BAIL_OUT( "fail-safe recursion limit doesn't work! Must Abort!\n" );
    }
}


is( strinterp( '$a', \%vars ), '$b', 'no recursion' );

is( strinterp( '$a', \%vars, { recurse => 1, } ), 'the_end', 'full recursion' );

foreach ( [ 0 => 'the_end' ], [ 1 => '$c' ], [ 2 => '$d' ], [ 3 => 'the_end' ] ) {

    my ( $limit, $exp ) = @$_;

    is( strinterp( '$a', \%vars, { recurse => 1, recurse_limit => $limit } ),
        $exp, "recursion limit = $limit" );
}



# make sure that more complex variable interpolations work
is( strinterp( '$a/$c/$d', \%vars, { recurse => 1 } ),
    'the_end/the_end/the_end', 'recursion w/ multiple variables in parallel' );


# and now the dangerous one; circular dependencies

foreach (
    [ 'loop => 0 <= 0', '$a', { a => '$a' } ],
    [ 'loop => 0 <= 1', '$a', { a => '$b', b => '$a' } ],
    [ 'loop => 1 <= 2', '$a', { a => '$b', b => '$c', c => '$b' } ],
    [ 'loop => 1 <= 3', '$a', { a => '$b', b => '$c', c => '$d', d => '$c' } ],
  )
{

    my ( $label, $str, $var ) = @$_;

    like(
        dies { strinterp( $str, $var, { recurse => 1 } ) },
        qr/circular interpolation loop detected/,
        "dependency loops: $label"
    );

}

done_testing;
