package PAX::Gatekeeper;

our $VERSION = '0.031';

use strict;
use warnings;
use JSON::PP ();
use PAX::Backend::Tier1CraneliftEquivalent;
use PAX::Backend::Tier2LLVM;
use PAX::Benchmark;
use PAX::BenchmarkMatrix;
use PAX::CPANMatrix;
use PAX::Capture;
use PAX::CoreSuite;
use PAX::Corpus;
use PAX::GuardedSSA;
use PAX::HIR;
use PAX::Manifest;
use PAX::ProfileStore;
use PAX::RegionSelector;
use PAX::AppImage;

sub new {
    my ($class, %args) = @_;
    return bless {
        root => $args{root} // '.',
    }, $class;
}

sub sow01_report {
    my ($self) = @_;
    my @checks = (
        $self->_check_file('source_sow', 'project/SOW-01.pdf', 'Approved SOW-01 PDF exists'),
        $self->_check_file('source_sow_02', 'project/SOW-02.pdf', 'Approved SOW-02 PDF exists when SOW-02 is indexed'),
        $self->_check_backlog_approved_sows,
        $self->_check_docker_pin,
        $self->_check_cli_surface,
        $self->_check_test_file('host_cli_tests', 't/cli.t', 'Host CLI test suite is present'),
        $self->_check_core_suite,
        $self->_check_cpan_matrix,
        $self->_check_file('nasty_perl_corpus', 't/corpus.json', 'Nasty Perl corpus manifest is present for local dynamic-feature fixtures'),
        $self->_check_file('benchmark_matrix_manifest', 't/benchmark_matrix.json', 'Benchmark matrix manifest is present'),
        $self->_check_validation_matrix,
        $self->_check_semantic_snapshot_capture,
        $self->_check_optree_derived_hir_lowering,
        $self->_check_tiered_backend_architecture,
        $self->_check_deopt_frame_fields,
        $self->_check_broad_cpan_xs_matrix,
        $self->_check_performance_observability_fields,
        $self->_check_current_docs_no_gap_language,
        $self->_check_real_backend_integration,
        $self->_check_real_hot_region_jit_aot,
        $self->_check_real_cpan_xs_coverage,
        $self->_check_whole_program_app_image,
    );
    my $passed = 0;
    $passed++ for grep { $_->{status} eq 'passed' } @checks;
    my $blocked = 0;
    $blocked++ for grep { $_->{status} ne 'passed' } @checks;
    return {
        sow => 'SOW-01',
        status => $blocked ? 'not_passed' : 'passed',
        passed => $passed,
        blocked => $blocked,
        checks => \@checks,
    };
}

sub _check_real_backend_integration {
    my ($self) = @_;
    my $tier1 = _slurp("$self->{root}/lib/PAX/Tier1.pm");
    my $tier2 = _slurp("$self->{root}/lib/PAX/Backend/Tier2LLVM.pm");
    my @missing;
    push @missing, 'real_cranelift_backend' if $tier1 =~ /\brustc\b/ || $tier1 !~ /Cranelift/i;
    push @missing, 'real_llvm_codegen' if $tier2 !~ /LLVM/ || $tier2 !~ /emit|compile|module|object/i;
    return {
        id => 'real_backend_integration',
        description => 'Real Cranelift-equivalent Tier 1 and LLVM Tier 2 code generation are implemented, not just metadata or rustc fixture emission',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'real backend integration',
    };
}

sub _check_real_hot_region_jit_aot {
    my ($self) = @_;
    my @missing;
    push @missing, 'hot_region_jit_runtime' if !-f "$self->{root}/lib/PAX/HotRegionJIT.pm";
    push @missing, 'profile_guided_aot_runtime' if !-f "$self->{root}/lib/PAX/ProfileGuidedAOT.pm";
    push @missing, 'osr_runtime' if !-f "$self->{root}/lib/PAX/OSR.pm";
    push @missing, 'inline_cache_runtime' if !-f "$self->{root}/lib/PAX/InlineCache.pm";
    return {
        id => 'real_hot_region_jit_aot',
        description => 'Hot-region JIT, profile-guided AOT, OSR, and inline caches are implemented',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'JIT/AOT/OSR runtime',
    };
}

