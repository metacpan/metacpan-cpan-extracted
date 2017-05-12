#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 20;

do {
    package MyApp::Dispatcher;
    use Path::Dispatcher::Declarative -base;

    under gate => sub {
        on enum('foo', 'bar', 'baz') => sub { die };
        on quux => sub { die };
    };
};

my $dispatcher = MyApp::Dispatcher->dispatcher;

sub complete_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $path     = shift;
    my @expected = @_;

    my @got = $dispatcher->complete($path);

    my $message = @expected == 0 ? "no completions"
                : @expected == 1 ? "one completion"
                :                  @expected . " completions";
    $message .= " for path '$path'";

    is_deeply(\@got, \@expected, $message);
}

complete_ok('z');
complete_ok('gate z');
complete_ok('zig ');
complete_ok('zig f');
complete_ok('zig fo');
complete_ok('zig foo');

complete_ok(g   => 'gate');
complete_ok(ga  => 'gate');
complete_ok(gat => 'gate');

complete_ok(gate    => 'gate foo', 'gate bar', 'gate baz', 'gate quux');
complete_ok('gate ' => 'gate foo', 'gate bar', 'gate baz', 'gate quux');

complete_ok('gate f' => 'gate foo');

complete_ok('gate b'  => 'gate bar', 'gate baz');
complete_ok('gate ba' => 'gate bar', 'gate baz');

complete_ok('gate q'   => 'gate quux');
complete_ok('gate quu' => 'gate quux');

complete_ok('gate foo');
complete_ok('gate bar');
complete_ok('gate baz');
complete_ok('gate quux');

