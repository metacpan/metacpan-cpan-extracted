#!/usr/bin/env perl
# Test sprintf formatting

use warnings;
use strict;
use utf8;

use Test::More;

use String::Print;

my $pi = 3.14157;

my $f = String::Print->new;
isa_ok($f, 'String::Print');

my $x1 = $f->sprinti("a={a%d} b={b %.2f}", a => 007, b => $pi);
$x1    =~ s/,/./g;  # locale may output floats with comma
is $x1, "a=7 b=3.14";

is $f->sprinti("x={v%_d}", v => 1e9), 'x=1_000_000_000';
is $f->sprinti("x={v%,d}", v => 1e9), 'x=1,000,000,000';
is $f->sprinti("x={v%.d}", v => 1e9), 'x=1.000.000.000';
is $f->sprinti("x={v%.d}", v => 1e8), 'x=100.000.000';
is $f->sprinti("x={v%.d}", v => 1e7), 'x=10.000.000';
is $f->sprinti("x={v%.d}", v => 1e6), 'x=1.000.000';
is $f->sprinti("x={v%.d}", v => 1e5), 'x=100.000';
is $f->sprinti("x={v%.d}", v => 1e4), 'x=10.000';
is $f->sprinti("x={v%.d}", v => 1e3), 'x=1.000';
is $f->sprinti("x={v%.d}", v => 100), 'x=100';
is $f->sprinti("x={v%.d}", v => 10), 'x=10';
is $f->sprinti("x={v%.d}", v => 1), 'x=1';
is $f->sprinti("x={v%.d}", v => 0), 'x=0';

is $f->sprinti("x={v%_d}",  v => -1e4), 'x=-10_000';
is $f->sprinti("x={v%+_d}", v => -1e4), 'x=-10_000';
is $f->sprinti("x={v%+_d}", v =>  1e4), 'x=+10_000';
is $f->sprinti("x={v% _d}", v =>  1e4), 'x= 10_000';

is $f->sprinti("x={v%-10.d}", v =>  1e4), 'x=10.000    ';
is $f->sprinti("x={v%10.d}",  v =>  1e4), 'x=    10.000';
is $f->sprinti("x={v%-10.d}", v => -1e4), 'x=-10.000   ';
is $f->sprinti("x={v%10.d}",  v => -1e4), 'x=   -10.000';

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

$f->setDefaults(FORMAT => { thousands => ',' });
is $f->sprinti("x={v%d}", v => 1e9), 'x=1,000,000,000', 'default thousands';

#XXX Now re-run the tests with wide display chars.

done_testing;
