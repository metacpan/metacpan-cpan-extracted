#!/usr/bin/env perl

use Test::More tests => 4;
use Carp;

use strict;
use warnings;
use SVG::Sparkline;

{
    my $w = SVG::Sparkline->new( Whisker => { values=>'++--+-+-', gap=>4 } );
    is( "$w",
        '<svg height="12" viewBox="0 -6 40 12" width="40" xmlns="http://www.w3.org/2000/svg"><path d="M2,0v-5m5,5v-5m5,5v5m5,-5v5m5,-5v-5m5,5v5m5,-5v-5m5,5v5" stroke="#000" stroke-width="1" /></svg>',
        'Whisker: gap of 4'
    );
}

{
    my $w = SVG::Sparkline->new( Whisker => { values=>'++--+-+-', gap=>1 } );
    is( "$w",
        '<svg height="12" viewBox="0 -6 16 12" width="16" xmlns="http://www.w3.org/2000/svg"><path d="M0.5,0v-5m2,5v-5m2,5v5m2,-5v5m2,-5v-5m2,5v5m2,-5v-5m2,5v5" stroke="#000" stroke-width="1" /></svg>',
        'Whisker: gap of 1'
    );
}

{
    my $b = SVG::Sparkline->new( Bar => { values=>[1,2,0,-2,-1], gap=>1 } );
    is( "$b",
        '<svg height="12" viewBox="0 -6 20 12" width="20" xmlns="http://www.w3.org/2000/svg"><path d="M0.5,0v-2.5h3v2.5h1v-5h3v5h5v5h3v-5h1v2.5h3v-2.5z" fill="#000" stroke="none" /></svg>',
        'Bar: gap of 1'
    );
}

{
    my $b = SVG::Sparkline->new( Bar => { values=>[1,2,0,-2,-1], gap=>2 } );
    is( "$b",
        '<svg height="12" viewBox="0 -6 25 12" width="25" xmlns="http://www.w3.org/2000/svg"><path d="M1,0v-2.5h3v2.5h2v-5h3v5h7v5h3v-5h2v2.5h3v-2.5z" fill="#000" stroke="none" /></svg>',
        'Bar: gap of 2'
    );
}

