use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;
use NBI::Slurm;
use File::Basename;
# Try executing the scripts in bin to see if at least they run with --version

for my $bin (glob "$RealBin/../bin/*") {
    my $base = basename($bin);
    ok(-e $bin, "$base exists at $bin");
    ok(-x $bin, "$base is executable");
}


done_testing();