#!/usr/bin/env perl -w
use strict;
use Test::More tests => 5;

use Railsish::Router;

Railsish::Router->draw(
    sub {
	my ($map) = @_;
	$map->resources("blogs", path_prefix => "/admin");
    }
);

my $blog = { id => 1 };

is(Railsish::Router->blogs_path, "/admin/blogs");
is(Railsish::Router->blog_path($blog), "/admin/blogs/1");
is(Railsish::Router->edit_blog_path($blog), "/admin/blogs/1/edit");
is(Railsish::Router->new_blog_path, "/admin/blogs/new");

{
    my $matched = Railsish::Router->match("/admin/blogs", conditions => {method => "get" });
    if ($matched) {
        my $mapping = $matched->mapping;
        is($mapping->{path_prefix}, "/admin");
    }
    else {
        fail "Not matching /admin/blogs";
    }
}
