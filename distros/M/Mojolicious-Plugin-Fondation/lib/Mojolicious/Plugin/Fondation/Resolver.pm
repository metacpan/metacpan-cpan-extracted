package Mojolicious::Plugin::Fondation::Resolver;
$Mojolicious::Plugin::Fondation::Resolver::VERSION = '0.02';
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

    $self->_visit($long, $direct_conf);

    return $self->{result};
}

# ---------------------------------------------------------------------------
# _visit -- DFS traversal with 3-state cycle detection
#
# State machine:
#   undef     -> unvisited, recurse
#   'visiting' -> currently in DFS path -> CYCLE DETECTED
#   'visited'  -> already resolved, skip
#
# On cycle: dies with a message naming the plugin causing the cycle.
# ---------------------------------------------------------------------------
sub _visit ($self, $long, $direct_conf) {
    my $state = $self->states->{$long};

    if (defined $state && $state eq 'visiting') {
        die "Dependency cycle detected: $long is part of a circular dependency chain.\n";
    }

    return if defined $state && $state eq 'visited';

    # Mark as visiting -- if we encounter it again during this DFS, it's a cycle
    $self->states->{$long} = 'visiting';

    my $meta    = $self->_discover_meta($long);
    my $short   = short_name($long);
    my $merged  = merge(
        $direct_conf,
        $self->app->config->{$short} // {},
        $meta->{defaults} // {}
    );

    # Resolve dependencies first (depth-first = deps before dependant)
    my $deps = $merged->{dependencies} // $meta->{dependencies} // [];
    for my $dep_spec (@$deps) {
        my ($dep_name, $dep_conf);
        if (ref $dep_spec eq 'HASH') {
            ($dep_name) = keys %$dep_spec;
            $dep_conf = $dep_spec->{$dep_name} // {};
        }
        elsif (ref $dep_spec eq 'ARRAY') {
            ($dep_name, $dep_conf) = @$dep_spec;
            $dep_conf //= {};
        }
        else {
            $dep_name    = $dep_spec;
            $dep_conf    = {};
        }
        $self->_visit(long_name($dep_name), $dep_conf);
    }

    # Mark as visited + add to result (post-order = deps added first)
    $self->states->{$long} = 'visited';
    push @{$self->result}, {
        long   => $long,
        short  => $short,
        config => $merged,
        meta   => $meta,
    };
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

version 0.02

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
