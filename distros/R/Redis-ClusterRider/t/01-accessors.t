use 5.008000;
use strict;
use warnings;

use Test::More tests => 4;
BEGIN {
  require 't/test_helper.pl';
}

my $cluster = new_cluster( refresh_interval => 5 );

can_ok( $cluster, 'refresh_interval' );

t_refresh_interval($cluster);


sub t_refresh_interval {
  my $cluster = shift;

  is( $cluster->refresh_interval, 5, q{get "refresh_interval"} );

  $cluster->refresh_interval(undef);
  is( $cluster->refresh_interval, 15,
    q{reset to default "refresh_interval"} );

  $cluster->refresh_interval(10);
  is( $cluster->refresh_interval, 10, q{set "refresh_interval"} );

  return;
}
