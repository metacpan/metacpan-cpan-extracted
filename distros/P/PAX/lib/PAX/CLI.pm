package PAX::CLI;

our $VERSION = '0.031';

use strict;
use warnings;
use JSON::PP qw(encode_json);
use File::Spec ();
use File::Temp ();
use PAX::Capture;
use PAX::CLI::Progress;
use PAX::Manifest;
use PAX::RegionSelector;
use PAX::HIR;
use PAX::GuardedSSA;
use PAX::GuardManager;
use PAX::Tier1;
use PAX::ArtifactCache;
use PAX::Mode;
use PAX::Differential;
use PAX::Benchmark;
use PAX::NativeRunner;
use PAX::Corpus;
use PAX::RuntimeDispatcher;
use PAX::ProfileStore;
use PAX::Gatekeeper;
use PAX::InlineCache;
use PAX::BenchmarkMatrix;
use PAX::CoreSuite;
use PAX::CPANMatrix;
use PAX::AppImage;
use PAX::AppServer;
use PAX::Paxfile;
use PAX::StandaloneImage;
use PAX::StandaloneDispatch;

sub run {
    my ($class, @argv) = @_;
    my $command = shift @argv // 'help';

    if ($command eq 'run') {
        return $class->_run(@argv);
    }
    if ($command eq 'build') {
        return $class->_build(@argv);
    }
    if ($command eq 'help' || $command eq '--help' || $command eq '-h') {
        print _usage();
        return 0;
    }
    if ($class->_looks_like_interpreter_script($command)) {
        return $class->_run_interpreter_script($command, @argv);
    }

    print STDERR "unknown command: $command\n";
    print STDERR _usage();
    return 2;
}

# Treat a plain script path as interpreter-mode execution so a built pax binary
# can be used directly from a shebang line.
sub _looks_like_interpreter_script {
    my ($class, $candidate) = @_;
    return 0 if !defined $candidate || $candidate eq q{};
    return 0 if $candidate =~ /\A-/;
    return -f $candidate ? 1 : 0;
}

# Execute a shebang-target script as package main while preserving the expected
# process-facing script path and argument vector.
sub _run_interpreter_script {
    my ($class, $script, @argv) = @_;
    my $script_path = File::Spec->rel2abs($script);
    local @ARGV = @argv;
    local $0 = $script_path;
    require FindBin;
    local $FindBin::Bin;
    local $FindBin::RealBin;
    local $FindBin::Script;
    local $FindBin::RealScript;
    FindBin::again();

    my $runner = sub {
        package main;
        my ($path) = @_;
        return do $path;
    };

    my $rv = $runner->($script_path);
    if (!defined $rv) {
        my $error = $@ || $! || "unknown interpreter failure";
        print STDERR "pax interpreter failed for $script_path: $error\n";
        return 255;
    }

    return 0;
}

sub _run {
    my ($class, @argv) = @_;
    return $class->_run_standalone(@argv);
}

sub _run_dispatch {
    my ($class, @argv) = @_;
    my ($left, $right, $region, $pretty, $entrypoint) = (10, 32, undef, 1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--left') {
            $left = shift @argv // return _missing('--left');
            next;
        }
        if ($arg eq '--right') {
            $right = shift @argv // return _missing('--right');
            next;
        }
        if ($arg eq '--region') {
            $region = shift @argv // return _missing('--region');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $entrypoint) {
        print STDERR "run requires a Perl entrypoint\n";
        return 2;
    }

    my $result = PAX::RuntimeDispatcher->new->dispatch_i64(
        entrypoint => $entrypoint,
        left => $left,
        right => $right,
        region_name => $region,
    );
    $result->{command} = 'run';
    $result->{execution_model} = $result->{status} eq 'native' ? 'native' : 'reference_fallback';
    print _json($result, $pretty);
    return 0;
}

sub _capture {
    my ($class, @argv) = @_;
    my ($mode, $pretty, $entrypoint) = ('live', 1);

    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--mode') {
            $mode = shift @argv // return _missing('--mode');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }

    if (!defined $entrypoint) {
        print STDERR "capture requires a Perl entrypoint\n";
        return 2;
    }

    my $capture = PAX::Capture->new(mode => $mode)->capture($entrypoint);
    my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
    print _json($manifest, $pretty);
    return $capture->{status} eq 'ok' ? 0 : 1;
}

sub _inspect {
    my ($class, @argv) = @_;
    my ($mode, $entrypoint) = ('live');

    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--mode') {
            $mode = shift @argv // return _missing('--mode');
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }

    if (!defined $entrypoint) {
        print STDERR "inspect requires a Perl entrypoint\n";
        return 2;
    }

    my $capture = PAX::Capture->new(mode => $mode)->capture($entrypoint);
    my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
    my $compat = $manifest->{compatibility};
    my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;

    print "entrypoint: $manifest->{source_entrypoint}\n";
    print "capture_status: $manifest->{capture}{status}\n";
    print "perl_version: $manifest->{runtime}{perl_version}\n";
    print "baseline: $manifest->{runtime}{perl_family_target}\n";
    print "baseline_match: " . ($manifest->{runtime}{baseline_match} ? 'true' : 'false') . "\n";
    print "compatibility_level: $compat->{level}\n";
    print "compatibility_reason: $compat->{reason}\n";
    print "loaded_modules: " . scalar(@{ $manifest->{module_graph}{modules} }) . "\n";
    print "compile_phase_events: " . scalar(@{ $manifest->{compile_phase_events} }) . "\n";
    print "selected_regions: " . scalar(@{ $regions->{selected} }) . "\n";
    return $capture->{status} eq 'ok' ? 0 : 1;
}

