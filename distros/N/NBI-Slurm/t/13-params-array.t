use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

use_ok 'NBI::Job';
use_ok 'NBI::Opts';

my $tmpdir = tempdir(CLEANUP => 1);
my $params_file = File::Spec->catfile($tmpdir, 'params.tsv');
open(my $params_fh, '>', $params_file) or die "Cannot write $params_file: $!";
print {$params_fh} "# comment\r\n";
print {$params_fh} "\r\n";
print {$params_fh} "reads/A_R1.fastq.gz\treads/A_R2.fastq.gz\tresults/A\r\n";
print {$params_fh} "reads/B_R1.fastq.gz\treads/B_R2.fastq.gz\tresults/B\r\n";
close $params_fh;

my $abs_params = abs_path($params_file);
my $opts = NBI::Opts->new(
    -queue => 'default',
    -threads => 1,
    -memory => 12000,
    -time   => '1-00:00:00',
    -tmpdir => '/tmp',
    -params_array => $abs_params,
    -params_rows => 2,
    -placeholder => '#FILE#',
);

ok($opts->is_array(), 'params-array mode is treated as an array job');
ok($opts->is_params_array(), 'params-array mode is detected explicitly');
ok(!$opts->is_files_array(), 'params-array mode does not use file arrays');

my $job = NBI::Job->new(
    -name => 'params-job',
    -command => 'spades.py -1 ##1## -2 ##2## --threads 12 -o ##3##/',
    -opts => $opts,
);

my $script = $job->script();
like($script, qr/#SBATCH --array=0-1/, 'params-array row count becomes the SLURM array span');
like($script, qr/\Qparams_file='$abs_params'\E/, 'script stores the params TSV path');
like($script, qr/mapfile -d '' -t params/, 'script loads the selected TSV row with mapfile');
like($script, qr/\$\{param_1\}/, 'first params placeholder is expanded');
like($script, qr/\$\{param_2\}/, 'second params placeholder is expanded');
like($script, qr/\$\{param_3\}\//, 'third params placeholder is expanded in-place');
unlike($script, qr/##1##/, 'raw params placeholder tokens are removed from the script');
unlike($script, qr/\$\{selected_file\}/, 'file-array variables are not injected in params-array mode');

my $job_without_placeholders = NBI::Job->new(
    -name => 'no-placeholders',
    -command => 'echo hello',
    -opts => $opts,
);
my $ok = eval { $job_without_placeholders->script(); 1 };
ok(!$ok, 'params-array mode rejects commands without numeric placeholders');
like($@, qr/params-array placeholders like ##1##/, 'params-array mode reports the missing numeric placeholder requirement');

my $runjob = abs_path(File::Spec->catfile($RealBin, '..', 'bin', 'runjob'));

{
    local $ENV{HOME} = $tmpdir;
    my $output = qx{$^X "$runjob" --params-array "$params_file" --placeholder "#FILE#" "echo ##1## ##2## ##3##" 2>&1};
    my $exit_code = $? >> 8;
    is($exit_code, 0, 'runjob accepts --params-array input');
    like($output, qr/#SBATCH --array=0-1/, 'CLI output contains the array span for the TSV rows');
    like($output, qr/\$\{param_1\}/, 'CLI output rewrites params placeholders');
    unlike($output, qr/\$\{selected_file\}/, 'CLI output ignores file-array replacement when using --params-array');
}

{
    my $dummy_file = File::Spec->catfile($tmpdir, 'input.txt');
    open(my $fh, '>', $dummy_file) or die "Cannot write $dummy_file: $!";
    print {$fh} "hello\n";
    close $fh;

    local $ENV{HOME} = $tmpdir;
    my $output = qx{$^X "$runjob" --files "$dummy_file" --params-array "$params_file" "echo ##1##" 2>&1};
    my $exit_code = $? >> 8;
    isnt($exit_code, 0, '--files and --params-array cannot be combined');
    like($output, qr/mutually exclusive/, 'CLI reports mutually exclusive array inputs');
}

{
    my $bad_params = File::Spec->catfile($tmpdir, 'bad-params.tsv');
    open(my $fh, '>', $bad_params) or die "Cannot write $bad_params: $!";
    print {$fh} "only-one-column\n";
    close $fh;

    local $ENV{HOME} = $tmpdir;
    my $output = qx{$^X "$runjob" --params-array "$bad_params" "echo ##2##" 2>&1};
    my $exit_code = $? >> 8;
    isnt($exit_code, 0, 'runjob rejects rows with too few columns for the requested placeholders');
    like($output, qr/requires ##2##/, 'CLI reports the missing params-array column requirement');
}

done_testing();
