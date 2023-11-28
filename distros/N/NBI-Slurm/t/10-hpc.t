use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;
use NBI::Slurm;

my $has_queue = NBI::Slurm::has_squeue();

# Skip if NBI::Slurm::has_squeue() is false
if ($has_queue == 0) {
    plan skip_all => "Skipping all tests: not in a slurm cluster";
}

ok($has_queue == 1, "has_squeue() returns a value");

my @queue = NBI::Slurm::queues();
ok(scalar @queue > 0, "queue() returns a list of queues");
done_testing();
