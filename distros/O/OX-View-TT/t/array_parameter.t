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
            Path::Class::dir($FindBin::Bin)->subdir('data', 'array_parameter', 'templates')->stringify
        },
    );

    has 'template_params' => (
        is    => 'ro',
        block => sub {
            my $s = shift;
            return {
                some_scalar => 'scalar',
                some_array => ['one', 'two'],
                other_array => ['four', 'five'],
            };
        },
    );

    has view => (
        is           => 'ro',
        isa          => 'OX::View::TT',
        dependencies => ['template_root', 'template_params'],
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
            is($res->content, "<b>Hello world</b>\n<p>scalar</p>\n\n<span>one</span>\n\n<span>two</span>\n\n\n<span>four</span>\n\n<span>five</span>\n\n", "array parameter was passed");
        }
    };

done_testing;
