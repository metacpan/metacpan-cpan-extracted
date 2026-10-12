#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Open::API;

# Swagger 2.0 conversion (include/oa_swagger2.h), the twin of t/28-openapi30.t.
#
# A 2.0 Schema Object is a draft-04 subset of 3.0's, so the pre-pass brings a
# 2.0 document to 3.0 SHAPE and the 3.0 pass (oa_normalize.h) does the schema
# work it already does. These tests assert through the public API first - what
# the validator accepts and refuses - and read ->spec only to pin the shape a
# consumer (the docs UI, the mock, Maat) is entitled to find. The last group
# is the idempotency contract: the normalised document keeps `swagger: "2.0"`,
# so feeding ->spec back through new() runs the whole pipeline again, and
# twice must equal once.

my $TRUE  = \1;
my $FALSE = \0;
my $JSON  = { 'content-type' => 'application/json' };

# a 2.0 document with one POST whose body parameter carries `$schema`
sub api_for {
    my ($schema, %extra) = @_;
    return Open::API->new(spec => {
        swagger  => '2.0',
        info     => { title => 'T', version => '1.0.0' },
        consumes => [ 'application/json' ],
        paths    => { '/t' => { post => {
            operationId => 'post_t',
            parameters  => [ { name => 'body', in => 'body', required => $TRUE,
                               schema => $schema } ],
            responses   => { 200 => { description => 'ok' } },
        } } },
        %extra,
    });
}

sub accepts {
    my ($api, $body) = @_;
    my ($ok) = $api->validate_request(post_t => { header => $JSON, body => $body });
    return $ok ? 1 : 0;
}

sub body_schema {
    my ($api) = @_;
    return $api->spec->{paths}{'/t'}{post}{requestBody}{content}{'application/json'}{schema};
}

# ---- the 3.0 pass's rules, under a 2.0 root ------------------------------------
{
    my $api = api_for({ type => 'object', properties => {
        n => { type => 'integer', minimum => 5, exclusiveMinimum => $TRUE } } });
    is(accepts($api, '{"n":5}'), 0, 'draft-04 boolean exclusiveMinimum excludes the bound');
    is(accepts($api, '{"n":6}'), 1, '...and admits the next value');
    is(body_schema($api)->{properties}{n}{exclusiveMinimum}, 5,
       '->spec carries the 2020-12 numeric form');
}
{
    my $api = api_for({ type => 'array', items => [ { type => 'string' }, { type => 'integer' } ] });
    is(accepts($api, '["a",1]'), 1, 'a draft-04 tuple validates positionally');
    is(accepts($api, '[1,"a"]'), 0, '...and refuses the positions swapped');
    ok(ref body_schema($api)->{prefixItems} eq 'ARRAY', '->spec carries prefixItems');
}
{
    my $api = api_for({ type => 'object', properties => {
        b => { type => 'string', format => 'byte' },
        f => { type => 'string', format => 'binary' },
        e => { type => 'string', example => 'x' } } });
    my $p = body_schema($api)->{properties};
    is($p->{b}{contentEncoding}, 'base64', 'format byte becomes contentEncoding');
    ok($p->{f}{contentMediaType}, 'format binary becomes contentMediaType');
    is_deeply($p->{e}{examples}, ['x'], 'a schema example becomes the examples list');
}
{
    my $api = api_for({ type => 'object', properties => {
            a => { '$ref' => '#/definitions/S', maxLength => 1 } } },
        definitions => { S => { type => 'string' } });
    is(accepts($api, '{"a":"long enough to fail maxLength"}'), 1,
       'draft-04: assertions beside a $ref are ignored');
    is(body_schema($api)->{properties}{a}{'$ref'}, '#/components/schemas/S',
       'the $ref was rewritten to its 3.x home');
}

