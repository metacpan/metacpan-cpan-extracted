#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 36;

use PerlBench::Stats qw(calc_stats);

my $res;
$res = calc_stats([]);
ok(!$res);

$res = calc_stats([1]);
ok($res);
ok($res->{avg}, 1);
ok($res->{min}, 1);
ok($res->{med}, 1);
ok($res->{max}, 1);
ok($res->{n}, 1);
ok($res->{stddev}, 0);

$res = calc_stats([1, 1]);
ok($res);
ok($res->{avg}, 1);
ok($res->{min}, 1);
ok($res->{med}, 1);
ok($res->{max}, 1);
ok($res->{n}, 2);
ok($res->{stddev}, 0);

$res = calc_stats([1, 2]);
ok($res);
ok($res->{avg}, 1.5);
ok($res->{min}, 1);
ok($res->{med}, 1.5);
ok($res->{max}, 2);
ok($res->{n}, 2);
ok(is_about($res->{stddev}, 0.5));

$res = calc_stats([5, 6, 8, 9]);
ok($res);
ok($res->{avg}, 7);
ok($res->{min}, 5);
ok($res->{med}, 7);
ok($res->{max}, 9);
ok($res->{n}, 4);
ok(is_about($res->{stddev}, 1.5811));

$res = calc_stats([3, 100, -1]);
ok($res);
ok($res->{avg}, 34);
ok($res->{min}, -1);
ok($res->{med}, 3);
ok($res->{max}, 100);
ok($res->{n}, 3);
ok(is_about($res->{stddev}, 46.6976));

sub is_about {
   my($v, $exp) = @_;
   return abs($v - $exp) < 1e-3;
}
