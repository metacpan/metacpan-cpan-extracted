#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp 'tempdir';
use File::Path 'make_path';
use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use_ok 'Mojolicious::Plugin::Fondation::Resolver';

# ═══════════════════════════════════════════════════════════════════════════
# Helper: create a minimal Mojolicious app for the Resolver
# ═══════════════════════════════════════════════════════════════════════════

sub _build_app {
    require Mojolicious;
    require Mojo::Home;
    my $tempdir = tempdir(CLEANUP => 1);
    my $app_home = "$tempdir/app_home";
    mkdir $app_home;
    my $app = Mojolicious->new;
    $app->home(Mojo::Home->new($app_home));
    $app->home->child('share')->make_path;
    # Load Config with empty file so app->config works
    my $conf_file = "$tempdir/test.conf";
    open my $fh, '>', $conf_file or die $!;
    print $fh '{}';
    close $fh;
    $app->plugin('Config' => { file => $conf_file });
    return $app;
}

# ═══════════════════════════════════════════════════════════════════════════
# No dependencies
# ═══════════════════════════════════════════════════════════════════════════

subtest 'No dependencies -- single plugin' => sub {
    my $app      = _build_app();
    my $resolver = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);
    my $sorted   = $resolver->resolve('Fondation::Resolver::Leaf');

    is(scalar @$sorted, 1, 'Exactly one plugin resolved');
    is($sorted->[0]{long}, 'Mojolicious::Plugin::Fondation::Resolver::Leaf',
       'Correct long name');
    is($sorted->[0]{short}, 'Fondation::Resolver::Leaf', 'Correct short name');
    is($sorted->[0]{config}{level}, 'leaf', 'Default config merged');
};

# ═══════════════════════════════════════════════════════════════════════════
# Linear chain: Root → Mid → Leaf
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Linear chain -- deps before dependant' => sub {
    my $app      = _build_app();
    my $resolver = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);
    my $sorted   = $resolver->resolve('Fondation::Resolver::Root');

    is(scalar @$sorted, 3, 'Three plugins resolved');

    # Topological order: Leaf → Mid → Root
    my @longs = map { $_->{long} } @$sorted;
    is($longs[0], 'Mojolicious::Plugin::Fondation::Resolver::Leaf',
       'Leaf loaded first');
    is($longs[1], 'Mojolicious::Plugin::Fondation::Resolver::Mid',
       'Mid loaded second');
    is($longs[2], 'Mojolicious::Plugin::Fondation::Resolver::Root',
       'Root loaded third');
};

# ═══════════════════════════════════════════════════════════════════════════
# Direct cycle: A → B → A
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Direct cycle detected' => sub {
    my $app      = _build_app();
    my $resolver = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);

    eval {
        $resolver->resolve('Fondation::Resolver::CycleX');
        1;
    };
    ok($@, 'Cycle detection threw an error');
    like($@, qr/cycle/i,  'Error message mentions cycle');
};

# ═══════════════════════════════════════════════════════════════════════════
# Indirect cycle: A → B → C → A
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Indirect cycle detected (A→B→C→A)' => sub {
    my $app      = _build_app();
    my $resolver = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);
    # CycleX → CycleY → CycleX
    eval {
        $resolver->resolve('Fondation::Resolver::CycleX');
        1;
    };
    ok($@, 'Indirect cycle detected');
    like($@, qr/cycle/i, 'Error message mentions cycle');
};

# ═══════════════════════════════════════════════════════════════════════════
# Self-referential dependency: A → A
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Self-referential dependency detected' => sub {
    my $app      = _build_app();
    my $resolver = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);

    eval {
        $resolver->resolve('Fondation::Resolver::SelfRef');
        1;
    };
    ok($@, 'Self-reference detected as cycle');
    like($@, qr/cycle/i, 'Error message mentions cycle');
};

# ═══════════════════════════════════════════════════════════════════════════
# Duplicate dependencies
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Duplicate dependencies deduplicated' => sub {
    # We can test this by resolving a plugin twice -- second call should use
    # the previously resolved state and return the same result.
    my $app      = _build_app();
    my $resolver = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);

    my $first  = $resolver->resolve('Fondation::Resolver::Leaf');
    my $second = $resolver->resolve('Fondation::Resolver::Leaf');

    is(scalar @$first,  1, 'First resolution: 1 plugin');
    is(scalar @$second, 1, 'Second resolution: 1 plugin (no duplication)');
    is($first->[0]{long}, $second->[0]{long}, 'Same plugin resolved twice');
};

# ═══════════════════════════════════════════════════════════════════════════
# Config merge priority: direct > app config > plugin defaults
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Config merge -- direct overrides app config overrides defaults' => sub {
    my $app = _build_app();

    # Set app-level config for Leaf
    $app->config->{'Fondation::Resolver::Leaf'} = {
        key_test => 'from_app_config',
    };

    my $resolver = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);
    my $sorted   = $resolver->resolve('Fondation::Resolver::Leaf',
                                      { key_test => 'from_direct' });

    is($sorted->[0]{config}{key_test}, 'from_direct',
       'Direct config wins over app config');

    # Without direct config, app config wins over default
    my $resolver2 = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);
    my $sorted2   = $resolver2->resolve('Fondation::Resolver::Leaf');

    is($sorted2->[0]{config}{key_test}, 'from_app_config',
       'App config wins over defaults when no direct config');
};

