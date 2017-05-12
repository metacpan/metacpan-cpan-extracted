#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner 'no_plan';

use Scalar::Vec::Util qw<vcopy SVU_SIZE>;

BEGIN {
 *myfill = *Scalar::Vec::Util::vfill_pp;
 *myeq   = *Scalar::Vec::Util::veq_pp;
}

my $p = SVU_SIZE;
$p    = 8 if $p < 8;
my $n = 3 * $p;
my $q = 1;

sub rst {
 myfill $_[0], 0, $n, 0;
 $_[0] = '';
}

sub pat {
 my (undef, $a, $b, $x) = @_;
 if ($b) {
  $_[0] = '';
  myfill $_[0], 0,       $a,             $x;
  myfill $_[0], $a,      $b,             1 - $x;
  myfill $_[0], $a + $b, $n - ($a + $b), $x      if $a + $b < $n;
 } else {
  rst $_[0];
 }
}

sub prnt {
 my (undef, $n, $desc) = @_;
 my $s = '';
 $s .= vec($_[0], $_, 1) for 0 .. $n - 1;
 diag "$desc: $s";
}

my ($v, $c) = ('') x 2;

my @s = (0 .. $q, ($p - $q) .. ($p + $q));
for my $s1 (@s) {
 for my $s2 (@s) {
  for my $l (0 .. $n - 1) {
   for my $x (0 .. $q) {
    for my $y (0 .. $q) {
     next if $l - $x - $y < 0 or $s2 + $l - $y < 0;
     my $desc = "vcopy [ $x, $y ], $s1, $s2, $l (move)";
     pat $v, $s1 + $x, $l - $x - $y, 0;
     my $v0 = $v;
     $c = $v;
     myfill $c, $s2,           $x,           0 if $x;
     myfill $c, $s2 + $x,      $l - $x - $y, 1;
     myfill $c, $s2 + $l - $y, $y,           0 if $y;
     vcopy $v => $s1, $v => $s2, $l;
     is length $v, length $c,   "$desc: length";
     ok myeq($v, 0, $c, 0, $n), "$desc: bits" or do {
      diag "n = $n, s1 = $s1, s2 = $s2, l = $l, x = $x, y = $y";
      prnt $v0, $n, 'original';
      prnt $v,  $n, 'got     ';
      prnt $c,  $n, 'expected';
     }
    }
   }
  }
 }
}
