#!/usr/bin/perl6
use v6;

=begin pod

This is quite similar to the same code in Perl 5.

=end pod


my @names      = <foo bar baz>;

say @names.perl;
@names = reverse @names;
say @names.perl;

