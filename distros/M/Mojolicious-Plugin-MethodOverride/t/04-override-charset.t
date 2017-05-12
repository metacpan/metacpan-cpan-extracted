#!/usr/bin/env perl

use utf8;   # needed for Mojolicious < 3.69

use Mojo::Base -strict;
use Mojo::URL;

# Disable IPv6 and libev
BEGIN {
    $ENV{MOJO_NO_IPV6} = 1;
    $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

my $enc = 'Shift_JIS';
my $yatta = 'やった';
my @methods = qw(GET POST PUT PATCH DELETE);
my $pname = 'x-test-tunnel-method';

eval {
    plugin 'Charset', charset => $enc; 1;
}
or do {
    app->types->type(html => "text/html;charset=$enc");
    app->renderer->encoding('Shift_JIS');
    app->hook(
        before_dispatch => sub {
            shift->req->default_charset('Shift_JIS')->url->query->charset('Shift_JIS');
        }
    );
};

plugin 'MethodOverride', header => undef, param => $pname;

any \@methods => '/' => sub {
    my $self = shift;
    my $method = uc $self->req->method;
    my $p = $self->param('p') // '';
    my $m = $self->param($pname) // '*undef*';

    $self->render(text => "$method p=$p, m=$m");
};


my $t = Test::Mojo->new;

my $url = Mojo::URL->new->path('/')->query(p => $yatta);
$url->query->charset($enc);

$t->post_ok($url)
  ->status_is(200)
  ->content_is("POST p=$yatta, m=*undef*");

for my $method (@methods) {
    $url = Mojo::URL->new->path('/')
        ->query(p => $yatta, $pname => $method);
    $url->query->charset($enc);

    $t->post_ok($url)
        ->status_is(200)
        ->content_is("$method p=$yatta, m=*undef*");
}

done_testing;
