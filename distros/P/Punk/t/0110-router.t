#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Raw::JSON qw(file_json_decode);

# Static exact matches, dynamic :param / *splat buckets, HEAD fallback,
# 404 vs 405 with the Allow list computed on the miss path.

{
    package RouterApp;
    use Punk;
    get   '/'               => sub { $_[0]->text('home') };
    get   '/books'          => sub { $_[0]->text('list') };
    post  '/books'          => sub { $_[0]->text('made') };
    get   '/books/:id'      => sub { { id => $_[0]->param('id') } };
    put   '/books/:id'      => sub { { put => $_[0]->param('id') } };
    get   '/books/:id/tags/:tag' => sub {
        { id => $_[0]->param('id'), tag => $_[0]->param('tag') } };
    get   '/files/*rest'    => sub { { rest => $_[0]->param('rest') } };
    get   '/:page'          => sub { { page => $_[0]->param('page') } };
    any   '/anything'       => sub { $_[0]->text($_[0]->req->method) };
    del   '/books/:id'      => sub { { gone => $_[0]->param('id') } };
    patch '/books/:id'      => sub { { patched => $_[0]->param('id') } };
    package main;
}

my $app = RouterApp->to_app;

is(hit($app, path => '/')->[2][0], 'home', 'static /');
is(hit($app, path => '/books')->[2][0], 'list', 'static GET');
is(hit($app, method => 'POST', path => '/books')->[2][0], 'made',
    'static POST same path');
is(file_json_decode(hit($app, path => '/books/7')->[2][0])->{id}, 7,
    ':param captures');
is(file_json_decode(hit($app, method => 'PUT',
    path => '/books/7')->[2][0])->{put}, 7, 'method picks the record');
{
    my $d = file_json_decode(hit($app, path => '/books/7/tags/new')->[2][0]);
    is_deeply($d, { id => 7, tag => 'new' }, 'two captures');
}
is(file_json_decode(hit($app, path => '/files/a/b/c.txt')->[2][0])->{rest},
    'a/b/c.txt', '*splat captures the rest');
is(file_json_decode(hit($app, path => '/about')->[2][0])->{page}, 'about',
    'param-first path uses the empty bucket');
is(hit($app, method => 'DELETE', path => '/anything')->[2][0], 'DELETE',
    'any matches every method');

# ---- HEAD falls back to GET with an empty body -------------------------------
{
    my $r = hit($app, method => 'HEAD', path => '/books');
    is($r->[0], 200, 'HEAD hits the GET route');
    is($r->[2][0], '', 'HEAD body is stripped');
    my %h = @{ $r->[1] };
    is($h{'Content-Length'}, 4, 'Content-Length survives for HEAD');
}

# ---- 404 / 405 ---------------------------------------------------------------
is(hit($app, path => '/no/such/path/here')->[0], 404, 'unknown path 404s');
{
    my $r = hit($app, method => 'POST', path => '/books/7');
    is($r->[0], 405, 'known dynamic path, undeclared method: 405');
    my %h = @{ $r->[1] };
    is($h{Allow}, 'DELETE, GET, PATCH, PUT', 'Allow lists the declared methods');
    like($r->[2][0], qr/Method Not Allowed/, 'error body shape');
}
{
    my $r = hit($app, method => 'PUT', path => '/');
    is($r->[0], 405, 'static path, undeclared method: 405');
    my %h = @{ $r->[1] };
    is($h{Allow}, 'GET', 'static Allow');
}

# ---- trailing slash ----------------------------------------------------------
# /account/ answers the route declared as /account, rather than 404ing.
is(hit($app, path => '/books/')->[2][0], 'list', 'trailing slash: static');
is(hit($app, method => 'POST', path => '/books/')->[2][0], 'made',
    'trailing slash: static, other method');
is(file_json_decode(hit($app, path => '/books/7/')->[2][0])->{id}, 7,
    'trailing slash: :param');
is(hit($app, path => '/')->[2][0], 'home', 'the root itself is untouched');
is(hit($app, path => '/books///')->[2][0], 'list', 'repeated slashes');
{
    my $r = hit($app, method => 'PUT', path => '/books/');
    is($r->[0], 405, 'trailing slash still 405s an undeclared method');
    my %h = @{ $r->[1] };
    is($h{Allow}, 'GET, POST', 'and carries the trimmed path Allow');
}
{
    # *splat owns everything after the prefix, trailing slash included, so
    # the rescue must not reach a route that already matched
    my $d = file_json_decode(hit($app, path => '/files/a/b/')->[2][0]);
    is($d->{rest}, 'a/b/', 'splat keeps its own trailing slash');
}

# ---- boot-time route validation ----------------------------------------------
{
    package BadPath;
    use Punk;
    package main;
    my $err = '';
    eval { BadPath::punk_app()->route(GET => 'nope', sub { }) } or $err = $@;
    like($err, qr/starting with '\//, 'path without leading slash croaks');
}
{
    package DupRoute;
    use Punk;
    get '/x' => sub { };
    get '/x' => sub { };
    package main;
    my $err = '';
    eval { DupRoute->to_app } or $err = $@;
    like($err, qr/duplicate route GET \/x/, 'duplicate static route croaks');
}

done_testing();
