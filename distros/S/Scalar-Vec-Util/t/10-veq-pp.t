#!perl -T

use strict;
use warnings;

use Test::More 'no_plan';

use Scalar::Vec::Util;

for ([ 1, 'offset', -1 ], [ 3, 'offset', '-1' ], [ 4, 'length', -1 ]) {
 my @args  = ('1') x 5;
 $args[$_->[0]] = $_->[2];
 local $@;
 eval { &Scalar::Vec::Util::veq_pp(@args) };
 my $err  = $@;
 my $line = __LINE__-2;
 like $err, qr/^Invalid\s+negative\s+$_->[1]\s+at\s+\Q$0\E\s+line\s+$line/,
      "veq_pp(@args) failed";
}

my $p = 8;
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

my @s = ($p - $q) .. ($p + $q);
for my $s1 (@s) {
 for my $s2 (@s) {
  for my $l (0 .. $n - 1) {
   next if $s1 + $l > $n or $s2 + $l > $n;
   my $v1 = '';
   my $v2 = '';
   pat $v1, $s1, $l, 0, 0;
   pat $v2, $s2, $l, 0, 1;
   my $desc = "veq_pp $s1, $s2, $l";
   ok   Scalar::Vec::Util::veq_pp($v1 => $s1,     $v2 => $s2, $l),
        "$desc [1<=>2]";
   ok   Scalar::Vec::Util::veq_pp($v2 => $s2,     $v1 => $s1, $l),
        "$desc [2<=>1]";
   if ($l > 0) {
    ok !Scalar::Vec::Util::veq_pp($v1 => $s1 - 1, $v2 => $s2, $l),
        'not veq_pp ' . ($s1-1) . ", $s2, $l [1<=>2]";
    ok !Scalar::Vec::Util::veq_pp($v1 => $s1 + 1, $v2 => $s2, $l),
        'not veq_pp ' . ($s1+1) . ", $s2, $l [1<=>2]";
   }
  }
 }
}
