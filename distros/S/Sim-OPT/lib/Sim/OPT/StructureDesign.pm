package Sim::OPT::StructureDesign;

use strict;
use warnings;
use Exporter 'import';
use File::Basename qw(dirname basename);
use File::Path qw(make_path);
use File::Copy qw(copy);
use File::Find qw(find);
use JSON::PP ();

our $VERSION = '0.14';
our @EXPORT_OK = qw(
    parse_instance format_instance
    abstraction_distance apply_abstraction_model
    map_memory_instance_to_source map_source_instance_to_memory
    refined_level_count rescale_level rescale_instance
    inspect_config plan_zoom_in render_zoom_config
    memory_level_count plan_memory_reconstruction render_memory_config create_memory_workspace
    plan_enlarge_pan render_enlarge_pan_config validate_enlarge_pan_config_text
    write_manifest create_zoom_workspace create_enlarge_pan_workspace
    map_local_instance_to_global
    rewrite_clear_instances_in_text
    resolve_incumbent_model
    render_refined_parent_config validate_refined_parent_config_text
    render_cloned_state_config validate_cloned_state_config_text
    plan_zoom_out_merge scan_max_short_id
);

# -------------------------------------------------------------------------
# Pure lattice/name functions
# -------------------------------------------------------------------------

sub parse_instance {
    my ($s) = @_;
    die "parse_instance: undefined instance\n" unless defined $s;

    my %h;
    while ($s =~ /(?:^|_)(\d+)-(\d+)(?=_|$)/g) {
        $h{0 + $1} = 0 + $2;
    }
    die "parse_instance: no variable-level pairs in '$s'\n" unless keys %h;
    return \%h;
}

sub format_instance {
    my ($h) = @_;
    die "format_instance: HASH reference required\n" unless ref($h) eq 'HASH';
    return join('_', map { $_ . '-' . $h->{$_} } sort { $a <=> $b } keys %$h);
}

sub _abstraction_clamp01 {
    my ($x) = @_;
    return 0 if $x < 0;
    return 1 if $x > 1;
    return $x;
}

sub _abstraction_hybrid {
    my ($values, $weights, $lambda) = @_;
    die "abstraction hybrid: no values\n" unless ref($values) eq 'ARRAY' && @$values;
    my ($wsum, $asum, $logsum, $zero) = (0, 0, 0, 0);
    for my $i (0 .. $#$values) {
        my $v = _abstraction_clamp01(0 + $values->[$i]);
        my $w = 0 + $weights->[$i];
        die "abstraction hybrid: weight must be positive\n" unless $w > 0;
        $wsum += $w;
        $asum += $w * $v;
        if ($v <= 0) { $zero = 1; }
        else { $logsum += $w * log($v); }
    }
    die "abstraction hybrid: non-positive total weight\n" unless $wsum > 0;
    my $A = $asum / $wsum;
    my $G = $zero ? 0 : exp($logsum / $wsum);
    return _abstraction_clamp01((1 - $lambda) * $A + $lambda * $G);
}

