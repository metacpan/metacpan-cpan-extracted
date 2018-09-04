#!/usr/bin/env perl
use strictures 2;

use Test2::V0;
use Test::Starch;
use Starch;

{
    package MyPlugin::Manager;
    use Moo::Role;
    with 'Starch::Plugin::ForManager';
    sub my_manager_plugin { 1 }
}

{
    package MyPlugin::State;
    use Moo::Role;
    with 'Starch::Plugin::ForState';
    sub my_state_plugin { 1 }
}

{
    package MyPlugin::Store;
    use Moo::Role;
    with 'Starch::Plugin::ForStore';
    sub my_store_plugin { 1 }
}

{
    package MyPlugin;
    use Moo;
    with 'Starch::Plugin::Bundle';
    sub bundled_plugins {
        ['MyPlugin::Manager', 'MyPlugin::State', 'MyPlugin::Store'];
    }
}

Test::Starch->new(
    plugins => ['MyPlugin'],
)->test();

subtest bundle => sub{
    my $starch = Starch->new(
        plugins => ['MyPlugin'],
        store => { class => '::Memory' },
    );

    can_ok( $starch, 'my_manager_plugin' );
    can_ok( $starch->state(), 'my_state_plugin' );
    can_ok( $starch->store(), 'my_store_plugin' );
};

subtest individual => sub{
    my $starch = Starch->new(
        plugins => ['MyPlugin::Manager', 'MyPlugin::Store'],
        store => { class => '::Memory' },
    );

    can_ok( $starch, 'my_manager_plugin' );
    can_ok( $starch->store(), 'my_store_plugin' );

    ok(
        (!$starch->state->can('my_state_plugin')),
        '!' . $starch->factory->state_class() . q[->can('my_state_plugin')],
    );
};

done_testing;
