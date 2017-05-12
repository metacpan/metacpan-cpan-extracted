#!/usr/bin/env perl;
use Modern::Perl;
use Data::Dumper;
use Test::More;

my $module;

BEGIN {
  $module = 'Statistics::Cook';
  use_ok($module);
}
my @attrs = qw/x y weight slope intercept regress_done/;
my @methods = qw/_trigger_x _trigger_y regress computeSums coefficients
  fitted residuals cooks_distance N sd mean var/;

for my $attr(@attrs) {
  can_ok($module, $attr);
}

for my $method(@methods) {
  can_ok($module, $method);
}


my $obj = $module->new;
say  $obj->sd([1,2,3,4,5,6]);
say  $obj->sd(1,2,3);

done_testing;

1;

