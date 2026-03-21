use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use NBI::Slurm;

# ---------------------------------------------------------------------------
# HPC-facing tests: submit a short job and wait for it to complete.
# Run manually on the cluster: prove -lv xt/hpc-*.t
#
# Polls squeue every 5 s for up to 2 min.  The job just runs "sleep 10"
# so it should complete well within that window.
#
# NOTE: tmpdir must be on a shared filesystem visible to all nodes (e.g.
# $HOME or a project scratch area).  Local /tmp on the login node is NOT
# visible on compute nodes, so SLURM output files would never appear there.
# ---------------------------------------------------------------------------

unless (NBI::Slurm::has_squeue()) {
    plan skip_all => 'squeue not found — must be run on a SLURM cluster';
}

my @queues = NBI::Slurm::queues();
unless (@queues) {
    plan skip_all => 'No SLURM partitions found';
}

# Use $HOME so the directory is on shared NFS and visible from compute nodes.
my $tmpdir = tempdir('nbi-slurm-test-XXXXXX', DIR => $ENV{HOME}, CLEANUP => 1);
my $queue  = $queues[0];

my $opts = NBI::Opts->new(
    -queue   => $queue,
    -threads => 1,
    -memory  => 100,
    -time    => '00:05:00',
    -tmpdir  => $tmpdir,
);

my $job = NBI::Job->new(
    -name    => 'nbi-slurm-test-wait',
    -command => 'sleep 10 && echo "done"',
    -opts    => $opts,
);

my $job_id;
eval { $job_id = $job->run() };
ok(!$@,                                         'job submitted without error');
ok($job_id && $job_id =~ /^\d+$/,               "got numeric job ID ($job_id)");

SKIP: {
    skip 'No job ID — cannot poll', 2 unless $job_id && $job_id =~ /^\d+$/;

    diag("Waiting for job $job_id to leave the queue (max 120 s) ...");
    my $deadline = time() + 120;
    my $found    = 1;
    while (time() < $deadline) {
        my $out = `squeue -j $job_id --noheader 2>/dev/null`;
        if ($out eq '') {
            $found = 0;   # job no longer in queue
            last;
        }
        sleep 5;
    }
    ok(!$found, "job $job_id left the queue within 120 s");

    # Verify the output file was written (NBI::Job sets outputfile to tmpdir/<name>-<id>.out)
    my @out_files = glob("$tmpdir/*.out");
    ok(scalar @out_files > 0, 'at least one .out file written to tmpdir')
        or diag("tmpdir contents: " . join(', ', glob("$tmpdir/*")));
}

done_testing();
