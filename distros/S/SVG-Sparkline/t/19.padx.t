#!/usr/bin/env perl

use Test::More tests => 8;
use Carp;

use strict;
use warnings;
use SVG::Sparkline;

my @yvalues = (10,5,-10,-5,3,8,12,20,18,10,5);

{
    my $w = SVG::Sparkline->new( Whisker => { padx=>5, values=>[1,1,0,1,0,1] } );
    is( "$w",
        '<svg height="12" viewBox="-5 -6 28 12" width="28" xmlns="http://www.w3.org/2000/svg"><path d="M1,0v-5m3,5v-5m6,5v-5m6,5v-5" stroke="#000" stroke-width="1" /></svg>',
        'Whisker: five x padding'
    );
}

{
my $l = SVG::Sparkline->new( Line => { padx=>5, values=>\@yvalues } );
is( "$l",
    '<svg height="12" viewBox="-5 -7.67 31 12" width="31" xmlns="http://www.w3.org/2000/svg"><polyline fill="none" points="0,-3.33 2,-1.67 4,3.33 6,1.67 8,-1 10,-2.67 12,-4 14,-6.67 16,-6 18,-3.33 20,-1.67" stroke="#000" stroke-linecap="round" stroke-width="1" /></svg>',
    'Line: five x padding'
);
}

{
    my $a = SVG::Sparkline->new( Area => { padx=>5, values=>\@yvalues } );
    is( "$a",
        '<svg height="12" viewBox="-5 -7.67 31 12" width="31" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="0,0 0,-3.33 2,-1.67 4,3.33 6,1.67 8,-1 10,-2.67 12,-4 14,-6.67 16,-6 18,-3.33 20,-1.67 20,0" stroke="none" /></svg>',
        'Area: five x padding'
    );
}

{
    my $b = SVG::Sparkline->new( Bar => { padx=>5, values=>[2,4,5,3,0,-2,-4,-3,-5,0,3,-3,5,2,0] } );
    is( "$b",
        '<svg height="12" viewBox="-5 -6 55 12" width="55" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v-2h3v-2h3v-1h3v2h3v3h3v2h3v2h3v-1h3v2h3v-5h3v-3h3v6h3v-8h3v3h3v2h3z" fill="#000" stroke="none" /></svg>',
        'Bar: five x padding'
    );
}

{
    my $wb = SVG::Sparkline->new( Whisker => { padx=>5, bgcolor=>'#fff', values=>[1,1,0,1,0,1] } );
    is( "$wb",
        '<svg height="12" viewBox="-5 -6 28 12" width="28" xmlns="http://www.w3.org/2000/svg"><rect fill="#fff" height="14" stroke="none" width="30" x="-6" y="-7" /><path d="M1,0v-5m3,5v-5m6,5v-5m6,5v-5" stroke="#000" stroke-width="1" /></svg>',
        'Whisker: five x padding, with background'
    );
}

{
    my $lb = SVG::Sparkline->new( Line => { padx=>5, bgcolor=>'#fff', values=>\@yvalues } );
    is( "$lb",
        '<svg height="12" viewBox="-5 -7.67 31 12" width="31" xmlns="http://www.w3.org/2000/svg"><rect fill="#fff" height="14" stroke="none" width="33" x="-6" y="-8.67" /><polyline fill="none" points="0,-3.33 2,-1.67 4,3.33 6,1.67 8,-1 10,-2.67 12,-4 14,-6.67 16,-6 18,-3.33 20,-1.67" stroke="#000" stroke-linecap="round" stroke-width="1" /></svg>',
        'Line: five x padding, with background'
    );
}

{
    my $ab = SVG::Sparkline->new( Area => { padx=>5, bgcolor=>'#fff', values=>\@yvalues } );
    is( "$ab",
        '<svg height="12" viewBox="-5 -7.67 31 12" width="31" xmlns="http://www.w3.org/2000/svg"><rect fill="#fff" height="14" stroke="none" width="33" x="-6" y="-8.67" /><polygon fill="#000" points="0,0 0,-3.33 2,-1.67 4,3.33 6,1.67 8,-1 10,-2.67 12,-4 14,-6.67 16,-6 18,-3.33 20,-1.67 20,0" stroke="none" /></svg>',
        'Area: five x padding, with background'
    );
}

{
    my $bb = SVG::Sparkline->new( Bar => { padx=>5, bgcolor=>'#fff', values=>[2,4,5,3,0,-2,-4,-3,-5,0,3,-3,5,2,0] } );
    is( "$bb",
        '<svg height="12" viewBox="-5 -6 55 12" width="55" xmlns="http://www.w3.org/2000/svg"><rect fill="#fff" height="14" stroke="none" width="57" x="-6" y="-7" /><path d="M0,0v-2h3v-2h3v-1h3v2h3v3h3v2h3v2h3v-1h3v2h3v-5h3v-3h3v6h3v-8h3v3h3v2h3z" fill="#000" stroke="none" /></svg>',
        'Bar: five x padding, with background'
    );
}
