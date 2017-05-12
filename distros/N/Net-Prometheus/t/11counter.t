#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Net::Prometheus::Counter;

sub HASHfromSample
{
   my ( $sample ) = @_;
   return { map { $_, $sample->$_ } qw( varname labels value ) };
}

{
   my $counter = Net::Prometheus::Counter->new(
      name => "test_total",
      help => "A testing counter",
   );

   ok( defined $counter, 'defined $counter' );

   my @samples = $counter->samples;
   is( scalar @samples, 1, '$counter->samples yields 1 sample' );

   is_deeply( HASHfromSample( $samples[0] ),
      { varname => "test_total", labels => [], value => 0 },
      '$samples[0] initially'
   );

   $counter->inc;

   is_deeply( HASHfromSample( ( $counter->samples )[0] ),
      { varname => "test_total", labels => [], value => 1 },
      '$samples[0]'
   );
}

done_testing;
