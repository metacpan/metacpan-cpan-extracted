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
# provides_actions -- action discovery
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Action discovered via provides_actions in fondation_meta' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    $app->plugin('Fondation' => {
        dependencies => ['Fondation::CustomAction']
    });

    my $manager = $app->manager;
    my @actions = @{$manager->action_classes};

    ok((grep { /MyAction$/ } @actions), 'MyAction is in action_classes');
};

subtest 'Custom action class resolved to plugin namespace' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    $app->plugin('Fondation' => {
        dependencies => ['Fondation::CustomAction']
    });

    my $manager = $app->manager;
    my ($my_action) = grep { /MyAction$/ } @{$manager->action_classes};

    is($my_action,
       'Mojolicious::Plugin::Fondation::CustomAction::Action::MyAction',
       'MyAction resolved to plugin namespace, not core');
};

# ═══════════════════════════════════════════════════════════════════════════
# Action execution
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Custom action executed for each loaded plugin' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    $app->plugin('Fondation' => {
        dependencies => [
            'Fondation::CustomAction',
            'Fondation::User',
        ]
    });

    my $manager = $app->manager;
    my $calls = $manager->{_my_action_calls} || [];

    # Should be called for each plugin in load order:
    # CustomAction (itself), User (listed dep)
    cmp_ok(@$calls, '>=', 2, 'MyAction called for at least 2 plugins');

    my @long_names = map { $_->{long_name} } @$calls;
    ok((grep { /CustomAction$/ } @long_names),
       'MyAction called for CustomAction plugin');
    ok((grep { /User$/ } @long_names),
       'MyAction called for User plugin');
};

subtest 'Actions run in order: core actions before custom actions' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    # No explicit 'actions' → defaults: ['Templates', 'Controllers']
    # + CustomAction provides MyAction
    $app->plugin('Fondation' => {
        dependencies => ['Fondation::CustomAction']
    });

    my $manager = $app->manager;
    my @actions = @{$manager->action_classes};

    # Templates and Controllers are defaults, MyAction is auto-added after
    my $tmpl_idx  = _index_of_str(\@actions, 'Mojolicious::Plugin::Fondation::Action::Templates');
    my $ctrl_idx  = _index_of_str(\@actions, 'Mojolicious::Plugin::Fondation::Action::Controllers');
    my $myact_idx = _index_of_str(\@actions,
        'Mojolicious::Plugin::Fondation::CustomAction::Action::MyAction');

    cmp_ok($tmpl_idx, '<', $myact_idx,
        'Templates action comes before MyAction');
    cmp_ok($ctrl_idx, '<', $myact_idx,
        'Controllers action comes before MyAction');
};

# ═══════════════════════════════════════════════════════════════════════════
# Action with explicit config override
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Custom action respects explicit actions list' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    # Explicitly only Templates + MyAction → Controllers excluded
    $app->plugin('Fondation' => {
        actions      => ['Templates', 'MyAction'],
        dependencies => ['Fondation::CustomAction']
    });

    my $manager = $app->manager;
    my @actions = @{$manager->action_classes};

    ok((grep { /MyAction$/ } @actions), 'MyAction present when explicit');
    ok(!(grep { /Controllers$/ } @actions),
       'Controllers absent when not in explicit list');
};

# ═══════════════════════════════════════════════════════════════════════════
# Action resolution fallback (no provides_actions)
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Action without provides_actions resolves to core namespace' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    # Templates is NOT in any provides_actions → core fallback
    $app->plugin('Fondation' => {
        actions => ['Templates'],
    });

    my $manager = $app->manager;
    my ($templates) = grep { /Templates$/ } @{$manager->action_classes};

    is($templates,
       'Mojolicious::Plugin::Fondation::Action::Templates',
       'Templates resolves to core namespace (no provides_actions)');
};

done_testing();

sub _index_of_str {
    my ($array, $value) = @_;
    for my $i (0 .. $#$array) {
        return $i if $array->[$i] eq $value;
    }
    return -1;
}
