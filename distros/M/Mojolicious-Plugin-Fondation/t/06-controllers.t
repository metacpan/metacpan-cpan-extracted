#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::Home;
use File::Temp 'tempdir';
use File::Spec;
use FindBin;

# Add lib directories to @INC so plugins can be found
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

# Use test helper for creating apps with temporary home
use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

# Real app class for testing app-level controllers
use MyApp;

# Load the Fondation plugin
use_ok 'Mojolicious::Plugin::Fondation';


subtest 'Controller priority: dependency plugin over parent plugin' => sub {
    # Create fresh app
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    # Define share directories for Role, Permission and Authorization plugins
    my $role_share_dir = "$FindBin::Bin/share/fondation/role";
    my $perm_share_dir = "$FindBin::Bin/share/fondation/permission";
    my $auth_share_dir = "$FindBin::Bin/share/fondation/authorization";

    # Load Fondation with Authorization plugin, explicit share_dir for all plugins,
    # and enable Controllers action
    $app->plugin('Fondation' => {
        actions => ['Templates', 'Assets', 'Controllers'],  # Enable Controllers action
        dependencies => [
            {
                'Fondation::Authorization' => {
                    dependencies => [
                        ['Fondation::Role', { share_dir => $role_share_dir }],
                        ['Fondation::Permission', { share_dir => $perm_share_dir }]
                    ],
                    share_dir => $auth_share_dir
                }
            }
        ]
    });

    my $fondation = $app->manager;
    my $registry = $fondation->registry;

    # Check that all plugins are registered
    ok(exists $registry->{'Mojolicious::Plugin::Fondation::Role'}, 'Role plugin registered');
    ok(exists $registry->{'Mojolicious::Plugin::Fondation::Permission'}, 'Permission plugin registered');
    ok(exists $registry->{'Mojolicious::Plugin::Fondation::Authorization'}, 'Authorization plugin registered');

    # Check controller namespaces in routes
    my $namespaces = $app->routes->namespaces;

    # Find positions of Role and Authorization controller namespaces
    my $role_ns = 'Mojolicious::Plugin::Fondation::Role::Controller';
    my $auth_ns = 'Mojolicious::Plugin::Fondation::Authorization::Controller';

    my $role_index = -1;
    my $auth_index = -1;

    for my $i (0 .. $#{$namespaces}) {
        $role_index = $i if $namespaces->[$i] eq $role_ns;
        $auth_index = $i if $namespaces->[$i] eq $auth_ns;
    }

    ok($role_index >= 0, "Role controller namespace found in routes namespaces");
    ok($auth_index >= 0, "Authorization controller namespace found in routes namespaces");

    # The dependency (Role) should appear BEFORE the parent (Authorization) in namespaces
    cmp_ok($role_index, '<', $auth_index,
           'Role (dependency) controller namespace appears before Authorization (parent)');

    # Check that controllers are registered in plugin entries
    my $role_entry = $registry->{'Mojolicious::Plugin::Fondation::Role'};
    my $auth_entry = $registry->{'Mojolicious::Plugin::Fondation::Authorization'};

    ok($role_entry->{controllers}, 'Role plugin has controllers registered');
    ok($auth_entry->{controllers}, 'Authorization plugin has controllers registered');

    # Both plugins should have the Common controller
    my @role_controllers = @{$role_entry->{controllers} || []};
    my @auth_controllers = @{$auth_entry->{controllers} || []};

    my $role_has_common = grep { /Common$/ } @role_controllers;
    my $auth_has_common = grep { /Common$/ } @auth_controllers;

    ok($role_has_common, 'Role plugin has Common controller');
    ok($auth_has_common, 'Authorization plugin has Common controller');

    # Create a test route that uses the Common controller
    # Since Role namespace is first, Mojolicious should find Role::Controller::Common first
    $app->routes->get('/common')->to('common#index');

    # Create Test::Mojo instance and test
    my $t = Test::Mojo->new($app);
    $t->get_ok('/common')
      ->status_is(200)
      ->content_like(qr/Controller from ROLE plugin/i,
           'Dependency plugin controller should be used (priority)')
      ->content_unlike(qr/Controller from AUTHORIZATION plugin/i,
           'Parent plugin controller should NOT be used');
};

