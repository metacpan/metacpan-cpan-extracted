# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use 5.020;
use experimental qw(signatures postderef);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Test::Deep;
use OpenAPI::Modern;
use JSON::Schema::Modern::Utilities 'jsonp';
use Test::File::ShareDir -share => { -dist => { 'OpenAPI-Modern' => 'share' } };
use constant { true => JSON::PP::true, false => JSON::PP::false };
use YAML::PP 0.005;

use lib 't/lib';
use Helper;

my $openapi_preamble = <<'YAML';
---
openapi: 3.1.0
info:
  title: Test API
  version: 1.2.3
YAML

my $doc_uri_rel = Mojo::URL->new('/api');
my $doc_uri = $doc_uri_rel->to_abs(Mojo::URL->new('https://example.com'));
my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

my $type_index = 0;

START:
$::TYPE = $::TYPES[$type_index];
note 'REQUEST/RESPONSE TYPE: '.$::TYPE;

subtest 'validation errors in responses' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    post: {}
YAML

  cmp_deeply(
    (my $result = $openapi->validate_response(response(404),
      { request => request('GET', 'http://example.com/foo/bar') }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'no match found for URI path "/foo/bar"',
        },
      ],
    },
    'error in find_path when passing request into options',
  );

  if ($::TYPE eq 'lwp') {
    my $response = response(404);
    $response->request(request('POST', 'http://example.com/foo/bar'));

    cmp_deeply(
      (my $result = $openapi->validate_response($response))->TO_JSON,
      {
        valid => false,
        errors => [
          {
            instanceLocation => '/request/uri/path',
            keywordLocation => '/paths',
            absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
            error => 'no match found for URI path "/foo/bar"',
          },
        ],
      },
      'error in find_path when providing request on response',
    );

    $response->request(request('POST', 'http://example.com/foo'));
    cmp_deeply(
      ($result = $openapi->validate_response($response))->TO_JSON,
      { valid => true },
      'operation is successfully found using the request on the response',
    );
  }

  cmp_deeply(
    ($result = $openapi->validate_response(response(404),
      { path_template => '/foo', request => request('POST', 'http://example.com/foo') }))->TO_JSON,
    { valid => true },
    'operation is successfully found using the request in options',
  );

  cmp_deeply(
    ($result = $openapi->validate_response(response(404), { path_template => '/foo', method => 'PoSt' }))->TO_JSON,
    { valid => true },
    'operation is successfully found using the method in options',
  );

  cmp_deeply(
    ($result = $openapi->validate_response(response(404), { path_template => '/foo', method => 'POST' }))->TO_JSON,
    { valid => true },
    'no responses object - nothing to validate against',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    post:
      responses:
        200:
          description: success
        2XX:
          description: other success
YAML

  cmp_deeply(
    ($result = $openapi->validate_response(response(404), { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => jsonp(qw(/paths /foo post responses)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses)))->to_string,
          error => 'no response object found for code 404',
        },
      ],
    },
    'response code not found - nothing to validate against',
  );

  cmp_deeply(
    ($result = $openapi->validate_response(response(200), { path_template => '/foo', method => 'post' }))->TO_JSON,
    { valid => true },
    'response code matched exactly',
  );

  cmp_deeply(
    ($result = $openapi->validate_response(response(202), { path_template => '/foo', method => 'post' }))->TO_JSON,
    { valid => true },
    'response code matched wildcard',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
components:
  responses:
    foo:
      \$ref: '#/i_do_not_exist'
    default:
      description: unexpected failure
      headers:
        Content-Type:
          # this is ignored!
          required: true
          schema: {}
        Foo-Bar:
          \$ref: '#/components/headers/foo-header'
  headers:
    foo-header:
      required: true
      schema:
        pattern: ^[0-9]+\$
paths:
  /foo:
    post:
      responses:
        303:
          \$ref: '#/components/responses/foo'
        default:
          \$ref: '#/components/responses/default'
YAML

  cmp_deeply(
    ($result = $openapi->validate_response(response(303), { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => jsonp(qw(/paths /foo post responses 303 $ref $ref)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment('/components/responses/foo/$ref')->to_string,
          error => 'EXCEPTION: unable to find resource /api#/i_do_not_exist',
        },
      ],
    },
    'bad $ref in responses',
  );

  cmp_deeply(
    ($result = $openapi->validate_response(response(500), { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Foo-Bar',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref headers Foo-Bar $ref required)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment('/components/headers/foo-header/required')->to_string,
          error => 'missing header: Foo-Bar',
        },
      ],
    },
    'header is missing',
  );

  cmp_deeply(
    ($result = $openapi->validate_response(response(500, [ 'FOO-BAR' => 'header value' ]), { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Foo-Bar',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref headers Foo-Bar $ref schema pattern)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment('/components/headers/foo-header/schema/pattern')->to_string,
          error => 'pattern does not match',
        },
      ],
    },
    'header is evaluated against its schema',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
components:
  responses:
    default:
      description: unexpected failure
      content:
        application/json:
          schema:
            type: object
            properties:
              alpha:
                type: string
                pattern: ^[0-9]+\$
              beta:
                type: string
                const: éclair
              gamma:
                type: string
                const: ಠ_ಠ
            additionalProperties: false
        bloop/html:
          schema: false
        text/plain:
          schema:
            const: éclair
paths:
  /foo:
    post:
      responses:
        303:
          \$ref: '#/components/responses/foo'
        default:
          \$ref: '#/components/responses/default'
YAML

  # response has no content-type, content-length or body.
  cmp_deeply(
    ($result = $openapi->validate_response(response(200), { path_template => '/foo', method => 'post' }))->TO_JSON,
    { valid => true },
    'missing Content-Type does not cause an exception',
  );


  cmp_deeply(
    ($result = $openapi->validate_response(response(200, [ 'Content-Type' => 'application/json' ], 'null'),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content application/json schema type)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment('/components/responses/default/content/application~1json/schema/type')->to_string,
          error => 'got null, not object',
        },
      ],
    },
    'missing Content-Length does not prevent the response body from being checked',
  );

  cmp_deeply(
    ($result = $openapi->validate_response(response(200, [ 'Content-Type' => 'text/bloop' ], 'plain text'),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment('/components/responses/default/content')->to_string,
          error => 'incorrect Content-Type "text/bloop"',
        },
      ],
    },
    'Content-Type not allowed by the schema',
  );

  cmp_deeply(
    ($result = $openapi->validate_response(response(200, [ 'Content-Type' => 'bloop/html' ], 'html text'),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content bloop/html)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp('/components/responses/default/content', 'bloop/html'))->to_string,
          error => 'EXCEPTION: unsupported Content-Type "bloop/html": add support with $openapi->add_media_type(...)',
        },
      ],
    },
    'unsupported Content-Type',
  );

  cmp_deeply(
    ($result = $openapi->validate_response(response(200, [ 'Content-Type' => 'text/plain; charset=ISO-8859-1' ],
        chr(0xe9).'clair'),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    { valid => true },
    'latin1 content can be successfully decoded',
  );

  cmp_deeply(
    ($result = $openapi->validate_response(response(200, [ 'Content-Type' => 'application/json' ],
        '{"alpha": "foo", "gamma": "o.o"}'),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body/alpha',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content application/json schema properties alpha pattern)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp('/components/responses/default/content', qw(application/json schema properties alpha pattern)))->to_string,
          error => 'pattern does not match',
        },
        {
          instanceLocation => '/response/body/gamma',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content application/json schema properties gamma const)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp('/components/responses/default/content', qw(application/json schema properties gamma const)))->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content application/json schema properties)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp('/components/responses/default/content', qw(application/json schema properties)))->to_string,
          error => 'not all properties are valid',
        },
      ],
    },
    'decoded content does not match the schema',
  );


  my $disapprove = v224.178.160.95.224.178.160; # utf-8-encoded "ಠ_ಠ"
  cmp_deeply(
    ($result = $openapi->validate_response(response(200, [ 'Content-Type' => 'application/json' ],
        '{"alpha": "123", "gamma": "'.$disapprove.'"}'),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    { valid => true },
    'decoded content matches the schema',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    post:
      responses:
        '200':
          description: no content permitted
          headers:
            Content-Length:
              description: if present, the value must be 0
              required: false
              schema:
                type: integer
                const: 0
            Content-Type:
              description: cannot be present (an empty value is not permitted)
              required: false
              schema:
                false
          content:
            '*/*':
              schema:
                type: string
                maxLength: 0
        '204':
          description: no content permitted, and no Content-Length either
          headers:
            Content-Length:
              required: false
              schema: false
            Content-Type:
              required: false
              schema: false
          content:
            '*/*':
              schema: false
        default:
          description: default
          headers:
            Content-Length:
              required: true
              schema:
                type: integer
                minimum: 1
          content:
            text/plain:
              schema:
                minLength: 10
YAML


  cmp_deeply(
    ($result = $openapi->validate_response(response(400, [ 'Content-Length' => 10 ], 'plain text'),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Content-Type',
          keywordLocation => jsonp(qw(/paths /foo post responses default content)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses default content)))->to_string,
          error => 'missing header: Content-Type',
        },
      ],
    },
    'missing Content-Type does not cause an exception',
  );


  cmp_deeply(
    ($result = $openapi->validate_response(
      response(400, [ 'Content-Length' => 1, 'Content-Type' => 'text/plain' ], ''), # Content-Length lies!
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses default content text/plain schema minLength)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses default content text/plain schema minLength)))->to_string,
          error => 'length is less than 10',
        },
      ],
    },
    'missing body (with a lying Content-Length) does not cause an exception, but is detectable',
  );

  # no Content-Length
  cmp_deeply(
    ($result = $openapi->validate_response(response(400, [ 'Content-Type' => 'text/plain' ]),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Content-Length',
          keywordLocation => jsonp(qw(/paths /foo post responses default headers Content-Length required)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses default headers Content-Length required)))->to_string,
          error => 'missing header: Content-Length',
        },
      ],
    },
    'missing body and no Content-Length does not cause an exception, but is still detectable',
  );


  cmp_deeply(
    ($result = $openapi->validate_response(response(200, [ 'Content-Type' => 'text/plain', 'Content-Length' => 20 ], 'I should not have content'),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Content-Length',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 headers Content-Length schema const)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses 200 headers Content-Length schema const)))->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 content */* schema maxLength)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses 200 content */* schema maxLength)))->to_string,
          error => 'length is greater than 0',
        },
      ],
    },
    'an undesired response body is detectable',
  );


  # note: when 204, mojo's $message->body always returns ''
  # this test is only possible (for HTTP::Response) if we manually add a Content-Length; it will not
  # be added via parse().
  cmp_deeply(
    ($result = $openapi->validate_response(response(204, [ 'Content-Type' => 'text/plain', 'Content-Length' => 20 ], 'I should not have content'),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Content-Length',
          keywordLocation => jsonp(qw(/paths /foo post responses 204 headers Content-Length schema)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses 204 headers Content-Length schema)))->to_string,
          error => 'response header not permitted',
        },
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses 204 content */* schema)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses 204 content */* schema)))->to_string,
          error => 'response body not permitted',
        },
      ],
    },
    'an undesired response body is detectable for 204 responses',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    post:
      responses:
        default:
          description: no content permitted
          content:
            '*/*':
              schema:
                maxLength: 0
