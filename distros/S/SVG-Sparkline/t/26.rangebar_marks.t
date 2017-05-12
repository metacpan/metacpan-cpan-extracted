#!/usr/bin/env perl

use Test::More tests => 10;
use Test::Exception;
use Carp;
use SVG::Sparkline;

use strict;
use warnings;

my @values = (
    [2,4], [3,6], [1,3], [5,10], [0,6]
);
my $path = 'M0,-2v-2h3v2h-3m3,-1v-3h3v3h-3m3,2v-2h3v2h-3m3,-4v-5h3v5h-3m3,5v-6h3v6h-3';
{
    my $mark = '<rect fill="blue" height="2" stroke="none" width="3" x="6" y="-3" />';
    my $rb = SVG::Sparkline->new( RangeBar => { values=>\@values, mark=>[2=>'blue'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="$path" fill="#000" stroke="none" />$mark</svg>],
        'index mark'
    );
}

{
    my $mark = '<rect fill="blue" height="2" stroke="none" width="3" x="0" y="-4" />';
    my $rb = SVG::Sparkline->new( RangeBar => { values=>\@values, mark=>[first=>'blue'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="$path" fill="#000" stroke="none" />$mark</svg>],
        'first mark'
    );
}

{
    my $mark = '<rect fill="blue" height="6" stroke="none" width="3" x="12" y="-6" />';
    my $rb = SVG::Sparkline->new( RangeBar => { values=>\@values, mark=>[last=>'blue'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="$path" fill="#000" stroke="none" />$mark</svg>],
        'last mark'
    );
}

{
    my $mark = '<rect fill="green" height="5" stroke="none" width="3" x="9" y="-10" />';
    my $rb = SVG::Sparkline->new( RangeBar => { values=>\@values, mark=>[high=>'green'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="$path" fill="#000" stroke="none" />$mark</svg>],
        'high mark'
    );
}

{
    my $mark = '<rect fill="red" height="6" stroke="none" width="3" x="12" y="-6" />';
    my $rb = SVG::Sparkline->new( RangeBar => { values=>\@values, mark=>[low=>'red'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="$path" fill="#000" stroke="none" />$mark</svg>],
        'low mark'
    );
}

$path = 'M0.5,-2v-2h3v2h-3m4,-1v-3h3v3h-3m4,2v-2h3v2h-3m4,-4v-5h3v5h-3m4,5v-6h3v6h-3';
{
    my $mark = '<rect fill="blue" height="2" stroke="none" width="3" x="0.5" y="-4" />';
    my $rb = SVG::Sparkline->new( RangeBar => { values=>\@values, gap=>1, mark=>[first=>'blue'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 20 12" width="20" xmlns="http://www.w3.org/2000/svg"><path d="$path" fill="#000" stroke="none" />$mark</svg>],
        'first mark with gap'
    );
}

{
    my $mark = '<rect fill="green" height="5" stroke="none" width="3" x="12.5" y="-10" />';
    my $rb = SVG::Sparkline->new( RangeBar => { values=>\@values, gap=>1, mark=>[high=>'green'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 20 12" width="20" xmlns="http://www.w3.org/2000/svg"><path d="$path" fill="#000" stroke="none" />$mark</svg>],
        'high mark with gap'
    );
}

{
    my $path = 'M0,-2v-2h4v2h-4m4,-1v-3h4v3h-4m4,2v-2h4v2h-4m4,-4v-5h4v5h-4m4,5v-6h4v6h-4';
    my $mark = '<rect fill="green" height="5" stroke="none" width="4" x="12" y="-10" />';
    my $rb = SVG::Sparkline->new( RangeBar => { values=>\@values, thick=>4, mark=>[high=>'green'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 20 12" width="20" xmlns="http://www.w3.org/2000/svg"><path d="$path" fill="#000" stroke="none" />$mark</svg>],
        'high mark with thick=4'
    );
}

{
    my @values = (
        [2,4], [3,6], [2,2], [5,10], [0,6]
    );
    my $path = 'M0,-2v-2h3v2h-3m3,-1v-3h3v3h-3m3,1v-0.5h1v1h1v-1h1v0.5h-3m3,-3v-5h3v5h-3m3,5v-6h3v6h-3';
    my $mark = '<path d="M6,-2v-0.5h1v1h1v-1h1v0.5h-3" fill="blue" stroke="none" />';
    my $rb = SVG::Sparkline->new( RangeBar => { values=>\@values, mark=>[2=>'blue'] } );
    is( "$rb",
        qq[<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="$path" fill="#000" stroke="none" />$mark</svg>],
        'mark on zero height bar'
    );
}

throws_ok {
    my @values = (
        [2,4], [3,6], [2,2], [5,10], [0,6]
    );
    SVG::Sparkline->new( RangeBar => { values=>\@values, mark=>[xyzzy=>'green'] } );
} qr/not a valid mark/, 'rangebar: unrecogized mark not allowed';
