#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Raw::JSON qw(file_json_decode);

# The context: request wrapping, params (captures then query then form),
# stash, cookies, JSON bodies, headers.

{
    package CtxApp;
    use Punk;
    get '/echo/:name' => sub {
        my ($c) = @_;
        return {
            capture => $c->param('name'),
            q       => $c->param('q'),
            method  => $c->req->method,
            path    => $c->req->path,
            ua      => $c->req->header('User-Agent'),
        };
    };
    post '/form' => sub {
        my ($c) = @_;
        return { name => $c->param('name'), tags => $c->req->param('tags') };
    };
    post '/json' => sub { my ($c) = @_; { got => $c->req->json } };
    get '/jar' => sub { my ($c) = @_; { sid => $c->req->cookie('sid') } };
    get '/stash' => sub {
        my ($c) = @_;
        $c->stash->{x} = 5;
        return { x => $c->stash->{x} };
    };
    package main;
}

my $app = CtxApp->to_app;

{
    my $d = file_json_decode(hit($app, path => '/echo/rex',
        query => 'q=1', env => { HTTP_USER_AGENT => 'punk-test' })->[2][0]);
    is($d->{capture}, 'rex', 'capture through param');
    is($d->{q}, 1, 'query through param');
    is($d->{method}, 'GET', 'req->method');
    is($d->{path}, '/echo/rex', 'req->path');
    is($d->{ua}, 'punk-test', 'req->header');
}
{
    my $d = file_json_decode(hit($app, method => 'POST', path => '/form',
        body => 'name=rex&tags=a&tags=b%20c',
        type => 'application/x-www-form-urlencoded')->[2][0]);
    is($d->{name}, 'rex', 'form body param');
    is_deeply($d->{tags}, ['a', 'b c'],
        'repeated form param is an arrayref, percent-decoded');
}
{
    my $d = file_json_decode(hit($app, method => 'POST', path => '/json',
        body => '{"pet":{"id":3}}')->[2][0]);
    is($d->{got}{pet}{id}, 3, 'req->json decodes the body');
}
{
    my $d = file_json_decode(hit($app, path => '/jar',
        env => { HTTP_COOKIE => 'sid=abc123; theme=dark' })->[2][0]);
    is($d->{sid}, 'abc123', 'cookies parse');
}
is(file_json_decode(hit($app, path => '/stash')->[2][0])->{x}, 5, 'stash');

# ---- query precedence over form ----------------------------------------------
{
    package Precedence;
    use Punk;
    post '/p' => sub { { v => $_[0]->param('v') } };
    package main;
    my $d = file_json_decode(hit(Precedence->to_app,
        method => 'POST', path => '/p', query => 'v=query',
        body => 'v=form',
        type => 'application/x-www-form-urlencoded')->[2][0]);
    is($d->{v}, 'query', 'query wins over form in param');
}

# ---- params(@keys) -----------------------------------------------------------
# The keyed form resolves each name exactly as param does - capture first,
# then query, then form - and is the one call the filter-hash idiom needs.
{
    package Many;
    use Punk;
    post '/many/:state' => sub {
        my ($c) = @_;
        my @slice = $c->params(qw(state queue nope));
        return {
            slice  => \@slice,
            filter => { %{ $c->params(qw(state queue task nope)) } },
            all    => $c->params,
        };
    };
    package main;
    my $d = file_json_decode(hit(Many->to_app,
        method => 'POST', path => '/many/active', query => 'queue=default',
        body => 'task=send&state=body-loses',
        type => 'application/x-www-form-urlencoded')->[2][0]);
    is_deeply($d->{slice}, [ 'active', 'default', undef ],
        'params(@keys) slices in capture-then-query order, undef for missing');
    is_deeply($d->{filter},
        { state => 'active', queue => 'default', task => 'send' },
        'the hashref form drops the name no layer has');
    is_deeply($d->{all},
        { state => 'active', queue => 'default', task => 'send' },
        'params with no names merges every layer, the capture winning');
}

# ---- slot layout -------------------------------------------------------------
# The accessors (xs/context.xs) and the PCX_* enum (punk_context.h) are the two
# halves of one contract: the accessor XSUB maps its ALIAS index straight into
# that enum, and _build, ps_ctx and the dispatcher all store by it. Reordering
# one list without the other would read the wrong slot in silence, so pin the
# mapping rather than trust the two orderings to stay in step.
{
    require Punk::Context;
    my @slots = qw(env app _req _res stash_hv openapi_params match);
    my $c = Punk::Context->_build({ PATH_INFO => '/slots' }, 'APP', {});
    is(scalar @$c, scalar @slots, 'the context is exactly its slots - no more');
    for my $i (0 .. $#slots) {
        my $name = $slots[$i];
        $c->$name("v$i");
        is($c->[$i], "v$i", "$name writes slot $i");
        is($c->$name,  "v$i", "$name reads slot $i back");
    }
    like(do { eval { Punk::Context::env(bless {}, 'NotAContext') }; $@ },
        qr/not a context object/, 'an accessor on a foreign invocant croaks');
}

done_testing();
