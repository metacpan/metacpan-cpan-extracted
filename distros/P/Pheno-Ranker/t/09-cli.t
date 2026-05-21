#!/usr/bin/env perl
use strict;
use warnings;
use lib qw(./lib ../lib t/lib);

use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Test::More;
use Test::PhenoRanker qw(fixture);

use Pheno::Ranker::CLI;

my $cli = Pheno::Ranker::CLI->new( pod_file => catfile( 'bin', 'pheno-ranker' ) );

subtest 'parse_args translates CLI options into Ranker constructor arguments' => sub {
    my $args = $cli->parse_args(
        '-r', fixture('individuals.json'),
        '--matrix-format', 'mtx',
        '--cytoscape-json',
        '--graph-max-weight', '10',
        '--max-matrix-records-in-ram', '42',
        '-v',
    );

    is_deeply $args->{reference_files}, [ fixture('individuals.json') ],
      'reference file is captured as an array ref';
    is $args->{out_file}, 'matrix.mtx',
      'mtx matrix format gets the Matrix Market default output filename';
    is $args->{cytoscape_json}, 'graph.json',
      'cytoscape-json without an explicit value gets the default graph filename';
    is $args->{graph_max_weight}, 10, 'graph max-weight is captured';
    is $args->{max_matrix_records_in_ram}, 42,
      'matrix RAM threshold uses the current records option name';
    ok $args->{verbose}, 'short -v alias enables verbose mode';
};

subtest 'parse_args keeps patient-mode defaults separate from cohort-mode defaults' => sub {
    my $args = $cli->parse_args(
        '-r', fixture('individuals.json'),
        '-t', fixture('patient.json'),
    );

    is $args->{out_file}, 'rank.txt',
      'patient mode keeps the rank output default';
    is $args->{target_file}, fixture('patient.json'), 'target file is captured';
    ok !exists $args->{matrix_format}, 'undefined options are filtered out';
};

subtest 'precomputed prefix resolves plain or gzipped exported files' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $prefix = catfile( $tmpdir, 'job' );
    my $gz_ref = "$prefix.ref_hash.json.gz";
    open my $fh, '>', $gz_ref;
    print {$fh} "{}\n";
    close $fh;

    my $args = $cli->parse_args( '--prp', $prefix );

    is $args->{glob_hash_file}, "$prefix.glob_hash.json",
      'missing precomputed files keep the expected plain filename';
    is $args->{ref_hash_file}, $gz_ref,
      'gzipped precomputed files are preferred when the plain file is absent';
    is $args->{out_file}, 'matrix.txt',
      'precomputed cohort mode keeps dense matrix default unless requested otherwise';
};

subtest '--man is deprecated but exits successfully' => sub {
    my $script = catfile( 'bin', 'pheno-ranker' );
    my $output = qx{$^X -Ilib $script --man 2>&1};
    my $exit   = $? >> 8;

    is $exit, 0, '--man exits successfully';
    like $output, qr/--man is deprecated/, '--man reports deprecation';
    like $output, qr/pheno-ranker\/usage/, '--man points to usage documentation';
};

done_testing;
