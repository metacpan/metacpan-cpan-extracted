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
            $c->stash('cached' =>
                join '', $c->stash('cached') // '',  $captures->{$pattern}
            );
            return 1;
        });
    }
    1;
}

my $t = Test::Mojo->new('MyApp');

$t  ->app->routes
    ->under('bridge1/:foo')
    ->under('bridge2/:bar')
    ->any("/cached")
    ->over('cached' => 'foo', 'cached' => 'bar')
    ->to( cb => sub { $_[0]->render(text => $_[0]->stash('cached')) })
;
$t
    ->get_ok("/bridge1/1/bridge2/2/cached")
    ->status_is(200)
    ->content_is('12')

;
$t
    ->get_ok("/bridge1/A/bridge2/B/cached")
    ->status_is(200)
    ->content_is('AB')
;
