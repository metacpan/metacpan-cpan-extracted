use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use File::Spec;
use NBI::Slurm;

# ---------------------------------------------------------------------------
# HPC-facing tests: CLI bin scripts that require a live SLURM cluster.
# Run manually on the cluster: prove -lv xt/hpc-*.t
# ---------------------------------------------------------------------------

unless (NBI::Slurm::has_squeue()) {
    plan skip_all => 'squeue not found — must be run on a SLURM cluster';
}

# Locate the bin/ directory relative to the repo root (two levels up from xt/)
my $repo_root = File::Spec->catdir($RealBin, File::Spec->updir());
my $bin_dir   = File::Spec->catdir($repo_root, 'bin');

sub bin { File::Spec->catfile($bin_dir, $_[0]) }

# --- lsjobs ----------------------------------------------------------------
{
    my $out = `perl @{[bin('lsjobs')]} 2>&1`;
    my $rc  = $? >> 8;
    ok($rc == 0, 'lsjobs exits 0')
        or diag("lsjobs output: $out");
}

# --- whojobs ---------------------------------------------------------------
{
    my $out = `perl @{[bin('whojobs')]} 2>&1`;
    my $rc  = $? >> 8;
    ok($rc == 0, 'whojobs exits 0')
        or diag("whojobs output: $out");
}

# --- runjob (dry-run / --help) ---------------------------------------------
{
    my $out = `perl @{[bin('runjob')]} --help 2>&1`;
    my $rc  = $? >> 8;
    # --help typically exits 0 or 1 depending on Getopt style; just check output
    like($out, qr/usage|options|runjob/i, 'runjob --help prints usage text');
}

# --- waitjobs (immediate: pattern that matches nothing) -------------------
{
    my $out = `perl @{[bin('waitjobs')]} __no_such_pattern__ 2>&1`;
    my $rc  = $? >> 8;
    ok($rc == 0, 'waitjobs exits 0 when no matching jobs are found')
        or diag("waitjobs output: $out");
}

done_testing();
