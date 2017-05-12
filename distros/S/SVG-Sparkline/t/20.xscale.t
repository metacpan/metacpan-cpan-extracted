#!/usr/bin/env perl

use Test::More tests => 4;
use Carp;

use strict;
use warnings;
use SVG::Sparkline;

my @yvalues = (10,5,-10,-5,3,8,12,20,18,10,5);

{
    my $l = SVG::Sparkline->new( Line => { xscale=>3, values=>\@yvalues } );
    is( "$l",
        '<svg height="12" viewBox="0 -7.67 32 12" width="32" xmlns="http://www.w3.org/2000/svg"><polyline fill="none" points="0,-3.33 3,-1.67 6,3.33 9,1.67 12,-1 15,-2.67 18,-4 21,-6.67 24,-6 27,-3.33 30,-1.67" stroke="#000" stroke-linecap="round" stroke-width="1" /></svg>',
        'Line: xscale=3'
    );
}

{
    my $a = SVG::Sparkline->new( Area => { xscale=>3, values=>\@yvalues } );
    is( "$a",
        '<svg height="12" viewBox="0 -7.67 32 12" width="32" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="0,0 0,-3.33 3,-1.67 6,3.33 9,1.67 12,-1 15,-2.67 18,-4 21,-6.67 24,-6 27,-3.33 30,-1.67 30,0" stroke="none" /></svg>',
        'Area: xscale=3'
    );
}

{
    my $l2 = SVG::Sparkline->new( Line => { xscale=>5, values=>\@yvalues } );
    is( "$l2",
        '<svg height="12" viewBox="0 -7.67 54 12" width="54" xmlns="http://www.w3.org/2000/svg"><polyline fill="none" points="0,-3.33 5,-1.67 10,3.33 15,1.67 20,-1 25,-2.67 30,-4 35,-6.67 40,-6 45,-3.33 50,-1.67" stroke="#000" stroke-linecap="round" stroke-width="1" /></svg>',
        'Line: xscale=5'
    );
}

{
    my $a2 = SVG::Sparkline->new( Area => { xscale=>5, values=>\@yvalues } );
    is( "$a2",
        '<svg height="12" viewBox="0 -7.67 54 12" width="54" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="0,0 0,-3.33 5,-1.67 10,3.33 15,1.67 20,-1 25,-2.67 30,-4 35,-6.67 40,-6 45,-3.33 50,-1.67 50,0" stroke="none" /></svg>',
        'Area: xscale=5'
    );
}
