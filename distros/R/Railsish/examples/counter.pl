#!/usr/bin/env perl -w
use strict;
use warnings;

package CounterController;
our $VERSION = '0.21';

use Railsish::Controller;

sub index {
    if (session->{counter}) {
        session->{counter} = session->{counter} + 1;
    }
    else {
        session->{counter} = 1;
    }
    response->body("Counting: " . session->{counter});
}

package main;
our $VERSION = '0.21';

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
        $map->connect("", controller => "counter");
    }
);

my $engine = HTTP::Engine->new(
    interface => {
        module => "ServerSimple",
        args   => {
            host => 'localhost',
            port =>  3000,
        },
        request_handler => sub {
            Railsish::Dispatcher->dispatch(@_);
        }
    }
);

$engine->run;
