#!/usr/bin/env perl

use Test::More tests => 12;
use Carp;
use SVG::Sparkline;

use strict;
use warnings;
my $expect = '<svg height="12" viewBox="0 -6 18 12" width="18" xmlns="http://www.w3.org/2000/svg"><path d="M1,0v-5m3,5v-5m6,5v-5m6,5v-5" stroke="#000" stroke-width="1" /></svg>';

{
    my $w1 = SVG::Sparkline->new( Whisker => { values=>[1,1,0,1,0,1] } );
    isa_ok( $w1, 'SVG::Sparkline', 'pos array: right type' );
    is( "$w1", $expect, 'pos array: output correct' );
    is( "$w1", $w1->to_string, 'Stringify works' );
}

{
    my $w2 = SVG::Sparkline->new( Whisker => { values=>'++0+0+' } );
    isa_ok( $w2, 'SVG::Sparkline', 'pos tickstr: right type' );
    is( "$w2", $expect, 'pos tickstr: output correct' );
}

{
    $expect = '<svg height="12" viewBox="0 -6 18 12" width="18" xmlns="http://www.w3.org/2000/svg"><path d="M1,0v-5m3,5v-5m3,5v5m3,-5v-5m3,5v5m3,-5v-5" stroke="#000" stroke-width="1" /></svg>';
    my $w3 = SVG::Sparkline->new( Whisker => { values=>'110101' } );
    isa_ok( $w3, 'SVG::Sparkline', 'pos binstr: right type' );
    is( "$w3", $expect, 'pos binstr: output correct' );
}

{
    my $w4 = SVG::Sparkline->new( Whisker => { values=>[0,1,1,0,0,-1,-1,-1,1,1,-1,-1] } );
    like( "$w4", qr/d="M4,0v-5m3,5v-5m9,5v5m3,-5v5m3,-5v5m3,-5v-5m3,5v-5m3,5v5m3,-5v5"/,
        'posneg array: correct output' );
}

{
    my $w5 = SVG::Sparkline->new( Whisker => { values=>'0++00---++--' } );
    like( "$w5", qr/d="M4,0v-5m3,5v-5m9,5v5m3,-5v5m3,-5v5m3,-5v-5m3,5v-5m3,5v5m3,-5v5"/,
        'posneg tickstr: correct output' );
}

{
    my $expect = '<svg height="12" viewBox="0 -6 18 12" width="18" xmlns="http://www.w3.org/2000/svg"><path d="M1,0v-5m3,5v-5m6,5v-5m6,5v-5" stroke="#000" stroke-width="1" /></svg>';
    my $w1 = SVG::Sparkline->new( Whisker => { -sized=>1, values=>[1,1,0,1,0,1] } );
    is( "$w1", $expect, 'sized true: output correct' );
}

{
    my $expect = '<svg viewBox="0 -6 18 12" xmlns="http://www.w3.org/2000/svg"><path d="M1,0v-5m3,5v-5m6,5v-5m6,5v-5" stroke="#000" stroke-width="1" /></svg>';

    my $w1 = SVG::Sparkline->new( Whisker => { -sized => 0, values=>[1,1,0,1,0,1] } );
    is( "$w1", $expect, 'sized false: output correct' );
}

{
    my $expect = '<svg height="12" viewBox="0 -6 18 12" width="18" xmlns="http://www.w3.org/2000/svg"><path d="M16,0v0" stroke="#000" stroke-width="1" /></svg>';

    my $w1 = SVG::Sparkline->new( Whisker => { values=>[0,0,0,0,0,0] } );
    is( "$w1", $expect, 'all zero data: output correct' );
}
