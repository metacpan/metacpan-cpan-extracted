#!/usr/bin/perl6
use v6;

my $x = 23;
my $y = 42;
my $z = 'foo';

($x, $y) = ($y, $x);

say $x;    # 42
say $y;    # 23


($x, $y, $z) = ($y, $z, $x);
say $x;    # 23
say $y;    # foo
say $z;    # 42
