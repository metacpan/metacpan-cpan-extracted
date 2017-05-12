#!/usr/bin/env perl

use Test::More tests => 8;
use Carp;
use SVG::Sparkline;

use strict;
use warnings;

{
    my $w = SVG::Sparkline->new( Whisker => { values=>'++0+0+', width=>18 } );
    like( "$w", qr/d="M1,0v-5m3,5v-5m6,5v-5m6,5v-5"/, 'Width=18' );
    like( "$w", qr/stroke-width="1"/, 'Width=18: stroke' );
}

{
    my $w = SVG::Sparkline->new( Whisker => { values=>'++0+0+', width=>9 } );
    like( "$w", qr/d="M0.5,0v-5m1.5,5v-5m3,5v-5m3,5v-5"/, 'Width=9' );
    like( "$w", qr/stroke-width="0.5"/, 'Width=9: stroke' );
}

{
    my $w = SVG::Sparkline->new( Whisker => { values=>'++0+0+', width=>36 } );
    like( "$w", qr/d="M2,0v-5m6,5v-5m12,5v-5m12,5v-5"/, 'Width=36' );
    like( "$w", qr/stroke-width="2"/, 'Width=36: stroke' );
}

{
    my $w = SVG::Sparkline->new( Whisker => { values=>'++0+0+', width=>10 } );
    like( "$w", qr/d="M0.56,0v-5m1.68,5v-5m3.36,5v-5m3.36,5v-5"/, 'Width=10' );
    like( "$w", qr/stroke-width="0.56"/, 'Width=10: stroke' );
}

