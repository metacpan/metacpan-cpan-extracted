#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;

use Net::Prometheus;

my $client = Net::Prometheus->new(
   disable_process_collector => 1,
   disable_perl_collector    => 1,
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

# NaN rendering
{
   my $client = Net::Prometheus->new(
      disable_process_collector => 1,
      disable_perl_collector    => 1,
   );

   $client->new_gauge(
      name => "gauge",
      help => "undefined",
   )->set( "nan" );

   is( $client->render, <<'EOF', '$client->render renders NaN' );
# HELP gauge undefined
# TYPE gauge gauge
gauge NaN
EOF
}

# undef is absent
{
   my $client = Net::Prometheus->new(
      disable_process_collector => 1,
      disable_perl_collector    => 1,
   );

   $client->new_gauge(
      name => "gauge",
      help => "undefined",
   )->set( undef );

   is( $client->render, <<'EOF', '$client->render renders undef absent' );
# HELP gauge undefined
# TYPE gauge gauge
EOF
}

# HELP escaping
{
   my $client = Net::Prometheus->new(
      disable_process_collector => 1,
      disable_perl_collector    => 1,
   );

   $client->new_gauge(
      name => "gauge",
      help => "with\nlinefeed",
   )->set( 0 );

   is( $client->render, <<'EOF', '$client->render escapes HELP text' );
# HELP gauge with\nlinefeed
# TYPE gauge gauge
gauge 0
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
