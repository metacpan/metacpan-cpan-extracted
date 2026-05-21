package PAX::StandaloneAnalysis;

our $VERSION = '0.031';

use strict;
use warnings;
use Cwd qw(abs_path);
use File::Spec;
use JSON::PP ();
use PAX::Capture;
use PAX::Manifest;
use PAX::RegionSelector;
use PAX::HIR;
use PAX::GuardedSSA;
use PAX::Tier1;

sub new {
    my ($class, %args) = @_;
    return bless {}, $class;
}

sub dependencies {
    my ($self, %args) = @_;
    my $entrypoint = $args{entrypoint} // die 'entrypoint required';
    my $code_units = $args{code_units} // [];
    my $cpanfiles = $args{cpanfiles} // [];

    my %modules;
    my @seed_modules;
    for my $unit (@$code_units) {
        my $source = _analysis_source(_slurp($unit->{source_path}));
        for my $module (_source_module_refs($source)) {
            $modules{$module}{used_in_code} = 1;
            push @seed_modules, $module;
        }
    }

    for my $cpanfile (@$cpanfiles) {
        my $source = _slurp($cpanfile);
        while ($source =~ /^\s*(requires|recommends)\s+['"]([A-Za-z_][A-Za-z0-9_:]*)['"]/gm) {
            my ($kind, $module) = ($1, $2);
            push @{ $modules{$module}{declared_in_cpanfile} }, {
                type => $kind,
                path => $cpanfile,
            };
        }
    }

    my %packaged = map {
        my $name = _module_name_from_path($_->{source_path});
        defined $name ? ($name => $_) : ()
    } grep { ($_->{unit_kind} // '') eq 'lib' || ($_->{unit_kind} // '') eq 'dependency' } @$code_units;
    _expand_dependency_closure(\%modules, \@seed_modules, \%packaged);
    my @items;
    my %summary = (
        packaged_app => 0,
        compiled_dependency => 0,
        bundled_pure_perl => 0,
        bundled_xs => 0,
        missing => 0,
        unsupported => 0,
    );

    for my $module (sort keys %modules) {
        my %item = (
            module => $module,
            declared_in_cpanfile => $modules{$module}{declared_in_cpanfile} // [],
            used_in_code => $modules{$module}{used_in_code} ? JSON::PP::true() : JSON::PP::false(),
        );
        if (my $packaged = $packaged{$module}) {
            if (($packaged->{unit_kind} // '') eq 'dependency') {
                $item{class} = 'compiled_dependency';
                $item{provider} = 'pax_compiler';
                $summary{compiled_dependency}++;
            } else {
                $item{class} = 'packaged_app';
                $item{provider} = 'application';
                $summary{packaged_app}++;
            }
            $item{source_path} = $packaged->{source_path};
            $item{packaging} = $packaged->{packaging};
        } else {
            my $path = _locate_module($module);
            if (!$path) {
                $item{class} = 'missing';
                $item{provider} = 'unresolved';
                $summary{missing}++;
            } else {
                my $xs = _module_uses_xs($path);
                $item{class} = $xs ? 'bundled_xs' : 'bundled_pure_perl';
                $item{provider} = 'bundled_runtime';
                $item{source_path} = $path;
                $item{xs} = $xs ? JSON::PP::true() : JSON::PP::false();
                $summary{$item{class}}++;
            }
        }
        push @items, \%item;
    }

    return {
        items => \@items,
        summary => \%summary,
    };
}

sub _analysis_source {
    my ($source) = @_;
    $source //= '';
    $source =~ s/^__(?:END|DATA)__\b.*\z//ms;
    $source =~ s/^=\w+.*?^=cut\s*\n?//msg;
    return $source;
}

sub _source_module_refs {
    my ($source) = @_;
    my @modules;
    while ($source =~ /^\s*use\s+([A-Z][A-Za-z0-9_:]*)\b/gm) {
        my $module = $1;
        next if !_is_dependency_candidate($module);
        push @modules, $module;
    }
    while ($source =~ /^\s*require\s+([A-Z][A-Za-z0-9_:]*)\b/gm) {
        my $module = $1;
        next if !_is_dependency_candidate($module);
        push @modules, $module;
    }
    my %seen;
    return grep { !$seen{$_}++ } @modules;
}

sub _is_dependency_candidate {
    my ($module) = @_;
    return 0 if !defined $module || length($module) < 2;
    return 0 if $module =~ /^(?:strict|warnings|utf8|lib|parent|base|constant|feature)$/;
    return 1;
}

sub _expand_dependency_closure {
    my ($modules, $seed_modules, $packaged) = @_;
    my @queue = grep { defined && $_ ne '' } @$seed_modules;
    my %seen_module;
    my %scanned_path;

    while (@queue) {
        my $module = shift @queue;
        next if $seen_module{$module}++;
        my $path = $packaged->{$module} ? $packaged->{$module}{source_path} : _locate_module($module);
        next if !$path || $scanned_path{$path}++;
        my $source = _analysis_source(_slurp($path));
        for my $child (_source_module_refs($source)) {
            $modules->{$child}{used_in_code} = 1 if !exists $modules->{$child}{used_in_code};
            next if $seen_module{$child};
            push @queue, $child;
        }
    }
}

sub native_artifacts {
    my ($self, %args) = @_;
    my $entrypoint = $args{entrypoint} // die 'entrypoint required';
    my $code_units = $args{code_units} // [];
    my $static_units = _static_native_units_from_code_units($code_units);
    if (@$static_units) {
        return _native_artifacts_from_units($static_units, _default_runtime_epochs());
    }
    my @probe_paths = _native_probe_paths($entrypoint, $code_units);
    return { items => [], summary => { native_ready => 0, fallback_only => 0, total => 0 }, runtime_epochs => undef }
        if !_native_probe_worthwhile(\@probe_paths);
    my $capture = eval { PAX::Capture->new(mode => 'live')->capture($entrypoint) };
    return {
        items => [],
        summary => { native_ready => 0, fallback_only => 0, total => 0 },
        diagnostics => [{
            level => 'warning',
            code => 'native_capture_failed',
            message => "$@",
        }],
        runtime_epochs => undef,
    } if !$capture || $@;
    return { items => [], summary => { native_ready => 0, fallback_only => 0, total => 0 } }
        if ($capture->{status} ne 'ok');

    my ($manifest, $regions, $hir, $ssa) = eval {
        my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
        my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;
        my $hir = PAX::HIR->new(manifest => $manifest, regions => $regions->{selected})->lower_all;
        my $ssa = PAX::GuardedSSA->new(hir_units => $hir)->build_all;
        ($manifest, $regions, $hir, $ssa);
    };
    return {
        items => [],
        summary => { native_ready => 0, fallback_only => 0, total => 0 },
        diagnostics => [{
            level => 'warning',
            code => 'native_analysis_failed',
            message => "$@",
        }],
        runtime_epochs => undef,
    } if $@;

    return _native_artifacts_from_units($ssa, $manifest->{runtime_epochs});
}

# Convert compiled unit metadata into the standalone native-artifact summary
# without requiring a fresh live capture step.
sub _native_artifacts_from_units {
    my ($units, $runtime_epochs) = @_;
    my @items;
    my %summary = (
        total => 0,
        native_ready => 0,
        fallback_only => 0,
    );
    for my $unit (@$units) {
        my $artifact = PAX::Tier1->new(out_dir => '.pax/standalone-native')->compile($unit);
        my %item = (
            region_id => $unit->{region_id},
            region_name => $unit->{region_name},
            status => $artifact->{status},
            entry_kind => $artifact->{entry_kind},
            reason => $artifact->{reason},
            guards => $unit->{guards} // [],
            deopt => $unit->{deopt} // {},
            tier2_artifact => $artifact->{tier2_artifact},
        );
        if (($artifact->{entry_kind} // '') =~ /\Anative_i64_(?:leaf|loop)\z/ && $artifact->{executable_path}) {
            $item{executable_path} = $artifact->{executable_path};
            $item{library_path} = $artifact->{library_path};
            $summary{native_ready}++;
        } else {
            $summary{fallback_only}++;
        }
        $summary{total}++;
        push @items, \%item;
    }

    return {
        items => \@items,
        summary => \%summary,
        runtime_epochs => $runtime_epochs,
    };
}

# Scan packaged code units for native-capable sub metadata that can be promoted
# into standalone dispatch artifacts.
sub _static_native_units_from_code_units {
    my ($code_units) = @_;
    my @units;
    my $index = 0;
    for my $unit (@$code_units) {
        next if ref($unit) ne 'HASH';
        my $bytes = $unit->{bytes};
        next if !defined $bytes || $bytes eq '';
        my $record = eval { JSON::PP::decode_json($bytes) };
        next if !$record || ref($record) ne 'HASH';
        my @subs = (
            @{ $record->{subs} // [] },
            @{ $record->{compiled_subs} // [] },
        );
        for my $sub (@subs) {
            next if ref($sub) ne 'HASH';
            my $shape = $sub->{native_shape};
            next if ref($shape) ne 'HASH' || !%$shape;
            my $full_name = $sub->{full_name} // do {
                my $package = $record->{package} // 'main';
                my $name = $sub->{name} // next;
                $package . '::' . $name;
            };
            push @units, {
                region_id => sprintf('static-region-%04d', ++$index),
                region_name => $full_name,
                native_shape => $shape,
                source => {
                    native_shape => $shape,
                },
                guards => _default_guards(),
                deopt => {
                    safepoint => sprintf('static-region-%04d:entry', $index),
                },
            };
        }
    }
    return \@units;
}

# Seed static standalone artifacts with the baseline epoch set used by guarded
# runtime dispatch.
sub _default_runtime_epochs {
    return {
        package_symbols => 1,
        method_resolution => 1,
        loaded_modules => 1,
    };
}

# Provide the default guard set for static native artifacts derived from
# compiled-unit metadata.
sub _default_guards {
    return [
        map +{
            id => 'guard_' . $_,
            predicate => $_ . '_epoch_unchanged',
            invalidation_key => $_,
            compatibility_classification => 'guarded',
        }, qw(package_symbols method_resolution loaded_modules)
    ];
}

sub _native_probe_paths {
    my ($entrypoint, $code_units) = @_;
    my %seen;
    my @paths = grep { defined && !$seen{$_}++ } (
        $entrypoint,
        map { $_->{source_path} } @$code_units,
    );
    return @paths;
}

sub _native_probe_worthwhile {
    my ($paths) = @_;
    for my $path (@$paths) {
        next if !$path || !-f $path;
        my $source = _slurp($path);
        next if !defined $source || $source eq '';
        return 1 if _source_has_native_candidate($source);
    }
    return 0;
}

sub _source_has_native_candidate {
    my ($source) = @_;
    return 1 if $source =~ /sub\s+\w+\s*\{[^{}]*my\s*\(\s*\$\w+\s*,\s*\$\w+\s*\)\s*=\s*\@_;[^{}]*return\s+\$\w+\s*(?:\+|\-|\*)\s*\$\w+\s*;/ms;
    return 1 if $source =~ /sub\s+\w+\s*\{[^{}]*for\s*\(.*?;.*?;.*?\)\s*\{[^{}]*\$\w+\s*(?:\+=|\-=|\*=)\s*\$\w+/ms;
    return 1 if $source =~ /sub\s+\w+\s*\{[^{}]*while\s*\(.*?\)\s*\{[^{}]*\$\w+\s*(?:\+=|\-=|\*=)\s*\$\w+/ms;
    return 0;
}

sub _module_name_from_path {
    my ($path) = @_;
    return undef if !$path || $path !~ /\.pm$/;
    my $abs = abs_path($path) || $path;
    for my $inc (@INC) {
        next if ref $inc;
        my $inc_abs = abs_path($inc) || $inc;
        next if index($abs, $inc_abs . '/') != 0;
        my $rel = substr($abs, length($inc_abs) + 1);
        $rel =~ s/\.pm$//;
        $rel =~ s{/}{::}g;
        return $rel if $rel ne '';
    }
    my @parts = File::Spec->splitdir($abs);
    for my $i (0 .. $#parts) {
        if ($parts[$i] eq 'lib' && $i < $#parts) {
            my @tail = @parts[$i + 1 .. $#parts];
            my $name = join('::', @tail);
            $name =~ s/\.pm$//;
            return $name if $name ne '';
        }
    }
    my $name = $parts[-1];
    $name =~ s/\.pm$//;
    return $name;
}

sub _locate_module {
    my ($module) = @_;
    my $rel = $module;
    $rel =~ s{::}{/}g;
    $rel .= '.pm';
    for my $inc (@INC) {
        next if ref $inc;
        my $path = File::Spec->catfile($inc, $rel);
        return abs_path($path) || $path if -f $path;
    }
    return;
}

sub _module_uses_xs {
    my ($path) = @_;
    my $source = _slurp($path);
    return 1 if $source =~ /\b(?:XSLoader|DynaLoader)\b/;
    my $base = $path;
    $base =~ s/\.pm$//;
    for my $ext (qw(so bundle dll)) {
        return 1 if -f "$base.$ext";
    }
    return 0;
}

sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or return '';
    local $/;
    return <$fh> // '';
}

1;

=pod

=head1 NAME

PAX::StandaloneAnalysis - standalone dependency and payload analyzer

=head1 SYNOPSIS

  use PAX::StandaloneAnalysis;

  my $obj = PAX::StandaloneAnalysis->new(...);
  my $result = $obj->dependencies(...);

=head1 DESCRIPTION

Analyzes application source, Perl dependencies, XS/native payloads, and runtime helper requirements for standalone bundles.

=head1 METHODS

=head2 new, dependencies, native_artifacts

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the standalone dependency and payload analyzer logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs standalone dependency and payload analyzer. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects standalone dependency and payload analyzer, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover standalone dependency and payload analyzer.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::StandaloneAnalysis -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
