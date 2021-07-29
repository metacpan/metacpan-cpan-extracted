#!/usr/bin/env perl

use Test2::V0;
use TCOD;

subtest 'Singleton' => sub {
    ok my $default = TCOD::Random->get_instance, 'Got default instance';
    ok my $copy    = TCOD::Random->get_instance, 'Got another copy';

    is $copy, $default, 'Both copies are the same';
};

subtest 'Save state' => sub {
    ok my $rng = TCOD::Random->new( TCOD::RNG_CMWC ), 'Can create new';
    ok my $backup = $rng->save, 'Can save state';

    my @numbers = map $rng->get_int( 0, 100 ), 0 .. 10;

    $rng->restore($backup);
    is \@numbers, [ map $rng->get_int( 0, 100 ), 0 .. 10 ],
        'Random number generator is restorable';
};

subtest 'Generators' => sub {
    my $rng = TCOD::Random->new_from_seed( TCOD::RNG_CMWC, 1234 );

    is [ map $rng->get_int( 1, 10 ), 0 .. 10 ],
        [ 5, 10, 4, 1, 4, 10, 8, 4, 8, 4, 2 ], 'Can get integers in a range';

    is [ map $rng->get_int_mean( 1, 10, 5 ), 0 .. 10 ],
        [ 2, 3, 4, 6, 3, 4, 5, 7, 7, 5, 4 ], 'Can get integers in a range with mean';

    is [ map $rng->get_float( 1, 10 ), 0 .. 10 ] => [
        within( 4.53, 0.01 ),
        within( 9.33, 0.01 ),
        within( 8.53, 0.01 ),
        within( 1.63, 0.01 ),
        within( 4.04, 0.01 ),
        within( 1.78, 0.01 ),
        within( 6.83, 0.01 ),
        within( 1.18, 0.01 ),
        within( 4.31, 0.01 ),
        within( 8.49, 0.01 ),
        within( 9.61, 0.01 ),
    ] => 'Can get floats in a range';

    is [ map $rng->get_float_mean( 1, 10, 5 ), 0 .. 10 ] => [
        within( 9.46, 0.01 ),
        within( 5.62, 0.01 ),
        within( 4.18, 0.01 ),
        within( 5.68, 0.01 ),
        within( 4.96, 0.01 ),
        within( 5.95, 0.01 ),
        within( 5.96, 0.01 ),
        within( 1,    0.01 ),
        within( 7.44, 0.01 ),
        within( 6.79, 0.01 ),
        within( 6.14, 0.01 ),
    ] => 'Can get floats in a range with mean';

    is [ map $rng->get_double( 1, 10 ), 0 .. 10 ] => [
        within( 2.06, 0.01 ),
        within( 7.48, 0.01 ),
        within( 6.75, 0.01 ),
        within( 6.23, 0.01 ),
        within( 2.29, 0.01 ),
        within( 5.83, 0.01 ),
        within( 9.50, 0.01 ),
        within( 7.82, 0.01 ),
        within( 5.69, 0.01 ),
        within( 1.95, 0.01 ),
        within( 4.73, 0.01 ),
    ] => 'Can get doubles in a range';

    is [ map $rng->get_double_mean( 1, 10, 5 ), 0 .. 10 ] => [
        within( 4.67, 0.01 ),
        within( 2.13, 0.01 ),
        within( 3.92, 0.01 ),
        within( 5.93, 0.01 ),
        within( 7.80, 0.01 ),
        within( 4.48, 0.01 ),
        within( 2.62, 0.01 ),
        within( 5.57, 0.01 ),
        within( 2.43, 0.01 ),
        within( 6.71, 0.01 ),
        within( 3.24, 0.01 ),
    ] => 'Can get doubles in a range with mean';
};

done_testing;
