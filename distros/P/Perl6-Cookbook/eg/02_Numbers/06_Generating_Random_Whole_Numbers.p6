#!/usr/bin/perl6
use v6;

=begin pod

The rand() function in Perl 6 provides a random number between
0 and 1 where 0 is possible while 1 is not.

so $x = rand(); 
0 <= $x < 1;

As opposed to Perl 5 in Perl 6 rand() does not get an argument.
If you'd like to generate a random integer between $N and $K 
(both inclusive) then you have to write
TODO: really Num.rand is not exported to main?

$N + int rand * $K

So for example throwing a cube is 

1 + int rand * 6;

As rand is also a method of the Num class one could also write
the above like this:

6.rand.int+1

In order to avoid the need to think over $N and $K 
again and again Perl 6 also provides a nice way to generate
random whole numbers

(1..6).pick;

but don't try it on (1..100000).pick on Rakudo as it does 
not seem to like it. It seems he range is not lazy there.


=end pod

say 1 + int rand * 6 for 1..10;
say 6.rand.int+1     for 1..10;
say (1..6).pick      for 1..10;

