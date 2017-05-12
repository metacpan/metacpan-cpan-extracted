#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

my @calls;

do {
    package MyApp::Dispatcher;
    use Path::Dispatcher::Declarative -base;

    on { method => 'GET' } => sub {
        push @calls, "method: GET, path: $_";
    };
};

my $path = Path::Dispatcher::Path->new(
    path     => "/REST/Ticket/1.yml",
    metadata => {
        method => "GET",
        query_parameters => {
            owner => 'Sartak',
            status => 'closed',
        },
    },
);

MyApp::Dispatcher->run($path);
is_deeply([splice @calls], ["method: GET, path: /REST/Ticket/1.yml"]);

do {
    package MyApp::Other::Dispatcher;
    use Path::Dispatcher::Declarative -base;

    on {
        query_parameters => {
            owner => qr/^\w+$/,
        },
    } => sub {
        push @calls, "query_parameters/owner/regex";
    };
};

TODO: {
    local $TODO = "metadata can't be a deep data structure";

    eval {
        MyApp::Other::Dispatcher->run($path);
    };
    is_deeply([splice @calls], ["query_parameters/owner/regex"]);
};

