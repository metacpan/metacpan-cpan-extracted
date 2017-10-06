#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 4;
use Test::Mojo;

{
    package MyApp;
    use Mojo::Base 'Mojolicious';
    sub startup {
        my ($self) = @_;
        $self->plugin('Check');

        $self->add_checker('true' => sub{
            my ($route, $c, $captures, $pattern) = @_;
            return $captures->{$pattern} ? 1 : 0;
        });
    }
    1;
}

my $t = Test::Mojo->new('MyApp');

$t  ->app->routes
    ->any("/test/:foo")
    ->to( cb => sub { $_[0]->render(text => 'OK.')})
;
$t
    ->get_ok("/test/1")
    ->status_is(200)
;
$t
    ->get_ok("/test/0")
    ->status_is(200)
;
