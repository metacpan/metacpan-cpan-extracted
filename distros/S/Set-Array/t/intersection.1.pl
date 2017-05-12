#!/usr/bin/env perl

use strict;
use warnings;

use Set::Array;

# -------------

my(@input_1)      = (1, 1, 5, 5, 7);
my(@input_2)      = (1, 1, 5, 6);
my($string_set_1) = Set::Array -> new(@input_1);
my($string_set_2) = Set::Array -> new(@input_2);

print 'length input 1: ', $string_set_1 -> length, "\n";
print 'length input 2: ', $string_set_2 -> length, "\n";

my(@matches) = $string_set_1 -> intersection($string_set_2);
my($matches) = Set::Array -> new(@{Set::Array -> new(@matches) -> unique});

print 'set 1:   ', join(', ', $string_set_1 -> print), "\n";
print 'set 2:   ', join(', ', $string_set_2 -> print), "\n";
print 'matches: ', join(', ', $matches -> print), "\n";

my(@rest_set_1) = $string_set_1 -> difference($matches);
my(@rest_set_2) = $string_set_2 -> difference($matches);

print 'rest 1: ', join(', ', @rest_set_1), "\n";
print 'rest 2: ', join(', ', @rest_set_2), "\n";

