package Sim::OPT::ClusterMedoid;

# Sim::OPT::ClusterMedoid clusters discrete simulation/design instances and
# identifies one observed medoid instance for each cluster.
#
# Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.
# gianluca.brunetti@gmail.com.
# This software is distributed under a dual licence, open-source (GPL v3)
# and proprietary. The present copy is GPL. By consequence, this is free
# software. You can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation,
# version 3.

use strict;
use warnings;
use feature 'say';
use Exporter 'import';
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use JSON::PP ();
use List::Util qw(min max);
use Text::CSV;

our @EXPORT = qw(cluster_medoid);
our @EXPORT_OK = qw(cluster_medoid run_cli);
our $VERSION = '0.008';
our $ABSTRACT = 'Cluster discrete Sim::OPT problem landscapes with a hybrid arithmetic-geometric similarity and identify representative medoid instances.';

sub cluster_medoid {
    my (%args) = @_;

    my $config_file = $args{search_config} // $args{config_file};
    my $results_file = $args{results_file};
    my $output_prefix = $args{output_prefix};

    die "cluster_medoid requires search_config => FILE\n"
        unless defined($config_file) && length($config_file);
    die "cluster_medoid requires results_file => FILE\n"
        unless defined($results_file) && length($results_file);

    my $self = bless {
        verbose => $args{verbose} ? 1 : 0,
    }, __PACKAGE__;

    return $self->_run($config_file, $results_file, $output_prefix);
}

sub run_cli {
    my (@argv) = @_ ? @_ : @ARGV;
    my ($config_file, $results_file, $output_prefix) = @argv;

    die "Usage: simopt-clustermedoid SEARCH_CONFIG.pl RESULTS.csv [OUTPUT_PREFIX]\n"
        unless defined($config_file) && defined($results_file);

    my $res = cluster_medoid(
        search_config => $config_file,
        results_file  => $results_file,
        output_prefix => $output_prefix,
        verbose       => 1,
    );

    say "rows: $res->{rows}";
    say "instance prefix: $res->{instance_prefix}";
    say "performance column: $res->{performance_column}";
    say "fixed variables: " . (@{$res->{fixed_variables}} ? join(',', @{$res->{fixed_variables}}) : '(none)');
    say "context variables: " . (@{$res->{context_variables}} ? join(',', @{$res->{context_variables}}) : '(none)');
    say "problem variables: " . join(',', @{$res->{problem_variables}});
    say "lambda: $res->{lambda}";
    say "clusters: $res->{clusters}";
    say "silhouette: " . sprintf('%.6f', $res->{silhouette});
    say "clustered: $res->{files}{clustered}";
    say "medoids: $res->{files}{medoids}";
    say "silhouette scores: $res->{files}{silhouette}";
    say "info: $res->{files}{info}";

    return $res;
}

