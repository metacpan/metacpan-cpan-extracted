#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;
use File::Raw::JSON qw(file_json_decode);

# The PSGI app driven with in-process env hashes: happy paths, auto-JSON
# encoding, triplet pass-through, and every error status.

my $api = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");

# a handler that lives in a package, referenced by name below
{
    package My::Pets;
    sub list { [ { id => 9, name => 'package' } ] }
}

my %pets = ( 1 => { id => 1, name => 'rex' } );

my $app = $api->to_app(handlers => {
    listPets  => sub { [ values %pets ] },                       # auto-JSON
    getPet    => sub {
        my ($p) = @_;
        my $pet = $pets{ $p->{path}{petId} };
        return $pet ? $pet : [ 404, ['Content-Type' => 'text/plain'], ['gone'] ];
    },
    createPet => sub {
        my ($p) = @_;
        my $pet = { id => 99, name => $p->{body}{name} };
        [ 201, ['Content-Type' => 'application/json'],
               [ File::Raw::JSON::file_json_encode($pet) ] ];
    },
    deletePet => sub { die "boom\n" },                            # 500 path
    # no ping handler in petstore; use listPets etc.
});

sub req {
    my (%o) = @_;
    my $body = defined $o{body} ? $o{body} : '';
    open my $in, '<', \$body or die;
    return $app->({
        REQUEST_METHOD => $o{method} || 'GET',
        PATH_INFO      => $o{path}   || '/',
        QUERY_STRING   => $o{query}  || '',
        CONTENT_TYPE   => $o{ctype}  || ($body ne '' ? 'application/json' : ''),
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
        %{ $o{env} || {} },
    });
}

sub body_json { file_json_decode($_[0][2][0]) }

# ---- auto-JSON 200 -----------------------------------------------------------
{
    my $r = req(path => '/pets');
    is($r->[0], 200, 'listPets 200');
    is_deeply(body_json($r), [ { id => 1, name => 'rex' } ], 'auto-encoded JSON');
    my %h = @{ $r->[1] };
    is($h{'Content-Type'}, 'application/json', 'json content type');
}

# ---- validated params reach the handler ----------------------------------------
{
    my $r = req(path => '/pets/1');
    is($r->[0], 200, 'getPet 200');
    is(body_json($r)->{name}, 'rex', 'handler saw coerced petId');
}

# ---- handler triplet pass-through ------------------------------------------------
{
    my $r = req(path => '/pets/7');
    is($r->[0], 404, 'handler triplet passes through untouched');
    is($r->[2][0], 'gone', 'triplet body preserved');
}

# ---- body + 201 --------------------------------------------------------------------
{
    my $r = req(method => 'POST', path => '/pets', body => '{"name":"fido"}');
    is($r->[0], 201, 'createPet 201');
    is(body_json($r)->{name}, 'fido', 'created from validated body');
}

# ---- 400 ------------------------------------------------------------------------------
{
    my $r = req(method => 'POST', path => '/pets', body => '{"tag":"x"}');
    is($r->[0], 400, 'invalid body 400');
    my $e = body_json($r);
    is($e->{errors}[0]{in}, 'body', '400 body carries the error shape');
}
{
    my $r = req(path => '/pets/abc');
    is($r->[0], 400, 'bad path param 400');
}
{
    my $r = req(path => '/pets', query => 'limit=1000');
    is($r->[0], 400, 'bad query param 400');
}

# ---- 404 / 405 + Allow ------------------------------------------------------------------
{
    my $r = req(path => '/nope');
    is($r->[0], 404, 'unknown path 404');
}
{
    my $r = req(method => 'PATCH', path => '/pets');
    is($r->[0], 405, 'wrong method 405');
    my %h = @{ $r->[1] };
    is($h{Allow}, 'GET, POST', 'Allow header set');
}

# ---- 500 on handler die -------------------------------------------------------------------
{
    my $r = req(method => 'DELETE', path => '/pets/1',
                env => { HTTP_COOKIE => 'session=x' });
    is($r->[0], 500, 'handler die is a 500');
    like(body_json($r)->{errors}[0]{message}, qr/boom/, 'die message captured');
}

# ---- 501 when no handler -------------------------------------------------------------------
{
    my $app2 = $api->to_app(handlers => {});
    open my $in, '<', \(my $b = '') or die;
    my $r = $app2->({ REQUEST_METHOD => 'GET', PATH_INFO => '/pets',
                      QUERY_STRING => '', 'psgi.input' => $in });
    is($r->[0], 501, 'matched op without a handler is a 501');
}

# ---- handlers as fully qualified package sub names ------------------------------------------
{
    my $app3 = $api->to_app(handlers => {
        listPets => 'My::Pets::list',                 # string, resolved now
        getPet   => sub { { id => 1, name => 'rex' } },
    });
    open my $in, '<', \(my $b = '') or die;
    my $r = $app3->({ REQUEST_METHOD => 'GET', PATH_INFO => '/pets',
                      QUERY_STRING => '', 'psgi.input' => $in });
    is($r->[0], 200, 'package-sub handler dispatches');
    is(body_json($r)->[0]{name}, 'package', 'ran the named sub');

    my $err;
    eval { $api->to_app(handlers => { listPets => 'No::Such::sub_here' }) }
        or $err = $@;
    like($err, qr/names no such sub 'No::Such::sub_here'/,
        'unknown sub name croaks at to_app time');

    undef $err;
    eval { $api->to_app(handlers => { listPets => [1, 2] }) } or $err = $@;
    like($err, qr/coderef or a fully qualified sub name/,
        'bad handler value croaks');
}

# ---- validate_responses --------------------------------------------------------------------
{
    my $lying = $api->to_app(validate_responses => 1, handlers => {
        getPet => sub { { wrong => 'shape' } },   # not a Pet
    });
    open my $in, '<', \(my $b = '') or die;
    my $r = $lying->({ REQUEST_METHOD => 'GET', PATH_INFO => '/pets/1',
                       QUERY_STRING => '', 'psgi.input' => $in });
    is($r->[0], 500, 'response validation catches a lying handler');
    is(body_json($r)->{errors}[0]{in}, 'response', 'error marked in=response');
}

done_testing();