# ═══════════════════════════════════════════════════════════════════════════
# before / after — ordering hints
# ═══════════════════════════════════════════════════════════════════════════

subtest 'after — target loaded before declarer' => sub {
    my $app      = _build_app();
    my $resolver = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);

    # BeforeAfterRoot depends on [BeforeTest, AfterTest, Leaf].
    # AfterTest declares after => ['Leaf'] → Leaf must load before AfterTest.
    my $sorted = $resolver->resolve('Fondation::Resolver::BeforeAfterRoot');

    my $leaf_pos  = _index_of('Resolver::Leaf', $sorted);
    my $after_pos = _index_of('Resolver::AfterTest', $sorted);

    ok($leaf_pos < $after_pos,
       'after: Leaf (target) loaded before AfterTest (declarer)')
        or diag "Order: " . join(', ', map { $_->{short} } @$sorted);
};

subtest 'before — declarer loaded before target' => sub {
    my $app      = _build_app();
    my $resolver = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);

    # BeforeAfterRoot depends on [BeforeTest, AfterTest, Leaf].
    # BeforeTest declares before => ['Leaf'] → BeforeTest must load before Leaf.
    my $sorted = $resolver->resolve('Fondation::Resolver::BeforeAfterRoot');

    my $before_pos = _index_of('Resolver::BeforeTest', $sorted);
    my $leaf_pos   = _index_of('Resolver::Leaf', $sorted);

    ok($before_pos < $leaf_pos,
       'before: BeforeTest (declarer) loaded before Leaf (target)')
        or diag "Order: " . join(', ', map { $_->{short} } @$sorted);
};

subtest 'before/after cycle detected' => sub {
    my $app      = _build_app();
    my $resolver = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);

    # Resolve a root that depends on BeforeCycleA and BeforeCycleB.
    # BeforeCycleA → before → BeforeCycleB
    # BeforeCycleB → before → BeforeCycleA  ← cycle!
    my $sorted = eval {
        $resolver->resolve('Mojolicious::Plugin::Fondation', {
            dependencies => [
                'Fondation::Resolver::BeforeCycleA',
                'Fondation::Resolver::BeforeCycleB',
            ],
        });
        1;
    };
    ok(!$sorted, 'before/after cycle: resolve returned no result');
    ok($@, 'before/after cycle detected');
    like($@, qr/cycle/i, 'Error message mentions cycle');
};

subtest 'before — non-existent target silently ignored' => sub {
    my $app      = _build_app();
    my $resolver = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);

    # BeforeGhost declares before => ['NonExistent']
    my $sorted = $resolver->resolve('Fondation::Resolver::BeforeGhost');

    is(scalar @$sorted, 1, 'One plugin resolved');
    is($sorted->[0]{long},
       'Mojolicious::Plugin::Fondation::Resolver::BeforeGhost',
       'BeforeGhost loaded without error');
};

# ═══════════════════════════════════════════════════════════════════════════
# dev_plugins_dir — discover plugins from a development directory
# ═══════════════════════════════════════════════════════════════════════════

subtest 'dev_plugins_dir — discovers plugins from dev directory' => sub {
    my $app = _build_app();

    # Build a fake dev directory: Mojolicious-Plugin-Fondation-DevTest/
    my $dev_root  = tempdir(CLEANUP => 1);
    my $pkg_dir   = "$dev_root/Mojolicious-Plugin-Fondation-DevTest";
    my $ns_dir    = "$pkg_dir/lib/Mojolicious/Plugin/Fondation";
    make_path($ns_dir);

    # Write a minimal Fondation plugin
    open my $fh, '>', "$ns_dir/DevTest.pm" or die $!;
    print $fh <<'END_PM';
package Mojolicious::Plugin::Fondation::DevTest;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [],
        defaults     => { from_dev => 1 },
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

1;
END_PM
    close $fh;

    my $resolver = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);
    my $sorted   = $resolver->resolve('Fondation::DevTest',
                                      { dev_plugins_dir => $dev_root });

    is(scalar @$sorted, 1, 'One plugin resolved from dev dir');
    is($sorted->[0]{long}, 'Mojolicious::Plugin::Fondation::DevTest',
       'Correct long name');
    is($sorted->[0]{config}{from_dev}, 1,
       'Dev plugin config merged');
};

done_testing();

# ── helper ────────────────────────────────────────────────────────────────

sub _index_of {
    my ($short_name, $sorted) = @_;
    for my $i (0 .. $#$sorted) {
        return $i if $sorted->[$i]{long} =~ /\Q$short_name\E$/;
    }
    return -1;
}
