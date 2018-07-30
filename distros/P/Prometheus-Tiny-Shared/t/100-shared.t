#!perl

use warnings;
use strict;

use Test::More;

use Prometheus::Tiny::Shared;
use File::Temp qw(tmpnam);

my $cache_args = {
  share_file => scalar tmpnam(),
};

my $p1 = Prometheus::Tiny::Shared->new(cache_args => $cache_args);
my $p2 = Prometheus::Tiny::Shared->new(cache_args => $cache_args);

# set things on the first one
$p1->set('some_metric', 5);
$p1->set('other_metric', 10);

# format on the second
is $p2->format, <<EOF, 'set on client 1, format on client 2';
other_metric 10
some_metric 5
EOF

# set on the second, format on the first
$p2->set('other_metric', 8);
is $p1->format, <<EOF, 'set on client 2, format on client 1';
other_metric 8
some_metric 5
EOF

my $p3 = Prometheus::Tiny::Shared->new(cache_args => $cache_args);
is $p3->format, <<EOF, 'format on late client 3';
other_metric 8
some_metric 5
EOF

done_testing;

