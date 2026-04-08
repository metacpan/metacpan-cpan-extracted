use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Test::More;
use File::Temp qw(tempdir);
use JSON::PP;

use_ok 'NBI::Manifest';

my $tmpdir = tempdir(CLEANUP => 1);

# ── new() with required fields ────────────────────────────────────────────────
my $m = NBI::Manifest->new(
    tool         => 'kraken2',
    tool_version => '2.1.0',
    sample       => 'sample1',
    outdir       => '/results/kraken2',
    inputs       => { r1 => '/data/s_R1.fq.gz', r2 => '/data/s_R2.fq.gz' },
    params       => { db => '/db/kraken2', threads => 8 },
    outputs      => { report => 'sample1.k2report', output => 'sample1.k2out' },
    slurm_queue  => 'short',
    slurm_cpus   => 8,
    slurm_mem_gb => 32,
);
isa_ok($m, 'NBI::Manifest', 'new() returns NBI::Manifest');
is($m->{tool},         'kraken2',          'tool stored');
is($m->{sample},       'sample1',          'sample stored');
is($m->{slurm_cpus},   8,                  'slurm_cpus stored');
is($m->{status},       'submitted',        'default status is submitted');
ok(!defined $m->{completed_at},            'completed_at starts undef');
ok(!defined $m->{slurm_job_id},            'slurm_job_id starts undef');

# ── write() + load() round-trip ───────────────────────────────────────────────
my $path = "$tmpdir/sample1.manifest.json";
$m->write($path);
ok(-f $path, 'write() creates file');

my $raw = do { open my $fh, '<', $path or die $!; local $/; <$fh> };
my $decoded = eval { JSON::PP->new->utf8->decode($raw) };
ok(!$@, 'written file is valid JSON');
is($decoded->{tool},   'kraken2', 'JSON tool field correct');
is($decoded->{sample}, 'sample1', 'JSON sample field correct');
ok(!exists $decoded->{_path},     '_path is not serialised');

my $m2 = NBI::Manifest->load($path);
isa_ok($m2, 'NBI::Manifest', 'load() returns NBI::Manifest');
is($m2->{tool},         'kraken2', 'loaded tool correct');
is($m2->{sample},       'sample1', 'loaded sample correct');
is($m2->{slurm_mem_gb}, 32,        'loaded slurm_mem_gb correct');
is($m2->{_path},        $path,     '_path set after load()');

# ── output($name) ─────────────────────────────────────────────────────────────
my $report_path = $m2->output('report');
is($report_path, '/results/kraken2/sample1.k2report', 'output() returns absolute path');

eval { $m2->output('nonexistent') };
ok($@, 'output() dies on unknown name');

# ── update() patches and rewrites ─────────────────────────────────────────────
$m->update(slurm_job_id => 4821934, status => 'submitted');
my $m3 = NBI::Manifest->load($path);
is($m3->{slurm_job_id}, 4821934,    'update() persists slurm_job_id');
is($m3->{status},       'submitted','update() persists status');

$m->update(status => 'success', exit_code => 0, completed_at => '2026-03-21T12:00:00Z');
my $m4 = NBI::Manifest->load($path);
is($m4->{status},       'success',              'updated status is success');
is($m4->{exit_code},    0,                      'updated exit_code is 0');
is($m4->{completed_at}, '2026-03-21T12:00:00Z', 'updated completed_at correct');

# ── missing required fields ───────────────────────────────────────────────────
eval { NBI::Manifest->new(tool => 'x', sample => 'y') };
ok($@, 'new() dies when outdir missing');

eval { NBI::Manifest->new(tool => 'x', outdir => '/out') };
ok($@, 'new() dies when sample missing');

# ── update() without prior write() ───────────────────────────────────────────
my $m5 = NBI::Manifest->new(tool => 'x', sample => 's', outdir => '/o');
eval { $m5->update(status => 'success') };
ok($@, 'update() without write() dies');

done_testing();
