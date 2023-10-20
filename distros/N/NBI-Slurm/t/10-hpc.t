use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;
use NBI::Slurm;

# Skip if NBI::Slurm::has_squeue() is false
if (NBI::Slurm::has_squeue() == 0) {
    plan skip_all => "Skipping all tests: not in a slurm cluster";
}

my @queue = NBI::Slurm::queue();
ok(scalar @queue > 0, "queue() returns a list of queues");
done_testing();
