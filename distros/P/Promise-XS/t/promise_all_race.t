#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Promise::XS;

my $p1 = Promise::XS::resolved(2, 3);
my $p2 = Promise::XS::resolved(4);

$p1->all($p1, $p2)->then( sub {
    my (@got)  = @_;

    is_deeply(
        \@got,
        [
            [ 2, 3 ],
            [ 4 ],
        ],
        'all() works as a method of the promise object',
    );
} );

Promise::XS::Promise->all($p1, $p2)->then( sub {
    my (@got)  = @_;

    is_deeply(
        \@got,
        [
            [ 2, 3 ],
            [ 4 ],
        ],
        'all() works as a class method',
    );
} );

#----------------------------------------------------------------------

$p1->race($p1, $p2)->then( sub {
    my (@got)  = @_;

    is_deeply(
        \@got,
        [ 2, 3 ],
        'race() works as a method of the promise object',
    );
} );

Promise::XS::Promise->race($p1, $p2)->then( sub {
    my (@got)  = @_;

    is_deeply(
        \@got,
        [ 2, 3 ],
        'race() works as a class method',
    );
} );

done_testing();

1;
