#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;

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

   is( [ map { HASHfromSample( $_ ) } $summary->samples ],
      [
         # Slightly fragile as we depend on 'count' coming before 'sum'
         { varname => "test_count", labels => [], value => 0 },
         { varname => "test_sum",   labels => [], value => 0 },
      ],
      '$summary->samples initially'
   );

   $summary->observe( 5 );

   is( [ map { HASHfromSample( $_ ) } $summary->samples ],
      [
         { varname => "test_count", labels => [], value => 1 },
         { varname => "test_sum",   labels => [], value => 5 },
      ],
      '$summary->samples after ->observe( 5 )'
   );
}

# Remove and clear
{
   my $summary = Net::Prometheus::Summary->new(
      name   => "removal_test",
      help   => "A summary for testing removal",
      labels => [qw( x )],
   );

   $summary->observe( { x => "one" }, 1 );
   $summary->observe( { x => "two" }, 2 );
   $summary->observe( { x => "three" }, 3 );

   is( [ map { $_->varname =~ m/_count/ ? $_->labels : () } $summary->samples ],
      # Grr sorting
      [ [ x => "one" ], [ x => "three" ], [ x => "two" ] ],
      'labels before ->remove' );

   $summary->remove( { x => "one" } );

   is( [ map { $_->varname =~ m/_count/ ? $_->labels : () } $summary->samples ],
      [ [ x => "three" ], [ x => "two" ] ],
      'labels after ->remove' );

   $summary->clear;

   is( [ map { $_->varname =~ m/_count/ ? $_->labels : () } $summary->samples ],
      [],
      'labels after ->clear' );
}

# exceptions
{
   ok( dies {
         Net::Prometheus::Summary->new(
            name => "test",
            labels => [ "quantile" ],
            help => "",
         );
      }, 'Summary with "quantile" label dies'
   );
}

done_testing;
