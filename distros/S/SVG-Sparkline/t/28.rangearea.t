#!/usr/bin/env perl

use Test::More tests => 13;
use Carp;
use SVG::Sparkline;

use strict;
use warnings;

my @values = (
    [2,4], [3,6], [1,3], [5,10], [0,6]
);
my $points = '0,-2 2,-3 4,-1 6,-5 8,0 8,-6 6,-10 4,-3 2,-6 0,-4';
{
    my $ra = SVG::Sparkline->new( RangeArea => { values=>\@values } );
    isa_ok( $ra, 'SVG::Sparkline', 'Created a RangeArea-type Sparkline.' );
    is( "$ra",
        qq[<svg height="12" viewBox="0 -11 9 12" width="9" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>],
        'pos only: output correct'
    );
    is( "$ra", $ra->to_string, 'Stringify works' );
}

{
    my $ra = SVG::Sparkline->new( RangeArea => { -sized => 1, values=>\@values } );
    is( "$ra",
        qq[<svg height="12" viewBox="0 -11 9 12" width="9" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>],
        'sized true: output correct'
    );
}

{
    my $ra = SVG::Sparkline->new( RangeArea => { -sized => 0, values=>\@values } );
    is( "$ra",
        qq[<svg viewBox="0 -11 9 12" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>],
        'sized false: output correct'
    );
}

{
    my $ra = SVG::Sparkline->new( RangeArea => { values=>\@values, width=>17 } );
    my $points = '0,-2 4,-3 8,-1 12,-5 16,0 16,-6 12,-10 8,-3 4,-6 0,-4';
    is( "$ra",
        qq[<svg height="12" viewBox="0 -11 17 12" width="17" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>],

        'pos only with width: output correct'
    );
}

{
    my $ra = SVG::Sparkline->new( RangeArea => { values=>\@values, color=>'#008' } );
    is( "$ra",
        qq[<svg height="12" viewBox="0 -11 9 12" width="9" xmlns="http://www.w3.org/2000/svg"><polygon fill="#008" points="$points" stroke="none" /></svg>],
        'pos only color: output correct'
    );
}

{
    my @values = (
        [2,4], [3,5], [1,2], [-3,1], [-5,-2], [-4,4]
    );
    my $points = '0,-2 2,-3 4,-1 6,3 8,5 10,4 10,-4 8,2 6,-1 4,-2 2,-5 0,-4';
    my $ra = SVG::Sparkline->new( RangeArea => { values=>\@values } );
    is( "$ra",
        qq[<svg height="12" viewBox="0 -6 11 12" width="11" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>],
        'pos/neg: output correct'
    );
}

{
    my @values = (
        [-2,0], [-10,-5], [-6,-3], [-3,-1], [-5,-2]
    );
    my $points = '0,2 2,10 4,6 6,3 8,5 8,2 6,1 4,3 2,5 0,0';
    my $ra = SVG::Sparkline->new( RangeArea => { values=>\@values } );
    is( "$ra",
        qq[<svg height="12" viewBox="0 -1 9 12" width="9" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>],
        'neg: output correct'
    );
}

{
    my $ra = SVG::Sparkline->new( RangeArea => { values=>\@values, height=>10, pady=>0 } );
    is( "$ra",
        qq[<svg height="10" viewBox="0 -10 9 10" width="9" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>],
        'pady=0'
    );
}

{
    my $ra = SVG::Sparkline->new( RangeArea => { values=>\@values, height=>20, pady=>5 } );
    is( "$ra",
        qq[<svg height="20" viewBox="0 -15 9 20" width="9" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>],
        'pady=5'
    );
}

{
    my $ra = SVG::Sparkline->new( RangeArea => { values=>\@values, padx=>2 } );
    is( "$ra",
        qq[<svg height="12" viewBox="-2 -11 13 12" width="13" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>],
        'padx=2'
    );
}

{
    my $points = '0,-2 4,-3 8,-1 12,-5 16,0 16,-6 12,-10 8,-3 4,-6 0,-4';
    my $ra = SVG::Sparkline->new( RangeArea => { values=>\@values, xscale=>4 } );
    is( "$ra",
        qq[<svg height="12" viewBox="0 -11 19 12" width="19" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>],
        'xscale=4'
    );
}

