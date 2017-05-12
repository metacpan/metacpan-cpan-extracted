use strict;
use warnings;

use SimpleFlake;
use Test::More;
use Benchmark;

my $t0 = Benchmark->new;

my $i = 100_000;

my $collisions = {};

for( 1 .. $i) {

    my $hex_flake = SimpleFlake->get_flake;
    $collisions->{$hex_flake}++;

    fail( 'collision detected by run number ' . $_ .  ' for hex_flake: ' . $hex_flake ) if $collisions->{$hex_flake} > 1;
#    print $hex_flake."\n";
}




my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);

ok( $td, "needed " . timestr($td) . ' for ' . $i . ' executions' );

done_testing;
