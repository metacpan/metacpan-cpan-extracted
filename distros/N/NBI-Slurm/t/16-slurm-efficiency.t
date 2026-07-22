use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Cwd qw(abs_path);
use NBI::Slurm;
# Skip on Windows (scripts not supported there, matches the rest of the suite)
if ($^O eq 'MSWin32') {
    plan skip_all => "Skipping: scripts not supported on Windows";
}

# Skip if NBI::Slurm::has_squeue() is false (must be declared before any ok())
if (NBI::Slurm::has_squeue() == 0) {
    plan skip_all => "Skipping all tests: not in a slurm cluster";
}

my $script = abs_path(File::Spec->catfile($RealBin, '..', 'bin', 'slurm-efficiency'));
ok(-e $script, 'slurm-efficiency exists');
ok(-x $script, 'slurm-efficiency is executable');

# --------------------------------------------------------------------------- --version / --help
{
    my $out  = qx{$^X "$script" --version 2>&1};
    my $code = $? >> 8;
    is($code, 0, '--version exits 0');
    like($out, qr/slurm-efficiency/, '--version mentions the program name');
}
{
    my $out  = qx{$^X "$script" --help 2>&1};
    my $code = $? >> 8;
    is($code, 0, '--help exits 0');
    like($out, qr/Requested-vs-used time & memory/, '--help shows description');
}

# --------------------------------------------------------------------------- mock sacct (normal)
{
    my $tmpdir   = tempdir(CLEANUP => 1);
    my $mock_dir = File::Spec->catdir($tmpdir, 'mock_bin');
    make_path($mock_dir);

    my $sacct = File::Spec->catfile($mock_dir, 'sacct');
    open(my $fh, '>', $sacct) or die $!;
    # Emits parsable2/noheader rows regardless of args.
    # Fields: JobID|JobName|State|Elapsed|Timelimit|ReqMem|MaxRSS|AllocCPUS|NNodes
    print {$fh} <<'MOCK';
#!/bin/sh
cat <<'EOF'
1001|good_job|COMPLETED|01:00:00|02:00:00|4Gn||1|1
1001.batch|batch|COMPLETED|01:00:00||4Gn|2.00G|1|1
1002|bad_job|FAILED|00:10:00|01:00:00|2Gc||2|1
1002.batch|batch|FAILED|00:10:00||2Gc|512M|2|1
1003|live_job|RUNNING|00:05:00|10:00:00|1Gn||1|1
EOF
MOCK
    close $fh;
    chmod 0755, $sacct;

    my $out;
    {
        local $ENV{PATH} = "$mock_dir:$ENV{PATH}";
        $out = qx{$^X "$script" --days 7 --csv 2>&1};
    }
    my $code = $? >> 8;
    is($code, 0, 'runs successfully against mock sacct');

    my @lines = grep { /\S/ } split /\n/, $out;
    is($lines[0],
       "ID,Name,State,Actual_Duration,Perc_Allocated_Duration,MaxMemory,Perc_Allocated_Memory",
       'CSV header matches');

    # Rows sorted by id; RUNNING job dropped -> exactly 2 data rows
    is(scalar(@lines), 3, 'RUNNING job is dropped; two finished jobs reported');

    is($lines[1], "1001,good_job,COMPLETED,01:00:00,50.0,2.00G,50.0",
       'COMPLETED job: 50% time, 50% memory (4Gn per-node)');
    is($lines[2], "1002,bad_job,FAILED,00:10:00,16.7,512M,12.5",
       'FAILED job: per-CPU memory scaled by AllocCPUS (2Gc * 2 = 4G)');
}

# --------------------------------------------------------------------------- coloured table
{
    my $tmpdir   = tempdir(CLEANUP => 1);
    my $mock_dir = File::Spec->catdir($tmpdir, 'mock_bin');
    make_path($mock_dir);
    my $sacct = File::Spec->catfile($mock_dir, 'sacct');
    open(my $fh, '>', $sacct) or die $!;
    print {$fh} <<'MOCK';
#!/bin/sh
cat <<'EOF'
2001|c_job|COMPLETED|01:00:00|02:00:00|1Gn||1|1
2001.batch|batch|COMPLETED|01:00:00||1Gn|256M|1|1
EOF
MOCK
    close $fh;
    chmod 0755, $sacct;

    my $out;
    {
        local $ENV{PATH} = "$mock_dir:$ENV{PATH}";
        # Force colours on even though STDOUT is a pipe in tests.
        local $ENV{ANSI_COLORS_DISABLED};
        delete $ENV{ANSI_COLORS_DISABLED};
        $out = qx{$^X "$script" 2>&1};
    }
    my $code = $? >> 8;
    is($code, 0, 'coloured table runs successfully');
    like($out, qr/COMPLETED/, 'table shows the COMPLETED state');
    like($out, qr/\bID\b.*\bState\b.*%Mem/, 'table header present');
}

# --------------------------------------------------------------------------- "too wide" date range
{
    my $tmpdir   = tempdir(CLEANUP => 1);
    my $mock_dir = File::Spec->catdir($tmpdir, 'mock_bin');
    make_path($mock_dir);
    my $sacct = File::Spec->catfile($mock_dir, 'sacct');
    open(my $fh, '>', $sacct) or die $!;
    print {$fh} <<'MOCK';
#!/bin/sh
echo "sacct: error: Too wide of a date range in query" >&2
exit 1
MOCK
    close $fh;
    chmod 0755, $sacct;

    my $out;
    {
        local $ENV{PATH} = "$mock_dir:$ENV{PATH}";
        $out = qx{$^X "$script" --days 999 2>&1};
    }
    my $code = $? >> 8;
    isnt($code, 0, 'too-wide date range exits non-zero');
    like($out, qr/too wide/i, 'too-wide error is captured and reported');
    like($out, qr/--days/, 'hint to reduce --days is shown');
}

# --------------------------------------------------------------------------- sacct missing
{
    my $tmpdir   = tempdir(CLEANUP => 1);
    my $mock_dir = File::Spec->catdir($tmpdir, 'empty_bin');
    make_path($mock_dir);

    my $out;
    {
        # Minimal PATH without sacct, but keep the perl interpreter reachable.
        local $ENV{PATH} = $mock_dir;
        $out = qx{$^X "$script" 2>&1};
    }
    my $code = $? >> 8;
    isnt($code, 0, 'missing sacct exits non-zero');
    like($out, qr/sacct.*not found/i, 'missing sacct is reported clearly');
}

# --------------------------------------------------------------------------- real cluster smoke test
SKIP: {
    my $have_sacct = do {
        my $p = `command -v sacct 2>/dev/null`;
        ($? == 0 && $p =~ /\S/) ? 1 : 0;
    };
    skip "not on a Slurm cluster (sacct not found)", 1 unless $have_sacct;

    my $out  = qx{$^X "$script" --days 1 2>&1};
    my $code = $? >> 8;
    ok($code == 0, 'real sacct query runs (last 1 day)')
        or diag("slurm-efficiency output:\n$out");
}

done_testing();
