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

use_ok 'Mojolicious::Plugin::Fondation';

# ── Route without requires — always accessible ───────────────────────

subtest 'Route without requires is always accessible' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);
    $app->plugin('Fondation' => {dependencies => []});

    $app->routes->get('/public')->to(cb => sub {
        shift->render(text => 'OK', status => 200);
    });

    my $t = Test::Mojo->new($app);
    $t->get_ok('/public')->status_is(200)->content_is('OK');
};

# ── fondation.perm with no-op (allow all) ────────────────────────────

subtest 'fondation.perm with no-op check_perm — route accessible' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);
    $app->plugin('Fondation' => {dependencies => []});

    $app->routes->get('/admin')
        ->requires('fondation.perm' => 'admin_access')
        ->to(cb => sub { shift->render(text => 'Admin', status => 200) });

    my $t = Test::Mojo->new($app);
    $t->get_ok('/admin')->status_is(200)->content_is('Admin');
};

# ── fondation.perm blocked when check_perm returns 0 ─────────────────

subtest 'fondation.perm blocked when check_perm returns 0' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);
    $app->plugin('Fondation' => {dependencies => []});

    $app->routes->get('/admin')
        ->requires('fondation.perm' => 'admin_access')
        ->to(cb => sub { shift->render(text => 'Admin', status => 200) });

    # Override the no-op helper to deny all permissions
    $app->helper(check_perm => sub { 0 });

    my $t = Test::Mojo->new($app);
    $t->get_ok('/admin')->status_is(403);
};

# ── fondation.group with no-op (allow all) ───────────────────────────

subtest 'fondation.group with no-op check_group — route accessible' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);
    $app->plugin('Fondation' => {dependencies => []});

    $app->routes->get('/members')
        ->requires('fondation.group' => 'admins')
        ->to(cb => sub { shift->render(text => 'Members', status => 200) });

    my $t = Test::Mojo->new($app);
    $t->get_ok('/members')->status_is(200)->content_is('Members');
};

# ── fondation.group blocked when check_group returns 0 ───────────────

subtest 'fondation.group blocked when check_group returns 0' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);
    $app->plugin('Fondation' => {dependencies => []});

    $app->routes->get('/members')
        ->requires('fondation.group' => 'admins')
        ->to(cb => sub { shift->render(text => 'Members', status => 200) });

    # Override the no-op helper to deny all groups
    $app->helper(check_group => sub { 0 });

    my $t = Test::Mojo->new($app);
    $t->get_ok('/members')->status_is(403);
};

# ── Combination: perm + group, both no-ops ───────────────────────────

subtest 'Combination fondation.perm + fondation.group with no-ops — accessible' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);
    $app->plugin('Fondation' => {dependencies => []});

    $app->routes->get('/vault')
        ->requires(
            'fondation.perm'  => 'vault_access',
            'fondation.group' => 'admins',
        )
        ->to(cb => sub { shift->render(text => 'Vault', status => 200) });

    my $t = Test::Mojo->new($app);
    $t->get_ok('/vault')->status_is(200)->content_is('Vault');
};

# ── Combination: perm denied, group allowed — blocked ────────────────

subtest 'Combination: perm blocked, group allowed — route blocked' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);
    $app->plugin('Fondation' => {dependencies => []});

    $app->routes->get('/vault')
        ->requires(
            'fondation.perm'  => 'vault_access',
            'fondation.group' => 'admins',
        )
        ->to(cb => sub { shift->render(text => 'Vault', status => 200) });

    $app->helper(check_perm => sub { 0 });
    # check_group stays as no-op (returns 1)

    my $t = Test::Mojo->new($app);
    $t->get_ok('/vault')->status_is(403);
};

# ── Combination: group denied, perm allowed — blocked ────────────────

subtest 'Combination: group blocked, perm allowed — route blocked' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);
    $app->plugin('Fondation' => {dependencies => []});

    $app->routes->get('/vault')
        ->requires(
            'fondation.perm'  => 'vault_access',
            'fondation.group' => 'admins',
        )
        ->to(cb => sub { shift->render(text => 'Vault', status => 200) });

    $app->helper(check_group => sub { 0 });
    # check_perm stays as no-op (returns 1)

    my $t = Test::Mojo->new($app);
    $t->get_ok('/vault')->status_is(403);
};

# ── Condition names are registered ───────────────────────────────────

subtest 'fondation.perm and fondation.group conditions are registered' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);
    $app->plugin('Fondation' => {dependencies => []});

    my $conditions = $app->routes->conditions;
    ok(exists $conditions->{'fondation.perm'},
        q{'fondation.perm' condition registered});
    ok(exists $conditions->{'fondation.group'},
        q{'fondation.group' condition registered});
};

done_testing;
