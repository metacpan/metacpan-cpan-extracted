#!perl -T

use strict;
use warnings;

use Test::More 'no_plan';

use Scalar::Vec::Util qw<veq SVU_SIZE>;

for ([ 1, 'offset', -1 ], [ 3, 'offset', '-1' ], [ 4, 'length', -1 ]) {
 my @args  = ('1') x 5;
 $args[$_->[0]] = $_->[2];
 local $@;
 eval { &veq(@args) };
 my $err  = $@;
 my $line = __LINE__-2;
 like $err, qr/^Invalid\s+negative\s+$_->[1]\s+at\s+\Q$0\E\s+line\s+$line/,
      "veq(@args) failed";
}

my $p = SVU_SIZE;
$p    = 8 if $p < 8;
my $n = 3 * $p;
my $q = 1;

sub myfill {
 my (undef, $s, $l, $x) = @_;
 $x = 1 if $x;
 vec($_[0], $_, 1) = $x for $s .. $s + $l - 1;
}

sub rst {
 myfill $_[0], 0, $n, 0;
}

sub pat {
 my (undef, $a, $b, $x, $y) = @_;
 myfill $_[0], 0,       $a,             $x;
 myfill $_[0], $a,      $b,             1 - $x;
 myfill $_[0], $a + $b, $n - ($a + $b), $x     if $y;
}

my $z = '';

my @s = ($p - $q) .. ($p + $q);
for my $s1 (@s) {
 for my $s2 (@s) {
  for my $l (0 .. $n) {
   next if $s1 + $l > $n or $s2 + $l > $n;
   my $v1 = '';
   my $v2 = '';
   pat $v1, $s1, $l, 0, 0;
   pat $v2, $s2, $l, 0, 1;
   if ($l > 0) {
    my $desc = "not veq 0, 0, $n";
    ok    !veq($v1 => 0, $z  => 0, $n), "$desc [1<=>0,$l]";
    ok    !veq($z  => 0, $v1 => 0, $n), "$desc [0<=>1,$l]";
   }
   for my $r ($l, $l + $n + 1) {
    my $desc = "veq $s1, $s2, $r";
    ok     veq($v1 => $s1,   $v2 => $s2,   $r), "$desc [1<=>2,$l]";
    ok     veq($v2 => $s2,   $v1 => $s1,   $r), "$desc [2<=>1,$l]";
    if ($l > 0) { # Implies $r > 0
     if ($s1 > 0) {
      my $desc = 'not veq ' . ($s1 - 1). ", $s2, $r";
      ok !veq($v1 => $s1-1, $v2 => $s2,   $r), "$desc [1-1<=>2,$l]";
      ok !veq($v2 => $s2,   $v1 => $s1-1, $r), "$desc [2<=>1-1,$l]";
     }
     {
      my $desc = 'not veq ' . ($s1 + 1). ", $s2, $r";
      ok !veq($v1 => $s1+1, $v2 => $s2,   $r), "$desc [1+1<=>2,$l]";
      ok !veq($v2 => $s2,   $v1 => $s1+1, $r), "$desc [2<=>1+1,$l]";
     }
    }
   }
  }
 }
}
