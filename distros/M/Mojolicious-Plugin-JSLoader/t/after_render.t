#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::JSLoader';

## Webapp START

plugin('JSLoader');

any '/'      => sub { shift->render( json => { success => 1 } ) };
any '/hello' => sub {
    my $self = shift;

    $self->js_load( 'second_file.js' );
    $self->render( 'default' );
};

## Webapp END

my $t = Test::Mojo->new;

$t->get_ok( '/' )->status_is( 200 )->content_is( '{"success":1}' );

{
    my $c = $t->app->build_controller;
    $c->stash->{__JSLOADERFILES__} = {};
    my $string = $c->render( 'default' );
    is $string, 1;
}

{
    my $c = $t->app->build_controller;
    $c->stash->{__JSLOADERFILES__} = [];
    my $string = $c->render( 'default' );
    is $string, 1;
}

{
    my $c = $t->app->build_controller;
    $c->stash->{__JSLOADERFILES__} = [[]];
    my $string = $c->render( 'default' );
    is $string, 1;
}

done_testing();

__DATA__
@@ default.html.ep
test
