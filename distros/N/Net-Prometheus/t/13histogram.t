#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;

use Net::Prometheus::Histogram;

sub HASHfromSample
{
   my ( $sample ) = @_;
   return { map { $_, $sample->$_ } qw( varname labels value ) };
}

{
   my $histogram = Net::Prometheus::Histogram->new(
      name => "test",
      help => "A testing histogram",
      buckets => [ 1, 2, 5 ],
   );

   ok( defined $histogram, 'defined $histogram' );

   is( [ $histogram->bucket_bounds ],
      [ 1, 2, 5 ],
      '$histogram->bucket_bounds'
   );

   is( [ map { HASHfromSample( $_ ) } $histogram->samples ],
      [
         # Slightly fragile as we depend on 'count' coming before 'sum'
         { varname => "test_count", labels => [], value => 0 },
         { varname => "test_sum",   labels => [], value => 0 },
         { varname => "test_bucket", labels => [ le => 1 ], value => 0 },
         { varname => "test_bucket", labels => [ le => 2 ], value => 0 },
         { varname => "test_bucket", labels => [ le => 5 ], value => 0 },
         { varname => "test_bucket", labels => [ le => "+Inf" ], value => 0 },
      ],
      '$histogram->samples initially'
   );

   $histogram->observe( 5 );

   is( [ map { HASHfromSample( $_ ) } $histogram->samples ],
      [
         { varname => "test_count", labels => [], value => 1 },
         { varname => "test_sum",   labels => [], value => 5 },
         { varname => "test_bucket", labels => [ le => 1 ], value => 0 },
         { varname => "test_bucket", labels => [ le => 2 ], value => 0 },
         { varname => "test_bucket", labels => [ le => 5 ], value => 1 },
         { varname => "test_bucket", labels => [ le => "+Inf" ], value => 1 },
      ],
      '$histogram->samples after ->observe( 5 )'
   );

   $histogram->observe( 1.5 );

   is( [ map { HASHfromSample( $_ ) } $histogram->samples ],
      [
         { varname => "test_count", labels => [], value => 2 },
         { varname => "test_sum",   labels => [], value => 6.5 },
         { varname => "test_bucket", labels => [ le => 1 ], value => 0 },
         { varname => "test_bucket", labels => [ le => 2 ], value => 1 },
         { varname => "test_bucket", labels => [ le => 5 ], value => 2 },
         { varname => "test_bucket", labels => [ le => "+Inf" ], value => 2 },
      ],
      '$histogram->samples after ->observe( 1.5 )'
   );
}

# Remove and clear
{
   my $histogram = Net::Prometheus::Histogram->new(
      name   => "removal_test",
      help   => "A histogram for testing removal",
      labels => [qw( x )],
   );

   $histogram->observe( { x => "one" }, 1 );
   $histogram->observe( { x => "two" }, 2 );
   $histogram->observe( { x => "three" }, 3 );

   is( [ map { $_->varname =~ m/_count/ ? $_->labels : () } $histogram->samples ],
      # Grr sorting
      [ [ x => "one" ], [ x => "three" ], [ x => "two" ] ],
      'labels before ->remove' );

   $histogram->remove( { x => "one" } );

   is( [ map { $_->varname =~ m/_count/ ? $_->labels : () } $histogram->samples ],
      [ [ x => "three" ], [ x => "two" ] ],
      'labels after ->remove' );

   $histogram->clear;

   is( [ map { $_->varname =~ m/_count/ ? $_->labels : () } $histogram->samples ],
      [],
      'labels after ->clear' );
}

# exceptions
{
   ok( dies {
         Net::Prometheus::Histogram->new(
            name => "test",
            labels => [ "le" ],
            help => "",
         );
      }, 'Histogram with "le" label dies'
   );

   ok( dies {
         Net::Prometheus::Histogram->new(
            name => "test",
            help => "",
            buckets => [ 5, 5 ],
         );
      }, 'Histogram with non-monotonic buckets dies'
   );
}

# Decade buckets
{
   my $hist;

   # Large
   $hist = Net::Prometheus::Histogram->new(
      name => "large",
      help => "A large value",
      bucket_min => 1, bucket_max => 1E6
   );

   is( [ $hist->bucket_bounds ],
      [ 1E0, 1E1, 1E2, 1E3, 1E4, 1E5, 1E6 ],
      'buckets for 1 to 1E6' );

   # Small
   $hist = Net::Prometheus::Histogram->new(
      name => "small",
      help => "A small value",
      bucket_min => 1E-6, bucket_max => 1,
   );

   is( [ $hist->bucket_bounds ],
      [ 1E-6, 1E-5, 1E-4, 1E-3, 1E-2, 1E-1, 1E0 ],
      'buckets for 1E-6 to 1' );
}

# Custom buckets
{
   # Generate E6 values
   my $hist = Net::Prometheus::Histogram->new(
      name => "E6",
      help => "Engineering E6 series",
      bucket_min => 1,
      buckets_per_decade => [ 1, 1.5, 2.2, 3.3, 4.7, 6.8 ],
   );

   is( [ $hist->bucket_bounds ],
      [  1.0, 1.5, 2.2, 3.3, 4.7, 6.8,
          10,  15,  22,  33,  47,  68,
         100, 150, 220, 330, 470, 680,
        1000 ],
     'buckets for custom values per decade' );
}

done_testing;
