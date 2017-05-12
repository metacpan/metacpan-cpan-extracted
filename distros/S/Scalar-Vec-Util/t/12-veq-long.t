#!perl -T

use strict;
use warnings;

use Test::More tests => 1;
use Config qw<%Config>;

use Scalar::Vec::Util qw<veq>;

my ($v1, $v2) = ('') x 2;
my $n = ($Config{alignbytes} - 1) * 8;
vec($v1, $_, 1) = 0 for 0 .. $n - 1;
vec($v2, $_, 1) = 0 for 0 .. $n - 1;
my $i = $n / 2;
while ($i >= 1) {
 vec($v1, $i, 1) = 1;
 vec($v2, $i + 1, 1) = 1;
 $i /= 2;
}
ok veq($v1, 0, $v2, 1, 10 * $n), 'long veq is loooong';
