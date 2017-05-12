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

    our $AUTOLOAD;
    sub AUTOLOAD {
        my $self = shift;
        my ($r) = @_;
        (my $template = $AUTOLOAD) =~ s/.*:://;
        $template .= '.tt';
        $self->render($r, $template, $r->mapping);
    }
    sub can { 1 }
}

{
    package Foo;
    use OX;

    has template_root => (
        is    => 'ro',
        isa   => 'Str',
        block => sub {
            Path::Class::dir($FindBin::Bin)->subdir('data', 'basic', 'templates')->stringify
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
            content => 'Hello world',
        );
        route '/foo' => 'root.foo';
    };
}

my $foo = Foo->new;
my $view = $foo->view;
isa_ok($view, 'OX::View::TT');
isa_ok($view->tt, 'Template');

test_psgi
    app => $foo->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET 'http://localhost/');
            is($res->code, 200, "right code");
            is($res->content, "<b>Hello world</b>\n", "right content");
        }
        {
            my $res = $cb->(GET 'http://localhost/foo');
            is($res->code, 200, "right code");
            is($res->content, "<p>/foo</p>\n", "right content");
        }
    };

done_testing;