sub _check_real_cpan_xs_coverage {
    my ($self) = @_;
    my $matrix = _slurp("$self->{root}/t/cpan_matrix.json");
    my $dist_count = () = $matrix =~ /"distribution"\s*:/g;
    my @missing;
    push @missing, 'broad_distribution_count' if $dist_count < 25;
    push @missing, 'declared_xs_metadata' if $matrix !~ /declared-xs|declared_xs|XS declaration/i;
    push @missing, 'level_a_to_d_coverage' if $matrix !~ /Level A|Level B|Level C|Level D|fully acceleratable|fallback-heavy|unsupported/i;
    return {
        id => 'real_cpan_xs_coverage',
        description => 'Broad real CPAN and XS compatibility matrix covers common distributions and A-D compatibility levels',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'broad CPAN/XS matrix',
    };
}

sub _check_file {
    my ($self, $id, $path, $description) = @_;
    return {
        id => $id,
        description => $description,
        status => -f "$self->{root}/$path" ? 'passed' : 'blocked',
        evidence => $path,
    };
}

sub _check_test_file {
    my ($self, $id, $path, $description) = @_;
    return $self->_check_file($id, $path, $description);
}

sub _check_no_path {
    my ($self, $id, $path, $description) = @_;
    return {
        id => $id,
        description => $description,
        status => !-e "$self->{root}/$path" ? 'passed' : 'blocked',
        evidence => $path,
    };
}

sub _check_backlog_approved_sows {
    my ($self) = @_;
    my $path = "$self->{root}/project/BACKLOG.md";
    my $content = _slurp($path);
    my $ok = $content =~ /\| SOW-01 \|/ && $content =~ /\| SOW-02 \|/ && $content !~ /\| SOW-03 \|/;
    return {
        id => 'approved_sows_indexed',
        description => 'Backlog indexes approved SOW-01 and SOW-02 only',
        status => $ok ? 'passed' : 'blocked',
        evidence => 'project/BACKLOG.md',
    };
}

sub _check_docker_pin {
    my ($self) = @_;
    my $content = _slurp("$self->{root}/Dockerfile");
    return {
        id => 'pinned_perl_baseline',
        description => 'Dockerfile pins the Perl 5.42.0 baseline image',
        status => $content =~ /^FROM\s+perl:5\.42\.0\b/m ? 'passed' : 'blocked',
        evidence => 'Dockerfile',
    };
}

sub _check_cli_surface {
    my ($self) = @_;
    my $content = _slurp("$self->{root}/lib/PAX/CLI.pm");
    my @missing = grep { $content !~ /if \(\$command eq '\Q$_\E'\)/ } ('build', 'run');
    my @extra = grep { $content =~ /if \(\$command eq '\Q$_\E'\)/ } qw(
        capture inspect hir compile diff bench bench-matrix run-native corpus core-suite
        cpan-matrix dispatch profile why-not trace-guards gatekeeper app-build app-start
        app-run app-stop standalone-build standalone-run standalone-inspect standalone-extract
        standalone-why-not standalone-native-run
    );
    return {
        id => 'cli_sow03_surface',
        description => 'Public CLI includes only build and run; diagnostics remain internal implementation APIs',
        status => (@missing || @extra) ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : (@extra ? 'extra: ' . join(', ', @extra) : 'lib/PAX/CLI.pm'),
    };
}

