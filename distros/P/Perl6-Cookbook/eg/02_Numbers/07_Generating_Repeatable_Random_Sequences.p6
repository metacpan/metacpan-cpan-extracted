#!/usr/bin/perl6
use v6;

=begin pod

In order to make sure the random number generator starts
at the same place every time we start our script we should call
srand() ourself with some fixed numerical value.

=end pod

srand(42);

say rand();
say rand();
say rand();

