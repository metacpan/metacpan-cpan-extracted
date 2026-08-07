#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Raw::JSON qw(file_json_decode);

# The api mount: spec-first operations dispatched by operationId, with
# Open::API routing + validation in C and error shapes matching
# Open::API::Plack.

sub petstore {
    return {
        openapi => '3.1.0',
        info    => { title => 'Petstore', version => '1' },
        paths   => {
            '/pets' => {
                get => {
                    operationId => 'listPets',
                    parameters  => [ {
                        name => 'limit', in => 'query',
                        schema => { type => 'integer', minimum => 1,
                                    maximum => 100, default => 10 },
                    } ],
                    responses => { 200 => { description => 'ok' } },
                },
                post => {
                    operationId => 'createPet',
                    requestBody => {
                        required => 1,
                        content  => { 'application/json' => {
                            schema => {
                                type => 'object',
                                required => ['name'],
                                properties => {
                                    name => { type => 'string',
                                              minLength => 1 } },
                            } } },
                    },
                    responses => { 201 => { description => 'made' } },
                },
            },
            '/pets/{petId}' => {
                get => {
                    operationId => 'getPet',
                    parameters  => [ {
                        name => 'petId', in => 'path', required => 1,
                        schema => { type => 'integer' },
                    } ],
                    responses => { 200 => { description => 'ok' } },
                },
            },
        },
    };
}

# ---- happy paths, typed params, auto-JSON ------------------------------------
{
    package ApiApp;
    use Punk;
    api main::petstore() => { handlers => {
        listPets  => sub {
            my ($c) = @_;
            return { limit => $c->openapi->{query}{limit},
                     via_param => $c->param('limit') };
        },
        getPet    => sub { { id => $_[0]->param('petId') } },
        createPet => sub {
            my ($c) = @_;
            $c->status(201);
            return { name => $c->openapi->{body}{name} };
        },
    } };
    package main;

    my $app = ApiApp->to_app;

    my $d = file_json_decode(hit($app, path => '/pets',
        query => 'limit=5')->[2][0]);
    is($d->{limit}, 5, 'validated query param, coerced');
    is($d->{via_param}, 5, '$c->param reads openapi params first');

    $d = file_json_decode(hit($app, path => '/pets')->[2][0]);
    is($d->{limit}, undef,
        'absent optional param is undef (the core injects no default, '
        . 'matching the Catalyst adapter)');

    $d = file_json_decode(hit($app, path => '/pets/7')->[2][0]);
    is($d->{id}, 7, 'typed path capture');

    my $r = hit($app, method => 'POST', path => '/pets',
        body => '{"name":"rex"}');
    is($r->[0], 201, 'handler status honoured');
    is(file_json_decode($r->[2][0])->{name}, 'rex', 'validated body');

    # ---- validation failures: 400 with the Plack error shape ----------------
    $r = hit($app, path => '/pets', query => 'limit=999');
    is($r->[0], 400, 'out-of-range query is a 400');
    my $err = file_json_decode($r->[2][0]);
    ok(ref $err->{errors} eq 'ARRAY' && $err->{errors}[0]{message},
        'error shape matches Open::API::Plack');

    $r = hit($app, method => 'POST', path => '/pets', body => '{}');
    is($r->[0], 400, 'missing required body field is a 400');

    $r = hit($app, path => '/pets/notanumber');
    is($r->[0], 400, 'bad path param type is a 400');

    # ---- routing edges -------------------------------------------------------
    is(hit($app, path => '/nope')->[0], 404, 'unknown path 404s');
    $r = hit($app, method => 'DELETE', path => '/pets');
    is($r->[0], 405, 'undeclared method on a spec path is a 405');
    my %h = @{ $r->[1] };
    is($h{Allow}, 'GET, POST', 'Allow comes from the spec');

    my $head = hit($app, method => 'HEAD', path => '/pets');
    is($head->[0], 200, 'HEAD falls back to the GET operation');
    is($head->[2][0], '', 'HEAD body stripped');
}

# ---- prefix mounts through a scope -------------------------------------------
{
    package PrefixApp;
    use Punk;
    my $v1 = under '/v1';
    $v1->api(main::petstore() => { handlers => {
        listPets  => sub { { where => 'v1' } },
        getPet    => sub { {} }, createPet => sub { {} },
    } });
    get '/pets' => sub { $_[0]->text('web pets') };
    package main;

    my $app = PrefixApp->to_app;
    is(file_json_decode(hit($app, path => '/v1/pets')->[2][0])->{where},
        'v1', 'spec routes serve under the scope prefix');
    is(hit($app, path => '/pets')->[2][0], 'web pets',
        'web routes outside the prefix are untouched');
    is(hit($app, path => '/v1/nope')->[0], 404,
        'unknown paths under the prefix still 404');
}

# ---- stub, 413, on_error, boot croaks ----------------------------------------
{
    package StubApp;
    use Punk;
    api main::petstore() => { stub => 1, max_body_size => 10,
        handlers => { listPets => sub { die "handler bang\n" } },
        on_error => sub { my ($c, $err) = @_;
                          $c->json({ mount_rescued => "$err" }, 599) },
    };
    package main;

    my $app = StubApp->to_app;
    is(hit($app, path => '/pets/1')->[0], 501,
        'stub => 1: unimplemented operation answers 501');
    my $r = hit($app, method => 'POST', path => '/pets',
        body => '{"name":"a very long body"}');
    is($r->[0], 413, 'max_body_size answers 413');
    $r = hit($app, path => '/pets');
    is($r->[0], 599, 'mount-level on_error takes over');
    like($r->[2][0], qr/handler bang/, 'and sees the error');
}

{
    package MissingOp;
    use Punk;
    api main::petstore() => { handlers => { listPets => sub { } } };
    package main;
    my $err = '';
    eval { MissingOp->to_app } or $err = $@;
    like($err, qr/operation '\w+' has no controller method/,
        'an unimplemented operation croaks at to_app without stub');
}
{
    package BadOpt;
    use Punk;
    package main;
    my $err = '';
    eval { BadOpt::punk_app()->api(petstore(), { nope => 1 }); 1 }
        or $err = $@;
    like($err, qr/unknown api mount option\(s\) nope/,
        'unknown mount options croak at registration');
}

done_testing();
