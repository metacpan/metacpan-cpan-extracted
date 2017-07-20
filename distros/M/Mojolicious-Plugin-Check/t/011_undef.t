#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 2;
use Test::Mojo;

{
    package MyApp;
    use Mojo::Base 'Mojolicious';
    sub startup {
        my ($self) = @_;
        $self->plugin('Check');

        $self->add_checker('undefined' => sub{
            my ($route, $c, $captures, $pattern) = @_;
            $c->reply->not_found;
            return undef;
        });
    }
    1;
}

my $t = Test::Mojo->new('MyApp');

$t  ->app->routes
    ->any("/test/:foo")
    ->over('undefined' => 'foo')
    ->to( cb => sub { return $_[0]->render(text => 'OK.', status => 400)})
;
$t
    ->get_ok("/test/1")
    ->status_is(404)
;
