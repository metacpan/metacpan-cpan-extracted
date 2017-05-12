#!/usr/bin/perl6
use v6;

=begin pod

Quite similar to how it is done in Perl 5 using a for loop,
though the syntax of creating an array from a list of words
has changed from qw to be <>


=end pod


my @names = <foo bar baz>;

for @names -> $name {
    say $name;
}

