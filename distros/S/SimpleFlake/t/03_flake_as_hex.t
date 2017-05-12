use warnings;
use strict;
use Test::More 0.98;

use SimpleFlake;

my $hex_flake = SimpleFlake->get_flake;

ok( $hex_flake, 'Hex Value ' . $hex_flake . ' was generated for Flake ' );

done_testing;
