#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use File::Temp 'tempdir';
use File::Spec;
use FindBin;
use Mojo::File;
use File::Path 'make_path';
use Data::Dumper;
use feature 'signatures';

# Add lib directories to @INC so plugins can be found
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

# Use test helper for creating apps with temporary home
use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

# Load the Fondation plugin
use_ok 'Mojolicious::Plugin::Fondation';


subtest 'Plugin with share/templates directory' => sub {
    # Create a fresh app for this subtest with temporary home
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    # Define the share directory for the User plugin (located in t/share/fondation/user)
    my $user_share_dir = "$FindBin::Bin/share/fondation/user";

    # Load Fondation with User plugin and explicit share_dir
    $app->plugin('Fondation' => {
        dependencies => [
            ['Fondation::User', { share_dir => $user_share_dir }]
        ]
    });
    my $fondation = $app->manager;
    isa_ok($fondation, 'Mojolicious::Plugin::Fondation::Manager', 'Fondation manager object');

    # Get User plugin instance from registry
    my $registry = $fondation->registry;
    ok(exists $registry->{'Mojolicious::Plugin::Fondation::User'}, 'User plugin registered');

    my $user_entry = $registry->{'Mojolicious::Plugin::Fondation::User'};
    my $user_instance = $user_entry->{instance};
    my $plugin_share_dir = $user_entry->{share_dir};
    ok($plugin_share_dir, 'User plugin has share_dir');

    # Verify share_dir matches what was passed
    is($plugin_share_dir->to_string, $user_share_dir,
       'share_dir in registry matches the one passed in config');

    my $template_dir = $plugin_share_dir->child('templates');

    # Check that templates subdirectory exists
    ok(-d $template_dir, "Template directory exists at $template_dir");
    like(
        $template_dir,
        qr{t/share/fondation/user/templates$},
        "template_dir ends with t/share/fondation/user/templates"
        );

    # Get template paths from renderer
    my $paths = $app->renderer->paths;

    # Debug output
    # diag "Template paths:";
    # foreach my $path (@$paths) {
    #     diag "  - $path";
    # }

    # Check that plugin's template directory was added to renderer paths
    my $found_template_path = 0;
    foreach my $path (@$paths) {
        if ($path eq $template_dir->to_string) {
            $found_template_path = 1;
            last;
        }
    }
    ok($found_template_path, 'Template directory was added to renderer paths');

    # Check that the template file exists
    my $template_file = $template_dir->child('hello.html.ep');
    ok(-e $template_file, "Template file exists at $template_file");

    # Check that templates were registered in the entry's template hash
    my $templates = $user_entry->{templates};
    ok($templates && ref $templates eq 'HASH', 'User entry has templates hash');
    ok(exists $templates->{'hello.html.ep'}, 'hello.html.ep is registered in templates hash');
    is($templates->{'hello.html.ep'}{basename}, 'hello.html.ep',
       'Template basename is correct');
    is($templates->{'hello.html.ep'}{full_path}, $template_file->to_string,
       'Template full_path matches actual file path');
};


subtest 'Template rendering from plugin' => sub {

    # Create a mini test application
    my $t = Test::Mojo->new;
    my $app = $t->app;

    # Define the share directory for the User plugin (located in t/share/fondation/user)
    my $user_share_dir = "$FindBin::Bin/share/fondation/user";

    $app->plugin('Fondation' => {
        dependencies => [
            ['Fondation::User', { share_dir => $user_share_dir }]
        ]
    });

    # Add a test route that renders the 'hello' template
    $app->routes->get('/test-plugin-template' => sub ($c) {
                             $c->render('hello');
    });

    # Check if the template file is discoverable in any of the paths
    my $found = 0;
    foreach my $path (@{ $app->renderer->paths }) {
        my $file = Mojo::File->new($path, 'hello.html.ep');
        if (-e $file) {
            ok(1, "Template file exists at: $file");
            $found = 1;
            last;
        }
    }

    # Optional: fail explicitly if template not found (helps debugging)
    ok($found, 'hello.html.ep template was found in renderer paths')
        or diag "→ Make sure t/share/fondation/user/templates is correctly added by the plugin";

    $t->get_ok('/test-plugin-template')
      ->status_is(200, 'Status 200 OK')
      ->content_type_is('text/html;charset=UTF-8', 'Expected HTML type')
      ->content_like(qr/Hello from User dev share/i, 'Template contains expected text')
      ;

};

