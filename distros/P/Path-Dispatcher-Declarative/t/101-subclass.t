#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

my @calls;

do {
    package MyFramework::Dispatcher;
    use Path::Dispatcher::Declarative -base;

    on 'quit' => sub { push @calls, 'framework: quit' };

    package MyApp::Dispatcher;
    # this hack is here because "use" expects there to be a file for the module
    BEGIN { MyFramework::Dispatcher->import("-base") }

    on qr/.*/ => sub {
        push @calls, 'app: first .*';
        next_rule;
    };

    redispatch_to('MyFramework::Dispatcher');

    on qr/.*/ => sub {
        push @calls, 'app: second .*';
        next_rule;
    };
};

MyApp::Dispatcher->run("quit");
is_deeply([splice @calls], [
    'app: first .*',
    'framework: quit',
]);

MyApp::Dispatcher->run("other");
is_deeply([splice @calls], [
    'app: first .*',
    'app: second .*',
]);