sub _run {
    my ($self, $config_file, $results_file, $output_prefix) = @_;

    $config_file  = File::Spec->rel2abs($config_file);
    $results_file = File::Spec->rel2abs($results_file);

    my $loaded = $self->_load_search_config($config_file);
    my $cfg = $loaded->{landscapecluster};

    my $mypath = $loaded->{mypath};
    my $root_file = $loaded->{file};
    die "Search config must define \$mypath\n" unless defined($mypath) && length($mypath);
    die "Search config must define \$file\n" unless defined($root_file) && length($root_file);

    my $instance_prefix = File::Spec->catfile($mypath, $root_file);
    $instance_prefix =~ s{/+}{/}g;
    $self->{instance_prefix} = $instance_prefix;

    my $sweep_index = exists($cfg->{sweep_index}) ? int($cfg->{sweep_index}) : 0;
    die "sweep_index must be >= 0\n" if $sweep_index < 0;
    die "No \@varinumbers entry $sweep_index exists in search config\n"
        unless defined $loaded->{varinumbers}[$sweep_index];

    my $levels_cfg = $loaded->{varinumbers}[$sweep_index];
    die "\@varinumbers[$sweep_index] must be a hash reference\n"
        unless ref($levels_cfg) eq 'HASH' && keys %$levels_cfg;

    my %levels;
    for my $k (keys %$levels_cfg) {
        die "Variable id '$k' is not an integer\n" unless $k =~ /^\d+$/;
        my $L = 0 + $levels_cfg->{$k};
        die "Variable $k must have at least 1 level\n" if $L < 1;
        $levels{0 + $k} = $L;
    }
    my @variable_ids = sort { $a <=> $b } keys %levels;
    my %known = map { $_ => 1 } @variable_ids;

    # Variables may be fixed at a non-1 coordinate after StructureDesign
    # re-embedding.  Preserve the historical one-level rule, and allow an
    # explicit fixed_levels map for fixed coordinates on a larger lattice.
    my %fixed_level = map { $_ => 1 } grep { $levels{$_} == 1 } @variable_ids;
    if (exists $cfg->{fixed_levels}) {
        die "fixed_levels must be a hash\n" unless ref($cfg->{fixed_levels}) eq 'HASH';
        for my $k (keys %{$cfg->{fixed_levels}}) {
            die "Fixed variable id '$k' is not an integer\n" unless $k =~ /^\d+$/;
            my $v = 0 + $k;
            die "Fixed variable $v is not present in \@varinumbers[$sweep_index]\n" unless $known{$v};
            my $lev = $cfg->{fixed_levels}{$k};
            die "Fixed level for variable $v must be an integer\n" unless defined($lev) && "$lev" =~ /^\d+$/;
            $lev = 0 + $lev;
            die "Fixed level for variable $v is outside 1..$levels{$v}\n"
                if $lev < 1 || $lev > $levels{$v};
            if ($levels{$v} == 1 && $lev != 1) {
                die "One-level variable $v can only be fixed at level 1\n";
            }
            $fixed_level{$v} = $lev;
        }
    }
    my @fixed = grep { exists $fixed_level{$_} } @variable_ids;
    my @metric_variable_ids = grep { !exists $fixed_level{$_} } @variable_ids;

    my @context_requested = (ref($cfg->{context_variables}) eq 'ARRAY')
        ? map { 0 + $_ } @{$cfg->{context_variables}}
        : ();
    my %seen_context;
    for my $v (@context_requested) {
        die "Context variable $v is not present in \@varinumbers[$sweep_index]\n" unless $known{$v};
        die "Context variable $v is listed more than once\n" if $seen_context{$v}++;
    }
    my %is_context_requested = map { $_ => 1 } @context_requested;
    # One-level variables are valid Sim::OPT coordinates but carry no distance
    # information.  Keep them for row validation/output and omit them only
    # from the similarity metric.
    my @context = grep { !exists $fixed_level{$_} } @context_requested;
    my %is_context = map { $_ => 1 } @context;
    my @problem = grep { !exists $fixed_level{$_} && !$is_context_requested{$_} } @variable_ids;

    my $lambda = exists($cfg->{lambda}) ? 0 + $cfg->{lambda} : 0.5;
    die "lambda must be between 0 and 1\n" if $lambda < 0 || $lambda > 1;

    my %variable_weight = map { $_ => 1.0 } @metric_variable_ids;
    if (exists $cfg->{variable_weights}) {
        die "variable_weights must be a hash\n" unless ref($cfg->{variable_weights}) eq 'HASH';
        for my $v (@metric_variable_ids) {
            my $w = exists($cfg->{variable_weights}{$v}) ? 0 + $cfg->{variable_weights}{$v}
                  : exists($cfg->{variable_weights}{"$v"}) ? 0 + $cfg->{variable_weights}{"$v"}
                  : 1.0;
            die "Weight for variable $v must be > 0\n" if $w <= 0;
            $variable_weight{$v} = $w;
        }
    }

    my %component_weight = (context => 1.0, problem => 1.0, performance => 1.0);
    if (exists $cfg->{component_weights}) {
        die "component_weights must be a hash\n" unless ref($cfg->{component_weights}) eq 'HASH';
        for my $name (qw(context problem performance)) {
            next unless exists $cfg->{component_weights}{$name};
            my $w = 0 + $cfg->{component_weights}{$name};
            die "component_weights.$name must be > 0\n" if $w <= 0;
            $component_weight{$name} = $w;
        }
    }

    my $combination_col_spec = exists($cfg->{combination_column}) ? $cfg->{combination_column} : 0;
    my $performance_col_spec = exists($cfg->{performance_column}) ? $cfg->{performance_column} : -4;

    my $pcfg = (ref($cfg->{performance}) eq 'HASH') ? $cfg->{performance} : {};
    my $divisions = exists($pcfg->{divisions}) ? int($pcfg->{divisions}) : 100;
    die "performance.divisions must be >= 1\n" if $divisions < 1;

    my $ccfg = (ref($cfg->{clustering}) eq 'HASH') ? $cfg->{clustering} : {};
    my $max_iterations = exists($ccfg->{max_iterations}) ? int($ccfg->{max_iterations}) : 50;
    die "clustering.max_iterations must be >= 1\n" if $max_iterations < 1;

    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });
    open my $fh, '<', $results_file or die "Cannot open $results_file: $!\n";
    my @raw;
    while (my $r = $csv->getline($fh)) {
        push @raw, [@$r];
    }
    close $fh;
    die "Dataset is empty\n" unless @raw;

    my $header_mode = exists($cfg->{header}) ? $cfg->{header} : 'auto';
    my $has_header;
    if (!ref($header_mode) && $header_mode eq 'auto') {
        my $r = $raw[0];
        my $pidx = _resolve_column_index($performance_col_spec, scalar(@$r), 'performance_column', 1);
        $has_header = _is_number($r->[$pidx]) ? 0 : 1;
    } else {
        $has_header = $header_mode ? 1 : 0;
    }
    my $header = $has_header ? shift @raw : undef;
    die "No data rows after header\n" unless @raw;

    my @rows;
    for my $i (0 .. $#raw) {
        my $fields = $raw[$i];
        my $csv_row = $i + 1 + ($has_header ? 1 : 0);
        my $nf = scalar @$fields;
        my $combination_col = _resolve_column_index($combination_col_spec, $nf, 'combination_column', $csv_row);
        my $performance_col = _resolve_column_index($performance_col_spec, $nf, 'performance_column', $csv_row);

        die "Non-numeric performance at CSV row $csv_row, column $performance_col_spec: '$fields->[$performance_col]'\n"
            unless _is_number($fields->[$performance_col]);

        my $combo = $self->_parse_combo($fields->[$combination_col], $csv_row);
        my %present = map { $_ => 1 } keys %$combo;
        my @missing = grep { !$present{$_} } @variable_ids;
        my @extra = grep { !$known{$_} } keys %$combo;
        die "CSV row $csv_row variable mismatch; missing=[@missing], extra=[@extra]\n"
            if @missing || @extra;

        for my $v (@variable_ids) {
            my $lev = $combo->{$v};
            die "CSV row $csv_row: variable $v has level $lev outside 1..$levels{$v}\n"
                if $lev < 1 || $lev > $levels{$v};
            if (exists $fixed_level{$v} && $lev != $fixed_level{$v}) {
                die "CSV row $csv_row: fixed variable $v has level $lev; expected $fixed_level{$v}\n";
            }
        }

        push @rows, {
            fields      => $fields,
            combo_text  => $fields->[$combination_col],
            combo       => $combo,
            performance => 0 + $fields->[$performance_col],
            csv_row     => $csv_row,
        };
    }

    my $n = scalar @rows;
    my @performances = map { $_->{performance} } @rows;
    my $pbest = exists($pcfg->{best}) ? 0 + $pcfg->{best} : min(@performances);
    my $pworst = exists($pcfg->{worst}) ? 0 + $pcfg->{worst} : max(@performances);
    my $pspan = abs($pworst - $pbest);
    my $pstep = $pspan > 0 ? $pspan / $divisions : 0;

    my %var_sim;
    for my $v (@metric_variable_ids) {
        my $L = $levels{$v};
        my @s;
        for my $delta (0 .. $L - 1) {
            my $d = log(1 + $delta) / log($L);
            $d = _clamp01($d);
            push @s, _clamp01(1 - $d);
        }
        $var_sim{$v} = \@s;
    }

    my %perf_similarity_cache;
    my $hybrid = sub {
        my ($values, $weights) = @_;
        return _hybrid_from_values($values, $weights, $lambda);
    };

    my $group_similarity = sub {
        my ($a, $b, $vars) = @_;
        my (@s, @w);
        for my $v (@$vars) {
            my $delta = abs($a->{combo}{$v} - $b->{combo}{$v});
            push @s, $var_sim{$v}[$delta];
            push @w, $variable_weight{$v};
        }
        return $hybrid->(\@s, \@w);
    };

    my $performance_similarity = sub {
        my ($a, $b) = @_;
        return 1 if $pspan == 0;
        my $diff = abs($a->{performance} - $b->{performance});
        return 1 if $diff == 0;
        my $key = sprintf('%.12g', $diff);
        return $perf_similarity_cache{$key} if exists $perf_similarity_cache{$key};
        my $steps = $pstep > 0 ? $diff / $pstep : 0;
        $steps = $divisions if $steps > $divisions;
        my $d = log(1 + $steps) / log(1 + $divisions);
        my $s = _clamp01(1 - $d);
        $perf_similarity_cache{$key} = $s;
        return $s;
    };

    my $overall_similarity = sub {
        my ($a, $b) = @_;
        my (@s, @w);
        if (@context) {
            push @s, $group_similarity->($a, $b, \@context);
            push @w, $component_weight{context};
        }
        if (@problem) {
            push @s, $group_similarity->($a, $b, \@problem);
            push @w, $component_weight{problem};
        }
        push @s, $performance_similarity->($a, $b);
        push @w, $component_weight{performance};
        return $hybrid->(\@s, \@w);
    };

    my $DIST_SCALE = 1_000_000_000;
    my $distance_q = sub {
        my ($i, $j) = @_;
        return 0 if $i == $j;
        my $d = _clamp01(1 - $overall_similarity->($rows[$i], $rows[$j]));
        return int($d * $DIST_SCALE + 0.5);
    };

    # Exact PAM-style k-medoids needs a dense n x n distance matrix and
    # quadratic medoid updates.  That is appropriate for small landscapes but
    # not for StructureDesign surrogate lattices with hundreds of thousands of
    # rows.  In automatic mode, retain the historical exact path while its
    # matrix fits within the configured budget; otherwise use CLARA, the
    # standard sampling extension of k-medoids for large data sets.
    my $algorithm = exists($ccfg->{algorithm}) ? lc($ccfg->{algorithm}) : 'auto';
    die "clustering.algorithm must be exact, clara, or auto\n"
        unless $algorithm eq 'exact' || $algorithm eq 'clara' || $algorithm eq 'auto';
    my $max_exact_matrix_bytes = exists($ccfg->{max_exact_matrix_bytes})
        ? 0 + $ccfg->{max_exact_matrix_bytes}
        : 512 * 1024 * 1024;
    die "clustering.max_exact_matrix_bytes must be >= 0\n" if $max_exact_matrix_bytes < 0;
    my $exact_matrix_bytes = 4 * $n * $n;
    if ($algorithm eq 'auto') {
        $algorithm = $exact_matrix_bytes <= $max_exact_matrix_bytes ? 'exact' : 'clara';
    }

    my $requested = exists($ccfg->{clusters}) ? $ccfg->{clusters} : 'auto';
    my ($chosen_k, $chosen_medoids, $chosen_assign, $chosen_silhouette);
    my @score_table;
    my @distortion_table;
    my $selection_method = 'silhouette';
    my $target_k;
    my $hierarchy;
    my %scaling_info = (
        algorithm => $algorithm,
        exact_matrix_bytes => $exact_matrix_bytes,
        max_exact_matrix_bytes => $max_exact_matrix_bytes,
    );

    if ($algorithm eq 'exact') {
        my $D = "\0" x $exact_matrix_bytes;
        my @row_sum_q = (0) x $n;
        my $get_q = sub { return vec($D, $_[0] * $n + $_[1], 32); };

        $self->_progress("Building distance matrix for $n rows...");
        for my $i (0 .. $n - 1) {
            for my $j ($i + 1 .. $n - 1) {
                my $q = $distance_q->($i, $j);
                vec($D, $i * $n + $j, 32) = $q;
                vec($D, $j * $n + $i, 32) = $q;
                $row_sum_q[$i] += $q;
                $row_sum_q[$j] += $q;
            }
        }

        my $init_medoids = sub {
            my ($k) = @_;
            my $first = 0;
            for my $i (1 .. $n - 1) {
                $first = $i if $row_sum_q[$i] < $row_sum_q[$first];
            }
            my @medoids = ($first);
            my %is_medoid = ($first => 1);
            while (@medoids < $k) {
                my ($best_i, $best_nearest) = (-1, -1);
                for my $i (0 .. $n - 1) {
                    next if $is_medoid{$i};
                    my $nearest = $get_q->($i, $medoids[0]);
                    for my $m (@medoids[1 .. $#medoids]) {
                        my $q = $get_q->($i, $m);
                        $nearest = $q if $q < $nearest;
                    }
                    if ($nearest > $best_nearest) {
                        ($best_i, $best_nearest) = ($i, $nearest);
                    }
                }
                push @medoids, $best_i;
                $is_medoid{$best_i} = 1;
            }
            return @medoids;
        };

        my $assign_to_medoids = sub {
            my ($medoids) = @_;
            my @assign;
            for my $i (0 .. $n - 1) {
                my ($best_c, $best_q) = (0, $get_q->($i, $medoids->[0]));
                for my $c (1 .. $#$medoids) {
                    my $q = $get_q->($i, $medoids->[$c]);
                    if ($q < $best_q || ($q == $best_q && $medoids->[$c] < $medoids->[$best_c])) {
                        ($best_c, $best_q) = ($c, $q);
                    }
                }
                $assign[$i] = $best_c;
            }
            return \@assign;
        };

        my $recompute_medoids = sub {
            my ($k, $assign, $old_medoids) = @_;
            my @members;
            push @{$members[$assign->[$_]]}, $_ for 0 .. $n - 1;
            my @new = @$old_medoids;
            for my $c (0 .. $k - 1) {
                next unless defined($members[$c]) && @{$members[$c]};
                my @m = @{$members[$c]};
                my @cost = (0) x @m;
                for my $a (0 .. $#m) {
                    for my $b ($a + 1 .. $#m) {
                        my $q = $get_q->($m[$a], $m[$b]);
                        $cost[$a] += $q;
                        $cost[$b] += $q;
                    }
                }
                my $best = 0;
                for my $a (1 .. $#m) {
                    $best = $a if $cost[$a] < $cost[$best]
                        || ($cost[$a] == $cost[$best] && $m[$a] < $m[$best]);
                }
                $new[$c] = $m[$best];
            }
            return \@new;
        };

        my $fit_kmedoids = sub {
            my ($k) = @_;
            my @medoids = $init_medoids->($k);
            my $assign;
            for my $iter (1 .. $max_iterations) {
                $assign = $assign_to_medoids->(\@medoids);
                my $new = $recompute_medoids->($k, $assign, \@medoids);
                my $changed = 0;
                for my $c (0 .. $k - 1) {
                    if ($new->[$c] != $medoids[$c]) { $changed = 1; last; }
                }
                @medoids = @$new;
                last unless $changed;
            }
            $assign = $assign_to_medoids->(\@medoids);
            return (\@medoids, $assign);
        };

        my $sample_indices = sub {
            my ($wanted) = @_;
            return [0 .. $n - 1] if !$wanted || $wanted >= $n;
            return [0] if $wanted == 1;
            my (@idx, %seen);
            for my $t (0 .. $wanted - 1) {
                my $i = int(($t * ($n - 1)) / ($wanted - 1) + 0.5);
                push @idx, $i unless $seen{$i}++;
            }
            return \@idx;
        };

        my $silhouette_score = sub {
            my ($k, $assign, $sample) = @_;
            return 0 if $k <= 1 || $n <= 2;
            my @cluster_size = (0) x $k;
            $cluster_size[$assign->[$_]]++ for 0 .. $n - 1;
            my $indices = $sample_indices->($sample);
            my $total = 0;
            my $counted = 0;
            for my $i (@$indices) {
                my $ci = $assign->[$i];
                next if $cluster_size[$ci] <= 1;
                my @sum_q = (0) x $k;
                for my $j (0 .. $n - 1) {
                    next if $j == $i;
                    $sum_q[$assign->[$j]] += $get_q->($i, $j);
                }
                my $a = $sum_q[$ci] / ($cluster_size[$ci] - 1);
                my $b;
                for my $c (0 .. $k - 1) {
                    next if $c == $ci || $cluster_size[$c] == 0;
                    my $avg = $sum_q[$c] / $cluster_size[$c];
                    $b = $avg if !defined($b) || $avg < $b;
                }
                next unless defined $b;
                my $den = max($a, $b);
                $total += $den > 0 ? ($b - $a) / $den : 0;
                $counted++;
            }
            return $counted ? $total / $counted : 0;
        };

        my $hierarchical = defined($requested) && !ref($requested) && lc($requested) eq 'hierarchical';
        if ($hierarchical) {
            $selection_method = 'hierarchical_distortion';
            my $k_min = exists($ccfg->{k_min}) ? int($ccfg->{k_min}) : 2;
            my $k_max = exists($ccfg->{k_max}) ? int($ccfg->{k_max}) : 12;
            $k_min = 1 if $k_min < 1;
            $k_max = $n if $k_max > $n;
            die "clustering.k_min must not exceed clustering.k_max\n" if $k_min > $k_max;
            my $sample = exists($ccfg->{silhouette_sample}) ? int($ccfg->{silhouette_sample}) : min(600, $n);
            my @curve;
            for my $k (1 .. $k_max) {
                $self->_progress("Testing representation distortion at k=$k...");
                my ($m, $a) = $fit_kmedoids->($k);
                my $sumq = 0;
                for my $i (0 .. $n - 1) {
                    $sumq += $get_q->($i, $m->[$a->[$i]]);
                }
                my $mean = ($sumq / $n) / $DIST_SCALE;
                push @curve, [$k, $mean];
            }
            ($target_k, my $annotated) = _distortion_knee(\@curve, $k_min, $k_max);
            @distortion_table = @$annotated;
            $self->_progress("Distortion knee selected $target_k leaf medoids; allocating them hierarchically...");
            $hierarchy = _hierarchical_exact(
                self => $self, n => $n, target_k => $target_k,
                max_iterations => $max_iterations, distance_q => $distance_q,
                dist_scale => $DIST_SCALE,
            );
            ($chosen_k, $chosen_medoids, $chosen_assign) = @{$hierarchy}{qw(clusters medoids assign)};
            my $sil_indices = $sample_indices->($sample);
            $chosen_silhouette = _sample_pairwise_silhouette(
                distance_q => $distance_q, labels => $chosen_assign,
                k => $chosen_k, indices => $sil_indices,
            );
            push @score_table, [$chosen_k, $chosen_silhouette];
            $scaling_info{silhouette_mode} = 'sampled_pairwise_hierarchical';
            $scaling_info{silhouette_sample} = scalar(@$sil_indices);
        } elsif (defined($requested) && $requested ne 'auto') {
            my $k = int($requested);
            die "clustering.clusters must be between 1 and $n\n" if $k < 1 || $k > $n;
            $self->_progress("Clustering with k=$k...");
            my ($m, $a) = $fit_kmedoids->($k);
            my $sample = exists($ccfg->{silhouette_sample}) ? int($ccfg->{silhouette_sample}) : 0;
            my $s = $silhouette_score->($k, $a, $sample);
            ($chosen_k, $chosen_medoids, $chosen_assign, $chosen_silhouette) = ($k, $m, $a, $s);
            push @score_table, [$k, $s];
        } else {
            if ($n < 3) {
                my ($m, $a) = $fit_kmedoids->(1);
                ($chosen_k, $chosen_medoids, $chosen_assign, $chosen_silhouette) = (1, $m, $a, 0);
                push @score_table, [1, 0];
            } else {
                my $k_min = exists($ccfg->{k_min}) ? int($ccfg->{k_min}) : 2;
                my $k_max = exists($ccfg->{k_max}) ? int($ccfg->{k_max}) : 12;
                $k_min = 2 if $k_min < 2;
                $k_max = $n - 1 if $k_max >= $n;
                die "clustering.k_min must not exceed clustering.k_max\n" if $k_min > $k_max;
                my $sample = exists($ccfg->{silhouette_sample}) ? int($ccfg->{silhouette_sample}) : min(600, $n);
                my $best_s;
                for my $k ($k_min .. $k_max) {
                    $self->_progress("Testing k=$k...");
                    my ($m, $a) = $fit_kmedoids->($k);
                    my $s = $silhouette_score->($k, $a, $sample);
                    push @score_table, [$k, $s];
                    if (!defined($best_s) || $s > $best_s + 1e-12) {
                        ($best_s, $chosen_k, $chosen_medoids, $chosen_assign) = ($s, $k, $m, $a);
                    }
                }
                $chosen_silhouette = $ccfg->{exact_final_silhouette}
                    ? $silhouette_score->($chosen_k, $chosen_assign, 0)
                    : $best_s;
            }
        }

        if (!$hierarchical) {
            $chosen_medoids = $recompute_medoids->($chosen_k, $chosen_assign, $chosen_medoids);
            $chosen_assign = $assign_to_medoids->($chosen_medoids);
            $scaling_info{silhouette_mode} = 'historical_exact_reference';
        }
    } else {
        # CLARA: exact PAM within several small samples; candidate medoid sets
        # are compared on an independent validation sample.  The final chosen
        # medoids are then assigned across all n rows once, O(n*k), with no
        # dense full-landscape distance matrix.
        my $clara_samples = exists($ccfg->{clara_samples}) ? int($ccfg->{clara_samples}) : 5;
        die "clustering.clara_samples must be >= 1\n" if $clara_samples < 1;
        my $clara_sample_size = exists($ccfg->{clara_sample_size}) ? int($ccfg->{clara_sample_size}) : 2048;
        $clara_sample_size = $n if $clara_sample_size > $n;
        die "clustering.clara_sample_size must be >= 2\n" if $clara_sample_size < 2 && $n >= 2;
        my $validation_size = exists($ccfg->{clara_validation_sample}) ? int($ccfg->{clara_validation_sample}) : 4096;
        $validation_size = $n if $validation_size > $n;
        $validation_size = 2 if $validation_size < 2 && $n >= 2;
        my $seed = exists($ccfg->{random_seed}) ? int($ccfg->{random_seed}) : 1;

        my $lcg_sample = sub {
            my ($wanted, $seed0) = @_;
            return [0 .. $n - 1] if $wanted >= $n;
            my $state = $seed0 & 0x7fffffff;
            $state = 1 if !$state;
            my $rand_int = sub {
                my ($limit) = @_;
                $state = (1103515245 * $state + 12345) % 2147483648;
                return int(($state / 2147483648) * $limit);
            };
            my @res = (0 .. $wanted - 1);
            for my $i ($wanted .. $n - 1) {
                my $j = $rand_int->($i + 1);
                $res[$j] = $i if $j < $wanted;
            }
            @res = sort { $a <=> $b } @res;
            return \@res;
        };

        my $validation = $lcg_sample->($validation_size, $seed + 104729);
        my $sil_n = exists($ccfg->{silhouette_sample}) ? int($ccfg->{silhouette_sample}) : min(600, $validation_size);
        $sil_n = $validation_size if !$sil_n || $sil_n > $validation_size;
        my $silhouette_pick = $lcg_sample->($sil_n, $seed + 130363);
        my @silhouette_indices = @$silhouette_pick;

        my $hierarchical = defined($requested) && !ref($requested) && lc($requested) eq 'hierarchical';
        my ($k_min, $k_max);
        if ($hierarchical) {
            $selection_method = 'hierarchical_distortion';
            my $requested_min = exists($ccfg->{k_min}) ? int($ccfg->{k_min}) : 2;
            $k_min = 1;
            $k_max = exists($ccfg->{k_max}) ? int($ccfg->{k_max}) : 12;
            $k_max = $n if $k_max > $n;
            die "clustering.k_min must not exceed clustering.k_max\n" if $requested_min > $k_max;
        } elsif (defined($requested) && $requested ne 'auto') {
            $k_min = $k_max = int($requested);
            die "clustering.clusters must be between 1 and $n\n" if $k_min < 1 || $k_min > $n;
        } elsif ($n < 3) {
            $k_min = $k_max = 1;
        } else {
            $k_min = exists($ccfg->{k_min}) ? int($ccfg->{k_min}) : 2;
            $k_max = exists($ccfg->{k_max}) ? int($ccfg->{k_max}) : 12;
            $k_min = 2 if $k_min < 2;
            $k_max = $n - 1 if $k_max >= $n;
            die "clustering.k_min must not exceed clustering.k_max\n" if $k_min > $k_max;
        }
        die "clustering.clara_sample_size must be >= maximum k ($k_max)\n"
            if $clara_sample_size < $k_max;

        my %best_for_k;
        for my $trial (1 .. $clara_samples) {
            my $sample = $lcg_sample->($clara_sample_size, $seed + 1009 * $trial);
            my $sn = scalar @$sample;
            my $sample_bytes = 4 * $sn * $sn;
            my $SD = "\0" x $sample_bytes;
            my @row_sum_q = (0) x $sn;
            my $sget_q = sub { return vec($SD, $_[0] * $sn + $_[1], 32); };
            $self->_progress("CLARA sample $trial/$clara_samples: building $sn x $sn distance matrix...");
            for my $a (0 .. $sn - 1) {
                for my $b ($a + 1 .. $sn - 1) {
                    my $q = $distance_q->($sample->[$a], $sample->[$b]);
                    vec($SD, $a * $sn + $b, 32) = $q;
                    vec($SD, $b * $sn + $a, 32) = $q;
                    $row_sum_q[$a] += $q;
                    $row_sum_q[$b] += $q;
                }
            }

            my $fit_sample_k = sub {
                my ($k) = @_;
                my $first = 0;
                for my $i (1 .. $sn - 1) {
                    $first = $i if $row_sum_q[$i] < $row_sum_q[$first];
                }
                my @med = ($first);
                my %is_med = ($first => 1);
                return [$sample->[$first]] if $k == 1;
                while (@med < $k) {
                    my ($best_i, $best_nearest) = (-1, -1);
                    for my $i (0 .. $sn - 1) {
                        next if $is_med{$i};
                        my $nearest = $sget_q->($i, $med[0]);
                        for my $m (@med[1 .. $#med]) {
                            my $q = $sget_q->($i, $m);
                            $nearest = $q if $q < $nearest;
                        }
                        if ($nearest > $best_nearest) {
                            ($best_i, $best_nearest) = ($i, $nearest);
                        }
                    }
                    push @med, $best_i;
                    $is_med{$best_i} = 1;
                }
                my $assign_local = sub {
                    my ($meds) = @_;
                    my @as;
                    for my $i (0 .. $sn - 1) {
                        my ($bc, $bq) = (0, $sget_q->($i, $meds->[0]));
                        for my $c (1 .. $#$meds) {
                            my $q = $sget_q->($i, $meds->[$c]);
                            if ($q < $bq || ($q == $bq && $meds->[$c] < $meds->[$bc])) {
                                ($bc, $bq) = ($c, $q);
                            }
                        }
                        $as[$i] = $bc;
                    }
                    return \@as;
                };
                for my $iter (1 .. $max_iterations) {
                    my $as = $assign_local->(\@med);
                    my @members;
                    push @{$members[$as->[$_]]}, $_ for 0 .. $sn - 1;
                    my @new = @med;
                    for my $c (0 .. $k - 1) {
                        next unless defined($members[$c]) && @{$members[$c]};
                        my @m = @{$members[$c]};
                        my @cost = (0) x @m;
                        for my $a (0 .. $#m) {
                            for my $b ($a + 1 .. $#m) {
                                my $q = $sget_q->($m[$a], $m[$b]);
                                $cost[$a] += $q;
                                $cost[$b] += $q;
                            }
                        }
                        my $best = 0;
                        for my $a (1 .. $#m) {
                            $best = $a if $cost[$a] < $cost[$best]
                                || ($cost[$a] == $cost[$best] && $m[$a] < $m[$best]);
                        }
                        $new[$c] = $m[$best];
                    }
                    my $changed = 0;
                    for my $c (0 .. $k - 1) {
                        if ($new[$c] != $med[$c]) { $changed = 1; last; }
                    }
                    @med = @new;
                    last unless $changed;
                }
                return [map { $sample->[$_] } @med];
            };

            for my $k ($k_min .. $k_max) {
                my $medoids = $fit_sample_k->($k);
                my $cost = 0;
                for my $i (@$validation) {
                    my $best = $distance_q->($i, $medoids->[0]);
                    for my $c (1 .. $#$medoids) {
                        my $q = $distance_q->($i, $medoids->[$c]);
                        $best = $q if $q < $best;
                    }
                    $cost += $best;
                }
                if (!exists($best_for_k{$k}) || $cost < $best_for_k{$k}{validation_cost}) {
                    $best_for_k{$k} = { medoids => $medoids, validation_cost => $cost, trial => $trial };
                }
            }
        }

        my $sample_silhouette = sub {
            my ($k, $medoids) = @_;
            return 0 if $k <= 1 || @silhouette_indices <= 2;
            my @lab;
            for my $ii (0 .. $#silhouette_indices) {
                my $i = $silhouette_indices[$ii];
                my ($bc, $bq) = (0, $distance_q->($i, $medoids->[0]));
                for my $c (1 .. $#$medoids) {
                    my $q = $distance_q->($i, $medoids->[$c]);
                    if ($q < $bq || ($q == $bq && $medoids->[$c] < $medoids->[$bc])) {
                        ($bc, $bq) = ($c, $q);
                    }
                }
                $lab[$ii] = $bc;
            }
            my @size = (0) x $k;
            $size[$_]++ for @lab;
            my ($total, $counted) = (0, 0);
            for my $a (0 .. $#silhouette_indices) {
                my $ca = $lab[$a];
                next if $size[$ca] <= 1;
                my @sum = (0) x $k;
                for my $b (0 .. $#silhouette_indices) {
                    next if $a == $b;
                    $sum[$lab[$b]] += $distance_q->($silhouette_indices[$a], $silhouette_indices[$b]);
                }
                my $ain = $sum[$ca] / ($size[$ca] - 1);
                my $bout;
                for my $c (0 .. $k - 1) {
                    next if $c == $ca || !$size[$c];
                    my $avg = $sum[$c] / $size[$c];
                    $bout = $avg if !defined($bout) || $avg < $bout;
                }
                next unless defined $bout;
                my $den = max($ain, $bout);
                $total += $den > 0 ? ($bout - $ain) / $den : 0;
                $counted++;
            }
            return $counted ? $total / $counted : 0;
        };

        if ($hierarchical) {
            my $requested_min = exists($ccfg->{k_min}) ? int($ccfg->{k_min}) : 2;
            my @curve;
            for my $k (1 .. $k_max) {
                my $mean = ($best_for_k{$k}{validation_cost} / scalar(@$validation)) / $DIST_SCALE;
                push @curve, [$k, $mean];
            }
            ($target_k, my $annotated) = _distortion_knee(\@curve, $requested_min, $k_max);
            @distortion_table = @$annotated;
            $self->_progress("Distortion knee selected $target_k leaf medoids; allocating them hierarchically...");
            my $hier_samples = exists($ccfg->{hierarchy_samples}) ? int($ccfg->{hierarchy_samples}) : 3;
            my $hier_sample_size = exists($ccfg->{hierarchy_sample_size}) ? int($ccfg->{hierarchy_sample_size}) : min(512, $clara_sample_size);
            my $hier_validation = exists($ccfg->{hierarchy_validation_sample}) ? int($ccfg->{hierarchy_validation_sample}) : min(1024, $validation_size);
            my $hier_working = exists($ccfg->{hierarchy_working_sample}) ? int($ccfg->{hierarchy_working_sample}) : min(4096, $n);
            $hierarchy = _hierarchical_clara(
                self => $self, n => $n, target_k => $target_k,
                max_iterations => $max_iterations, distance_q => $distance_q,
                dist_scale => $DIST_SCALE, seed => $seed + 900001,
                samples => $hier_samples, sample_size => $hier_sample_size,
                validation_size => $hier_validation, working_size => $hier_working,
            );
            ($chosen_k, $chosen_medoids, $chosen_assign) = @{$hierarchy}{qw(clusters medoids assign)};
            $chosen_silhouette = _sample_pairwise_silhouette(
                distance_q => $distance_q, labels => $chosen_assign,
                k => $chosen_k, indices => \@silhouette_indices,
            );
            push @score_table, [$chosen_k, $chosen_silhouette];
        } else {
            my $best_s;
            for my $k ($k_min .. $k_max) {
                my $m = $best_for_k{$k}{medoids};
                my $s = $sample_silhouette->($k, $m);
                push @score_table, [$k, $s];
                if (!defined($best_s) || $s > $best_s + 1e-12) {
                    ($best_s, $chosen_k, $chosen_medoids) = ($s, $k, $m);
                }
            }
            $chosen_silhouette = $best_s // 0;

            # One full assignment after k selection.  This is the only O(n*k)
            # pass over the complete landscape in the legacy CLARA path.
            my @assign;
            for my $i (0 .. $n - 1) {
                my ($bc, $bq) = (0, $distance_q->($i, $chosen_medoids->[0]));
                for my $c (1 .. $#$chosen_medoids) {
                    my $q = $distance_q->($i, $chosen_medoids->[$c]);
                    if ($q < $bq || ($q == $bq && $chosen_medoids->[$c] < $chosen_medoids->[$bc])) {
                        ($bc, $bq) = ($c, $q);
                    }
                }
                $assign[$i] = $bc;
            }
            $chosen_assign = \@assign;
        }

        $scaling_info{clara_samples} = $clara_samples;
        $scaling_info{clara_sample_size} = $clara_sample_size;
        $scaling_info{clara_validation_sample} = $validation_size;
        $scaling_info{random_seed} = $seed;
        $scaling_info{silhouette_mode} = 'sampled_pairwise';
        $scaling_info{silhouette_sample} = scalar(@silhouette_indices);
        if ($hierarchical) {
            $scaling_info{hierarchy_samples} = exists($ccfg->{hierarchy_samples}) ? int($ccfg->{hierarchy_samples}) : 3;
            $scaling_info{hierarchy_sample_size} = exists($ccfg->{hierarchy_sample_size}) ? int($ccfg->{hierarchy_sample_size}) : min(512, $clara_sample_size);
            $scaling_info{hierarchy_validation_sample} = exists($ccfg->{hierarchy_validation_sample}) ? int($ccfg->{hierarchy_validation_sample}) : min(1024, $validation_size);
            $scaling_info{hierarchy_working_sample} = exists($ccfg->{hierarchy_working_sample}) ? int($ccfg->{hierarchy_working_sample}) : min(4096, $n);
        }
    }

    if ($hierarchy && ref($hierarchy->{nodes}) eq 'ARRAY') {
        for my $node (@{$hierarchy->{nodes}}) {
            my $i = $node->{medoid_row_index};
            next unless defined($i) && $i >= 0 && $i < $n;
            $node->{medoid_csv_row} = $rows[$i]{csv_row};
            $node->{medoid_instance} = $rows[$i]{combo_text};
            $node->{medoid_performance} = 0 + $rows[$i]{performance};
            if (ref($node->{split_medoid_row_indices}) eq 'ARRAY') {
                my @split;
                for my $si (@{$node->{split_medoid_row_indices}}) {
                    die "Hierarchy split medoid row index $si is outside 0..$#rows\n"
                        if $si < 0 || $si > $#rows;
                    push @split, {
                        row_index => 0 + $si,
                        csv_row => 0 + $rows[$si]{csv_row},
                        instance => $rows[$si]{combo_text},
                        performance => 0 + $rows[$si]{performance},
                    };
                }
                $node->{split_medoids} = \@split;
            }
        }
    }

    my @old_clusters = sort { $chosen_medoids->[$a] <=> $chosen_medoids->[$b] } 0 .. $chosen_k - 1;
    my %new_number;
    $new_number{$old_clusters[$_]} = $_ + 1 for 0 .. $#old_clusters;
    my @labels = map { $new_number{$chosen_assign->[$_]} } 0 .. $n - 1;
    my %medoid_for_cluster = map { $new_number{$_} => $chosen_medoids->[$_] } 0 .. $chosen_k - 1;

    if (!defined $output_prefix || !length $output_prefix) {
        ($output_prefix = $results_file) =~ s/\.[^.]+$//;
        $output_prefix .= @context ? '.context_hybrid' : '.problem_hybrid';
    } else {
        $output_prefix = File::Spec->rel2abs($output_prefix);
    }

    my $out_dir = dirname($output_prefix);
    make_path($out_dir) if defined($out_dir) && length($out_dir) && $out_dir ne '.' && !-d $out_dir;

    my $clustered_path = "$output_prefix.clustered.csv";
    my $medoids_path = "$output_prefix.medoids.csv";
    my $scores_path = "$output_prefix.silhouette.csv";
    my $distortion_path = "$output_prefix.distortion.csv";
    my $hierarchy_path = "$output_prefix.hierarchy.json";
    my $info_path = "$output_prefix.info.txt";

    my $outcsv = Text::CSV->new({ binary => 1, eol => "\n" });
    open my $cfh, '>', $clustered_path or die "Cannot write $clustered_path: $!\n";
    if ($header) {
        $outcsv->print($cfh, [@$header, 'cluster', 'is_medoid']);
    } else {
        my $nf = scalar @{$rows[0]{fields}};
        $outcsv->print($cfh, [map({"col$_"} 0 .. $nf - 1), 'cluster', 'is_medoid']);
    }
    my %is_medoid_row = map { $_ => 1 } values %medoid_for_cluster;
    for my $i (0 .. $n - 1) {
        $outcsv->print($cfh, [@{$rows[$i]{fields}}, $labels[$i], ($is_medoid_row{$i} ? 1 : 0)]);
    }
    close $cfh;

    open my $mfh, '>', $medoids_path or die "Cannot write $medoids_path: $!\n";
    my %is_fixed = map { $_ => 1 } @fixed;
    my @role_header = map { 'var_' . $_ . '_' . ($is_fixed{$_} ? 'fixed' : ($is_context{$_} ? 'context' : 'problem')) } @variable_ids;
    $outcsv->print($mfh, ['cluster', 'csv_row', 'instance', 'performance', @role_header]);
    my @medoid_records;
    for my $c (sort { $a <=> $b } keys %medoid_for_cluster) {
        my $i = $medoid_for_cluster{$c};
        my $r = $rows[$i];
        $outcsv->print($mfh, [$c, $r->{csv_row}, $r->{combo_text}, $r->{performance}, map {$r->{combo}{$_}} @variable_ids]);
        my $rec = {
            cluster     => $c,
            csv_row     => $r->{csv_row},
            instance    => $r->{combo_text},
            performance => $r->{performance},
            variables   => { %{$r->{combo}} },
        };
        if ($hierarchy && ref($hierarchy->{leaf_meta}) eq 'ARRAY' && $hierarchy->{leaf_meta}[$c - 1]) {
            my $hm = $hierarchy->{leaf_meta}[$c - 1];
            $rec->{hierarchy_node} = $hm->{node_id};
            $rec->{hierarchy_depth} = $hm->{depth};
            $rec->{hierarchy_path} = $hm->{path};
            $rec->{representation_mean_distance} = $hm->{mean_distance};
        }
        push @medoid_records, $rec;
    }
    close $mfh;

    open my $sfh, '>', $scores_path or die "Cannot write $scores_path: $!\n";
    $outcsv->print($sfh, ['k', $selection_method eq 'hierarchical_distortion' ? 'silhouette_diagnostic' : 'silhouette_used_for_selection']);
    for my $x (@score_table) {
        $outcsv->print($sfh, [$x->[0], sprintf('%.10f', $x->[1])]);
    }
    close $sfh;

    if ($selection_method eq 'hierarchical_distortion') {
        open my $dfh, '>', $distortion_path or die "Cannot write $distortion_path: $!\n";
        $outcsv->print($dfh, [qw(k validation_mean_distance monotone_mean_distance relative_to_k1 marginal_reduction knee_score selected_target)]);
        for my $x (@distortion_table) {
            $outcsv->print($dfh, [
                $x->{k}, sprintf('%.10f', $x->{raw}), sprintf('%.10f', $x->{monotone}),
                sprintf('%.10f', $x->{relative}), sprintf('%.10f', $x->{marginal}),
                sprintf('%.10f', $x->{knee_score}), ($x->{k} == $target_k ? 1 : 0),
            ]);
        }
        close $dfh;
        my $hj = {
            schema => 'Sim::OPT::ClusterMedoid/hierarchical-distortion-1',
            selection_method => $selection_method,
            target_leaf_clusters => 0 + ($target_k || $chosen_k),
            realized_leaf_clusters => 0 + $chosen_k,
            final_mean_distance => 0 + ($hierarchy->{final_mean_distance} // 0),
            nodes => $hierarchy->{nodes} || [],
        };
        open my $hfh, '>', $hierarchy_path or die "Cannot write $hierarchy_path: $!\n";
        print {$hfh} JSON::PP->new->canonical(1)->pretty(1)->encode($hj);
        close $hfh;
    }

    my @cluster_size = (0) x ($chosen_k + 1);
    $cluster_size[$_]++ for @labels;
    open my $ifh, '>', $info_path or die "Cannot write $info_path: $!\n";
    say $ifh "search_config=$config_file";
    say $ifh "instance_prefix=$instance_prefix";
    say $ifh "combination_column=$combination_col_spec";
    say $ifh "performance_column=$performance_col_spec";
    say $ifh "rows=$n";
    say $ifh "variables=" . join(',', @variable_ids);
    say $ifh "fixed_variables=" . join(',', @fixed);
    say $ifh "fixed_levels=" . join(',', map { $_ . ':' . $fixed_level{$_} } @fixed);
    say $ifh "context_variables=" . join(',', @context);
    say $ifh "problem_variables=" . join(',', @problem);
    say $ifh "lambda=$lambda";
    say $ifh "performance_best=$pbest";
    say $ifh "performance_worst=$pworst";
    say $ifh "performance_divisions=$divisions";
    say $ifh "variable_distance=log(1+level_difference)/log(number_of_levels)";
    say $ifh "variable_similarity=1-variable_distance";
    say $ifh "group_similarity=(1-lambda)*weighted_arithmetic_mean+lambda*weighted_geometric_mean";
    say $ifh "performance_similarity=1-log(1+performance_difference/step)/log(1+divisions), clipped";
    say $ifh "overall_similarity=hybrid_mean(context_if_any,problem,performance)";
    say $ifh "distance=1-overall_similarity";
    say $ifh "clustering=k_medoids";
    say $ifh "clustering_algorithm=$scaling_info{algorithm}";
    say $ifh "selection_method=$selection_method";
    say $ifh "target_leaf_clusters=$target_k" if defined $target_k;
    say $ifh "representation_mean_distance=$hierarchy->{final_mean_distance}" if $hierarchy;
    say $ifh "exact_matrix_bytes=$scaling_info{exact_matrix_bytes}";
    say $ifh "max_exact_matrix_bytes=$scaling_info{max_exact_matrix_bytes}";
    for my $name (qw(clara_samples clara_sample_size clara_validation_sample random_seed silhouette_mode silhouette_sample hierarchy_samples hierarchy_sample_size hierarchy_validation_sample hierarchy_working_sample)) {
        say $ifh "$name=$scaling_info{$name}" if exists $scaling_info{$name};
    }
    say $ifh "clusters=$chosen_k";
    say $ifh "silhouette=" . sprintf('%.10f', $chosen_silhouette);
    for my $c (1 .. $chosen_k) {
        say $ifh "cluster_${c}_size=$cluster_size[$c]";
        say $ifh "cluster_${c}_medoid_csv_row=$rows[$medoid_for_cluster{$c}]{csv_row}";
    }
    close $ifh;

    return {
        rows               => $n,
        clusters           => $chosen_k,
        silhouette         => 0 + $chosen_silhouette,
        clustering_algorithm => $scaling_info{algorithm},
        selection_method    => $selection_method,
        target_clusters     => (defined($target_k) ? 0 + $target_k : 0 + $chosen_k),
        distortion_curve    => [map { { %$_ } } @distortion_table],
        hierarchy           => ($hierarchy ? { nodes => $hierarchy->{nodes}, final_mean_distance => 0 + ($hierarchy->{final_mean_distance} // 0) } : undef),
        scaling             => { %scaling_info },
        lambda             => $lambda,
        metric             => {
            schema => 'Sim::OPT::ClusterMedoid/hybrid-distance-1',
            variable_levels => { %levels },
            fixed_levels => { %fixed_level },
            context_variables => [@context],
            problem_variables => [@problem],
            lambda => 0 + $lambda,
            variable_weights => { %variable_weight },
            component_weights => { %component_weight },
            performance => {
                best => 0 + $pbest,
                worst => 0 + $pworst,
                divisions => 0 + $divisions,
            },
            formulas => {
                variable_distance => 'log(1+level_difference)/log(number_of_levels)',
                group_similarity => '(1-lambda)*weighted_arithmetic_mean+lambda*weighted_geometric_mean',
                performance_similarity => '1-log(1+performance_difference/step)/log(1+divisions), clipped',
                distance => '1-overall_similarity',
            },
        },
        instance_prefix    => $instance_prefix,
        performance_column => $performance_col_spec,
        variables          => [@variable_ids],
        fixed_variables    => [@fixed],
        fixed_levels       => { %fixed_level },
        context_variables  => [@context],
        problem_variables  => [@problem],
        medoids            => \@medoid_records,
        silhouette_scores  => [map { [$_->[0], 0 + $_->[1]] } @score_table],
        files              => {
            clustered => $clustered_path,
            medoids    => $medoids_path,
            silhouette => $scores_path,
            ($selection_method eq 'hierarchical_distortion' ? (distortion => $distortion_path, hierarchy => $hierarchy_path) : ()),
            info       => $info_path,
        },
    };
}

sub _distortion_knee {
    my ($curve, $k_min, $k_max) = @_;
    die "distortion curve must be a non-empty ARRAY\n" unless ref($curve) eq 'ARRAY' && @$curve;
    $k_min = 1 if !defined($k_min) || $k_min < 1;
    $k_max = $curve->[-1][0] unless defined $k_max;

    my @raw = map { [0 + $_->[0], 0 + $_->[1]] } @$curve;
    my @mono;
    my $best;
    for my $x (@raw) {
        $best = $x->[1] if !defined($best) || $x->[1] < $best;
        push @mono, [$x->[0], $best];
    }
    my $d1 = $mono[0][1];
    my $dlast = $mono[-1][1];
    my $range = $d1 - $dlast;
    my $denx = max(1, $mono[-1][0] - $mono[0][0]);
    my $target = $k_min;
    my $best_score = -1;
    my @out;
    for my $i (0 .. $#mono) {
        my ($k, $d) = @{$mono[$i]};
        my $xnorm = ($k - $mono[0][0]) / $denx;
        my $ynorm = $range > 1e-15 ? ($d - $dlast) / $range : 0;
        my $score = $range > 1e-15 ? (1 - $xnorm) - $ynorm : 0;
        $score = 0 if $score < 0;
        my $relative = $d1 > 0 ? $d / $d1 : 0;
        my $marginal = $i == 0 ? 0 : max(0, $mono[$i-1][1] - $d);
        push @out, {
            k => $k, raw => $raw[$i][1], monotone => $d,
            relative => $relative, marginal => $marginal, knee_score => $score,
        };
        next if $k < $k_min || $k > $k_max;
        next if $k == $mono[-1][0] && $k > $k_min;
        if ($score > $best_score + 1e-15) {
            ($best_score, $target) = ($score, $k);
        }
    }
    $target = $k_min if $range <= 1e-15;
    $target = $k_max if $target > $k_max;
    return ($target, \@out);
}

sub _sample_pairwise_silhouette {
    my (%a) = @_;
    my $distance_q = $a{distance_q};
    my $labels = $a{labels};
    my $k = $a{k};
    my $indices = $a{indices};
    return 0 if $k <= 1 || ref($indices) ne 'ARRAY' || @$indices <= 2;
    my @size = (0) x $k;
    $size[$labels->[$_]]++ for @$indices;
    my ($total, $counted) = (0, 0);
    for my $aa (0 .. $#$indices) {
        my $i = $indices->[$aa];
        my $ci = $labels->[$i];
        next if $size[$ci] <= 1;
        my @sum = (0) x $k;
        for my $bb (0 .. $#$indices) {
            next if $aa == $bb;
            my $j = $indices->[$bb];
            $sum[$labels->[$j]] += $distance_q->($i, $j);
        }
        my $ain = $sum[$ci] / ($size[$ci] - 1);
        my $bout;
        for my $c (0 .. $k - 1) {
            next if $c == $ci || !$size[$c];
            my $avg = $sum[$c] / $size[$c];
            $bout = $avg if !defined($bout) || $avg < $bout;
        }
        next unless defined $bout;
        my $den = max($ain, $bout);
        $total += $den > 0 ? ($bout - $ain) / $den : 0;
        $counted++;
    }
    return $counted ? $total / $counted : 0;
}

sub _hierarchical_exact {
    my (%a) = @_;
    my $self = $a{self};
    my $n = $a{n};
    my $target = min($a{target_k}, $n);
    my $distance_q = $a{distance_q};
    my $scale = $a{dist_scale};
    my $max_iterations = $a{max_iterations};

    my $fit_node = sub {
        my ($members) = @_;
        my $m = scalar @$members;
        my $med1 = $members->[0];
        my $best_sum;
        for my $cand (@$members) {
            my $sum = 0;
            $sum += $distance_q->($cand, $_) for @$members;
            if (!defined($best_sum) || $sum < $best_sum || ($sum == $best_sum && $cand < $med1)) {
                ($best_sum, $med1) = ($sum, $cand);
            }
        }
        my $res = { medoid => $med1, mean1_q => $m ? $best_sum / $m : 0, splittable => 0 };
        return $res if $m < 2;

        my $med2 = $members->[0] == $med1 ? $members->[1] : $members->[0];
        my $far = -1;
        for my $cand (@$members) {
            next if $cand == $med1;
            my $q = $distance_q->($cand, $med1);
            if ($q > $far || ($q == $far && $cand < $med2)) { ($far, $med2) = ($q, $cand); }
        }
        my @med = ($med1, $med2);
        my @assign;
        for my $iter (1 .. $max_iterations) {
            my @groups = ([], []);
            for my $idx (@$members) {
                my $q0 = $distance_q->($idx, $med[0]);
                my $q1 = $distance_q->($idx, $med[1]);
                my $c = ($q1 < $q0 || ($q1 == $q0 && $med[1] < $med[0])) ? 1 : 0;
                push @{$groups[$c]}, $idx;
            }
            last unless @{$groups[0]} && @{$groups[1]};
            my @new = @med;
            for my $c (0,1) {
                my ($best, $bsum) = ($groups[$c][0], undef);
                for my $cand (@{$groups[$c]}) {
                    my $sum = 0;
                    $sum += $distance_q->($cand, $_) for @{$groups[$c]};
                    if (!defined($bsum) || $sum < $bsum || ($sum == $bsum && $cand < $best)) {
                        ($best, $bsum) = ($cand, $sum);
                    }
                }
                $new[$c] = $best;
            }
            my $changed = ($new[0] != $med[0] || $new[1] != $med[1]);
            @med = @new;
            last unless $changed;
        }
        my @groups = ([], []);
        my $sum2 = 0;
        for my $idx (@$members) {
            my $q0 = $distance_q->($idx, $med[0]);
            my $q1 = $distance_q->($idx, $med[1]);
            my $c = ($q1 < $q0 || ($q1 == $q0 && $med[1] < $med[0])) ? 1 : 0;
            push @{$groups[$c]}, $idx;
            $sum2 += $c ? $q1 : $q0;
        }
        if (@{$groups[0]} && @{$groups[1]}) {
            my $mean2 = $sum2 / $m;
            my $gain = $res->{mean1_q} - $mean2;
            $res->{splittable} = $gain > 0 ? 1 : 0;
            $res->{split_medoids} = [@med];
            $res->{split_groups} = \@groups;
            $res->{mean2_q} = $mean2;
            $res->{gain_q} = $gain;
            $res->{gain_total_q} = $gain * $m;
            $res->{relative_gain} = $res->{mean1_q} > 0 ? $gain / $res->{mean1_q} : 0;
        }
        return $res;
    };

    return _grow_hierarchy(
        n => $n, target_k => $target, fit_node => $fit_node,
        distance_q => $distance_q, dist_scale => $scale,
    );
}

sub _hierarchical_clara {
    my (%a) = @_;
    my $self = $a{self};
    my $n = $a{n};
    my $target = min($a{target_k}, $n);
    my $distance_q = $a{distance_q};
    my $scale = $a{dist_scale};
    my $max_iterations = $a{max_iterations};
    my $base_seed = $a{seed};
    my $trials = max(1, int($a{samples} || 3));
    my $sample_size_cfg = max(2, int($a{sample_size} || 1024));
    my $validation_cfg = max(2, int($a{validation_size} || 1024));
    my $working_cfg = max(2, int($a{working_size} || 4096));
    my $node_counter = 0;

    my $sample_members = sub {
        my ($members, $wanted, $seed) = @_;
        my $m = scalar @$members;
        return [@$members] if $wanted >= $m;
        my $state = $seed & 0x7fffffff;
        $state ||= 1;
        my $rand_int = sub {
            my ($limit) = @_;
            $state = (1103515245 * $state + 12345) & 0x7fffffff;
            return int(($state / 2147483648) * $limit);
        };
        my @pos = (0 .. $wanted - 1);
        for my $i ($wanted .. $m - 1) {
            my $j = $rand_int->($i + 1);
            $pos[$j] = $i if $j < $wanted;
        }
        @pos = sort { $a <=> $b } @pos;
        return [map { $members->[$_] } @pos];
    };

    my $fit_node = sub {
        my ($members) = @_;
        my $m = scalar @$members;
        my $nid = ++$node_counter;
        return { medoid => $members->[0], mean1_q => 0, splittable => 0 } if $m == 1;
        my $validation = $sample_members->($members, min($validation_cfg, $m), $base_seed + 7919*$nid);
        my (%best, %best_cost);
        for my $trial (1 .. $trials) {
            my $sample = $sample_members->($members, min($sample_size_cfg, $m), $base_seed + 104729*$nid + 1009*$trial);
            my $sn = scalar @$sample;
            my $SD = "\0" x (4 * $sn * $sn);
            my @row_sum = (0) x $sn;
            my $get = sub { vec($SD, $_[0] * $sn + $_[1], 32) };
            for my $i (0 .. $sn - 1) {
                for my $j ($i + 1 .. $sn - 1) {
                    my $q = $distance_q->($sample->[$i], $sample->[$j]);
                    vec($SD, $i*$sn+$j, 32) = $q;
                    vec($SD, $j*$sn+$i, 32) = $q;
                    $row_sum[$i] += $q; $row_sum[$j] += $q;
                }
            }
            my $fit_k = sub {
                my ($k) = @_;
                my $first = 0;
                for my $i (1 .. $sn-1) { $first = $i if $row_sum[$i] < $row_sum[$first]; }
                my @med = ($first); my %used = ($first=>1);
                return [$sample->[$first]] if $k == 1;
                while (@med < $k) {
                    my ($bi,$bd)=(-1,-1);
                    for my $i (0 .. $sn-1) {
                        next if $used{$i};
                        my $d=$get->($i,$med[0]);
                        for my $mm (@med[1..$#med]) { my $q=$get->($i,$mm); $d=$q if $q<$d; }
                        if ($d>$bd || ($d==$bd && ($bi<0 || $i<$bi))) { ($bi,$bd)=($i,$d); }
                    }
                    push @med,$bi; $used{$bi}=1;
                }
                for my $iter (1..$max_iterations) {
                    my @groups = map { [] } 0..$k-1;
                    for my $i (0..$sn-1) {
                        my ($bc,$bq)=(0,$get->($i,$med[0]));
                        for my $c (1..$#med) { my $q=$get->($i,$med[$c]); if($q<$bq || ($q==$bq && $med[$c]<$med[$bc])){($bc,$bq)=($c,$q)} }
                        push @{$groups[$bc]},$i;
                    }
                    my @new=@med;
                    for my $c (0..$k-1) {
                        next unless @{$groups[$c]};
                        my ($best_i,$best_sum)=($groups[$c][0],undef);
                        for my $cand (@{$groups[$c]}) {
                            my $sum=0; $sum += $get->($cand,$_) for @{$groups[$c]};
                            if(!defined($best_sum)||$sum<$best_sum||($sum==$best_sum&&$cand<$best_i)){($best_i,$best_sum)=($cand,$sum)}
                        }
                        $new[$c]=$best_i;
                    }
                    my $changed=0; for my $c(0..$k-1){ if($new[$c]!=$med[$c]){$changed=1;last} }
                    @med=@new; last unless $changed;
                }
                return [map {$sample->[$_]} @med];
            };
            for my $k (1,2) {
                next if $k > $sn;
                my $med = $fit_k->($k);
                my $cost=0;
                for my $idx (@$validation) {
                    my $d=$distance_q->($idx,$med->[0]);
                    for my $c (1..$#$med){ my $q=$distance_q->($idx,$med->[$c]); $d=$q if $q<$d; }
                    $cost += $d;
                }
                if(!defined($best_cost{$k}) || $cost<$best_cost{$k}){ $best_cost{$k}=$cost; $best{$k}=$med; }
            }
        }
        my $mean1 = $best_cost{1} / scalar(@$validation);
        my $res = { medoid => $best{1}[0], mean1_q => $mean1, splittable => 0 };
        if ($best{2}) {
            my $mean2 = $best_cost{2} / scalar(@$validation);
            my $gain = $mean1 - $mean2;
            if ($gain > 0 && $best{2}[0] != $best{2}[1]) {
                $res->{splittable}=1;
                $res->{split_medoids}=[@{$best{2}}];
                $res->{mean2_q}=$mean2;
                $res->{gain_q}=$gain;
                $res->{gain_total_q}=$gain*$m;
                $res->{relative_gain}=$mean1>0 ? $gain/$mean1 : 0;
            }
        }
        return $res;
    };

    my @all = (0 .. $n - 1);
    my $root_members = $sample_members->(\@all, min($working_cfg, $n), $base_seed + 424243);
    return _grow_hierarchy(
        n => $n, target_k => $target, fit_node => $fit_node,
        distance_q => $distance_q, dist_scale => $scale,
        root_members => $root_members,
    );
}

sub _grow_hierarchy {
    my (%a) = @_;
    my $n = $a{n};
    my $target = $a{target_k};
    my $fit_node = $a{fit_node};
    my $distance_q = $a{distance_q};
    my $scale = $a{dist_scale};
    my $root_members = ref($a{root_members}) eq 'ARRAY' ? $a{root_members} : [0 .. $n - 1];
    my @nodes;
    my $next_id = 1;
    my $root = { node_id=>1, parent=>undef, depth=>0, path=>'1', members=>[@$root_members], leaf=>1 };
    $root->{fit} = $fit_node->($root->{members});
    push @nodes,$root;

    while (scalar(grep {$_->{leaf}} @nodes) < $target) {
        my @cand = grep { $_->{leaf} && $_->{fit}{splittable} } @nodes;
        last unless @cand;
        @cand = sort {
            $b->{fit}{gain_total_q} <=> $a->{fit}{gain_total_q}
            || $a->{node_id} <=> $b->{node_id}
        } @cand;
        my $node = $cand[0];
        my @groups = ([],[]);
        my $med = $node->{fit}{split_medoids};
        for my $idx (@{$node->{members}}) {
            my $q0=$distance_q->($idx,$med->[0]);
            my $q1=$distance_q->($idx,$med->[1]);
            my $c=($q1<$q0 || ($q1==$q0 && $med->[1]<$med->[0])) ? 1:0;
            push @{$groups[$c]},$idx;
        }
        if (!@{$groups[0]} || !@{$groups[1]}) { $node->{fit}{splittable}=0; next; }
        $node->{leaf}=0;
        $node->{split_gain_mean}=($node->{fit}{gain_q}||0)/$scale;
        $node->{split_gain_relative}=0+($node->{fit}{relative_gain}||0);
        my @child_ids;
        for my $c (0,1) {
            my $id=++$next_id;
            my $child={ node_id=>$id,parent=>$node->{node_id},depth=>$node->{depth}+1,path=>$node->{path}.'.'.($c+1),members=>$groups[$c],leaf=>1 };
            $child->{fit}=$fit_node->($child->{members});
            push @nodes,$child; push @child_ids,$id;
        }
        $node->{children}=\@child_ids;
    }

    my @leaves=grep {$_->{leaf}} @nodes;
    @leaves=sort { $a->{fit}{medoid}<=>$b->{fit}{medoid} } @leaves;
    my @medoids=map {$_->{fit}{medoid}} @leaves;
    my %leaf_cluster = map { $leaves[$_]{node_id} => $_ } 0..$#leaves;
    my %by_id = map { $_->{node_id} => $_ } @nodes;
    my @assign=(0)x$n;
    my @actual_size=(0)x($next_id+1);
    my @leaf_sum_q=(0)x scalar(@leaves);
    my $sumq=0;

    # One full-landscape pass only.  The hierarchy itself was learned on the
    # representative working sample; every full row is then routed through the
    # learned binary tree, preserving hierarchical membership without repeated
    # O(n) assignments at each split.
    for my $idx (0..$n-1) {
        my $node=$root;
        $actual_size[$node->{node_id}]++;
        while (!$node->{leaf}) {
            my $med=$node->{fit}{split_medoids};
            my $q0=$distance_q->($idx,$med->[0]);
            my $q1=$distance_q->($idx,$med->[1]);
            my $c=($q1<$q0 || ($q1==$q0 && $med->[1]<$med->[0])) ? 1:0;
            $node=$by_id{$node->{children}[$c]};
            $actual_size[$node->{node_id}]++;
        }
        my $c=$leaf_cluster{$node->{node_id}};
        $assign[$idx]=$c;
        my $q=$distance_q->($idx,$node->{fit}{medoid});
        $sumq += $q;
        $leaf_sum_q[$c] += $q;
    }

    my @leaf_meta;
    for my $c (0..$#leaves) {
        my $leaf=$leaves[$c];
        $leaf->{cluster}=$c+1;
        my $count=$actual_size[$leaf->{node_id}] || 0;
        push @leaf_meta, {
            node_id=>$leaf->{node_id},depth=>$leaf->{depth},path=>$leaf->{path},
            mean_distance=>$count ? $leaf_sum_q[$c]/$count/$scale : 0,
        };
    }
    my @public;
    for my $node (sort {$a->{node_id}<=>$b->{node_id}} @nodes) {
        push @public, {
            node_id=>$node->{node_id}, parent=>$node->{parent}, depth=>$node->{depth}, path=>$node->{path},
            size=>0+($actual_size[$node->{node_id}]||0), sample_size=>scalar(@{$node->{members}}),
            leaf=>$node->{leaf}?JSON::PP::true:JSON::PP::false,
            medoid_row_index=>0+$node->{fit}{medoid}, mean_sample_distance=>0+(($node->{fit}{mean1_q}||0)/$scale),
            (defined($node->{cluster}) ? (cluster=>0+$node->{cluster}) : ()),
            ($node->{children} ? (children=>[@{$node->{children}}]) : ()),
            (ref($node->{fit}{split_medoids}) eq 'ARRAY' ? (split_medoid_row_indices=>[map {0+$_} @{$node->{fit}{split_medoids}}]) : ()),
            (defined($node->{split_gain_mean}) ? (split_gain_mean=>0+$node->{split_gain_mean},split_gain_relative=>0+$node->{split_gain_relative}) : ()),
        };
    }
    return { clusters=>scalar(@leaves),medoids=>\@medoids,assign=>\@assign,nodes=>\@public,leaf_meta=>\@leaf_meta,final_mean_distance=>($n?$sumq/$n/$scale:0) };
}

sub _load_search_config {
    my ($self, $config_file) = @_;

    {
        no strict 'refs';
        undef ${'Sim::OPT::ClusterMedoid::_SearchConfig::mypath'};
        undef ${'Sim::OPT::ClusterMedoid::_SearchConfig::file'};
        @{'Sim::OPT::ClusterMedoid::_SearchConfig::varinumbers'} = ();
        %{'Sim::OPT::ClusterMedoid::_SearchConfig::landscapecluster'} = ();
    }

    my $rv;
    {
        package Sim::OPT::ClusterMedoid::_SearchConfig;
        no strict;
        no warnings;
        $rv = do $config_file;
    }
    die "Could not read config $config_file: $@ $!\n" if !defined($rv) && ($@ || $!);

    my ($mypath, $file, @varinumbers, %landscapecluster);
    {
        no strict 'refs';
        $mypath = ${'Sim::OPT::ClusterMedoid::_SearchConfig::mypath'};
        $file = ${'Sim::OPT::ClusterMedoid::_SearchConfig::file'};
        @varinumbers = @{'Sim::OPT::ClusterMedoid::_SearchConfig::varinumbers'};
        %landscapecluster = %{'Sim::OPT::ClusterMedoid::_SearchConfig::landscapecluster'};
    }

    return {
        mypath           => $mypath,
        file             => $file,
        varinumbers      => \@varinumbers,
        landscapecluster => \%landscapecluster,
    };
}

sub _parse_combo {
    my ($self, $text, $row_no) = @_;
    die "Undefined instance name at CSV row $row_no\n" unless defined $text;

    my $instance_prefix = $self->{instance_prefix};
    my $suffix;
    my $pos = index($text, $instance_prefix);
    if ($pos >= 0) {
        $suffix = substr($text, $pos + length($instance_prefix));
        $suffix =~ s/^[^0-9]+//;
    } elsif ($text =~ /^\s*((?:\d+-[+-]?\d+)(?:_\d+-[+-]?\d+)+)\s*$/) {
        # Sim::OPT totres files commonly store the clear instance id without
        # the absolute model prefix.  Accept that native representation too.
        $suffix = $1;
    } else {
        die "CSV row $row_no instance '$text' contains neither expected prefix '$instance_prefix' nor a bare clear instance id\n";
    }

    my %out;
    while ($suffix =~ /(?:^|_)(\d+)-([+-]?\d+)(?=_|$)/g) {
        my ($vid, $level) = (0 + $1, 0 + $2);
        die "Variable $vid occurs more than once at CSV row $row_no\n"
            if exists $out{$vid};
        $out{$vid} = $level;
    }

    die "Cannot parse variable combination after '$instance_prefix' at CSV row $row_no: '$text'\n"
        unless %out;
    return \%out;
}

sub _is_number {
    my ($x) = @_;
    return defined($x) && $x =~ /^\s*[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\s*$/;
}

sub _clamp01 {
    my ($x) = @_;
    return 0 if $x < 0;
    return 1 if $x > 1;
    return $x;
}

sub _resolve_column_index {
    my ($spec, $count, $what, $row_no) = @_;
    die "$what is not defined\n" unless defined $spec;
    die "$what must be an integer; got '$spec'\n" unless "$spec" =~ /^-?\d+$/;
    my $idx = int($spec);
    $idx = $count + $idx if $idx < 0;
    my $where = defined($row_no) ? " at CSV row $row_no" : "";
    die "$what=$spec is outside a row containing $count fields$where\n"
        if $idx < 0 || $idx >= $count;
    return $idx;
}

sub _hybrid_from_values {
    my ($values, $weights, $lambda) = @_;
    die "Internal error: hybrid requires at least one value\n" unless @$values;

    my ($wsum, $asum, $logsum, $zero) = (0, 0, 0, 0);
    for my $i (0 .. $#$values) {
        my $s = _clamp01($values->[$i]);
        my $w = $weights->[$i];
        $wsum += $w;
        $asum += $w * $s;
        if ($s <= 0) {
            $zero = 1;
        } else {
            $logsum += $w * log($s);
        }
    }

    my $A = $asum / $wsum;
    my $G = $zero ? 0 : exp($logsum / $wsum);
    return _clamp01((1 - $lambda) * $A + $lambda * $G);
}

sub _progress {
    my ($self, $message) = @_;
    say STDERR $message if $self->{verbose};
}

1;

__END__

=head1 NAME

Sim::OPT::ClusterMedoid - Hybrid similarity clustering and medoid selection for discrete Sim::OPT problem landscapes.

=head1 SYNOPSIS

  use Sim::OPT::ClusterMedoid;

  my $result = cluster_medoid(
      search_config => 'search2x.pl',
      results_file  => 'search2-report-0-0.csv',
      output_prefix => 'search2-landscape',
  );

  print "clusters: $result->{clusters}\n";
  print "first medoid: $result->{medoids}[0]{instance}\n";

From the shell, after installation:

  simopt-clustermedoid search2x.pl search2-report-0-0.csv search2-landscape

=head1 DESCRIPTION

Sim::OPT::ClusterMedoid partitions a discrete set of simulated or otherwise evaluated instances into clusters and selects one medoid for each cluster. A medoid is an actual observed instance whose total dissimilarity from the other members of its cluster is minimal. It is therefore suitable as a representative instance when an artificial average configuration would not correspond to a valid model.

The module reads the same Perl configuration file used by Sim::OPT. It uses C<$mypath> and C<$file> to recognize the instance names, and it obtains the variable identifiers and their numbers of levels directly from C<@varinumbers>. Clustering-specific options are supplied in C<%landscapecluster>.

Variables may be divided into context variables and problem variables. If C<context_variables> is absent or empty, all non-fixed variables are treated as problem variables. Variables declared with exactly one level are accepted as fixed coordinates.  Re-embedded landscapes may additionally declare C<fixed_levels =E<gt> { variable =E<gt> level, ... }> so that a coordinate fixed at a non-1 global lattice level is validated but omitted from the distance metric. Performance is read from the selected CSV column. Negative column numbers use Perl array semantics, so C<-4> means the fourth column from the end of a row.

=head1 RATIONALE AND DISTANCE CALCULATION

The calculation is designed to avoid two opposite failure modes. A purely arithmetic aggregation is compensatory: a very good match in some components can offset a poor match in another. A pure product is conjunctive but may be too severe: one zero or near-zero component can collapse the whole similarity. Sim::OPT::ClusterMedoid therefore mixes arithmetic and geometric aggregation.

For an ordered discrete variable v having L_v levels, two instances i and j have normalized variable dissimilarity

  d_v(i,j) = log(1 + |l_iv - l_jv|) / log(L_v)

and similarity

  s_v(i,j) = 1 - d_v(i,j).

Thus s_v lies in [0,1]. Equal levels give similarity 1, while the maximum possible level separation gives similarity 0.

Within a semantic group, such as the problem variables or the context variables, the weighted arithmetic similarity is

  A = sum(w_v s_v) / sum(w_v)

and the weighted geometric similarity is

  G = exp( sum(w_v log(s_v)) / sum(w_v) ).

If any positively weighted similarity is zero, G is zero. The group similarity is

  H = (1 - lambda) A + lambda G,

with C<lambda = 0.5> by default. C<lambda = 0> gives a purely arithmetic aggregation; C<lambda = 1> gives a geometric aggregation. Intermediate values trade compensability against conjunctiveness.

Performance is converted to a normalized logarithmic similarity on an analogous virtual level scale. If the performance span is divided into N divisions, one virtual step is

  step = |worst - best| / N.

For performance values y_i and y_j,

  d_y = log(1 + |y_i-y_j|/step) / log(1 + N)
  s_y = 1 - d_y,

with the step difference clipped to N. If best and worst are not specified, the observed minimum and maximum performances are used.

The same arithmetic-geometric hybrid operator is then applied to the available high-level components: context similarity, problem similarity, and performance similarity. The final clustering dissimilarity is

  D(i,j) = 1 - H_overall(i,j).

This module was motivated by the distance-based treatment of discrete design spaces in Sim::OPT::Interlinear, but the present formula is not a literal reimplementation of Interlinear. In the supplied Sim::OPT 0.921 source, Interlinear normalizes level increments by 1/(L-1), combines them with a Pythagorean distance, and then normalizes by the maximum distance. Interlinear's logarithmic option concerns the relaxation/weighting of neighbours. ClusterMedoid retains the logarithmic level mapping developed specifically for this clustering method.

=head1 CLUSTERING

The pairwise dissimilarity matrix is clustered by a pure-Perl k-medoids procedure. Initial medoids are chosen deterministically: first the globally most central observation, then observations that are farthest from the medoids already selected. Instances are assigned to their nearest medoid, and each medoid is repeatedly replaced by the member minimizing the total within-cluster dissimilarity until convergence or C<max_iterations> is reached.

If C<clustering =E<gt> { clusters =E<gt> 'auto' }> is used, candidate values of k are evaluated by the mean silhouette coefficient and the best candidate is retained. Alternatively, a fixed number of clusters may be specified.

=head1 CONFIGURATION

Add a clearly delimited block such as the following to the normal Sim::OPT configuration file:

  ##############################################################################
  ############ SIM::OPT::CLUSTERMEDOID SETTINGS - BEGIN ########################

  %landscapecluster = (
      sweep_index         => 0,
      combination_column  => 0,
      performance_column  => -4,

      # [] means that every variable in @varinumbers is a problem variable.
      # [ 1, 2 ] makes variables 1 and 2 context variables and all remaining
      # variables problem variables.
      context_variables   => [ 1, 2 ],

      # 0 = arithmetic, 1 = geometric, 0.5 = equal hybrid.
      lambda              => 0.5,

      performance => {
          divisions => 100,
          # best  => 60,   # optional; observed minimum is used if omitted
          # worst => 80,   # optional; observed maximum is used if omitted
      },

      clustering => {
          clusters          => 'auto',
          k_min             => 2,
          k_max             => 12,
          max_iterations    => 50,
          silhouette_sample => 600,
      },
  );

  ############ SIM::OPT::CLUSTERMEDOID SETTINGS - END ##########################
  ##############################################################################

C<variable_weights> and C<component_weights> may optionally be added. For example:

  variable_weights => { 1 => 2, 2 => 2, 9 => 0.5 },

  component_weights => {
      context     => 1,
      problem     => 1,
      performance => 1,
  },

All weights must be positive.

=head1 OUTPUT FILES

Four files are written using the requested output prefix:

=over 4

=item * C<.clustered.csv>

The original dataset with appended C<cluster> and C<is_medoid> columns.

=item * C<.medoids.csv>

One row for each cluster, containing the source CSV row, instance name, performance, and variable levels of the medoid.

=item * C<.silhouette.csv>

The candidate k values and the silhouette score used for selection.

=item * C<.info.txt>

A concise record of the metric, configuration, selected number of clusters, silhouette, cluster sizes, and medoid source rows.

=back

=head1 FUNCTION

=head2 cluster_medoid

  my $result = cluster_medoid(
      search_config => $configuration_file,
      results_file  => $csv_file,
      output_prefix => $prefix,       # optional
      verbose       => 1,             # optional
  );

Returns a hash reference containing the selected cluster count, silhouette, medoid records, variable classification, and paths of the files written.

=head2 run_cli

C<run_cli> is exported only on request and implements the installed C<simopt-clustermedoid> command.

=head1 MEMORY AND COMPUTATIONAL COST

The implementation stores the complete pairwise distance matrix. Its memory requirement is therefore O(n^2), and exact medoid updates can also be expensive for large datasets. The method is intended primarily for discrete experimental or simulation landscapes of moderate size, where retaining the actual medoid observations is valuable.

=head1 SEE ALSO

L<Sim::OPT>, L<Sim::OPT::Interlinear>, L<Sim::OPT::Morph>, L<Sim::OPT::Descend>.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 ACKNOWLEDGEMENTS

The initial design and implementation of ClusterMedoid were
developed by Gian Luca Brunetti with assistance from AI.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.

=cut


# Add this section to a normal Sim::OPT search configuration.
# $mypath, $file and @varinumbers remain defined in their usual places.

################################################################################
############ SIM::OPT::CLUSTERMEDOID SETTINGS - BEGIN ##########################
# EXAMPLE OF ROWS TO BE ADDED INTO A Sim:OPT configuration file
#%landscapecluster = (
#    sweep_index        => 0,
#    combination_column => 0,
#    performance_column => -4,
#
#    # Use [] when there are no context variables.
#    # In this example variables 1 and 2 are context variables; every other
#    # variable in @varinumbers is automatically treated as a problem variable.
#    context_variables  => [ 1, 2 ],
#
#    lambda => 0.5,
#
#    performance => {
#        divisions => 100,
#    },
#
#    clustering => {
#        clusters          => 'auto',
#        k_min             => 2,
#        k_max             => 12,
#        max_iterations    => 50,
#        silhouette_sample => 600,
#    },
#);
#
############ SIM::OPT::CLUSTERMEDOID SETTINGS - END ############################
################################################################################

