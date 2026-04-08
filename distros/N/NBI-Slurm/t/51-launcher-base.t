use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Test::More;
use File::Temp qw(tempdir tempfile);

use_ok 'NBI::Launcher';

# ── Helper: build a minimal valid launcher ────────────────────────────────────
sub minimal_launcher {
    return NBI::Launcher->new(
        name        => 'testtool',
        description => 'A test tool',
        version     => '1.0.0',
        activate    => { module => 'testtool/1.0.0' },
        slurm_defaults => { queue => 'short', threads => 4, memory => 8 },
        inputs  => [
            { name => 'r1', flag => '-1', type => 'file', required => 1,
              help => 'Forward reads' },
            { name => 'r2', flag => '-2', type => 'file', required => 0,
              help => 'Reverse reads' },
        ],
        params  => [
            { name => 'db', flag => '--db', type => 'dir', required => 1,
              default => '/default/db', default_env => 'TESTTOOL_DB',
              help => 'Database dir' },
            { name => 'threads', flag => '--threads', slurm_sync => 'threads' },
        ],
        outputs => [
            { name => 'report', pattern => '{sample}.report', required => 1,
              help => 'Report file' },
        ],
        outdir  => { flag => '--outdir', short => '-o', required => 1 },
        scratch => { use_tmpdir => 1, cleanup_on_failure => 1 },
    );
}

my $l = minimal_launcher();
isa_ok($l, 'NBI::Launcher', 'new() returns NBI::Launcher');

# ── Constructor validation ────────────────────────────────────────────────────
eval { NBI::Launcher->new(name => 'x', activate => { module => 'a', conda => 'b' }) };
ok($@, 'new() dies when activate has >1 key');

eval { NBI::Launcher->new(name => 'x', activate => { badkey => 'x' }) };
ok($@, 'new() dies with invalid activate key');

eval { NBI::Launcher->new(activate => { module => 'x' }) };
ok($@, 'new() dies when name missing');

eval { NBI::Launcher->new(name => 'x') };
ok($@, 'new() dies when activate missing');

eval { NBI::Launcher->new(name => 'x', activate => { module => 'x' },
                          slurm_defaults => { bad_key => 1 }) };
ok($@, 'new() dies on unknown slurm_defaults key');

# ── activation_lines() ────────────────────────────────────────────────────────
my $l_mod = NBI::Launcher->new(name => 'x', activate => { module => 'tool/1.0' },
    inputs => [], params => [], outputs => [],
    outdir => { flag => '--outdir', required => 1 });
like($l_mod->activation_lines(), qr/module load tool\/1\.0/, 'module activation correct');

my $l_conda = NBI::Launcher->new(name => 'x', activate => { conda => 'myenv' },
    inputs => [], params => [], outputs => [],
    outdir => { flag => '--outdir', required => 1 });
like($l_conda->activation_lines(), qr/source activate myenv/, 'conda activation correct');

my $l_sing = NBI::Launcher->new(name => 'x', activate => { singularity => '/img.sif' },
    inputs => [], params => [], outputs => [],
    outdir => { flag => '--outdir', required => 1 });
is($l_sing->activation_lines(), '', 'singularity activation_lines returns empty string');
is($l_sing->singularity_prefix(), 'singularity exec /img.sif ', 'singularity_prefix correct');
is($l_mod->singularity_prefix(), '', 'singularity_prefix empty for module activation');

# ── sample_name() ─────────────────────────────────────────────────────────────
is($l->sample_name(r1 => 'sample1_R1.fastq.gz'), 'sample1',  '_R1.fastq.gz stripped');
is($l->sample_name(r1 => 'SRR123_1.fq.gz'),       'SRR123',  '_1.fq.gz stripped');
is($l->sample_name(r1 => 'mysample.fastq'),        'mysample','plain .fastq stripped');
is($l->sample_name(r1 => 'foo_R2.fq.gz'),         'foo',     '_R2.fq.gz stripped');
is($l->sample_name(r1 => '/abs/path/s_R1.fq.gz', sample_name => 'override'),
   'override', 'explicit sample_name overrides derivation');

# ── arg_spec() — slurm_sync params excluded ───────────────────────────────────
my $spec = $l->arg_spec();
my @param_names = map { $_->{name} } @{ $spec->{params} };
ok(!grep { $_ eq 'threads' } @param_names, 'slurm_sync param excluded from arg_spec');
ok(grep { $_ eq 'db' } @param_names, 'user param included in arg_spec');

# ── input_mode() ─────────────────────────────────────────────────────────────
is($l->input_mode(r1 => 'a.fq', r2 => 'b.fq'), 'paired', 'paired when r2 present');
is($l->input_mode(r1 => 'a.fq'),               'single', 'single when r2 absent');

# ── validate() ────────────────────────────────────────────────────────────────
my $tmpdir = tempdir(CLEANUP => 1);
my ($fh, $tmpfile) = tempfile(DIR => $tmpdir, SUFFIX => '.fq.gz');
close $fh;

# Missing required input
eval { $l->validate(outdir => $tmpdir) };
ok($@, 'validate() dies on missing required input r1');
like($@, qr/missing required input '--r1'/, 'validate() error message mentions r1');

# File does not exist
eval { $l->validate(r1 => '/nonexistent/file.fq', outdir => $tmpdir) };
ok($@, 'validate() dies when file not found');

# default_env fills in missing required param
local $ENV{TESTTOOL_DB} = $tmpdir;
eval { $l->validate(r1 => $tmpfile, outdir => $tmpdir) };
ok(!$@, 'validate() passes when default_env fills required param') or diag $@;

# Missing outdir
eval { $l->validate(r1 => $tmpfile) };
ok($@, 'validate() dies when outdir missing');

# ── generate_script() ─────────────────────────────────────────────────────────
{
    # Give make_command a concrete implementation for this test
    no warnings 'redefine';
    local *NBI::Launcher::make_command = sub { return 'echo hello' };

    my $script = $l->generate_script(
        r1           => '/data/s_R1.fq.gz',
        sample       => 'sample1',
        outdir       => $tmpdir,
        threads      => 4,
        db           => $tmpdir,
        manifest_path => "$tmpdir/.nbilaunch/sample1.manifest.json",
    );

    like($script, qr/set -euo pipefail/,          'script has set -euo pipefail');
    like($script, qr/_nbi_manifest_update/,        'script has manifest update function');
    like($script, qr/trap.*ERR/,                   'script has ERR trap');
    like($script, qr/module load testtool\/1\.0\.0/,'script has activation');
    like($script, qr/SAMPLE="sample1"/,            'script sets SAMPLE variable');
    like($script, qr/SCRATCH=\$\(mktemp/,          'script sets SCRATCH via mktemp');
    like($script, qr/trap.*EXIT/,                  'script has EXIT trap for cleanup');
    like($script, qr/echo hello/,                  'script contains tool command');
    like($script, qr/\[\[ ! -s.*\.report/,         'script has required output validation');
    like($script, qr/mv.*SCRATCH.*OUTDIR/,         'script promotes outputs from scratch');
    like($script, qr/success 0/,                   'script records success');
}

done_testing();
