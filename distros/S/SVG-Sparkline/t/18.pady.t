#!/usr/bin/env perl

use Test::More tests => 8;
use Carp;

use strict;
use warnings;
use SVG::Sparkline;

my @yvalues = (10,5,-10,-5,3,8,12,20,18,10,5);

{
    my $w = SVG::Sparkline->new( Whisker => { height=>10, pady=>0, values=>[1,1,0,1,0,1] } );
    is( "$w",
        '<svg height="10" viewBox="0 -5 18 10" width="18" xmlns="http://www.w3.org/2000/svg"><path d="M1,0v-5m3,5v-5m6,5v-5m6,5v-5" stroke="#000" stroke-width="1" /></svg>',
        'Whisker: zero y padding'
    );
}

{
    my $w1 = SVG::Sparkline->new( Whisker => { height=>20, pady=>5, values=>[1,1,0,1,0,1] } );
    is( "$w1",
        '<svg height="20" viewBox="0 -10 18 20" width="18" xmlns="http://www.w3.org/2000/svg"><path d="M1,0v-5m3,5v-5m6,5v-5m6,5v-5" stroke="#000" stroke-width="1" /></svg>',
        'Whisker: five y padding'
    );
}

{
    my $l = SVG::Sparkline->new( Line => { height=>10, pady=>0, values=>\@yvalues } );
    is( "$l",
        '<svg height="10" viewBox="0 -6.67 21 10" width="21" xmlns="http://www.w3.org/2000/svg"><polyline fill="none" points="0,-3.33 2,-1.67 4,3.33 6,1.67 8,-1 10,-2.67 12,-4 14,-6.67 16,-6 18,-3.33 20,-1.67" stroke="#000" stroke-linecap="round" stroke-width="1" /></svg>',
        'Line: zero y padding'
    );
}

{
    my $l1 = SVG::Sparkline->new( Line => { height=>20, pady=>5, values=>\@yvalues } );
    is( "$l1",
        '<svg height="20" viewBox="0 -11.67 21 20" width="21" xmlns="http://www.w3.org/2000/svg"><polyline fill="none" points="0,-3.33 2,-1.67 4,3.33 6,1.67 8,-1 10,-2.67 12,-4 14,-6.67 16,-6 18,-3.33 20,-1.67" stroke="#000" stroke-linecap="round" stroke-width="1" /></svg>',
        'Line: five y padding'
    );
}

{
    my $a = SVG::Sparkline->new( Area => { height=>10, pady=>0, values=>\@yvalues } );
    is( "$a",
        '<svg height="10" viewBox="0 -6.67 21 10" width="21" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="0,0 0,-3.33 2,-1.67 4,3.33 6,1.67 8,-1 10,-2.67 12,-4 14,-6.67 16,-6 18,-3.33 20,-1.67 20,0" stroke="none" /></svg>',
        'Area: zero y padding'
    );
}

{
    my $a1 = SVG::Sparkline->new( Area => { height=>20, pady=>5, values=>\@yvalues } );
    is( "$a1",
        '<svg height="20" viewBox="0 -11.67 21 20" width="21" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="0,0 0,-3.33 2,-1.67 4,3.33 6,1.67 8,-1 10,-2.67 12,-4 14,-6.67 16,-6 18,-3.33 20,-1.67 20,0" stroke="none" /></svg>',
        'Area: five y padding'
    );
}

{
    my $b = SVG::Sparkline->new( Bar => { height=>10, pady=>0, values=>[2,4,5,3,0,-2,-4,-3,-5,0,3,-3,5,2,0] } );
    is( "$b",
        '<svg height="10" viewBox="0 -5 45 10" width="45" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v-2h3v-2h3v-1h3v2h3v3h3v2h3v2h3v-1h3v2h3v-5h3v-3h3v6h3v-8h3v3h3v2h3z" fill="#000" stroke="none" /></svg>',
        'Bar: zero y padding'
    );
}

{
    my $b1 = SVG::Sparkline->new( Bar => { height=>20, pady=>5, values=>[2,4,5,3,0,-2,-4,-3,-5,0,3,-3,5,2,0] } );
    is( "$b1",
        '<svg height="20" viewBox="0 -10 45 20" width="45" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v-2h3v-2h3v-1h3v2h3v3h3v2h3v2h3v-1h3v2h3v-5h3v-3h3v6h3v-8h3v3h3v2h3z" fill="#000" stroke="none" /></svg>',
        'Bar: five y padding'
    );
}
