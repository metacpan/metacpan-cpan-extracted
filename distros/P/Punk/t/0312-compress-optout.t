#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk ();

# The per-route compression opt-out.
#
# Punk does not compress: the server does (Hyperman, hm_compress.h), because
# compression belongs to the write path and serves apps that are not Punk.
# What Punk owns is the INTENT, and it is spelled as a plain response header
# - `Content-Encoding: identity` - which the server honours and strips. That
# makes it a contract any PSGI framework could use rather than a private
# arrangement between these two.
#
# So this file asserts the CONTRACT, not any compression. It must pass on any
# PSGI server and on a Hyperman built without zlib.

{
    package Opt;
    use Punk;
    get '/plain'    => sub { $_[0]->text('x' x 3000) };
    get '/optout'   => sub { $_[0]->text('x' x 3000) }, { compress => 0 };
    get '/own'      => sub {
        my ($c) = @_;
        $c->res->header('Content-Encoding' => 'gzip');
        $c->text('already encoded');
    }, { compress => 0 };
    post '/optpost' => sub { $_[0]->text('x' x 3000) }, { compress => 0 };
    get '/both'     => sub { $_[0]->json({ ok => 1 }) },
                       { compress => 0, validate => { type => 'object' } };
    package main;
}

my $app = Opt->to_app;

sub call {
    my ($method, $path) = @_;
    open my $in, '<', \'';
    my $res = $app->({
        REQUEST_METHOD => $method,
        PATH_INFO      => $path,
        QUERY_STRING   => '',
        SERVER_NAME    => 'localhost', SERVER_PORT => 80,
        HTTP_HOST      => 'localhost', 'psgi.url_scheme' => 'http',
        'psgi.input'   => $in,
    });
    my %h = @{ $res->[1] };
    return ($res->[0], \%h);
}

# ---- the default is to say nothing -----------------------------------------

{
    my ($st, $h) = call(GET => '/plain');
    is $st, 200, 'an ordinary route answers';
    ok !exists $h->{'Content-Encoding'},
       'a route that says nothing emits no Content-Encoding: compressing is '
     . 'the server\'s decision to make';
}

# ---- the opt-out -----------------------------------------------------------

{
    my ($st, $h) = call(GET => '/optout');
    is $st, 200, 'an opted-out route answers normally';
    is $h->{'Content-Encoding'}, 'identity',
       'compress => 0 spells itself as Content-Encoding: identity';
}
{
    my ($st, $h) = call(POST => '/optpost');
    is $h->{'Content-Encoding'}, 'identity',
       'the option is per route, not per path: POST carries it too';
}

# ---- a handler that set its own encoding wins ------------------------------

# The route said "not yours to compress"; the handler said "here is the
# encoding". The handler is more specific and is not overridden - the same
# set-if-absent rule Punk::Headers follows.
{
    my ($st, $h) = call(GET => '/own');
    is $h->{'Content-Encoding'}, 'gzip',
       'a handler-set Content-Encoding is not replaced by identity';
}

# ---- it composes with the other route options ------------------------------

{
    my ($st, $h) = call(GET => '/both');
    is $h->{'Content-Encoding'}, 'identity',
       'compress sits alongside validate in the same options hashref';
}

# ---- boot-time validation --------------------------------------------------

sub boot_fails {
    my ($body, $like, $what) = @_;
    my $pkg = 'CBoot' . int(rand 1e9);
    eval "package $pkg; use Punk; $body; ${pkg}->to_app; 1";
    like $@ || '', $like, $what;
}

boot_fails q{get '/x' => sub { 1 }, { compres => 0 }},
    qr/unknown route option 'compres'/,
    'a misspelled option still croaks at boot, naming itself';

# `compress => 1` is accepted and means "no opt-out recorded" - compressing
# is already the server's default answer, so there is nothing to turn on.
{
    my $pkg = 'CBootOn' . int(rand 1e9);
    eval "package $pkg; use Punk;"
       . "get '/y' => sub { \$_[0]->text('hi') }, { compress => 1 };"
       . "our \$APP = ${pkg}->to_app; 1";
    is $@, '', 'compress => 1 is accepted';
    no strict 'refs';
    my $a = ${"${pkg}::APP"};
    open my $in, '<', \'';
    my $res = $a->({ REQUEST_METHOD => 'GET', PATH_INFO => '/y',
                     QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
                     HTTP_HOST => 'l', 'psgi.url_scheme' => 'http',
                     'psgi.input' => $in });
    my %hh = @{ $res->[1] };
    ok !exists $hh{'Content-Encoding'},
       '...and records nothing, leaving the decision to the server';
}

done_testing;
