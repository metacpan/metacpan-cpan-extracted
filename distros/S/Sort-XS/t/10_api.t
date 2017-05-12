use strict;
use warnings;
use Test::More;
use Sort::XS;

can_ok( 'Sort::XS', 'xsort' );

my $tests = {
    integer => [ [ 1, 5, 3 ], [ 1 .. 10, 2 .. 11 ], [ 10 .. 1 ], [ 1 .. 10 ] ],
    string => [
        [ 'kiwi',       'banana', 'apple', 'cherry' ],
        [ 'aa' .. 'ae', 'ac' .. 'am' ],
        [ 'z' .. 'a' ],
        [ 'a' .. 'z' ]
    ]
};

my @algos = qw/quick heap merge insertion perl/;

foreach my $type ( keys %$tests ) {
    foreach my $set ( @{ $tests->{$type} } ) {
        my @sorted;
        @sorted = sort { $a <=> $b } @$set if ( $type eq 'integer' );
        @sorted = sort { $a cmp $b } @$set if ( $type eq 'string' );

        if ( $type eq 'integer' ) {
            is_deeply( xsort($set), \@sorted,
                "can sort $type using one argument" );

            is_deeply( xsort( list => $set ),
                \@sorted, "can sort $type using a hash argument" )
              ;

            map {
                is_deeply( xsort( $set, algorithm => $_ ),
                    \@sorted, "can sort $type use algorithm $_" )
            } @algos;

            # check ixsort usage
            is_deeply( ixsort( list => $set ),
                \@sorted, "ixsort $type using a hash argument" );

            map {
                is_deeply( ixsort( $set, algorithm => $_ ),
                    \@sorted, "ixsort $type use algorithm $_" )
            } @algos;

        }
        else {

            # check sxsort usage
            is_deeply( sxsort( list => $set ),
                \@sorted, "sxsort $type using a hash argument" );
            is_deeply( sxsort( list => $set, type => 'integer' ),
                \@sorted, "sxsort type is not overwritten" );

            map {
                is_deeply( sxsort( $set, algorithm => $_ ),
                    \@sorted, "sxsort $type use algorithm $_" );
                is_deeply( sxsort( $set, algorithm => $_, type => 'integer' ),
                    \@sorted, "sxsort data type is not overwritten" );
            } @algos;
        }

        is_deeply( xsort( $set, algorithm => 'perl', type => $type ),
            \@sorted,
            "can sort $type using a hash argument without list attribute" );
        is_deeply( xsort( list => $set, algorithm => 'perl', type => $type ),
            \@sorted, "can sort $type using a hash argument" );
    }
}

# bad usage
my @bad_usage = (
    [ [ 10 .. 1 ], algorithm => 'unknown' ],
    [ list => [ 10 .. 1 ], algorithm => 'unknown' ],
    [], ['not a list'], [51],
);
foreach my $params (@bad_usage) {

    eval { xsort(@$params); };
    like( $@, '/\w+/', "can detect an error" );
}

done_testing;

