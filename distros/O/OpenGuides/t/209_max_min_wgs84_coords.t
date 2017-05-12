use strict;
use OpenGuides::Utils;
use Test::More;

plan tests => 2;

# Simple tests of the max/min/centre lat/long utility.

# One node.
my @nodes = ( { wgs84_lat => 10, wgs84_long => 20 } );
my %data = OpenGuides::Utils->get_wgs84_min_max( nodes => \@nodes );
is_deeply( \%data, { min_lat => 10, max_lat => 10, min_long => 20,
           max_long => 20, centre_lat => 10, centre_long => 20 },
           "get_wgs84_min_max gives correct answers for one node" );

# Two nodes.
@nodes = ( { wgs84_lat => 10, wgs84_long => 20 },
           { wgs84_lat => 18, wgs84_long => 28 } );
%data = OpenGuides::Utils->get_wgs84_min_max( nodes => \@nodes );
is_deeply( \%data, { min_lat => 10, max_lat => 18, min_long => 20,
           max_long => 28, centre_lat => 14, centre_long => 24 },
           "get_wgs84_min_max gives correct answers for two nodes" );
