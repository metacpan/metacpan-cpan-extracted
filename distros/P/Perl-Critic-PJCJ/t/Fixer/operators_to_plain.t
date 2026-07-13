#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0 qw( done_testing subtest );

use lib             qw( lib t/lib );
use ViolationFinder qw( fixes unchanged );

subtest "q() becomes double quotes" => sub {
  fixes 'my $x = q(hello);', 'my $x = "hello";', "simple q() is re-quoted";
  fixes 'my $x = q(hello world);', 'my $x = "hello world";',
    "q() with spaces is re-quoted";
  fixes 'my $x = q(a\(b);', 'my $x = "a(b";', "escaped delimiter is decoded";
};

subtest "q() becomes single quotes" => sub {
  fixes 'my $x = q(say "hi");', q(my $x = 'say "hi"';),
    "q() with double quotes becomes single-quoted";
  fixes 'my $x = q(user@domain.com);', q(my $x = 'user@domain.com';),
    'q() with literal @ becomes single-quoted';
};

subtest "qq() becomes double quotes" => sub {
  fixes 'my $x = qq(hello $name);', 'my $x = "hello $name";',
    "interpolating qq() is re-quoted";
  fixes 'my $x = qq(plain);', 'my $x = "plain";', "simple qq() is re-quoted";
  fixes 'my $x = qq($\();', 'my $x = "$(";',
    "escaped delimiter after a sigil keeps the punctuation variable";
  fixes 'my $x = qq(a\(b);', 'my $x = "a(b";',
    "escaped delimiter is unescaped for double quotes";
  fixes 'my $x = qq(a\)b);', 'my $x = "a)b";',
    "escaped end delimiter is unescaped for double quotes";
  fixes q[my $x = qq(don't);], q(my $x = "don't";),
    "qq() with apostrophe becomes double-quoted";
  fixes q[my $x = qq(it's $y);], q(my $x = "it's $y";),
    "qq() with apostrophe and interpolation keeps double quotes";
};

subtest "qq() becomes single quotes" => sub {
  fixes 'my $x = qq(user\@domain.com);', q(my $x = 'user@domain.com';),
    'qq() with escaped @ becomes single-quoted';
  fixes 'my $x = qq(say "hi");', q(my $x = 'say "hi"';),
    "qq() with double quotes becomes single-quoted";
};

subtest "Justified quote operators are untouched" => sub {
  unchanged q[my $x = q(has 'single' and "double");],
    "q() with both quote types stays";
  unchanged q[my $x = qq(both 'q' and "qq" $x);],
    "qq() with both quote types stays";
  unchanged 'my $x = qq(tab\there);',
    "qq() with quote-sensitive escape stays";
};

done_testing
