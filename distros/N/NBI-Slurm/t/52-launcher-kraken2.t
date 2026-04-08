use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Test::More;
use File::Temp qw(tempdir tempfile);

use_ok 'NBI::Launcher::Kraken2';
use_ok 'NBI::Job';
use_ok 'NBI::Opts';

my $k = NBI::Launcher::Kraken2->new();
isa_ok($k, 'NBI::Launcher',         'Kraken2 isa NBI::Launcher');
isa_ok($k, 'NBI::Launcher::Kraken2','Kraken2 isa NBI::Launcher::Kraken2');
is($k->{name},    'kraken2', 'name is kraken2');
is($k->{version}, '2.0.8',   'version is 2.0.8');

# ── make_command() — paired-end ───────────────────────────────────────────────
my $cmd_pe = $k->make_command(
    r1         => '/data/s_R1.fq.gz',
    r2         => '/data/s_R2.fq.gz',
    db         => '/db/kraken2',
    confidence => 0.0,
    threads    => 8,
    sample     => 'sample1',
);
like($cmd_pe, qr/kraken2/,                  'paired cmd starts with kraken2');
like($cmd_pe, qr/--paired/,                 'paired cmd has --paired');
like($cmd_pe, qr/-1 "?\/data\/s_R1\.fq\.gz"?/, 'paired cmd has -1 with r1');
like($cmd_pe, qr/-2 "?\/data\/s_R2\.fq\.gz"?/, 'paired cmd has -2 with r2');
like($cmd_pe, qr/--threads 8/,              'paired cmd has threads');
like($cmd_pe, qr/--db "?\/db\/kraken2"?/,   'paired cmd has db');
like($cmd_pe, qr/--confidence 0/,           'paired cmd has confidence');
like($cmd_pe, qr/\$SCRATCH\/sample1\.k2report/, 'output uses $SCRATCH');

# ── make_command() — single-end ───────────────────────────────────────────────
my $cmd_se = $k->make_command(
    r1         => '/data/s.fq.gz',
    db         => '/db/kraken2',
    confidence => 0.5,
    threads    => 4,
    sample     => 'mysample',
);
unlike($cmd_se, qr/--paired/, 'single-end cmd has no --paired');
like($cmd_se,   qr/--confidence 0\.5/, 'single-end confidence 0.5');

# ── arg_spec() — threads not exposed ─────────────────────────────────────────
my $spec = $k->arg_spec();
my @pnames = map { $_->{name} } @{ $spec->{params} };
ok(!grep { $_ eq 'threads' } @pnames, 'threads excluded from arg_spec (slurm_sync)');
ok(grep  { $_ eq 'db' } @pnames,       'db included in arg_spec');

# ── default_env for db ────────────────────────────────────────────────────────
my $tmpdir = tempdir(CLEANUP => 1);
my ($fh, $r1_file) = tempfile(DIR => $tmpdir, SUFFIX => '_R1.fq.gz');
close $fh;
my ($fh2, $db_dir) = (undef, $tmpdir);   # use tmpdir as fake db dir

local $ENV{KRAKEN2_DB} = $db_dir;
eval { $k->validate(r1 => $r1_file, outdir => $tmpdir) };
ok(!$@, 'validate() passes when KRAKEN2_DB fills in db') or diag $@;

# Without env var and without default (remove default temporarily)
delete $ENV{KRAKEN2_DB};
# Validate without db — should fail because required and no default_env
eval { $k->validate(r1 => $r1_file, outdir => $tmpdir) };
# Note: the hardcoded default '/qib/databases/kraken2/standard' won't exist in test,
# but validate only checks existence for 'dir' type when value IS provided.
# With default set, validate will use the default — dir won't exist so it'll die.
ok($@, 'validate() dies when db dir does not exist');

# ── build() returns NBI::Job + NBI::Manifest ──────────────────────────────────
my ($fh3, $r1) = tempfile(DIR => $tmpdir, SUFFIX => '_R1.fq.gz');
close $fh3;
my $outdir = "$tmpdir/results";

# Provide a real db dir (tmpdir) so validate passes, override default
local $ENV{KRAKEN2_DB} = $tmpdir;

my ($job, $manifest) = eval {
    $k->build(
        r1           => $r1,
        outdir       => $outdir,
        slurm_queue  => 'test',
        slurm_threads => 4,
        slurm_memory  => 8,
    );
};
ok(!$@, 'build() does not die') or diag $@;
isa_ok($job,      'NBI::Job',      'build() returns NBI::Job');
isa_ok($manifest, 'NBI::Manifest', 'build() returns NBI::Manifest');

# Script contains expected SBATCH directives
my $script = $job->script();
like($script, qr/#SBATCH -p test/,  'script has correct queue');
like($script, qr/#SBATCH -c 4/,     'script has correct cpus');
like($script, qr/module load kraken2\/2\.0\.8/, 'script has module activation');
like($script, qr/SCRATCH=\$\(mktemp/, 'script sets up scratch');

# slurm_sync: threads in make_command comes from slurm_threads
like($script, qr/--threads 4/, 'slurm_sync wired: threads=4 in command');

# Manifest fields
is($manifest->{tool},       'kraken2', 'manifest tool');
is($manifest->{slurm_cpus}, 4,         'manifest slurm_cpus');
is($manifest->{slurm_queue},'test',    'manifest slurm_queue');

done_testing();