YAML

  cmp_deeply(
    ($result = $openapi->validate_response(
      response(400, [ 'Content-Length' => 1, 'Content-Type' => 'unknown/unknown' ], '!!!'),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses default content */* schema maxLength)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses default content */* schema maxLength)))->to_string,
          error => 'length is greater than 0',
        },
      ],
    },
    'demonstrate recipe for guaranteeing that there is no response body',
  );
};

subtest 'unevaluatedProperties and annotations' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    evaluator => JSON::Schema::Modern->new,
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    post:
      responses:
        200:
          description: success
          content:
            application/json:
              schema:
                type: object
                properties:
                  bar: true
                unevaluatedProperties: false
YAML

  cmp_deeply(
    (my $result = $openapi->validate_response(
      response(200, [ 'Content-Type' => 'application/json' ], '{"foo":1}'),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body/foo',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 content application/json schema unevaluatedProperties)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses 200 content application/json schema unevaluatedProperties)))->to_string,
          error => 'additional property not permitted',
        },
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 content application/json schema unevaluatedProperties)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses 200 content application/json schema unevaluatedProperties)))->to_string,
          error => 'not all additional properties are valid',
        },
      ],
    },
    'unevaluatedProperties can be used in schemas',
  );

  cmp_deeply(
    ($result = $openapi->validate_response(
      response(200, [ 'Content-Type' => 'application/json' ], '{"bar":1}'),
      { path_template => '/foo', method => 'post' }))->format('basic', 1),
    {
      valid => true,
      annotations => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 content application/json schema properties)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses 200 content application/json schema properties)))->to_string,
          annotation => ['bar'],
        },
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 content application/json schema unevaluatedProperties)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses 200 content application/json schema unevaluatedProperties)))->to_string,
          annotation => [],
        },
      ],
    },
    'annotations are collected when evaluating valid response',
  );
};

