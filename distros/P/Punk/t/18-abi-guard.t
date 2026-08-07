#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Punk ();
use Test::More;
use PunkTest;
use File::Raw::JSON qw(file_json_decode);

# Phase 6: an API operation is routed and dispatched entirely in C through
# Open::API's ABI (oa_abi.h) - before hooks, guards, 413/501, validation and
# the controller. Open::API 0.04+ is a hard prerequisite, so there is no Perl
# fallback: the ABI is always there, and a version mismatch is a boot error.
# This checks the C dispatch is correct across every input location and error,
# and that the version guard rejects an incompatible table.

ok(Punk::_oa_available(), 'the Open::API C ABI is available');
is(Punk::_oa_abi_version(), 1, 'vendored at OA_ABI_VERSION 1');

# ---- a spec exercising every input location + error status ------------------
sub spec {
    return {
        openapi => '3.1.0',
        info    => { title => 'Guard', version => '1' },
        paths   => {
            '/pets' => {
                get => {
                    operationId => 'listPets',
                    parameters  => [ {
                        name => 'limit', in => 'query',
                        schema => { type => 'integer', minimum => 1,
                                    maximum => 100 },
                    } ],
                    responses => { 200 => { description => 'ok' } },
                },
                post => {
                    operationId => 'createPet',
                    requestBody => {
                        required => 1,
                        content  => { 'application/json' => { schema => {
                            type => 'object', required => ['name'],
                            properties => { name => { type => 'string',
                                                      minLength => 1 } },
                        } } },
                    },
                    responses => { 201 => { description => 'made' } },
                },
            },
            '/pets/{petId}' => {
                get => {
                    operationId => 'getPet',
                    parameters  => [
                        { name => 'petId', in => 'path', required => 1,
                          schema => { type => 'integer' } },
                        { name => 'X-Trace', in => 'header',
                          schema => { type => 'string', minLength => 3 } },
                    ],
                    responses => { 200 => { description => 'ok' } },
                },
            },
        },
    };
}

{
    package GuardApp;
    use Punk;
    api main::spec() => { handlers => {
        listPets  => sub { { limit => $_[0]->openapi->{query}{limit} } },
        getPet    => sub { my ($c) = @_;
                           { id => $c->param('petId'),
                             trace => $c->openapi->{header}{'X-Trace'} } },
        createPet => sub { my ($c) = @_; $c->status(201);
                           { made => $c->openapi->{body}{name} } },
        boom      => sub { die "kaboom\n" },
    } };
}
my $app = GuardApp->to_app;

# ---- the C dispatch is correct across the battery ---------------------------
sub body { file_json_decode($_[0][2][0]) }

{
    my $r = hit($app, path => '/pets', query => 'limit=5');
    is($r->[0], 200, 'happy query 200');
    is(body($r)->{limit}, 5, 'coerced query param reached the handler');
}
is(body(hit($app, path => '/pets'))->{limit}, undef,
    'an absent optional param is undef (no default injected)');
is(hit($app, path => '/pets', query => 'limit=huge')->[0], 400,
    'bad query type 400');
{
    my $r = hit($app, path => '/pets', query => 'limit=999');
    is($r->[0], 400, 'query out of range 400');
    is(body($r)->{errors}[0]{in}, 'query', 'error marked in=query');
}
{
    my $r = hit($app, path => '/pets/42');
    is($r->[0], 200, 'typed path param 200');
    is(body($r)->{id}, 42, 'petId coerced to an integer');
}
{
    my $r = hit($app, path => '/pets/notanint');
    is($r->[0], 400, 'bad path param 400');
    is(body($r)->{errors}[0]{in}, 'path', 'marked in=path');
}
{
    my $r = hit($app, path => '/pets/7', env => { HTTP_X_TRACE => 'abcd' });
    is($r->[0], 200, 'validated header 200');
    is(body($r)->{trace}, 'abcd', 'header reached the handler');
}
{
    my $r = hit($app, path => '/pets/7', env => { HTTP_X_TRACE => 'ab' });
    is($r->[0], 400, 'header too short 400');
    is(body($r)->{errors}[0]{in}, 'header', 'marked in=header');
}
{
    my $r = hit($app, method => 'POST', path => '/pets',
        body => '{"name":"Rex"}');
    is($r->[0], 201, 'body happy keeps the handler status');
    is(body($r)->{made}, 'Rex', 'created from the validated body');
}
{
    my $r = hit($app, method => 'POST', path => '/pets', body => '{}');
    is($r->[0], 400, 'invalid body 400');
    is(body($r)->{errors}[0]{in}, 'body', 'marked in=body');
}
is(hit($app, method => 'POST', path => '/pets', body => 'not json')->[0], 400,
    'unparseable body 400');
is(hit($app, path => '/nope')->[0], 404, 'unknown path 404');
{
    my $r = hit($app, method => 'DELETE', path => '/pets');
    is($r->[0], 405, 'wrong method 405');
    my %h = @{ $r->[1] };
    is($h{Allow}, 'GET, POST', 'with the Allow header');
}

# ---- guards and dies flow through the C dispatcher --------------------------
{
    package GuardApp2;
    use Punk;
    my $api = under('/api')->api(main::spec() => {
        handlers => {
            getPet    => sub { { id => $_[0]->param('petId') } },
            listPets  => sub { [] },
            createPet => sub { {} },
        },
        under    => { '/pets' => sub {
            my ($c) = @_;
            return $c->json({ error => 'nope' }, 403)
                unless ($c->req->header('x-key') // '') eq 'ok';
            return;
        } },
    });
}
my $app2 = GuardApp2->to_app;
is(hit($app2, path => '/api/pets/1')->[0], 403, 'a guard short-circuits (C)');
is(hit($app2, path => '/api/pets/1', env => { HTTP_X_KEY => 'ok' })->[0], 200,
    'and passes with the header');

# ---- a version mismatch is a hard error (no fallback) -----------------------
# PUNK_FAKE_OA_BAD makes the C resolver reject the table as if its abi_version
# did not match. In a child (the one-shot resolve is isolated) the ABI must
# then look unavailable - a real app would croak rather than silently fall back.
{
    local $ENV{PUNK_FAKE_OA_BAD} = 1;
    my $status = system($^X, '-Mblib', '-MPunk', '-e',
        'exit(Punk::_oa_available() ? 0 : 3)');
    is($status >> 8, 3,
        'a simulated version mismatch leaves the ABI unavailable (would croak)');
}

done_testing();
