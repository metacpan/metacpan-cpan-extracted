#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use_ok('String::Fraction');

# these are adapted forms of leon's tests

my $f = String::Fraction->new;
isa_ok($f, 'String::Fraction');

is($f->tweak("Hi there"), "Hi there");
is($f->tweak("Half is 1/2"), "Half is \x{00BD}");
is($f->tweak("1/2 of 1/2 is 1/4"),  "\x{00BD} of \x{00BD} is \x{00BC}");
is($f->tweak("1/5 of 1/5 is 1/25"), "\x{2155} of \x{2155} is 1/25");

# my own tests

is($f->tweak("Half is 0.5 or .5 or 000.5 or 0.5000"),
   "Half is \x{00BD} or \x{00BD} or \x{00BD} or \x{00BD}");

is($f->tweak("Third is .33 or 0.33 or 0.333 or 0.3333 but not 0.3"),
             "Third is \x{2153} or \x{2153} or \x{2153} or \x{2153} but not 0.3");
   
is($f->tweak("Two Thirds is .667 or 0.67 or 0.667 or 0.6667"),
             "Two Thirds is \x{2154} or \x{2154} or \x{2154} or \x{2154}");

is($f->tweak("One sixth is .167 or 0.17 or 0.1667 or 0.16667"),
             "One sixth is \x{2159} or \x{2159} or \x{2159} or \x{2159}");


is($f->tweak("Five sixth is .83 or 0.833 or 0.8333 or 0.8333"),
             "Five sixth is \x{215A} or \x{215A} or \x{215A} or \x{215A}");


isnt($f->tweak("Two Thirds is 0.6"),  # this will be encoded as 3/5
               "Two Thirds is \x{2154}");

isnt($f->tweak("Two Thirds is 0.66"),  # this will be left alone
               "Two Thirds is \x{2154}");

isnt($f->tweak("Two Thirds is 0.7"),  # this is just wrong
               "Two Thirds is \x{2154}");


# right, make sure we're not eating things we shouldn't
is($f->tweak("ten and a half is 10.5"),
             "ten and a half is 10\x{00BD}");

is($f->tweak("hundred and a half is 100.5"),
             "hundred and a half is 100\x{00BD}")
     or Dump($f->tweak("hunderd and a half is 100.5"));