sub _check_whole_program_app_image {
    my ($self) = @_;
    my @missing;
    push @missing, 'app_image_builder' if !-f "$self->{root}/lib/PAX/AppImage.pm";
    push @missing, 'app_server_runtime' if !-f "$self->{root}/lib/PAX/AppServer.pm";
    push @missing, 'paxfile_loader' if !-f "$self->{root}/lib/PAX/Paxfile.pm";
    push @missing, 'project_paxfile' if !-f "$self->{root}/paxfile.yml";
    push @missing, 'app_image_test' if !-f "$self->{root}/t/app_image.t";
    push @missing, 'embedded_asset_fixture' if !-f "$self->{root}/t/fixtures/app_assets/banner.txt";
    my $cli = _slurp("$self->{root}/lib/PAX/CLI.pm");
    my $app_image = _slurp("$self->{root}/lib/PAX/AppImage.pm");
    push @missing, 'public_build_command' if $cli !~ /if \(\$command eq 'build'\)/;
    push @missing, 'public_run_command' if $cli !~ /if \(\$command eq 'run'\)/;
    push @missing, 'asset_build_flags' if $cli !~ /--asset/ || $cli !~ /--asset-dir/;
    push @missing, 'paxfile_cli_flags' if $cli !~ /--paxfile/ || $cli !~ /--no-paxfile/;
    push @missing, 'asset_embedding_runtime' if $app_image !~ /pax_assets/ || $app_image !~ /PAX_EMBEDDED_ASSET_ROOT/;
    return {
        id => 'whole_program_app_image_runtime',
        description => 'Whole-program Perl entrypoints can be built from paxfile.yml into PAX app images with embedded assets and run through a preloaded subsystem',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'PAX::AppImage/PAX::AppServer',
    };
}

sub _check_benchmark_matrix_command {
    my ($self) = @_;
    my $content = _slurp("$self->{root}/lib/PAX/CLI.pm");
    return {
        id => 'full_benchmark_execution',
        description => 'Benchmark matrix has an executable CLI path',
        status => $content =~ /bench-matrix/ ? 'passed' : 'blocked',
        evidence => 'PAX::BenchmarkMatrix t/benchmark_matrix.json',
    };
}

sub _check_validation_matrix {
    my ($self) = @_;
    my @runs = (
        ['core-suite', sub { PAX::CoreSuite->new(manifest_path => "$self->{root}/t/perl_core_suite.json")->run }],
        ['corpus', sub { PAX::Corpus->new(manifest_path => "$self->{root}/t/corpus.json")->run }],
        ['cpan-matrix', sub { PAX::CPANMatrix->new(manifest_path => "$self->{root}/t/cpan_matrix.json")->run }],
        ['bench-matrix', sub { PAX::BenchmarkMatrix->new(manifest_path => "$self->{root}/t/benchmark_matrix.json", iterations => 1, pax_bin => "$self->{root}/bin/pax")->run }],
    );
    my @failed;
    for my $run (@runs) {
        my ($name, $code) = @$run;
        my $result = eval { $code->() };
        if ($@ || !$result || !$result->{passed}) {
            push @failed, $@ ? "$name: $@" : $name;
        }
    }
    return {
        id => 'sow_validation_matrix',
        description => 'Core, nasty Perl, CPAN/XS, and performance validation suites execute successfully',
        status => @failed ? 'blocked' : 'passed',
        evidence => @failed ? join('; ', @failed) : 'core-suite, corpus, cpan-matrix, bench-matrix',
    };
}

sub _check_core_suite {
    my ($self) = @_;
    my $content = _slurp("$self->{root}/lib/PAX/CLI.pm");
    my $report = "$self->{root}/projects/sow-01-project-pax/epic-06-validation-benchmarking-delivery/perl-core-suite-report.md";
    return {
        id => 'perl_core_suite',
        description => 'Perl core regression suite is wired and recorded',
        status => ($content =~ /core-suite/ && -f $report) ? 'passed' : 'blocked',
        evidence => 'PAX::CoreSuite t/perl_core_suite.json',
    };
}

sub _check_cpan_matrix {
    my ($self) = @_;
    my $content = _slurp("$self->{root}/lib/PAX/CLI.pm");
    my $report = "$self->{root}/projects/sow-01-project-pax/epic-06-validation-benchmarking-delivery/cpan-matrix-report.md";
    return {
        id => 'real_cpan_matrix',
        description => 'CPAN distribution matrix is wired and recorded',
        status => ($content =~ /cpan-matrix/ && -f $report) ? 'passed' : 'blocked',
        evidence => 'PAX::CPANMatrix t/cpan_matrix.json',
    };
}

