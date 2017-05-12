#!/usr/bin/perl6
use v6;

=begin pod

The rand() function in Perl 6 provides a random number between
0 and 1 where 0 is possible while 1 is not.

so $x = rand(); 
0 <= $x < 1;

In order to make the numbers random Perl automatically calls
srand() for us the first time rand() is called in a program.
So normally there is no need to call srand().


=end pod

say rand();
say rand();
say rand();

