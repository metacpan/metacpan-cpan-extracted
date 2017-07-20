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

        $self->add_checker('cached' => sub{
            my ($route, $c, $captures, $pattern) = @_;
            $c->stash('cached' => $captures->{$pattern});
            return $captures->{$pattern} ? 1 : 0;
        });
    }
    1;
}

my $t = Test::Mojo->new('MyApp');

$t  ->app->routes
    ->any("/cached/:foo")
    ->over('cached' => 'foo')
    ->to( cb => sub { $_[0]->render(text => $_[0]->stash('cached')) })
;
$t
    ->get_ok("/cached/1")
    ->status_is(200)
    ->content_is('1')

;
$t
    ->get_ok("/cached/2")
    ->status_is(200)
    ->content_is('2')
;