# Evaluate the exact hybrid dissimilarity persisted by an antecedent abstraction.
# This function is deliberately model-application only: it never estimates a
# performance range, selects k, optimizes medoids, or changes category labels.
sub abstraction_distance {
    my (%a) = @_;
    my $metric = $a{metric};
    my $ia = $a{instance_a};
    my $ib = $a{instance_b};
    my $pa = 0 + $a{performance_a};
    my $pb = 0 + $a{performance_b};
    die "abstraction_distance: metric HASH required\n" unless ref($metric) eq 'HASH';
    die "abstraction_distance: instance_a required\n" unless defined($ia) && length($ia);
    die "abstraction_distance: instance_b required\n" unless defined($ib) && length($ib);

    my $ha = parse_instance($ia);
    my $hb = parse_instance($ib);
    my $levels = $metric->{variable_levels};
    die "abstraction_distance: metric has no variable_levels\n"
        unless ref($levels) eq 'HASH' && keys %$levels;
    my $lambda = exists($metric->{lambda}) ? 0 + $metric->{lambda} : 0.5;
    my $vw = ref($metric->{variable_weights}) eq 'HASH' ? $metric->{variable_weights} : {};
    my $cw = ref($metric->{component_weights}) eq 'HASH' ? $metric->{component_weights} : {};

    my $group = sub {
        my ($vars) = @_;
        my (@sim, @w);
        for my $v (@$vars) {
            die "abstraction_distance: instance lacks variable $v\n"
                unless exists($ha->{$v}) && exists($hb->{$v});
            my $L = 0 + ($levels->{$v} // $levels->{"$v"} // 0);
            next if $L <= 1;
            my $delta = abs($ha->{$v} - $hb->{$v});
            my $d = log(1 + $delta) / log($L);
            push @sim, _abstraction_clamp01(1 - $d);
            push @w, 0 + ($vw->{$v} // $vw->{"$v"} // 1);
        }
        return undef unless @sim;
        return _abstraction_hybrid(\@sim, \@w, $lambda);
    };

    my (@components, @weights);
    my $ctx = ref($metric->{context_variables}) eq 'ARRAY' ? $metric->{context_variables} : [];
    my $prb = ref($metric->{problem_variables}) eq 'ARRAY' ? $metric->{problem_variables} : [];
    my $cs = $group->($ctx);
    if (defined $cs) {
        push @components, $cs;
        push @weights, 0 + ($cw->{context} // 1);
    }
    my $ps = $group->($prb);
    if (defined $ps) {
        push @components, $ps;
        push @weights, 0 + ($cw->{problem} // 1);
    }

    my $pc = ref($metric->{performance}) eq 'HASH' ? $metric->{performance} : {};
    die "abstraction_distance: metric performance model is incomplete\n"
        unless exists($pc->{best}) && exists($pc->{worst}) && exists($pc->{divisions});
    my $best = 0 + $pc->{best};
    my $worst = 0 + $pc->{worst};
    my $div = 0 + $pc->{divisions};
    die "abstraction_distance: performance divisions must be >= 1\n" unless $div >= 1;
    my $span = abs($worst - $best);
    my $perf_sim = 1;
    if ($span > 0 && $pa != $pb) {
        my $step = $span / $div;
        my $steps = $step > 0 ? abs($pa - $pb) / $step : 0;
        $steps = $div if $steps > $div;
        my $d = log(1 + $steps) / log(1 + $div);
        $perf_sim = _abstraction_clamp01(1 - $d);
    }
    push @components, $perf_sim;
    push @weights, 0 + ($cw->{performance} // 1);
    return _abstraction_clamp01(1 - _abstraction_hybrid(\@components, \@weights, $lambda));
}

# Assign one regenerated state to the nearest retained antecedent medoid under
# the frozen antecedent metric.  The returned cluster label is the antecedent
# cluster label; no fitting, label alignment, or medoid optimization occurs.
sub apply_abstraction_model {
    my (%a) = @_;
    my $model = $a{model};
    die "apply_abstraction_model: model HASH required\n" unless ref($model) eq 'HASH';
    my $metric = $model->{metric};
    my $medoids = $model->{medoids};
    die "apply_abstraction_model: model has no persisted metric\n"
        unless ref($metric) eq 'HASH';
    die "apply_abstraction_model: model has no retained medoids\n"
        unless ref($medoids) eq 'ARRAY' && @$medoids;
    my $instance = $a{instance};
    die "apply_abstraction_model: instance required\n" unless defined($instance) && length($instance);
    die "apply_abstraction_model: performance required\n" unless defined($a{performance});
    my $performance = 0 + $a{performance};

    # Preferred semantics for a persisted hierarchical abstraction: route the
    # regenerated state through the *same learned binary partition* that
    # produced the antecedent clusters.  This is categorisation by a frozen
    # learned partition, not a new clustering operation.
    if (ref($model->{hierarchy}) eq 'HASH' && ref($model->{hierarchy}{nodes}) eq 'ARRAY') {
        my @nodes = @{$model->{hierarchy}{nodes}};
        my %by_id = map { (defined($_->{node_id}) ? (0+$_->{node_id} => $_) : ()) } @nodes;
        my ($root) = grep { !defined($_->{parent}) } @nodes;
        if ($root) {
            my $node = $root;
            my $usable = 1;
            while (!$node->{leaf}) {
                my $children = $node->{children};
                my $split = $node->{split_medoids};
                if (ref($children) ne 'ARRAY' || @$children != 2 || ref($split) ne 'ARRAY' || @$split != 2) {
                    $usable = 0;
                    last;
                }
                for my $m (@$split) {
                    unless (ref($m) eq 'HASH' && defined($m->{instance}) && defined($m->{performance})) {
                        $usable = 0;
                        last;
                    }
                }
                last unless $usable;
                my $d0 = abstraction_distance(
                    metric => $metric,
                    instance_a => $instance, performance_a => $performance,
                    instance_b => $split->[0]{instance}, performance_b => 0 + $split->[0]{performance},
                );
                my $d1 = abstraction_distance(
                    metric => $metric,
                    instance_a => $instance, performance_a => $performance,
                    instance_b => $split->[1]{instance}, performance_b => 0 + $split->[1]{performance},
                );
                my $pick;
                if ($d1 < $d0) {
                    $pick = 1;
                } elsif ($d1 > $d0) {
                    $pick = 0;
                } else {
                    my $r0 = defined($split->[0]{row_index}) ? 0 + $split->[0]{row_index} : undef;
                    my $r1 = defined($split->[1]{row_index}) ? 0 + $split->[1]{row_index} : undef;
                    $pick = (defined($r0) && defined($r1))
                        ? ($r1 < $r0 ? 1 : 0)
                        : (($split->[1]{instance} lt $split->[0]{instance}) ? 1 : 0);
                }
                my $next = $children->[$pick];
                unless (defined($next) && exists $by_id{0+$next}) {
                    $usable = 0;
                    last;
                }
                $node = $by_id{0+$next};
            }
            if ($usable && $node->{leaf} && defined($node->{cluster})) {
                my $cluster = 0 + $node->{cluster};
                my ($m) = grep { defined($_->{cluster}) && 0+$_->{cluster} == $cluster } @$medoids;
                die "apply_abstraction_model: hierarchy leaf cluster $cluster has no retained medoid\n"
                    unless $m && defined($m->{instance}) && defined($m->{performance});
                my $d = abstraction_distance(
                    metric => $metric,
                    instance_a => $instance, performance_a => $performance,
                    instance_b => $m->{instance}, performance_b => 0 + $m->{performance},
                );
                return {
                    cluster => $cluster,
                    medoid_instance => $m->{instance},
                    medoid_performance => 0 + $m->{performance},
                    distance => 0 + $d,
                    partition_semantics => 'frozen_hierarchical_partition',
                };
            }
        }
    }

    # Backward-compatible fallback for abstractions created before hierarchical
    # split medoids were persisted.  This is nearest-retained-medoid assignment
    # and is intentionally labelled as an approximation of the learned partition.
    my $best;
    for my $m (@$medoids) {
        die "apply_abstraction_model: malformed medoid record\n"
            unless ref($m) eq 'HASH' && defined($m->{cluster}) && defined($m->{instance}) && defined($m->{performance});
        my $d = abstraction_distance(
            metric => $metric,
            instance_a => $instance, performance_a => $performance,
            instance_b => $m->{instance}, performance_b => $m->{performance},
        );
        my $candidate = {
            cluster => 0 + $m->{cluster},
            medoid_instance => $m->{instance},
            medoid_performance => 0 + $m->{performance},
            distance => 0 + $d,
            partition_semantics => 'nearest_retained_medoid_fallback',
        };
        if (!defined($best)
            || $candidate->{distance} < $best->{distance}
            || ($candidate->{distance} == $best->{distance} && $candidate->{cluster} < $best->{cluster})
            || ($candidate->{distance} == $best->{distance} && $candidate->{cluster} == $best->{cluster}
                && $candidate->{medoid_instance} lt $best->{medoid_instance})) {
            $best = $candidate;
        }
    }
    return $best;
}

# Translate between a shared compressed memory lattice and the source lattice
# from which it was reconstructed.  Active memory axes preserve the source-grid
# resolution and differ only by an integer origin shift; inactive axes are
# unchanged.  Experiential-memory reconstruction keeps the compact window inside
# the antecedent source lattice.
sub map_memory_instance_to_source {
    my ($instance, $plan) = @_;
    die "map_memory_instance_to_source: plan HASH required\n" unless ref($plan) eq 'HASH';
    my $axes = $plan->{per_variable_axes};
    my $vars = $plan->{variables};
    die "map_memory_instance_to_source: plan has no per_variable_axes\n"
        unless ref($axes) eq 'HASH';
    die "map_memory_instance_to_source: plan has no variables\n"
        unless ref($vars) eq 'ARRAY';
    my $h = parse_instance($instance);
    my %out = %$h;
    for my $v (@$vars) {
        my $a = $axes->{$v} || $axes->{"$v"};
        die "map_memory_instance_to_source: plan lacks axis $v\n" unless ref($a) eq 'HASH';
        die "map_memory_instance_to_source: instance '$instance' lacks variable $v\n"
            unless exists $h->{$v};
        my $lo = $a->{memory_source_low};
        die "map_memory_instance_to_source: axis $v lacks memory_source_low\n" unless defined $lo;
        $out{$v} = 0 + $h->{$v} + 0 + $lo - 1;
    }
    return format_instance(\%out);
}

sub map_source_instance_to_memory {
    my ($instance, $plan) = @_;
    die "map_source_instance_to_memory: plan HASH required\n" unless ref($plan) eq 'HASH';
    my $axes = $plan->{per_variable_axes};
    my $vars = $plan->{variables};
    die "map_source_instance_to_memory: plan has no per_variable_axes\n"
        unless ref($axes) eq 'HASH';
    die "map_source_instance_to_memory: plan has no variables\n"
        unless ref($vars) eq 'ARRAY';
    my $h = parse_instance($instance);
    my %out = %$h;
    for my $v (@$vars) {
        my $a = $axes->{$v} || $axes->{"$v"};
        die "map_source_instance_to_memory: plan lacks axis $v\n" unless ref($a) eq 'HASH';
        die "map_source_instance_to_memory: instance '$instance' lacks variable $v\n"
            unless exists $h->{$v};
        my $lo = $a->{memory_source_low};
        my $levels = $a->{memory_levels};
        die "map_source_instance_to_memory: axis $v lacks memory_source_low/memory_levels\n"
            unless defined($lo) && defined($levels);
        my $m = 0 + $h->{$v} - 0 - $lo + 1;
        return undef if $m < 1 || $m > 0 + $levels;
        $out{$v} = $m;
    }
    return format_instance(\%out);
}

sub refined_level_count {
    my ($n, $factor) = @_;
    $factor = 2 unless defined $factor;
    die "refined_level_count: n must be >= 1\n" unless defined($n) && $n >= 1;
    die "refined_level_count: factor must be a positive integer\n"
        unless $factor =~ /^\d+$/ && $factor >= 1;
    return 1 + $factor * ($n - 1);
}

sub rescale_level {
    my ($level, $factor) = @_;
    $factor = 2 unless defined $factor;
    die "rescale_level: level must be >= 1\n" unless defined($level) && $level >= 1;
    return 1 + $factor * ($level - 1);
}

sub rescale_instance {
    my ($s, $factor, $vars) = @_;
    $factor = 2 unless defined $factor;
    my $h = parse_instance($s);
    my %wanted = $vars ? map { $_ => 1 } @$vars : map { $_ => 1 } keys %$h;
    my %out = %$h;
    for my $v (keys %out) {
        $out{$v} = rescale_level($out{$v}, $factor) if $wanted{$v};
    }
    return format_instance(\%out);
}

# Generated lattices use the central level as their reference iteration by
# default, matching Sim::OPT's own implicit-medium convention.  An explicit
# per-variable override is allowed when a design intentionally needs another
# reference level.  For an even number of levels this follows Sim::OPT's
# existing lower-middle convention: int((n + 1) / 2).
sub _centered_mediumiters {
    my (%a) = @_;
    my $counts = $a{counts};
    my $override = $a{override};
    my $label = $a{label} || 'mediumiters';
    die "$label: counts HASH required\n"
        unless ref($counts) eq 'HASH' && keys %$counts;
    die "$label: override must be a HASH reference\n"
        if defined($override) && ref($override) ne 'HASH';
    $override ||= {};

    for my $v (keys %$override) {
        die "$label: override variable $v is absent from lattice counts\n"
            unless exists $counts->{$v};
    }

    my %medium;
    for my $v (sort { $a <=> $b } keys %$counts) {
        my $n = 0 + $counts->{$v};
        die "$label: variable $v level count must be an integer >= 1\n"
            unless $n >= 1 && $n == int($n);
        my $m = exists($override->{$v})
            ? $override->{$v}
            : int(($n + 1) / 2);
        die "$label: variable $v medium must be an integer in 1..$n\n"
            unless defined($m) && "$m" =~ /^\d+$/ && $m >= 1 && $m <= $n;
        $medium{$v} = 0 + $m;
    }
    return \%medium;
}

# -------------------------------------------------------------------------
# Conservative parser for the subset of a Sim::OPT config needed here.
# It does not execute the configuration file.
# -------------------------------------------------------------------------

sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    local $/;
    my $txt = <$fh>;
    close $fh;
    return $txt;
}

sub _spit {
    my ($path, $txt) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!\n";
    print {$fh} $txt;
    close $fh or die "Cannot close $path: $!\n";
}

sub _parse_hash_assignment {
    my ($txt, $name) = @_;
    my ($body) = $txt =~ /^\s*\Q$name\E\s*=\s*\(\s*\{(.*?)\}\s*\)\s*;/ms;
    die "Cannot parse $name from config\n" unless defined $body;
    my %h;
    while ($body =~ /(\d+)\s*=>\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+))/g) {
        $h{0 + $1} = 0 + $2;
    }
    die "No entries parsed from $name\n" unless keys %h;
    return \%h;
}

sub _parse_active_sweeps {
    my ($txt) = @_;
    my ($line) = $txt =~ /^(?!\s*#)\s*\@sweeps\s*=\s*([^;]+);/m;
    die "Cannot find active \@sweeps assignment\n" unless defined $line;
    my @vars = map { 0 + $_ } ($line =~ /\b(\d+)\b/g);
    return \@vars;
}

sub _num_list {
    my ($s) = @_;
    my @n = map { 0 + $_ } ($s =~ /["']?([+-]?(?:\d+(?:\.\d*)?|\.\d+))["']?/g);
    return \@n;
}

sub _extract_operation {
    my ($txt, $v) = @_;
    my ($apply) = $txt =~ /\$vals\{1\}\{\Q$v\E\}\{applytype\}\s*=\s*(\[.*?\])\s*;/ms;
    die "Variable $v has no parseable applytype\n" unless defined $apply;
    my ($type) = $apply =~ /\[\s*["']([^"']+)["']/;
    die "Cannot identify operation type for variable $v\n" unless defined $type;

    if ($type eq 'rotate') {
        my ($block) = $txt =~ /\$vals\{1\}\{\Q$v\E\}\{rotate\}\s*=\s*\[(.*?)\]\s*;/ms;
        die "Cannot parse rotate block for variable $v\n" unless defined $block;
        my ($arg) = $block =~ /\[\s*["'][^"']*["']\s*,\s*(\[[^\]]+\]|["']?[+-]?(?:\d+(?:\.\d*)?|\.\d+)["']?)/s;
        die "Cannot parse rotate interval for variable $v\n" unless defined $arg;
        my ($begin, $end);
        if ($arg =~ /^\s*\[/) {
            my $n = _num_list($arg);
            die "rotate endpoints need two numbers for variable $v\n" unless @$n >= 2;
            ($begin, $end) = @$n[0,1];
        } else {
            $arg =~ s/["']//g;
            my $h = 0 + $arg;
            ($begin, $end) = (-$h, $h);
        }
        return { type => 'rotate', begin => [$begin], end => [$end] };
    }

    if ($type eq 'translate') {
        my ($block) = $txt =~ /\$vals\{1\}\{\Q$v\E\}\{translate\}\s*=\s*\[(.*?)\]\s*;/ms;
        die "Cannot parse translate block for variable $v\n" unless defined $block;
        my ($arg) = $block =~ /\[\s*["'][^"']*["']\s*,\s*(\[.*?\])\s*,\s*["']/s;
        die "Cannot parse translate coordinates for variable $v\n" unless defined $arg;

        # explicit endpoints: [[x,y,z],[x,y,z]]
        if ($arg =~ /^\s*\[\s*\[/) {
            my @inner = $arg =~ /\[([^\[\]]+)\]/g;
            die "translate endpoints need two vectors for variable $v\n" unless @inner >= 2;
            my $a = _num_list($inner[0]);
            my $b = _num_list($inner[1]);
            die "translate vectors must have three components for variable $v\n" unless @$a >= 3 && @$b >= 3;
            return { type => 'translate', begin => [@$a[0..2]], end => [@$b[0..2]] };
        }
        my $h = _num_list($arg);
        die "translate swing must have three components for variable $v\n" unless @$h >= 3;
        return {
            type  => 'translate',
            begin => [ @$h[0..2] ],
            end   => [ map { -$_ } @$h[0..2] ],
        };
    }

    if ($type eq 'obs_modify') {
        my ($block) = $txt =~ /\$vals\{1\}\{\Q$v\E\}\{obs_modify\}\s*=\s*\[(.*?)\]\s*;/ms;
        die "Cannot parse obs_modify block for variable $v\n" unless defined $block;
        my ($mode) = $block =~ /\]\s*,\s*["']([^"']+)["']\s*,/s;
        die "Cannot parse obs_modify mode for variable $v\n" unless defined $mode;
        die "StructureDesign v$VERSION currently supports vector obs_modify modes a/b only (variable $v uses '$mode')\n"
            unless $mode eq 'a' || $mode eq 'b';
        my ($arg) = $block =~ /\]\s*,\s*["'][^"']+["']\s*,\s*(\[.*\])\s*\]/s;
        die "Cannot parse obs_modify values for variable $v\n" unless defined $arg;

        if ($arg =~ /^\s*\[\s*\[/) {
            my @inner = $arg =~ /\[([^\[\]]+)\]/g;
            die "obs_modify endpoints need two vectors for variable $v\n" unless @inner >= 2;
            my $a = _num_list($inner[0]);
            my $b = _num_list($inner[1]);
            die "obs_modify vectors must have three components for variable $v\n" unless @$a >= 3 && @$b >= 3;
            return { type => 'obs_modify', mode => $mode, begin => [@$a[0..2]], end => [@$b[0..2]] };
        }
        my $h = _num_list($arg);
        die "obs_modify swing must have three components for variable $v\n" unless @$h >= 3;
        return {
            type  => 'obs_modify', mode => $mode,
            begin => [ @$h[0..2] ],
            end   => [ map { -$_ } @$h[0..2] ],
        };
    }

    die "StructureDesign v$VERSION does not yet know how to zoom operation '$type' for variable $v\n";
}

sub inspect_config {
    my ($path) = @_;
    my $txt = _slurp($path);
    my ($mypath) = $txt =~ /^(?!\s*#)\s*\$mypath\s*=\s*["']([^"']+)["']/m;
    my ($file)   = $txt =~ /^(?!\s*#)\s*\$file\s*=\s*["']([^"']+)["']/m;
    die "Cannot parse \$mypath from $path\n" unless defined $mypath;
    die "Cannot parse \$file from $path\n" unless defined $file;

    return {
        path        => $path,
        text        => $txt,
        mypath      => $mypath,
        file        => $file,
        sweeps      => _parse_active_sweeps($txt),
        varinumbers => _parse_hash_assignment($txt, '@varinumbers'),
        mediumiters => _parse_hash_assignment($txt, '@mediumiters'),
    };
}

sub _clamp {
    my ($x, $lo, $hi) = @_;
    return $lo if $x < $lo;
    return $hi if $x > $hi;
    return $x;
}

sub _interp_vec {
    my ($a, $b, $pos, $last) = @_;
    return [ @$a ] if $last == 0;
    my @out;
    for my $i (0 .. $#$a) {
        push @out, $a->[$i] + ($b->[$i] - $a->[$i]) * $pos / $last;
    }
    return \@out;
}

sub _vec_sub {
    my ($a, $b) = @_;
    return [ map { $a->[$_] - $b->[$_] } 0 .. $#$a ];
}

sub plan_zoom_in {
    my (%a) = @_;
    my $parent_config = $a{parent_config} or die "plan_zoom_in: parent_config required\n";
    my $incumbent     = $a{incumbent}     or die "plan_zoom_in: incumbent required\n";
    my $variables     = $a{variables} || [1,2,3,4,5];
    my $factor_default = defined($a{resolution_factor}) ? $a{resolution_factor} : 2;
    my $factor_map     = $a{resolution_factors};
    die "resolution_factors must be a HASH reference\n"
        if defined($factor_map) && ref($factor_map) ne 'HASH';
    my $local_levels_arg = defined($a{local_levels}) ? $a{local_levels} : 3;
    die "local_levels must be a scalar or HASH reference\n"
        if ref($local_levels_arg) && ref($local_levels_arg) ne 'HASH';
    my $local_stride_arg = defined($a{local_strides}) ? $a{local_strides} : 1;
    die "local_strides must be a scalar or HASH reference\n"
        if ref($local_stride_arg) && ref($local_stride_arg) ne 'HASH';
    # `mediumiters` is a compatibility alias for the generated local zoom.
    # The canonical refined/global lattice has its own optional override.
    my $local_medium_override = exists($a{local_mediumiters})
        ? $a{local_mediumiters} : $a{mediumiters};
    my $refined_medium_override = $a{refined_mediumiters};

    my $cfg = inspect_config($parent_config);
    my $inc = parse_instance($incumbent);
    my %wanted = map { $_ => 1 } @$variables;

    my (%global_counts, %global_medium, %global_inc, %local_counts, %local_medium,
        %windows, %ops, %resolution_factors, %local_strides, %parent_level_offsets,
        %per_variable_axes);

    for my $v (sort { $a <=> $b } keys %{ $cfg->{varinumbers} }) {
        my $n = $cfg->{varinumbers}{$v};
        if ($wanted{$v}) {
            die "Incumbent lacks variable $v\n" unless exists $inc->{$v};
            my $factor = ref($factor_map) eq 'HASH' && exists($factor_map->{$v})
                ? $factor_map->{$v} : $factor_default;
            die "resolution factor for variable $v must be a positive integer\n"
                unless defined($factor) && $factor =~ /^\d+$/ && $factor >= 1;

            my $local_levels = ref($local_levels_arg) eq 'HASH'
                ? $local_levels_arg->{$v} : $local_levels_arg;
            $local_levels = 3 unless defined $local_levels;
            die "local_levels for variable $v must be an odd integer >= 3\n"
                unless $local_levels =~ /^\d+$/ && $local_levels >= 3 && $local_levels % 2 == 1;

            my $local_stride = ref($local_stride_arg) eq 'HASH'
                ? $local_stride_arg->{$v} : $local_stride_arg;
            $local_stride = 1 unless defined $local_stride;
            die "local_stride for variable $v must be a positive integer\n"
                unless $local_stride =~ /^\d+$/ && $local_stride >= 1;

            $factor = 0 + $factor;
            $local_levels = 0 + $local_levels;
            $local_stride = 0 + $local_stride;
            $resolution_factors{$v} = $factor;
            $local_strides{$v} = $local_stride;
            $local_counts{$v} = $local_levels;

            # First construct the parent-refined coordinate system. Parent
            # levels lie at 1, 1+r, 1+2r, ... and therefore retain their exact
            # physical positions while the increment is divided by r.
            my $parent_refined_count  = refined_level_count($n, $factor);
            my $inc_raw               = rescale_level($inc->{$v}, $factor);

            # Start from the nominal incumbent-centred local window, then shift
            # the whole window inward if it crosses a parent boundary.  A
            # reduce_scope operation must remain a subset of the parent scope;
            # it must never enlarge that scope merely to preserve centring.
            my $center = int(($local_levels + 1) / 2);
            my $window_span = ($local_levels - 1) * $local_stride;
            die "Local zoom for variable $v does not fit inside refined parent scope\n"
                if $window_span > $parent_refined_count - 1;

            my $local_start_raw = $inc_raw - ($center - 1) * $local_stride;
            my $local_end_raw   = $local_start_raw + $window_span;

            if ($local_start_raw < 1) {
                my $shift = 1 - $local_start_raw;
                $local_start_raw += $shift;
                $local_end_raw   += $shift;
            }
            if ($local_end_raw > $parent_refined_count) {
                my $shift = $local_end_raw - $parent_refined_count;
                $local_start_raw -= $shift;
                $local_end_raw   -= $shift;
            }

            die "Contained local zoom for variable $v is outside refined parent scope\n"
                if $local_start_raw < 1 || $local_end_raw > $parent_refined_count;
            die "Contained local zoom for variable $v no longer contains the incumbent\n"
                if $inc_raw < $local_start_raw || $inc_raw > $local_end_raw;
            die "Contained local zoom for variable $v is off the requested stride\n"
                if (($inc_raw - $local_start_raw) % $local_stride) != 0;

            my $left_steps  = $inc_raw - $local_start_raw;
            my $right_steps = $local_end_raw - $inc_raw;

            # The canonical refined lattice is exactly the rescaled parent
            # scope.  No coordinate-origin offset is introduced by zooming.
            my $raw_min = 1;
            my $raw_max = $parent_refined_count;
            my $offset = 0;
            $parent_level_offsets{$v} = 0;
            $global_counts{$v} = $parent_refined_count;
            $global_inc{$v} = $inc_raw;
            $windows{$v} = [ $local_start_raw, $local_end_raw ];

            my $op = _extract_operation($cfg->{text}, $v);
            my @fine_step;
            for my $i (0 .. $#{ $op->{begin} }) {
                push @fine_step,
                    ($op->{end}[$i] - $op->{begin}[$i]) / ($parent_refined_count - 1);
            }
            my @child_begin = map { -$left_steps  * $_ } @fine_step;
            my @child_end   = map {  $right_steps * $_ } @fine_step;
            my @global_begin = map {
                $op->{begin}[$_] + ($raw_min - 1) * $fine_step[$_]
            } 0 .. $#fine_step;
            my @global_end = map {
                $op->{begin}[$_] + ($raw_max - 1) * $fine_step[$_]
            } 0 .. $#fine_step;

            $ops{$v} = {
                %$op,
                child_begin => \@child_begin,
                child_end   => \@child_end,
                global_begin => \@global_begin,
                global_end   => \@global_end,
            };
            $per_variable_axes{$v} = {
                resolution_factor          => $factor,
                local_levels               => $local_levels,
                local_stride               => $local_stride,
                parent_refined_count       => $parent_refined_count,
                parent_level_offset        => $offset,
                physical_step_per_level    => \@fine_step,
            };
        } else {
            $global_counts{$v} = $n;
            $global_inc{$v}    = $inc->{$v} if exists $inc->{$v};
            $parent_level_offsets{$v} = 0;
            # A deferred variable remains fixed in the child workspace.
            $local_counts{$v}  = 1;
        }
    }

    # A local reduce_scope workspace is the intentional exception to the
    # normal centred-medium default: its reference level is the incumbent's
    # coordinate inside the shifted local window.  This preserves the meaning
    # of a local zoom as being anchored on the incumbent even when containment
    # forces the window inward at a parent boundary.  An explicit per-variable
    # local override may still replace that default.
    my %local_medium_default;
    for my $v (sort { $a <=> $b } keys %local_counts) {
        if ($wanted{$v}) {
            my $stride = $local_strides{$v};
            $local_medium_default{$v}
                = 1 + int(($global_inc{$v} - $windows{$v}[0]) / $stride);
        } else {
            $local_medium_default{$v} = 1;
        }
    }
    die "plan_zoom_in local mediumiters: override must be a HASH reference\n"
        if defined($local_medium_override) && ref($local_medium_override) ne 'HASH';
    my %local_medium_effective = %local_medium_default;
    if (ref($local_medium_override) eq 'HASH') {
        @local_medium_effective{ keys %$local_medium_override }
            = values %$local_medium_override;
    }
    %local_medium = %{ _centered_mediumiters(
        counts => \%local_counts,
        override => \%local_medium_effective,
        label => 'plan_zoom_in local mediumiters',
    ) };

    # The canonical refined/global lattice follows the normal policy: central
    # mediumiters unless explicitly overridden.
    %global_medium = %{ _centered_mediumiters(
        counts => \%global_counts,
        override => $refined_medium_override,
        label => 'plan_zoom_in refined mediumiters',
    ) };

    my $global_inc_name = format_instance(\%global_inc);
    return {
        schema              => 'Sim::OPT::StructureDesign/zoom-plan-5',
        operation           => 'zoom_in',
        parent_config       => $parent_config,
        parent_dir          => $cfg->{mypath},
        model_root          => $cfg->{file},
        child_dir           => $a{child_dir},
        child_config        => $a{child_config},
        variables           => [ @$variables ],
        resolution_factor   => $factor_default,
        resolution_factors  => \%resolution_factors,
        local_levels        => ref($local_levels_arg) eq 'HASH'
            ? { %$local_levels_arg } : $local_levels_arg,
        local_strides       => ref($local_stride_arg) eq 'HASH'
            ? { %$local_stride_arg } : $local_stride_arg,
        parent_level_offsets => \%parent_level_offsets,
        per_variable_axes   => \%per_variable_axes,
        parent_counts       => { %{ $cfg->{varinumbers} } },
        parent_medium       => { %{ $cfg->{mediumiters} } },
        incumbent_parent    => $incumbent,
        refined_counts      => \%global_counts,
        refined_medium      => \%global_medium,
        incumbent_refined        => $global_inc_name,
        incumbent_refined_levels => { %global_inc },
        local_counts             => \%local_counts,
        medium_default      => 'mixed',
        local_medium_default => 'incumbent',
        refined_medium_default => 'center',
        local_medium_overrides => ref($local_medium_override) eq 'HASH'
            ? { %$local_medium_override } : {},
        refined_medium_overrides => ref($refined_medium_override) eq 'HASH'
            ? { %$refined_medium_override } : {},
        local_medium        => \%local_medium,
        windows             => \%windows,
        operations          => \%ops,
    };
}

sub plan_enlarge_pan {
    my (%a) = @_;
    my $template_config = $a{template_config} || $a{parent_config}
        or die "plan_enlarge_pan: template_config required\n";
    my $source_dir = $a{source_dir}
        or die "plan_enlarge_pan: source_dir required\n";
    my $source_counts = $a{source_counts};
    die "plan_enlarge_pan: source_counts HASH required\n"
        unless ref($source_counts) eq 'HASH' && keys %$source_counts;
    my $source_incumbent = $a{source_incumbent} || $a{incumbent}
        or die "plan_enlarge_pan: source_incumbent required\n";
    my $variables = $a{variables} || [];
    die "plan_enlarge_pan: variables ARRAY required\n"
        unless ref($variables) eq 'ARRAY' && @$variables;

    my $default_factor = defined($a{scope_factor}) ? $a{scope_factor} : 2;
    my $factor_arg = ref($a{scope_factors}) eq 'HASH' ? $a{scope_factors} : {};
    my $cfg = inspect_config($template_config);
    my $inc = parse_instance($source_incumbent);
    my %wanted = map { 0 + $_ => 1 } @$variables;

    # The canonical source configuration and the lattice manifest must describe
    # the same state before any enlargement is planned.  This prevents a stale
    # template (for example the original parent config) from silently defining
    # the geometry of a later state.
    _same_numeric_hash($cfg->{varinumbers}, $source_counts,
        'plan_enlarge_pan source config @varinumbers');
    for my $v (keys %$source_counts) {
        my $lev = $inc->{$v};
        die "plan_enlarge_pan: source incumbent lacks variable $v\n"
            unless defined $lev;
        die "plan_enlarge_pan: source incumbent variable $v level $lev is outside 1..$source_counts->{$v}\n"
            if $lev < 1 || $lev > $source_counts->{$v};
    }

    my (%target_counts, %target_medium, %target_inc, %factors, %ops, %axes);
    for my $v (sort { $a <=> $b } keys %$source_counts) {
        my $n = 0 + $source_counts->{$v};
        die "plan_enlarge_pan: source variable $v must have at least 1 level\n" if $n < 1;
        die "plan_enlarge_pan: source incumbent lacks variable $v\n" unless exists $inc->{$v};
        $target_counts{$v} = $n;
        $target_medium{$v} = 0 + $inc->{$v};
        $target_inc{$v} = 0 + $inc->{$v};
    }

    for my $v (@$variables) {
        die "plan_enlarge_pan: source_counts lacks variable $v\n" unless exists $source_counts->{$v};
        die "plan_enlarge_pan: template config lacks variable $v\n" unless exists $cfg->{varinumbers}{$v};
        my $source_n = 0 + $source_counts->{$v};
        die "plan_enlarge_pan: variable $v needs at least 2 source levels to maintain resolution\n"
            if $source_n < 2;
        my $factor = exists($factor_arg->{$v}) ? $factor_arg->{$v}
                   : exists($factor_arg->{"$v"}) ? $factor_arg->{"$v"}
                   : $default_factor;
        die "plan_enlarge_pan: scope factor for variable $v must be a positive integer\n"
            unless defined($factor) && "$factor" =~ /^\d+$/ && $factor >= 1;
        $factor = 0 + $factor;
        $factors{$v} = $factor;

        my $target_n = 1 + $factor * ($source_n - 1);
        die "plan_enlarge_pan: target lattice for variable $v has no unique center ($target_n levels)\n"
            unless $target_n % 2 == 1;
        my $center = int(($target_n + 1) / 2);
        $target_counts{$v} = $target_n;
        $target_medium{$v} = $center;
        $target_inc{$v} = $center;

        my $op = _extract_operation($cfg->{text}, $v);
        my @step;
        for my $i (0 .. $#{ $op->{begin} }) {
            push @step, ($op->{end}[$i] - $op->{begin}[$i]) / ($source_n - 1);
        }
        my @child_begin = map { -($center - 1) * $_ } @step;
        my @child_end   = map {  ($target_n - $center) * $_ } @step;
        $ops{$v} = {
            %$op,
            child_begin => \@child_begin,
            child_end   => \@child_end,
        };
        $axes{$v} = {
            scope_change => 'enlarge',
            scope_factor => $factor,
            resolution_change => 'same',
            source_levels => $source_n,
            target_levels => $target_n,
            source_incumbent_level => 0 + $inc->{$v},
            target_incumbent_level => $center,
            physical_step_per_level => \@step,
            relative_begin => \@child_begin,
            relative_end => \@child_end,
        };
    }

    my $target_medium_override = exists($a{target_mediumiters})
        ? $a{target_mediumiters} : $a{mediumiters};
    if (defined $target_medium_override) {
        die "plan_enlarge_pan mediumiters: override must be a HASH reference\n"
            unless ref($target_medium_override) eq 'HASH';
        my %active = map { 0 + $_ => 1 } @$variables;
        for my $v (keys %$target_medium_override) {
            die "plan_enlarge_pan mediumiters: override variable $v is not an enlarged variable\n"
                unless $active{$v};
            my $n = 0 + $target_counts{$v};
            my $m = $target_medium_override->{$v};
            die "plan_enlarge_pan mediumiters: variable $v medium must be an integer in 1..$n\n"
                unless defined($m) && "$m" =~ /^\d+$/ && $m >= 1 && $m <= $n;
            $target_medium{$v} = 0 + $m;
        }
    }

    return {
        schema => 'Sim::OPT::StructureDesign/scope-pan-plan-2',
        operation => 'enlarge_scope+maintain_resolution+pan',
        primitives => [ 'enlarge_scope', 'maintain_resolution', 'pan' ],
        template_config => $template_config,
        source_dir => $source_dir,
        source_counts => { map { $_ => 0 + $source_counts->{$_} } keys %$source_counts },
        source_medium => { map { $_ => 0 + $cfg->{mediumiters}{$_} } keys %{ $cfg->{mediumiters} } },
        source_incumbent => $source_incumbent,
        source_incumbent_levels => { %$inc },
        variables => [ map { 0 + $_ } @$variables ],
        scope_factor => 0 + $default_factor,
        scope_factors => \%factors,
        target_counts => \%target_counts,
        medium_default => 'center_on_transformed_axes',
        medium_overrides => ref($target_medium_override) eq 'HASH'
            ? { %$target_medium_override } : {},
        target_medium => \%target_medium,
        target_incumbent => format_instance(\%target_inc),
        target_incumbent_levels => \%target_inc,
        per_variable_axes => \%axes,
        operations => \%ops,
        model_root => $a{model_root} || $cfg->{file},
        child_dir => $a{child_dir},
        child_config => $a{child_config},
        lattice_manifest => $a{lattice_manifest},
    };
}

sub _fmt_num {
    my ($x) = @_;
    return '0' if abs($x) < 1e-12;
    my $s = sprintf('%.10f', $x);
    $s =~ s/0+$//;
    $s =~ s/\.$//;
    return $s;
}

sub _fmt_vec {
    my ($v) = @_;
    return '[ ' . join(', ', map { '"' . _fmt_num($_) . '"' } @$v) . ' ]';
}

sub _replace_hash_assignment {
    my ($txt, $name, $h) = @_;
    my $body = join(', ', map { $_ . ' => ' . $h->{$_} } sort { $a <=> $b } keys %$h) . ',';
    my $new = "$name = \n( { \n$body\n} );";
    my $n = ($txt =~ s/^\s*\Q$name\E\s*=\s*\(\s*\{.*?\}\s*\)\s*;/$new/ms);
    die "Could not replace $name\n" unless $n == 1;
    return $txt;
}

sub _patch_operation {
    my ($txt, $v, $op) = @_;
    my $type = $op->{type};
    my $a = $op->{child_begin};
    my $b = $op->{child_end};

    if ($type eq 'rotate') {
        my $range = '[ ' . _fmt_num($a->[0]) . ', ' . _fmt_num($b->[0]) . ' ]';
        my $re = qr/(\$vals\{1\}\{\Q$v\E\}\{rotate\}\s*=\s*\[\s*\[\s*["'][^"']*["']\s*,\s*)(?:\[[^\]]+\]|["']?[+-]?(?:\d+(?:\.\d*)?|\.\d+)["']?)(\s*,)/ms;
        my $n = ($txt =~ s/$re/$1$range$2/);
        die "Could not patch rotate for variable $v\n" unless $n == 1;
        return $txt;
    }

    if ($type eq 'translate') {
        my $range = '[ ' . _fmt_vec($a) . ', ' . _fmt_vec($b) . ' ]';
        my $re = qr/(\$vals\{1\}\{\Q$v\E\}\{translate\}\s*=\s*\[\s*\[\s*["'][^"']*["']\s*,\s*)\[.*?\](\s*,\s*["'][^"']+["'])/ms;
        my $n = ($txt =~ s/$re/$1$range$2/);
        die "Could not patch translate for variable $v\n" unless $n == 1;
        return $txt;
    }

    if ($type eq 'obs_modify') {
        my $range = '[ ' . _fmt_vec($a) . ', ' . _fmt_vec($b) . ' ]';
        my $re = qr/(\$vals\{1\}\{\Q$v\E\}\{obs_modify\}\s*=\s*\[\s*\[\s*\[[^\]]+\]\s*,\s*["'][^"']+["']\s*,\s*)\[[^\n]*?\](\s*\]\s*,?\s*\]\s*;)/ms;
        my $n = ($txt =~ s/$re/$1$range$2/);
        die "Could not patch obs_modify for variable $v\n" unless $n == 1;
        return $txt;
    }

    die "Cannot patch unsupported operation $type for variable $v\n";
}

sub render_zoom_config {
    my ($plan) = @_;
    die "render_zoom_config: zoom plan required\n" unless ref($plan) eq 'HASH' && $plan->{operation} eq 'zoom_in';
    my $cfg = inspect_config($plan->{parent_config});
    my $txt = $cfg->{text};
    my $child_dir = $plan->{child_dir} or die "render_zoom_config: child_dir missing in plan\n";

    my $n = ($txt =~ s/^(?!\s*#)(\s*\$mypath\s*=\s*)["'][^"']+["']/$1"$child_dir"/m);
    die "Could not patch \$mypath\n" unless $n == 1;

    my $sweep = '@sweeps = ( [ [ ' . join(' , ', @{ $plan->{variables} }) . ' ] ] );';
    $n = ($txt =~ s/^(?!\s*#)\s*\@sweeps\s*=\s*[^;]+;/$sweep/m);
    die "Could not patch active \@sweeps\n" unless $n == 1;

    $txt = _replace_hash_assignment($txt, '@varinumbers', $plan->{local_counts});
    $txt = _replace_hash_assignment($txt, '@mediumiters', $plan->{local_medium});

    for my $v (@{ $plan->{variables} }) {
        $txt = _patch_operation($txt, $v, $plan->{operations}{$v});
    }

    my $stamp = "# Generated by Sim::OPT::StructureDesign $VERSION\n"
              . "# local mediumiters default: incumbent position unless explicitly overridden\n"
              . "# Parent incumbent: $plan->{incumbent_parent}\n"
              . "# Refined global incumbent: $plan->{incumbent_refined}\n";
    return $stamp . $txt;
}

sub render_enlarge_pan_config {
    my ($plan) = @_;
    die "render_enlarge_pan_config: scope-pan plan required\n"
        unless ref($plan) eq 'HASH'
            && ($plan->{operation} || '') eq 'enlarge_scope+maintain_resolution+pan';
    my $cfg = inspect_config($plan->{template_config});
    my $txt = $cfg->{text};
    my $child_dir = $plan->{child_dir}
        or die "render_enlarge_pan_config: child_dir missing in plan\n";

    my $n = ($txt =~ s/^(?!\s*#)(\s*\$mypath\s*=\s*)["'][^"']+["']/$1"$child_dir"/m);
    die "Could not patch \$mypath\n" unless $n == 1;

    my $sweep = '@sweeps = ( [ [ ' . join(' , ', @{ $plan->{variables} }) . ' ] ] );';
    $n = ($txt =~ s/^(?!\s*#)\s*\@sweeps\s*=\s*[^;]+;/$sweep/m);
    die "Could not patch active \@sweeps\n" unless $n == 1;

    $txt = _replace_hash_assignment($txt, '@varinumbers', $plan->{target_counts});
    $txt = _replace_hash_assignment($txt, '@mediumiters', $plan->{target_medium});
    for my $v (@{ $plan->{variables} }) {
        $txt = _patch_operation($txt, $v, $plan->{operations}{$v});
    }

    my $stamp = "# Generated by Sim::OPT::StructureDesign $VERSION\n"
              . "# mediumiters default: central level on transformed axes unless explicitly overridden\n"
              . "# Operation: enlarge_scope + maintain_resolution + pan\n"
              . "# Source incumbent: $plan->{source_incumbent}\n"
              . "# Target reference: $plan->{target_incumbent}\n";
    return $stamp . $txt;
}

sub validate_enlarge_pan_config_text {
    my ($txt, $plan, %a) = @_;
    die "validate_enlarge_pan_config_text: text required\n" unless defined $txt;
    die "validate_enlarge_pan_config_text: scope-pan plan required\n"
        unless ref($plan) eq 'HASH'
            && ($plan->{operation} || '') eq 'enlarge_scope+maintain_resolution+pan';

    my ($mypath) = $txt =~ /^(?!\s*#)\s*\$mypath\s*=\s*["']([^"']+)["']/m;
    my ($file)   = $txt =~ /^(?!\s*#)\s*\$file\s*=\s*["']([^"']+)["']/m;
    die "validate_enlarge_pan_config_text: cannot parse \$mypath\n" unless defined $mypath;
    die "validate_enlarge_pan_config_text: cannot parse \$file\n" unless defined $file;

    if (defined $a{target_dir}) {
        die "validate_enlarge_pan_config_text: \$mypath is '$mypath', expected '$a{target_dir}'\n"
            unless $mypath eq $a{target_dir};
    }
    my $root = $plan->{model_root};
    die "validate_enlarge_pan_config_text: model root is '$file', expected '$root'\n"
        if defined($root) && length($root) && $file ne $root;

    my $counts = _parse_hash_assignment($txt, '@varinumbers');
    my $medium = _parse_hash_assignment($txt, '@mediumiters');
    _same_numeric_hash($counts, $plan->{target_counts}, 'scope-pan @varinumbers');
    _same_numeric_hash($medium, $plan->{target_medium}, 'scope-pan @mediumiters');

    my $target_inc = parse_instance($plan->{target_incumbent});
    for my $v (@{ $plan->{variables} || [] }) {
        my $axis = $plan->{per_variable_axes}{$v}
            or die "validate_enlarge_pan_config_text: scope plan lacks axis for variable $v\n";
        my $want = $plan->{operations}{$v}
            or die "validate_enlarge_pan_config_text: scope plan lacks operation for variable $v\n";
        my $got = _extract_operation($txt, $v);
        die "validate_enlarge_pan_config_text: operation type differs for variable $v\n"
            unless ($got->{type} || '') eq ($want->{type} || '');
        if (exists $want->{mode}) {
            die "validate_enlarge_pan_config_text: operation mode differs for variable $v\n"
                unless defined($got->{mode}) && $got->{mode} eq $want->{mode};
        }
        _same_numeric_vector($got->{begin}, $want->{child_begin},
            "scope-pan variable $v physical begin");
        _same_numeric_vector($got->{end}, $want->{child_end},
            "scope-pan variable $v physical end");

        my $n = 0 + $plan->{target_counts}{$v};
        my $center = int(($n + 1) / 2);
        die "validate_enlarge_pan_config_text: variable $v target incumbent is not centered\n"
            unless 0 + $target_inc->{$v} == $center
                && 0 + $plan->{target_medium}{$v} == $center;

        my @step_from_target;
        for my $i (0 .. $#{ $got->{begin} }) {
            push @step_from_target,
                ($got->{end}[$i] - $got->{begin}[$i]) / ($n - 1);
        }
        _same_numeric_vector(\@step_from_target, $axis->{physical_step_per_level},
            "scope-pan variable $v maintained resolution");
    }
    return 1;
}

sub write_manifest {
    my ($plan, $path) = @_;
    die "write_manifest: plan HASH and path required\n" unless ref($plan) eq 'HASH' && defined $path;
    my $json = JSON::PP->new->canonical(1)->pretty(1)->encode($plan);
    _spit($path, $json);
    return $path;
}

sub _copy_tree {
    my ($src, $dst) = @_;
    die "Source directory does not exist: $src\n" unless -d $src;
    die "Destination already exists: $dst\n" if -e $dst;
    make_path($dst);
    my $src_len = length($src);
    find({
        no_chdir => 1,
        wanted => sub {
            my $p = $File::Find::name;
            return if $p eq $src;
            my $rel = substr($p, $src_len);
            $rel =~ s{^/}{};
            my $q = "$dst/$rel";
            # Test symlinks before -d/-f: Perl's file tests follow symlinks,
            # so a directory symlink otherwise becomes an empty real directory.
            # Memory roots are often morphed Sim::OPT instances and must retain
            # their link topology exactly.
            if (-l $p) {
                my $target = readlink($p);
                die "readlink $p failed: $!\n" unless defined $target;
                make_path(dirname($q)) unless -d dirname($q);
                symlink($target, $q) or die "symlink $q failed: $!\n";
            } elsif (-d $p) {
                make_path($q) unless -d $q;
                my $mode = (stat($p))[2];
                chmod($mode & 07777, $q) if defined $mode;
            } elsif (-f $p) {
                make_path(dirname($q)) unless -d dirname($q);
                copy($p, $q) or die "copy $p -> $q failed: $!\n";
                my $mode = (stat($p))[2];
                chmod($mode & 07777, $q) if defined $mode;
            }
        },
    }, $src);
}

sub _load_cryptolinks {
    my ($path) = @_;
    return undef unless defined($path) && -f $path;
    my $data = do $path;
    return $data if ref($data) eq 'HASH';

    # Conservative fallback for Data::Dump-like key/value pairs.
    my $txt = _slurp($path);
    my %h;
    while ($txt =~ /["']([^"']+)["']\s*=>\s*(?:["']([^"']*)["']|(\d+))/g) {
        $h{$1} = defined($2) ? $2 : $3;
    }
    return keys(%h) ? \%h : undef;
}

sub resolve_incumbent_model {
    my (%a) = @_;
    my $dir = $a{parent_dir} or die "resolve_incumbent_model: parent_dir required\n";
    my $root = $a{model_root} or die "resolve_incumbent_model: model_root required\n";
    my $inc = $a{incumbent} or die "resolve_incumbent_model: incumbent required\n";
    return $a{incumbent_model_dir} if $a{incumbent_model_dir};

    my $crypt = $a{cryptolinks} || "$dir/${root}_0_cryptolinks.pl";
    my $h = _load_cryptolinks($crypt)
        or die "Cannot parse cryptolinks file $crypt; pass incumbent_model_dir explicitly\n";

    # Older Sim::OPT files may map clear-id => numeric short-id directly.
    my $short = $h->{$inc};
    $short = undef unless defined($short) && "$short" =~ /^\d+$/;

    # Native files may instead contain absolute path pairs in both directions:
    #   .../bt_5 <=> .../bt_1-4_2-9_...
    unless (defined $short) {
        for my $k (keys %$h) {
            my $v = $h->{$k};
            next if ref($v) || !defined($v);
            my $kb = basename($k);
            my $vb = basename("$v");
            if ($kb =~ /^\Q$root\E_(\d+)$/
                && $vb eq $root . '_' . $inc) {
                $short = 0 + $1;
                last;
            }
            if ($vb =~ /^\Q$root\E_(\d+)$/
                && $kb eq $root . '_' . $inc) {
                $short = 0 + $1;
                last;
            }
        }
    }

    die "Incumbent '$inc' not found in $crypt\n" unless defined $short;
    my $model = "$dir/${root}_$short";
    die "Resolved incumbent directory does not exist: $model\n" unless -d $model;
    return $model;
}

sub create_zoom_workspace {
    my (%a) = @_;
    my $plan = $a{plan} || plan_zoom_in(%a);
    my $commit = $a{commit} ? 1 : 0;
    return $plan unless $commit;

    my $child_dir = $plan->{child_dir} or die "create_zoom_workspace: child_dir required\n";
    die "Refusing to overwrite existing child directory $child_dir\n" if -e $child_dir;
    my $child_cfg_name = $plan->{child_config} || basename($plan->{parent_config});
    my $src_model = resolve_incumbent_model(
        parent_dir          => $plan->{parent_dir},
        model_root          => $plan->{model_root},
        incumbent           => $plan->{incumbent_parent},
        cryptolinks         => $a{cryptolinks},
        incumbent_model_dir => $a{incumbent_model_dir},
    );

    make_path($child_dir);
    _copy_tree($src_model, "$child_dir/$plan->{model_root}");
    _spit("$child_dir/$child_cfg_name", render_zoom_config($plan));
    write_manifest($plan, "$child_dir/structuredesign-zoom.json");
    return $plan;
}


sub create_enlarge_pan_workspace {
    my (%a) = @_;
    my $plan = $a{plan} || plan_enlarge_pan(%a);
    my $commit = $a{commit} ? 1 : 0;
    return $plan unless $commit;

    my $child_dir = $plan->{child_dir}
        or die "create_enlarge_pan_workspace: child_dir required\n";
    die "Refusing to overwrite existing child directory $child_dir\n" if -e $child_dir;
    my $child_cfg_name = $plan->{child_config} || basename($plan->{template_config});
    my $src_model = resolve_incumbent_model(
        parent_dir => $plan->{source_dir},
        model_root => $plan->{model_root},
        incumbent => $plan->{source_incumbent},
        cryptolinks => $a{cryptolinks},
        incumbent_model_dir => $a{incumbent_model_dir},
    );

    my $rendered = render_enlarge_pan_config($plan);
    validate_enlarge_pan_config_text($rendered, $plan, target_dir => $child_dir);

    make_path($child_dir);
    _copy_tree($src_model, "$child_dir/$plan->{model_root}");
    _spit("$child_dir/$child_cfg_name", $rendered);
    write_manifest($plan, "$child_dir/structuredesign-scope.json");
    return $plan;
}

sub _same_numeric_hash {
    my ($got, $want, $label) = @_;
    die "$label: HASH references required\n"
        unless ref($got) eq 'HASH' && ref($want) eq 'HASH';
    my @gk = sort { $a <=> $b } keys %$got;
    my @wk = sort { $a <=> $b } keys %$want;
    die "$label: variable sets differ\n" unless "@gk" eq "@wk";
    for my $v (@wk) {
        die "$label: variable $v differs (got $got->{$v}, expected $want->{$v})\n"
            unless 0 + $got->{$v} == 0 + $want->{$v};
    }
    return 1;
}

sub _same_numeric_vector {
    my ($got, $want, $label) = @_;
    die "$label: ARRAY references required\n"
        unless ref($got) eq 'ARRAY' && ref($want) eq 'ARRAY';
    die "$label: vector lengths differ\n" unless @$got == @$want;
    for my $i (0 .. $#$want) {
        my $d = abs((0 + $got->[$i]) - (0 + $want->[$i]));
        die "$label: component $i differs (got $got->[$i], expected $want->[$i])\n"
            if $d > 1e-9;
    }
    return 1;
}

sub validate_refined_parent_config_text {
    my ($txt, $plan, %a) = @_;
    die "validate_refined_parent_config_text: text required\n" unless defined $txt;
    die "validate_refined_parent_config_text: zoom plan required\n"
        unless ref($plan) eq 'HASH' && ($plan->{operation} || '') eq 'zoom_in';

    my ($mypath) = $txt =~ /^(?!\s*#)\s*\$mypath\s*=\s*["']([^"']+)["']/m;
    my ($file)   = $txt =~ /^(?!\s*#)\s*\$file\s*=\s*["']([^"']+)["']/m;
    die "validate_refined_parent_config_text: cannot parse \$mypath\n" unless defined $mypath;
    die "validate_refined_parent_config_text: cannot parse \$file\n" unless defined $file;

    if (defined $a{target_dir}) {
        die "validate_refined_parent_config_text: \$mypath is '$mypath', expected '$a{target_dir}'\n"
            unless $mypath eq $a{target_dir};
    }
    my $root = $plan->{model_root};
    die "validate_refined_parent_config_text: model root is '$file', expected '$root'\n"
        if defined($root) && length($root) && $file ne $root;

    my $counts = _parse_hash_assignment($txt, '@varinumbers');
    my $medium = _parse_hash_assignment($txt, '@mediumiters');
    _same_numeric_hash($counts, $plan->{refined_counts}, 'refined @varinumbers');
    _same_numeric_hash($medium, $plan->{refined_medium}, 'refined @mediumiters');

    # The canonical refined-global configuration is the rescaled parent scope.
    # Boundary zoom windows are shifted inward, so reduce_scope never extends
    # the physical parent bounds.
    for my $v (@{ $plan->{variables} || [] }) {
        my $want = $plan->{operations}{$v}
            or die "validate_refined_parent_config_text: zoom plan lacks operation for variable $v\n";
        my $got = _extract_operation($txt, $v);
        die "validate_refined_parent_config_text: operation type differs for variable $v\n"
            unless ($got->{type} || '') eq ($want->{type} || '');
        if (($want->{type} || '') eq 'obs_modify') {
            die "validate_refined_parent_config_text: obs_modify mode differs for variable $v\n"
                unless ($got->{mode} || '') eq ($want->{mode} || '');
        }
        _same_numeric_vector($got->{begin}, $want->{global_begin}, "variable $v physical begin");
        _same_numeric_vector($got->{end},   $want->{global_end},   "variable $v physical end");
    }

    return 1;
}

sub render_refined_parent_config {
    my ($plan, %a) = @_;
    die "render_refined_parent_config: zoom plan required\n"
        unless ref($plan) eq 'HASH' && $plan->{operation} eq 'zoom_in';
    my $cfg = inspect_config($plan->{parent_config});
    my $txt = $cfg->{text};

    if (defined $a{target_dir}) {
        my $n = ($txt =~ s/^(?!\s*#)(\s*\$mypath\s*=\s*)["'][^"']+["']/$1"$a{target_dir}"/m);
        die "render_refined_parent_config: could not patch \$mypath\n" unless $n == 1;
    }

    $txt = _replace_hash_assignment($txt, '@varinumbers', $plan->{refined_counts});
    $txt = _replace_hash_assignment($txt, '@mediumiters', $plan->{refined_medium});
    for my $v (@{ $plan->{variables} || [] }) {
        my $op = $plan->{operations}{$v}
            or die "render_refined_parent_config: zoom plan lacks operation for variable $v\n";
        my %global_op = (%$op, child_begin => $op->{global_begin}, child_end => $op->{global_end});
        $txt = _patch_operation($txt, $v, \%global_op);
    }
    my $stamp = "# Refined global lattice generated by Sim::OPT::StructureDesign $VERSION\n"
              . "# Rescaled parent scope preserved; boundary zooms are shifted inward; fine-grid resolution preserved.\n";
    my $rendered = $stamp . $txt;
    validate_refined_parent_config_text($rendered, $plan, %a);
    return $rendered;
}

sub _render_cloned_state_config_unchecked {
    my ($source_config, %a) = @_;
    die "render_cloned_state_config: source_config required\n"
        unless defined($source_config) && -f $source_config;
    die "render_cloned_state_config: target_dir required\n"
        unless defined($a{target_dir}) && length($a{target_dir});

    my $cfg = inspect_config($source_config);
    my $txt = $cfg->{text};
    my $target_dir = $a{target_dir};
    my $n = ($txt =~ s/^(?!\s*#)(\s*\$mypath\s*=\s*)["'][^"']+["']/$1"$target_dir"/m);
    die "render_cloned_state_config: could not patch \$mypath in $source_config\n" unless $n == 1;
    return $txt;
}

sub validate_cloned_state_config_text {
    my ($txt, $source_config, %a) = @_;
    die "validate_cloned_state_config_text: text required\n" unless defined $txt;
    die "validate_cloned_state_config_text: source_config required\n"
        unless defined($source_config) && -f $source_config;
    die "validate_cloned_state_config_text: target_dir required\n"
        unless defined($a{target_dir}) && length($a{target_dir});

    my $expected = _render_cloned_state_config_unchecked(
        $source_config, target_dir => $a{target_dir},
    );
    die "validate_cloned_state_config_text: target differs from source by more than \$mypath\n"
        unless $txt eq $expected;

    my $source = inspect_config($source_config);
    my ($mypath) = $txt =~ /^(?!\s*#)\s*\$mypath\s*=\s*["']([^"']+)["']/m;
    my ($file)   = $txt =~ /^(?!\s*#)\s*\$file\s*=\s*["']([^"']+)["']/m;
    die "validate_cloned_state_config_text: cannot parse \$mypath\n" unless defined $mypath;
    die "validate_cloned_state_config_text: cannot parse \$file\n" unless defined $file;
    die "validate_cloned_state_config_text: \$mypath is '$mypath', expected '$a{target_dir}'\n"
        unless $mypath eq $a{target_dir};
    die "validate_cloned_state_config_text: model root differs (got '$file', expected '$source->{file}')\n"
        unless $file eq $source->{file};

    my $counts = _parse_hash_assignment($txt, '@varinumbers');
    my $medium = _parse_hash_assignment($txt, '@mediumiters');
    _same_numeric_hash($counts, $source->{varinumbers}, 'cloned @varinumbers');
    _same_numeric_hash($medium, $source->{mediumiters}, 'cloned @mediumiters');
    return 1;
}

sub render_cloned_state_config {
    my ($source_config, %a) = @_;
    my $txt = _render_cloned_state_config_unchecked($source_config, %a);
    validate_cloned_state_config_text($txt, $source_config, %a);
    return $txt;
}

sub scan_max_short_id {
    my ($dir, $root) = @_;
    die "scan_max_short_id: directory and model root required\n" unless defined($dir) && defined($root);
    opendir my $dh, $dir or die "Cannot open directory $dir: $!\n";
    my $max = 0;
    while (defined(my $e = readdir $dh)) {
        if ($e =~ /^\Q$root\E_(\d+)$/) {
            $max = $1 if $1 > $max;
        }
    }
    closedir $dh;
    return $max;
}

sub plan_zoom_out_merge {
    my (%a) = @_;
    my $zoom = $a{zoom_plan} or die "plan_zoom_out_merge: zoom_plan required\n";
    die "plan_zoom_out_merge: invalid zoom plan\n"
        unless ref($zoom) eq 'HASH' && $zoom->{operation} eq 'zoom_in';

    my $parent_dir = $a{parent_dir} || $zoom->{parent_dir};
    my $child_dir  = $a{child_dir}  || $zoom->{child_dir};
    my $root       = $zoom->{model_root};
    my $parent_max;
    if (defined($parent_dir) && -d $parent_dir) {
        $parent_max = scan_max_short_id($parent_dir, $root);
    }

    my $child_max;
    if (defined($child_dir) && -d $child_dir) {
        $child_max = scan_max_short_id($child_dir, $root);
    }

    my %ranges = map { $_ => [ @{ $zoom->{windows}{$_} } ] } @{ $zoom->{variables} };
    return {
        schema            => 'Sim::OPT::StructureDesign/zoom-out-plan-1',
        operation         => 'zoom_out',
        parent_dir        => $parent_dir,
        child_dir         => $child_dir,
        model_root        => $root,
        variables         => [ @{ $zoom->{variables} } ],
        resolution_factor => $zoom->{resolution_factor},
        parent_counts_old => { %{ $zoom->{parent_counts} } },
        global_counts_new => { %{ $zoom->{refined_counts} } },
        parent_medium_new => { %{ $zoom->{refined_medium} } },
        parent_level_rule => 'new_level = parent_level_offset + 1 + resolution_factor * (old_level - 1)',
        child_windows     => \%ranges,
        child_level_rule  => 'global_level = child_window_start + local_stride * (local_level - 1)',
        parent_short_max  => $parent_max,
        child_short_max   => $child_max,
        child_short_offset => $parent_max,
        safety => {
            clear_names => 'structural variable-level mapping',
            short_ids   => 'offset only in validated identifier fields and model-folder basenames',
            result_values => 'never blind numeric substitution',
        },
    };
}

# Map a child's local 1..L clear name onto the refined global lattice.
sub map_local_instance_to_global {
    my ($s, $plan) = @_;
    my $h = parse_instance($s);
    my %out = %$h;
    my %active = map { $_ => 1 } @{ $plan->{variables} || [] };

    # Validate the source clear name on the local zoom lattice before any
    # collapsed coordinates are restored to refined-global levels.
    if (ref($plan->{local_counts}) eq 'HASH' && keys %{ $plan->{local_counts} }) {
        my @got = sort { $a <=> $b } keys %out;
        my @want = sort { $a <=> $b } keys %{ $plan->{local_counts} };
        die "Local instance '$s' variable set differs from zoom local_counts\n"
            unless "@got" eq "@want";
        for my $v (@want) {
            my $max = 0 + $plan->{local_counts}{$v};
            my $lev = 0 + $out{$v};
            die "Local instance '$s': variable $v level $lev outside 1..$max\n"
                if $lev < 1 || $lev > $max;
        }
    }

    # zoom-plan-1 files written before incumbent_refined_levels was persisted
    # still contain the equivalent canonical clear name in incumbent_refined.
    # Recover the hash from that string so existing completed zoom states can
    # be reembedded without rerunning their simulations.
    my $inc_levels = $plan->{incumbent_refined_levels};
    if (ref($inc_levels) ne 'HASH' && defined($plan->{incumbent_refined})
        && length($plan->{incumbent_refined})) {
        $inc_levels = parse_instance($plan->{incumbent_refined});
    }
    $inc_levels = {} unless ref($inc_levels) eq 'HASH';

    for my $v (keys %out) {
        if ($active{$v}) {
            my $w = $plan->{windows}{$v} or die "No window for variable $v\n";
            my $stride = 1;
            if (ref($plan->{local_strides}) eq 'HASH' && exists $plan->{local_strides}{$v}) {
                $stride = 0 + $plan->{local_strides}{$v};
            } elsif (ref($plan->{per_variable_axes}) eq 'HASH'
                     && ref($plan->{per_variable_axes}{$v}) eq 'HASH'
                     && exists $plan->{per_variable_axes}{$v}{local_stride}) {
                $stride = 0 + $plan->{per_variable_axes}{$v}{local_stride};
            }
            my $g = $w->[0] + ($out{$v} - 1) * $stride;
            die "Local level $out{$v} for v$v maps outside [$w->[0],$w->[1]]\n"
                if $g < $w->[0] || $g > $w->[1];
            $out{$v} = $g;
        } elsif (($plan->{local_counts}{$v} || 0) == 1
                 && exists $inc_levels->{$v}) {
            # In a zoom workspace, inactive variables are collapsed to local
            # level 1. Re-embedding must restore their refined-global level.
            $out{$v} = $inc_levels->{$v};
        }
    }
    return format_instance(\%out);
}

# Rewrite only structurally recognizable clear names; numeric result values are untouched.
sub rewrite_clear_instances_in_text {
    my ($txt, $mapper) = @_;
    die "rewrite_clear_instances_in_text: mapper CODE required\n" unless ref($mapper) eq 'CODE';
    $txt =~ s{(?<![A-Za-z0-9])((?:\d+-\d+)(?:_\d+-\d+)+)(?![A-Za-z0-9])}{$mapper->($1)}ge;
    return $txt;
}

sub _quote_scalar {
    my ($x) = @_;
    my $q = defined($x) ? "$x" : '';
    $q =~ s/([\\"])/\\$1/g;
    return qq{"$q"};
}


# -------------------------------------------------------------------------
# Memory reconstruction: reactivate retained medoids jointly in one workspace.
# The medoids remain explicit centres of one multi-star acquisition, one totres
# and one surrogate.  Optional star_divisions enriches recall by adding an
# n>-equivalent evenly distributed centre set on the same shared memory lattice;
# it never removes or replaces the retained medoid centres.  Active axes are
# nominally compressed to about half their
# source level count while preserving the source grid and every medoid exactly;
# if the medoids themselves span a wider interval, the shared recalled axis is
# widened only enough to contain them.  Three-level variables are incompressible.
# -------------------------------------------------------------------------

sub memory_level_count {
    my ($n) = @_;
    die "memory_level_count: level count must be an integer >= 1\n"
        unless defined($n) && "$n" =~ /^\d+$/ && $n >= 1;
    return 0 + $n if $n <= 3;

    # Keep an odd number so the remembered medoid is a unique central level.
    # Choose the odd integer nearest to n/2, with a minimum of 3.  This gives
    # 5->3, 9->5, 10->5, 17->9, 19->9, 29->15, ...
    my $half = $n / 2;
    my $lo = int($half);
    $lo-- if $lo % 2 == 0;
    $lo = 3 if $lo < 3;
    my $hi = $lo + 2;
    return (abs($half - $lo) <= abs($hi - $half)) ? $lo : $hi;
}

# Return an n>-equivalent set of evenly distributed star centres on the
# already-defined shared memory lattice.  The retained medoids are NOT replaced
# by these centres: plan_memory_reconstruction() unions the generated centres
# with the medoid centres so richer recall changes only the amount of probing,
# not the retained archetypal cues or the reconstruction scope.
#
# Sim::OPT's subdivision progression is 2> -> 3 centres, 3> -> 5 centres,
# 4> -> 9 centres, ... .  The corresponding normalized positions are the
# dyadic fractions 0..1 at denominator 2^(divisions-1).  Each active axis is
# mapped to its nearest lattice level; inactive axes retain the common medoid
# setting from the supplied template.
sub _memory_subdivision_starpositions {
    my (%a) = @_;
    my $counts = $a{counts};
    my $variables = $a{variables};
    my $template = $a{template};
    my $divisions = $a{divisions};

    die "memory subdivision: counts HASH required\n" unless ref($counts) eq 'HASH';
    die "memory subdivision: variables ARRAY required\n"
        unless ref($variables) eq 'ARRAY' && @$variables;
    die "memory subdivision: template HASH required\n" unless ref($template) eq 'HASH';
    die "memory subdivision: divisions must be an integer >= 2\n"
        unless defined($divisions) && "$divisions" =~ /^\d+$/ && $divisions >= 2;

    my $segments = 2 ** ($divisions - 1);
    my (@out, %seen);
    for my $i (0 .. $segments) {
        my %p = %$template;
        for my $v (@$variables) {
            die "memory subdivision: missing lattice count for variable $v\n"
                unless exists $counts->{$v};
            my $L = 0 + $counts->{$v};
            die "memory subdivision: lattice count for variable $v must be >= 1\n"
                if $L < 1;
            # Integer half-up rounding of 1 + (L-1) * i / segments.
            my $lev = 1 + int(((($L - 1) * $i) + ($segments / 2)) / $segments);
            $lev = 1 if $lev < 1;
            $lev = $L if $lev > $L;
            $p{$v} = $lev;
        }
        my $id = format_instance(\%p);
        next if $seen{$id}++;
        push @out, \%p;
    }
    return \@out;
}

sub _memory_set_dowhat_string {
    my ($txt, $key, $value) = @_;
    my $q = defined($value) ? "$value" : '';
    $q =~ s/([\\"])/\\$1/g;
    $q = qq{"$q"};

    my $n = ($txt =~ s/^(\s*)\Q$key\E\s*=>\s*["'][^"']*["']\s*,[^\n]*$/$1$key => $q,/m);
    return $txt if $n == 1;
    die "memory config: multiple active '$key' entries\n" if $n > 1;

    $n = ($txt =~ s/^\s*#\s*\Q$key\E\s*=>[^\n]*$/$key => $q,/m);
    return $txt if $n == 1;
    die "memory config: multiple commented '$key' entries\n" if $n > 1;

    $n = ($txt =~ s/(%dowhat\s*=\s*\(.*?)(^\s*\);[^\n]*$)/$1$key => $q,\n$2/ms);
    die "memory config: could not insert '$key' into %dowhat\n" unless $n == 1;
    return $txt;
}


sub _memory_format_starpositions {
    my ($positions) = @_;
    die "memory config: starpositions ARRAY required\n"
        unless ref($positions) eq 'ARRAY' && @$positions;
    my @rows;
    for my $h (@$positions) {
        die "memory config: each starposition must be a HASH reference\n"
            unless ref($h) eq 'HASH';
        my @pairs;
        for my $v (sort { $a <=> $b } keys %$h) {
            my $lev = $h->{$v};
            die "memory config: invalid starposition $v => $lev\n"
                unless "$v" =~ /^\d+$/ && defined($lev) && "$lev" =~ /^\d+$/;
            push @pairs, "$v => $lev";
        }
        push @rows, '        { ' . join(', ', @pairs) . ' }';
    }
    return "[\n" . join(",\n", @rows) . "\n    ]";
}

sub _memory_set_dowhat_perl_value {
    my ($txt, $key, $value_text) = @_;
    die "memory config: invalid dowhat key '$key'\n"
        unless defined($key) && $key =~ /^\w+$/;
    die "memory config: perl value required for '$key'\n"
        unless defined($value_text) && length($value_text);

    # Replace the flat array-of-hashes form emitted by StructureDesign.
    my $n = ($txt =~ s{^(\s*)\Q$key\E\s*=>\s*\[(?:\s*\{[^{}]*\}\s*,?)*\s*\]\s*,[^\n]*$}{$1$key => $value_text,}ms);
    return $txt if $n == 1;
    die "memory config: multiple active '$key' entries\n" if $n > 1;

    # Replace a scalar active value such as starpositions => "".
    $n = ($txt =~ s/^(\s*)\Q$key\E\s*=>\s*[^,\n]+\s*,[^\n]*$/$1$key => $value_text,/m);
    return $txt if $n == 1;
    die "memory config: multiple active '$key' entries\n" if $n > 1;

    # Prefer activating the documented commented slot when present.
    $n = ($txt =~ s/^\s*#\s*\Q$key\E\s*=>[^\n]*$/$key => $value_text,/m);
    return $txt if $n == 1;
    die "memory config: multiple commented '$key' entries\n" if $n > 1;

    $n = ($txt =~ s/(%dowhat\s*=\s*\(.*?)(^\s*\);[^\n]*$)/$1$key => $value_text,\n$2/ms);
    die "memory config: could not insert '$key' into %dowhat\n" unless $n == 1;
    return $txt;
}

sub _memory_geometry_distance {
    my (%a) = @_;
    my $pa = $a{a};
    my $pb = $a{b};
    my $vars = $a{variables};
    my $counts = $a{source_counts};
    die "memory geometry: point a HASH required\n" unless ref($pa) eq 'HASH';
    die "memory geometry: point b HASH required\n" unless ref($pb) eq 'HASH';
    die "memory geometry: variables ARRAY required\n" unless ref($vars) eq 'ARRAY' && @$vars;
    die "memory geometry: source_counts HASH required\n" unless ref($counts) eq 'HASH';
    my ($sum, $n) = (0, 0);
    for my $v (@$vars) {
        my $L = 0 + ($counts->{$v} // $counts->{"$v"} // 0);
        next if $L <= 1;
        my $d = abs((0 + $pa->{$v}) - (0 + $pb->{$v}));
        $sum += log(1 + $d) / log($L);
        $n++;
    }
    return $n ? $sum / $n : 0;
}

# Choose a compact source-grid interval that must contain every medoid but is
# positioned using retained direct experience.  Each non-empty cluster carries
# equal total weight, so a large cluster cannot erase a small remembered class.
sub _memory_choose_axis_window {
    my (%a) = @_;
    my $L = 0 + $a{levels};
    my $width = 0 + $a{width};
    my $medoid_levels = $a{medoid_levels};
    my $support = $a{support};
    my $v = $a{variable};
    die "memory window: invalid lattice width\n" unless $L >= 1 && $width >= 1 && $width <= $L;
    die "memory window: medoid_levels ARRAY required\n" unless ref($medoid_levels) eq 'ARRAY' && @$medoid_levels;
    die "memory window: support ARRAY required\n" unless ref($support) eq 'ARRAY';

    my $min_m = $medoid_levels->[0];
    my $max_m = $medoid_levels->[0];
    for my $x (@$medoid_levels) {
        $min_m = $x if $x < $min_m;
        $max_m = $x if $x > $max_m;
    }

    my %cluster_n;
    for my $r (@$support) {
        next unless ref($r) eq 'HASH' && defined($r->{cluster}) && ref($r->{position}) eq 'HASH';
        $cluster_n{0 + $r->{cluster}}++;
    }

    my @valid;
    for my $lo (1 .. ($L - $width + 1)) {
        my $hi = $lo + $width - 1;
        next if $lo > $min_m || $hi < $max_m;
        my ($score, $raw) = (0, 0);
        for my $r (@$support) {
            next unless ref($r) eq 'HASH' && ref($r->{position}) eq 'HASH';
            my $x = 0 + $r->{position}{$v};
            next if $x < $lo || $x > $hi;
            my $c = 0 + $r->{cluster};
            my $n = $cluster_n{$c} || 1;
            $score += 1 / $n;
            $raw++;
        }
        my $centre2 = $lo + $hi;
        my $medoid_centre2 = $min_m + $max_m;
        my $centre_penalty = abs($centre2 - $medoid_centre2);
        push @valid, { low=>$lo, high=>$hi, score=>$score, raw=>$raw, centre_penalty=>$centre_penalty };
    }
    die "memory window: no compact interval can contain all medoids on variable $v\n" unless @valid;
    @valid = sort {
           $b->{score} <=> $a->{score}
        || $b->{raw} <=> $a->{raw}
        || $a->{centre_penalty} <=> $b->{centre_penalty}
        || $a->{low} <=> $b->{low}
    } @valid;
    return $valid[0];
}

sub _memory_select_cloud_centres {
    my (%a) = @_;
    my $medoid = $a{medoid};
    my $candidates = $a{candidates};
    my $variables = $a{variables};
    my $source_counts = $a{source_counts};
    my $target = 0 + $a{target};
    die "memory cloud centres: medoid HASH required\n" unless ref($medoid) eq 'HASH';
    die "memory cloud centres: candidates ARRAY required\n" unless ref($candidates) eq 'ARRAY';
    return [] if $target <= 1 || !@$candidates;

    my @selected = ({ %$medoid });
    my %used = ( format_instance($medoid) => 1 );
    my @out;
    while (@selected < $target) {
        my $best;
        for my $r (@$candidates) {
            next unless ref($r) eq 'HASH' && ref($r->{position}) eq 'HASH';
            my $p = $r->{position};
            my $id = format_instance($p);
            next if $used{$id};
            my $mind;
            for my $q (@selected) {
                my $d = _memory_geometry_distance(
                    a=>$p, b=>$q, variables=>$variables, source_counts=>$source_counts,
                );
                $mind = $d if !defined($mind) || $d < $mind;
            }
            my $cand = { record=>$r, position=>$p, id=>$id, distance=>$mind };
            if (!defined($best)
                || $cand->{distance} > $best->{distance}
                || ($cand->{distance} == $best->{distance} && $cand->{id} lt $best->{id})) {
                $best = $cand;
            }
        }
        last unless $best;
        $used{$best->{id}} = 1;
        push @selected, { %{ $best->{position} } };
        push @out, $best->{record};
    }
    return \@out;
}

sub _memory_reconstruction_mode {
    my (%a) = @_;
    my $mode = $a{reconstruction_mode};
    if (!defined($mode) || !length($mode)) {
        # Backward compatibility in both directions.  Historical procedures did
        # not have a memory packet and therefore mean the legacy medoid-only
        # reconstruction.  Experiential-memory procedures carry memory_packet.
        return ref($a{memory_packet}) eq 'HASH'
            ? 'experiential_cloud'
            : 'legacy_medoid_only';
    }
    die "plan_memory_reconstruction: reconstruction_mode must be 'legacy_medoid_only' or 'experiential_cloud'\n"
        unless $mode eq 'legacy_medoid_only' || $mode eq 'experiential_cloud';
    return $mode;
}

sub plan_memory_reconstruction {
    my (%a) = @_;
    my $mode = _memory_reconstruction_mode(%a);
    return _plan_memory_reconstruction_legacy(%a)
        if $mode eq 'legacy_medoid_only';
    return _plan_memory_reconstruction_experiential(%a);
}

sub _plan_memory_reconstruction_legacy {
    my (%a) = @_;
    my $source_config = $a{source_config} or die "plan_memory_reconstruction: source_config required\n";
    my $medoids = $a{medoids};
    die "plan_memory_reconstruction: medoids ARRAY required\n"
        unless ref($medoids) eq 'ARRAY' && @$medoids;
    my $variables = $a{variables};
    die "plan_memory_reconstruction: variables ARRAY required\n"
        unless ref($variables) eq 'ARRAY' && @$variables;
    my $child_dir = $a{child_dir} or die "plan_memory_reconstruction: child_dir required\n";
    my $child_config = $a{child_config} || 'memory.pl';
    my $memory_root = defined($a{memory_model_root}) && length($a{memory_model_root})
        ? $a{memory_model_root} : 'btmed';
    die "plan_memory_reconstruction: memory_model_root must be a simple model-directory name\n"
        unless $memory_root =~ /^[A-Za-z0-9_.-]+$/;

    my $cfg = inspect_config($source_config);
    my @vars = sort { $a <=> $b } map { 0 + $_ } @$variables;
    my %active = map { $_ => 1 } @vars;
    for my $v (@vars) {
        die "plan_memory_reconstruction: variable $v absent from source lattice\n"
            unless exists $cfg->{varinumbers}{$v};
    }

    # Parse and validate all retained medoids in the source lattice first.
    my (@clear_medoids, @source_positions);
    my %seen;
    for my $clear (@$medoids) {
        next if $seen{$clear}++;
        my $h = parse_instance($clear);
        my %pos;
        for my $v (sort { $a <=> $b } keys %{ $cfg->{varinumbers} }) {
            die "plan_memory_reconstruction: medoid '$clear' lacks variable $v\n"
                unless exists $h->{$v};
            my $lev = 0 + $h->{$v};
            my $max = 0 + $cfg->{varinumbers}{$v};
            die "plan_memory_reconstruction: medoid '$clear' has variable $v level $lev outside 1..$max\n"
                if $lev < 1 || $lev > $max;
            $pos{$v} = $lev;
        }
        push @clear_medoids, $clear;
        push @source_positions, \%pos;
    }
    die "plan_memory_reconstruction: no distinct medoids remain\n" unless @source_positions;

    # In a shared reconstruction all medoids must inhabit one common lattice.
    # Variables not reconstructed by the star block therefore have to be fixed
    # identically in every medoid.  Otherwise there is no single rectangular
    # landscape for one totres/ordmeta pair.
    for my $v (sort { $a <=> $b } keys %{ $cfg->{varinumbers} }) {
        next if $active{$v};
        my %levels = map { $_->{$v} => 1 } @source_positions;
        die "plan_memory_reconstruction: medoids differ on inactive variable $v; include variable $v in reconstruct_memory variables for a shared landscape\n"
            if keys(%levels) > 1;
    }

    # Shared compression rule.
    #
    # The earlier per-medoid implementation could centre an independent half-
    # scope lattice on every medoid.  In one shared workspace that is impossible
    # in general without moving medoids off their actual source coordinates.
    # Instead, retain the source resolution and choose, per active variable, the
    # smallest contiguous source-grid window that:
    #   (a) contains every retained medoid exactly, and
    #   (b) is at least the nominal compressed width memory_level_count(L).
    # Thus a compact medoid set receives the intended approximately half-sized
    # recalled scope, while a dispersed medoid set expands only as much as is
    # necessary to preserve all archetypes.  Three-level variables remain
    # incompressible.  As with centred zooming, a boundary medoid is not clipped:
    # the shared recalled window may extend beyond the previously experienced
    # source boundary while retaining the same source-grid step.
    my %counts = %{ $cfg->{varinumbers} };
    my (%medium, %ops, %axes, %bounds);

    for my $v (@vars) {
        my $L = 0 + $cfg->{varinumbers}{$v};
        my $nominal = memory_level_count($L);
        my @ml = sort { $a <=> $b } map { 0 + $_->{$v} } @source_positions;
        my $min_m = $ml[0];
        my $max_m = $ml[-1];
        my $span = $max_m - $min_m + 1;
        my $width = $span > $nominal ? $span : $nominal;
        $width = $L if $width > $L;

        my $extra = $width - $span;
        my $left = int($extra / 2);
        my $right = $extra - $left;
        my $lo = $min_m - $left;
        my $hi = $max_m + $right;

        $counts{$v} = $width;
        $bounds{$v} = { source_low => $lo, source_high => $hi };

        my $op = _extract_operation($cfg->{text}, $v);
        my (@begin, @end);
        if ($L <= 1) {
            @begin = @{ $op->{begin} };
            @end = @{ $op->{end} };
        }
        else {
            @begin = @{ _interp_vec($op->{begin}, $op->{end}, $lo - 1, $L - 1) };
            @end   = @{ _interp_vec($op->{begin}, $op->{end}, $hi - 1, $L - 1) };
        }
        $ops{$v} = {
            %$op,
            child_begin => \@begin,
            child_end   => \@end,
        };
        $axes{$v} = {
            source_levels => $L,
            nominal_memory_levels => $nominal,
            medoid_source_min => $min_m,
            medoid_source_max => $max_m,
            medoid_source_span => $span,
            memory_source_low => $lo,
            memory_source_high => $hi,
            memory_levels => $width,
            compression_limited_by_medoid_span => ($span > $nominal ? JSON::PP::true : JSON::PP::false),
        };
    }

    # Map the actual medoid coordinates into the shared compressed window.
    # This is a pure integer shift on each active axis, so no medoid is rounded,
    # approximated or replaced by a synthetic point.
    my @positions;
    for my $src (@source_positions) {
        my %p = %$src;
        for my $v (@vars) {
            $p{$v} = $src->{$v} - $bounds{$v}{source_low} + 1;
        }
        push @positions, \%p;
    }

    # Optionally enrich reactivation with the same dyadic centre-count
    # progression used by Sim::OPT n> star subdivision.  The generated centres
    # are added to, never substituted for, the retained medoid centres.  Thus
    # star_divisions changes recall effort while keeping the memory cues and
    # shared recalled lattice unchanged.
    my $star_divisions;
    my @subdivision_positions;
    if (exists $a{star_divisions}) {
        $star_divisions = $a{star_divisions};
        die "plan_memory_reconstruction: star_divisions must be an integer >= 2\n"
            unless defined($star_divisions)
                && "$star_divisions" =~ /^\d+$/
                && $star_divisions >= 2;
        @subdivision_positions = @{ _memory_subdivision_starpositions(
            counts => \%counts,
            variables => \@vars,
            template => $positions[0],
            divisions => $star_divisions,
        ) };
    }

    my (@all_positions, %position_seen);
    for my $pos (@positions, @subdivision_positions) {
        my $id = format_instance($pos);
        next if $position_seen{$id}++;
        push @all_positions, { %$pos };
    }

    # Translate generated auxiliary centres back to source-grid coordinates for
    # provenance.  This is the same exact integer origin shift used by the
    # memory/source mapping functions.
    my @subdivision_source_positions;
    for my $pos (@subdivision_positions) {
        my %src = %$pos;
        for my $v (@vars) {
            $src{$v} = $pos->{$v} + $bounds{$v}{source_low} - 1;
        }
        push @subdivision_source_positions, \%src;
    }

    # The generated memory lattice follows the same reference convention as
    # every other generated state: central mediumiters by default.  Explicit
    # starpositions remain independent of this initial/reference level choice.
    my $memory_medium_override = exists($a{lattice_mediumiters})
        ? $a{lattice_mediumiters} : $a{mediumiters};
    %medium = %{ _centered_mediumiters(
        counts => \%counts,
        override => $memory_medium_override,
        label => 'plan_memory_reconstruction mediumiters',
    ) };

    my $expected_lattice_rows = 1;
    $expected_lattice_rows *= 0 + $counts{$_} for @vars;

    # Every effective star centre samples each complete coordinate line through
    # that centre in the active variables.  Count the sampled union exactly.
    my %sample_ids;
    for my $pos (@all_positions) {
        for my $v (@vars) {
            for my $lev (1 .. (0 + $counts{$v})) {
                my %q = %$pos;
                $q{$v} = $lev;
                $sample_ids{ format_instance(\%q) } = 1;
            }
        }
    }

    my $dowhat_inherit = $a{dowhat_inherit} || {};
    die "plan_memory_reconstruction: dowhat_inherit must be a HASH reference\n"
        unless ref($dowhat_inherit) eq 'HASH';
    for my $key (keys %$dowhat_inherit) {
        die "plan_memory_reconstruction: inherited dowhat keys/values must be strings\n"
            if !defined($key) || ref($key) || !length($key)
                || !defined($dowhat_inherit->{$key}) || ref($dowhat_inherit->{$key});
    }

    return {
        schema => 'Sim::OPT::StructureDesign/memory-reconstruction-plan-4',
        operation => 'reconstruct_memory',
        reconstruction_mode => 'legacy_medoid_only',
        mode => 'shared_multistar_compressed',
        source_config => $source_config,
        source_dir => $cfg->{mypath},
        source_model_root => $cfg->{file},
        model_root => $memory_root,
        medoids => \@clear_medoids,
        source_starpositions => \@source_positions,
        medoid_starpositions => \@positions,
        subdivision_source_starpositions => \@subdivision_source_positions,
        subdivision_starpositions => \@subdivision_positions,
        starpositions => \@all_positions,
        (defined($star_divisions) ? (star_divisions => 0 + $star_divisions) : ()),
        medoid_star_count => scalar(@positions),
        subdivision_star_count => scalar(@subdivision_positions),
        effective_star_count => scalar(@all_positions),
        variables => \@vars,
        child_dir => $child_dir,
        child_config => $child_config,
        lattice_counts => \%counts,
        medium_default => 'center',
        medium_overrides => ref($memory_medium_override) eq 'HASH'
            ? { %$memory_medium_override } : {},
        lattice_medium => \%medium,
        operations => \%ops,
        per_variable_axes => \%axes,
        expected_sample_rows => scalar(keys %sample_ids),
        expected_lattice_rows => $expected_lattice_rows,
        dowhat_inherit => { %$dowhat_inherit },
        metamodel => 'y',
        convergeintomodel => 'y',
    };
}

sub _plan_memory_reconstruction_experiential {
    my (%a) = @_;
    my $source_config = $a{source_config} or die "plan_memory_reconstruction: source_config required\n";
    my $medoids = $a{medoids};
    die "plan_memory_reconstruction: medoids ARRAY required\n"
        unless ref($medoids) eq 'ARRAY' && @$medoids;
    my $variables = $a{variables};
    die "plan_memory_reconstruction: variables ARRAY required\n"
        unless ref($variables) eq 'ARRAY' && @$variables;
    my $packet = $a{memory_packet};
    die "plan_memory_reconstruction: memory_packet HASH required; recall must carry retained experiential support as well as medoids\n"
        unless ref($packet) eq 'HASH'
            && ($packet->{schema} || '') eq 'Sim::OPT::StructureDesign/memory-packet-1'
            && ref($packet->{support}) eq 'ARRAY'
            && ref($packet->{medoids}) eq 'ARRAY';
    my $child_dir = $a{child_dir} or die "plan_memory_reconstruction: child_dir required\n";
    my $child_config = $a{child_config} || 'memory.pl';
    my $memory_root = defined($a{memory_model_root}) && length($a{memory_model_root})
        ? $a{memory_model_root} : 'btmed';
    die "plan_memory_reconstruction: memory_model_root must be a simple model-directory name\n"
        unless $memory_root =~ /^[A-Za-z0-9_.-]+$/;

    my $cfg = inspect_config($source_config);
    my @vars = sort { $a <=> $b } map { 0 + $_ } @$variables;
    my %active = map { $_ => 1 } @vars;
    for my $v (@vars) {
        die "plan_memory_reconstruction: variable $v absent from source lattice\n"
            unless exists $cfg->{varinumbers}{$v};
    }

    my (@clear_medoids, @source_positions);
    my %seen;
    for my $clear (@$medoids) {
        next if $seen{$clear}++;
        my $h = parse_instance($clear);
        my %pos;
        for my $v (sort { $a <=> $b } keys %{ $cfg->{varinumbers} }) {
            die "plan_memory_reconstruction: medoid '$clear' lacks variable $v\n" unless exists $h->{$v};
            my $lev = 0 + $h->{$v};
            my $max = 0 + $cfg->{varinumbers}{$v};
            die "plan_memory_reconstruction: medoid '$clear' has variable $v level $lev outside 1..$max\n"
                if $lev < 1 || $lev > $max;
            $pos{$v} = $lev;
        }
        push @clear_medoids, $clear;
        push @source_positions, \%pos;
    }
    die "plan_memory_reconstruction: no distinct medoids remain\n" unless @source_positions;

    for my $v (sort { $a <=> $b } keys %{ $cfg->{varinumbers} }) {
        next if $active{$v};
        my %levels = map { $_->{$v} => 1 } @source_positions;
        die "plan_memory_reconstruction: medoids differ on inactive variable $v; include variable $v in reconstruct_memory variables for a shared landscape\n"
            if keys(%levels) > 1;
    }

    # Parse retained direct support once.  The packet already associates every
    # experienced row with the frozen antecedent cluster/medoid; reconstruction
    # must not reclassify it here.
    my @support;
    for my $r (@{ $packet->{support} }) {
        die "plan_memory_reconstruction: malformed memory support record\n"
            unless ref($r) eq 'HASH' && defined($r->{cluster}) && defined($r->{instance}) && defined($r->{row});
        my $h = parse_instance($r->{instance});
        my %pos;
        for my $v (sort { $a <=> $b } keys %{ $cfg->{varinumbers} }) {
            die "plan_memory_reconstruction: support '$r->{instance}' lacks variable $v\n" unless exists $h->{$v};
            my $lev = 0 + $h->{$v};
            my $max = 0 + $cfg->{varinumbers}{$v};
            die "plan_memory_reconstruction: support '$r->{instance}' has variable $v level $lev outside 1..$max\n"
                if $lev < 1 || $lev > $max;
            $pos{$v} = $lev;
        }
        push @support, { %$r, position=>\%pos };
    }

    # Every medoid is mandatory.  The nominal compression width is kept unless
    # the medoid span itself requires a larger interval.  Unlike the former
    # planner, recalled scope never extrapolates beyond the antecedent lattice.
    # The retained direct clouds decide where each compact interval sits.
    my %counts = %{ $cfg->{varinumbers} };
    my (%medium, %ops, %axes, %bounds);
    for my $v (@vars) {
        my $L = 0 + $cfg->{varinumbers}{$v};
        my $nominal = memory_level_count($L);
        my @ml = sort { $a <=> $b } map { 0 + $_->{$v} } @source_positions;
        my $min_m = $ml[0];
        my $max_m = $ml[-1];
        my $span = $max_m - $min_m + 1;
        my $width = $span > $nominal ? $span : $nominal;
        $width = $L if $width > $L;
        my $choice = _memory_choose_axis_window(
            levels=>$L, width=>$width, medoid_levels=>\@ml,
            support=>\@support, variable=>$v,
        );
        my ($lo, $hi) = ($choice->{low}, $choice->{high});
        $counts{$v} = $width;
        $bounds{$v} = { source_low=>$lo, source_high=>$hi };

        my $op = _extract_operation($cfg->{text}, $v);
        my (@begin, @end);
        if ($L <= 1) {
            @begin = @{ $op->{begin} };
            @end = @{ $op->{end} };
        } else {
            @begin = @{ _interp_vec($op->{begin}, $op->{end}, $lo - 1, $L - 1) };
            @end   = @{ _interp_vec($op->{begin}, $op->{end}, $hi - 1, $L - 1) };
        }
        $ops{$v} = { %$op, child_begin=>\@begin, child_end=>\@end };
        $axes{$v} = {
            source_levels=>$L,
            nominal_memory_levels=>$nominal,
            medoid_source_min=>$min_m,
            medoid_source_max=>$max_m,
            medoid_source_span=>$span,
            memory_source_low=>$lo,
            memory_source_high=>$hi,
            memory_levels=>$width,
            support_axis_weighted_coverage=>0 + $choice->{score},
            support_axis_raw_coverage=>0 + $choice->{raw},
            compression_limited_by_medoid_span=>($span > $nominal ? JSON::PP::true : JSON::PP::false),
        };
    }

    # A remembered category that has direct support should not disappear merely
    # because its nearest retained experience lies just outside the nominal
    # compressed box.  Expand the box minimally until every non-empty retained
    # category contributes at least one direct support point.  Categories with
    # zero direct support remain represented by their medoid alone.
    my %nonempty_cluster = map { (0 + $_->{cluster}) => 1 } @support;
    my @scope_expansions;
    while (1) {
        my %represented;
        for my $r (@support) {
            my $inside = 1;
            for my $v (@vars) {
                my $x = 0 + $r->{position}{$v};
                $inside = 0 if $x < $bounds{$v}{source_low} || $x > $bounds{$v}{source_high};
            }
            $represented{0 + $r->{cluster}} = 1 if $inside;
        }
        my @missing = grep { !$represented{$_} } sort { $a <=> $b } keys %nonempty_cluster;
        last unless @missing;
        my %missing = map { $_ => 1 } @missing;
        my $best;
        for my $r (@support) {
            my $cluster = 0 + $r->{cluster};
            next unless $missing{$cluster};
            my %candidate = map {
                $_ => { source_low=>$bounds{$_}{source_low}, source_high=>$bounds{$_}{source_high} }
            } @vars;
            for my $v (@vars) {
                my $x = 0 + $r->{position}{$v};
                $candidate{$v}{source_low} = $x if $x < $candidate{$v}{source_low};
                $candidate{$v}{source_high} = $x if $x > $candidate{$v}{source_high};
            }
            my $volume = 1;
            $volume *= ($candidate{$_}{source_high} - $candidate{$_}{source_low} + 1) for @vars;
            my $cand = { volume=>$volume, cluster=>$cluster, instance=>$r->{instance}, bounds=>\%candidate };
            if (!defined($best)
                || $cand->{volume} < $best->{volume}
                || ($cand->{volume} == $best->{volume} && $cand->{cluster} < $best->{cluster})
                || ($cand->{volume} == $best->{volume} && $cand->{cluster} == $best->{cluster}
                    && $cand->{instance} lt $best->{instance})) {
                $best = $cand;
            }
        }
        die "plan_memory_reconstruction: could not include direct support for retained categories\n" unless $best;
        for my $v (@vars) {
            $bounds{$v}{source_low} = $best->{bounds}{$v}{source_low};
            $bounds{$v}{source_high} = $best->{bounds}{$v}{source_high};
        }
        push @scope_expansions, {
            cluster=>$best->{cluster}, support_instance=>$best->{instance}, resulting_lattice_rows=>$best->{volume},
        };
    }

    # Rebuild axis counts and physical operations after any category-support
    # expansion.  The final bounds remain a compact subset of the source lattice.
    for my $v (@vars) {
        my $L = 0 + $cfg->{varinumbers}{$v};
        my $lo = $bounds{$v}{source_low};
        my $hi = $bounds{$v}{source_high};
        my $width = $hi - $lo + 1;
        $counts{$v} = $width;
        my $op = _extract_operation($cfg->{text}, $v);
        my (@begin, @end);
        if ($L <= 1) {
            @begin = @{ $op->{begin} }; @end = @{ $op->{end} };
        } else {
            @begin = @{ _interp_vec($op->{begin}, $op->{end}, $lo - 1, $L - 1) };
            @end   = @{ _interp_vec($op->{begin}, $op->{end}, $hi - 1, $L - 1) };
        }
        $ops{$v} = { %$op, child_begin=>\@begin, child_end=>\@end };
        $axes{$v}{memory_source_low} = $lo;
        $axes{$v}{memory_source_high} = $hi;
        $axes{$v}{memory_levels} = $width;
        $axes{$v}{compression_limited_by_retained_support} =
            ($width > $axes{$v}{medoid_source_span} && $width > $axes{$v}{nominal_memory_levels})
                ? JSON::PP::true : JSON::PP::false;
    }

    my @positions;
    for my $src (@source_positions) {
        my %p = %$src;
        for my $v (@vars) { $p{$v} = $src->{$v} - $bounds{$v}{source_low} + 1; }
        push @positions, \%p;
    }

    # Retained experiences inside the chosen compact reconstruction domain are
    # materialised as seed evidence.  Experiences outside remain in memory and
    # influence scope placement, but do not force the current recall to expand.
    my (@support_in, @support_out);
    my (%support_total_by_cluster, %support_in_by_cluster);
    for my $r (@support) {
        $support_total_by_cluster{$r->{cluster}}++;
        my $inside = 1;
        for my $v (@vars) {
            my $x = 0 + $r->{position}{$v};
            $inside = 0 if $x < $bounds{$v}{source_low} || $x > $bounds{$v}{source_high};
        }
        if ($inside) {
            my %local = %{ $r->{position} };
            for my $v (@vars) { $local{$v} = $local{$v} - $bounds{$v}{source_low} + 1; }
            push @support_in, { %$r, local_position=>\%local, local_instance=>format_instance(\%local) };
            $support_in_by_cluster{$r->{cluster}}++;
        } else {
            push @support_out, $r;
        }
    }

    # Enriched recall uses actual remembered support positions as additional
    # star centres.  Selection is deterministic maximin coverage within each
    # antecedent cluster, beginning at that cluster's retained medoid.
    my $cloud_divisions;
    if (exists $a{cloud_star_divisions}) {
        $cloud_divisions = $a{cloud_star_divisions};
    } elsif (exists $a{star_divisions}) {
        # Compatibility with procedures written before memory packets existed;
        # the geometry is nevertheless cloud-conditioned, not lattice-wide.
        $cloud_divisions = $a{star_divisions};
    }
    if (defined $cloud_divisions) {
        die "plan_memory_reconstruction: cloud_star_divisions must be an integer >= 2\n"
            unless "$cloud_divisions" =~ /^\d+$/ && $cloud_divisions >= 2;
    }
    my $target_per_cluster = defined($cloud_divisions) ? (2 ** ($cloud_divisions - 1) + 1) : 1;

    my %packet_medoid_by_instance = map {
        (defined($_->{instance}) ? ($_->{instance} => $_) : ())
    } grep { ref($_) eq 'HASH' } @{ $packet->{medoids} };
    my (@cloud_source_records, @cloud_positions);
    for my $i (0 .. $#clear_medoids) {
        my $mid_id = $clear_medoids[$i];
        my $pm = $packet_medoid_by_instance{$mid_id};
        die "plan_memory_reconstruction: memory packet lacks medoid '$mid_id'\n" unless ref($pm) eq 'HASH' && defined($pm->{cluster});
        my $cluster = 0 + $pm->{cluster};
        next if $target_per_cluster <= 1;
        my @cand = grep { 0 + $_->{cluster} == $cluster } @support_in;
        my $picked = _memory_select_cloud_centres(
            medoid=>$source_positions[$i], candidates=>\@cand,
            variables=>\@vars, source_counts=>$cfg->{varinumbers}, target=>$target_per_cluster,
        );
        for my $r (@$picked) {
            my %local = %{ $r->{local_position} };
            push @cloud_positions, \%local;
            push @cloud_source_records, {
                cluster=>$cluster,
                instance=>$r->{instance},
                local_instance=>$r->{local_instance},
                position=>{ %{ $r->{position} } },
                local_position=>{ %local },
            };
        }
    }

    my (@all_positions, %position_seen);
    for my $pos (@positions, @cloud_positions) {
        my $id = format_instance($pos);
        next if $position_seen{$id}++;
        push @all_positions, { %$pos };
    }

    my $memory_medium_override = exists($a{lattice_mediumiters}) ? $a{lattice_mediumiters} : $a{mediumiters};
    %medium = %{ _centered_mediumiters(
        counts=>\%counts, override=>$memory_medium_override,
        label=>'plan_memory_reconstruction mediumiters',
    ) };

    my $expected_lattice_rows = 1;
    $expected_lattice_rows *= 0 + $counts{$_} for @vars;

    my %star_sample_ids;
    for my $pos (@all_positions) {
        for my $v (@vars) {
            for my $lev (1 .. (0 + $counts{$v})) {
                my %q = %$pos; $q{$v} = $lev;
                $star_sample_ids{ format_instance(\%q) } = 1;
            }
        }
    }
    my %all_sample_ids = %star_sample_ids;
    $all_sample_ids{ $_->{local_instance} } = 1 for @support_in;

    my $dowhat_inherit = $a{dowhat_inherit} || {};
    die "plan_memory_reconstruction: dowhat_inherit must be a HASH reference\n" unless ref($dowhat_inherit) eq 'HASH';
    for my $key (keys %$dowhat_inherit) {
        die "plan_memory_reconstruction: inherited dowhat keys/values must be strings\n"
            if !defined($key) || ref($key) || !length($key) || !defined($dowhat_inherit->{$key}) || ref($dowhat_inherit->{$key});
    }

    my %support_total_json = map { ("$_", 0 + $support_total_by_cluster{$_}) } keys %support_total_by_cluster;
    my %support_in_json = map { ("$_", 0 + ($support_in_by_cluster{$_} || 0)) } keys %support_total_by_cluster;

    return {
        schema=>'Sim::OPT::StructureDesign/memory-reconstruction-plan-5',
        operation=>'reconstruct_memory',
        reconstruction_mode=>'experiential_cloud',
        mode=>'shared_multistar_experiential_memory',
        scope_basis=>'compact_window_weighted_by_retained_experience',
        scope_expansions=>\@scope_expansions,
        source_config=>$source_config,
        source_dir=>$cfg->{mypath},
        source_model_root=>$cfg->{file},
        model_root=>$memory_root,
        medoids=>\@clear_medoids,
        source_starpositions=>\@source_positions,
        medoid_starpositions=>\@positions,
        cloud_source_starpositions=>\@cloud_source_records,
        cloud_starpositions=>\@cloud_positions,
        starpositions=>\@all_positions,
        (defined($cloud_divisions) ? (cloud_star_divisions=>0+$cloud_divisions, cloud_target_centres_per_cluster=>0+$target_per_cluster) : ()),
        medoid_star_count=>scalar(@positions),
        cloud_star_count=>scalar(@cloud_positions),
        effective_star_count=>scalar(@all_positions),
        retained_support_total=>scalar(@support),
        retained_support_in_scope=>scalar(@support_in),
        retained_support_out_of_scope=>scalar(@support_out),
        retained_support_by_cluster=>\%support_total_json,
        retained_support_in_scope_by_cluster=>\%support_in_json,
        retained_support=>\@support_in,
        variables=>\@vars,
        child_dir=>$child_dir,
        child_config=>$child_config,
        lattice_counts=>\%counts,
        medium_default=>'center',
        medium_overrides=>ref($memory_medium_override) eq 'HASH' ? { %$memory_medium_override } : {},
        lattice_medium=>\%medium,
        operations=>\%ops,
        per_variable_axes=>\%axes,
        expected_star_sample_rows=>scalar(keys %star_sample_ids),
        expected_sample_rows=>scalar(keys %all_sample_ids),
        expected_lattice_rows=>$expected_lattice_rows,
        dowhat_inherit=>{ %$dowhat_inherit },
        metamodel=>'y', convergeintomodel=>'y',
    };
}

sub _render_memory_config_legacy {
    my ($plan) = @_;
    die "render_memory_config: memory plan required\n"
        unless ref($plan) eq 'HASH'
            && ($plan->{operation} || '') eq 'reconstruct_memory'
            && ($plan->{mode} || '') eq 'shared_multistar_compressed';
    my $cfg = inspect_config($plan->{source_config});
    my $txt = $cfg->{text};
    my $child_dir = $plan->{child_dir};

    my $n = ($txt =~ s/^(?!\s*#)(\s*\$mypath\s*=\s*)["'][^"']+["']/$1"$child_dir"/m);
    die "memory config: could not patch \$mypath\n" unless $n == 1;
    $n = ($txt =~ s/^(?!\s*#)(\s*\$file\s*=\s*)["'][^"']+["']/$1"$plan->{model_root}"/m);
    die "memory config: could not patch \$file\n" unless $n == 1;

    my @vars = @{ $plan->{variables} };
    my $first = $vars[0];
    # With explicit starpositions, the numeric prefix is not used to generate
    # centres.  1> simply selects Sim::OPT's star-search path for this block.
    my $sweep = '@sweeps = ( [ [ ' . _quote_scalar('1>' . $first);
    if (@vars > 1) {
        $sweep .= ', ' . join(' , ', @vars[1 .. $#vars]);
    }
    $sweep .= ' ] ] );';
    $n = ($txt =~ s/^(?!\s*#)\s*\@sweeps\s*=\s*[^;]+;/$sweep/m);
    die "memory config: could not patch active \@sweeps\n" unless $n == 1;

    $txt = _replace_hash_assignment($txt, '@varinumbers', $plan->{lattice_counts});
    $txt = _replace_hash_assignment($txt, '@mediumiters', $plan->{lattice_medium});
    for my $v (@vars) {
        $txt = _patch_operation($txt, $v, $plan->{operations}{$v});
    }

    my $sp = _memory_format_starpositions($plan->{starpositions});
    $txt = _memory_set_dowhat_perl_value($txt, 'starpositions', $sp);
    for my $key (sort keys %{ $plan->{dowhat_inherit} || {} }) {
        $txt = _memory_set_dowhat_string($txt, $key, $plan->{dowhat_inherit}{$key});
    }
    # Stage semantics remain authoritative over inherited user preferences.
    $txt = _memory_set_dowhat_string($txt, 'names', 'short');
    $txt = _memory_set_dowhat_string($txt, 'metamodel', 'y');
    $txt = _memory_set_dowhat_string($txt, 'convergeintomodel', 'y');

    my $stamp = "# Generated shared compressed multi-star memory reconstruction by Sim::OPT::StructureDesign $VERSION\n"
              . "# mediumiters default: central level unless explicitly overridden\n"
              . "# Retained medoids remain explicit starpositions in one Sim::OPT search.\n"
              . (defined($plan->{star_divisions})
                    ? "# Enriched recall: star_divisions=$plan->{star_divisions}; $plan->{subdivision_star_count} subdivision centres are unioned with the medoid centres.\n"
                    : "# Minimal recall: no auxiliary subdivision centres.\n")
              . "# Active axes use a shared source-grid window: nominally compressed, enlarged only when needed to contain all medoids exactly.\n"
              . "# Medoids: " . scalar(@{ $plan->{medoids} }) . "\n"
              . "# Effective star centres: $plan->{effective_star_count}\n"
              . "# Expected sampled union: $plan->{expected_sample_rows} rows\n"
              . "# Expected reconstructed lattice: $plan->{expected_lattice_rows} rows\n";
    return $stamp . $txt;
}

sub _render_memory_config_experiential {
    my ($plan) = @_;
    die "render_memory_config: memory plan required\n"
        unless ref($plan) eq 'HASH'
            && ($plan->{operation} || '') eq 'reconstruct_memory'
            && ($plan->{mode} || '') eq 'shared_multistar_experiential_memory';
    my $cfg = inspect_config($plan->{source_config});
    my $txt = $cfg->{text};
    my $child_dir = $plan->{child_dir};

    my $n = ($txt =~ s/^(?!\s*#)(\s*\$mypath\s*=\s*)["'][^"']+["']/$1"$child_dir"/m);
    die "memory config: could not patch \$mypath\n" unless $n == 1;
    $n = ($txt =~ s/^(?!\s*#)(\s*\$file\s*=\s*)["'][^"']+["']/$1"$plan->{model_root}"/m);
    die "memory config: could not patch \$file\n" unless $n == 1;

    my @vars = @{ $plan->{variables} };
    my $first = $vars[0];
    # With explicit starpositions, the numeric prefix is not used to generate
    # centres.  1> simply selects Sim::OPT's star-search path for this block.
    my $sweep = '@sweeps = ( [ [ ' . _quote_scalar('1>' . $first);
    if (@vars > 1) {
        $sweep .= ', ' . join(' , ', @vars[1 .. $#vars]);
    }
    $sweep .= ' ] ] );';
    $n = ($txt =~ s/^(?!\s*#)\s*\@sweeps\s*=\s*[^;]+;/$sweep/m);
    die "memory config: could not patch active \@sweeps\n" unless $n == 1;

    $txt = _replace_hash_assignment($txt, '@varinumbers', $plan->{lattice_counts});
    $txt = _replace_hash_assignment($txt, '@mediumiters', $plan->{lattice_medium});
    for my $v (@vars) {
        $txt = _patch_operation($txt, $v, $plan->{operations}{$v});
    }

    my $sp = _memory_format_starpositions($plan->{starpositions});
    $txt = _memory_set_dowhat_perl_value($txt, 'starpositions', $sp);
    for my $key (sort keys %{ $plan->{dowhat_inherit} || {} }) {
        $txt = _memory_set_dowhat_string($txt, $key, $plan->{dowhat_inherit}{$key});
    }
    # Stage semantics remain authoritative over inherited user preferences.
    $txt = _memory_set_dowhat_string($txt, 'names', 'short');
    $txt = _memory_set_dowhat_string($txt, 'metamodel', 'y');
    $txt = _memory_set_dowhat_string($txt, 'convergeintomodel', 'y');

    my $stamp = "# Generated experiential-memory reconstruction by Sim::OPT::StructureDesign $VERSION\n"
              . "# mediumiters default: central level unless explicitly overridden\n"
              . "# Retained medoids remain privileged explicit starpositions.\n"
              . (defined($plan->{cloud_star_divisions})
                    ? "# Enriched recall: cloud_star_divisions=$plan->{cloud_star_divisions}; $plan->{cloud_star_count} additional centres are selected from retained cluster-conditioned experience.\n"
                    : "# Minimal recall: one reactivation star per retained medoid; retained direct evidence still seeds the surrogate.\n")
              . "# Scope is compact and source-grid aligned; retained experiential clouds position the compact window without expanding to their full min/max extent.\n"
              . "# Retained direct support in scope: $plan->{retained_support_in_scope}/$plan->{retained_support_total} rows\n"
              . "# Medoids: " . scalar(@{ $plan->{medoids} }) . "\n"
              . "# Effective star centres: $plan->{effective_star_count}\n"
              . "# Expected star-sampled union: $plan->{expected_star_sample_rows} rows\n"
              . "# Expected sampled+remembered union: $plan->{expected_sample_rows} rows\n"
              . "# Expected reconstructed lattice: $plan->{expected_lattice_rows} rows\n";
    return $stamp . $txt;
}

sub render_memory_config {
    my ($plan) = @_;
    die "render_memory_config: memory plan required\n"
        unless ref($plan) eq 'HASH' && ($plan->{operation} || '') eq 'reconstruct_memory';
    my $mode = $plan->{reconstruction_mode};
    $mode = (($plan->{mode} || '') eq 'shared_multistar_experiential_memory')
        ? 'experiential_cloud' : 'legacy_medoid_only'
        unless defined($mode) && length($mode);
    return _render_memory_config_legacy($plan) if $mode eq 'legacy_medoid_only';
    return _render_memory_config_experiential($plan) if $mode eq 'experiential_cloud';
    die "render_memory_config: unsupported reconstruction_mode '$mode'\n";
}

sub create_memory_workspace {
    my (%a) = @_;
    my $plan = $a{plan} || plan_memory_reconstruction(%a);
    my $commit = $a{commit} ? 1 : 0;
    return $plan unless $commit;
    my $child_dir = $plan->{child_dir};
    die "create_memory_workspace: refusing to overwrite $child_dir\n" if -e $child_dir;
    my $root_model = $a{root_model_dir} or die "create_memory_workspace: root_model_dir required\n";
    die "create_memory_workspace: root model not found: $root_model\n" unless -d $root_model;

    make_path($child_dir);
    _copy_tree($root_model, "$child_dir/$plan->{model_root}");
    _spit("$child_dir/$plan->{child_config}", render_memory_config($plan));
    write_manifest($plan, "$child_dir/structuredesign-memory-local.json");
    return $plan;
}


1;

__END__

=head1 NAME

Sim::OPT::StructureDesign - explicit transformations of Sim::OPT design lattices

=head1 DESIGN VOCABULARY

=over 4

=item search

Evaluate points on the current design lattice. This remains Sim::OPT's job; this
module records the lattice on which the search is performed.

=item zoom_in

Reduce scope around an incumbent while decreasing grid spacing (increasing
resolution). The local workspace is centred on the incumbent when the requested
window fits inside the parent scope. At a parent boundary, the whole local
window is shifted inward so that reduce_scope remains a subset of the parent
scope while preserving the requested number of local levels and fine-grid
resolution.

=item zoom_out

Embed results obtained on a finer local lattice back into a finer global lattice
covering exactly the parent scope. Existing parent levels map by
j' = 1 + r (j - 1); zooming introduces no coordinate-origin offset. The
resulting global lattice may contain unsampled points (voids).

=item pan

Move the sampled window while preserving its scope and resolution. A pan can be
combined with zooming, but is represented separately in the manifest.

=back


=head1 MEMORY RECONSTRUCTION MODES

C<plan_memory_reconstruction()> supports two explicit reconstruction semantics.
The selected mode is a scientific choice and should normally be written in the
procedure as C<reconstruction_mode>.

=head2 C<legacy_medoid_only>

This mode reproduces the historical medoid-only reconstruction used by the
first recall runs.  The abstraction medoids are the retained cues.  A compact
shared lattice is derived from their positions, every medoid is an explicit
star centre, and optional C<star_divisions> adds evenly distributed auxiliary
centres over that shared recalled lattice.  No retained experiential cloud is
required or used.

=head2 C<experiential_cloud>

This mode implements medoid-anchored experiential recall.  In addition to the
frozen abstraction, C<memory_packet> must contain cluster-conditioned direct
experience produced by the retention step.  The retained clouds position the
compact recalled scope, direct remembered rows seed the surrogate, medoids
remain mandatory privileged centres, and optional C<cloud_star_divisions>
selects additional star centres from actual retained experiences within their
frozen categories.

=head2 Compatibility when the switch is omitted

For reproducibility of procedures written before the explicit switch existed,
mode inference is intentionally conservative: a call carrying C<memory_packet>
is interpreted as C<experiential_cloud>; otherwise it is interpreted as
C<legacy_medoid_only>.  New procedures should nevertheless state the mode
explicitly so that the scientific reconstruction semantics are visible in the
procedure itself.

=head1 SAFETY MODEL

Planning is pure and non-destructive. Workspace creation refuses to overwrite an
existing destination. Merge/renaming should be executed only from a validated
manifest; short numeric IDs must be treated as identifiers, never replaced by a
blind text substitution.

=cut
