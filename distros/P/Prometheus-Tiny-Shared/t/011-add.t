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
  $p->add('some_metric', 2);
  is $p->format, <<EOF, 'single metric added correctly';
some_metric 2
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5);
  $p->add('some_metric', 10);
  is $p->format, <<EOF, 'single metric set then added correctly';
some_metric 15
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->add('some_metric', 3);
  $p->add('some_metric', 8);
  $p->add('some_metric', 2);
  is $p->format, <<EOF, 'single metric multiple adds correct';
some_metric 13
EOF
}

done_testing;
