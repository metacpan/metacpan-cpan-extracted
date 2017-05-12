#!/usr/bin/env perl

use Test::More tests => 3;
use Carp;

use strict;
use warnings;
use SVG::Sparkline;

{
    my $w = SVG::Sparkline->new( Whisker => { values=>'++0+0+', thick=>2 } );
    like( "$w", qr/d="M2,0v-5m6,5v-5m12,5v-5m12,5v-5"/, 'thick=2' );
    like( "$w", qr/stroke-width="2"/, 'thick=2: stroke' );
}

{
    my $b = SVG::Sparkline->new( Bar => { values=>[2,3,5,0,-1,-2,-5], thick=>4 } );
    is( "$b",
        '<svg height="12" viewBox="0 -6 28 12" width="28" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v-2h4v-1h4v-2h4v5h4v1h4v1h4v3h4v-5z" fill="#000" stroke="none" /></svg>',
        'Bar: change thickness.'
    );
}
