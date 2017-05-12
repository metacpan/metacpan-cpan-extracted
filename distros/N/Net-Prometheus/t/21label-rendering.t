#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Net::Prometheus;
use Net::Prometheus::Metric;

my $sample;

no warnings 'redefine';
local *Net::Prometheus::Metric::_type = sub { "untyped" };
local *Net::Prometheus::Metric::samples = sub {
   return $sample;
};

my $client = Net::Prometheus->new(
   disable_process_collector => 1
);

{
   my $metric = $client->register( Net::Prometheus::Metric->new(
      name => "metric",
      labels => [ "lab" ],
      help => "",
   ) );

   sub test_label
   {
      my ( $label, $str, $name ) = @_;

      $sample = $metric->make_sample(
         "", $metric->labels( $label )->labelkey, 0
      );

      is( ( split m/\n/, $client->render )[2],
          qq(metric{lab="$str"} 0),
          "render for $name"
       );
   }

   test_label( "a", "a",
      'basic label',
   );

   test_label( "val here", "val here",
      'label with whitespace',
   );

   test_label( q("quoted"), q(\"quoted\"),
      'label with quotes',
   );

   test_label( 'ab\cd', "ab\\\\cd",
      'label with backslash',
   );

   test_label( "line\nfeed", "line\\nfeed",
      'label with linefeed',
   );

   test_label( "with\0null", "with\0null",
      'label with NUL byte',
   );

   $client->unregister( $metric );
}

{
   my $metric = $client->register( Net::Prometheus::Metric->new(
      name => "metric",
      labels => [ "x", "y" ],
      help => "",
   ) );

   $sample = $metric->make_sample(
      "", $metric->labels( "a", "b" )->labelkey, 0
   );

   is( ( split m/\n/, $client->render )[2],
       q(metric{x="a",y="b"} 0),
       '_render_value for multi-dimensional label' );

   $client->unregister( $metric );
}

done_testing;
