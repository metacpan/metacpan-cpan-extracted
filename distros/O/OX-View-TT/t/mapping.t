#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;
use FindBin;

use HTTP::Request::Common;
use Path::Class ();

{
    package Foo::Controller;
    use Moose;

    has view => (
        is       => 'ro',
        isa      => 'OX::View::TT',
        required => 1,
        handles  => ['render'],
    );

    sub index {
        my $self = shift;
        my ($r) = @_;
        $self->render($r, 'index.tt');
    }
}

{
    package Foo;
    use OX;

    has template_root => (
        is    => 'ro',
        isa   => 'Str',
        block => sub {
            Path::Class::dir($FindBin::Bin)->subdir('data', 'mapping', 'templates')->stringify
        },
    );

    has view => (
        is           => 'ro',
        isa          => 'OX::View::TT',
        dependencies => ['template_root'],
    );

    has root => (
        is           => 'ro',
        isa          => 'Foo::Controller',
        dependencies => ['view'],
    );

    router as {
        route '/' => 'root.index', (
            foo => 'FOO',
            bar => 'BAR',
        );
    };
}

test_psgi
    app => Foo->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET 'http://localhost/');
            is($res->content, "<b>FOO BAR</b>\n", "right content");
        }
    };

done_testing;
