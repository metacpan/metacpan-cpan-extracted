#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Net::Prometheus::Summary;

sub HASHfromSample
{
   my ( $sample ) = @_;
   return { map { $_, $sample->$_ } qw( varname labels value ) };
}

{
   my $summary = Net::Prometheus::Summary->new(
      name => "test",
      help => "A testing summary",
   );

   ok( defined $summary, 'defined $summary' );

   is_deeply( [ map { HASHfromSample( $_ ) } $summary->samples ],
      [
         # Slightly fragile as we depend on 'count' coming before 'sum'
         { varname => "test_count", labels => [], value => 0 },
         { varname => "test_sum",   labels => [], value => 0 },
      ],
      '$summary->samples initially'
   );

   $summary->observe( 5 );

   is_deeply( [ map { HASHfromSample( $_ ) } $summary->samples ],
      [
         { varname => "test_count", labels => [], value => 1 },
         { varname => "test_sum",   labels => [], value => 5 },
      ],
      '$summary->samples after ->observe( 5 )'
   );
}

# exceptions
{
   ok( exception {
         Net::Prometheus::Summary->new(
            name => "test",
            labels => [ "quantile" ],
            help => "",
         );
      }, 'Summary with "quantile" label dies'
   );
}

done_testing;
