#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More tests => 2;
use Moose ();

package SomeController;
use Railsish::Controller;
use Test::More;

sub stuff {
    my %params = %{params()};
    is( $params{controller}, "some" );
    is( $params{action}, "stuff" );
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

my $response = $engine->run(
    HTTP::Request->new(GET => "/some/stuff"),
    connection_info => {
        request_uri => "/some/stuff"
    }
);

