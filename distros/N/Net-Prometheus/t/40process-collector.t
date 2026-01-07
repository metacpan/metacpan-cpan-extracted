#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;

use Net::Prometheus::ProcessCollector;

# unknown OS
{
   ok( !defined Net::Prometheus::ProcessCollector->for_OS( "unknown" ),
      '->for_OS on unknown OS does not fail' );
}

done_testing;
