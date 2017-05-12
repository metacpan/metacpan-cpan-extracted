#!/usr/bin/env perl -w
use strict;
use Test::More tests => 9;

use Railsish::Router;

Railsish::Router->draw(
    sub {
	my ($map) = @_;

	$map->connect(
	    "/dashboard/:year/:month/:date",
	    controller => "users",
	    action => "dashboard"
	);

        $map->connect("/:controller/:action/:id");
    }
);

my $uri = Railsish::Router->uri_for(
    controller => "users",
    action => "dashboard",
    year => "3009",
    month => "12",
    date => "23"
);

is($uri, "/dashboard/3009/12/23");

{
    my $matched = Railsish::Router->match("/admin/show/123");

    if ($matched) {
        my $mapping = $matched->mapping;
        is $mapping->{controller}, "admin";
        is $mapping->{action}, "show";
        is $mapping->{id}, "123";
    } else {
        fail "Not maching /admin/show/123" for 1..3;
    }
}

{
    my $matched = Railsish::Router->match("/dashboard/1234/12/21");

    if ($matched) {
        my $mapping = $matched->mapping;
        is $mapping->{controller}, "users";
        is $mapping->{action}, "dashboard";
        is $mapping->{year}, "1234";
        is $mapping->{month}, "12";
        is $mapping->{date}, "21";
    } else {
        fail "Not maching /dashboard/1234/12/21" for 1..3;
    }
}
