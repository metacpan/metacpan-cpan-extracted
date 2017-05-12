#!./perl

use Test::More tests => 11;
BEGIN { use_ok('Perf::Stopwatch') };

END {is( $loaded, 1, "module not loaded");}

use Perf::Stopwatch qw( :burst );

$loaded = 1;
is( $loaded, 1, "module loaded" );

$burst = new Perf::Stopwatch( type => "burst" );

ok( defined $burst, "");
ok( $burst->isa("Perf::Stopwatch"), "made Stopwatch object");
is( $burst->{type},    2, " is burst Stopwatch");
is( $burst->{laps},  100, " has 100-lap argument");
is( $burst->{final},   0, " has initial final=0");
is( $burst->{c_lap}, 0, " has initial burst=0");

for($i=0; $i<100; $i++){
    $burst->start();
    for($j=0; $j<40; $j++){ $x=1; }
    $burst->stop();
}

$elap = $burst->getTime();
ok( defined $elap, " elapsed time exists");
cmp_ok( $elap, ">", 0, " elapsed time > 0");
