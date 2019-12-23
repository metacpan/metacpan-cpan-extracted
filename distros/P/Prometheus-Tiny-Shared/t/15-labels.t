#!perl

use warnings;
use strict;

use Test::More;

use Prometheus::Tiny::Shared;

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5, { some_label => 'aaa' });
  is $p->format, <<EOF, 'single metric with label formatted correctly';
some_metric{some_label="aaa"} 5
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5, { some_label => "aaa" });
  $p->set('other_metric', 10, { other_label => "bbb" });
  is $p->format, <<EOF, 'multiple metrics with labels formatted correctly';
other_metric{other_label="bbb"} 10
some_metric{some_label="aaa"} 5
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5, { some_label => "aaa" });
  $p->set('other_metric', 10);
  is $p->format, <<EOF, 'multiple metrics with mixed labels formatted correctly';
other_metric 10
some_metric{some_label="aaa"} 5
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 3, { some_label => "aaa" });
  $p->set('some_metric', 8, { some_label => "aaa" });
  is $p->format, <<EOF, 'single metric with same label is overwritten correctly';
some_metric{some_label="aaa"} 8
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 2, { some_label => "aaa" });
  $p->set('some_metric', 7, { other_label => "bbb" });
  is $p->format, <<EOF, 'single metric with different label keys are both formatted';
some_metric{other_label="bbb"} 7
some_metric{some_label="aaa"} 2
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 3, { some_label => "aaa" });
  $p->set('some_metric', 8, { some_label => "bbb" });
  is $p->format, <<EOF, 'single metric with different label values are both formatted';
some_metric{some_label="aaa"} 3
some_metric{some_label="bbb"} 8
EOF
}


{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5, { some_label => 'aaa' }, 1234);
  is $p->format, <<EOF, 'single metric with label and timestamp formatted correctly';
some_metric{some_label="aaa"} 5 1234
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5, { some_label => "aaa" }, 1234);
  $p->set('other_metric', 10, { other_label => "bbb" }, 2345);
  is $p->format, <<EOF, 'multiple metrics with labels and timestamps formatted correctly';
other_metric{other_label="bbb"} 10 2345
some_metric{some_label="aaa"} 5 1234
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5, { some_label => "aaa" }, 1234);
  $p->set('some_metric', 5, { some_label => "bbb" }, 2345);
  $p->set('some_metric', 5, { some_label => "ccc" }, 3456);
  $p->set('other_metric', 10, { other_label => "bbb" }, 4567);
  is $p->format, <<EOF, 'multiple metrics with labels and timestamps formatted correctly';
other_metric{other_label="bbb"} 10 4567
some_metric{some_label="aaa"} 5 1234
some_metric{some_label="bbb"} 5 2345
some_metric{some_label="ccc"} 5 3456
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->set('some_metric', 5, { some_label => "aaa" }, 1234);
  $p->set('other_metric', 10);
  is $p->format, <<EOF, 'multiple metrics with mixed labels formatted correctly';
other_metric 10
some_metric{some_label="aaa"} 5 1234
EOF
}

done_testing;
