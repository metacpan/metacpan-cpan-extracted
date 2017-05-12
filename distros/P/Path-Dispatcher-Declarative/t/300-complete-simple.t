#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 16;
use Path::Dispatcher;

my $complete = Path::Dispatcher::Rule::Eq->new(string => "complete");
is_deeply([$complete->complete(Path::Dispatcher::Path->new('x'))], []);
is_deeply([$complete->complete(Path::Dispatcher::Path->new('completexxx'))], []);
is_deeply([$complete->complete(Path::Dispatcher::Path->new('cxxx'))], []);

is_deeply([$complete->complete(Path::Dispatcher::Path->new('c'))], ['complete']);
is_deeply([$complete->complete(Path::Dispatcher::Path->new('compl'))], ['complete']);
is_deeply([$complete->complete(Path::Dispatcher::Path->new('complete'))], []);

do {
    package MyApp::Dispatcher;
    use Path::Dispatcher::Declarative -base;

    on foo => sub { die "do not call blocks!" };
    on bar => sub { die "do not call blocks!" };
    on baz => sub { die "do not call blocks!" };
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

complete_ok('x');
complete_ok('foooo');
complete_ok('baq');

complete_ok(f  => 'foo');
complete_ok(fo => 'foo');
complete_ok('foo');

complete_ok('b'  => 'bar', 'baz');
complete_ok('ba' => 'bar', 'baz');
complete_ok('bar');
complete_ok('baz');

