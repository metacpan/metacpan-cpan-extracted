#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;

use Net::Prometheus;
use Net::Prometheus::PerlCollector;

# Client should automatically include ::PerlCollector
my $client = Net::Prometheus->new;

# perl_info
{
   like( $client->render,
      qr/^perl_info\{version="5\.\d+\.\d+"\} 1$/m,
      'Render output contains perl platform info' );
}

if( Net::Prometheus::PerlCollector::HAVE_XS ) {
   # perl_heap_arenas
   {
      like( $client->render,
         qr/^perl_heap_arenas [1-9]\d*$/m,
         'Render output contains non-zero perl_heap_arenas' );
   }

   # perl_heap_svs
   {
      like( $client->render,
         qr/^perl_heap_svs [1-9]\d*$/m,
         'Render output contains non-zero perl_heap_svs' );
   }
}

done_testing;
