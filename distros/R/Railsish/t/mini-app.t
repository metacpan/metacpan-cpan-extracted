#!/usr/bin/env perl -w
use strict;
use warnings;
use Moose ();
use Test::More tests => 1;;

package FooController;
use Railsish::Controller;
use Test::More;

sub bar {
    response->body( params("id") );
}

package main;
use Railsish::Router;

Railsish::Router->draw(
    sub {
        my ($map) = @_;
        $map->connect("/:controller/:action/:id");
        $map->connect("/:controller/:action");
        $map->connect("/:controller", action => 'index');
        $map->connect("", controller => "foo");
    }
);

use Railsish::Dispatcher;

use HTTP::Engine;
use HTTP::Request;

my $response = HTTP::Engine->new(
    interface => {
        module => "Test",
        request_handler => sub {
            Railsish::Dispatcher->dispatch(@_);
        }
    }
)->run(
    HTTP::Request->new(GET => "http://localhost/foo/bar/baz"),
    connection_info => { request_uri => "/foo/bar/baz" }
);

# The returned $response is a HTTP::Response object
is($response->content, "baz");
