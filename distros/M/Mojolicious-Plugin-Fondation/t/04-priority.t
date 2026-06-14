#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use File::Temp 'tempdir';
use File::Spec;
use FindBin;

# Add lib directories to @INC so plugins can be found
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

# Use test helper for creating apps with temporary home
use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

# Load the Fondation plugin
use_ok 'Mojolicious::Plugin::Fondation';


# Create a temporary directory for config file
my $tempdir = tempdir(CLEANUP => 1);
my $conf_file = File::Spec->catfile($tempdir, 'test.conf');

# Write test configuration with some dependencies
write_config($conf_file);

# Create a test Mojolicious app with temporary home directory
my $app = create_test_app($tempdir);
my $t = Test::Mojo->new($app);

# Load Config plugin with our config file (global config)
$t->app->plugin('Config' => {file => $conf_file});

# Load Fondation plugin with DIRECT configuration (should override global)
$t->app->plugin('Fondation' => {
    dependencies => [
        'Mojolicious::Plugin::Fondation::User',  # Only User in direct config
        # Authorization is NOT in direct config, should not be loaded
    ]
});

# Get the Fondation plugin instance via helper
my $fondation = $t->app->manager;

# Check plugin registry
my $registry = $fondation->registry;
is(ref $registry, 'HASH', 'registry is a hashref');

# Check that Fondation itself is registered
ok(exists $registry->{'Mojolicious::Plugin::Fondation'}, 'Fondation registered');

# Check Fondation dependencies - with array merge, direct + global are combined
my $fondation_entry = $registry->{'Mojolicious::Plugin::Fondation'};
my $fondation_deps = $fondation_entry->{config}{dependencies} // [];
is(ref $fondation_deps, 'ARRAY', 'Fondation dependencies is arrayref');
ok((grep { /User/ } @$fondation_deps), 'User dependency present (from direct config)');
ok((grep { /Authorization/ } @$fondation_deps), 'Authorization dependency present (from global config, merged)');

# Test 2: Plugin-specific configuration priority
# Create another app to test plugin-specific config merging
my $tempdir2 = tempdir(CLEANUP => 1);
my $app2 = create_test_app($tempdir2);
my $t2 = Test::Mojo->new($app2);

# Load Config plugin with config that has plugin-specific settings
$t2->app->plugin('Config' => {file => $conf_file});

# Load Fondation with direct config that includes plugin-specific config for User
$t2->app->plugin('Fondation' => {
    dependencies => [
        {
            'Mojolicious::Plugin::Fondation::User' => { custom_setting => 'from_direct_config' }
        },
        'Mojolicious::Plugin::Fondation::Authorization',
    ]
});

my $fondation2 = $t2->app->manager;
ok($fondation2, 'Fondation plugin loaded and accessible via helper in test 2');
my $registry2 = $fondation2->registry;

# Check that User plugin is registered
ok(exists $registry2->{'Mojolicious::Plugin::Fondation::User'}, 'User plugin registered in second test');

# Check that direct config was passed to User plugin
is($registry2->{'Mojolicious::Plugin::Fondation::User'}{config}{custom_setting}, 'from_direct_config',
   'Direct config for User plugin contains custom_setting');
# Check that Authorization plugin is registered (was in direct config)
ok(exists $registry2->{'Mojolicious::Plugin::Fondation::Authorization'}, 'Authorization plugin registered in second test');
# Check that Role and Permission plugins are registered (dependencies of Authorization)
ok(exists $registry2->{'Mojolicious::Plugin::Fondation::Role'}, 'Role plugin registered via Authorization dependency');
ok(exists $registry2->{'Mojolicious::Plugin::Fondation::Permission'}, 'Permission plugin registered via Authorization dependency');

# Test 3: Direct config for dependency plugin (Authorization) should override global
# Create another app
my $tempdir3 = tempdir(CLEANUP => 1);
my $app3 = create_test_app($tempdir3);
my $t3 = Test::Mojo->new($app3);

# Load Config plugin
$t3->app->plugin('Config' => {file => $conf_file});

# Load Fondation with direct config for Authorization dependencies
$t3->app->plugin('Fondation' => {
    dependencies => [
        'Mojolicious::Plugin::Fondation::User',
        {
            'Mojolicious::Plugin::Fondation::Authorization' => {
                dependencies => [
                    'Mojolicious::Plugin::Fondation::Role',
                    # Permission is NOT in direct config, should not be loaded
                ]
            }
        },
    ]
});

my $fondation3 = $t3->app->manager;
my $registry3 = $fondation3->registry;