subtest 'writeOnly' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    evaluator => JSON::Schema::Modern->new,
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    post:
      responses:
        '200':
          description: success
          headers:
            a:
              schema:
                readOnly: true
                writeOnly: true
            b:
              schema:
                readOnly: false
                writeOnly: false
          content:
            application/json:
              schema:
                type: object
                properties:
                  c:
                    readOnly: true
                    writeOnly: true
                  d:
                    readOnly: false
                    writeOnly: false
YAML

  cmp_deeply(
    (my $result = $openapi->validate_response(
      response(200, [ 'Content-Type' => 'application/json', A => 1, B => 2 ], '{"c":1,"d":2}'),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    { valid => true },
    'writeOnly values are still valid in a response',
  );
};

subtest 'custom error messages for false schemas' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    evaluator => JSON::Schema::Modern->new,
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    post:
      responses:
        '200':
          description: blah
          headers:
            Foo:
              schema: false
          content:
            '*/*':
              schema: false
YAML

  cmp_deeply(
    (my $result = $openapi->validate_response(
      response(200, [ Foo => 1, 'Content-Type' => 'text/plain' ], 'hi'),
      { path_template => '/foo', method => 'post' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Foo',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 headers Foo schema)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses 200 headers Foo schema)))->to_string,
          error => 'response header not permitted',
        },
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 content */* schema)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo post responses 200 content */* schema)))->to_string,
          error => 'response body not permitted',
        },
      ],
    },
    'custom error message when the entity is not permitted',
  );
};

goto START if ++$type_index < @::TYPES;

done_testing;
