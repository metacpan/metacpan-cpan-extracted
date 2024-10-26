#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

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

   is( HASHfromSample( $samples[0] ),
      { varname => "test_total", labels => [], value => 0 },
      '$samples[0] initially'
   );

   $counter->inc;

   is( HASHfromSample( ( $counter->samples )[0] ),
      { varname => "test_total", labels => [], value => 1 },
      '$samples[0]'
   );
}

# Remove and clear
{
   my $counter = Net::Prometheus::Counter->new(
      name   => "removal_test",
      help   => "A counter for testing removal",
      labels => [qw( x )],
   );

   $counter->inc( { x => "one" }, 1 );
   $counter->inc( { x => "two" }, 2 );
   $counter->inc( { x => "three" }, 3 );

   is( [ map { $_->labels } $counter->samples ],
      # Grr sorting
      [ [ x => "one" ], [ x => "three" ], [ x => "two" ] ],
      'labels before ->remove' );

   $counter->remove( { x => "one" } );

   is( [ map { $_->labels } $counter->samples ],
      [ [ x => "three" ], [ x => "two" ] ],
      'labels after ->remove' );

   $counter->clear;

   is( [ map { $_->labels } $counter->samples ],
      [],
      'labels after ->clear' );
}

done_testing;
