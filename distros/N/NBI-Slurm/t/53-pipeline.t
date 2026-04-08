use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

use_ok 'NBI::Job';
use_ok 'NBI::Opts';
use_ok 'NBI::Pipeline';

my $tmpdir = tempdir(CLEANUP => 1);

# ── Mock sbatch ───────────────────────────────────────────────────────────────
# Create a fake sbatch that echoes "Submitted batch job N" with incrementing IDs.
my $mock_dir  = "$tmpdir/mock_bin";
my $sbatch_log = "$tmpdir/sbatch_calls.log";
make_path($mock_dir);

open(my $fh, '>', "$mock_dir/sbatch") or die $!;
print $fh <<'MOCK';
#!/bin/sh
# Fake sbatch: reads the script, echoes a job ID, and logs the call.
LOG="SBATCH_LOG"
count=0
[ -f "$LOG" ] && count=$(wc -l < "$LOG")
ID=$((9000 + count + 1))
echo "$*" >> "$LOG"
echo "Submitted batch job $ID"
MOCK
$fh->close if $fh->can('close');
close $fh;
$sbatch_log =~ s|/|\/|g;
open($fh, '+<', "$mock_dir/sbatch") or die $!;
my $content = do { local $/; <$fh> };
$content =~ s/SBATCH_LOG/$sbatch_log/;
seek $fh, 0, 0; truncate $fh, 0;
print $fh $content;
close $fh;
chmod 0755, "$mock_dir/sbatch";

local $ENV{PATH} = "$mock_dir:$ENV{PATH}";

# ── Helper: build a minimal NBI::Job ─────────────────────────────────────────
sub make_job {
    my ($name, $outdir) = @_;
    make_path($outdir);
    my $opts = NBI::Opts->new(
        -queue   => 'short',
        -threads => 2,
        -memory  => '4GB',
        -time    => '1h',
        -tmpdir  => $outdir,
    );
    return NBI::Job->new(
        -name    => $name,
        -command => "echo running $name",
        -opts    => $opts,
    );
}

# ── new() and add_job() ───────────────────────────────────────────────────────
my $j1 = make_job('step1', "$tmpdir/step1");
my $j2 = make_job('step2', "$tmpdir/step2");
my $j3 = make_job('step3', "$tmpdir/step3");

my $p = NBI::Pipeline->new(jobs => [$j1, $j2]);
isa_ok($p, 'NBI::Pipeline', 'new() returns NBI::Pipeline');
is(scalar @{ $p->{jobs} }, 2, 'pipeline has 2 jobs');

$p->add_job($j3);
is(scalar @{ $p->{jobs} }, 3, 'add_job() adds a job');

# Invalid job type
eval { NBI::Pipeline->new(jobs => ['not_a_job']) };
ok($@, 'new() dies when jobs contains non-NBI::Job');

# ── run() without dependencies ────────────────────────────────────────────────
my $pa = NBI::Pipeline->new(jobs => [
    make_job('jobA', "$tmpdir/jobA"),
    make_job('jobB', "$tmpdir/jobB"),
]);

my @ids = $pa->run();
is(scalar @ids, 2, 'run() returns two job IDs');
ok($ids[0] =~ /^\d+$/, 'first ID is numeric');
ok($ids[1] =~ /^\d+$/, 'second ID is numeric');
ok($ids[0] != $ids[1],  'job IDs are distinct');

# ── run() with afterok dependency ─────────────────────────────────────────────
unlink $sbatch_log if -f $sbatch_log;

my $dep1 = make_job('dep1', "$tmpdir/dep1");
my $dep2 = make_job('dep2', "$tmpdir/dep2");
$dep2->{_nbi_depends_on} = $dep1;

my $pb = NBI::Pipeline->new(jobs => [$dep1, $dep2]);
my @dep_ids = $pb->run();

is(scalar @dep_ids, 2, 'dependency pipeline returns two IDs');

# Check that dep2's generated script contains the afterok dependency directive.
# NBI::Job->run() writes the dependency as a #SBATCH directive inside the
# script file (not as a sbatch CLI argument), so we check the script content.
my $first_id  = $dep_ids[0];
my $dep2_script_path = $dep2->script_path;
ok(-f $dep2_script_path, 'dep2 script file exists');
my $dep2_script = do { open my $f, '<', $dep2_script_path or die $!; local $/; <$f> };
like($dep2_script, qr/#SBATCH --dependency=afterok:$first_id/,
     "dep2 script has afterok:$first_id dependency");

# ── print_summary() ───────────────────────────────────────────────────────────
my $jx = make_job('x', "$tmpdir/x");
my $jy = make_job('y', "$tmpdir/y");
$jy->{_nbi_depends_on} = $jx;
my $pc = NBI::Pipeline->new(jobs => [$jx, $jy]);

my $summary = '';
{
    open my $old, '>&', \*STDOUT or die;
    close STDOUT;
    open STDOUT, '>', \$summary or die;
    $pc->print_summary();
    close STDOUT;
    open STDOUT, '>&', $old or die;
}
like($summary, qr/\[x\]/, 'summary contains job x');
like($summary, qr/\[y\]/, 'summary contains job y');
like($summary, qr/afterok:\[x\]/, 'summary shows afterok dependency');

done_testing();