# Check Authorization dependencies - with array merge, direct + global are combined
my $auth_entry = $registry3->{'Mojolicious::Plugin::Fondation::Authorization'};
my $auth_deps = $auth_entry->{config}{dependencies} // [];
is(ref $auth_deps, 'ARRAY', 'Authorization dependencies is arrayref');
ok((grep { /Role/ } @$auth_deps), 'Role dependency present (from direct config)');
ok((grep { /Permission/ } @$auth_deps), 'Permission dependency present (from global config, merged)');

# Role should be registered
ok(exists $registry3->{'Mojolicious::Plugin::Fondation::Role'}, 'Role plugin registered');

# Permission should also be registered (merged from global config)
ok(exists $registry3->{'Mojolicious::Plugin::Fondation::Permission'},
   'Permission plugin registered (merged from global config)');

# Test 4: Configuration hierarchy (direct > global > plugin default)
{
    # Helper to write a config file
    my $write_config = sub {
        my ($file, $content) = @_;
        open my $fh, '>', $file or die "Cannot write $file: $!";
        print $fh $content;
        close $fh;
    };

    # Scenario A: Direct config should override everything
    {
        my $tempdir = tempdir(CLEANUP => 1);
        my $conf_file = File::Spec->catfile($tempdir, 'test_hierarchy.conf');
        $write_config->($conf_file, '{}');  # empty config

        my $appA = create_test_app($tempdir);
        my $tA = Test::Mojo->new($appA);
        $tA->app->plugin('Config' => {file => $conf_file});
        $tA->app->plugin('Fondation' => {
            dependencies => [
                { 'Mojolicious::Plugin::Fondation::User' => { key_test => 'direct_config' } }
            ]
        });
        my $fondationA = $tA->app->manager;
        my $registryA = $fondationA->registry;
        is($registryA->{'Mojolicious::Plugin::Fondation::User'}{config}{key_test}, 'direct_config',
           'Direct config should be used when provided');
    }

    # Scenario B: Global config should override plugin default
    {
        my $tempdir = tempdir(CLEANUP => 1);
        my $conf_file = File::Spec->catfile($tempdir, 'test_hierarchy.conf');
        $write_config->($conf_file, <<'CONFIG');
{
 'Fondation' => {
     dependencies => [
         'Fondation::User'
     ]
  },
 'Fondation::User' => {
     key_test => 'global_config'
  }
}
CONFIG

        my $appB = create_test_app($tempdir);
        my $tB = Test::Mojo->new($appB);
        $tB->app->plugin('Config' => {file => $conf_file});
        $tB->app->plugin('Fondation');  # no direct config
        my $fondationB = $tB->app->manager;
        my $registryB = $fondationB->registry;
        is($registryB->{'Mojolicious::Plugin::Fondation::User'}{config}{key_test}, 'global_config',
           'Global config should be used when no direct config');
    }

    # Scenario C: Plugin default should be used when no direct or global config
    {
        my $tempdir = tempdir(CLEANUP => 1);
        my $conf_file = File::Spec->catfile($tempdir, 'test_hierarchy.conf');
        $write_config->($conf_file, <<'CONFIG');
{
 'Fondation' => {
     dependencies => [
         'Fondation::User'
     ]
  }
}
CONFIG

        my $appC = create_test_app($tempdir);
        my $tC = Test::Mojo->new($appC);
        $tC->app->plugin('Config' => {file => $conf_file});
        $tC->app->plugin('Fondation');  # no direct config
        my $fondationC = $tC->app->manager;
        my $registryC = $fondationC->registry;
        is($registryC->{'Mojolicious::Plugin::Fondation::User'}{config}{key_test}, 'plugin_default',
           'Plugin default config should be used when no direct or global config');
    }
}

# Test 5: Partial merge -- direct and global have different keys
# When direct config has key_a and global has key_a + key_b,
# the result should contain both key_a (from direct) and key_b (from global).
{
    my $tempdir = tempdir(CLEANUP => 1);
    my $conf_file = File::Spec->catfile($tempdir, 'test_merge.conf');

    # Global sets both key_test and title
    open my $fh, '>', $conf_file or die "Cannot write $conf_file: $!";
    print $fh <<'CONFIG';
{
 'Fondation' => {
     dependencies => [
         'Fondation::User'
     ]
  },
 'Fondation::User' => {
     key_test => 'from_global',
     title    => 'from_global'
  }
}
CONFIG
    close $fh;

    my $app = create_test_app($tempdir);
    my $t = Test::Mojo->new($app);
    $t->app->plugin('Config' => {file => $conf_file});

    # Direct overrides only key_test, title should come from global
    $t->app->plugin('Fondation' => {
        dependencies => [
            { 'Mojolicious::Plugin::Fondation::User' => { key_test => 'from_direct' } }
        ]
    });

    my $fondation = $t->app->manager;
    my $registry  = $fondation->registry;
    my $user_cfg  = $registry->{'Mojolicious::Plugin::Fondation::User'}{config};

    is($user_cfg->{key_test}, 'from_direct', 'direct overrides global for key_test');
    is($user_cfg->{title},    'from_global', 'global key survives when not in direct config');
}

