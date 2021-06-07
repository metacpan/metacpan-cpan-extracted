#!perl

use warnings;
use strict;

use Test::More;
use Test::Exception;

use Prometheus::Tiny::Shared;

my $p = Prometheus::Tiny::Shared->new;

$p->declare('some_metric', type => 'counter', help => 'my great metric');
lives_ok(sub {
  $p->declare('some_metric', type => 'counter', help => 'my great metric');
}, 'redeclaring metric with same meta is allowed');

dies_ok(sub {
  $p->declare('some_metric', type => 'gauge', help => 'my great metric');
}, 'redeclaring metric with different meta values crashes');
dies_ok(sub {
  $p->declare('some_metric', help => 'my great metric');
}, 'redeclaring metric with missing meta values crashes');
dies_ok(sub {
  $p->declare('some_metric', type => 'counter', help => 'my great metric', buckets => []);
}, 'redeclaring metric with added meta values crashes');


$p->declare('h', buckets => [1,2,3,4,5]);
lives_ok(sub {
  $p->declare('h', buckets => [1,2,3,4,5]);
}, 'redeclaring histogram metric with same buckets is allowed');

dies_ok(sub {
  $p->declare('h');
}, 'redeclaring histogram metric with missing buckets crashes');
dies_ok(sub {
  $p->declare('h', buckets => [1,2,3]);
}, 'redeclaring histogram metric with different number of buckets crashes');
dies_ok(sub {
  $p->declare('h', buckets => [1,2,3,4,8]);
}, 'redeclaring histogram metric with different buckets crashes');

done_testing;