subtest 'Plugin with unique controller (no name conflict) + metadata' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    $app->plugin('Fondation' => {
        dependencies => [['Fondation::TestController', {}]]
    });

    my $fondation = $app->manager;
    my $registry  = $fondation->registry;

    ok(exists $registry->{'Mojolicious::Plugin::Fondation::TestController'},
       'TestController plugin registered');

    my $entry = $registry->{'Mojolicious::Plugin::Fondation::TestController'};

    # Metadata set by Controllers action
    ok($entry->{metadata}{controllers_count},
       'metadata->controllers_count is set');
    ok($entry->{metadata}{controllers_ns},
       'metadata->controllers_ns is set');
    is($entry->{metadata}{controllers_count}, 1,
       'Exactly 1 controller discovered for TestController');
    is($entry->{metadata}{controllers_ns},
       'Mojolicious::Plugin::Fondation::TestController::Controller',
       'Controller namespace is correct');

    # Controllers array in entry
    ok($entry->{controllers}, 'TestController entry has controllers array');
    my @ctrls = @{$entry->{controllers}};
    is(scalar @ctrls, 1, 'Exactly 1 controller in array');
    like($ctrls[0], qr/::Controller::List$/,
         'List controller is registered');

    # Namespace should be in routes
    my $namespaces = $app->routes->namespaces;
    my $found = grep { $_ eq 'Mojolicious::Plugin::Fondation::TestController::Controller' }
                     @$namespaces;
    ok($found, 'TestController namespace added to routes');

    # The controller should be reachable
    $app->routes->get('/testcontroller-list')->to('list#index');
    my $t = Test::Mojo->new($app);
    $t->get_ok('/testcontroller-list')
      ->status_is(200)
      ->content_like(qr/TestController list/i,
           'TestController responds correctly');
};

subtest 'App controller has priority over plugin controller' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    # Real app -- MyApp::Controller is automatically in routes->namespaces
    # because Mojolicious adds the app's namespace by default
    my $app = MyApp->new;
    $app->home(Mojo::Home->new($tempdir));
    $app->home->child('share')->make_path;

    my $role_share_dir = "$FindBin::Bin/share/fondation/role";

    $app->plugin('Fondation' => {
        dependencies => [
            ['Fondation::Role', { share_dir => $role_share_dir }]
        ]
    });

    # MyApp::Controller should be first (native), plugin namespaces after
    my $namespaces = $app->routes->namespaces;
    my $app_idx  = _index_of_str($namespaces, 'MyApp::Controller');
    my $role_idx = _index_of_str($namespaces,
        'Mojolicious::Plugin::Fondation::Role::Controller');
    ok($app_idx >= 0, 'MyApp::Controller is in routes namespaces');
    ok($role_idx >= 0, 'Role::Controller is in routes namespaces');
    cmp_ok($app_idx, '<', $role_idx,
           'App namespace is before plugin namespace');

    # Both MyApp::Controller::Common and Role::Controller::Common exist
    # App should win because its namespace comes first
    $app->routes->get('/app-vs-plugin')->to('common#index');
    my $t = Test::Mojo->new($app);
    $t->get_ok('/app-vs-plugin')
      ->status_is(200)
      ->content_like(qr/Controller from LOCAL APP/i,
           'App controller wins over plugin controller')
      ->content_unlike(qr/Controller from ROLE plugin/i,
           'Plugin controller is NOT used');
};

subtest 'Plugin without controllers' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    # Permission plugin has no Controller/ directory
    $app->plugin('Fondation' => {
        dependencies => ['Fondation::Permission']
    });

    my $fondation = $app->manager;
    my $registry  = $fondation->registry;

    ok(exists $registry->{'Mojolicious::Plugin::Fondation::Permission'},
       'Permission plugin registered');

    my $perm_entry = $registry->{'Mojolicious::Plugin::Fondation::Permission'};

    # No controllers should be registered
    ok(!$perm_entry->{controllers},
       'Permission entry has no controllers (no Controller/ dir)');

    # Metadata should reflect 0 controllers
    is($perm_entry->{metadata}{controllers_count}, 0,
       'controllers_count is 0 for plugin without controllers');
};

subtest 'Controllers action is active by default' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    # Load Fondation WITHOUT explicit 'actions' -- Controllers should be active
    $app->plugin('Fondation' => {
        dependencies => [['Fondation::TestController', {}]]
    });

    my $fondation = $app->manager;
    my $registry  = $fondation->registry;

    my $entry = $registry->{'Mojolicious::Plugin::Fondation::TestController'};
    ok($entry, 'TestController plugin registered');

    # Controllers should be discovered even without explicit 'actions'
    ok($entry->{controllers}, 'Controllers discovered by default');
    ok($entry->{metadata}{controllers_count} == 1,
       'Exactly 1 controller found with default actions');

    # Verify the route actually works
    $app->routes->get('/default-controllers')->to('list#index');
    my $t = Test::Mojo->new($app);
    $t->get_ok('/default-controllers')
      ->status_is(200)
      ->content_like(qr/TestController list/i,
           'Controller works with default Controllers action');
};

done_testing();

sub _index_of_str {
    my ($array, $value) = @_;
    for my $i (0 .. $#$array) {
        return $i if $array->[$i] eq $value;
    }
    return -1;
}
