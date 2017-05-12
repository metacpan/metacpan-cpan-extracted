#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Net::Prometheus::Gauge;

sub HASHfromSample
{
   my ( $sample ) = @_;
   return { map { $_, $sample->$_ } qw( varname labels value ) };
}

# No labels
{
   my $gauge = Net::Prometheus::Gauge->new(
      name => "test_gauge",
      help => "A testing gauge",
   );

   ok( defined $gauge, 'defined $gauge' );

   my @samples = $gauge->samples;
   is( scalar @samples, 1, '$gauge->samples yields 1 sample' );

   is_deeply( HASHfromSample( $samples[0] ),
      { varname => "test_gauge", labels => [], value => 0, },
      '$samples[0] initially'
   );

   $gauge->inc;

   @samples = $gauge->samples;
   is( $samples[0]->value, 1, 'sample->value after $gauge->inc' );

   $gauge->inc( 10 );

   @samples = $gauge->samples;
   is( $samples[0]->value, 11, 'sample->value after $gauge->inc( 10 )' );

   $gauge->dec( 5 );

   @samples = $gauge->samples;
   is( $samples[0]->value, 6, 'sample->value after $gauge->dec( 5 )' );
}

# Functions
{
   my $gauge = Net::Prometheus::Gauge->new(
      name => "func_gauge",
      help => "A gauge reporting a function",
   );

   my $value;
   $gauge->set_function( sub { $value } );

   $value = 10;
   is( ( $gauge->samples )[0]->value, 10, 'sample->value from function' );

   $value = 20;
   is( ( $gauge->samples )[0]->value, 20, 'sample->value updates' );
}

# One label
{
   my $gauge = Net::Prometheus::Gauge->new(
      name => "labeled_gauge",
      help => "A gauge with a label",
      labels => [qw( lab )],
   );

   is_deeply( [ $gauge->samples ], [],
      '$gauge->samples initially empty'
   );

   $gauge->set( one => 1 );
   $gauge->set( two => 2 );

   # FRAGILE: depends on the current implementation sorting these
   my @samples = $gauge->samples;
   is( scalar @samples, 2, '$gauge->samples yields 2 samples' );

   is_deeply( [ map { HASHfromSample( $_ ) } @samples ],
      [
         { varname => "labeled_gauge", labels => [ lab => "one" ], value => 1 },
         { varname => "labeled_gauge", labels => [ lab => "two" ], value => 2 },
      ],
      '@samples'
   );

   $gauge->labels( "three" )->set( 3 );

   is_deeply( [ map { HASHfromSample( $_ ) } $gauge->samples ],
      [
         { varname => "labeled_gauge", labels => [ lab => "one"   ], value => 1 },
         { varname => "labeled_gauge", labels => [ lab => "three" ], value => 3 },
         { varname => "labeled_gauge", labels => [ lab => "two"   ], value => 2 },
      ],
      '@samples after adding "three"'
   );
}

# Two labels
{
   my $gauge = Net::Prometheus::Gauge->new(
      name => "multidimensional_gauge",
      help => "A gauge with two labels",
      labels => [qw( x y )],
   );

   $gauge->set( 0 => 0 => 10 );
   $gauge->set( 0 => 1 => 20 );
   $gauge->set( 1 => 0 => 30 );
   $gauge->set( 1 => 1 => 40 );

   is_deeply( [ map { HASHfromSample( $_ ) } $gauge->samples ],
      [
         { varname => "multidimensional_gauge", labels => [ x => "0", y => "0" ],
            value => 10 },
         { varname => "multidimensional_gauge", labels => [ x => "0", y => "1" ],
            value => 20 },
         { varname => "multidimensional_gauge", labels => [ x => "1", y => "0" ],
            value => 30 },
         { varname => "multidimensional_gauge", labels => [ x => "1", y => "1" ],
            value => 40 },
      ],
      '@samples after adding "three"'
   );
}

done_testing;
