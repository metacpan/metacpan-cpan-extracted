#!perl -T

use strict;
use warnings;

use Test::More tests => 34;

use Scalar::Vec::Util qw<vfill>;

BEGIN {
 *myfill = *Scalar::Vec::Util::vfill_pp;
 *myeq   = *Scalar::Vec::Util::veq_pp;
}

my $n = 2 ** 16;

my ($v, $c) = ('') x 2;

my $l = 1;
while ($l <= $n) {
 my $desc = "vfill 0, $l, 1";
 myfill $c, 0, $l, 1;
 vfill  $v, 0, $l, 1;
 is length $v, length $c,   "$desc: length";
 ok myeq($v, 0, $c, 0, $l), "$desc: bits";
 $l *= 2;
}
