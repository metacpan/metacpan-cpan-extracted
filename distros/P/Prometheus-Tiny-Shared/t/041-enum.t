#!perl

use warnings;
use strict;

use Test::More;

use Prometheus::Tiny::Shared;

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->declare('some_state', enum => 'state', enum_values => [qw(FOO BAR BAZ)]);
  $p->enum_set('some_state', 'FOO');
  is $p->format, <<EOF, 'single enum set formatted correctly';
some_state{state="BAR"} 0
some_state{state="BAZ"} 0
some_state{state="FOO"} 1
EOF
}

{
  my $p = Prometheus::Tiny::Shared->new;
  $p->declare('some_state', enum => 'state', enum_values => [qw(FOO BAR BAZ)]);
  $p->enum_set('some_state', 'BAR', { one => "1", two => "2" });
  is $p->format, <<EOF, 'single enum set with lables formatted correctly';
some_state{one="1",state="BAR",two="2"} 1
some_state{one="1",state="BAZ",two="2"} 0
some_state{one="1",state="FOO",two="2"} 0
EOF
}

done_testing;
