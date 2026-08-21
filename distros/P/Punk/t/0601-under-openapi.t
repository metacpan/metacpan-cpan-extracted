#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Raw::JSON qw(file_json_decode);
use MIME::Base64 qw(encode_base64);

# under x OpenAPI: scope guards apply to every operation, the mount's
# under option adds per-spec-prefix guards, and the spec's security
# requirements compile to guards (401 before validation, coverage
# checked at boot).

our @order;

sub spec {
    return {
        openapi => '3.1.0',
        info    => { title => 'Guarded', version => '1' },
        components => { securitySchemes => {
            key   => { type => 'apiKey', in => 'header', name => 'X-Key' },
            basic => { type => 'http', scheme => 'basic' },
        } },
        paths => {
            '/pets' => { get => {
                operationId => 'listPets',
                security    => [ { key => [] } ],
                parameters  => [ { name => 'limit', in => 'query',
                    schema => { type => 'integer' } } ],
                responses   => { 200 => { description => 'ok' } },
            } },
            '/pets/manage' => { post => {
                operationId => 'managePets',
                security    => [ { key => [] }, { basic => [] } ],
                responses   => { 200 => { description => 'ok' } },
            } },
            '/open' => { get => {
                operationId => 'openOp',
                security    => [],
                responses   => { 200 => { description => 'ok' } },
            } },
        },
    };
}

{
    package GuardedApp;
    use Punk;
    my $v1 = under '/v1' => sub {
        push @main::order, 'scope';
        return;
    };
    $v1->api(main::spec() => {
        handlers => {
            listPets   => sub { push @main::order, 'handler';
                                { auth => $_[0]->stash->{auth} } },
            managePets => sub { { auth => $_[0]->stash->{auth} } },
            openOp     => sub { { open => 1 } },
        },
        security => {
            key   => sub { my ($cred, $c, $op, $scopes) = @_;
                           push @main::order, 'checker';
                           $cred eq 'sekrit' ? { via => 'key', op => $op } : 0 },
            basic => sub { my ($cred) = @_;
                           $cred eq 'user:pass' ? { via => 'basic' } : 0 },
        },
        under => {
            '/pets/manage' => sub {
                push @main::order, 'prefix';
                return $_[0]->json({ errors => [ { message => 'no manage' } ] },
                                   403)
                    if $_[0]->req->header('x-deny');
                return;
            },
        },
    });
    package main;
}

my $app = GuardedApp->to_app;

# ---- security guard: 401 before validation, stash on success -----------------
{
    @order = ();
    my $r = hit($app, path => '/v1/pets', query => 'limit=notanint');
    is($r->[0], 401, 'no credential: 401 (and before validation - the bad '
        . 'query never got checked)');
    is_deeply(\@order, [qw(scope)], 'scope guard ran, checker/handler not');
}
{
    @order = ();
    my $r = hit($app, path => '/v1/pets',
        env => { HTTP_X_KEY => 'wrong' });
    is($r->[0], 401, 'bad credential: 401');
    is_deeply(\@order, [qw(scope checker)], 'checker ran and rejected');
}
{
    @order = ();
    my $r = hit($app, path => '/v1/pets', env => { HTTP_X_KEY => 'sekrit' });
    is($r->[0], 200, 'good credential authorizes');
    is_deeply(\@order, [qw(scope checker handler)],
        'scope guard, then security, then handler');
    my $d = file_json_decode($r->[2][0]);
    is($d->{auth}{key}{via}, 'key', 'checker result stashed under auth');
    is($d->{auth}{key}{op}, 'listPets', 'checker saw the operationId');
}
{
    my $r = hit($app, path => '/v1/pets',
        query => 'limit=notanint', env => { HTTP_X_KEY => 'sekrit' });
    is($r->[0], 400, 'authorized but invalid: validation still runs after');
}

# ---- security alternatives are OR --------------------------------------------
{
    my $r = hit($app, method => 'POST', path => '/v1/pets/manage',
        env => { HTTP_AUTHORIZATION =>
                 'Basic ' . encode_base64('user:pass', '') });
    is($r->[0], 200, 'second alternative (basic) authorizes');
    is(file_json_decode($r->[2][0])->{auth}{basic}{via}, 'basic',
        'basic checker result stashed');
}

# ---- empty security disables auth --------------------------------------------
is(hit($app, path => '/v1/open')->[0], 200,
    'security: [] disables auth for the operation');

# ---- per-prefix under guards --------------------------------------------------
{
    @order = ();
    my $r = hit($app, method => 'POST', path => '/v1/pets/manage',
        env => { HTTP_X_KEY => 'sekrit', HTTP_X_DENY => 1 });
    is($r->[0], 403, 'prefix guard short-circuits');
    is_deeply(\@order, [qw(scope checker prefix)],
        'prefix guard runs after security');
}
{
    my $r = hit($app, path => '/v1/pets', env => { HTTP_X_KEY => 'sekrit' });
    is($r->[0], 200, 'the prefix guard does not apply outside its prefix');
}

# ---- coverage croak -----------------------------------------------------------
{
    package Uncovered;
    use Punk;
    api main::spec() => { handlers => {
        listPets => sub { }, managePets => sub { }, openOp => sub { } } };
    package main;
    my $err = '';
    eval { Uncovered->to_app } or $err = $@;
    like($err, qr/requires securityScheme 'key' but no checker/,
        'a required scheme without a checker croaks at to_app');
}

done_testing();
