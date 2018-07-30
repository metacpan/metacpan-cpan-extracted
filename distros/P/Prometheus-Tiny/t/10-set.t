#!perl

use warnings;
use strict;

use Test::More;

use Prometheus::Tiny;

{
  my $p = Prometheus::Tiny->new;
  is $p->format, '', 'no metrics produces no output';
}

{
  my $p = Prometheus::Tiny->new;
  $p->set('some_metric', 5);
  is $p->format, <<EOF, 'single metric formatted correctly';
some_metric 5
EOF
}

{
  my $p = Prometheus::Tiny->new;
  $p->set('some_metric', 5);
  $p->set('other_metric', 10);
  is $p->format, <<EOF, 'multiple metrics formatted correctly';
other_metric 10
some_metric 5
EOF
}

{
  my $p = Prometheus::Tiny->new;
  $p->set('some_metric', 3);
  $p->set('some_metric', 8);
  is $p->format, <<EOF, 'single metric is overwritten correctly';
some_metric 8
EOF
}

done_testing;
