#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

my @calls;

do {
    package MyFramework::Dispatcher;
    use Path::Dispatcher::Declarative -base;

    on qr/a(rg)s/ => sub {
        push @calls, {
            from => "framework",
            args => [@_],
            it   => $_,
            one  => $1,
            two  => $2,
        };
    };

    package MyApp::Dispatcher;
    # this hack is here because "use" expects there to be a file for the module
    BEGIN { MyFramework::Dispatcher->import("-base") }

    on qr/ar(g)s/ => sub {
        push @calls, {
            from => "app",
            args => [@_],
            it   => $_,
            one  => $1,
            two  => $2,
        };
        next_rule;
    };

    redispatch_to(MyFramework::Dispatcher->dispatcher);
};

MyApp::Dispatcher->run('args', 1..3);
is_deeply([splice @calls], [
    {
        from => 'app',
        one  => 'g',
        two  => undef,
        it   => 'args',
        args => [1, 2, 3],
    },
    {
        from => 'framework',
        one  => 'rg',
        two  => undef,
        it   => 'args',
        args => [1, 2, 3],
    },
]);

