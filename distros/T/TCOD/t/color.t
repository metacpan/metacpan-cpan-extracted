#!/usr/bin/env perl

use Test2::V0;
use TCOD;

subtest 'Basic' => sub {
    my $color = TCOD::Color->new( 0x33, 0x66, 0x99 );

    is [ $color->r, $color->g, $color->b ], [ 0x33, 0x66, 0x99 ],
        'Got RGB components';
};

subtest 'HSV setters and getters' => sub {
    my $color = TCOD::BLACK;

    my ( $h, $s, $v ) = $color->get_HSV;

    is [ $h, $s, $v ] => [ 0, 0, 0 ] => 'Got HSV';

    is $color->get_hue,        $h, 'Got hue';
    is $color->get_saturation, $s, 'Got saturation';
    is $color->get_value,      $v, 'Got value';

    $color->set_HSV( 360, 0.6, 0.9 );

    is [ $color->get_HSV ] =>[
        0, # 360 degrees = 0 degrees
        within(0.599999964237213),
        within(0.901960790157318),
    ] => 'Got new HSV';

    $color->set_hue( 210 );
    $color->set_saturation( 0.3 );
    $color->set_value( 0.3 );

    is [ $color->get_HSV ] =>[
        within(211.304336547852),
        within(0.29870131611824),
        within(0.301960796117783),
    ] => 'Used individual setters for HSV';

    isnt $color, TCOD::BLACK, 'Color constants are imutable';
};

subtest 'Shift hue' => sub {
    my $shifted = TCOD::YELLOW;
    $shifted->shift_hue(15);
    is $shifted->get_hue, within( TCOD::YELLOW->get_hue + 15, 0.1 ),
        'Shift hue by degrees';
};

subtest 'Scale HSV' => sub {
    my $scaled = TCOD::YELLOW;
    $scaled->scale_HSV( 0.25, 0.75 );
    is [ $scaled->get_HSV ] => [
        TCOD::YELLOW->get_hue,
        within( TCOD::YELLOW->get_saturation * 0.25, 0.1 ),
        within( TCOD::YELLOW->get_value      * 0.75, 0.1 ),
    ] => 'Scale HSV';
};

subtest 'Interpolation' => sub {
    my $start = TCOD::Color->new( 0x00, 0x80, 0xff );
    my $mid   = TCOD::Color->new( 0x7f, 0x80, 0x7f );
    my $end   = TCOD::Color->new( 0xff, 0x80, 0x00 );

    is $start->lerp( $end, 0   ), $start, 'Interpolated at 0';
    is $start->lerp( $end, 0.5 ), $mid,   'Interpolated at 0.5';
    is $start->lerp( $end, 1   ), $end,   'Interpolated at 1';

    is [ TCOD::Color::gen_map( $start => 0, $mid => 7, $end => 9 ) ] => [
        $start,
        TCOD::Color->new( 0x12, 0x80, 0xec ),
        TCOD::Color->new( 0x24, 0x80, 0xda ),
        TCOD::Color->new( 0x36, 0x80, 0xc8 ),
        TCOD::Color->new( 0x48, 0x80, 0xb5 ),
        TCOD::Color->new( 0x5a, 0x80, 0xa3 ),
        TCOD::Color->new( 0x6c, 0x80, 0x91 ),
        $mid,
        TCOD::Color->new( 0xbf, 0x80, 0x3f ),
        $end,
    ] => 'Generated color map';
};

subtest 'Operators' => sub {
    ok TCOD::BLACK == TCOD::BLACK, '==';
    ok TCOD::BLACK != TCOD::WHITE, '!=';

    is +TCOD::Color->new( 1, 2, 3 ) + TCOD::Color->new( 3, 2, 1 ),
        TCOD::Color->new( 4, 4, 4 ), '+';

    is +TCOD::Color->new( 4, 4, 4 ) - TCOD::Color->new( 3, 2, 1 ),
        TCOD::Color->new( 1, 2, 3 ), '-';

    is TCOD::WHITE * TCOD::BLACK, TCOD::BLACK, '* (color)';
    is TCOD::WHITE * 0, TCOD::BLACK, '* (scalar)';

    is '' . TCOD::GREY, '#7f7f7f', '""';
};

done_testing;
