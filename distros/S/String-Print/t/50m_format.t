#!/usr/bin/env perl
# Test sprintf formatting

use warnings;
use strict;
use utf8;
use Test::More tests => 12;

use String::Print;

my $pi = 3.14157;

my $f = String::Print->new;
isa_ok($f, 'String::Print');

my $x1 = $f->sprinti("a={a%d} b={b %.2f}", a => 007, b => $pi);
$x1    =~ s/,/./g;  # locale may output floats with comma
is($x1, "a=7 b=3.14");

# multi-byte characters
my $short = "€éö";
is $f->sprinti("c={z%s}x",   z => $short), "c=${short}x";
is $f->sprinti("c2={z %s}x", z => $short), "c2=${short}x";
is $f->sprinti("c3={ z%s}x", z => $short), "c3=${short}x";
is $f->sprinti("c4={ z %s}x", z => $short), "c4=${short}x";

is $f->sprinti("d={z%5s}x",  z => $short), "d=  ${short}x";
is $f->sprinti("e={z%-5s}x", z => $short), "e=${short}  x";
is $f->sprinti("f={z%5s}x",  z => "${short}yzzz"), "f=${short}yzzzx";
is $f->sprinti("g={z%.5s}x", z => "${short}yzz"), "g=${short}yzx", 'too large';
is $f->sprinti("h={z%5.3s}x",z => "${short}yz"), "h=  ${short}x";
is $f->sprinti("i={z%-5.3s}x",z=> "${short}yz"), "i=${short}  x";

#XXX Now re-run the tests with wide display chars.
