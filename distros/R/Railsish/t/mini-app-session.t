#!/usr/bin/env perl -w
use strict;
use warnings;
use Moose ();
use Test::More tests => 4;

package FooController;
use Railsish::Controller;

sub index {
    if (session->{counter}) {
        session->{counter} = session->{counter} + 1;
    }
    else {
        session->{counter} = 1;
    }
    response->body("Hi from Foo: " . session->{counter});
}

package main;
use Railsish::Router;
use Railsish::Dispatcher;
use HTTP::Engine;
use HTTP::Request;
use HTTP::Headers;
use HTTP::Cookies;
use CGI::Cookie;

Railsish::Router->draw(
    sub {
        my ($map) = @_;
        $map->connect("/:controller/:action/:id");
        $map->connect("/:controller/:action");
        $map->connect("/:controller", action => 'index');
        $map->connect("", controller => "foo");
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

my $response = $engine->run(
    HTTP::Request->new(GET => "http://localhost/"),
    connection_info => { request_uri => "/" }
);
is($response->content, "Hi from Foo: 1");
# diag $response->content;
ok($response->header("Set-Cookie"));
# diag($response->header("Set-Cookie"));

use YAML;

my $cookies = $response->header("Set-Cookie");

# diag(Dump($cookies));

my $request = HTTP::Request->new(GET => "http://localhost/");
$request->header(Cookie => $cookies);

$response = $engine->run(
    $request,
    connection_info => {
        request_uri => "/"
    }
);

is($response->content, "Hi from Foo: 2");
# diag $response->content;

ok($response->header("Set-Cookie"));
# diag($response->header("Set-Cookie"));
