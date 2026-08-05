#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;

# The compiled operation table: op ids/methods/paths, the path-item +
# operation parameter merge, forced-required path params, body content types
# and required flag, response statuses, and the operationId croaks.

my $api = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");
isa_ok($api, 'Open::API');

# ---- operations() -----------------------------------------------------------
{
    my $ops = $api->operations;
    is(scalar @$ops, 4, 'four operations compiled');
    my %by = map { $_->{operationId} => $_ } @$ops;
    is_deeply([sort keys %by], [qw(createPet deletePet getPet listPets)],
        'operation ids');
    is($by{listPets}{method},  'get',           'listPets method');
    is($by{createPet}{method}, 'post',          'createPet method');
    is($by{getPet}{path},      '/pets/{petId}', 'getPet path template');
}

# ---- operation($id) ---------------------------------------------------------
{
    my $op = $api->operation('getPet');
    ok($op, 'operation(getPet)');

    # petId comes from the path-item level (merge) and is forced required
    is(scalar @{ $op->{params}{path} }, 1, 'one path param (merged from item)');
    is($op->{params}{path}[0]{name}, 'petId', 'petId name');
    ok($op->{params}{path}[0]{required}, 'path param forced required');

    is(scalar @{ $op->{params}{header} }, 1, 'one header param');
    is($op->{params}{header}[0]{name}, 'X-Request-Id', 'header param name');
    ok(!$op->{params}{header}[0]{required}, 'header param optional');

    is_deeply([sort @{ $op->{responses} }], ['200'],
        'only json responses recorded (404 has no content)');
}

{
    my $op = $api->operation('listPets');
    is(scalar @{ $op->{params}{query} }, 2, 'two query params');
    my %q = map { $_->{name} => $_ } @{ $op->{params}{query} };
    ok(exists $q{limit} && exists $q{tags}, 'query param names');
}

{
    my $op = $api->operation('createPet');
    ok($op->{body}{required}, 'body required flag');
    is_deeply([sort @{ $op->{body}{content} }],
              ['application/json', 'text/plain'],
        'body content types (json compiled, text pass-through)');
    is_deeply($op->{responses}, ['201'], 'createPet response statuses');
}

{
    my $op = $api->operation('deletePet');
    is(scalar @{ $op->{params}{cookie} }, 1, 'one cookie param');
    ok($op->{params}{cookie}[0]{required}, 'cookie param required');
    is_deeply($op->{responses}, [], '204 has no json content');
}

is($api->operation('nope'), undef, 'unknown operationId is undef');

# ---- croaks -----------------------------------------------------------------
{
    my %base = (
        openapi => '3.1.0',
        info    => { title => 'x', version => '1' },
    );
    my $err;

    eval { Open::API->new(spec => { %base,
        paths => { '/a' => { get => { responses => {} } } } }) } or $err = $@;
    like($err, qr/has no operationId/, 'missing operationId croaks');

    undef $err;
    eval { Open::API->new(spec => { %base, paths => {
        '/a' => { get => { operationId => 'dup', responses => {} } },
        '/b' => { get => { operationId => 'dup', responses => {} } },
    } }) } or $err = $@;
    like($err, qr/duplicate operationId 'dup'/, 'duplicate operationId croaks');
}

done_testing();
