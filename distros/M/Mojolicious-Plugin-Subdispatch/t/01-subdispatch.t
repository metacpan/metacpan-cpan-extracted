#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 47;
use Mojolicious::Lite;
use Mojo::DOM;
use FindBin '$Bin';
use lib "$Bin/../lib";

# silence!
app->log->level('warn');

# plugin loads
use_ok('Mojolicious::Plugin::Subdispatch');

plugin 'Subdispatch';

any '/x/:thing/y' => sub {
    my $self = shift;
    $self->stash(method => $self->req->method)
} => 'acshun';

# PUT /x/foo/y (subdispatch)
my $tx = app->subdispatch(PUT => 'acshun', thing => 'foo');
isa_ok($tx, 'Mojo::Transaction', 'subdispatch return value');
is($tx->req->method, 'PUT', 'right method');
is($tx->req->url->path, '/x/foo/y', 'right url');
is($tx->res->code, 200, 'right response status');
my $resd = Mojo::DOM->new($tx->res->body);
is($resd->at('title')->text, 'yum', 'right title');
is($resd->at('h1')->text, 'This is PUT/foo!', 'right headline');
is($resd->find('p')->size, 0, 'no paragraphs');

# DELETE /x/bar/y (delete)
my $res = app->subdispatch->delete('acshun', thing => 'bar');
isa_ok($res, 'Mojo::Message::Response', 'subdispatch return value');
is($res->code, 200, 'right response status');
$resd = Mojo::DOM->new($res->body);
is($resd->at('title')->text, 'yum', 'right title');
is($resd->at('h1')->text, 'This is DELETE/bar!', 'right headline');
is($resd->find('p')->size, 0, 'no paragraphs');

# GET /x/baz/y (get)
$res = app->subdispatch->get('acshun', thing => 'baz');
isa_ok($res, 'Mojo::Message::Response', 'subdispatch return value');
is($res->code, 200, 'right response status');
$resd = Mojo::DOM->new($res->body);
is($resd->at('title')->text, 'yum', 'right title');
is($resd->at('h1')->text, 'This is GET/baz!', 'right headline');
is($resd->find('p')->size, 0, 'no paragraphs');

# HEAD /x/quux/y (head)
$res = app->subdispatch->head('acshun', thing => 'quux');
isa_ok($res, 'Mojo::Message::Response', 'subdispatch return value');
is($res->code, 200, 'right response status');
$resd = Mojo::DOM->new($res->body);
is($resd->at('title')->text, 'yum', 'right title');
is($resd->at('h1')->text, 'This is HEAD/quux!', 'right headline');
is($resd->find('p')->size, 0, 'no paragraphs');

# POST /x/om/y (post)
$res = app->subdispatch->post('acshun', thing => 'om');
isa_ok($res, 'Mojo::Message::Response', 'subdispatch return value');
is($res->code, 200, 'right response status');
$resd = Mojo::DOM->new($res->body);
is($resd->at('title')->text, 'yum', 'right title');
is($resd->at('h1')->text, 'This is POST/om!', 'right headline');
is($resd->find('p')->size, 0, 'no paragraphs');

# PUT /x/nom/y (put)
$res = app->subdispatch->put('acshun', thing => 'nom');
isa_ok($res, 'Mojo::Message::Response', 'subdispatch return value');
is($res->code, 200, 'right response status');
$resd = Mojo::DOM->new($res->body);
is($resd->at('title')->text, 'yum', 'right title');
is($resd->at('h1')->text, 'This is PUT/nom!', 'right headline');
is($resd->find('p')->size, 0, 'no paragraphs');

# POST FORM /x/noy/y (subdispatch)
$tx = app->subdispatch(POST => 'acshun', thing => 'noy', {hogo => 'prenuut'});
isa_ok($tx, 'Mojo::Transaction', 'subdispatch return value');
is($tx->req->method, 'POST', 'right method');
is($tx->req->url->path, '/x/noy/y', 'right url');
is($tx->res->code, 200, 'right response status');
$resd = Mojo::DOM->new($tx->res->body);
is($resd->at('title')->text, 'yum', 'right title');
is($resd->at('h1')->text, 'This is POST/noy!', 'right headline');
is($resd->at('p')->text, 'hogo: prenuut', 'right post data');

# POST FORM /x/nox/y (post)
$res = app->subdispatch->post('acshun', thing => 'nox', {hogo => 'perl'});
isa_ok($res, 'Mojo::Message::Response', 'subdispatch return value');
is($res->code, 200, 'right response status');
$resd = Mojo::DOM->new($res->body);
is($resd->at('title')->text, 'yum', 'right title');
is($resd->at('h1')->text, 'This is POST/nox!', 'right headline');
is($resd->at('p')->text, 'hogo: perl', 'right post data');

# with base
plugin 'Subdispatch', base_url => 'http://foo';
$tx = app->subdispatch(GET => 'acshun', thing => 'yay');
isa_ok($tx, 'Mojo::Transaction', 'subdispatch return value (with base)');
is($tx->req->url->base, 'http://foo', 'right base');

__DATA__

@@ acshun.html.ep
% layout 'wrap';
<h1>This is <%= "$method/$thing" %>!</h1>
% if (defined param 'hogo') {
<p>hogo: <%= param 'hogo' %></p>
% }

@@ layouts/wrap.html.ep
<!doctype html>
<html><head><title>yum</title></head><body><%= content %></body></html>
