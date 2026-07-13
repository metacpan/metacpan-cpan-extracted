package Mojolicious::Plugin::Fondation::Resolver;
$Mojolicious::Plugin::Fondation::Resolver::VERSION = '0.04';
# ABSTRACT: Dependency graph resolver with cycle detection and topological sort

use Mojo::Base -base, -signatures;
use Mojolicious::Plugin::Fondation::Utils qw(long_name short_name merge);

has 'app';
has 'states' => sub { {} };   # $long_name => 'visiting' | 'visited'
has 'result' => sub { [] };    # topologically sorted specs

# ---------------------------------------------------------------------------
# resolve -- entry point
#
# Returns an arrayref of plugin specs in topological order (deps first).
# Each spec: { long => $long, short => $short, config => $merged, meta => $meta }
#
# Dies on dependency cycles with a clear message.
# ---------------------------------------------------------------------------
sub resolve ($self, $name_or_short, $direct_conf = {}) {
    my $long = long_name($name_or_short);

    # Reset internal state for fresh resolution
    $self->{states} = {};
    $self->{result} = [];

    # Phase 1 — Discover all plugins via the original dependency graph
    my $graph = {};
    $self->_discover_graph($long, $direct_conf, $graph);

    # Phase 2 — Augment with before / after ordering hints
    $self->_augment_graph($graph);

    # Phase 3 — Topological sort on the augmented graph
    $self->{states} = {};
    $self->_sort($long, $graph);

    return $self->{result};
}

# ---------------------------------------------------------------------------
# Phase 1 — _discover_graph: DFS to collect every reachable plugin.
# Builds a flat map: $long => { deps => [...], config => {...}, meta => {...} }
# ---------------------------------------------------------------------------
sub _discover_graph ($self, $long, $direct_conf, $graph) {
    return if $graph->{$long};    # already discovered

    my $meta   = $self->_discover_meta($long);
    my $short  = short_name($long);
    my $merged = merge(
        $direct_conf,
        $self->app->config->{$short} // {},
        $meta->{defaults} // {}
    );

    my $deps = $merged->{dependencies} // $meta->{dependencies} // [];

    $graph->{$long} = {
        deps   => [@$deps],           # shallow copy of spec list
        config => $merged,
        meta   => $meta,
    };

    # Recurse into declared dependencies
    for my $dep_spec (@$deps) {
        my ($dep_name, $dep_conf) = $self->_parse_dep($dep_spec);
        $self->_discover_graph(long_name($dep_name), $dep_conf, $graph);
    }
}

# ---------------------------------------------------------------------------
# Phase 2 — _augment_graph: add edges from before / after declarations.
#
#   after  => ['B']   →   B must load before me   →   B is a dependency of me
#   before => ['B']   →   I must load before B     →   I am a dependency of B
#
# Silently ignored when the target plugin is not in the graph.
# ---------------------------------------------------------------------------
sub _augment_graph ($self, $graph) {
    for my $long (keys %$graph) {
        my $entry = $graph->{$long};

        # after — the named plugin should be loaded before me
        my $after = $entry->{config}{after} // $entry->{meta}{after} // [];
        for my $target_short (@$after) {
            my $target = long_name($target_short);
            next unless $graph->{$target};
            push @{$entry->{deps}}, $target;
        }

        # before — I should be loaded before the named plugin
        my $before = $entry->{config}{before} // $entry->{meta}{before} // [];
        for my $target_short (@$before) {
            my $target = long_name($target_short);
            next unless $graph->{$target};
            push @{$graph->{$target}{deps}}, $long;
        }
    }
}

# ---------------------------------------------------------------------------
# Phase 3 — _sort: topological sort via DFS with 3-state cycle detection.
#
# Cycles caused by conflicting before/after are caught here just like
# dependency cycles.
# ---------------------------------------------------------------------------
sub _sort ($self, $long, $graph) {
    my $state = $self->states->{$long};

    if (defined $state && $state eq 'visiting') {
        die "Dependency cycle detected: $long is part of a circular dependency chain.\n";
    }
    return if defined $state && $state eq 'visited';

    $self->states->{$long} = 'visiting';

    my $entry = $graph->{$long};
    for my $dep_spec (@{$entry->{deps}}) {
        my ($dep_name) = $self->_parse_dep($dep_spec);
        $self->_sort(long_name($dep_name), $graph);
    }

    $self->states->{$long} = 'visited';
    push @{$self->result}, {
        long   => $long,
        short  => short_name($long),
        config => $entry->{config},
        meta   => $entry->{meta},
    };
}

# ---------------------------------------------------------------------------
# _parse_dep -- normalize a dependency spec (string or hashref).
# Returns ($name, $conf).
# ---------------------------------------------------------------------------
sub _parse_dep ($self, $dep_spec) {
    if (ref $dep_spec eq 'HASH') {
        my ($name) = keys %$dep_spec;
        return ($name, $dep_spec->{$name} // {});
    }
    return ($dep_spec, {});
}

# ---------------------------------------------------------------------------
# _discover_meta -- load fondation_meta from a plugin class without
# instantiating it (i.e. without calling register).
# ---------------------------------------------------------------------------
sub _discover_meta ($self, $long_name) {
    my $class = $long_name;

    # If the module is already loaded in %INC, do not reload it
    my $pm_file = $class =~ s{::}{/}gr . '.pm';
    if ($INC{$pm_file}) {
        return $class->can('fondation_meta')
            ? $class->fondation_meta
            : { dependencies => [], defaults => {} };
    }

    my $err = Mojo::Loader::load_class($class);
    if ($err) {
        $self->app->log->warn("Resolver: could not load $class -- $err");
        return { dependencies => [], defaults => {} };
    }

    return $class->can('fondation_meta')
        ? $class->fondation_meta
        : { dependencies => [], defaults => {} };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Resolver - Dependency graph resolver with cycle detection and topological sort

=head1 VERSION

version 0.04

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
