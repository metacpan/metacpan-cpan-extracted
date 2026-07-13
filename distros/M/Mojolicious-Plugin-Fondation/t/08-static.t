#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use File::Temp 'tempdir';
use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);
use Mojo::File;
use File::Path 'make_path';

use_ok 'Mojolicious::Plugin::Fondation';

subtest 'Static action is in default action_classes' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    $app->plugin('Fondation' => {
        dependencies => ['Fondation::User'],
    });

    my $manager = $app->manager;
    my @actions = @{$manager->action_classes};

    ok((grep { /Static$/ } @actions), 'Static action is in default action_classes');

    # Verify order: Templates < Controllers < Static
    my $tmpl_idx  = _index_of_str(\@actions, 'Mojolicious::Plugin::Fondation::Action::Templates');
    my $ctrl_idx  = _index_of_str(\@actions, 'Mojolicious::Plugin::Fondation::Action::Controllers');
    my $stat_idx  = _index_of_str(\@actions, 'Mojolicious::Plugin::Fondation::Action::Static');

    cmp_ok($tmpl_idx, '<', $ctrl_idx, 'Templates before Controllers');
    cmp_ok($ctrl_idx, '<', $stat_idx, 'Controllers before Static');
};

subtest 'Plugin with share/public/ directory registers static paths' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    my $user_share_dir = "$FindBin::Bin/share/fondation/user";

    $app->plugin('Fondation' => {
        dependencies => [
            {'Fondation::User' => { share_dir => $user_share_dir }}
        ],
    });

    my $manager = $app->manager;
    my $registry = $manager->registry;

    ok(exists $registry->{'Mojolicious::Plugin::Fondation::User'},
       'User plugin registered');

    my $user_entry = $registry->{'Mojolicious::Plugin::Fondation::User'};

    # public_dir stored in registry
    my $public_dir = $user_entry->{public_dir};
    ok($public_dir, 'public_dir is stored in registry entry');
    is($public_dir->to_string, Mojo::File->new($user_share_dir, 'public')->to_string,
       'public_dir path matches expected share/public/');

    # Static paths include the plugin's public directory
    my $paths = $app->static->paths;
    my $found = 0;
    for my $path (@$paths) {
        if ($path eq $public_dir->to_string) {
            $found = 1;
            last;
        }
    }
    ok($found, 'Plugin public directory added to static paths');
};

subtest 'Static file is served from plugin public directory' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    my $user_share_dir = "$FindBin::Bin/share/fondation/user";

    $app->plugin('Fondation' => {
        dependencies => [
            {'Fondation::User' => { share_dir => $user_share_dir }}
        ],
    });

    my $t = Test::Mojo->new($app);

    # The style.css file exists in t/share/fondation/user/public/style.css
    $t->get_ok('/style.css')
      ->status_is(200)
      ->content_type_is('text/css')
      ->content_like(qr/background-color/, 'CSS content served correctly');
};

subtest 'Static action respects explicit actions list' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    my $user_share_dir = "$FindBin::Bin/share/fondation/user";

    # Explicit actions without Static
    $app->plugin('Fondation' => {
        actions      => ['Templates', 'Controllers'],
        dependencies => [
            {'Fondation::User' => { share_dir => $user_share_dir }}
        ],
    });

    my $manager = $app->manager;
    my $user_entry = $manager->registry->{'Mojolicious::Plugin::Fondation::User'};

    # public_dir should NOT be set because Static action was excluded
    ok(!$user_entry->{public_dir},
       'public_dir NOT set when Static action excluded from actions list');
};

subtest 'Static priority: dependency plugin over parent plugin' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    my $role_share_dir = "$FindBin::Bin/share/fondation/role";
    my $auth_share_dir = "$FindBin::Bin/share/fondation/authorization";

    # Authorization depends on Role. Both have common.css in share/public/.
    $app->plugin('Fondation' => {
        dependencies => [
            {
                'Fondation::Authorization' => {
                    dependencies => [
                        {'Fondation::Role' => { share_dir => $role_share_dir }},
                    ],
                    share_dir => $auth_share_dir,
                }
            }
        ],
    });

    my $manager  = $app->manager;
    my $registry = $manager->registry;

    ok(exists $registry->{'Mojolicious::Plugin::Fondation::Role'},
       'Role plugin registered');
    ok(exists $registry->{'Mojolicious::Plugin::Fondation::Authorization'},
       'Authorization plugin registered');

    # Both should have public_dir
    ok($registry->{'Mojolicious::Plugin::Fondation::Role'}{public_dir},
       'Role has public_dir');
    ok($registry->{'Mojolicious::Plugin::Fondation::Authorization'}{public_dir},
       'Authorization has public_dir');

    # Role (dependency) path should appear BEFORE Authorization in static paths
    my $paths     = $app->static->paths;
    my $role_path = Mojo::File->new($role_share_dir, 'public')->to_string;
    my $auth_path = Mojo::File->new($auth_share_dir, 'public')->to_string;

    my $role_idx = _index_of_str($paths, $role_path);
    my $auth_idx = _index_of_str($paths, $auth_path);

    ok($role_idx >= 0, 'Role static path found');
    ok($auth_idx >= 0, 'Authorization static path found');
    cmp_ok($role_idx, '<', $auth_idx,
           'Role (dependency) static path appears before Authorization (parent)');

    # Request common.css -- should get Role's version (dependency wins)
    my $t = Test::Mojo->new($app);
    $t->get_ok('/common.css')
      ->status_is(200)
      ->content_type_is('text/css')
      ->content_like(qr/Role plugin public asset/i,
           'Dependency plugin static file is served (priority)')
      ->content_unlike(qr/Authorization plugin public asset/i,
           'Parent plugin static file is NOT served');
};

subtest 'App-level static file overrides plugin static file' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    # Create app-level public/style.css that overrides User's style.css
    my $app_public = $app->home->child('public');
    make_path($app_public);
    $app_public->child('style.css')->spurt(
        "/* App-level override */\nbody { color: green; }\n"
    );

    my $user_share_dir = "$FindBin::Bin/share/fondation/user";

    $app->plugin('Fondation' => {
        dependencies => [
            {'Fondation::User' => { share_dir => $user_share_dir }},
        ],
    });

    my $t = Test::Mojo->new($app);
    $t->get_ok('/style.css')
      ->status_is(200)
      ->content_type_is('text/css')
      ->content_like(qr/App-level override/i,
           'App-level static file is served (priority)')
      ->content_unlike(qr/background-color/,
           'Plugin static file is NOT served');
};

done_testing();

sub _index_of_str {
    my ($array, $value) = @_;
    (my $norm_value = $value) =~ s{\\}{/}g;
    for my $i (0 .. $#$array) {
        (my $norm = $array->[$i]) =~ s{\\}{/}g;
        return $i if $norm eq $norm_value;
    }
    return -1;
}
