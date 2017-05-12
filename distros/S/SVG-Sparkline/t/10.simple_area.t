#!/usr/bin/env perl

use Test::More tests => 9;
use Carp;
use SVG::Sparkline;

use strict;
use warnings;

my @yvalues = (10,5,-10,-5,3,8,12,20,18,10,5);
my $points = '0,0 0,-3.33 3.2,-1.67 6.4,3.33 9.6,1.67 12.8,-1 16,-2.67 19.2,-4 22.4,-6.67 25.6,-6 28.8,-3.33 32,-1.67 32,0';
  
{
    my $a1 = SVG::Sparkline->new( Area => { values=>\@yvalues, width=>33 } );
    isa_ok( $a1, 'SVG::Sparkline', 'Created a Area-type Sparkline.' );
    is( "$a1",
        qq{<svg height="12" viewBox="0 -7.67 33 12" width="33" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>},
        'width & 11 points: output correct'
    );
    is( "$a1", $a1->to_string, 'Stringify works' );
}

{
    my $a2 = SVG::Sparkline->new( Area => { values=>\@yvalues, color=>'#888', width=>33 } );
    is( "$a2",
        qq{<svg height="12" viewBox="0 -7.67 33 12" width="33" xmlns="http://www.w3.org/2000/svg"><polygon fill="#888" points="$points" stroke="none" /></svg>},
        'color changed: output correct'
    );
}

{
    my $i = 0;
    my @values = map { [ $i++, $_ ] } @yvalues;
    my $a3 = SVG::Sparkline->new( Area => { values=>\@values, width=>33 } );
    is( "$a3",
        qq{<svg height="12" viewBox="0 -7.67 33 12" width="33" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>},
        'width & 11 points: output correct'
    );
}

{
    my $points = '0,0 0,-3.33 2,-1.67 4,3.33 6,1.67 8,-1 10,-2.67 12,-4 14,-6.67 16,-6 18,-3.33 20,-1.67 20,0';
    my $a5 = SVG::Sparkline->new( Area => { values=>\@yvalues } );
    is( "$a5",
        qq{<svg height="12" viewBox="0 -7.67 21 12" width="21" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>},
        'no width: output correct'
    );
}

{
    my $points = '0,0 0,-3.33 2,-1.67 4,3.33 6,1.67 8,-1 10,-2.67 12,-4 14,-6.67 16,-6 18,-3.33 20,-1.67 20,0';
    my $a6 = SVG::Sparkline->new( Area => { -sized => 1, values=>\@yvalues } );
    is( "$a6",
        qq{<svg height="12" viewBox="0 -7.67 21 12" width="21" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>},
        'sized true: output correct'
    );
}

{
    my $points = '0,0 0,-3.33 2,-1.67 4,3.33 6,1.67 8,-1 10,-2.67 12,-4 14,-6.67 16,-6 18,-3.33 20,-1.67 20,0';
    my $a7 = SVG::Sparkline->new( Area => { -sized => 0, values=>\@yvalues } );
    is( "$a7",
        qq{<svg viewBox="0 -7.67 21 12" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>},
        'sized false: output correct'
    );
}

{
    my $points = '0,0 0,0 2,0 4,0 6,0 8,0 10,0 12,0 14,0 16,0 18,0 18,0';
    my $a8 = SVG::Sparkline->new( Area => { values=>[ (0) x 10 ] } );
    is( "$a8",
        qq{<svg height="12" viewBox="0 -11 19 12" width="19" xmlns="http://www.w3.org/2000/svg"><polygon fill="#000" points="$points" stroke="none" /></svg>},
        'all zero data: output correct'
    );
}
