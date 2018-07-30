#!perl

use warnings;
use strict;

use Test::More;

use Prometheus::Tiny::Shared;

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->declare('some_metric', help => 'My great metric');
  is $p->format, <<EOF, 'metric help formatted correctly';
# HELP some_metric My great metric
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->declare('some_metric', type => 'counter');
  is $p->format, <<EOF, 'metric type formatted correctly';
# TYPE some_metric counter
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->declare('some_metric', help => 'My great metric', type => 'counter');
  is $p->format, <<EOF, 'metric help & type formatted correctly';
# HELP some_metric My great metric
# TYPE some_metric counter
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->declare('some_metric', help => 'My great metric', type => 'counter');
  $p->declare('other_metric', help => 'My other great metric', type => 'gauge');
  $p->set('some_metric', 5);
  $p->set('other_metric', 10);
  is $p->format, <<EOF, 'multiple metric help & type formatted correctly';
# HELP other_metric My other great metric
# TYPE other_metric gauge
other_metric 10
# HELP some_metric My great metric
# TYPE some_metric counter
some_metric 5
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->declare('some_metric', help => 'My great metric', type => 'counter');
  $p->set('some_metric', 5);
  $p->set('other_metric', 10);
  is $p->format, <<EOF, 'multiple metric single help & type formatted correctly';
other_metric 10
# HELP some_metric My great metric
# TYPE some_metric counter
some_metric 5
EOF
}

done_testing;
