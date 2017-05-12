#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 16;

do {
    package MyApp::Dispatcher;
    use Path::Dispatcher::Declarative -base;

    on qr/(b)(ar)(.*)/ => sub { die "do not call blocks!" };
    on ['token', 'matching'] => sub { die "do not call blocks!" };

    rewrite quux => 'bar';
    rewrite qr/^quux-(.*)/ => sub { "bar:$1" };

    on alpha => sub { die "do not call blocks!" };

    under alpha => sub {
        then { die "do not call blocks!" };
        on one => sub { die "do not call blocks!" };
        then { die "do not call blocks!" };
        on two => sub { die "do not call blocks!" };
        on three => sub { die "do not call blocks!" };
    };

    under beta => sub {
        on a => sub { die "do not call blocks!" };
        on b => sub { die "do not call blocks!" };
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

complete_ok('x');

complete_ok(q => 'quux');

complete_ok(a => 'alpha');
complete_ok(alpha => 'alpha one', 'alpha two', 'alpha three');

complete_ok(t => 'token');
complete_ok(token => 'token matching');
complete_ok('token m' => 'token matching');
complete_ok('token matchin' => 'token matching');
complete_ok('token matching');

complete_ok(bet => 'beta');
complete_ok(beta => 'beta a', 'beta b');
complete_ok('beta a');
complete_ok('beta b');
complete_ok('beta c');

TODO: {
    local $TODO = "cannot complete regex rules (yet!)";
    complete_ok(quux => 'quux-');
    complete_ok(b => 'bar', 'beta');
};

