#!perl

use warnings;
use strict;

use Test::More;

use Prometheus::Tiny::Shared;

{
  my $p = Prometheus::Tiny::Shared->new;
  is $p->format, '', 'no metrics produces no output';
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5);
  is $p->format, <<EOF, 'single metric formatted correctly';
some_metric 5
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5);
  $p->set('other_metric', 10);
  is $p->format, <<EOF, 'multiple metrics formatted correctly';
other_metric 10
some_metric 5
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 3);
  $p->set('some_metric', 8);
  is $p->format, <<EOF, 'single metric is overwritten correctly';
some_metric 8
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5, {}, 1234);
  is $p->format, <<EOF, 'single metric with timestamp formatted correctly';
some_metric 5 1234
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5, {}, 2345);
  $p->set('other_metric', 10, {}, 1234);
  is $p->format, <<EOF, 'multiple metrics with timestamp formatted correctly';
other_metric 10 1234
some_metric 5 2345
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 3, {}, 1234);
  $p->set('some_metric', 8, {}, 2345);
  is $p->format, <<EOF, 'single metric with timestamp is overwritten correctly';
some_metric 8 2345
EOF
}

done_testing;
