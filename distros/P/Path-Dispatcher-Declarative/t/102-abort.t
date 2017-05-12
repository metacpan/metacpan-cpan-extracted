#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

my @calls;

do {
    package MyFramework::Dispatcher;
    use Path::Dispatcher::Declarative -base;
    on qr/abort/ => sub {
        push @calls, 'framework on abort';
    };

    on qr/next rule/ => sub {
        push @calls, 'framework before next_rule';
        next_rule;
        push @calls, 'framework after next_rule';
    };

    on qr/next rule/ => sub {
        push @calls, 'framework before next_rule 2';
        next_rule;
        push @calls, 'framework after next_rule 2';
    };

    package MyApp::Dispatcher;
    # this hack is here because "use" expects there to be a file for the module
    BEGIN { MyFramework::Dispatcher->import("-base") }

    on qr/next rule/ => sub {
        push @calls, 'app before next_rule';
        next_rule;
        push @calls, 'app after next_rule';
    };

    on qr/next rule/ => sub {
        push @calls, 'app before next_rule 2';
        next_rule;
        push @calls, 'app after next_rule 2';
    };

    redispatch_to('MyFramework::Dispatcher');
};

MyApp::Dispatcher->run('abort');
is_deeply([splice @calls], [
    'framework on abort',
]);

MyApp::Dispatcher->run('next rule');
is_deeply([splice @calls], [
    'app before next_rule',
    'app before next_rule 2',
    'framework before next_rule',
    'framework before next_rule 2',
]);

