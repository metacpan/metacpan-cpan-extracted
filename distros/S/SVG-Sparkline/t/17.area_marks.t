#!/usr/bin/env perl

use Test::More tests => 16;
use Test::Exception;
use Carp;
use SVG::Sparkline;

use strict;
use warnings;

# positive only
{
    my @yvalues = (72,73,74,80,75,77,70,73);
    my $points=qq{0,0 0,-2 2,-3 4,-4 6,-10 8,-5 10,-7 12,0 14,-3 14,0};
    my $l1 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[2=>'blue'] } );
    is( "$l1",
        qq{<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><line fill="none" stroke="blue" stroke-width="1" x1="4" x2="4" y1="0" y2="-4" /></svg>},
        'pos only: mark index'
    );

    my $l2 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[first=>'blue'] } );
    is( "$l2",
        qq{<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><line fill="none" stroke="blue" stroke-width="1" x1="0" x2="0" y1="0" y2="-2" /></svg>},
        'pos only: mark first'
    );

    my $l3 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[last=>'blue'] } );
    is( "$l3",
        qq{<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><line fill="none" stroke="blue" stroke-width="1" x1="14" x2="14" y1="0" y2="-3" /></svg>},
        'pos only: mark last'
    );

    my $l4 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[low=>'red'] } );
    is( "$l4",
        qq{<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><circle cx="12" cy="0" fill="red" r="1" stroke="none" /></svg>},
        'pos only: mark low'
    );

    my $l5 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[high=>'green'] } );
    is( "$l5",
        qq{<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><line fill="none" stroke="green" stroke-width="1" x1="6" x2="6" y1="0" y2="-10" /></svg>},
        'pos only: mark high'
    );
}

# negative only
{
    my @yvalues = (-62,-63,-64,-70,-65,-67,-60,-63);
    my $points=qq{0,0 0,2 2,3 4,4 6,10 8,5 10,7 12,0 14,3 14,0};
    my $l1 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[2=>'blue'] } );
    is( "$l1",
        qq{<svg height="12" viewBox="0 -1 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><line fill="none" stroke="blue" stroke-width="1" x1="4" x2="4" y1="0" y2="4" /></svg>},
        'neg only: mark index'
    );

    my $l2 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[first=>'blue'] } );
    is( "$l2",
        qq{<svg height="12" viewBox="0 -1 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><line fill="none" stroke="blue" stroke-width="1" x1="0" x2="0" y1="0" y2="2" /></svg>},
        'neg only: mark first'
    );

    my $l3 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[last=>'blue'] } );
    is( "$l3",
        qq{<svg height="12" viewBox="0 -1 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><line fill="none" stroke="blue" stroke-width="1" x1="14" x2="14" y1="0" y2="3" /></svg>},
        'neg only: mark last'
    );

    my $l4 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[low=>'red'] } );
    is( "$l4",
        qq{<svg height="12" viewBox="0 -1 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><line fill="none" stroke="red" stroke-width="1" x1="6" x2="6" y1="0" y2="10" /></svg>},
        'neg only: mark low'
    );

    my $l5 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[high=>'green'] } );
    is( "$l5",
        qq{<svg height="12" viewBox="0 -1 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><circle cx="12" cy="0" fill="green" r="1" stroke="none" /></svg>},
        'neg only: mark high'
    );
}

# postive and negative
{
    my @yvalues = (3,2,1,-5,0,-2,5,2);
    my $points=qq{0,0 0,-3 2,-2 4,-1 6,5 8,0 10,2 12,-5 14,-2 14,0};
    my $l1 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[2=>'blue'] } );
    is( "$l1",
        qq{<svg height="12" viewBox="0 -6 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><line fill="none" stroke="blue" stroke-width="1" x1="4" x2="4" y1="0" y2="-1" /></svg>},
        'pos/neg only: mark index'
    );

    my $l2 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[first=>'blue'] } );
    is( "$l2",
        qq{<svg height="12" viewBox="0 -6 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><line fill="none" stroke="blue" stroke-width="1" x1="0" x2="0" y1="0" y2="-3" /></svg>},
        'pos/neg only: mark first'
    );

    my $l3 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[last=>'blue'] } );
    is( "$l3",
        qq{<svg height="12" viewBox="0 -6 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><line fill="none" stroke="blue" stroke-width="1" x1="14" x2="14" y1="0" y2="-2" /></svg>},
        'pos/neg only: mark last'
    );

    my $l4 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[low=>'red'] } );
    is( "$l4",
        qq{<svg height="12" viewBox="0 -6 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><line fill="none" stroke="red" stroke-width="1" x1="6" x2="6" y1="0" y2="5" /></svg>},
        'pos/neg only: mark low'
    );

    my $l5 = SVG::Sparkline->new( Area => { values=>\@yvalues, mark=>[high=>'green'] } );
    is( "$l5",
        qq{<svg height="12" viewBox="0 -6 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /><line fill="none" stroke="green" stroke-width="1" x1="12" x2="12" y1="0" y2="-5" /></svg>},
        'pos/neg only: mark high'
    );
}

throws_ok {
    SVG::Sparkline->new( Area => { values=>[-2,-5,0,5,3], mark=>[xyzzy=>'green'] } );
} qr/not a valid mark/, 'area: unrecogized mark not allowed';
