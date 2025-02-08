
use 5.012;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use Term::ANSIColor qw(:constants);
use File::Spec::Functions; 
use lib $RealBin;
use TestFu;
#TODO
ok(1, "TODO: test the binaries");

my ($test, $out, $err) = run_bin("n50", ("--version"));


$out = $out =~/FASTX N50/ ? substr($out, 0, 40) . '...' : $out;
$err = $err eq "" ? "OK" : $err;
say STDERR "\nSTDOUT=$out", RESET;
say STDERR "STDERR=$err", RESET;
say STDERR "TEST=($test)", RESET;


done_testing();