#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;

# validate_request(): coercion, defaults, required, the four locations,
# arrayref query params, percent-decoding, and the error shape.

my $api = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");

# ---- happy path: path + query + header ----------------------------------------
{
    my ($ok, $params) = $api->validate_request('getPet', {
        path   => { petId => '42' },
        header => { 'x-request-id' => 'abcd1234' },
    });
    is($ok, 1, 'getPet validates');
    is($params->{path}{petId}, 42, 'path param present (coerced string ok)');
    is($params->{header}{'X-Request-Id'}, 'abcd1234',
        'header stored under its declared name');
}

# ---- query: string form, defaults, arrays ---------------------------------------
{
    my ($ok, $params) = $api->validate_request('listPets', {
        query => 'limit=25&tags=a&tags=b&extra=zz',
    });
    is($ok, 1, 'listPets validates from a query string');
    is($params->{query}{limit}, 25, 'limit parsed');
    is_deeply($params->{query}{tags}, ['a', 'b'], 'repeat key -> arrayref');
    is($params->{query}{extra}, 'zz', 'undeclared query key passes through');
}
{
    my ($ok, $params) = $api->validate_request('listPets', { query => '' });
    is($ok, 1, 'no query params still valid (none required)');
    is($params->{query}{limit}, undef,
        'no default injected when the parameter is absent entirely');
}
{
    my ($ok, $params) = $api->validate_request('listPets', {
        query => { limit => '10', tags => ['x'] },
    });
    is($ok, 1, 'query accepted as a pre-parsed hashref');
    is_deeply($params->{query}{tags}, ['x'], 'hashref arrays pass through');
}

# ---- percent-decoding ------------------------------------------------------------
{
    my ($ok, $params) = $api->validate_request('listPets', {
        query => 'extra=hello%20world+x',
    });
    is($params->{query}{extra}, 'hello world x', 'query %XX and + decoded');
}

# ---- failures ---------------------------------------------------------------------
{
    my ($ok, $errs) = $api->validate_request('getPet', {
        path => { petId => 'abc' },
    });
    is($ok, 0, 'bad path param fails');
    is($errs->[0]{in},   'path',  'error carries in=path');
    is($errs->[0]{name}, 'petId', 'error carries the param name');
    ok($errs->[0]{message}, 'error has a message');
}
{
    my ($ok, $errs) = $api->validate_request('getPet', { });
    is($ok, 0, 'missing required path param fails');
    is($errs->[0]{keyword}, 'required', 'keyword is required');
}
{
    my ($ok, $errs) = $api->validate_request('listPets', {
        query => 'limit=500',
    });
    is($ok, 0, 'limit over maximum fails');
    is($errs->[0]{in}, 'query', 'in=query');
    is($errs->[0]{name}, 'limit', 'name=limit');
}
{
    my ($ok, $errs) = $api->validate_request('deletePet', {
        path => { petId => '1' },
    });
    is($ok, 0, 'missing required cookie fails');
    is($errs->[0]{in}, 'cookie', 'in=cookie');
}
{
    my ($ok, $params) = $api->validate_request('deletePet', {
        path   => { petId => '1' },
        header => { cookie => 'session=s3cr3t; other=x' },
    });
    is($ok, 1, 'cookie parsed from the Cookie header');
    is($params->{cookie}{session}, 's3cr3t', 'declared cookie extracted');
}

# ---- multiple errors collected -----------------------------------------------------
{
    my ($ok, $errs) = $api->validate_request('getPet', {
        path   => { petId => 'abc' },
        header => { 'x-request-id' => 'ab' },
    });
    is($ok, 0, 'two failures fail');
    is(scalar @$errs, 2, 'both errors collected');
}

# ---- unknown op croaks ---------------------------------------------------------------
{
    my $err;
    eval { $api->validate_request('nope', {}) } or $err = $@;
    like($err, qr/unknown operationId 'nope'/, 'unknown op croaks');
}

done_testing();
