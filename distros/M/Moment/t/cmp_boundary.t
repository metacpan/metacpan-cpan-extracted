use strict;
use warnings FATAL => 'all';
use Test::More;

use Moment;

sub main_in_test {

    my $timestamp = 1000000000;

    is(
        Moment->new( timestamp => $timestamp )->cmp(
            Moment->new( timestamp => $timestamp + 1 )
        ),
        -1,
        'cmp() -1'
    );

    is(
        Moment->new( timestamp => $timestamp )->cmp(
            Moment->new( timestamp => $timestamp )
        ),
        0,
        'cmp() 0'
    );

    is(
        Moment->new( timestamp => $timestamp )->cmp(
            Moment->new( timestamp => $timestamp - 1 )
        ),
        1,
        'cmp() 1'
    );

    done_testing;

}
main_in_test();
