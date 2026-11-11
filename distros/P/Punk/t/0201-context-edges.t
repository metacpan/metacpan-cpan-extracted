#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest qw(hit);

# The context's edges: a redirect that carries the headers set before it,
# the status read back before any was set, a fragment asked for without a
# template, url_for's refusals from a handler, an upload asked of a request
# that carries none, csrf_token on an application with no csrf, the bus
# methods outside a worker pool, and after_response given something that
# is not code.

{
    package CtxApp;
    use Punk;
    get '/redir'    => sub { my ($c) = @_; $c->header('X-Extra' => 'yes'); $c->redirect('/elsewhere', 303) };
    get '/status'   => sub { my ($c) = @_; $c->text(defined $c->status ? 'set' : 'unset') };
    get '/fragment' => sub { my ($c) = @_; eval { $c->fragment }; $c->text($@) };
    get '/url_odd'  => sub { my ($c) = @_; eval { $c->url_for('home', 'odd') }; $c->text($@) };
    get '/url_none' => sub { my ($c) = @_; eval { $c->url_for('') }; $c->text($@) };
    get '/url_q'    => sub { my ($c) = @_; eval { $c->url_for('home', query => 'x') }; $c->text($@) };
    get '/url_nope' => sub { my ($c) = @_; eval { $c->url_for('nope') }; $c->text($@) };
    get '/upload'   => sub { my ($c) = @_; $c->text(defined $c->upload('file') ? 'has' : 'none') };
    get '/csrf'     => sub { my ($c) = @_; eval { $c->csrf_token }; $c->text($@) };
    get '/bus'      => sub { my ($c) = @_; my $p = $c->publish('t', 'payload'); my $s = $c->subscribe('t', sub { }, group => 'g'); $c->text("p=$p s=$s") };
    get '/after'    => sub { my ($c) = @_; eval { $c->after_response('not code') }; $c->text($@) };
    get '/'         => sub { $_[0]->text('home') }, { name => 'home' };
    package main;
}
my $app = CtxApp->to_app;
sub body { join '', @{ $_[0]->[2] } }
{
    my $r = hit($app, path => '/redir');
    is($r->[0], 303, 'a redirect with its own status');
    my %h = @{ $r->[1] };
    is($h{Location}, '/elsewhere', 'and location');
    is($h{'X-Extra'}, 'yes', 'carries the headers set before it');
}
is(body(hit($app, path => '/status')), 'unset', 'status reads back undef before any was set');
like(body(hit($app, path => '/fragment')), qr/Punk::Context::fragment: a template name is required/, 'a fragment needs a template');
like(body(hit($app, path => '/url_odd')), qr/url_for takes a route name then key => value pairs/, 'url_for with an odd list');
like(body(hit($app, path => '/url_none')), qr/url_for needs a route name/, 'url_for with no name');
like(body(hit($app, path => '/url_q')), qr/`query` takes a hashref/, 'url_for with a query that is not a hashref');
like(body(hit($app, path => '/url_nope')), qr/no route is named 'nope'/, 'url_for with a name nothing has');
is(body(hit($app, path => '/upload')), 'none', 'an upload asked of a request with none is undef');
like(body(hit($app, path => '/csrf')), qr/no csrf configured \(add a `csrf` keyword\)/, 'csrf_token without the keyword');
like(body(hit($app, path => '/bus')), qr/^p=-?\d+ s=-?\d+$/, 'the bus methods answer with numbers outside a pool');
like(body(hit($app, path => '/after')), qr/after_response takes a code reference/, 'after_response needs code');

done_testing;
