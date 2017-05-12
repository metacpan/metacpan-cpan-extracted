#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

my @calls;

do {
    package MyApp::Dispatcher;
    use Path::Dispatcher::Declarative -base;

    on '' => sub {
        push @calls, "empty: $_";
    };
};

MyApp::Dispatcher->run("foo");
is_deeply([splice @calls], []);

MyApp::Dispatcher->run("");
is_deeply([splice @calls], ["empty: "]);

