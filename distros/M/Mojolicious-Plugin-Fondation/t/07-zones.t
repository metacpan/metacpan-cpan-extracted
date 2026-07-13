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

# ═══════════════════════════════════════════════════════════════════════════
# HTML zones
# ═══════════════════════════════════════════════════════════════════════════

subtest 'render_zone renders HTML template from plugin extension dir' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    my $user_share_dir = "$FindBin::Bin/share/fondation/user";

    $app->plugin('Fondation' => {
        dependencies => [
            {'Fondation::User' => { share_dir => $user_share_dir }}
        ]
    });

    my $c = $app->build_controller;
    my $output = $c->render_zone('header');

    like($output, qr/Hello from HTML extension/i,
         'HTML extension from User plugin is included');
};

subtest 'render_zone returns empty string for unknown zone' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    my $user_share_dir = "$FindBin::Bin/share/fondation/user";

    $app->plugin('Fondation' => {
        dependencies => [
            {'Fondation::User' => { share_dir => $user_share_dir }}
        ]
    });

    my $c = $app->build_controller;
    my $output = $c->render_zone('nonexistent_zone');

    is($output, '', 'Unknown zone returns empty string');
};

subtest 'render_zone collects from multiple plugins in load order' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    my $user_share_dir = "$FindBin::Bin/share/fondation/user";
    my $role_share_dir = "$FindBin::Bin/share/fondation/role";

    # User is loaded first, then Authorization → Role (dependency)
    $app->plugin('Fondation' => {
        dependencies => [
            {'Fondation::User' => { share_dir => $user_share_dir }},
            {
                'Fondation::Authorization' => {
                    dependencies => [
                        {'Fondation::Role' => { share_dir => $role_share_dir }},
                    ],
                }
            }
        ]
    });

    my $c = $app->build_controller;
    my $output = $c->render_zone('header');

    ok(length($output) > 0, 'Multi-plugin extensions produce non-empty output');

    # User is loaded before Role (User listed first, Role via Authorization dep)
    my $user_pos = index($output, 'Hello from HTML extension');
    my $role_pos = index($output, 'Hello from Role extension');

    ok($user_pos >= 0, 'User extension is in output');
    ok($role_pos >= 0, 'Role extension is in output');
    cmp_ok($user_pos, '<', $role_pos,
           'User extension appears before Role (load order)');
};

# ═══════════════════════════════════════════════════════════════════════════
# JS zones
# ═══════════════════════════════════════════════════════════════════════════

subtest 'render_zone_js returns JS content' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    my $user_share_dir = "$FindBin::Bin/share/fondation/user";

    $app->plugin('Fondation' => {
        dependencies => [
            {'Fondation::User' => { share_dir => $user_share_dir }}
        ]
    });

    my $c = $app->build_controller;
    my $output = $c->render_zone_js('footer');

    like($output, qr/JS extension loaded from User plugin/i,
         'JS extension content is included');
};

subtest 'render_zone_js returns empty for unknown zone' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    my $user_share_dir = "$FindBin::Bin/share/fondation/user";

    $app->plugin('Fondation' => {
        dependencies => [
            {'Fondation::User' => { share_dir => $user_share_dir }}
        ]
    });

    my $c = $app->build_controller;
    my $output = $c->render_zone_js('bogus_zone');

    is("$output", '', 'Unknown JS zone returns empty');
};

# ═══════════════════════════════════════════════════════════════════════════
# Zones without share_dir or plugin without zones
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Plugin without share_dir is silently skipped in zones' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    # Permission has no share_dir → should not cause errors
    $app->plugin('Fondation' => {
        dependencies => ['Fondation::Permission']
    });

    my $c = $app->build_controller;
    my $output = $c->render_zone('header');

    is($output, '', 'Plugin without share_dir does not break zones');
};

done_testing();
