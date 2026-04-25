use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Cwd qw(abs_path);

use_ok 'NBI::Job';
use_ok 'NBI::Opts';

my $tmpdir = tempdir(CLEANUP => 1);
my $params_file = File::Spec->catfile($tmpdir, 'params.tsv');
open(my $params_fh, '>', $params_file) or die "Cannot write $params_file: $!";
for my $i (1 .. 7) {
    print {$params_fh} "sample_$i\n";
}
close $params_fh;
my $abs_params = abs_path($params_file);

my $opts = NBI::Opts->new(
    -queue => 'short',
    -threads => 1,
    -memory => '1GB',
    -time => '1h',
    -tmpdir => $tmpdir,
    -params_array => $abs_params,
    -params_rows => 7,
    -array_offset => 3,
    -array_tasks => 3,
);
my $job = NBI::Job->new(
    -name => 'chunked-params',
    -command => 'echo ##1##',
    -opts => $opts,
);
my $script = $job->script();
like($script, qr/#SBATCH --array=0-2/, 'chunked params-array emits a local chunk-sized array range');
like($script, qr/nbi_array_index=\$\(\(SLURM_ARRAY_TASK_ID \+ 3\)\)/, 'chunked params-array offsets the global row index');
like($script, qr/perl -e .*"\$nbi_array_index"/, 'params loader reads the global row index rather than the local array task id');

my $mock_dir = File::Spec->catdir($tmpdir, 'mock_bin');
make_path($mock_dir);
my $sbatch_log = File::Spec->catfile($tmpdir, 'sbatch_calls.log');
open(my $sbatch_fh, '>', File::Spec->catfile($mock_dir, 'sbatch')) or die $!;
print {$sbatch_fh} <<'MOCK';
#!/bin/sh
LOG="SBATCH_LOG"
count=0
[ -f "$LOG" ] && count=$(wc -l < "$LOG")
ID=$((9000 + count + 1))
echo "$1" >> "$LOG"
echo "Submitted batch job $ID"
MOCK
close $sbatch_fh;

my $sbatch_path = File::Spec->catfile($mock_dir, 'sbatch');
open($sbatch_fh, '+<', $sbatch_path) or die $!;
my $mock = do { local $/; <$sbatch_fh> };
$mock =~ s/SBATCH_LOG/$sbatch_log/;
seek $sbatch_fh, 0, 0;
truncate $sbatch_fh, 0;
print {$sbatch_fh} $mock;
close $sbatch_fh;
chmod 0755, $sbatch_path;

my $runjob = abs_path(File::Spec->catfile($RealBin, '..', 'bin', 'runjob'));
my $output;
{
    local $ENV{PATH} = "$mock_dir:$ENV{PATH}";
    local $ENV{HOME} = $tmpdir;
    local $ENV{SKIP_SLURM_CHECK} = 1;
    local $ENV{NBI_MAX_ARRAY_SIZE} = 3;
    $output = qx{$^X "$runjob" --name split-array --queue short --tmpdir "$tmpdir" --no-eco --params-array "$params_file" --run "echo ##1##" 2>&1};
}

my $exit_code = $? >> 8;
is($exit_code, 0, 'runjob succeeds when splitting an oversized params-array job');
like($output, qr/\[array\] Splitting 7 tasks into 3 jobs/, 'runjob reports array chunking');
like($output, qr/^9001$/m, 'first chunk job id is printed');
like($output, qr/^9002$/m, 'second chunk job id is printed');
like($output, qr/^9003$/m, 'third chunk job id is printed');

open(my $log_fh, '<', $sbatch_log) or die "Cannot read $sbatch_log: $!";
my @submitted_scripts = <$log_fh>;
close $log_fh;
is(scalar @submitted_scripts, 3, 'runjob submitted three chunked array jobs');

my $script1 = do { open my $fh, '<', File::Spec->catfile($tmpdir, 'split-array.part1.sh') or die $!; local $/; <$fh> };
my $script2 = do { open my $fh, '<', File::Spec->catfile($tmpdir, 'split-array.part2.sh') or die $!; local $/; <$fh> };
my $script3 = do { open my $fh, '<', File::Spec->catfile($tmpdir, 'split-array.part3.sh') or die $!; local $/; <$fh> };

like($script1, qr/#SBATCH --array=0-2/, 'first chunk uses the expected local array span');
unlike($script1, qr/SLURM_ARRAY_TASK_ID \+ 3/, 'first chunk does not offset the first range');
like($script2, qr/#SBATCH --array=0-2/, 'second chunk also uses the local array span');
like($script2, qr/SLURM_ARRAY_TASK_ID \+ 3/, 'second chunk offsets into the original TSV');
like($script3, qr/#SBATCH --array=0-0/, 'final chunk shrinks to the remaining single task');
like($script3, qr/SLURM_ARRAY_TASK_ID \+ 6/, 'final chunk points at the last original TSV row');

done_testing();
