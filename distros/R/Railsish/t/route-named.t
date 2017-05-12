#!/usr/bin/env perl -w
use strict;
use Test::More tests => 7;

use Railsish::Router;
use Railsish::PathHelpers;

Railsish::Router->draw(
    sub {
        my ($map) = @_;

        $map->login("/login", controller => "login");
        $map->user("/users/:id", controller => "users", action => "show");
    }
);

is(Railsish::Router->login_path, "/login", "urlish with variables");
is(Railsish::Router->user_path(id => 3), "/users/3", "urlish with variables");
is(Railsish::Router->uri_for(controller => "users", action => "show", id => 3), "/users/3", "retrivie the uri with using names");

Railsish::PathHelpers->install_helpers(__PACKAGE__);

is(login_path(), "/login", "as helper");
is(user_path(id => 3), "/users/3", "as helper");

my $helpers = Railsish::PathHelpers->hash_for_helpers;
is( ref($helpers->{login_path}), "CODE", 'retrieved helpers as a hash' );
is( ref($helpers->{user_path}), "CODE", 'retrieved heplers as a hash' );


