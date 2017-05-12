#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

my @calls;

do {
    package MyApp::Dispatcher;
    use Path::Dispatcher::Declarative -base;

    under first => sub {
        on qr/./ => sub {
            push @calls, "[$_] first -> regex";
            next_rule;
        };

        on second => sub {
            push @calls, "[$_] first -> string, via next_rule";
        };
    };
};

TODO: {
    local $TODO = "under doesn't pass its matched fragment as part of the path";
    MyApp::Dispatcher->run("first second");
    is_deeply([splice @calls], [
        "[first second] first -> regex",
        "[first second] first -> string, via next_rule",
    ]);
}

