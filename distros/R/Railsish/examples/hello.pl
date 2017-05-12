#!/usr/bin/env perl -w

use strict;

package HelloController;
our $VERSION = '0.21';

use Railsish::Controller;

sub index {
    my $id = params("id");

    my $text = "Hello";
    if ($id) {
        $text .= ", $id";
    }
    
    response->body($text);
}

package main;
our $VERSION = '0.21';


use Railsish::Router;

Railsish::Router->draw(
    sub {
        my ($map) = @_;

        $map->connect("", controller => "hello");
        $map->connect("/:id", controller => "hello", action => 'index');

        $map->connect("/:controller/:action");
        $map->connect("/:controller/:action/:id");
    }
);

use Railsish::Dispatcher;
use HTTP::Engine;
my $engine = HTTP::Engine->new(
    interface => {
        module => 'ServerSimple',
        args   => {
            host => 'localhost',
            port =>  3000,
        },
        request_handler => sub {
            my ($request) = @_;
            warn $request->method . " " . $request->path . "\n";

            return Railsish::Dispatcher->dispatch($request);
        }
    }
);

print <<M;

Hi, I am an hello server that responds to the following request paths:

    /hello/index/\$id
    /hello/\$id
    /\$id
    /

\$id can also be passed as a query parameter named "id":

    /hello/index/?id=\$id
    /?id=\$id

M

$engine->run;
