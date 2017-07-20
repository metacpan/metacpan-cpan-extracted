#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 6;
use Test::Mojo;

{
    package MyApp;
    use Mojo::Base 'Mojolicious';
    sub startup {
        my ($self) = @_;
        $self->plugin('Check');

        $self->add_checker('nostash' => sub{
            my ($route, $c, $captures, $pattern) = @_;
            my $a = $c->param('a');
            return scalar grep {$a == $_} @$pattern;
        });
    }
    1;
}

my $t = Test::Mojo->new('MyApp');

$t  ->app->routes
    ->any("/test")
    ->over('nostash' => [1, 2])
    ->to( cb => sub { $_[0]->render(text => 'OK.')})
;
$t
    ->get_ok("/test?a=1")
    ->status_is(200)
;
$t
    ->get_ok("/test?a=2")
    ->status_is(200)
;
$t
    ->get_ok("/test?a=3")
    ->status_is(404)
;
