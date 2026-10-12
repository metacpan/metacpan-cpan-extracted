#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;
use Open::API::Plack;
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

my $app = Open::API::Plack->new(api => $api, handlers => {
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
})->to_app;

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
    my $app2 = Open::API::Plack->new(api => $api, handlers => {})->to_app;
    open my $in, '<', \(my $b = '') or die;
    my $r = $app2->({ REQUEST_METHOD => 'GET', PATH_INFO => '/pets',
                      QUERY_STRING => '', 'psgi.input' => $in });
    is($r->[0], 501, 'matched op without a handler is a 501');
}

# ---- handlers as fully qualified package sub names ------------------------------------------
{
    my $app3 = Open::API::Plack->new(api => $api, handlers => {
        listPets => 'My::Pets::list',                 # string, resolved now
        getPet   => sub { { id => 1, name => 'rex' } },
    })->to_app;
    open my $in, '<', \(my $b = '') or die;
    my $r = $app3->({ REQUEST_METHOD => 'GET', PATH_INFO => '/pets',
                      QUERY_STRING => '', 'psgi.input' => $in });
    is($r->[0], 200, 'package-sub handler dispatches');
    is(body_json($r)->[0]{name}, 'package', 'ran the named sub');

    my $err;
    eval { Open::API::Plack->new(api => $api, handlers => { listPets => 'No::Such::sub_here' })->to_app }
        or $err = $@;
    like($err, qr/names no such sub 'No::Such::sub_here'/,
        'unknown sub name croaks at to_app time');

    undef $err;
    eval { Open::API::Plack->new(api => $api, handlers => { listPets => [1, 2] })->to_app } or $err = $@;
    like($err, qr/coderef or a fully qualified sub name/,
        'bad handler value croaks');
}

# ---- validate_responses --------------------------------------------------------------------
{
    my $lying = Open::API::Plack->new(api => $api, validate_responses => 1, handlers => {
        getPet => sub { { wrong => 'shape' } },   # not a Pet
    })->to_app;
    open my $in, '<', \(my $b = '') or die;
    my $r = $lying->({ REQUEST_METHOD => 'GET', PATH_INFO => '/pets/1',
                       QUERY_STRING => '', 'psgi.input' => $in });
    is($r->[0], 500, 'response validation catches a lying handler');
    is(body_json($r)->{errors}[0]{in}, 'response', 'error marked in=response');
}

# ---- a Swagger 2.0 document serves like any other ---------------------------------
# One document, converted at load; every status the app answers must come out
# the same as it would from the 3.0 twin. Driven in-process, no server.
{
    my $api20 = Open::API->new(spec => {
        swagger  => '2.0',
        info     => { title => 'P', version => '1' },
        consumes => [ 'application/json' ],
        produces => [ 'application/json' ],
        securityDefinitions => { B => { type => 'basic' } },
        definitions => { NewPet => { type => 'object', required => ['name'],
                                     properties => { name => { type => 'string' } } } },
        paths => {
            '/pets' => {
                post => { operationId => 'addPet',
                    parameters => [ { name => 'pet', in => 'body', required => \1,
                                      schema => { '$ref' => '#/definitions/NewPet' } } ],
                    responses => { 200 => { description => 'ok', schema => { '$ref' => '#/definitions/NewPet' } } } },
                get  => { operationId => 'listPets',
                    parameters => [ { name => 'limit', in => 'query', type => 'integer' } ],
                    responses => { 200 => { description => 'ok' } } },
            },
            '/pets/{id}' => {
                get => { operationId => 'getPet',
                    parameters => [ { name => 'id', in => 'path', required => \1, type => 'integer' } ],
                    responses => { 200 => { description => 'ok' } } },
            },
            '/secret' => {
                get => { operationId => 'secret', security => [ { B => [] } ],
                    responses => { 200 => { description => 'ok' } } },
            },
        },
    });
    my $app20 = Open::API::Plack->new(api => $api20,
        handlers => {
            addPet   => sub { my ($p) = @_; { name => $p->{body}{name} } },
            listPets => sub { [] },
            getPet   => sub { my ($p) = @_; { id => $p->{path}{id} } },
            secret   => sub { { ok => 1 } },
        },
        security => { B => sub { $_[0] eq 'alice:pw' ? { u => 'alice' } : 0 } },
    )->to_app;
    my $r20 = sub {
        my (%o) = @_;
        my $body = defined $o{body} ? $o{body} : '';
        open my $in, '<', \$body or die;
        return $app20->({
            REQUEST_METHOD => $o{method} || 'GET',
            PATH_INFO      => $o{path}   || '/',
            QUERY_STRING   => $o{query}  || '',
            CONTENT_TYPE   => $o{ctype}  || ($body ne '' ? 'application/json' : ''),
            CONTENT_LENGTH => length $body,
            'psgi.input'   => $in,
            %{ $o{env} || {} },
        });
    };
    is($r20->(path => '/pets/7')->[0], 200, '2.0: a routed path with an integer id is 200');
    is($r20->(path => '/pets/x')->[0], 400, '2.0: a non-integer id is a 400 (the inline type validates)');
    is($r20->(path => '/nowhere')->[0], 404, '2.0: an unknown path is 404');
    {
        my $r = $r20->(method => 'PATCH', path => '/pets');
        is($r->[0], 405, '2.0: an undeclared method is 405');
        my %h = @{ $r->[1] };
        is(join(',', sort split /,\s*/, $h{Allow}), 'GET,POST', '2.0: ...with Allow from the path item');
    }
    {   # 415 is the opt-in content negotiation (t/18); by default an undeclared
        # body type is a 400 naming the content type, for 3.x and 2.0 alike
        my $r = $r20->(method => 'POST', path => '/pets', body => '<a/>', ctype => 'application/xml');
        is($r->[0], 400, '2.0: a body type not in consumes is refused');
        like($r->[2][0], qr/undeclared request content type/, '2.0: ...naming the content type');
    }
    is($r20->(method => 'POST', path => '/pets', body => '{}')->[0], 400,
       '2.0: a body missing a required property is 400');
    {
        my $r = $r20->(method => 'POST', path => '/pets', body => '{"name":"fido"}');
        is($r->[0], 200, '2.0: a conforming body reaches the handler');
        is(body_json($r)->{name}, 'fido', '2.0: ...which saw the decoded body');
    }
    is($r20->(path => '/secret')->[0], 401, '2.0: a basic scheme refuses a bare request');
    is($r20->(path => '/secret', env => { HTTP_AUTHORIZATION => 'Basic YWxpY2U6cHc=' })->[0], 200,
       '2.0: ...and admits the right credential');
    is($r20->(path => '/secret', env => { HTTP_AUTHORIZATION => 'Basic Ym9iOm5vcGU=' })->[0], 401,
       '2.0: ...and refuses the wrong one');
}

done_testing();
