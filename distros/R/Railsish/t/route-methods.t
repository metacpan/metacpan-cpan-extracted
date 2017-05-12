#!/usr/bin/env perl -w
use strict;
use Test::More tests => 2;
use Moose ();

use Railsish::Router;

Railsish::Router->draw(
    sub {
	my ($map) = @_;
	$map->connect(
	    "/photos",
	    controller => "photos",
	    action => "create",
            conditions => { method => 'post' }
	);

        $map->connect(
	    "/photos",
	    controller => "photos",
	    action => "index",
            conditions => { method => 'get' }
	);
    }
);

{
    my $matched = Railsish::Router->match("/photos", conditions => { method => "get" });

    if ($matched) {
        my $mapping = $matched->mapping;
        is $mapping->{controller}, "photos";
        is $mapping->{action}, "index";
    } else {
        fail "Not maching /dashboard/1234/12/21" for 1..2;
    }
}
