use strict;
use warnings;
use Test::More;
use NBI::Slurm;

# ---------------------------------------------------------------------------
# HPC-facing tests: cluster connectivity and partition discovery.
# Run manually on the cluster: prove -lv xt/hpc-*.t
# ---------------------------------------------------------------------------

unless (NBI::Slurm::has_squeue()) {
    plan skip_all => 'squeue not found — must be run on a SLURM cluster';
}

# squeue/sinfo are present
ok(NBI::Slurm::has_squeue(), 'squeue binary is available');

# At least one partition is returned
my @queues = NBI::Slurm::queues();
ok(scalar @queues > 0, 'sinfo returns at least one partition');
diag('Available partitions: ' . join(', ', @queues));

# valid_queue() accepts the first real partition
my $first = $queues[0];
ok(NBI::Slurm::valid_queue($first), "valid_queue('$first') is true");

# valid_queue() rejects a nonsense name
ok(!NBI::Slurm::valid_queue('__no_such_queue__'), 'valid_queue rejects unknown partition');

done_testing();
