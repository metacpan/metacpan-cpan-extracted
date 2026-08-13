#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Open::API;

# OpenAPI 3.0 up-conversion (include/oa_upconvert.h).
#
# A 3.0 Schema Object is a different dialect from a 3.1 one, so a 3.0 document
# is rewritten into 3.1 shape at load. These tests assert through the public
# API - what the validator accepts and rejects - rather than by inspecting the
# converted document, because the behaviour is the contract and the shape is
# an implementation detail. The one exception is the group at the end that
# reads ->spec directly, to pin the annotations a consumer (the docs UI, Maat)
# is entitled to find there.

# JSON booleans, the way a decoder leaves them. `\1` and `\0` are the portable
# spelling and are what the converter recognises; a bare 1 is a number.
my $TRUE  = \1;
my $FALSE = \0;

# Build a 3.0 document with one POST whose body is `$schema`.
sub api_for {
    my ($schema, %extra) = @_;
    return Open::API->new(spec => {
        openapi => '3.0.3',
        info    => { title => 'T', version => '1.0.0' },
        paths   => {
            '/t' => {
                post => {
                    operationId => 'post_t',
                    requestBody => {
                        required => 1,
                        content  => { 'application/json' => { schema => $schema } },
                    },
                    responses => { 200 => { description => 'ok' } },
                },
            },
        },
        %extra,
    });
}

# Does this API accept that body?
sub accepts {
    my ($api, $json) = @_;
    my ($ok) = $api->validate_request('post_t', {
        header => { 'content-type' => 'application/json' },
        body   => $json,
    });
    return $ok ? 1 : 0;
}

# ---- nullable --------------------------------------------------------------
{
    my $api = api_for({
        type       => 'object',
        properties => {
            plain => { type => 'string' },
            nul   => { type => 'string', nullable => $TRUE },
            off   => { type => 'string', nullable => $FALSE },
        },
    });

    ok(accepts($api, '{"nul":null}'),   'nullable: true accepts null');
    ok(accepts($api, '{"nul":"hi"}'),   'nullable: true still accepts the type');
    ok(!accepts($api, '{"plain":null}'), 'a plain string still rejects null');
    ok(!accepts($api, '{"off":null}'),   'nullable: false rejects null');
    ok(!accepts($api, '{"nul":42}'),     'nullable does not widen to other types');
}

# nullable on a type that is already a union, and on an enum
{
    my $api = api_for({
        type       => 'object',
        properties => {
            multi => { type => ['string', 'integer'], nullable => $TRUE },
            enu   => { enum => ['a', 'b'], nullable => $TRUE },
        },
    });
    ok(accepts($api, '{"multi":null}'), 'nullable appends null to a type union');
    ok(accepts($api, '{"multi":7}'),    'the union members survive');
    ok(accepts($api, '{"enu":null}'),   'nullable admits null into an enum');
    ok(accepts($api, '{"enu":"a"}'),    'the enum members survive');
    ok(!accepts($api, '{"enu":"z"}'),   'the enum still rejects a non-member');
}

# nullable beside a $ref becomes the anyOf union 3.1 would have written
{
    my $api = api_for(
        { type => 'object', properties => { pet => {
            '$ref' => '#/components/schemas/Pet', nullable => $TRUE } } },
        components => { schemas => {
            Pet => { type => 'object', required => ['id'],
                     properties => { id => { type => 'integer' } } },
        } },
    );
    ok(accepts($api, '{"pet":null}'),      'nullable $ref accepts null');
    ok(accepts($api, '{"pet":{"id":1}}'),  'nullable $ref accepts the referent');
    ok(!accepts($api, '{"pet":{}}'),       'nullable $ref still enforces the referent');
}

