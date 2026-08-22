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

# $c->safe_path: the guard for a redirect destination that came out of the
# request. A browser strips TAB/CR/LF before parsing a URL and folds '\' to
# '/', so "starts with a slash" is not the same question as "stays on this
# site" - see Punk::OAuth2's CVE-2026-75628, whose rules these are.
{
    package SafeApp;
    use Punk;
    get '/go' => sub {
        my ($c) = @_;
        $c->text($c->safe_path($c->param('to'), '/fallback'));
    };
    get '/bare' => sub {
        my ($c) = @_;
        my $p = $c->safe_path($c->param('to'));
        $c->text(defined $p ? $p : 'undef');
    };
    package main;

    my $sapp = SafeApp->to_app;
    my $go = sub {
        my ($to, $path) = @_;
        $to =~ s/([^A-Za-z0-9])/sprintf '%%%02X', ord $1/ge;
        return hit($sapp, path => $path // '/go', env => { QUERY_STRING => "to=$to" })->[2][0];
    };

    for my $ok ('/', '/dashboard', '/a/b/c?x=1&y=2', '/a%5Cb', '/sp ace') {
        is($go->($ok), $ok, "same-origin path passes: '$ok'");
    }

    my %evil = (
        'protocol-relative' => '//evil.example',
        'backslash'         => '/\\evil.example',
        'backslash-slash'   => '/\\/evil.example',
        'tab'               => "/\t/evil.example",
        'CR'                => "/\r/evil.example",
        'LF'                => "/\n/evil.example",
        'NUL'               => "/\0//evil.example",
        'DEL'               => "/\x7f//evil.example",
        'absolute'          => 'https://evil.example/',
        'scheme-relative'   => 'javascript:alert(1)',
        'bare word'         => 'evil.example',
        'empty'             => '',
    );
    for my $why (sort keys %evil) {
        is($go->($evil{$why}), '/fallback', "refused, falls back: $why");
    }

    # with no fallback the refusal is undef, so `// '/'` at a call site works
    is($go->('//evil.example', '/bare'), 'undef', 'no fallback means undef');
    is($go->('/ok', '/bare'), '/ok', 'and a good path still comes back');
}

# ---- the raw slots behind stash and openapi ---------------------------------
# stash_hv and openapi_params are the accessor pair the class is built from -
# documented, and used by the framework and by code that wants the slot
# untouched. Nothing exercised either, so nothing said whether they really are
# the same storage the lazy accessors build into, or a second one beside it.
{
    package SlotApp;
    use Punk;

    get '/same' => sub {
        my ($c) = @_;
        $c->stash->{via_accessor} = 1;             # builds the slot lazily
        my $raw = $c->stash_hv;                    # ...and this reads it
        $raw->{via_raw} = 1;
        $c->json({
            raw_saw_accessor => $raw->{via_accessor} ? 1 : 0,
            accessor_saw_raw => $c->stash->{via_raw} ? 1 : 0,
            one_hash         => $c->stash == $raw ? 1 : 0,
        });
    };

    # the raw slot is EMPTY until something builds it, which is the whole
    # reason to prefer stash: the lazy accessor is what makes it a hashref
    get '/untouched' => sub {
        my ($c) = @_;
        my $raw = $c->stash_hv;
        $c->json({ defined_before => defined $raw ? 1 : 0 });
    };

    # openapi_params on a route that is not an API mount: undef, not an
    # accidental empty hash somebody could mistake for validated input
    get '/no-api' => sub {
        my ($c) = @_;
        $c->json({ params  => defined $c->openapi_params ? 1 : 0,
                   openapi => defined $c->openapi        ? 1 : 0 });
    };

    package main;
    my $sapp = SlotApp->to_app;

    my $d = file_json_decode(hit($sapp, path => '/same')->[2][0]);
    is($d->{raw_saw_accessor}, 1,
        'stash_hv reads the hash stash built - one slot, not two');
    is($d->{accessor_saw_raw}, 1, 'and a write through the raw slot is visible '
                                . 'through the accessor');
    is($d->{one_hash}, 1, 'because they are the same hashref');

    my $u = file_json_decode(hit($sapp, path => '/untouched')->[2][0]);
    is($u->{defined_before}, 0,
        'the raw slot is undef until the lazy accessor builds it - which is '
      . 'why the documentation says to prefer stash');

    my $n = file_json_decode(hit($sapp, path => '/no-api')->[2][0]);
    is($n->{params}, 0,
        'openapi_params is undef off an API mount, rather than an empty hash '
      . 'that would read as "validated, nothing in it"');
    is($n->{openapi}, 0, 'and so is the accessor over it');
}

done_testing();
