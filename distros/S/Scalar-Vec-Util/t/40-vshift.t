#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner 'no_plan';

use Scalar::Vec::Util qw<vshift SVU_SIZE>;

BEGIN {
 *myfill = *Scalar::Vec::Util::vfill_pp;
 *myeq   = *Scalar::Vec::Util::veq_pp;
}

for ([ 1, 'offset', -1 ], [ 2, 'length', '-1' ]) {
 my @args  = ('1') x 4;
 $args[$_->[0]] = $_->[2];
 local $@;
 eval { &vshift(@args) };
 my $err  = $@;
 my $line = __LINE__-2;
 like $err, qr/^Invalid\s+negative\s+$_->[1]\s+at\s+\Q$0\E\s+line\s+$line/,
      "vshift(@args) failed";
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
 my (undef, $a, $b, $x) = @_;
 $_[0] = '';
 $x = $x ? 1 : 0;
 if (defined $b) {
  myfill $_[0], 0,  $a, $x;
  myfill $_[0], $a, $b, 1 - $x;
 }
}

sub expect {
 my (undef, $s, $l, $b, $left, $insert) = @_;
 myfill $_[0], 0, $s, 0;
 if ($b < $l) {
  if ($left) {
   myfill $_[0], $s,      $b,      defined $insert ? $insert : 1;
   myfill $_[0], $s + $b, $l - $b, 1;
  } else {
   myfill $_[0], $s,           $l - $b, 1;
   myfill $_[0], $s + $l - $b, $b,      defined $insert ? $insert : 1;
  }
 } else {
  myfill $_[0], $s, $l, defined $insert ? $insert : 1;
 }
}

my ($v, $v0, $c) = ('', '') x 2;

sub try {
 my ($left, $insert) = @_;
 my @s = ($p - $q) .. ($p + $q);
 for my $s (@s) {
  for my $l (0 .. $n - 1) {
   next if $s + $l > $n;
   rst $v0;
   pat $v0, $s, $l, 0;
   my @b = (0);
   my $l2 = int($l/2);
   push @b, $l2 if $l2 != $l;
   push @b, $l + 1;
   for my $b (@b) {
    my $desc = "vshift $s, $l, $b, " . (defined $insert ? $insert : 'undef');
    $v = $v0;
    rst $c;
    expect $c, $s, $l, $b, $left, $insert;
    $b = -$b unless $left;
    vshift $v, $s, $l => $b, $insert;
    is length $v, length $c,   "$desc: length";
    ok myeq($v, 0, $c, 0, $n), "$desc: bits";
   }
  }
 }
}

try 1;
try 1, 0;
try 1, 1;
try 0;
try 0, 0;
try 0, 1;
