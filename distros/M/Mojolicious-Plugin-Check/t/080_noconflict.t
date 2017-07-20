#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 5;
use Test::Mojo;

my @test;

{
    package MyApp;
    use Mojo::Base 'Mojolicious';
    sub startup {
        my ($self) = @_;

        $self->hook(around_action => sub {
            my ($next, $c, $action, $last) = @_;
            push @test, 'one';
            return $next->();
        });

        $self->plugin('Check');

        $self->hook(around_action => sub {
            my ($next, $c, $action, $last) = @_;
            push @test, 'two';
            return $next->();
        });

        $self->add_checker('true' => sub{
            my ($route, $c, $captures, $pattern) = @_;
            return $captures->{$pattern} ? 1 : 0;
        });

        $self->hook(around_action => sub {
            my ($next, $c, $action, $last) = @_;
            push @test, 'three';
            return $next->();
        });
    }
    1;
}

my $t = Test::Mojo->new('MyApp');

$t  ->app->routes
    ->any("/test/:foo")
    ->over('true' => 'foo')
    ->to( cb => sub { $_[0]->render(text => 'OK.')})
;
$t
    ->get_ok("/test/1")
    ->status_is(200)
;
$t
    ->get_ok("/test/0")
    ->status_is(404)
;

is_deeply \@test, [qw(one two three one)], 'All hooks ok';
