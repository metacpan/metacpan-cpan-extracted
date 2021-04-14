#!perl

use warnings;
use strict;

use Test::More;

use Prometheus::Tiny::Shared;

my $p = Prometheus::Tiny::Shared->new;
$p->declare('some_metric', help => 'My great metric', type => 'counter');
$p->declare('other_metric', help => 'My other great metric', type => 'gauge');

$p->set('some_metric', 5);
$p->set('other_metric', 10);
is $p->format, <<EOF, 'normal operation';
# HELP other_metric My other great metric
# TYPE other_metric gauge
other_metric 10
# HELP some_metric My great metric
# TYPE some_metric counter
some_metric 5
EOF

$p->clear;
is $p->format, <<EOF, 'no metrics after clearing, just the meta';
# HELP other_metric My other great metric
# TYPE other_metric gauge
# HELP some_metric My great metric
# TYPE some_metric counter
EOF

$p->set('some_metric', 20);
$p->set('other_metric', 30);
is $p->format, <<EOF, 'new metrics values after clear';
# HELP other_metric My other great metric
# TYPE other_metric gauge
other_metric 30
# HELP some_metric My great metric
# TYPE some_metric counter
some_metric 20
EOF

done_testing;