sub _hir {
    my ($class, @argv) = @_;
    my ($mode, $pretty, $entrypoint) = ('live', 1);

    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--mode') {
            $mode = shift @argv // return _missing('--mode');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }

    if (!defined $entrypoint) {
        print STDERR "hir requires a Perl entrypoint\n";
        return 2;
    }

    my $capture = PAX::Capture->new(mode => $mode)->capture($entrypoint);
    my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
    my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;
    my $hir = PAX::HIR->new(
        manifest => $manifest,
        regions => $regions->{selected},
    )->lower_all;

    print _json({
        manifest_schema_version => $manifest->{schema_version},
        source_entrypoint => $manifest->{source_entrypoint},
        regions => $regions,
        hir_units => $hir,
    }, $pretty);
    return $capture->{status} eq 'ok' ? 0 : 1;
}

sub _compile {
    my ($class, @argv) = @_;
    my ($mode, $pretty, $entrypoint) = ('live', 1);

    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--mode') {
            $mode = shift @argv // return _missing('--mode');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }

    if (!defined $entrypoint) {
        print STDERR "compile requires a Perl entrypoint\n";
        return 2;
    }

    my $capture = PAX::Capture->new(mode => $mode)->capture($entrypoint);
    my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
    my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;
    my $hir = PAX::HIR->new(
        manifest => $manifest,
        regions => $regions->{selected},
    )->lower_all;
    my $ssa = PAX::GuardedSSA->new(hir_units => $hir)->build_all;
    my $tier1 = PAX::Tier1->new;
    my @artifacts = map { $tier1->compile($_) } @$ssa;

    print _json({
        source_entrypoint => $manifest->{source_entrypoint},
        ssa_units => $ssa,
        artifacts => \@artifacts,
    }, $pretty);
    return $capture->{status} eq 'ok' ? 0 : 1;
}

sub _build {
    my ($class, @argv) = @_;
    return $class->_build_standalone(@argv);
}

sub _build_artifacts {
    my ($class, @argv) = @_;
    my ($capture_mode, $operation_mode, $cache_root, $pretty, $entrypoint) = ('live', 'dev', '.pax/cache', 1);

    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--mode') {
            $capture_mode = shift @argv // return _missing('--mode');
            next;
        }
        if ($arg eq '--operation-mode') {
            $operation_mode = shift @argv // return _missing('--operation-mode');
            next;
        }
        if ($arg eq '--cache-root') {
            $cache_root = shift @argv // return _missing('--cache-root');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }

    if (!defined $entrypoint) {
        print STDERR "build requires a Perl entrypoint\n";
        return 2;
    }

    my $capture = PAX::Capture->new(mode => $capture_mode)->capture($entrypoint);
    my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
    my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;
    my $hir = PAX::HIR->new(manifest => $manifest, regions => $regions->{selected})->lower_all;
    my $ssa = PAX::GuardedSSA->new(hir_units => $hir)->build_all;
    my $tier1 = PAX::Tier1->new;
    my $cache = PAX::ArtifactCache->new(root => $cache_root);
    my @written;

    for my $unit (@$ssa) {
        my $artifact = $tier1->compile($unit);
        push @written, $cache->write_artifact(
            manifest => $manifest,
            artifact => $artifact,
        );
    }

    print _json({
        source_entrypoint => $manifest->{source_entrypoint},
        operation_mode => $operation_mode,
        operation_policy => PAX::Mode->policy($operation_mode),
        written_artifacts => \@written,
    }, $pretty);
    return $capture->{status} eq 'ok' ? 0 : 1;
}

sub _diff {
    my ($class, @argv) = @_;
    my ($pretty, $entrypoint) = (1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $entrypoint) {
        print STDERR "diff requires a Perl entrypoint\n";
        return 2;
    }
    my $result = PAX::Differential->new(pax_bin => _pax_bin())->compare_capture($entrypoint);
    print _json($result, $pretty);
    return $result->{pass} ? 0 : 1;
}

sub _bench {
    my ($class, @argv) = @_;
    my ($iterations, $pretty, $entrypoint) = (3, 1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--iterations') {
            $iterations = shift @argv // return _missing('--iterations');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $entrypoint) {
        print STDERR "bench requires a Perl entrypoint\n";
        return 2;
    }
    my $result = PAX::Benchmark->new(
        pax_bin => _pax_bin(),
        iterations => $iterations,
    )->run_runtime_benchmark($entrypoint);
    print _json($result, $pretty);
    return 0;
}

