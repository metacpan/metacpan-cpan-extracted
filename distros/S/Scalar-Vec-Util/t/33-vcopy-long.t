#!perl -T

use strict;
use warnings;

use Test::More tests => 34 + 2;
use Config qw<%Config>;

use Scalar::Vec::Util qw<vcopy>;

BEGIN {
 *myfill = *Scalar::Vec::Util::vfill_pp;
 *myeq   = *Scalar::Vec::Util::veq_pp;
}

my $n = 2 ** 16;

my ($v, $c) = ('') x 2;

my $l = 1;
vec($v, 0, 1) = 1;
vec($c, 0, 1) = 1;
while ($l <= $n) {
 my $desc = "vcopy $l";
 myfill $c, $l, $l, 1;
 vcopy  $v, 0,  $v, $l, $l;
 $l *= 2;
 is length $v, length $c,   "$desc: length";
 ok myeq($v, 0, $c, 0, $l), "$desc: bits";
}

{
 my $desc = 'vcopy with fill';
 my ($w, $k) = ('') x 2;
 $n = ($Config{alignbytes} - 1) * 8;
 my $p = 4 + $n / 2;
 vec($w, $_, 1)      = 1 for 0  .. $n - 1;
 vec($k, $_, 1)      = 0 for 0  .. $n - 1;
 vec($k, $_ - $p, 1) = 1 for $p .. $n - 1;
 vcopy $w, $p, $w, 0, $n;
 is length $w, length $k,   "$desc: length";
 ok myeq($w, 0, $k, 0, $n), "$desc: bits";
}
