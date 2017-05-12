#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

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

   is_deeply( [ map { HASHfromSample( $_ ) } $histogram->samples ],
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

   is_deeply( [ map { HASHfromSample( $_ ) } $histogram->samples ],
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

   is_deeply( [ map { HASHfromSample( $_ ) } $histogram->samples ],
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

# exceptions
{
   ok( exception {
         Net::Prometheus::Histogram->new(
            name => "test",
            labels => [ "le" ],
            help => "",
         );
      }, 'Histogram with "le" label dies'
   );

   ok( exception {
         Net::Prometheus::Histogram->new(
            name => "test",
            help => "",
            buckets => [ 5, 5 ],
         );
      }, 'Histogram with non-monotonic buckets dies'
   );
}

done_testing;
