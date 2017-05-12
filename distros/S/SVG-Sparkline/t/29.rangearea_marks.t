#!/usr/bin/env perl

use Test::More tests => 6;
use Test::Exception;
use Carp;
use SVG::Sparkline;

use strict;
use warnings;

my @values = (
    [2,4], [3,6], [1,3], [5,10], [0,6]
);
my $points = '0,-2 2,-3 4,-1 6,-5 8,0 8,-6 6,-10 4,-3 2,-6 0,-4';
{
    my $mark = '<line fill="none" stroke="blue" stroke-width="1" x1="4" x2="4" y1="-1" y2="-3" />';
    my $rb = SVG::Sparkline->new( RangeArea => { values=>\@values, mark=>[2=>'blue'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 9 12" width="9" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" />$mark</svg>],
        'index mark'
    );
}

{
    my $mark = '<line fill="none" stroke="blue" stroke-width="1" x1="0" x2="0" y1="-2" y2="-4" />';
    my $rb = SVG::Sparkline->new( RangeArea => { values=>\@values, mark=>[first=>'blue'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 9 12" width="9" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" />$mark</svg>],
        'first mark'
    );
}

{
    my $mark = '<line fill="none" stroke="blue" stroke-width="1" x1="8" x2="8" y1="0" y2="-6" />';
    my $rb = SVG::Sparkline->new( RangeArea => { values=>\@values, mark=>[last=>'blue'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 9 12" width="9" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" />$mark</svg>],
        'last mark'
    );
}

{
    my $mark = '<line fill="none" stroke="green" stroke-width="1" x1="6" x2="6" y1="-5" y2="-10" />';
    my $rb = SVG::Sparkline->new( RangeArea => { values=>\@values, mark=>[high=>'green'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 9 12" width="9" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" />$mark</svg>],
        'high mark'
    );
}

{
    my $mark = '<line fill="none" stroke="red" stroke-width="1" x1="8" x2="8" y1="0" y2="-6" />';
    my $rb = SVG::Sparkline->new( RangeArea => { values=>\@values, mark=>[low=>'red'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 9 12" width="9" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" />$mark</svg>],
        'low mark'
    );
}

throws_ok {
    my @values = (
        [2,4], [3,6], [2,2], [5,10], [0,6]
    );
    SVG::Sparkline->new( RangeArea => { values=>\@values, mark=>[xyzzy=>'green'] } );
} qr/not a valid mark/, 'rangearea: unrecogized mark not allowed';
