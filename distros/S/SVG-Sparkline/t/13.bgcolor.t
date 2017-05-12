#!/usr/bin/env perl

use Test::More tests => 4;
use Carp;

use strict;
use warnings;
use SVG::Sparkline;

my @yvalues = (10,5,-10,-5,3,8,12,20,18,10,5);

{
    my $w = SVG::Sparkline->new( Whisker => { bgcolor=>'#fff', values=>[1,1,0,1,0,1] } );
    is( "$w",
        '<svg height="12" viewBox="0 -6 18 12" width="18" xmlns="http://www.w3.org/2000/svg"><rect fill="#fff" height="14" stroke="none" width="20" x="-1" y="-7" /><path d="M1,0v-5m3,5v-5m6,5v-5m6,5v-5" stroke="#000" stroke-width="1" /></svg>',
        'Whisker with background'
    );
}

{
    my $l = SVG::Sparkline->new( Line => { bgcolor=>'#fff', values=>\@yvalues } );
    is( "$l",
        '<svg height="12" viewBox="0 -7.67 21 12" width="21" xmlns="http://www.w3.org/2000/svg"><rect fill="#fff" height="14" stroke="none" width="23" x="-1" y="-8.67" /><polyline fill="none" points="0,-3.33 2,-1.67 4,3.33 6,1.67 8,-1 10,-2.67 12,-4 14,-6.67 16,-6 18,-3.33 20,-1.67" stroke="#000" stroke-linecap="round" stroke-width="1" /></svg>',
        'Line with background'
    );
}

{
    my $a = SVG::Sparkline->new( Area => { bgcolor=>'#fff', values=>\@yvalues } );
    is( "$a",
        '<svg height="12" viewBox="0 -7.67 21 12" width="21" xmlns="http://www.w3.org/2000/svg"><rect fill="#fff" height="14" stroke="none" width="23" x="-1" y="-8.67" /><polygon fill="#000" points="0,0 0,-3.33 2,-1.67 4,3.33 6,1.67 8,-1 10,-2.67 12,-4 14,-6.67 16,-6 18,-3.33 20,-1.67 20,0" stroke="none" /></svg>',
        'Area with background'
    );
}

{
    my $b = SVG::Sparkline->new( Bar => { bgcolor=>'#fff', values=>[2,4,5,3,0,-2,-4,-3,-5,0,3,-3,5,2,0] } );
    is( "$b",
        '<svg height="12" viewBox="0 -6 45 12" width="45" xmlns="http://www.w3.org/2000/svg"><rect fill="#fff" height="14" stroke="none" width="47" x="-1" y="-7" /><path d="M0,0v-2h3v-2h3v-1h3v2h3v3h3v2h3v2h3v-1h3v2h3v-5h3v-3h3v6h3v-8h3v3h3v2h3z" fill="#000" stroke="none" /></svg>',
        'Bar with background'
    );
}