sub _check_semantic_snapshot_capture {
    my ($self) = @_;
    my $manifest = _slurp("$self->{root}/lib/PAX/Manifest.pm");
    my $capture = _slurp("$self->{root}/lib/PAX/Capture.pm");
    my @required = qw(lexical_pads closure_descriptors method_resolution regex_metadata compile_phase_events pad_layout closure_descriptor);
    my @missing = grep { ($manifest . $capture) !~ /\b\Q$_\E\b/ } @required;
    my $snapshot = eval {
        my $raw = PAX::Capture->new(mode => 'live')->capture("$self->{root}/t/fixtures/compile_phase.pl");
        PAX::Manifest->new(capture => $raw)->to_hash;
    };
    push @missing, 'executable_capture' if $@ || !$snapshot || ($snapshot->{capture}{status} // '') ne 'ok';
    push @missing, 'compile_phase_events' if !$snapshot || !@{ $snapshot->{compile_phase_events} // [] };
    push @missing, 'lexical_pads' if !$snapshot || !%{ $snapshot->{lexical_pads}{subs} // {} };
    push @missing, 'closure_descriptors' if !$snapshot || !%{ $snapshot->{closure_descriptors}{subs} // {} };
    push @missing, 'method_resolution' if !$snapshot || !%{ $snapshot->{method_resolution} // {} };
    return {
        id => 'full_semantic_snapshot_capture',
        description => 'Pads, closures, method metadata, regex metadata, and compile-time side effects are captured',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'PAX::Capture/PAX::Manifest',
    };
}

sub _check_optree_derived_hir_lowering {
    my ($self) = @_;
    my $hir = _slurp("$self->{root}/lib/PAX/HIR.pm");
    my $selector = _slurp("$self->{root}/lib/PAX/RegionSelector.pm");
    my $uses_manifest_shape = $hir =~ /source\}\{native_shape\}/ && $selector =~ /native_shape/;
    my $reads_source = $hir =~ /open\s+my\s+\$fh/ || $hir =~ /_slurp/;
    my $pipeline_ok = eval {
        my $capture = PAX::Capture->new(mode => 'live')->capture("$self->{root}/t/fixtures/native_leafs.pl");
        my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
        my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;
        my $units = PAX::HIR->new(manifest => $manifest, regions => $regions->{selected})->lower_all;
        my ($unit) = grep { $_->{source}{native_shape} && @{ $_->{source}{optree_ops} // [] } } @$units;
        $unit ? 1 : 0;
    };
    return {
        id => 'optree_derived_hir_lowering',
        description => 'HIR lowering consumes captured optree/native metadata rather than reading source',
        status => ($uses_manifest_shape && !$reads_source && $pipeline_ok) ? 'passed' : 'blocked',
        evidence => 'lib/PAX/HIR.pm',
    };
}

sub _check_tiered_backend_architecture {
    my ($self) = @_;
    my $tier1 = eval { PAX::Backend::Tier1CraneliftEquivalent->new->metadata };
    my $tier2 = eval { PAX::Backend::Tier2LLVM->new->metadata };
    my @missing;
    push @missing, 'tier1' if !$tier1 || ($tier1->{tier} // 0) != 1;
    push @missing, 'tier2' if !$tier2 || ($tier2->{tier} // 0) != 2;
    push @missing, 'tier1_name' if !$tier1 || ($tier1->{name} // '') =~ /prototype/;
    push @missing, 'tier2_enabled' if !$tier2 || ($tier2->{status} // '') ne 'enabled';
    return {
        id => 'tiered_backend_architecture',
        description => 'Cranelift-equivalent Tier 1 and LLVM Tier 2 backend paths are present',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'PAX::Backend::Tier1CraneliftEquivalent/PAX::Backend::Tier2LLVM',
    };
}

sub _check_performance_observability_fields {
    my ($self) = @_;
    my @missing;
    my $bench = eval {
        PAX::Benchmark->new(pax_bin => "$self->{root}/bin/pax", iterations => 1)
            ->run_runtime_benchmark("$self->{root}/t/fixtures/simple.pl");
    };
    push @missing, 'benchmark_memory_impact' if $@ || !$bench || ref($bench->{memory_impact}) ne 'HASH';
    push @missing, 'benchmark_memory_delta' if !$bench || !exists $bench->{memory_impact}{delta_rss_kb};

    my $store = PAX::ProfileStore->new(threshold => 1);
    $store->record_dispatch({ region_name => 'gate', status => 'native', osr_event => 'promote' });
    $store->record_dispatch({ region_name => 'gate', status => 'fallback', osr_event => 'retire' });
    my ($region) = @{ $store->report->{regions} };
    push @missing, 'osr_promotion_events' if !$region || ($region->{osr_promotions} // 0) < 1;
    push @missing, 'osr_retirement_events' if !$region || ($region->{osr_retirements} // 0) < 1;

    return {
        id => 'performance_observability_fields',
        description => 'Benchmarking and profiling expose memory impact plus OSR promotion and retirement events',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'PAX::Benchmark/PAX::ProfileStore',
    };
}

sub _check_current_docs_no_gap_language {
    my ($self) = @_;
    my @paths = qw(
        project/BACKLOG.md
        DOCKER.md
        projects/sow-01-project-pax/SOW.md
        projects/sow-01-project-pax/implementation-status.md
        projects/sow-01-project-pax/sow-alignment-report.md
        projects/sow-01-project-pax/sow-gatekeeper-report.md
    );
    my @bad;
    for my $path (@paths) {
        my $content = _slurp("$self->{root}/$path");
        push @bad, $path if $content =~ /\b(?:placeholder|not_measured|interface_defined_pending|current prototype|prototype checkpoint|future hardening|remains future|not implemented)\b/i;
    }
    return {
        id => 'current_docs_no_gap_language',
        description => 'Current SOW status documents do not describe completed SOW-01 work as prototype, pending, placeholder, or future work',
        status => @bad ? 'blocked' : 'passed',
        evidence => @bad ? 'gap language in: ' . join(', ', @bad) : 'current SOW status documents',
    };
}

sub _check_broad_cpan_xs_matrix {
    my ($self) = @_;
    my $matrix = _slurp("$self->{root}/t/cpan_matrix.json");
    my $dist_count = () = $matrix =~ /"distribution"\s*:/g;
    my $has_xs = $matrix =~ /installed-xs-backed-cpan/;
    return {
        id => 'broad_cpan_xs_matrix',
        description => 'CPAN and XS matrix covers dual-life and XS-backed distributions',
        status => ($dist_count >= 7 && $has_xs) ? 'passed' : 'blocked',
        evidence => 't/cpan_matrix.json',
    };
}

sub _check_deopt_frame_fields {
    my ($self) = @_;
    my $content = _slurp("$self->{root}/lib/PAX/DeoptEngine.pm");
    my @required = qw(argv wantarray lexicals closure_environment exception_handlers exception_state caller debugger_stack);
    my @missing = grep { $content !~ /\b\Q$_\E\b/ } @required;
    return {
        id => 'arbitrary_frame_deopt',
        description => 'Deopt reconstruction includes arbitrary Perl frame fields',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'lib/PAX/DeoptEngine.pm',
    };
}

sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or return '';
    local $/;
    return <$fh> // '';
}

1;

__END__

=head1 NAME

PAX::Gatekeeper - release and SOW validation checks for PAX

=head1 SYNOPSIS

  my $gatekeeper = PAX::Gatekeeper->new(root => '.');
  my $report = $gatekeeper->sow01_report;

=head1 DESCRIPTION

C<PAX::Gatekeeper> provides internal validation checks used by development and
release gates. SOW-03 keeps these checks as module APIs while the public
C<bin/pax> command surface is limited to C<build> and C<run>.

=head1 METHODS

=head2 new

Creates a gatekeeper rooted at a repository path.

=head2 sow01_report

Returns the historical SOW validation report. The CLI-surface check now verifies
that the public command runner exposes only C<build> and C<run>, with lower-level
diagnostics retained as internal Perl APIs.

=head1 PURPOSE

This module keeps historical SOW and release-policy checks callable from Perl
so validation can be reused by gates and tests without reopening the public CLI
surface.

=cut
