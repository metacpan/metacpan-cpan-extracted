#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use_ok 'Mojolicious::Plugin::BootstrapAlerts';

plugin('BootstrapAlerts', { dismissable => 1 });

my $t   = Test::Mojo->new;
my $c = $t->app->build_controller;

my $check = q~
                <div class="alert alert-dismissable alert-danger">
                    <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
                    test
                </div>
            ~;

{
    $c->stash( '__NOTIFICATIONS__', [] );
    $c->notify( 'error', 'test' );
    my $output = $c->notifications;
    is $output, $check;
    like $output, qr/data-dismiss/;
}

{
    $c->stash( '__NOTIFICATIONS__', [] );
    $c->notify( 'error', 'test', {} );
    my $output = $c->notifications;
    is $output, $check;
    like $output, qr/data-dismiss/;
}

{
    $c->stash( '__NOTIFICATIONS__', [] );
    $c->notify( 'error', 'test', [] );
    my $output = $c->notifications;
    is $output, $check;
    like $output, qr/data-dismiss/;
}

{
    $c->stash( '__NOTIFICATIONS__', [] );
    $c->notify( 'error', 'test', {dismissable => 1} );
    my $output = $c->notifications;
    is $output, $check;
    like $output, qr/data-dismiss/;
}

done_testing();

