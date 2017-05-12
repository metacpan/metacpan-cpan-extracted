#!perl -T

use strict;
use warnings;

use Test::More 'no_plan';

use Scalar::Vec::Util;

BEGIN {
 *myeq = *Scalar::Vec::Util::veq_pp;
}

for ([ 1, 'offset', -1 ], [ 2, 'length', '-1' ]) {
 my @args  = ('1') x 4;
 $args[$_->[0]] = $_->[2];
 local $@;
 eval { &Scalar::Vec::Util::vfill_pp(@args) };
 my $err  = $@;
 my $line = __LINE__-2;
 like $err, qr/^Invalid\s+negative\s+$_->[1]\s+at\s+\Q$0\E\s+line\s+$line/,
      "vfill_pp(@args) failed";
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
 $_[0] = '';
}

my ($v, $c) = ('') x 2;

my @s = ($p - $q) .. ($p + $q);
for my $s (@s) {
 for my $l (0 .. $n - 1) {
  next if $s + $l > $n;
  my $desc = "vfill_pp $s, $l";
  rst $c;
  myfill $c, 0,  $s, 0;
  myfill $c, $s, $l, 1;
  rst $v;
  Scalar::Vec::Util::vfill_pp($v, 0,  $s, 0);
  Scalar::Vec::Util::vfill_pp($v, $s, $l, 1);
  is length $v, length $c,   "$desc: length";
  ok myeq($v, 0, $c, 0, $n), "$desc: bits";
 }
}
