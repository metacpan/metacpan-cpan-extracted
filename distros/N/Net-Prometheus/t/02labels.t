#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Net::Prometheus::Metric;

# samples
{
   my $metric = Net::Prometheus::Metric->new(
      name => "basename",
      help => "",
      labels => [qw( labelname )],
   );

   # TODO: child instances are still undocumented
   my $sample = $metric->make_sample(
      undef, $metric->labels( "value" )->labelkey, 123
   );

   is( $sample->varname, "basename",                     '$sample->varname' );
   is_deeply( $sample->labels, [ labelname => "value" ], '$sample->labels' );
   is( $sample->value, 123,                              '$sample->value' );

   is_deeply(
      $metric->make_sample(
         undef, $metric->labels( "value" )->labelkey, 123, [ another => "label" ],
      )->labels,
      [ labelname => "value", another => "label" ],
      '$sample->labels with morelabels'
   );
}

# exceptions
{
   ok( exception {
         Net::Prometheus::Metric->new(
            name => "metric",
            labels => [ "ab/cd" ],
            help => "",
         )
      }, 'Invalid label name dies'
   );

   ok( exception {
         Net::Prometheus::Metric->new(
            name => "metric",
            labels => [ "__name" ],
            help => "",
         )
      }, 'Reserved label name dies'
   );

   ok( exception {
         my $metric = Net::Prometheus::Metric->new(
            name => "metric",
            labels => [ "label" ],
            help => "",
         );

         $metric->labels( "" );
      }, 'Empty label value dies'
   );
}

done_testing;
