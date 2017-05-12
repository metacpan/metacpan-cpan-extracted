#!/usr/bin/env perl -w
use strict;
use Cwd;
use Moose ();

BEGIN {
    my $cwd = getcwd;
    unshift @INC, "$cwd/t/lib";
    unshift @INC, "$cwd/t/SimpleApp/lib";
}
use Test::More tests => 1;
use Railsish::Dispatcher;
use Railsish::Bootstrap;
use HTTP::Engine;
use HTTP::Request;

chdir("t/SimpleApp");
use lib '../../lib';

$ENV{APP_ROOT} = getcwd;

Railsish::Bootstrap->load_configs;
Railsish::Bootstrap->load_controllers;

my $engine = HTTP::Engine->new(
    interface => {
	module => 'Test',
	request_handler => sub {
            Railsish::Dispatcher->dispatch(@_)
        }
    }
);

my $response = $engine->run(
    HTTP::Request->new(GET => 'http://localhost/welcome/here'),
    env => \%ENV,
    connection_info => {
	request_uri => "/welcome/here"
    }
);

like $response->content, qr{<p>The answer is 42</p>};
