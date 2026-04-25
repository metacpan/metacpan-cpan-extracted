use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Cwd qw(abs_path);

my $tmpdir = tempdir(CLEANUP => 1);
my $mock_dir = File::Spec->catdir($tmpdir, 'mock_bin');
make_path($mock_dir);

my $sinfo_path = File::Spec->catfile($mock_dir, 'sinfo');
open(my $sinfo_fh, '>', $sinfo_path) or die $!;
print {$sinfo_fh} <<'MOCK';
#!/bin/sh
cat <<'EOF'
alpha|2|idle
alpha|1|mix@
alpha|1|down
beta|1|alloc
beta|2|idle~
EOF
MOCK
close $sinfo_fh;
chmod 0755, $sinfo_path;

my $squeue_path = File::Spec->catfile($mock_dir, 'squeue');
open(my $squeue_fh, '>', $squeue_path) or die $!;
print {$squeue_fh} <<'MOCK';
#!/bin/sh
cat <<'EOF'
alpha|R|1
alpha|PD|2
beta|CG|1
EOF
MOCK
close $squeue_fh;
chmod 0755, $squeue_path;

my $script = abs_path(File::Spec->catfile($RealBin, '..', 'bin', 'slurm-load'));
ok(-e $script, 'slurm-load exists');

my $output;
{
    local $ENV{PATH} = "$mock_dir:$ENV{PATH}";
    $output = qx{$^X "$script" --tab 2>&1};
}
my $exit_code = $? >> 8;

is($exit_code, 0, 'slurm-load exits successfully');
my @lines = grep { /\S/ } split /\n/, $output;
is($lines[0], "Partition\tTotal\tUp\tIdle\tMix\tAlloc\tDown\tJobsR\tJobsPD\tRunNodes\tPendNodes\tLoad", 'header matches expected columns');
is($lines[1], "alpha\t4\t3\t2\t1\t0\t1\t1\t1\t1\t2\t33%", 'alpha workload is summarised correctly');
is($lines[2], "beta\t3\t3\t2\t0\t1\t0\t1\t0\t1\t0\t33%", 'beta workload is summarised correctly');
is($lines[3], "TOTAL\t7\t6\t4\t1\t1\t1\t2\t1\t2\t2\t33%", 'total row is summarised correctly');

my $help_output;
{
    local $ENV{PATH} = "$mock_dir:$ENV{PATH}";
    $help_output = qx{$^X "$script" --help 2>&1};
}
my $help_exit = $? >> 8;
is($help_exit, 0, '--help exits successfully');
like($help_output, qr/slurm-load - Summarise Slurm workload by partition/, 'help text is shown');

done_testing();
