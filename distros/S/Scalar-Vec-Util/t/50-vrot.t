#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner 'no_plan';

use Scalar::Vec::Util qw<vrot vcopy SVU_SIZE>;

BEGIN {
 *myfill = *Scalar::Vec::Util::vfill_pp;
 *myeq   = *Scalar::Vec::Util::veq_pp;
}

for ([ 1, 'offset', -1 ], [ 2, 'length', '-1' ]) {
 my @args  = ('1') x 4;
 $args[$_->[0]] = $_->[2];
 local $@;
 eval { &vrot(@args) };
 my $err  = $@;
 my $line = __LINE__-2;
 like $err, qr/^Invalid\s+negative\s+$_->[1]\s+at\s+\Q$0\E\s+line\s+$line/,
      "vrot(@args) failed";
}

my $p = SVU_SIZE;
$p    = 8 if $p < 8;
my $n = 3 * $p;
my $q = 2;

sub rst {
 myfill $_[0], 0, $n, 0;
 $_[0] = '';
}

sub pat {
 my (undef, $a, $b, $c, $x) = @_;
 $_[0] = '';
 myfill $_[0], 0,            $a,                  $x;
 myfill $_[0], $a,           $b,                  1 - $x;
 myfill $_[0], $a + $b,      $c,                  $x;
 myfill $_[0], $a + $b + $c, $n - ($a + $b + $c), 1 - $x;
}

sub expected {
 my (undef, $s, $l, $b, $left) = @_;
 unless ($l) {
  myfill $_[0], 0,  $s,      0;
  myfill $_[0], $s, $n - $s, 1;
  return;
 }
 my $lx = int($l / 2);
 my $ly = $l - $lx;
 $b %= $l;
 $_[0] = '';
 myfill $_[0], 0, $s, 0;
 if ($left) {
  if ($b <= $ly) {
   myfill $_[0], $s,            $b,            0;
   myfill $_[0], $s + $b,       $lx,           1;
   myfill $_[0], $s + $b + $lx, $l - $lx - $b, 0;
  } else {
   myfill $_[0], $s,            $b - $ly, 1;
   myfill $_[0], $s + $b - $ly, $ly,      0;
   myfill $_[0], $s + $b,       $l - $b,  1;
  }
 } else {
  if ($b <= $lx) {
   myfill $_[0], $s,            $lx - $b, 1;
   myfill $_[0], $s + $lx - $b, $l - $lx, 0;
   myfill $_[0], $s + $l  - $b, $b,       1;
  } else {
   myfill $_[0], $s,                 $ly - ($b - $lx), 0;
   myfill $_[0], $s + $l - $b,       $lx,              1;
   myfill $_[0], $s + $l + $lx - $b, $b - $lx,         0;
  }
 }
 myfill $_[0], $s + $l, $n - $s - $l, 1;
}

sub prnt {
 my (undef, $n, $desc) = @_;
 my $s;
 $s .= vec($_[0], $_, 1) for 0 .. $n - 1;
 diag "$desc: $s";
}

my ($v, $v0, $c) = ('', '') x 2;

sub try {
 my ($left) = @_;
 my @s = ($p - $q) .. ($p + $q);
 for my $s (@s) {
  for my $l (0 .. $n - 1) {
   next if $s + $l > $n;
   my $l2 = int($l/2);
   rst $v0;
   pat $v0, $s, $l2, $l - $l2, 0;
   my @b = (0, 3, 5, 7, 11, 13, 17, $l2, $l2 + 1, $l + 1);
   @b = do { my %seen; ++$seen{$_} for @b; sort keys %seen };
   for my $b (@b) {
    my $desc = "vrot $s, $l, $b";
    $v = $v0;
    expected $c, $s, $l, $b, $left;
    $b = -$b unless $left;
    vrot $v, $s, $l, $b;
    is length $v, length $c,   "$desc: length";
    ok myeq($v, 0, $c, 0, $n), "$desc: bits" or do {
     diag "n = $n, s = $s, l = $l, l2 = $l2";
     prnt $v0, $n, 'original';
     prnt $v, $n,  'got     ';
     prnt $c, $n,  'expected';
    }
   }
  }
 }
}

try 1;
try 0;
