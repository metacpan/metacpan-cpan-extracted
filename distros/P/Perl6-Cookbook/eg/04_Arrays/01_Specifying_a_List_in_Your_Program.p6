#!/usr/bin/perl6
use v6;

# Creating an array
# see also S09

my @names = ('foo', 'bar', 'baz');
@names.perl.say;

my @others = qw(foo bar baz);
@others.perl.say;
