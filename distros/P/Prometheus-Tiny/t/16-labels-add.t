#!perl

use warnings;
use strict;

use Test::More;

use Prometheus::Tiny;

{
  my $p = Prometheus::Tiny->new;
  $p->add('some_metric', 5, { some_label => 'aaa' });
  is $p->format, <<EOF, 'single metric with label adds correctly';
some_metric{some_label="aaa"} 5
EOF
}

{
  my $p = Prometheus::Tiny->new;
  $p->inc('some_metric', { some_label => "aaa" });
  is $p->format, <<EOF, 'single metric with label increments correctly';
some_metric{some_label="aaa"} 1
EOF
}

{
  my $p = Prometheus::Tiny->new;
  $p->dec('some_metric', { some_label => "aaa" });
  is $p->format, <<EOF, 'single metric with label decrements correctly';
some_metric{some_label="aaa"} -1
EOF
}

done_testing;
