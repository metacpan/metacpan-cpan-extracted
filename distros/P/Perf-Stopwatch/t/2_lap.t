#!./perl

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 18;
BEGIN { use_ok('Perf::Stopwatch') };

END {is( $loaded, 1, "module loaded");}

use Perf::Stopwatch qw( :lap );

$loaded = 1;
is( $loaded, 1, "module loaded" );

$iter = 200;
$lap = new Perf::Stopwatch( type => "lap", laps => $iter );

ok( defined $lap, "");
ok( $lap->isa("Perf::Stopwatch"), "made Stopwatch object");
is( $lap->{type},     1, " is lap Stopwatch");
is( $lap->{laps}, $iter, " has ${iter}-lap argument");
is( $lap->{final},    0, " has initial final=0");
is( $lap->{c_lap},    0, " has initial lap=0");

$lap->start();
for($i=0; $i<$iter; $i++){
    for($j=0; $j<($iter/10); $j++){ $x=1; }
    $lap->lap();
}

$elap = $lap->getTime();
$lmin = $lap->getMinLap();
$lmax = $lap->getMaxLap();
$laps = $lap->getLaps();

ok( defined $elap, " elapsed time exists");
ok( defined $lmin, " min-lap found");
ok( defined $lmax, " max-lap found");
ok( defined $laps, " lap-array found");
cmp_ok( $elap, ">", 0, " elapsed time > 0");
cmp_ok( $lmin, ">", 0, " minimum > 0");
cmp_ok( $lmax, ">", 0, " maximum > 0");
ok( ref($laps), " laps in a reference");
cmp_ok( ref($laps), "eq", "ARRAY", "laps in an ARRAY refernce");
