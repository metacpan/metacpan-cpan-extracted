#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Net::Prometheus;
use Net::Prometheus::PerlCollector;

$Net::Prometheus::PerlCollector::DETAIL = 1;

# Client should automatically include ::PerlCollector
my $client = Net::Prometheus->new;

# perl_heap_svs_by_type
{
   my @by_type = grep { m/^perl_heap_svs_by_type/ } split m/\n/, $client->render;

   # Don't need to test all the SV types but this should be sufficient
   ok( (grep { m/^perl_heap_svs_by_type\{type="ARRAY"} [1-9]\d+/ } @by_type),
      'Render output contains a non-zero count of ARRAYs' );
   ok( (grep { m/^perl_heap_svs_by_type\{type="CODE"} [1-9]\d+/ } @by_type),
      'Render output contains a non-zero count of CODEs' );
   ok( (grep { m/^perl_heap_svs_by_type\{type="HASH"} [1-9]\d+/ } @by_type),
      'Render output contains a non-zero count of HASHs' );
   ok( (grep { m/^perl_heap_svs_by_type\{type="SCALAR"} [1-9]\d+/ } @by_type),
      'Render output contains a non-zero count of SCALARs' );
}

$Net::Prometheus::PerlCollector::DETAIL = 2;

# perl_heap_svs_by_class
{
   # We should at least find a Net::Prometheus object in here somewhere
   like( $client->render,
      qr/^perl_heap_svs_by_class\{class="Net::Prometheus"\} [1-9]/m,
      'Render output finds at least one class="Net::Prometheus" object for DETAIL=2' );
}

# Leak check - it would be terrible if this tool itself leaked memory ;)
SKIP: {
   skip "Test::MemoryGrowth is not available", 1 unless eval { require Test::MemoryGrowth };

   Test::MemoryGrowth::no_growth( sub {
      $client->render;
   }, calls => 1000, burn_in => 2,
      'Detailed rendering does not leak memory' );
}

done_testing;
