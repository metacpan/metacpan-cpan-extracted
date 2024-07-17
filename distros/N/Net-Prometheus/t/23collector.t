#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Net::Prometheus;

my $client = Net::Prometheus->new(
   disable_process_collector => 1,
   disable_perl_collector    => 1,
);

$client->register( CustomCollector->new );

my $collector_options;

$client->render( { custom_collector_option => 123 } );

is( $collector_options, { custom_collector_option => 123 },
   'CustomCollector->collect invoked with options' );

done_testing;

package CustomCollector;

sub new { return bless {}, shift }

sub collect
{
   shift;
   ( $collector_options ) = @_;

   return ();
}
