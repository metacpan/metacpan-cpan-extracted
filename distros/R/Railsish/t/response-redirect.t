#!/usr/bin/env perl

use strict;
use warnings;
use Moose ();
use Test::More tests => 4;

package FooController;
use Railsish::Controller;

sub bar {
    response->body("bar");
}

sub baz {
    redirect_to("/foo/bar");
}

sub bax {
    redirect_to(action => "bar")
}

package main;
use Railsish::Router;
use Railsish::Dispatcher;
use HTTP::Engine;
use HTTP::Request;

Railsish::Router->draw(
    sub {
        my ($map) = @_;
        $map->connect("/:controller/:action");
    }
);


my $engine = HTTP::Engine->new(
    interface => {
        module => "Test",
        request_handler => sub {
            Railsish::Dispatcher->dispatch(@_);
        }
    }
);

{
    my $response = $engine->run(
        HTTP::Request->new(GET => "http://localhost/foo/baz"),
        connection_info => { request_uri => "/foo/baz" }
    );
    ok($response->is_redirect);
    is($response->header("Location"), "/foo/bar");
}

{
    my $response = $engine->run(
        HTTP::Request->new(GET => "http://localhost/foo/bax"),
        connection_info => { request_uri => "/foo/bax" }
    );
    ok($response->is_redirect);
    is($response->header("Location"), "/foo/bar");
}

