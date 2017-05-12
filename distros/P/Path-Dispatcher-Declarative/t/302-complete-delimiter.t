#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 18;

do {
    package MyApp::Dispatcher;
    use Path::Dispatcher::Declarative -base, -default => {
        token_delimiter => '/',
    };

    on ['token', 'matching'] => sub { die "do not call blocks!" };

    under alpha => sub {
        on one => sub { die "do not call blocks!" };
        on two => sub { die "do not call blocks!" };
        on three => sub { die "do not call blocks!" };
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

complete_ok(t => 'token');
complete_ok(toke => 'token');
complete_ok('token' => 'token/matching');
complete_ok('token/' => 'token/matching');
complete_ok('token/m' => 'token/matching');
complete_ok('token/matchin' => 'token/matching');
complete_ok('token/matching');
complete_ok('token/x');
complete_ok('token/mx');

complete_ok(a => 'alpha');
complete_ok(alph => 'alpha');
complete_ok(alpha => 'alpha/one', 'alpha/two', 'alpha/three');
complete_ok('alpha/' => 'alpha/one', 'alpha/two', 'alpha/three');
complete_ok('alpha/o' => 'alpha/one');
complete_ok('alpha/t' => 'alpha/two', 'alpha/three');
complete_ok('alpha/tw' => 'alpha/two');
complete_ok('alpha/th' => 'alpha/three');
complete_ok('alpha/x');

