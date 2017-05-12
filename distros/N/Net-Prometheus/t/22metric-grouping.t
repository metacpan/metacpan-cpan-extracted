#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Net::Prometheus;
use Net::Prometheus::Types qw( MetricSamples Sample );

my $client = Net::Prometheus->new(
   disable_process_collector => 1
);

{
   package CustomCollector;

   sub new { my $class = shift; bless [ @_ ], $class; }
   sub collect { shift->[0]->() }
}

$client->register( CustomCollector->new(
   sub {
      MetricSamples( "metric", gauge => "",
         [ Sample( "metric", [ label => "a" ], 123 ) ] )
   }
) );
$client->register( CustomCollector->new(
   sub {
      MetricSamples( "metric", gauge => "",
         [ Sample( "metric", [ label => "b" ], 123 ) ] )
   }
) );

my @samples = $client->collect;

is( scalar @samples, 1, '$client->collect returns 1 MetricSamples group' );
is( scalar @{ $samples[0]->samples }, 2, 'MetricSamples group contains both samples' );

done_testing;
