#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Net::Prometheus::Metric;

{
   is( Net::Prometheus::Metric->new(
         name => "basename",
         help => "",
      )->fullname,
      "basename",
      'fullname for name only'
   );

   is( Net::Prometheus::Metric->new(
         subsystem => "subsys",
         name => "basename",
         help => "",
      )->fullname,
      "subsys_basename",
      'fullname for subsystem+name'
   );

   is( Net::Prometheus::Metric->new(
         namespace => "namesp",
         name => "basename",
         help => "",
      )->fullname,
      "namesp_basename",
      'fullname for namespace+name'
   );

   is( Net::Prometheus::Metric->new(
         namespace => "namesp",
         subsystem => "subsys",
         name => "basename",
         help => "",
      )->fullname,
      "namesp_subsys_basename",
      'fullname for namespace+subsystem+name'
   );
}

# samples
{
   my $metric = Net::Prometheus::Metric->new(
      name => "basename",
      help => "",
   );

   my $sample = $metric->make_sample( undef, "", 123 );

   is( $sample->varname, "basename", '$sample->varname' );
   is_deeply( $sample->labels, [],   '$sample->labels' );
   is( $sample->value, 123,          '$sample->value' );

   is( $metric->make_sample( "suffix", "", 456 )->varname,
       "basename_suffix",
       '$sample->varname with suffix',
    );
}

# exceptions
{
   ok( exception {
         Net::Prometheus::Metric->new(
            name => "with_no_help",
         )
      }, 'Metric without help dies'
   );

   ok( exception {
         Net::Prometheus::Metric->new(
            help => "This metric lacks a name",
         )
      }, 'Metric without name dies'
   );

   ok( exception {
         Net::Prometheus::Metric->new(
            name => "hello/world",
            help => "",
         )
      }, 'Invalid metric name dies'
   );
}

done_testing;