# Test 6: Empty hashref in direct config should not wipe plugin defaults
{
    my $tempdir = tempdir(CLEANUP => 1);
    my $conf_file = File::Spec->catfile($tempdir, 'test_empty.conf');

    open my $fh, '>', $conf_file or die "Cannot write $conf_file: $!";
    print $fh <<'CONFIG';
{
 'Fondation' => {
     dependencies => [
         'Fondation::User'
     ]
  }
}
CONFIG
    close $fh;

    my $app = create_test_app($tempdir);
    my $t = Test::Mojo->new($app);
    $t->app->plugin('Config' => {file => $conf_file});

    # Direct config is empty hashref -- should NOT overwrite defaults
    $t->app->plugin('Fondation' => {
        dependencies => [
            { 'Mojolicious::Plugin::Fondation::User' => {} }
        ]
    });

    my $fondation = $t->app->manager;
    my $registry  = $fondation->registry;
    my $user_cfg  = $registry->{'Mojolicious::Plugin::Fondation::User'}{config};

    is($user_cfg->{key_test}, 'plugin_default',   'empty direct hash keeps plugin default for key_test');
    is($user_cfg->{title},    'User Management',   'empty direct hash keeps plugin default for title');
}

# Test 7: Transitive dependencies via fondation_meta (no explicit listing)
# Authorization's fondation_meta declares Role + Permission as dependencies.
# Loading Authorization should auto-load both, even when they are not mentioned
# anywhere in direct config or global config.
{
    my $tempdir = tempdir(CLEANUP => 1);
    my $conf_file = File::Spec->catfile($tempdir, 'test_transitive.conf');

    open my $fh, '>', $conf_file or die "Cannot write $conf_file: $!";
    print $fh <<'CONFIG';
{
 'Fondation' => {
     dependencies => [
         'Fondation::Authorization'
     ]
  }
}
CONFIG
    close $fh;

    my $app = create_test_app($tempdir);
    my $t = Test::Mojo->new($app);
    $t->app->plugin('Config' => {file => $conf_file});
    $t->app->plugin('Fondation');  # no direct config -- relies on global

    my $fondation = $t->app->manager;
    my $registry  = $fondation->registry;

    ok(exists $registry->{'Mojolicious::Plugin::Fondation::Authorization'},
       'Authorization loaded from global config');
    ok(exists $registry->{'Mojolicious::Plugin::Fondation::Role'},
       'Role auto-loaded via Authorization fondation_meta');
    ok(exists $registry->{'Mojolicious::Plugin::Fondation::Permission'},
       'Permission auto-loaded via Authorization fondation_meta');

    # Verify the load order: deps before dependant
    my $auth_idx = _index_of($fondation->load_order, 'Mojolicious::Plugin::Fondation::Authorization');
    my $role_idx = _index_of($fondation->load_order, 'Mojolicious::Plugin::Fondation::Role');
    my $perm_idx = _index_of($fondation->load_order, 'Mojolicious::Plugin::Fondation::Permission');

    ok($role_idx < $auth_idx, 'Role loaded before Authorization');
    ok($perm_idx < $auth_idx, 'Permission loaded before Authorization');
}

done_testing();

sub _index_of {
    my ($array, $value) = @_;
    for my $i (0 .. $#$array) {
        return $i if $array->[$i] eq $value;
    }
    return -1;
}

sub write_config {
    my ($file) = @_;
    open my $fh, '>', $file or die "Cannot write $file: $!";
    print $fh <<'CONFIG';
{
 'Fondation' => {
     dependencies => [
         'Fondation::User',
         'Fondation::Authorization',
    ]
  },
 'Fondation::Authorization' => {
     dependencies => [
         'Fondation::Role',
         'Fondation::Permission',
    ]
  },
 'Fondation::User' => {
     # No dependencies for User
  },
 'Fondation::Role' => {
     # No dependencies for Role
  },
 'Fondation::Permission' => {
     # No dependencies for Permission
  }
}
CONFIG
    close $fh;
}
