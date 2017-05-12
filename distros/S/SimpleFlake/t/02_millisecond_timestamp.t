use warnings;
use strict;
use Test::More 0.98;

use SimpleFlake;

my $timestamp = SimpleFlake->get_millisecond_timestamp;

ok( $timestamp, "Timestamp " . $timestamp . " was generated" );

done_testing;
