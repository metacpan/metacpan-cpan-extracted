#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 11;

my @calls;

do {
    package MyApp::Dispatcher;
    use Path::Dispatcher::Declarative -base;

    on qr/(b)(ar)(.*)/ => sub {
        push @calls, [$1, $2, $3];
    };

    on ['token', 'matching'] => sub {
        push @calls, [$1, $2];
    };

    rewrite quux => 'bar';
    rewrite qr/^quux-(.*)/ => sub { "bar:$1" };

    on alpha => sub {
        push @calls, "alpha"
    };

    under alpha => sub {
        then {
            push @calls, "alpha (chain) ";
        };
        on one => sub {
            push @calls, "one";
        };

        then {
            push @calls, "(before two or three) ";
        };
        on two => sub {
            push @calls, "two";
        };
        on three => sub {
            push @calls, "three";
        };
    };
};

ok(MyApp::Dispatcher->isa('Path::Dispatcher::Declarative'), "use Path::Dispatcher::Declarative sets up ISA");

can_ok('MyApp::Dispatcher' => qw/dispatcher dispatch run/);
MyApp::Dispatcher->run('foobarbaz');
is_deeply([splice @calls], [
    [ 'b', 'ar', 'baz' ],
]);

MyApp::Dispatcher->run('quux');
is_deeply([splice @calls], [
    [ 'b', 'ar', '' ],
]);

MyApp::Dispatcher->run('quux-hello');
is_deeply([splice @calls], [
    [ 'b', 'ar', ':hello' ],
]);

MyApp::Dispatcher->run('token matching');
is_deeply([splice @calls], [
    [ 'token', 'matching' ],
]);

MyApp::Dispatcher->run('Token Matching');
is_deeply([splice @calls], [], "token matching is by default case sensitive");

MyApp::Dispatcher->run('alpha');
is_deeply([splice @calls], ['alpha']);

MyApp::Dispatcher->run('alpha one');
is_deeply([splice @calls], ['alpha (chain) ', 'one']);

MyApp::Dispatcher->run('alpha two');
is_deeply([splice @calls], ['alpha (chain) ', '(before two or three) ', 'two']);

MyApp::Dispatcher->run('alpha three');
is_deeply([splice @calls], ['alpha (chain) ', '(before two or three) ', 'three']);
