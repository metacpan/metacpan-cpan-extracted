use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use NBI::Slurm;

# ---------------------------------------------------------------------------
# HPC-facing tests: job submission via NBI::Job->run().
# Run manually on the cluster: prove -lv xt/hpc-*.t
#
# Submits a trivial 'echo' job and verifies we get a numeric SLURM job ID
# back.  Does NOT wait for the job to finish — see hpc-03-wait.t for that.
# ---------------------------------------------------------------------------

unless (NBI::Slurm::has_squeue()) {
    plan skip_all => 'squeue not found — must be run on a SLURM cluster';
}

my @queues = NBI::Slurm::queues();
unless (@queues) {
    plan skip_all => 'No SLURM partitions found';
}

my $tmpdir = tempdir(CLEANUP => 1);
my $queue  = $queues[0];

diag("Submitting test job to partition '$queue', tmpdir='$tmpdir'");

my $opts = NBI::Opts->new(
    -queue   => $queue,
    -threads => 1,
    -memory  => 100,        # MB
    -time    => '00:02:00',
    -tmpdir  => $tmpdir,
);

my $job = NBI::Job->new(
    -name    => 'nbi-slurm-test-submit',
    -command => 'echo "NBI::Slurm hpc-02 test ok"',
    -opts    => $opts,
);

# Script generation must not die
my $script;
eval { $script = $job->script() };
ok(!$@, 'script() generates without error');
like($script, qr/#SBATCH/, 'script contains #SBATCH directives');
like($script, qr/-p $queue/, "script names partition '$queue'");

# Actually submit
my $job_id;
eval { $job_id = $job->run() };
ok(!$@, "run() did not die: $@");
ok(defined $job_id && $job_id =~ /^\d+$/, "run() returned numeric job ID ($job_id)");

diag("Submitted job ID: $job_id");

done_testing();
