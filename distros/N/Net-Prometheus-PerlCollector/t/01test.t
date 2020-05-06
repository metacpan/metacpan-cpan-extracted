#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Net::Prometheus;
use Net::Prometheus::PerlCollector;

# Client should automatically include ::PerlCollector
my $client = Net::Prometheus->new;

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

done_testing;