# ---- the 2.0 rules of this phase ------------------------------------------------
{
    my $err;
    eval { api_for({ type => [ 'string', 'null' ] }) } or $err = $@;
    like($err, qr/type must be a string/, 'a type array is refused: 2.0 supports one type');
}
{
    my $api = api_for({ type => 'object', properties => {
        s => { type => 'string', nullable => $TRUE } } });
    is(accepts($api, '{"s":null}'), 0, 'nullable is not a 2.0 keyword: null is refused');
    is(accepts($api, '{"s":"x"}'), 1, '...and the type is unchanged');
    my $s = body_schema($api)->{properties}{s};
    ok(!exists $s->{nullable}, 'the keyword is dropped from ->spec');
    is($s->{type}, 'string', '...leaving a single type, never an array');
}
{
    my %defs = (
        Pet => { type => 'object', discriminator => 'kind', required => ['kind'],
                 properties => { kind => { type => 'string' } } },
        Dog => { allOf => [ { '$ref' => '#/definitions/Pet' },
                            { type => 'object', required => ['bark'],
                              properties => { bark => { type => 'string' } } } ] },
        Cat => { allOf => [ { '$ref' => '#/definitions/Pet' },
                            { type => 'object', required => ['meow'],
                              properties => { meow => { type => 'boolean' } } } ] },
    );
    my $api = api_for({ '$ref' => '#/definitions/Pet' }, definitions => \%defs);
    is(accepts($api, '{"kind":"Dog","bark":"w"}'), 1, 'a string discriminator selects Dog');
    is(accepts($api, '{"kind":"Dog"}'), 0, '...and Dog\'s own constraints apply');
    is(accepts($api, '{"kind":"Cat","meow":true}'), 1, 'Cat too');
    is($api->spec->{components}{schemas}{Pet}{discriminator}{propertyName}, 'kind',
       '->spec carries the object form');

    my $err;
    eval { api_for({ type => 'object', discriminator => 'kind', required => ['kind'] }) } or $err = $@;
    like($err, qr/discriminator property 'kind' is not defined/,
         'the property MUST be defined at this schema');
    undef $err;
    eval { api_for({ type => 'object', discriminator => 'kind',
                     properties => { kind => { type => 'string' } } }) } or $err = $@;
    like($err, qr/discriminator property 'kind' is not in the required/,
         'the property MUST be in the required list');
}

# ---- idempotency -----------------------------------------------------------
# The normalised document keeps `swagger: "2.0"`, so ->spec fed back through
# new() runs the pre-pass AND the 3.0 pass again. Twice must equal once.
{
    # the discriminator sits on a NAMED base with a child: an inline schema
    # with a discriminator and nothing inheriting from it is refused in every
    # version (t/30 pins that), so the body refers to the base instead
    my $base = {
        type       => 'object',
        discriminator => 'kind',
        required   => ['kind'],
        properties => {
            kind => { type => 'string' },
            n    => { type => 'integer', minimum => 5, exclusiveMinimum => $TRUE },
            s    => { type => 'string', nullable => $TRUE },
            b    => { type => 'string', format => 'byte' },
            pair => { type => 'array', items => [ { type => 'string' } ] },
            ex   => { type => 'string', example => 'x' },
            r    => { '$ref' => '#/definitions/S' },
        },
    };
    my $schema = { '$ref' => '#/definitions/Base' };
    my %extra = (
        definitions => { S     => { type => 'string', 'x-nullable' => $TRUE },
                         Base  => $base,
                         Child => { allOf => [ { '$ref' => '#/definitions/Base' },
                                               { type => 'object',
                                                 properties => { extra => { type => 'string' } } } ] } },
        host => 'h.test', basePath => '/v2', schemes => [ 'https' ],
        produces => [ 'application/json' ],
        securityDefinitions => { k => { type => 'apiKey', name => 'X-K', in => 'header' },
                                 b => { type => 'basic' } },
        security => [ { k => [] }, { b => [] } ],
    );
    my $one   = api_for($schema, %extra);
    my $two   = Open::API->new(spec => $one->spec);
    my $three = Open::API->new(spec => $two->spec);

    is_deeply($two->spec, $one->spec,   'a second pass changes nothing');
    is_deeply($three->spec, $one->spec, 'nor does a third');

    for my $case (['{"kind":"Child","n":5}', 0], ['{"kind":"Child","n":6}', 1],
                  ['{"kind":"Child","s":null}', 0], ['{"kind":"Child","pair":["a"]}', 1],
                  ['{"kind":"Child","pair":[1]}', 0], ['{"n":6}', 0],
                  ['{"kind":"Nobody"}', 0]) {
        my ($body, $want) = @$case;
        is(accepts($two, $body), $want, "reloaded: $body");
    }

    is($two->openapi_version, '2.0', 'the version string survives a round trip');
    is($one->spec->{swagger}, '2.0', '->spec keeps swagger');
    ok(!exists $one->spec->{openapi}, '...and gains no openapi key');
    ok(!exists $one->spec->{$_}, "the 2.0 root key '$_' is consumed")
        for qw(host basePath schemes consumes produces definitions securityDefinitions);
    ok(exists $one->spec->{components}{schemas}{S}{'x-nullable'},
       'an extension on a definition survives untouched');
}

done_testing;
