#!perl

use warnings;
use strict;

use Test::More;

use Prometheus::Tiny::Shared;

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->histogram_observe('h', .273);
  is $p->format, <<EOF, 'single histogram observation formatted correctly';
h_bucket{le="0.005"} 0
h_bucket{le="0.01"} 0
h_bucket{le="0.025"} 0
h_bucket{le="0.05"} 0
h_bucket{le="0.075"} 0
h_bucket{le="0.1"} 0
h_bucket{le="0.25"} 0
h_bucket{le="0.5"} 1
h_bucket{le="0.75"} 1
h_bucket{le="1"} 1
h_bucket{le="10"} 1
h_bucket{le="2.5"} 1
h_bucket{le="5"} 1
h_bucket{le="7.5"} 1
h_bucket{le="+Inf"} 1
h_count 1
h_sum 0.273
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->histogram_observe('h', .2);
  $p->histogram_observe('h', .4);
  $p->histogram_observe('h', .6);
  $p->histogram_observe('h', .8);
  is $p->format, <<EOF, 'multiple histogram observations formatted correctly';
h_bucket{le="0.005"} 0
h_bucket{le="0.01"} 0
h_bucket{le="0.025"} 0
h_bucket{le="0.05"} 0
h_bucket{le="0.075"} 0
h_bucket{le="0.1"} 0
h_bucket{le="0.25"} 1
h_bucket{le="0.5"} 2
h_bucket{le="0.75"} 3
h_bucket{le="1"} 4
h_bucket{le="10"} 4
h_bucket{le="2.5"} 4
h_bucket{le="5"} 4
h_bucket{le="7.5"} 4
h_bucket{le="+Inf"} 4
h_count 4
h_sum 2.0
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->declare("h", buckets => [1,2,3,4,5]);
  $p->histogram_observe('h', .5);
  $p->histogram_observe('h', 1.5);
  $p->histogram_observe('h', 2.5);
  $p->histogram_observe('h', 3.5);
  is $p->format, <<EOF, 'multiple histogram observations with declared buckets formatted correctly';
h_bucket{le="1"} 1
h_bucket{le="2"} 2
h_bucket{le="3"} 3
h_bucket{le="4"} 4
h_bucket{le="5"} 4
h_bucket{le="+Inf"} 4
h_count 4
h_sum 8.0
EOF
}
done_testing;
