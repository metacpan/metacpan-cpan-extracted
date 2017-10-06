#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 9;
use Test::Mojo;

{
    package MyApp;
    use Mojo::Base 'Mojolicious';
    sub startup {
        my ($self) = @_;
        $self->plugin('Check');

        $self->add_checker(first => sub{
            my ($route, $c, $captures, $pattern) = @_;
            return $captures->{$pattern} ? 1 : 0;
        });

        $self->add_checker(second => sub{
            my ($route, $c, $captures, $pattern) = @_;
            return $captures->{$pattern} ? 1 : 0;
        });

        $self->add_checker(tree => sub{
            my ($route, $c, $captures, $pattern) = @_;
            return $captures->{$pattern} ? 1 : 0;
        });
    }
    1;
}

my $t = Test::Mojo->new('MyApp');

my $r = $t->app->routes;
for my $r ( $r->under('/bridge1/:foo')->over(first => 'foo') ) {
    for my $r ( $r->under('/bridge2/:bar')->over(second => 'bar') ) {
        $r  ->any('/test/:some')
            ->over(tree => 'some')
            ->to( cb => sub { $_[0]->render(text => 'OK'); } )
            ->name('test')
        ;
    }
}

$t
    ->get_ok( $t->app->url_for('test', foo => 1, bar => 1, some => 1) )
    ->status_is(200)
    ->content_is('OK')
;
$t
    ->get_ok( $t->app->url_for('test', foo => 0, bar => 1, some => 1) )
    ->status_is(404)
;
$t
    ->get_ok( $t->app->url_for('test', foo => 1, bar => 0, some => 1) )
    ->status_is(404)
;
$t
    ->get_ok( $t->app->url_for('test', foo => 1, bar => 1, some => 0) )
    ->status_is(404)
;
