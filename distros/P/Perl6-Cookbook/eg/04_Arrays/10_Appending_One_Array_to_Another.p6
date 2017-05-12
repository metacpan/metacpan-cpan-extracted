#!/usr/bin/perl6
use v6;

=begin pod

This is quite similar to the same code in Perl 5.

=end pod


my @names      = <foo bar baz>;
my @more_names = <moo barney>;

say @names.perl;
say @more_names.perl;
push @names, @more_names;
say @names.perl;

