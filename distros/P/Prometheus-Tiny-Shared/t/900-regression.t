#!perl

use warnings;
use strict;

use Test::More;

use Prometheus::Tiny::Shared;

# 0.003 introduced timestamp supported, stored in $meta{timestamp}, which
# tramples the metadata for a declared metric named for keys under the meta namespace
{
  my $p = Prometheus::Tiny::Shared->new;
  $p->declare('help', help => 'my help metric', type => 'gauge');
  $p->set('help', 1234);
  is $p->format, <<EOF, 'declared metric named "help" formatted correctly';
# HELP help my help metric
# TYPE help gauge
help 1234
EOF

  $p->set('help', 2345, {}, 3456);
  is $p->format, <<EOF, 'declared metric named "help" with timestamp formatted correctly';
# HELP help my help metric
# TYPE help gauge
help 2345 3456
EOF
}

done_testing;

