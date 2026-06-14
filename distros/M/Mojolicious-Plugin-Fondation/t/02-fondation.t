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
# fondation_finalyze
# ═══════════════════════════════════════════════════════════════════════════

subtest 'fondation_finalyze called in load order (dep before dependant)' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    # Authorization depends on Role + Permission.
    # Role has fondation_finalyze, Authorization has fondation_finalyze.
    $app->plugin('Fondation' => {
        dependencies => ['Fondation::Authorization']
    });

    my $calls = $app->{_finalyze_calls} || [];
    ok(@$calls >= 2, 'At least 2 finalyze calls made');

    # Role (dependency) should be called before Authorization (dependant)
    my $role_idx = _index_of_str($calls,
        'Mojolicious::Plugin::Fondation::Role');
    my $auth_idx = _index_of_str($calls,
        'Mojolicious::Plugin::Fondation::Authorization');
    ok($role_idx >= 0, 'Role finalyze was called');
    ok($auth_idx >= 0, 'Authorization finalyze was called');
    cmp_ok($role_idx, '<', $auth_idx,
        'Role (dep) finalyze called before Authorization (dependant)');
};

subtest 'Plugin without fondation_finalyze is skipped silently' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    # Permission has NO fondation_finalyze -- should not error
    $app->plugin('Fondation' => {
        dependencies => ['Fondation::Permission']
    });

    my $fondation = $app->manager;
    ok($fondation->registry->{'Mojolicious::Plugin::Fondation::Permission'},
       'Permission loaded despite no fondation_finalyze');
};

subtest 'Plugin with fondation_finalyze receives correct app and long_name' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    $app->plugin('Fondation' => {
        dependencies => ['Fondation::Role']
    });

    my $calls = $app->{_finalyze_calls} || [];
    ok(@$calls == 1, 'Exactly 1 finalyze call for Role');
    is($calls->[0], 'Mojolicious::Plugin::Fondation::Role',
       'fondation_finalyze receives correct long_name');
};

# ═══════════════════════════════════════════════════════════════════════════
# has_helper
# ═══════════════════════════════════════════════════════════════════════════

subtest 'has_helper detects registered helpers' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    $app->plugin('Fondation' => {
        dependencies => ['Fondation::Authorization']
    });

    ok($app->has_helper('manager'),      'manager helper exists');
    ok($app->has_helper('check_group'),  'check_group helper exists');
    ok($app->has_helper('check_perm'),   'check_perm helper exists');
    ok($app->has_helper('has_helper'),   'has_helper detects itself');
    ok(!$app->has_helper('nonexistent'), 'nonexistent helper returns false');
};

# ═══════════════════════════════════════════════════════════════════════════
# Helpers fallback
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Fallback helpers work when plugin not loaded' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    $app->plugin('Fondation');

    my $c = $app->build_controller;

    # l() returns key as-is (no I18N plugin)
    is($c->l('some.key'), 'some.key', 'l() returns key as-is (no I18N)');

    # check_group and check_perm are permissive
    ok($c->check_group, 'check_group permits (no Authorization)');
    ok($c->check_perm,  'check_perm permits (no Authorization)');

    # notify_user returns resolved Promise
    my $promise = $c->notify_user;
    ok($promise, 'notify_user returns a Promise');
};

# ═══════════════════════════════════════════════════════════════════════════
# fondation helper (API)
# ═══════════════════════════════════════════════════════════════════════════

subtest 'fondation helper returns API instance' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    $app->plugin('Fondation' => {
        dependencies => ['Fondation::User'],
    });

    my $api = $app->fondation;
    isa_ok($api, 'Mojolicious::Plugin::Fondation::API',
           'fondation helper returns API instance');

    # API wraps the same registry as manager
    is_deeply($api->registry, $app->manager->registry,
              'API registry matches manager registry');

    # API can resolve plugin config
    my $cfg = $api->config('Fondation::User');
    ok($cfg, 'API config() returns user config');
    is($cfg->{key_test}, 'plugin_default', 'Config value correct via API');
};

done_testing();

sub _index_of_str {
    my ($array, $value) = @_;
    for my $i (0 .. $#$array) {
        return $i if $array->[$i] eq $value;
    }
    return -1;
}
