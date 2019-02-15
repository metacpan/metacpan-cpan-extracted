#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use_ok 'Mojolicious::Plugin::BootstrapAlerts';

plugin('BootstrapAlerts');

my $t   = Test::Mojo->new;
my $c = $t->app->build_controller;

{
    $c->stash( '__NOTIFICATIONS__', [] );
    $c->notify( 'error', {message => 'test'} );
    my $output = $c->notifications;
    like $output, qr/HASH\(0x/;
}

{
    $c->stash( '__NOTIFICATIONS__', [] );
    $c->notify( 'error', $t, {} );
    my $output = $c->notifications;
    like $output, qr/HASH\(0x/;
}

done_testing();

