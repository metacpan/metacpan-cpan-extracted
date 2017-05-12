#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Net::Prometheus;

my $client = Net::Prometheus->new(
   disable_process_collector => 1
);

ok( defined $client, 'defined $client' );

# initially empty
is( $client->render, "", '$client->render gives empty string' );

# with some metrics
{
   $client->new_gauge(
      name => "gauge",
      help => "A gauge metric",
   )->set( 123 );

   $client->new_counter(
      name => "counter",
      help => "A counter metric",
   )->inc();

   is( $client->render, <<'EOF', '$client->render gives metric results' );
# HELP counter A counter metric
# TYPE counter counter
counter 1
# HELP gauge A gauge metric
# TYPE gauge gauge
gauge 123
EOF
}

# metric groups
{
   is(
      $client->new_metricgroup(
         namespace => "namespc"
      )->new_gauge(
         subsystem => "subsys",
         name => "gauge",
         help => ""
      )->fullname,
      "namespc_subsys_gauge",
      'Metric Group can provide default namespace'
   );

   is(
      $client->new_metricgroup(
         subsystem => "subsys",
      )->new_gauge(
         name => "gauge",
         help => ""
      )->fullname,
      "subsys_gauge",
      'Metric Group can provide default subsystem'
   );
}

done_testing;