sub _bench_matrix {
    my ($class, @argv) = @_;
    my ($iterations, $pretty, $manifest_path) = (1, 1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--iterations') {
            $iterations = shift @argv // return _missing('--iterations');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $manifest_path) {
            $manifest_path = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $manifest_path) {
        print STDERR "bench-matrix requires a manifest path\n";
        return 2;
    }
    my $result = PAX::BenchmarkMatrix->new(
        manifest_path => $manifest_path,
        iterations => $iterations,
        pax_bin => _pax_bin(),
    )->run;
    print _json($result, $pretty);
    return $result->{passed} ? 0 : 1;
}

sub _run_native {
    my ($class, @argv) = @_;
    my ($left, $right, $region, $pretty, $entrypoint) = (2, 3, undef, 1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--left') {
            $left = shift @argv // return _missing('--left');
            next;
        }
        if ($arg eq '--right') {
            $right = shift @argv // return _missing('--right');
            next;
        }
        if ($arg eq '--region') {
            $region = shift @argv // return _missing('--region');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $entrypoint) {
        print STDERR "run-native requires a Perl entrypoint\n";
        return 2;
    }

    my $capture = PAX::Capture->new(mode => 'live')->capture($entrypoint);
    my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
    my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;
    my $hir = PAX::HIR->new(manifest => $manifest, regions => $regions->{selected})->lower_all;
    my $ssa = PAX::GuardedSSA->new(hir_units => $hir)->build_all;
    my @artifacts = map { PAX::Tier1->new->compile($_) } @$ssa;
    my ($native) = grep { ($_->{entry_kind} // '') eq 'native_i64_leaf' && $_->{executable_path} } @artifacts;

    if (!$native) {
        print _json({
            status => 'fallback',
            reason => 'no callable native i64 artifact emitted',
            artifacts => \@artifacts,
        }, $pretty);
        return 1;
    }

    my $result = PAX::NativeRunner->new->run_i64_binary(
        path => $native->{executable_path},
        left => $left,
        right => $right,
        region_name => $region,
    );

    print _json({
        status => $result->{status},
        region_id => $native->{region_id},
        artifact => $native,
        args => [$left + 0, $right + 0],
        result => $result,
    }, $pretty);
    return $result->{status} eq 'ok' ? 0 : 1;
}

sub _corpus {
    my ($class, @argv) = @_;
    my ($pretty, $manifest_path) = (1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $manifest_path) {
            $manifest_path = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $manifest_path) {
        print STDERR "corpus requires a manifest path\n";
        return 2;
    }

    my $result = PAX::Corpus->new(manifest_path => $manifest_path)->run;
    print _json($result, $pretty);
    return $result->{passed} ? 0 : 1;
}

sub _core_suite {
    my ($class, @argv) = @_;
    my ($pretty, $manifest_path) = (1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $manifest_path) {
            $manifest_path = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $manifest_path) {
        print STDERR "core-suite requires a manifest path\n";
        return 2;
    }
    my $result = PAX::CoreSuite->new(manifest_path => $manifest_path)->run;
    print _json($result, $pretty);
    return $result->{passed} ? 0 : 1;
}

sub _cpan_matrix {
    my ($class, @argv) = @_;
    my ($pretty, $manifest_path) = (1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $manifest_path) {
            $manifest_path = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $manifest_path) {
        print STDERR "cpan-matrix requires a manifest path\n";
        return 2;
    }
    my $result = PAX::CPANMatrix->new(manifest_path => $manifest_path)->run;
    print _json($result, $pretty);
    return $result->{passed} ? 0 : 1;
}

sub _dispatch {
    my ($class, @argv) = @_;
    my ($left, $right, $region, $pretty, $entrypoint) = (2, 3, undef, 1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--left') {
            $left = shift @argv // return _missing('--left');
            next;
        }
        if ($arg eq '--right') {
            $right = shift @argv // return _missing('--right');
            next;
        }
        if ($arg eq '--region') {
            $region = shift @argv // return _missing('--region');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $entrypoint) {
        print STDERR "dispatch requires a Perl entrypoint\n";
        return 2;
    }

    my $result = PAX::RuntimeDispatcher->new->dispatch_i64(
        entrypoint => $entrypoint,
        left => $left,
        right => $right,
        region_name => $region,
    );
    print _json($result, $pretty);
    return $result->{status} eq 'native' ? 0 : 1;
}

sub _profile {
    my ($class, @argv) = @_;
    my ($iterations, $threshold, $region, $pretty, $entrypoint) = (3, 2, undef, 1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--iterations') {
            $iterations = shift @argv // return _missing('--iterations');
            next;
        }
        if ($arg eq '--threshold') {
            $threshold = shift @argv // return _missing('--threshold');
            next;
        }
        if ($arg eq '--region') {
            $region = shift @argv // return _missing('--region');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $entrypoint) {
        print STDERR "profile requires a Perl entrypoint\n";
        return 2;
    }
    my $store = PAX::ProfileStore->new(threshold => $threshold);
    my @events;
    my $dispatcher = PAX::RuntimeDispatcher->new(
        profile_store => $store,
        inline_cache => PAX::InlineCache->new,
        threshold => $threshold,
    );
    for (1 .. $iterations) {
        my $event = $dispatcher->dispatch_i64(
            entrypoint => $entrypoint,
            region_name => $region,
            left => 10,
            right => 32,
        );
        push @events, $event;
    }
    my $report = $store->report;
    $report->{events} = \@events;
    $report->{inline_cache} = $dispatcher->inline_cache_report;
    print _json($report, $pretty);
    return 0;
}

sub _why_not {
    my ($class, @argv) = @_;
    my ($region, $pretty, $entrypoint) = (undef, 1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--region') {
            $region = shift @argv // return _missing('--region');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $entrypoint) {
        print STDERR "why-not requires a Perl entrypoint\n";
        return 2;
    }

    my ($capture, $manifest, $regions, $hir, $ssa) = _pipeline($entrypoint);
    my @selected = @{ $regions->{selected} // [] };
    @selected = grep { ($_->{name} // '') eq $region || ($_->{name} // '') eq "main::$region" } @selected
        if defined $region;

    my @native_reasons;
    for my $unit (@$ssa) {
        next if defined $region && (($unit->{region_name} // '') ne $region && ($unit->{region_name} // '') ne "main::$region");
        my $artifact = PAX::Tier1->new->compile($unit);
        push @native_reasons, {
            region_id => $unit->{region_id},
            region_name => $unit->{region_name},
            entry_kind => $artifact->{entry_kind},
            status => $artifact->{status},
            reason => $artifact->{reason},
        };
    }

    print _json({
        command => 'why-not',
        entrypoint => $entrypoint,
        requested_region => $region,
        capture_status => $capture->{status},
        baseline_match => $manifest->{runtime}{baseline_match},
        compatibility => $manifest->{compatibility},
        selected_regions => \@selected,
        rejected_regions => $regions->{rejected},
        native_reasons => \@native_reasons,
        summary => _why_not_summary($manifest, \@selected, \@native_reasons),
    }, $pretty);
    return 0;
}

sub _trace_guards {
    my ($class, @argv) = @_;
    my ($region, $pretty, $entrypoint) = (undef, 1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--region') {
            $region = shift @argv // return _missing('--region');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $entrypoint) {
        print STDERR "trace-guards requires a Perl entrypoint\n";
        return 2;
    }

    my ($capture, $manifest, $regions, $hir, $ssa) = _pipeline($entrypoint);
    my $guard_manager = PAX::GuardManager->new(epochs => $manifest->{runtime_epochs});
    my @traces;
    for my $unit (@$ssa) {
        next if defined $region && (($unit->{region_name} // '') ne $region && ($unit->{region_name} // '') ne "main::$region");
        my $result = ($unit->{status} // '') eq 'fallback'
            ? { status => 'deopt' }
            : $guard_manager->validate_or_deopt($unit);
        push @traces, {
            region_id => $unit->{region_id},
            region_name => $unit->{region_name},
            status => $result->{status},
            guards => $unit->{guards},
            deopt => $unit->{deopt},
        };
    }

    print _json({
        command => 'trace-guards',
        entrypoint => $entrypoint,
        requested_region => $region,
        baseline_match => $manifest->{runtime}{baseline_match},
        traces => \@traces,
        telemetry => $guard_manager->telemetry,
    }, $pretty);
    return 0;
}

sub _gatekeeper {
    my ($class, @argv) = @_;
    my ($pretty) = 1;
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    my $report = PAX::Gatekeeper->new(root => '.')->sow01_report;
    print _json($report, $pretty);
    return $report->{status} eq 'passed' ? 0 : 1;
}

sub _pipeline {
    my ($entrypoint) = @_;
    my $capture = PAX::Capture->new(mode => 'live')->capture($entrypoint);
    my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
    my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;
    my $hir = PAX::HIR->new(manifest => $manifest, regions => $regions->{selected})->lower_all;
    my $ssa = PAX::GuardedSSA->new(hir_units => $hir)->build_all;
    return ($capture, $manifest, $regions, $hir, $ssa);
}

sub _why_not_summary {
    my ($manifest, $selected, $native_reasons) = @_;
    return 'runtime baseline mismatch blocks native acceleration'
        if !$manifest->{runtime}{baseline_match};
    return 'compatibility barriers require guarded or fallback execution'
        if @{ $manifest->{compatibility}{barriers} // [] };
    return 'requested region was not selected'
        if !@$selected;
    my @fallback = grep { ($_->{entry_kind} // '') !~ /\Anative_i64_(?:leaf|loop)\z/ } @$native_reasons;
    return $fallback[0]{reason} if @fallback;
    return 'region is native-capable in the current SOW-01 implementation';
}

sub _pax_bin {
    require FindBin;
    no warnings 'once';
    return "$FindBin::Bin/pax";
}

sub _app_build {
    my ($class, @argv) = @_;
    my ($name, $paxfile, $no_paxfile, $pretty, @libs, @assets, @asset_dirs, $entrypoint) = (undef, 'paxfile.yml', 0, 1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--name') {
            $name = shift @argv // return _missing('--name');
            next;
        }
        if ($arg eq '--paxfile') {
            $paxfile = shift @argv // return _missing('--paxfile');
            next;
        }
        if ($arg eq '--no-paxfile') {
            $no_paxfile = 1;
            next;
        }
        if ($arg eq '--lib') {
            push @libs, shift @argv // return _missing('--lib');
            next;
        }
        if ($arg eq '--asset') {
            push @assets, shift @argv // return _missing('--asset');
            next;
        }
        if ($arg eq '--asset-dir') {
            push @asset_dirs, shift @argv // return _missing('--asset-dir');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    my $cfg = $no_paxfile ? {} : PAX::Paxfile->load_optional($paxfile);
    $entrypoint //= $cfg->{entrypoint};
    if (!defined $entrypoint) {
        print STDERR "app-build requires a Perl entrypoint or paxfile.yml entrypoint\n";
        return 2;
    }
    $name //= $cfg->{name};
    @libs = @{ $cfg->{libs} // [] } if !@libs;
    @assets = @{ $cfg->{assets} // [] } if !@assets;
    @asset_dirs = @{ $cfg->{asset_dirs} // [] } if !@asset_dirs;
    my $result = PAX::AppImage->new->build(
        name => $name,
        entrypoint => $entrypoint,
        lib_dirs => \@libs,
        assets => \@assets,
        asset_dirs => \@asset_dirs,
    );
    print _json($result, $pretty);
    return 0;
}

sub _app_start {
    my ($class, @argv) = @_;
    my ($name, $daemonize, $pretty) = (undef, 0, 1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--name') {
            $name = shift @argv // return _missing('--name');
            next;
        }
        if ($arg eq '--daemonize') {
            $daemonize = 1;
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $name) {
        print STDERR "app-start requires --name\n";
        return 2;
    }
    my $image = PAX::AppImage->new->load(name => $name);
    if ($daemonize) {
        PAX::AppServer->new(image => $image)->start(daemonize => 1);
        print _json({ status => 'started', name => $name, socket_path => $image->{socket_path} }, $pretty);
        return 0;
    }
    return PAX::AppServer->new(image => $image)->start;
}

sub _app_run {
    my ($class, @argv) = @_;
    my $name;
    if (@argv && $argv[0] eq '--name') {
        shift @argv;
        $name = shift @argv // return _missing('--name');
    }
    if (@argv && $argv[0] eq '--') {
        shift @argv;
    }
    if (!defined $name) {
        print STDERR "app-run requires --name\n";
        return 2;
    }
    my $image = PAX::AppImage->new->load(name => $name);
    return PAX::AppServer->run_client(image => $image, argv => \@argv);
}

sub _app_stop {
    my ($class, @argv) = @_;
    my $name;
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--name') {
            $name = shift @argv // return _missing('--name');
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $name) {
        print STDERR "app-stop requires --name\n";
        return 2;
    }
    my $image = PAX::AppImage->new->load(name => $name);
    return PAX::AppServer->stop(image => $image);
}

sub _standalone_build {
    my ($class, @argv) = @_;
    return $class->_build_standalone(@argv);
}

sub _standalone_build_config {
    my ($class, @argv) = @_;
    my (
        $name, $paxfile, $no_paxfile, $pretty, $entrypoint, $output, $runtime_mode,
        $app_name, $app_namespace, $app_entrypoint_env, $app_entrypoint_fallback, $app_command
    ) = (undef, 'paxfile.yml', 0, 1, undef, undef, undef, undef, undef, undef, undef);
    my $entrypoint_from_cli = 0;
    my $inline_eval_from_cli = 0;
    my $paxfile_from_cli = 0;
    my (@libs, @assets, @asset_dirs, @source_roots, @cpanfiles, @override_fields, @perl_libs, @perl_modules, @inline_eval_parts);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '-I') {
            push @perl_libs, shift @argv // return _missing('-I');
            push @override_fields, 'perl_libs';
            next;
        }
        if ($arg =~ /\A-I(.+)\z/) {
            push @perl_libs, $1;
            push @override_fields, 'perl_libs';
            next;
        }
        if ($arg eq '-M') {
            push @perl_modules, shift @argv // return _missing('-M');
            push @override_fields, 'perl_modules';
            next;
        }
        if ($arg =~ /\A-M(.+)\z/) {
            push @perl_modules, $1;
            push @override_fields, 'perl_modules';
            next;
        }
        if ($arg eq '-e') {
            push @inline_eval_parts, shift @argv // return _missing('-e');
            $inline_eval_from_cli = 1;
            push @override_fields, 'inline_eval';
            next;
        }
        if ($arg eq '--name') {
            $name = shift @argv // return _missing('--name');
            push @override_fields, 'name';
            next;
        }
        if ($arg eq '--paxfile') {
            $paxfile = shift @argv // return _missing('--paxfile');
            $paxfile_from_cli = 1;
            next;
        }
        if ($arg eq '--no-paxfile') {
            $no_paxfile = 1;
            next;
        }
        if ($arg eq '--lib') {
            push @libs, shift @argv // return _missing('--lib');
            push @override_fields, 'libs';
            next;
        }
        if ($arg eq '--source-root') {
            push @source_roots, shift @argv // return _missing('--source-root');
            push @override_fields, 'source_roots';
            next;
        }
        if ($arg eq '--asset') {
            push @assets, shift @argv // return _missing('--asset');
            push @override_fields, 'assets';
            next;
        }
        if ($arg eq '--asset-dir') {
            push @asset_dirs, shift @argv // return _missing('--asset-dir');
            push @override_fields, 'asset_dirs';
            next;
        }
        if ($arg eq '--cpanfile') {
            push @cpanfiles, shift @argv // return _missing('--cpanfile');
            push @override_fields, 'cpanfiles';
            next;
        }
        if ($arg eq '--output' || $arg eq '-o') {
            $output = shift @argv // return _missing('--output');
            push @override_fields, 'output';
            next;
        }
        if ($arg eq '--runtime-mode') {
            $runtime_mode = shift @argv // return _missing('--runtime-mode');
            push @override_fields, 'runtime_mode';
            next;
        }
        if ($arg eq '--app-name') {
            $app_name = shift @argv // return _missing('--app-name');
            push @override_fields, 'app_name';
            next;
        }
        if ($arg eq '--app-namespace') {
            $app_namespace = shift @argv // return _missing('--app-namespace');
            push @override_fields, 'app_namespace';
            next;
        }
        if ($arg eq '--app-entrypoint-env') {
            $app_entrypoint_env = shift @argv // return _missing('--app-entrypoint-env');
            push @override_fields, 'app_entrypoint_env';
            next;
        }
        if ($arg eq '--app-entrypoint-fallback') {
            $app_entrypoint_fallback = shift @argv // return _missing('--app-entrypoint-fallback');
            push @override_fields, 'app_entrypoint_fallback';
            next;
        }
        if ($arg eq '--app-command') {
            $app_command = shift @argv // return _missing('--app-command');
            push @override_fields, 'app_command';
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        if (!defined $entrypoint) {
            $entrypoint = $arg;
            $entrypoint_from_cli = 1;
            push @override_fields, 'entrypoint';
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }

    my $cfg = $no_paxfile ? {} : PAX::Paxfile->load_optional($paxfile);
    if (defined $entrypoint && @inline_eval_parts) {
        print STDERR "standalone-build cannot accept both an entrypoint and -e\n";
        return 2;
    }
    $entrypoint //= $cfg->{entrypoint} if !@inline_eval_parts;
    if (!defined $entrypoint && !@inline_eval_parts) {
        print STDERR "standalone-build requires a Perl entrypoint or paxfile.yml entrypoint\n";
        return 2;
    }
    my $use_paxfile_defaults = ($entrypoint_from_cli || $inline_eval_from_cli) ? $paxfile_from_cli : 1;
    if ($use_paxfile_defaults) {
        $name //= $cfg->{name};
        @libs = @{ $cfg->{libs} // [] } if !@libs;
        @source_roots = @{ $cfg->{source_roots} // [] } if !@source_roots;
        @assets = @{ $cfg->{assets} // [] } if !@assets;
        @asset_dirs = @{ $cfg->{asset_dirs} // [] } if !@asset_dirs;
        @cpanfiles = @{ $cfg->{cpanfiles} // [] } if !@cpanfiles;
        $output //= $cfg->{output};
        $runtime_mode //= $cfg->{runtime_mode};
        $app_name //= $cfg->{app_name};
        $app_namespace //= $cfg->{app_namespace};
        $app_entrypoint_env //= $cfg->{app_entrypoint_env};
        $app_entrypoint_fallback //= $cfg->{app_entrypoint_fallback};
        $app_command //= $cfg->{app_command};
    }

    return {
        name => $name,
        paxfile => $paxfile,
        no_paxfile => $no_paxfile,
        pretty => $pretty,
        entrypoint => $entrypoint,
        inline_eval => @inline_eval_parts ? join("\n", @inline_eval_parts) : undef,
        output => $output,
        runtime_mode => $runtime_mode,
        app_name => $app_name,
        app_namespace => $app_namespace,
        app_entrypoint_env => $app_entrypoint_env,
        app_entrypoint_fallback => $app_entrypoint_fallback,
        app_command => $app_command,
        libs => \@libs,
        source_roots => \@source_roots,
        assets => \@assets,
        asset_dirs => \@asset_dirs,
        cpanfiles => \@cpanfiles,
        perl_libs => \@perl_libs,
        perl_modules => \@perl_modules,
        override_fields => [ sort @override_fields ],
        paxfile_applied => $no_paxfile ? 0 : (($use_paxfile_defaults && -f $paxfile) ? 1 : 0),
    };
}

sub _build_standalone {
    my ($class, @argv) = @_;
    my $cfg = $class->_standalone_build_config(@argv);
    return $cfg if !ref($cfg);
    my $build = $class->_standalone_build_from_config($cfg);
    print _json($build->{result}, $build->{pretty});
    return $build->{result}{status} eq 'built' ? 0 : 1;
}

sub _standalone_build_from_config {
    my ($class, $cfg) = @_;
    my $progress = $class->_standalone_build_progress;
    my ($entrypoint, $cleanup_path) = $class->_standalone_materialize_entrypoint($cfg);
    my @lib_dirs = (@{ $cfg->{perl_libs} // [] }, @{ $cfg->{libs} // [] });
    my $result = eval {
        PAX::StandaloneImage->new->build(
            name => $cfg->{name},
            entrypoint => $entrypoint,
            lib_dirs => \@lib_dirs,
            source_roots => $cfg->{source_roots},
            assets => $cfg->{assets},
            asset_dirs => $cfg->{asset_dirs},
            cpanfiles => $cfg->{cpanfiles},
            output_path => $cfg->{output},
            runtime_mode => $cfg->{runtime_mode},
            app_name => $cfg->{app_name},
            app_namespace => $cfg->{app_namespace},
            app_entrypoint_env => $cfg->{app_entrypoint_env},
            app_entrypoint_fallback => $cfg->{app_entrypoint_fallback},
            app_command => $cfg->{app_command},
            paxfile_applied => $cfg->{paxfile_applied},
            override_fields => $cfg->{override_fields},
            progress => $progress ? $progress->callback : undef,
        );
    };
    my $error = $@;
    unlink $cleanup_path if defined $cleanup_path && -f $cleanup_path;
    $progress->finish if $progress;
    die $error if $error;
    return {
        result => $result,
        pretty => $cfg->{pretty},
    };
}

sub _standalone_materialize_entrypoint {
    my ($class, $cfg) = @_;
    return ($cfg->{entrypoint}, undef) if !defined $cfg->{inline_eval};
    my ($fh, $path) = File::Temp::tempfile('pax-inline-entrypoint-XXXXXX', TMPDIR => 1, SUFFIX => '.pl', UNLINK => 0);
    print {$fh} $class->_standalone_inline_entrypoint_source($cfg);
    close $fh or die "unable to close inline entrypoint $path: $!";
    return ($path, $path);
}

sub _standalone_inline_entrypoint_source {
    my ($class, $cfg) = @_;
    my @lines = (
        "#!/usr/bin/env perl",
        "use strict;",
        "use warnings;",
    );
    for my $lib (@{ $cfg->{perl_libs} // [] }) {
        push @lines, 'use lib ' . _perl_single_quote($lib) . ';';
    }
    for my $spec (@{ $cfg->{perl_modules} // [] }) {
        my ($module, @imports) = _parse_perl_module_switch($spec);
        my $import_args = join(', ', map { _perl_single_quote($_) } @imports);
        my $call = @imports ? "$module->import($import_args);" : "$module->import();";
        push @lines, "BEGIN { require $module; $call }";
    }
    push @lines, $cfg->{inline_eval};
    push @lines, '';
    return join("\n", @lines);
}

sub _parse_perl_module_switch {
    my ($spec) = @_;
    my ($module, $imports) = split /=/, $spec, 2;
    my @imports = defined $imports && length $imports
        ? split /,/, $imports
        : ();
    return ($module, @imports);
}

sub _perl_single_quote {
    my ($value) = @_;
    $value //= '';
    $value =~ s/\\/\\\\/g;
    $value =~ s/'/\\'/g;
    return "'$value'";
}

sub _standalone_build_progress {
    my ($class) = @_;
    my $enabled = exists $ENV{PAX_PROGRESS}
        ? ($ENV{PAX_PROGRESS} ? 1 : 0)
        : 1;
    return if !$enabled;
    return PAX::CLI::Progress->new(
        title   => 'pax build progress',
        tasks   => PAX::StandaloneImage->build_progress_tasks,
        stream  => \*STDERR,
        dynamic => ( -t STDERR ? 1 : 0 ),
        color   => ( -t STDERR ? 1 : 0 ),
    );
}

sub _standalone_run {
    my ($class, @argv) = @_;
    my ($name, @cmd) = (undef);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--name') {
            $name = shift @argv // return _missing('--name');
            next;
        }
        if ($arg eq '--') {
            push @cmd, @argv;
            last;
        }
        push @cmd, $arg;
    }
    if (!defined $name) {
        print STDERR "standalone-run requires --name\n";
        return 2;
    }
    my $image = PAX::StandaloneImage->new->load(name => $name);
    my @exec = ($image->{output_path}, @cmd);
    system { $exec[0] } @exec;
    return $? >> 8;
}

sub _run_standalone {
    my ($class, @argv) = @_;
    my (@build_args, @cmd);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--') {
            push @cmd, @argv;
            last;
        }
        push @build_args, $arg;
    }
    my $cfg = $class->_standalone_build_config(@build_args);
    return $cfg if !ref($cfg);
    my $build = $class->_standalone_build_from_config($cfg);
    return 1 if ($build->{result}{status} // '') ne 'built';
    my $output_path = $build->{result}{standalone}{output_path};
    my @exec = ($output_path, @cmd);
    system { $exec[0] } @exec;
    return $? >> 8;
}

sub _standalone_inspect {
    my ($class, @argv) = @_;
    my ($name, $pretty) = (undef, 1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--name') {
            $name = shift @argv // return _missing('--name');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $name) {
        print STDERR "standalone-inspect requires --name\n";
        return 2;
    }
    my $image = PAX::StandaloneImage->new->load(name => $name);
    print _json($image, $pretty);
    return 0;
}

sub _standalone_extract {
    my ($class, @argv) = @_;
    my ($name, $output) = (undef, undef);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--name') {
            $name = shift @argv // return _missing('--name');
            next;
        }
        if ($arg eq '--output') {
            $output = shift @argv // return _missing('--output');
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $name) {
        print STDERR "standalone-extract requires --name\n";
        return 2;
    }
    if (!defined $output) {
        print STDERR "standalone-extract requires --output\n";
        return 2;
    }
    my $image = PAX::StandaloneImage->new->load(name => $name);
    system { $image->{output_path} } $image->{output_path}, '--pax-standalone-extract', $output;
    return $? >> 8;
}

sub _standalone_why_not {
    my ($class, @argv) = @_;
    my ($name, $pretty) = (undef, 1);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--name') {
            $name = shift @argv // return _missing('--name');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $name) {
        print STDERR "standalone-why-not requires --name\n";
        return 2;
    }
    my $image = PAX::StandaloneImage->new->load(name => $name);
    my @missing = grep { ($_->{class} // '') eq 'missing' } @{ $image->{dependencies} // [] };
    my @fallback = grep { ($_->{status} // '') ne 'native_artifact' && ($_->{entry_kind} // '') !~ /\Anative_i64_(?:leaf|loop)\z/ } @{ $image->{native_artifacts} // [] };
    my @source_fallback = grep { ($_->{packaging} // '') eq 'source_payload_fallback' } @{ $image->{code_units} // [] };
    my $report = {
        name => $name,
        standalone_ready => (@missing == 0) ? JSON::PP::true() : JSON::PP::false(),
        bundled_runtime => $image->{runtime}{mode},
        missing_dependencies => [ map {
            {
                module => $_->{module},
                provider => $_->{provider},
            }
        } @missing ],
        native_not_packaged => [ map {
            {
                region_name => $_->{region_name},
                entry_kind => $_->{entry_kind},
                reason => $_->{reason},
            }
        } @fallback ],
        source_fallback_units => [ map {
            {
                logical_path => $_->{logical_path},
                unit_kind => $_->{unit_kind},
                reason => $_->{fallback_reason},
                detail => $_->{fallback_detail},
            }
        } @source_fallback ],
    };
    print _json($report, $pretty);
    return 0;
}

sub _standalone_native_run {
    my ($class, @argv) = @_;
    my ($name, $region, $left, $right, $pretty) = (undef, undef, 0, 0, 1);
    my @invalidate;
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--name') {
            $name = shift @argv // return _missing('--name');
            next;
        }
        if ($arg eq '--region') {
            $region = shift @argv // return _missing('--region');
            next;
        }
        if ($arg eq '--left') {
            $left = shift @argv // return _missing('--left');
            next;
        }
        if ($arg eq '--right') {
            $right = shift @argv // return _missing('--right');
            next;
        }
        if ($arg eq '--invalidate') {
            push @invalidate, shift @argv // return _missing('--invalidate');
            next;
        }
        if ($arg eq '--compact') {
            $pretty = 0;
            next;
        }
        print STDERR "unexpected argument: $arg\n";
        return 2;
    }
    if (!defined $name) {
        print STDERR "standalone-native-run requires --name\n";
        return 2;
    }
    if (!defined $region) {
        print STDERR "standalone-native-run requires --region\n";
        return 2;
    }
    my $result = PAX::StandaloneDispatch->new->run_i64(
        name => $name,
        region_name => $region,
        left => $left,
        right => $right,
        invalidate => \@invalidate,
    );
    print _json($result, $pretty);
    return (($result->{status} // '') eq 'native' || ($result->{result}{status} // '') eq 'ok') ? 0 : 1;
}

sub _missing {
    my ($flag) = @_;
    print STDERR "$flag requires a value\n";
    return 2;
}

sub _json {
    my ($data, $pretty) = @_;
    my $json = JSON::PP->new->ascii(1)->canonical(1);
    $json = $json->pretty(1) if $pretty;
    return $json->encode($data);
}

sub _usage {
    return <<'USAGE';
usage:
  pax build ...
  pax run ...
USAGE
}

1;

__END__

=head1 NAME

PAX::CLI - public PAX command facade

=head1 SYNOPSIS

  use PAX::CLI;

  exit PAX::CLI->run(@ARGV);

=head1 DESCRIPTION

C<PAX::CLI> implements the SOW-03 public command surface for C<bin/pax>. The
only public commands are C<build>, C<run>, and help aliases. Older diagnostic
handlers remain private implementation methods so tests and internal modules can
reuse them without exposing them as user CLI commands.

=head1 PUBLIC COMMANDS

=head2 build

Reads CLI options and optional C<paxfile.yml> defaults, then builds a standalone
executable through C<PAX::StandaloneImage>.

=head2 run

Uses the same build configuration path as C<build>, then executes the resulting
standalone binary with arguments after C<-->.

=head1 PURPOSE

This module keeps the public command contract, option parsing, interpreter
mode, and user-facing error handling in one place so C<bin/pax> can stay thin.

=head1 HOW TO USE

Route all public CLI execution through C<run>. Keep internal diagnostics and
legacy helpers private to the module layer instead of reopening the public
command surface.

=cut
