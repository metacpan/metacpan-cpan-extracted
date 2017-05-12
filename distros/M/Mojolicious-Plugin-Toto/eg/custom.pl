#!/usr/bin/env perl

package House;
use Mojo::Base 'Mojolicious::Controller';

sub list {
    shift->render_text("in the house");
}

package main;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

app->routes->namespaces(['main']);

my $menu = [
    city => {
        many => [qw/search browse/],
        one  => [qw/ingredients/],
    },
    house => {
        many => [qw/list/],
        one  => [qw/pictures address color/],
    }
];

get '/some/crazy/url' => sub { shift->render_text("hi there"); } => { nav_item => 'city' } => "city/search";

get '/city/browse' => sub { shift->render_text("my name is inigo montoya") } =>{ nav_item => 'city' } =>  "city/browse";

get '/house/list' => { controller => 'house', action => 'list', nav_item => 'house' } => 'house/list';

plugin 'toto' => menu => $menu;

app->start;

__DATA__
@@ not_found.html.ep
% layout 'default';
NOT FOUND : <%= $self->req->url->path %>

