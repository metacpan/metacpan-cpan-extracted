#!perl -w

# This tests if the sample module TEQF, that exports a quotelike function
# "rot13", works correctly.

BEGIN { unshift @INC, qw(./t ./lib) }

use strict;
use warnings;
use TEQF;

print "1..4\n";

print &rot13("bx 1 - shapgvba rkcbegrq\n");

print "not " if $Sub::Quotelike::qq_subs{rot13} ne '"';
print "ok 2 - function appears in qq_subs\n";

print rot13/bx 3 - fbhepr svygre vf ranoyrq\n/;

no TEQF;

eval q{ rot13!foo bar! };
print "not " unless $@;
print "ok 4 - disabling source filter\n";
