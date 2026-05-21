#!/usr/bin/env perl
use strict;
use warnings;
use lib qw(./lib ../lib t/lib);

use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir tempfile);
use Test::Exception;
use Test::More;
use Test::PhenoRanker qw(fixture temp_output_file);

use Pheno::Ranker;
use Pheno::Ranker::CLI;
use Pheno::Ranker::Config;
use Pheno::Ranker::Context;
use Pheno::Ranker::Options;
use Pheno::Ranker::Graph;
use Pheno::Ranker::IO;
use Pheno::Ranker::Metrics;
use Pheno::Ranker::Compare;
use Pheno::Ranker::Compare::Alignment;
use Pheno::Ranker::Compare::Encoding;
use Pheno::Ranker::Compare::Matrix;
use Pheno::Ranker::Compare::Ontology;
use Pheno::Ranker::Compare::Prepare;
use Pheno::Ranker::Compare::Prune;
use Pheno::Ranker::Compare::Rank;
use Pheno::Ranker::Compare::Remap;

my $tmpdir = tempdir( CLEANUP => 1 );

subtest 'Graph helpers can build and summarize Cytoscape graphs' => sub {
    my ( $binary_graph_fh, $binary_graph_file ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.json', UNLINK => 1 );
    close $binary_graph_fh;
    my $binary_graph = binary_hash2graph(
        {
            ref_binary_hash => {
                A => { binary_digit_string_weighted => '00' },
                B => { binary_digit_string_weighted => '10' },
                C => { binary_digit_string_weighted => '01' },
            },
            json             => $binary_graph_file,
            metric           => 'hamming',
            graph_stats      => 1,
            graph_max_weight => 1,
        }
    );
    is scalar @{ $binary_graph->{elements}{nodes} }, 3,
      'binary_hash2graph creates all nodes directly from binary hashes';
    is scalar @{ $binary_graph->{elements}{edges} }, 2,
      'binary_hash2graph applies max-weight filtering';
    is_deeply read_json($binary_graph_file), $binary_graph,
      'binary_hash2graph writes the graph JSON';

    my ( $unfiltered_graph_fh, $unfiltered_graph_file ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.json', UNLINK => 1 );
    close $unfiltered_graph_fh;
    my $graph = binary_hash2graph(
        {
            ref_binary_hash => {
                A => { binary_digit_string_weighted => '00' },
                B => { binary_digit_string_weighted => '10' },
                C => { binary_digit_string_weighted => '01' },
            },
            json        => $unfiltered_graph_file,
            metric      => 'hamming',
            graph_stats => 1,
        }
    );
    is scalar @{ $graph->{elements}{edges} }, 3,
      'binary_hash2graph writes upper-triangle graph edges';

    my ( $stats_fh, $stats_file ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.txt', UNLINK => 1 );
    close $stats_fh;
    ok(
        cytoscape2graph(
            {
                graph  => {
                    elements => {
                        nodes => $graph->{elements}{nodes},
                        edges => [
                            { data => { source => 'A', target => 'B', weight => 0.5 } },
                            { data => { source => 'B', target => 'C', weight => 0.4 } },
                            { data => { source => 'A', target => 'C', weight => 0.2 } },
                        ],
                    },
                },
                output => $stats_file,
                metric => 'jaccard',
            }
        ),
        'cytoscape2graph writes graph stats for a connected graph'
    );
    like slurp($stats_file), qr/^Metric: Jaccard/m, 'graph stats include the metric';
};

subtest 'IO helpers round-trip files and validate small data structures' => sub {
    my ( $json_fh, $json_file ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.json', UNLINK => 1 );
    my ( $yaml_fh, $yaml_file ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.yaml', UNLINK => 1 );
    close $json_fh;
    close $yaml_fh;

    my $data = { beta => [ 2, 3 ], alpha => { nested => 1 } };

    ok write_json( { filepath => $json_file, data => $data } ), 'write_json succeeds';
    is_deeply read_json($json_file), $data, 'read_json round-trips write_json output';

    ok Pheno::Ranker::IO::write_yaml( { filepath => $yaml_file, data => $data } ),
      'write_yaml succeeds';
    is_deeply read_yaml($yaml_file), $data, 'read_yaml round-trips write_yaml output';

    my ( $gzip_yaml_fh, $gzip_yaml ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.yaml.gz', UNLINK => 1 );
    close $gzip_yaml_fh;
    {
        require IO::Compress::Gzip;
        my $yaml_text = "---\nalpha: 1\n";
        IO::Compress::Gzip::gzip( \$yaml_text => $gzip_yaml )
          or die "gzip failed: $IO::Compress::Gzip::GzipError";
    }
    is_deeply read_yaml($gzip_yaml), { alpha => 1 }, 'read_yaml supports gzipped YAML';

    my ( $dispatch_fh, $via_dispatch ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.yml', UNLINK => 1 );
    close $dispatch_fh;
    ok(
        io_yaml_or_json(
            { mode => 'write', filepath => $via_dispatch, data => { ok => 1 } }
        ),
        'io_yaml_or_json dispatches writes'
    );
    is_deeply(
        io_yaml_or_json( { mode => 'read', filepath => $via_dispatch } ),
        { ok => 1 },
        'io_yaml_or_json dispatches reads'
    );
    throws_ok {
        my ( $bad_fh, $bad_file ) =
          tempfile( DIR => $tmpdir, SUFFIX => '.txt', UNLINK => 1 );
        close $bad_fh;
        io_yaml_or_json( { mode => 'read', filepath => $bad_file } )
    }
    qr/Extensions allowed/,
      'io_yaml_or_json rejects unsupported extensions';

    my ( $export_fh, $export_base ) = tempfile( DIR => $tmpdir, UNLINK => 1 );
    close $export_fh;
    unlink $export_base;
    ok(
        serialize_hashes(
            {
                export_basename => $export_base,
                data            => { one => { id => 1 }, two => [2] },
            }
        ),
        'serialize_hashes writes each named hash'
    );
    is_deeply read_json("$export_base.one.json"), { id => 1 }, 'first serialized hash is readable';
    is_deeply read_json("$export_base.two.json"), [2], 'second serialized hash is readable';

    my $poi_data = [ { id => 'P1', label => 'match' } ];
    my $warning;
    local $SIG{__WARN__} = sub { $warning = join q{}, @_ };
    ok(
        write_poi(
            {
                ref_data     => $poi_data,
                poi          => [qw(P1 missing)],
                poi_out_dir  => $tmpdir,
                primary_key  => 'id',
                verbose      => 1,
            }
        ),
        'write_poi handles matching and missing patients'
    );
    is_deeply read_json( catfile( $tmpdir, 'P1.json' ) ), $poi_data->[0],
      'write_poi writes the matching individual';
    like $warning, qr/No individual found for <missing>/, 'write_poi warns for missing individuals';
    is poi_output_filename( '107:week_0_arm_1', 0 ),
      '107:week_0_arm_1.json',
      'poi_output_filename preserves colon in POSIX-compatible mode';
    is poi_output_filename( '107:week_0_arm_1', 1 ),
      '107%3Aweek_0_arm_1.json',
      'poi_output_filename encodes colon for Windows-compatible mode';
    is poi_output_filename( 'a/b%2Fc', 0 ),
      'a%2Fb%252Fc.json',
      'poi_output_filename encodes path separators and literal percent signs';
    is poi_output_filename( 'CON', 1 ),
      '_CON.json',
      'poi_output_filename avoids Windows reserved device names';

    is_deeply array2object( [ { only => 1 } ] ), { only => 1 }, 'array2object unwraps one item';
    throws_ok { array2object( [ {}, {} ] ) } qr/only 1 patient/, 'array2object rejects multiple items';

    my $coverage = coverage_stats(
        [
            {
                present => 'value',
                empty_h => {},
                empty_a => [],
                missing => undef,
                na      => 'NA',
                nan     => 'NaN',
            },
            { present => 0, extra => 'x' },
        ],
        'BFF'
    );
    is $coverage->{cohort_size}, 2, 'coverage_stats records cohort size';
    is $coverage->{coverage_terms}{present}, 2, 'coverage_stats counts defined values';
    is $coverage->{coverage_terms}{empty_h}, 0, 'coverage_stats ignores empty hashes';
    ok check_existence_of_include_terms( $coverage, ['present'] ), 'include term exists';
    ok !check_existence_of_include_terms( $coverage, ['absent'] ), 'missing include term is false';
    ok check_existence_of_include_terms( $coverage, [] ), 'empty include term list is true';

    my $excluded_coverage = coverage_stats(
        [
            {
                id                  => 'excluded-only',
                phenotypicFeatures  => [
                    {
                        excluded => JSON::XS::true,
                        type     => { id => 'HP:0000001' },
                    },
                ],
            },
            {
                id                 => 'mixed',
                phenotypicFeatures => [
                    {
                        excluded => JSON::XS::true,
                        type     => { id => 'HP:0000001' },
                    },
                    {
                        type => { id => 'HP:0000002' },
                    },
                ],
            },
        ],
        'PXF'
    );
    is $excluded_coverage->{coverage_terms}{phenotypicFeatures}, 1,
      'coverage_stats ignores excluded-only phenotypicFeatures by default';

    my $retained_excluded_coverage = coverage_stats(
        [
            {
                id                 => 'excluded-only',
                phenotypicFeatures => [
                    {
                        excluded => JSON::XS::true,
                        type     => { id => 'HP:0000001' },
                    },
                ],
            },
        ],
        'PXF',
        { retain_excluded_phenotypicFeatures => 1 }
    );
    is $retained_excluded_coverage->{coverage_terms}{phenotypicFeatures}, 1,
      'coverage_stats counts excluded phenotypicFeatures when retain flag is enabled';

    my $excluded_export_file = catfile( $tmpdir, 'excluded-export.json' );
    write_json(
        {
            filepath => $excluded_export_file,
            data     => [
                {
                    id                  => 'excluded-only',
                    subject             => { id => 'excluded-only' },
                    phenotypicFeatures  => [
                        {
                            excluded => JSON::XS::true,
                            type     => { id => 'HP:0000001' },
                        },
                    ],
                },
                {
                    id                 => 'present',
                    subject            => { id => 'present' },
                    phenotypicFeatures => [
                        {
                            type => { id => 'HP:0000002' },
                        },
                    ],
                },
            ],
        }
    );
    my $excluded_export_prefix = catfile( $tmpdir, 'excluded-export' );
    my ( undef, $excluded_matrix_file ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.txt', UNLINK => 1 );
    my $excluded_export_ranker = Pheno::Ranker->new(
        {
            age                  => 0,
            align                => '',
            align_basename       => catfile( $tmpdir, 'excluded-align' ),
            append_prefixes      => [],
            exclude_terms        => [],
            export               => $excluded_export_prefix,
            include_terms        => [],
            log                  => '',
            max_out              => 36,
            out_file             => $excluded_matrix_file,
            patients_of_interest => [],
            reference_files      => [$excluded_export_file],
        }
    );
    $excluded_export_ranker->run;
    my $exported_coverage =
      read_json("$excluded_export_prefix.coverage_stats.json");
    is $exported_coverage->{coverage_terms}{phenotypicFeatures}, 1,
      'exported coverage ignores excluded-only phenotypicFeatures by default';

    my $single = append_and_rename_primary_key(
        { ref_data => [ { id => 'single' } ], append_prefixes => [], primary_key => 'id' }
    );
    is_deeply $single, [ { id => 'single' } ], 'single cohort is returned unchanged';

    my $combined = append_and_rename_primary_key(
        {
            ref_data        => [ [ { id => 'A' } ], { id => 'B' } ],
            append_prefixes => ['LEFT'],
            primary_key     => 'id',
        }
    );
    is_deeply [ map { $_->{id} } @$combined ], [qw(LEFT_A C2_B)],
      'multiple cohorts get explicit and generated prefixes';
    throws_ok {
        Pheno::Ranker::IO::check_null_primary_key(
            { id => undef, count => 1, primary_key => 'id', prefix => 'C1_' }
        )
    }
    qr/primary_key <id>/,
      'check_null_primary_key rejects undefined ids';
};

subtest 'PXF interpretation restructuring handles supported shapes' => sub {
    my $data = [
        {
            id              => 'PXF1',
            interpretations => [
                {
                    progressStatus => 'SOLVED',
                    diagnosis      => {
                        disease => { id => 'MONDO:1' },
                        genomicInterpretations => [
                            {
                                interpretationStatus => 'CAUSATIVE',
                                variantInterpretation => {
                                    variationDescriptor => {
                                        geneContext => { valueId => 'GENE1' },
                                    },
                                },
                            },
                            {
                                interpretationStatus => 'CANDIDATE',
                                variantInterpretation => {
                                    variationDescriptor => { id => 'VAR1' },
                                },
                            },
                            {
                                interpretationStatus => 'REJECTED',
                                geneDescriptor        => { valueId => 'GENE2' },
                            },
                        ],
                    },
                },
            ],
        },
    ];
    my $self = { format => 'PXF', exclude_terms => [] };

    ok restructure_pxf_interpretations( $data, $self ), 'PXF interpretations are restructured';
    my $interpretations = $data->[0]{interpretations}{'MONDO:1'}{genomicInterpretations};
    ok exists $interpretations->{GENE1}{variantInterpretation}, 'variant geneContext is keyed by gene';
    ok exists $interpretations->{VAR1}{variantInterpretation},  'variant id fallback is keyed by id';
    ok exists $interpretations->{GENE2}{geneDescriptor},        'geneDescriptor is keyed by gene';

    my $excluded = { interpretations => [] };
    ok !defined restructure_pxf_interpretations(
        $excluded, { format => 'BFF', exclude_terms => [] }
      ),
      'non-PXF data is ignored';

    my $hash_interpretation = {
        interpretations => [
            {
                progressStatus => 'UNKNOWN',
                diagnosis      => {
                    disease => { id => 'MONDO:2' },
                    genomicInterpretations => [
                        {
                            interpretationStatus => 'CANDIDATE',
                            geneDescriptor        => { valueId => 'GENE3' },
                        },
                    ],
                },
            },
        ],
    };
    ok restructure_pxf_interpretations( $hash_interpretation, $self ),
      'PXF interpretation restructuring accepts a single hash';
    ok exists $hash_interpretation->{interpretations}{'MONDO:2'}{genomicInterpretations}{GENE3},
      'single-hash PXF interpretation is keyed by disease and gene';

    my $excluded_interpretations = { interpretations => [] };
    ok !defined restructure_pxf_interpretations(
        $excluded_interpretations,
        { format => 'PXF', exclude_terms => ['interpretations'] }
      ),
      'PXF interpretation restructuring honors excluded interpretations';
};

subtest 'Metrics helpers cover error branches and pure Perl fallbacks' => sub {
    is hd_fast( '1010', '0011' ), 2, 'hd_fast returns hamming distance';
    throws_ok { hd_fast( '10', '101' ) } qr/same length/, 'hd_fast rejects unequal lengths';
    is Pheno::Ranker::Metrics::_hd_fast( '1010', '0011' ), 2, '_hd_fast fallback works';

    my ( $jaccard, $intersection ) = jaccard_similarity( '1100', '1010' );
    is sprintf( '%.6f', $jaccard ), '0.333333', 'jaccard_similarity returns similarity';
    is $intersection, 1, 'jaccard_similarity returns intersection';
    is jaccard_similarity_formatted( '1100', '1010' ), '0.333333',
      'jaccard_similarity_formatted formats similarity';
    throws_ok { jaccard_similarity( '1', '10' ) } qr/equal length/,
      'jaccard_similarity rejects unequal lengths';

    my @zero_union = Pheno::Ranker::Metrics::_jaccard_similarity( '0000', '0000' );
    is_deeply \@zero_union, [ 0, 0 ], '_jaccard_similarity handles zero union';
    my @fallback = Pheno::Ranker::Metrics::_jaccard_similarity( '1100', '1010' );
    is sprintf( '%.6f', $fallback[0] ), '0.333333', '_jaccard_similarity fallback works';

    my ( $mean, $sd ) = estimate_hamming_stats(8);
    is $mean, 4, 'estimate_hamming_stats returns expected mean';
    is sprintf( '%.3f', $sd ), '1.414', 'estimate_hamming_stats returns expected stddev';
    is z_score( 10, 5, 0 ), 0, 'z_score handles zero standard deviation';
    is z_score( 10, 4, 2 ), 3, 'z_score computes non-zero standard deviation';
    cmp_ok p_value_from_z_score(0), '==', 0.5, 'p_value_from_z_score uses normal CDF';

    my $stats = add_stats( [ 1, 2, 3, 4 ] );
    is $stats->{count}, 4, 'add_stats records count';
    is $stats->{sum},   10, 'add_stats records sum';
};

subtest 'Compare helpers cover deterministic transforms and exports' => sub {
    my $randomized = randomize_variables(
        { map { $_ => $_ } qw(a b c d e) },
        { max_number_vars => 3, seed => 123456789 }
    );
    is scalar keys %$randomized, 3, 'randomize_variables limits the number of variables';
    is_deeply $randomized, randomize_variables(
        { map { $_ => $_ } qw(a b c d e) },
        { max_number_vars => 3, seed => 123456789 }
      ),
      'randomize_variables is deterministic for a fixed seed';

    my $hpo = {
        graphs => [
            {
                nodes => [
                    {
                        id  => 'http://purl.obolibrary.org/obo/HP_0000001',
                        lbl => 'All',
                    },
                    {
                        id  => 'http://purl.obolibrary.org/obo/HP_0000002',
                        lbl => 'Child',
                    },
                ],
                edges => [
                    {
                        sub => 'http://purl.obolibrary.org/obo/HP_0000002',
                        obj => 'http://purl.obolibrary.org/obo/HP_0000001',
                    },
                ],
            },
        ],
    };
    my ( $nodes, $edges ) = parse_hpo_json($hpo);
    is $nodes->{'http://purl.obolibrary.org/obo/HP_0000001'}{lbl}, 'All',
      'parse_hpo_json indexes nodes by id';
    is_deeply(
        $edges->{'http://purl.obolibrary.org/obo/HP_0000002'},
        ['http://purl.obolibrary.org/obo/HP_0000001'],
        'parse_hpo_json groups parent edges by child id'
    );
    is_deeply(
        Pheno::Ranker::Compare::add_hpo_ascendants(
            'phenotypicFeatures.HP:0000002.featureType.id.HP:0000002',
            $nodes,
            $edges,
        ),
        ['phenotypicFeatures.HP:0000001.featureType.id.HP:0000001'],
        'add_hpo_ascendants rewrites HPO ids to parent terms'
    );

    my $encoded = Pheno::Ranker::Compare::binary_to_base64('101001');
    is Pheno::Ranker::Compare::_base64_to_binary( $encoded, 6 ), '101001',
      'binary_to_base64 round-trips through _base64_to_binary';

    my $binary_hash = create_binary_digit_string(
        'export',
        { a => 2, b => 1 },
        { a => 2, b => 1, c => 3 },
        { I1 => { a => 1, c => 1 }, I2 => { b => 1 } },
    );
    is $binary_hash->{I1}{binary_digit_string}, '101',
      'create_binary_digit_string records unweighted bits';
    is $binary_hash->{I1}{binary_digit_string_weighted}, '110111',
      'create_binary_digit_string records weighted bits';
    is(
        Pheno::Ranker::Compare::_base64_to_binary(
            $binary_hash->{I1}{zlib_base64_binary_digit_string}, 3
        ),
        '101',
        'create_binary_digit_string exports compressed unweighted bits'
    );

    my $unweighted = create_binary_digit_string(
        undef,
        undef,
        { a => 1, b => 1 },
        { I1 => { b => 1 } },
    );
    is $unweighted->{I1}{binary_digit_string_weighted}, '01',
      'create_binary_digit_string reuses unweighted bits without weights';

    my $included_hash = { foo => 1, bar => 1, baz => 1 };
    Pheno::Ranker::Compare::prune_excluded_included(
        $included_hash,
        { include_terms => ['bar'], exclude_terms => [] }
    );
    is_deeply $included_hash, { bar => 1 },
      'prune_excluded_included keeps included terms';

    my $excluded_hash = { foo => 1, bar => 1 };
    Pheno::Ranker::Compare::prune_excluded_included(
        $excluded_hash,
        { include_terms => [], exclude_terms => ['foo'] }
    );
    is_deeply $excluded_hash, { bar => 1 },
      'prune_excluded_included removes excluded terms';
    throws_ok {
        Pheno::Ranker::Compare::prune_excluded_included(
            { foo => 1 },
            { include_terms => ['foo'], exclude_terms => ['bar'] }
        )
    }
    qr/mutually exclusive/,
      'prune_excluded_included rejects simultaneous include and exclude';

    my $array_key = Pheno::Ranker::Compare::add_id2key(
        'medicalActions:0.treatment.routeOfAdministration.id',
        { 'medicalActions:0.treatment.agent.id' => 'DrugCentral:1' },
        {
            config_file          => 'test-config.yaml',
            format               => 'BFF',
            id_correspondence    => { BFF => { medicalActions => ['treatment.agent.id'] } },
            array_regex_qr       => qr/^([^:]+):(\d+)\.(.+)$/,
            array_terms_regex_qr => qr/^(medicalActions):/,
        }
    );
    is $array_key, 'medicalActions.DrugCentral:1.treatment.routeOfAdministration.id',
      'add_id2key handles array id_correspondence entries';

    my $nested_filter_self = {
        format                     => 'PXF',
        age                        => 1,
        exclude_variables_regex_qr => qr/label|timestamp|reference\.id/,
    };
    my $nested_a = {
        'medicalActions:0.treatment.agent.id' => 'CHEBI:1',
        'medicalActions:0.treatment.doseIntervals:0.quantity.unit.id' =>
          'UCUM:mg',
        'medicalActions:0.treatment.doseIntervals:0.quantity.value' => 10,
        'medicalActions:0.treatment.doseIntervals:0.quantity.unit.label' =>
          'milligram',
        'medicalActions:0.treatment.doseIntervals:1.quantity.unit.id' =>
          'UCUM:g',
        'medicalActions:0.treatment.doseIntervals:1.quantity.value' => 20,
        'medicalActions:0.treatment.doseIntervals:1.quantity.unit.label' =>
          'gram',
    };
    my $nested_b = {
        'medicalActions:0.treatment.agent.id' => 'CHEBI:1',
        'medicalActions:0.treatment.doseIntervals:0.quantity.unit.id' =>
          'UCUM:g',
        'medicalActions:0.treatment.doseIntervals:0.quantity.value' => 20,
        'medicalActions:0.treatment.doseIntervals:0.quantity.unit.label' =>
          'different ignored label',
        'medicalActions:0.treatment.doseIntervals:1.quantity.unit.id' =>
          'UCUM:mg',
        'medicalActions:0.treatment.doseIntervals:1.quantity.value' => 10,
        'medicalActions:0.treatment.doseIntervals:1.quantity.unit.label' =>
          'also ignored',
    };
    my $canon_a =
      Pheno::Ranker::Compare::Remap::canonicalize_nested_array_indexes(
        $nested_a, $nested_filter_self );
    my $canon_b =
      Pheno::Ranker::Compare::Remap::canonicalize_nested_array_indexes(
        $nested_b, $nested_filter_self );
    is_deeply [ sort keys %{$canon_a} ], [ sort keys %{$canon_b} ],
      'nested array canonicalization removes order-only index differences';
    like join( "\n", sort keys %{$canon_a} ),
      qr/doseIntervals\.idx_[0-9a-f]{12}\.quantity\.unit\.id/,
      'nested array canonicalization replaces nested indexes with signatures';
    unlike join( "\n", sort keys %{$canon_a} ), qr/doseIntervals:\d+/,
      'nested array canonicalization removes raw nested indexes';

    my $prefold_nested = {
        medicalActions => [
            {
                treatment => {
                    agent => { id => 'CHEBI:1' },
                    doseIntervals => [
                        {
                            quantity => {
                                unit  => { id => 'UCUM:mg', label => 'milligram' },
                                value => 10,
                            },
                        },
                    ],
                },
            },
        ],
    };
    Pheno::Ranker::Compare::Remap::normalize_nested_array_indexes(
        $prefold_nested, $nested_filter_self );
    is ref $prefold_nested->{medicalActions}, 'ARRAY',
      'pre-fold normalization preserves first-level arrays for id_correspondence';
    is ref $prefold_nested->{medicalActions}[0]{treatment}{doseIntervals}, 'HASH',
      'pre-fold normalization converts nested arrays to identity-keyed objects';
    like(
        join( "\n",
            keys %{ $prefold_nested->{medicalActions}[0]{treatment}{doseIntervals} } ),
        qr/^idx_[0-9a-f]{12}$/,
        'pre-fold normalization uses content signatures for nested object keys'
    );

    my $bff_nested_a = {
        'measurements:0.assayCode.id' => 'NCIT:C156778',
        'measurements:0.complexValue.typedQuantities:0.quantityType.id' =>
          'NCIT:C87149',
        'measurements:0.complexValue.typedQuantities:0.quantity.unit.id' =>
          'NCIT:C48570',
        'measurements:0.complexValue.typedQuantities:1.quantityType.id' =>
          'NCIT:C25250',
        'measurements:0.complexValue.typedQuantities:1.quantity.unit.id' =>
          'UCUM:kg',
        'biosamples:0.id'                         => 'biosample 1',
        'biosamples:0.diagnosticMarkers:0.id'     => 'NCIT:C131711',
        'biosamples:0.diagnosticMarkers:0.label'  => 'ignored marker label',
        'biosamples:0.diagnosticMarkers:1.id'     => 'NCIT:C140720',
        'biosamples:0.pathologicalTnmFinding:0.id' => 'NCIT:C48725',
        'biosamples:0.pathologicalTnmFinding:1.id' => 'NCIT:C48709',
    };
    my $bff_nested_b = {
        'measurements:0.assayCode.id' => 'NCIT:C156778',
        'measurements:0.complexValue.typedQuantities:0.quantityType.id' =>
          'NCIT:C25250',
        'measurements:0.complexValue.typedQuantities:0.quantity.unit.id' =>
          'UCUM:kg',
        'measurements:0.complexValue.typedQuantities:1.quantityType.id' =>
          'NCIT:C87149',
        'measurements:0.complexValue.typedQuantities:1.quantity.unit.id' =>
          'NCIT:C48570',
        'biosamples:0.id'                         => 'biosample 1',
        'biosamples:0.diagnosticMarkers:0.id'     => 'NCIT:C140720',
        'biosamples:0.diagnosticMarkers:1.id'     => 'NCIT:C131711',
        'biosamples:0.diagnosticMarkers:1.label'  => 'different ignored label',
        'biosamples:0.pathologicalTnmFinding:0.id' => 'NCIT:C48709',
        'biosamples:0.pathologicalTnmFinding:1.id' => 'NCIT:C48725',
    };
    my $bff_canon_a =
      Pheno::Ranker::Compare::Remap::canonicalize_nested_array_indexes(
        $bff_nested_a,
        { %{$nested_filter_self}, format => 'BFF' }
      );
    my $bff_canon_b =
      Pheno::Ranker::Compare::Remap::canonicalize_nested_array_indexes(
        $bff_nested_b,
        { %{$nested_filter_self}, format => 'BFF' }
      );
    is_deeply [ sort keys %{$bff_canon_a} ], [ sort keys %{$bff_canon_b} ],
      'nested array canonicalization handles BFF-style nested arrays';
    like join( "\n", sort keys %{$bff_canon_a} ),
      qr/typedQuantities\.idx_[0-9a-f]{12}\.quantityType\.id/,
      'nested array canonicalization covers complex typed quantities';
    like join( "\n", sort keys %{$bff_canon_a} ),
      qr/diagnosticMarkers\.idx_[0-9a-f]{12}\.id/,
      'nested array canonicalization covers biosample marker arrays';

    my $ignored_only = {
        'medicalActions:0.treatment.doseIntervals:0.label' => 'ignored',
    };
    is_deeply(
        Pheno::Ranker::Compare::Remap::canonicalize_nested_array_indexes(
            $ignored_only, $nested_filter_self
        ),
        $ignored_only,
        'nested array canonicalization leaves indexes when no usable leaves remain'
    );

    my $nested_remap_self = {
        include_terms                  => [],
        exclude_terms                  => [],
        format                         => 'PXF',
        retain_excluded_phenotypicFeatures => undef,
        id_correspondence              => { PXF => { medicalActions => ['treatment.agent.id'] } },
        array_regex_qr                 => qr/^([^:]+):(\d+)\.(.+)$/,
        array_terms_regex_qr           => qr/^(medicalActions):/,
        exclude_variables_regex_qr     => qr/label|timestamp|reference\.id/,
        age                            => 1,
    };
    my $nested_remap_a = remap_hash(
        {
            hash => {
                id             => 'A',
                medicalActions => [
                    {
                        treatment => {
                            agent => { id => 'CHEBI:1' },
                            doseIntervals => [
                                {
                                    quantity => {
                                        unit  => { id => 'UCUM:mg', label => 'milligram' },
                                        value => 10,
                                    },
                                },
                                {
                                    quantity => {
                                        unit  => { id => 'UCUM:g', label => 'gram' },
                                        value => 20,
                                    },
                                },
                            ],
                        },
                    },
                ],
            },
            self => $nested_remap_self,
        }
    );
    my $nested_remap_b = remap_hash(
        {
            hash => {
                id             => 'A',
                medicalActions => [
                    {
                        treatment => {
                            agent => { id => 'CHEBI:1' },
                            doseIntervals => [
                                {
                                    quantity => {
                                        unit  => { id => 'UCUM:g', label => 'ignored text' },
                                        value => 20,
                                    },
                                },
                                {
                                    quantity => {
                                        unit  => { id => 'UCUM:mg', label => 'ignored text' },
                                        value => 10,
                                    },
                                },
                            ],
                        },
                    },
                ],
            },
            self => $nested_remap_self,
        }
    );
    is_deeply $nested_remap_a, $nested_remap_b,
      'remap_hash is stable when nested arrays differ only by order';
    ok(
        ( grep { /doseIntervals\.idx_[0-9a-f]{12}\.quantity\.unit\.id\.UCUM:mg/ }
              keys %{$nested_remap_a} ),
        'remap_hash emits canonicalized nested array variables'
    );
    ok(
        !( grep { /^medicalActions\.idx_/ } keys %{$nested_remap_a} ),
        'remap_hash never applies content signatures to first-level arrays'
    );
    ok(
        ( grep { /^medicalActions\.CHEBI:1\./ } keys %{$nested_remap_a} ),
        'remap_hash preserves config-based identity for first-level arrays'
    );

    my $first_level_remap = remap_hash(
        {
            hash => {
                id                 => 'A',
                phenotypicFeatures => [
                    {
                        type => {
                            id    => 'HP:0000002',
                            label => 'Child',
                        },
                    },
                ],
            },
            self => {
                include_terms                  => [],
                exclude_terms                  => [],
                format                         => 'PXF',
                retain_excluded_phenotypicFeatures => undef,
                id_correspondence              => { PXF => { phenotypicFeatures => 'type.id' } },
                array_regex_qr                 => qr/^([^:]+):(\d+)\.(.+)$/,
                array_terms_regex_qr           => qr/^(phenotypicFeatures):/,
                exclude_variables_regex_qr     => qr/label/,
                age                            => 1,
            },
        }
    );
    ok exists $first_level_remap->{'phenotypicFeatures.HP:0000002.type.id.HP:0000002'},
      'first-level PXF arrays continue to use configured CURIE identity';
    ok(
        !( grep { /phenotypicFeatures\.idx_/ } keys %{$first_level_remap} ),
        'first-level PXF arrays are not content-signature canonicalized'
    );

    my $json_remap_base = {
        include_terms                  => [],
        exclude_terms                  => [],
        format                         => 'JSON',
        retain_excluded_phenotypicFeatures => undef,
        array_regex_qr                 => qr/^([^:]+):(\d+)(?:\.(.+))?$/,
        array_terms_regex_qr           => qr/^(genre|items):/,
        exclude_variables_regex_qr     => qr/label/,
        age                            => 1,
        config_file                    => 'json-config.yaml',
    };
    my $json_scalar_remap = remap_hash(
        {
            hash => {
                id    => 'A',
                genre => [ 'Sci-Fi', 'Drama' ],
            },
            self => $json_remap_base,
        }
    );
    ok exists $json_scalar_remap->{'genre.Sci-Fi'},
      'generic JSON scalar arrays use the scalar value as default identity';
    ok exists $json_scalar_remap->{'genre.Drama'},
      'generic JSON scalar arrays canonicalize all scalar values';

    my $json_object_remap = remap_hash(
        {
            hash => {
                id    => 'A',
                items => [
                    {
                        id    => 'item-1',
                        label => 'ignored',
                        color => 'red',
                    },
                ],
            },
            self => $json_remap_base,
        }
    );
    ok exists $json_object_remap->{'items.item-1.color.red'},
      'generic JSON object arrays infer direct id fields by default';
    ok(
        !( grep { /items\.idx_/ } keys %{$json_object_remap} ),
        'generic JSON direct ids take precedence over content signatures'
    );

    my $json_content_a = remap_hash(
        {
            hash => {
                id    => 'A',
                items => [
                    { color => 'red',  shape => 'round' },
                    { color => 'blue', shape => 'square' },
                ],
            },
            self => $json_remap_base,
        }
    );
    my $json_content_b = remap_hash(
        {
            hash => {
                id    => 'A',
                items => [
                    { shape => 'square', color => 'blue' },
                    { shape => 'round',  color => 'red' },
                ],
            },
            self => $json_remap_base,
        }
    );
    is_deeply $json_content_a, $json_content_b,
      'generic JSON object arrays fall back to stable content identities';
    like join( "\n", sort keys %{$json_content_a} ),
      qr/items\.idx_[0-9a-f]{12}\.color\.red/,
      'generic JSON content fallback emits idx signatures';

    my $json_explicit_remap = remap_hash(
        {
            hash => {
                id    => 'A',
                items => [
                    {
                        id   => 'direct-id',
                        code => 'configured-code',
                    },
                ],
            },
            self => {
                %{$json_remap_base},
                id_correspondence => { JSON => { items => 'code' } },
            },
        }
    );
    ok exists $json_explicit_remap->{'items.configured-code.id.direct-id'},
      'generic JSON explicit identity_paths override default identity inference';
    ok(
        !( grep { /items\.direct-id\./ } keys %{$json_explicit_remap} ),
        'generic JSON default direct id is not used when identity_paths are configured'
    );

    is(
        Pheno::Ranker::Compare::guess_label('top.level.leaf'),
        'leaf',
        'guess_label returns the final dotted segment'
    );
    is(
        Pheno::Ranker::Compare::guess_label('undotted'),
        'undotted',
        'guess_label returns undotted strings unchanged'
    );

    throws_ok {
        local $SIG{__WARN__} = sub { };
        Pheno::Ranker::Compare::_base64_to_binary( 'not-base64', 8 )
    }
    qr/Decompression failed/,
      '_base64_to_binary rejects invalid compressed payloads';

    my $empty_remap = remap_hash(
        {
            hash => { id => 'I1' },
            self => {
                include_terms                  => ['missing'],
                exclude_terms                  => [],
                format                         => 'BFF',
                retain_excluded_phenotypicFeatures => undef,
                id_correspondence              => { BFF => {} },
                array_regex_qr                 => qr/^([^:]+):(\d+)\.(.+)$/,
                array_terms_regex_qr           => qr/^(foo):/,
                age                            => 0,
            },
        }
    );
    is_deeply $empty_remap, {}, 'remap_hash returns an empty object after include pruning';

    my $hpo_remap = remap_hash(
        {
            hash => {
                id => 'I1',
                phenotypicFeatures => [
                    {
                        featureType => {
                            id    => 'HP:0000002',
                            label => 'Child',
                        },
                    },
                ],
            },
            weight => { phenotypicFeatures => 2 },
            self   => {
                include_terms                  => [],
                exclude_terms                  => [],
                format                         => 'BFF',
                retain_excluded_phenotypicFeatures => undef,
                id_correspondence              => { BFF => { phenotypicFeatures => 'featureType.id' } },
                array_regex_qr                 => qr/^([^:]+):(\d+)\.(.+)$/,
                array_terms_regex_qr           => qr/^(phenotypicFeatures):/,
                age                            => 1,
                nodes                          => $nodes,
                edges                          => $edges,
            },
        }
    );
    ok exists $hpo_remap->{'phenotypicFeatures.HP:0000002.featureType.id.HP:0000002'},
      'remap_hash includes original HPO feature';
    ok exists $hpo_remap->{'phenotypicFeatures.HP:0000001.featureType.id.HP:0000001'},
      'remap_hash includes HPO ascendants when ontology edges are provided';

    my ( $matrix_fh, $matrix_file ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.txt', UNLINK => 1 );
    close $matrix_fh;
    ok cohort_comparison(
        {
            A => { binary_digit_string_weighted => '00' },
            B => { binary_digit_string_weighted => '11' },
        },
        {
            out_file                  => $matrix_file,
            similarity_metric_cohort  => 'hamming',
            max_matrix_records_in_ram => 1,
        }
      ),
      'cohort_comparison supports RAM-efficient mode';
    like slurp($matrix_file), qr/^A\t0\t2/m, 'cohort_comparison writes expected distances';

    my ( $mtx_fh, $mtx_file ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.mtx', UNLINK => 1 );
    close $mtx_fh;
    ok cohort_comparison(
        {
            A => { binary_digit_string_weighted => '00' },
            B => { binary_digit_string_weighted => '11' },
        },
        {
            out_file                  => $mtx_file,
            similarity_metric_cohort  => 'hamming',
            max_matrix_records_in_ram => 1,
            matrix_format             => 'mtx',
        }
      ),
      'cohort_comparison writes Matrix Market sparse output';
    my $mtx = slurp($mtx_file);
    like $mtx, qr/^%%MatrixMarket matrix coordinate real symmetric/m,
      'Matrix Market output has coordinate symmetric header';
    like $mtx, qr/^\s*2\s+2\s+1\s*$/m,
      'Matrix Market output records sparse matrix dimensions and nonzero count';
    like $mtx, qr/^1 2 2$/m,
      'Matrix Market output records upper-triangle nonzero distance';

    my ( $verbose_matrix_fh, $verbose_matrix_file ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.txt', UNLINK => 1 );
    close $verbose_matrix_fh;
    ok cohort_comparison(
        {
            A => { binary_digit_string_weighted => '00' },
            B => { binary_digit_string_weighted => '11' },
        },
        {
            out_file                  => $verbose_matrix_file,
            similarity_metric_cohort  => 'hamming',
            max_matrix_records_in_ram => 1,
            debug                     => 1,
        }
      ),
      'cohort_comparison covers debug logging branches';
};

subtest 'Ranker validates configuration and fast run branches' => sub {
    my ( $bad_config_fh, $bad_config ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.yaml', UNLINK => 1 );
    close $bad_config_fh;
    Pheno::Ranker::IO::write_yaml(
        { filepath => $bad_config, data => { sort_by => 'hamming' } }
    );
    throws_ok { Pheno::Ranker->new( { config_file => $bad_config } ) }
    qr/No <allowed terms>/,
      'Ranker rejects configs without allowed_terms';

    my ( $missing_correspondence_fh, $missing_correspondence ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.yaml', UNLINK => 1 );
    close $missing_correspondence_fh;
    Pheno::Ranker::IO::write_yaml(
        {
            filepath => $missing_correspondence,
            data     => {
                allowed_terms => ['id'],
                indexed_terms => ['items'],
            },
        }
    );
    throws_ok { Pheno::Ranker->new( { config_file => $missing_correspondence } ) }
    qr/No <identity_paths>/,
      'Ranker rejects indexed config without identity_paths';

    my ( $json_default_identity_fh, $json_default_identity ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.yaml', UNLINK => 1 );
    close $json_default_identity_fh;
    Pheno::Ranker::IO::write_yaml(
        {
            filepath => $json_default_identity,
            data     => {
                allowed_terms => ['items'],
                indexed_terms => ['items'],
                format        => 'JSON',
            },
        }
    );
    lives_ok { Pheno::Ranker->new( { config_file => $json_default_identity } ) }
    'Ranker allows JSON indexed configs without identity_paths';

    my ( $format_mismatch_fh, $format_mismatch ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.yaml', UNLINK => 1 );
    close $format_mismatch_fh;
    Pheno::Ranker::IO::write_yaml(
        {
            filepath => $format_mismatch,
            data     => {
                allowed_terms     => ['id'],
                indexed_terms     => ['items'],
                format            => 'PXF',
                identity_paths     => { BFF => { items => 'id' } },
            },
        }
    );
    throws_ok { Pheno::Ranker->new( { config_file => $format_mismatch } ) }
    qr/does not match any key/,
      'Ranker rejects format missing from identity_paths';

    throws_ok {
        Pheno::Ranker->new(
            ranker_args(
                append_prefixes => ['A'],
                reference_files => [ fixture('individuals.json') ],
            )
        )
    }
    qr/requires at least 2 cohort files/,
      'Ranker validates append-prefix cohort count';

    throws_ok {
        Pheno::Ranker->new(
            ranker_args(
                append_prefixes => ['A'],
                reference_files => [ fixture('individuals.json'), fixture('patient.json') ],
            )
        )
    }
    qr/number of items/,
      'Ranker validates append-prefix item count';

    throws_ok {
        Pheno::Ranker->new( ranker_args( patients_of_interest => ['missing'] ) )
    }
    qr/must be used with <--r>/,
      'Ranker validates POI requires a reference cohort';

    throws_ok {
        Pheno::Ranker->new(
            ranker_args(
                reference_files => [ fixture('individuals.json') ],
                align           => catfile( $tmpdir, 'missing-dir', 'align' ),
                out_file        => temp_output_file(),
            )
        )->run;
    }
    qr/Directory .* does not exist \(used with --align\)/,
      'Ranker validates align output directory';

    throws_ok {
        Pheno::Ranker->new(
            ranker_args(
                reference_files => [ fixture('individuals.json') ],
                export          => catfile( $tmpdir, 'missing-dir', 'export' ),
                out_file        => temp_output_file(),
            )
        )->run;
    }
    qr/Directory .* does not exist \(used with --export\)/,
      'Ranker validates export output directory';

    my $poi_dir = tempdir( DIR => $tmpdir, CLEANUP => 1 );
    ok(
        Pheno::Ranker->new(
            ranker_args(
                reference_files      => [ fixture('individuals.json') ],
                out_file             => temp_output_file(),
                patients_of_interest => ['107:week_0_arm_1'],
                poi_out_dir          => $poi_dir,
            )
        )->run,
        'Ranker POI dry-run returns successfully'
    );
    ok -f catfile( $poi_dir, poi_output_filename('107:week_0_arm_1') ),
      'Ranker POI dry-run writes the selected individual';

    my ( $export_fh, $export_base ) =
      tempfile( DIR => $tmpdir, SUFFIX => '.export', UNLINK => 1 );
    close $export_fh;
    unlink $export_base;
    ok(
        Pheno::Ranker->new(
            ranker_args(
                reference_files => [ fixture('individuals.json') ],
                out_file        => temp_output_file(),
                export          => $export_base,
            )
        )->run,
        'Ranker serializes export hashes'
    );
    ok -f "$export_base.glob_hash.json", 'Ranker writes exported glob hash';
};

done_testing;

sub slurp {
    my $file = shift;
    open my $fh, '<:encoding(UTF-8)', $file;
    local $/;
    return <$fh>;
}

sub ranker_args {
    my (%override) = @_;

    my %args = (
        age                       => 0,
        align_basename            => 'alignment',
        append_prefixes           => [],
        exclude_terms             => [],
        include_terms             => [],
        log                       => '',
        max_out                   => 36,
        out_file                  => temp_output_file(),
        patients_of_interest      => [],
        reference_files           => [],
    );

    @args{ keys %override } = values %override;
    return \%args;
}
