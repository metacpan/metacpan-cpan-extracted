#!/usr/bin/env perl -w
use strict;
use Test::More tests => 15;

use Railsish::Router;

Railsish::Router->draw(
    sub {
        my ($map) = @_;
        $map->resources("photos");
    }
);

my $m;

$m = Railsish::Router->match("/photos/3")->mapping;
is($m->{controller}, "photos");
is($m->{action}, "show");
is($m->{id}, 3);

$m = Railsish::Router->match("/photos")->mapping;
is($m->{controller}, "photos");
is($m->{action}, "index");
is($m->{id}, undef);

$m = Railsish::Router->match("/photos/3/edit")->mapping;
is($m->{controller}, "photos");
is($m->{action}, "edit");
is($m->{id}, 3);

is(Railsish::Router->photos_path, "/photos");
is(Railsish::Router->photo_path( id => 3 ), "/photos/3");
is(Railsish::Router->edit_photo_path( id => 3 ), "/photos/3/edit");


$m = Railsish::Router->match("/photos/new")->mapping;
is($m->{controller}, "photos");
is($m->{action}, "new");
is(Railsish::Router->new_photo_path, "/photos/new");