# ---- exclusiveMinimum / exclusiveMaximum as booleans -----------------------
{
    my $api = api_for({
        type       => 'object',
        properties => {
            gt  => { type => 'integer', minimum => 5, exclusiveMinimum => $TRUE },
            ge  => { type => 'integer', minimum => 5, exclusiveMinimum => $FALSE },
            lt  => { type => 'integer', maximum => 5, exclusiveMaximum => $TRUE },
            le  => { type => 'integer', maximum => 5 },
            bare => { type => 'integer', exclusiveMinimum => $TRUE },
        },
    });

    ok(!accepts($api, '{"gt":5}'), 'exclusiveMinimum: true rejects the bound');
    ok(accepts($api, '{"gt":6}'),  'exclusiveMinimum: true accepts above it');
    ok(!accepts($api, '{"gt":4}'), 'the minimum is still a minimum');

    ok(accepts($api, '{"ge":5}'),  'exclusiveMinimum: false keeps an inclusive bound');
    ok(!accepts($api, '{"ge":4}'), 'exclusiveMinimum: false still enforces minimum');

    ok(!accepts($api, '{"lt":5}'), 'exclusiveMaximum: true rejects the bound');
    ok(accepts($api, '{"lt":4}'),  'exclusiveMaximum: true accepts below it');
    ok(accepts($api, '{"le":5}'),  'a bare maximum stays inclusive');

    # exclusiveMinimum: true with no minimum constrains nothing in 3.0
    ok(accepts($api, '{"bare":0}'), 'a dangling exclusiveMinimum is dropped');
}

# ---- tuple items (draft-04 habit) ------------------------------------------
{
    my $api = api_for({
        type  => 'object',
        properties => {
            pair => { type => 'array',
                      items => [ { type => 'string' }, { type => 'integer' } ] },
            capped => { type => 'array',
                        items => [ { type => 'string' } ],
                        additionalItems => { type => 'boolean' } },
        },
    });
    ok(accepts($api, '{"pair":["a",1]}'),  'tuple items validate positionally');
    ok(!accepts($api, '{"pair":[1,"a"]}'), 'the positions are enforced');
    ok(accepts($api, '{"pair":["a",1,{}]}'),
       'without additionalItems the tail is unconstrained');
    ok(accepts($api, '{"capped":["a",true]}'),
       'additionalItems constrains the tail');
    ok(!accepts($api, '{"capped":["a",99]}'),
       'the tail constraint is enforced');
}

# ---- $ref siblings ---------------------------------------------------------
# Under 3.0 a keyword beside a $ref is ignored. Under 2020-12 it would be
# merged - so an unconverted document would reject a request a 3.0-conformant
# gateway accepts.
{
    my $api = api_for(
        { '$ref' => '#/components/schemas/Pet',
          description => 'the pet',
          maxProperties => 0 },                    # the ignored assertion
        components => { schemas => {
            Pet => { type => 'object', properties => { id => { type => 'integer' } } },
        } },
    );
    ok(accepts($api, '{"id":1}'), 'an assertion beside a $ref is ignored');
}

# ---- format: byte / binary -------------------------------------------------
{
    my $api = api_for({
        type => 'object',
        properties => {
            blob => { type => 'string', format => 'byte' },
            file => { type => 'string', format => 'binary' },
        },
    });
    ok(accepts($api, '{"blob":"AA==","file":"x"}'), 'byte/binary bodies validate');

    my $s = $api->spec->{paths}{'/t'}{post}{requestBody}
                {content}{'application/json'}{schema}{properties};
    is($s->{blob}{contentEncoding}, 'base64',
       'format: byte gains contentEncoding');
    is($s->{blob}{format}, 'byte', 'format: byte is kept for the docs UI');
    is($s->{file}{contentMediaType}, 'application/octet-stream',
       'format: binary gains contentMediaType');
}

# ---- example -> examples ---------------------------------------------------
{
    my $api = api_for({ type => 'string', example => 'hello' });
    my $s = $api->spec->{paths}{'/t'}{post}{requestBody}
                {content}{'application/json'}{schema};
    is_deeply($s->{examples}, ['hello'], 'schema example becomes examples[]');
    ok(!exists $s->{example}, 'the 3.0 spelling is gone');
}

# A media-type `example` is an Example Object, not a schema keyword: untouched.
{
    my $api = Open::API->new(spec => {
        openapi => '3.0.3',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/t' => { post => {
            operationId => 'post_t',
            requestBody => { content => { 'application/json' => {
                schema  => { type => 'object' },
                example => { nullable => 'not a keyword here' },
            } } },
            responses => { 200 => { description => 'ok' } },
        } } },
    });
    my $m = $api->spec->{paths}{'/t'}{post}{requestBody}{content}{'application/json'};
    is_deeply($m->{example}, { nullable => 'not a keyword here' },
              'a media-type example is a value, not a schema');
}

