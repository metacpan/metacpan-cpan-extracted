#!perl

use warnings;
use strict;

use Test::More;
use Test::Warn;

use Prometheus::Tiny;

{
  my $p = Prometheus::Tiny->new;
  $p->set('some_metric', 10);
  warning_like
    { $p->set('some_metric') }
    qr/setting '.+' to non-numeric value, using 0 instead/,
    'setting undef value emits a warning';
  is $p->format, <<EOF, 'set metric undef formatted correctly';
some_metric 0
EOF
}

{
  my $p = Prometheus::Tiny->new;
  $p->set('some_metric', 10);
  warning_like
    { $p->add('some_metric') }
    qr/adjusting '.+' by non-numeric value, adding 0 instead/,
    'adding undef value emits a warning';
  is $p->format, <<EOF, 'add metric undef formatted correctly';
some_metric 10
EOF
}

done_testing;
