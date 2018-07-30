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
  $p->inc('some_metric');
  is $p->format, <<EOF, 'single metric incremented correctly';
some_metric 1
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5);
  $p->inc('some_metric');
  is $p->format, <<EOF, 'single metric set then incremented correctly';
some_metric 6
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5);
  $p->dec('some_metric');
  is $p->format, <<EOF, 'single metric set then decremented correctly';
some_metric 4
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->inc('some_metric');
  $p->inc('some_metric');
  $p->dec('some_metric');
  $p->inc('some_metric');
  $p->dec('some_metric');
  $p->dec('some_metric');
  is $p->format, <<EOF, 'single metric inc/dec correctly';
some_metric 0
EOF
}

done_testing;