# A `default` value is user JSON too, however schema-shaped it looks.
{
    my $api = api_for({
        type       => 'object',
        properties => { cfg => { type => 'object',
                                 default => { nullable => 1, items => [1, 2] } } },
    });
    my $s = $api->spec->{paths}{'/t'}{post}{requestBody}
                {content}{'application/json'}{schema};
    is_deeply($s->{properties}{cfg}{default}, { nullable => 1, items => [1, 2] },
              'a default value is copied, never walked');
}

# ---- parameters, responses and components all get the same treatment -------
{
    my $api = Open::API->new(spec => {
        openapi => '3.0.3',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/p/{id}' => {
            parameters => [ { name => 'id', in => 'path', required => 1,
                              schema => { type => 'integer', minimum => 0,
                                          exclusiveMinimum => $TRUE } } ],
            get => {
                operationId => 'get_p',
                parameters  => [ { name => 'q', in => 'query',
                                   schema => { type => 'string', nullable => $TRUE } } ],
                responses   => { 200 => {
                    description => 'ok',
                    content => { 'application/json' => {
                        schema => { '$ref' => '#/components/schemas/Out' } } },
                } },
            },
        } },
        components => { schemas => {
            Out => { type => 'object',
                     properties => { n => { type => 'integer', nullable => $TRUE } } },
        } },
    });

    my ($ok) = $api->validate_request('get_p', { path => { id => '0' } });
    ok(!$ok, 'a path-item parameter is converted (0 fails the exclusive bound)');
    ($ok) = $api->validate_request('get_p', { path => { id => '1' } });
    ok($ok, 'and accepts a value above it');

    ($ok) = $api->validate_request('get_p', { path => { id => '1' },
                                              query => 'q=hi' });
    ok($ok, 'an operation parameter is converted too');

    my $out = $api->spec->{components}{schemas}{Out};
    is_deeply($out->{properties}{n}{type}, ['integer', 'null'],
              'components.schemas is converted');
    ok(!exists $out->{properties}{n}{nullable}, 'nullable is consumed there too');

    my $errs = $api->check_response('get_p',
        [200, ['Content-Type' => 'application/json'], ['{"n":null}']]);
    ok(!$errs, 'the converted response schema accepts null');

    $errs = $api->check_response('get_p',
        [200, ['Content-Type' => 'application/json'], ['{"n":"nope"}']]);
    ok($errs, 'and still rejects a wrong type');
}

# ---- idempotency -----------------------------------------------------------
# The normalised document keeps its `openapi: 3.0.x` string, so feeding ->spec
# back through new() runs the converter again. Twice must equal once.
{
    my $schema = {
        type       => 'object',
        properties => {
            n    => { type => 'integer', minimum => 5, exclusiveMinimum => $TRUE },
            s    => { type => 'string', nullable => $TRUE },
            b    => { type => 'string', format => 'byte' },
            pair => { type => 'array', items => [ { type => 'string' } ] },
            ex   => { type => 'string', example => 'x' },
        },
    };

    my $one   = api_for($schema);
    my $two   = Open::API->new(spec => $one->spec);
    my $three = Open::API->new(spec => $two->spec);

    is_deeply($two->spec, $one->spec,   'a second pass changes nothing');
    is_deeply($three->spec, $one->spec, 'nor does a third');

    for my $case (['{"n":5}', 0], ['{"n":6}', 1], ['{"s":null}', 1],
                  ['{"pair":["a"]}', 1], ['{"pair":[1]}', 0]) {
        my ($body, $want) = @$case;
        is(accepts($two, $body), $want, "reloaded: $body");
    }

    is($two->openapi_version, '3.0.3', 'the version string survives a round trip');
}

# ---- a 3.1 document is untouched -------------------------------------------
# `nullable` means nothing in 3.1 and must NOT be honoured there.
{
    my $api = Open::API->new(spec => {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/t' => { post => {
            operationId => 'post_t',
            requestBody => { content => { 'application/json' => { schema => {
                type => 'object',
                properties => { s => { type => 'string', nullable => $TRUE } },
            } } } },
            responses => { 200 => { description => 'ok' } },
        } } },
    });
    ok(!accepts($api, '{"s":null}'), '3.1 does not honour nullable');
    is($api->spec->{paths}{'/t'}{post}{requestBody}{content}{'application/json'}
          {schema}{properties}{s}{nullable}, $TRUE, 'and the document is untouched');
}

done_testing();
