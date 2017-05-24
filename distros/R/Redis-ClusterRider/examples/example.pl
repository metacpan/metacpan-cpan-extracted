#!/usr/bin/env perl

use strict;
use warnings;

use Redis::ClusterRider;
use Time::HiRes;

my $cluster = Redis::ClusterRider->new(
  startup_nodes => [
    'localhost:7000',
    'localhost:7001',
    'localhost:7002',
  ],
  refresh_interval => 5,

  on_node_connect => sub {
    my $hostport = shift;

    print "Connected to $hostport\n";
  },

  on_node_error => sub {
    my $err = shift;
    my $hostport = shift;
    
    warn "$hostport: $err\n";
  }
);

my $num = $cluster->get('__last__') || 0;

while (1) {
  eval {
    $cluster->set( "foo$num", $num );
    print $cluster->get("foo$num") . "\n";
    $cluster->set( '__last__', $num );
  };

  if ($@) {
    warn $@;
  }

  $num++;

  Time::HiRes::usleep 100000;
}
