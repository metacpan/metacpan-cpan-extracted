#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Net::Prometheus::ProcessCollector;

# unknown OS
{
   ok( !defined Net::Prometheus::ProcessCollector->for_OS( "unknown" ),
      '->for_OS on unknown OS does not fail' );
}

done_testing;
