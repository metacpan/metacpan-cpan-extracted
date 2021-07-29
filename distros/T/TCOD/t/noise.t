#!/usr/bin/env perl

use Test2::V0;
use TCOD;

subtest 'Generators' => sub {
    my $rng   = TCOD::Random->new_from_seed( TCOD::RNG_CMWC, 1234 );
    ok my $noise = TCOD::Noise->new(
        2, TCOD::NOISE_DEFAULT_HURST, TCOD::NOISE_DEFAULT_LACUNARITY, $rng ),
        'Can create noise generator';

    is $noise->get(            [ 1, 1 ] ), within( -0.175, 0.001 ), 'Got noise';
    is $noise->get_fbm(        [ 1, 1 ] ), within(  0,     0.001 ), 'Got fbm noise';        # TODO: a non-zero value?
    is $noise->get_turbulence( [ 1, 1 ] ), within(  0,     0.001 ), 'Got turbulence noise'; # TODO: a non-zero value?
};

done_testing;
