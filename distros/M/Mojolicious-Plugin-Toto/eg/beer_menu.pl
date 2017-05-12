#!/usr/bin/env perl

use Mojolicious::Lite;

my $menu = [
    beer => {
        many => [qw/search browse/],
        one  => [qw/picture ingredients pubs/],
    },
    pub => {
        many => [qw/map list search/],
        one  => [qw/info comments/],
    }
];

plugin 'toto' => menu => $menu;

app->start;