subtest 'Template priority: dependency plugin over parent plugin' => sub {
    # Create fresh app
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    # Define share directories for Role, Permission and Authorization plugins
    my $role_share_dir = "$FindBin::Bin/share/fondation/role";
    my $perm_share_dir = "$FindBin::Bin/share/fondation/permission";
    my $auth_share_dir = "$FindBin::Bin/share/fondation/authorization";

    # Load Fondation with Authorization plugin and explicit share_dir for all plugins
    # Authorization depends on Role and Permission
    $app->plugin('Fondation' => {
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

    # Verify that Role template directory was added before Authorization
    my $paths = $app->renderer->paths;
    my $role_path = "$role_share_dir/templates";
    my $auth_path = "$auth_share_dir/templates";

    my $role_index = -1;
    my $auth_index = -1;
    for my $i (0 .. $#{$paths}) {
        $role_index = $i if $paths->[$i] eq $role_path;
        $auth_index = $i if $paths->[$i] eq $auth_path;
    }

    ok($role_index >= 0, "Role template path found in renderer paths");
    ok($auth_index >= 0, "Authorization template path found in renderer paths");
    cmp_ok($role_index, '<', $auth_index,
           'Role (dependency) template path appears before Authorization (parent) path');

    # Add a test route that renders the 'common' template
    $app->routes->get('/test-priority' => sub ($c) {
        $c->render('common');
    });

    # Create Test::Mojo instance and test
    my $t = Test::Mojo->new($app);
    $t->get_ok('/test-priority')
      ->status_is(200)
      ->content_like(qr/Common Template from ROLE plugin/i,
           'Dependency plugin template should be used (priority)')
      ->content_unlike(qr/Common Template from AUTHORIZATION plugin/i,
           'Parent plugin template should NOT be used');
};


subtest 'App-level template overrides plugin template' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    # Create app-level share/templates that will override User's hello.html.ep
    my $app_templates = Mojo::File->new($app->home->child('share', 'templates'));
    make_path($app_templates);
    $app_templates->child('hello.html.ep')->spurt(
        "<h1>Hello from APP-LEVEL template (overrides plugin)</h1>\n"
    );

    my $user_share_dir = "$FindBin::Bin/share/fondation/user";

    $app->plugin('Fondation' => {
        dependencies => [
            ['Fondation::User', { share_dir => $user_share_dir }]
        ]
    });

    $app->routes->get('/test-app-priority' => sub ($c) {
        $c->render('hello');
    });

    my $t = Test::Mojo->new($app);
    $t->get_ok('/test-app-priority')
      ->status_is(200)
      ->content_like(qr/Hello from APP-LEVEL/i,
           'App-level template is used instead of plugin template')
      ->content_unlike(qr/Hello from User dev share/i,
           'Plugin template is NOT used because app template has priority');
};

subtest 'Transitive dependency template is registered and renderable' => sub {
    # Load Authorization → Role (dependency). Role has common.html.ep.
    # Authorization also has one, but we test that Role's is registered
    # and usable even when no direct share_dir is given to Authorization.
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    my $role_share_dir = "$FindBin::Bin/share/fondation/role";

    $app->plugin('Fondation' => {
        dependencies => [
            {
                'Fondation::Authorization' => {
                    dependencies => [
                        ['Fondation::Role', { share_dir => $role_share_dir }],
                    ],
                }
            }
        ]
    });

    my $fondation = $app->manager;
    my $registry  = $fondation->registry;

    ok(exists $registry->{'Mojolicious::Plugin::Fondation::Role'},
       'Role registered as transitive dependency');

    # Role's templates should be discoverable
    my $role_entry = $registry->{'Mojolicious::Plugin::Fondation::Role'};
    my $templates  = $role_entry->{templates};
    ok($templates && exists $templates->{'common.html.ep'},
       'common.html.ep from Role is registered in templates hash');

    $app->routes->get('/test-transitive-dep' => sub ($c) {
        $c->render('common');
    });

    my $t = Test::Mojo->new($app);
    $t->get_ok('/test-transitive-dep')
      ->status_is(200)
      ->content_like(qr/Common Template from ROLE plugin/i,
           'Transitive dependency template is rendered');
};

done_testing();
