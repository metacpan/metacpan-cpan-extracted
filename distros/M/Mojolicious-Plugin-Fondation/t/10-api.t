#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use File::Temp 'tempdir';
use File::Spec;
use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

use_ok 'Mojolicious::Plugin::Fondation';
use_ok 'Mojolicious::Plugin::Fondation::API';

# ═══════════════════════════════════════════════════════════════════════════
# API construction and registry access
# ═══════════════════════════════════════════════════════════════════════════

subtest 'API wraps manager and exposes registry' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app     = create_test_app($tempdir);

    $app->plugin('Fondation' => {
        dependencies => ['Fondation::User'],
    });

    my $manager = $app->manager;
    my $api     = Mojolicious::Plugin::Fondation::API->new(
        registry => $manager->registry,
    );

    isa_ok($api, 'Mojolicious::Plugin::Fondation::API');

    # registry() returns the same hashref the manager holds
    is_deeply($api->registry, $manager->registry,
              'API registry matches manager registry');
};

# ═══════════════════════════════════════════════════════════════════════════
# plugin($name) -- get a specific entry's config
# ═══════════════════════════════════════════════════════════════════════════

subtest 'plugin() returns entry config' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app     = create_test_app($tempdir);

    $app->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::User' => { title => 'Custom Users' } },
        ],
    });

    my $manager = $app->manager;
    my $api     = Mojolicious::Plugin::Fondation::API->new(
        registry => $manager->registry,
    );

    my $cfg = $api->plugin('Fondation::User');
    ok($cfg, 'plugin() returns a hashref for existing plugin');
    is($cfg->{title}, 'Custom Users', 'Config value is correct');

    my $missing = $api->plugin('Fondation::NoSuch');
    ok(!$missing, 'plugin() returns undef for non-existent plugin');
};

# ═══════════════════════════════════════════════════════════════════════════
# config($name) -- get merged config (alias for plugin())
# ═══════════════════════════════════════════════════════════════════════════

subtest 'config() returns merged config' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app     = create_test_app($tempdir);

    $app->plugin('Fondation' => {
        dependencies => ['Fondation::User'],
    });

    my $manager = $app->manager;
    my $api     = Mojolicious::Plugin::Fondation::API->new(
        registry => $manager->registry,
    );

    my $cfg = $api->config('Fondation::User');
    ok($cfg, 'config() returns hashref');
    is($cfg->{key_test}, 'plugin_default', 'Plugin default config accessible');

    is_deeply($api->config('Fondation::User'), $api->plugin('Fondation::User'),
              'config() and plugin() return the same data');
};

# ═══════════════════════════════════════════════════════════════════════════
# Backward compat: manager helper still works
# ═══════════════════════════════════════════════════════════════════════════

subtest 'manager helper unchanged' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app     = create_test_app($tempdir);

    $app->plugin('Fondation' => {
        dependencies => ['Fondation::User'],
    });

    my $manager = $app->manager;
    ok($manager, 'manager helper still accessible');
    isa_ok($manager, 'Mojolicious::Plugin::Fondation::Manager');
};

done_testing();
