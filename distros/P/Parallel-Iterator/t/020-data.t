# $Id: 020-data.t 2683 2007-10-04 12:35:06Z andy $
use strict;
use warnings;
use Test::More tests => 1;
use Parallel::Iterator qw( iterate_as_array );

{
    my @input = (
        {
            type  => 'hash',
            value => 2
        },
        [ 1, 2, 3 ],
        "Hello"
    );

    my @want = (
        {
            type  => 'hash',
            value => 10
        },
        [ 4, 5, 6, 7, 8, 9 ],
        "HelloHello"
    );

    my @got = iterate_as_array(
        { workers => 1, nowarn => 1 },
        sub {
            my ( $id, $job ) = @_;
            if ( ref $job ) {
                if ( 'HASH' eq ref $job ) {
                    $job->{value} *= 5;
                    return $job;
                }
                elsif ( 'ARRAY' eq ref $job ) {
                    return [ 4, 5, 6, 7, 8, 9 ];
                }
            }
            else {
                return $job . $job;
            }
        },
        \@input
    );

    is_deeply \@got, \@want, "data structure";
}

1;
