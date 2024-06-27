#! /usr/bin/env perl

use v5.22;
use warnings;

use Multi::Dispatch;

multi quicksort ()              { () }

multi quicksort ($single)       { $single }

multi quicksort ($pivot, @tail) { quicksort(grep {$_ <  $pivot} @tail),
                                  $pivot,
                                  quicksort(grep {$_ >= $pivot} @tail)
                                }

say join ', ', quicksort(3,1,4,1,5,9,2,6);



multi merge ( [@x],     []             )  { @x }
multi merge ( [],       [@y]           )  { @y }
multi merge ( [$x, @x], [$y <  $x, @y] )  { $y, merge [$x, @x], \@y }
multi merge ( [$x, @x], [$y >= $x, @y] )  { $x, merge \@x, [$y, @y] }

multi mergesort (@list < 2) { @list }
multi mergesort (@list) {
    merge
        [mergesort @list[0..@list/2-1]    ],
        [mergesort @list[@list/2..$#list] ]
}

say join ', ', mergesort(3,1,4,1,5,9,2,6);

