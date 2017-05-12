# -*- perl -*-

use strict;
use Set::IntSpan 1.17 qw(grep_spans map_spans);

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

my @Sets  = split(' ', q{ - (-) (-0 0-) 1 5 1-3 3-7 1-3,8,10-23 1-3,8,10-23,30-) });

sub long_span
{
    my($l, $u) = @$_; 
    not defined $l or 
    not defined $u or
    $u-$l > 3
}

sub short_span
{
    my($l, $u) = @$_; 
    defined $l and
    defined $u and
    $u-$l < 3
}

my @Greps = ('0', '1', 'long_span', 'short_span');

sub mirror
{
    my($l, $u) = @$_;

       if (    defined $l and 	  defined $u) { return [ -$u  , -$l   ] }
    elsif (not defined $l and 	  defined $u) { return [ -$u  , undef ] }
    elsif (    defined $l and not defined $u) { return [ undef, -$l   ] }
    else                                      { return [ undef, undef ] }
}

sub mirror_mirror
{
    my($l, $u) = @$_;

       if (    defined $l and 	  defined $u) { return [ -$u  , -$l   ], [ $l    , $u   ] }
    elsif (not defined $l and 	  defined $u) { return [ -$u  , undef ], [ undef , $u   ] }
    elsif (    defined $l and not defined $u) { return [ undef, -$l   ], [ $l    , undef] }
    else                                      { return [ undef, undef ], [ undef, undef ] }
}

sub double_up
{
    my($l, $u) = @$_;

       if (    defined $l and 	  defined $u) { return [ 2*$l , 2*$u  ] }
    elsif (not defined $l and 	  defined $u) { return [ undef, 2*$u  ] }
    elsif (    defined $l and not defined $u) { return [ 2*$l,  undef ] }
    else                                      { return [ undef, undef ] }
}

sub stretch_up
{
    my($l, $u) = @$_;

       if (    defined $l and 	  defined $u) { return [ $l   , $u+5  ] }
    elsif (not defined $l and 	  defined $u) { return [ undef, $u+5  ] }
    elsif (    defined $l and not defined $u) { return [ $l   , undef ] }
    else                                      { return [ undef, undef ] }
}


my @Maps  = ('()', '$_', 'mirror', 'mirror_mirror', 'double_up', 'stretch_up');

print "1..", @Sets * (@Greps + @Maps), "\n";

Grep();
Map ();

sub Grep
{
    print "#grep_span\n";

    my @expected = 
    (['-', ' - ', ' - ', ' - ', '-', '-', ' - ', ' - ', ' -         ', ' -              '],
     ['-', '(-)', '(-0', '0-)', '1', '5', '1-3', '3-7', '1-3,8,10-23', '1-3,8,10-23,30-)'],
     ['-', '(-)', '(-0', '0-)', '-', '-', ' - ', '3-7', '      10-23', '      10-23,30-)'],
     ['-', ' - ', ' - ', ' - ', '1', '5', '1-3', ' - ', '1-3,8      ', '1-3,8,          '],
     );

    for (my $g=0; $g<@Greps; $g++)
    {
	for (my $s=0; $s<@Sets; $s++)
        {
	    my $set      = new Set::IntSpan $Sets[$s];
	    my $result   = grep_spans { eval $Greps[$g] } $set;
	    my $expected = new Set::IntSpan $expected[$g][$s];

	    printf "#%3d: grep_span { %-8s } %-20s -> %s\n",
	    $N, $Greps[$g], $Sets[$s], $result->run_list;

	    equal $result $expected or Not; OK;
        }
    }
}

sub Map
{
    print "#map_span\n";

    my @expected = 
    (['-', ' - ', ' - ', ' - ', ' -', ' -', '  - ' , '  -  ', '  -             ', '  -              	 '],
     ['-', '(-)', '(-0', '0-)', ' 1', ' 5', ' 1-3' , ' 3-7 ', ' 1-3,8,10-23    ', ' 1-3,8,10-23,30-)	 '],  
     ['-', '(-)', '0-)', '(-0', '-1', '-5', '-3--1', '-7--3', '-23--10,-8,-3--1', '(--30,-23--10,-8,-3--1'],

     ['-', '(-)', '(-)', '(-)', '-1,1', '-5,5', '-3--1,1-3', '-7--3,3-7 ', 
      '-23--10,-8,-3--1,1-3,8,10-23', '(--30,-23--10,-8,-3--1, 1-3,8,10-23,30-)'],  

     ['-', '(-)', '(-0', '0-)', ' 2', ' 10', '2-6', '6-14', '2-6,16,20-46', '2-6,16,20-46,60-)' ],
     ['-', '(-)', '(-5', '0-)', ' 1-6', '5-10', ' 1-8', '3-12', '1-28'        , '1-28,30-)'     ],

     );

    for (my $g=0; $g<@Maps; $g++)
    {
	for (my $s=0; $s<@Sets; $s++)
        {
	    my $set      = new Set::IntSpan $Sets[$s];
	    my $result   = map_spans { eval $Maps[$g] } $set;
	    my $expected = new Set::IntSpan $expected[$g][$s];

	    printf "#%3d: map_span { %-8s } %-20s -> %s\n",
	    $N, $Maps[$g], $Sets[$s], $result->run_list;

	    equal $result $expected or Not; OK;
        }
    }
}
