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

my $doc_uri = Mojo::URL->new('https://example.com/api');
my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

my $type_index = 0;

START:
$::TYPE = $::TYPES[$type_index];
note 'REQUEST/RESPONSE TYPE: '.$::TYPE;

subtest 'validation errors, request uri paths' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    get:
      parameters:
      - name: foo_id
        in: path
        required: true
        schema:
          pattern: ^[0-9]+\$
YAML

  cmp_deeply(
    (my $result = $openapi->validate_request(request('GET', 'http://example.com/foo/bar'), { path_template => '/foo/baz', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'missing path-item "/foo/baz"',
        },
      ],
    },
    'error in find_path',
  );

  cmp_deeply(
    ($result = $openapi->validate_request(request('GET', 'http://example.com/foo'), { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp(qw(/paths /foo get parameters 0 required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 0 required)))->to_string,
          error => 'missing path parameter: foo_id',
        },
      ],
    },
    'path parameter is missing',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo/{foo_id}:
    get:
      parameters:
      - name: foo_id
        in: path
        required: true
        schema:
          pattern: ^[0-9]+\$
YAML

  cmp_deeply(
    ($result = $openapi->validate_request(request('GET', 'http://example.com/foo/bar'), { path_template => '/foo/{foo_id}', path_captures => { foo_id => 'bar' } }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} get parameters 0 schema pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get parameters 0 schema pattern)))->to_string,
          error => 'pattern does not match',
        },
      ],
    },
    'path parameters are evaluated against their schemas',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo/{foo_id}:
    get:
      parameters:
      - name: foo_id
        in: path
        required: true
        content:
          application/json:
            schema:
              required: ['key']
YAML

  cmp_deeply(
    $result = $openapi->validate_request(request('GET', 'http://example.com/foo/corrupt_json'),
      { path_template => '/foo/{foo_id}', path_captures => { foo_id => 'corrupt_json' } })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} get parameters 0 content application/json)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get parameters 0 content application/json)))->to_string,
          error => re(qr/^could not decode content as application\/json: malformed JSON string/),
        },
      ],
    },
    'errors during media-type decoding are detected',
  );

  cmp_deeply(
    ($result = $openapi->validate_request(request('GET', 'http://example.com/foo/{"hello":"there"}'),
      { path_template => '/foo/{foo_id}', path_captures => { foo_id => '{"hello":"there"}'}}))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} get parameters 0 content application/json schema required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get parameters 0 content application/json schema required)))->to_string,
          error => 'missing property: key',
        },
      ],
    },
    'parameters are decoded using the indicated media type and then validated against the content schema',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo/{foo_id}/bar/{bar_id}:
    parameters:
    - name: foo_id
      in: path
      required: true
      schema:
        pattern: ^[0-9]+\$
    - name: bar_id
      in: path
      required: true
      schema:
        pattern: ^[0-9]+\$
    get:
      parameters:
      - name: foo_id
        in: path
        required: true
        schema:
          maxLength: 1
      - name: bar_id
        in: query
        required: false
        schema:
          maxLength: 1
YAML

  cmp_deeply(
    ($result = $openapi->validate_request(request('GET', 'http://example.com/foo/foo/bar/bar'),
      { path_template => '/foo/{foo_id}/bar/{bar_id}', path_captures => { foo_id => 'foo', bar_id => 'bar' } }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(get parameters 0 schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(get parameters 0 schema maxLength)))->to_string,
          error => 'length is greater than 1',
        },
        {
          instanceLocation => '/request/uri/path/bar_id',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(parameters 1 schema pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(parameters 1 schema pattern)))->to_string,
          error => 'pattern does not match',
        },
      ],
    },
    'path parameters: operation overshadows path-item',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => do {
      YAML::PP->new( boolean => 'JSON::PP' )->load_string(<<YAML);
$openapi_preamble
paths:
  /foo/{foo_id}:
    get: {}
YAML
      },
  );

  cmp_deeply(
    ($result = $openapi->validate_request(request('GET', 'http://example.com/foo/foo'),
      { path_template => '/foo/{foo_id}', path_captures => { foo_id => 'foo' } }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'missing path parameter specification for "foo_id"',
        },
      ],
    },
    'a specification must exist for every templated path value',
  );
};

subtest 'validation errors in requests' => sub {
  my $request = request('POST', 'http://example.com/foo');
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    post: {}
YAML

  cmp_deeply(
    (my $result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    { valid => true },
    'operation can be empty',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    post:
      parameters:
      - \$ref: '#/i_do_not_exist'
YAML

  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo post parameters 0 $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 0 $ref)))->to_string,
          error => 'EXCEPTION: unable to find resource /api#/i_do_not_exist',
        },
      ],
    },
    'bad $ref in operation parameters',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    parameters:
    - \$ref: '#/i_do_not_exist'
    post: {}
YAML

  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo parameters 0 $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo parameters 0 $ref)))->to_string,
          error => 'EXCEPTION: unable to find resource /api#/i_do_not_exist',
        },
      ],
    },
    'bad $ref in path-item parameters',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
components:
  parameters:
    foo:
      \$ref: '#/i_do_not_exist'
paths:
  /foo:
    post:
      parameters:
      - \$ref: '#/components/parameters/foo'
YAML

  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo post parameters 0 $ref $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/parameters/foo/$ref')->to_string,
          error => 'EXCEPTION: unable to find resource /api#/i_do_not_exist',
        },
      ],
    },
    'bad $ref to $ref in operation parameters',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    post:
      parameters:
      - name: yum
        in: cookie
        required: false
        schema:
          type: string
YAML

  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/cookie/yum',
          keywordLocation => jsonp(qw(/paths /foo post parameters 0)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 0)))->to_string,
          error => 'cookie parameters not yet supported',
        },
      ],
    },
    'cookies are not yet supported',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
components:
  parameters:
    foo-header:
      name: Alpha
      in: header
      required: true
      schema:
        pattern: ^[0-9]+\$
paths:
  /foo:
    parameters:
    - name: ALPHA   # different case, but should still be overridden by the operation parameter
      in: header
      required: true
      schema: true
    post:
      parameters:
      - name: alpha
        in: query
        required: true
        schema:
          pattern: ^[0-9]+\$
      - \$ref: '#/components/parameters/foo-header'
      - name: beta
        in: query
        required: false
        schema: false
      - name: gamma
        in: query
        required: false
        content:
          unknown/encodingtype:
            schema: true
      - name: delta
        in: query
        required: false
        content:
          unknown/encodingtype:
            schema: false
      - name: epsilon
        in: query
        required: false
        content:
          apPlicATion/jsON:
            schema: false
      - name: zeta
        in: query
        required: false
        content:
          iMAgE/*:
            schema: false
YAML
  # note that bar_id is not listed as a path parameter

  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/alpha',
          keywordLocation => jsonp(qw(/paths /foo post parameters 0 required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 0 required)))->to_string,
          error => 'missing query parameter: alpha',
        },
        {
          instanceLocation => '/request/header/Alpha',
          keywordLocation => jsonp(qw(/paths /foo post parameters 1 $ref required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/parameters/foo-header/required')->to_string,
          error => 'missing header: Alpha',
        },
      ],
    },
    'query and header parameters are missing; header names are case-insensitive',
  );


  $request = request('POST', 'http://example.com/foo?alpha=1&gamma=foo&delta=bar', [ Alpha => 1 ]);
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/delta',
          keywordLocation => jsonp(qw(/paths /foo post parameters 4 content unknown/encodingtype)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 4 content unknown/encodingtype)))->to_string,
          error => 'EXCEPTION: unsupported media type "unknown/encodingtype": add support with $openapi->add_media_type(...)',
        },
      ],
    },
    'a missing media-type is not an error if the schema is a no-op true schema',
  );

  $openapi->add_media_type('unknown/*' => sub ($value) { $value });

  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/delta',
          keywordLocation => jsonp(qw(/paths /foo post parameters 4 content unknown/encodingtype schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 4 content unknown/encodingtype schema)))->to_string,
          error => 'subschema is false',
        },
      ],
    },
    'after adding wildcard support, this parameter can be parsed',
  );


  $request = request('POST', 'http://example.com/foo?alpha=1&epsilon={"foo":42}', [ Alpha => 1 ]);
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/epsilon',
          keywordLocation => jsonp(qw(/paths /foo post parameters 5 content apPlicATion/jsON schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 5 content apPlicATion/jsON schema)))->to_string,
          error => 'subschema is false',
        },
      ],
    },
    'media-types in the openapi document are looked up case-insensitively',
  );


  $openapi->add_media_type('image/*' => sub ($value) { $value });

  $request = request('POST', 'http://example.com/foo?alpha=1&zeta=binary', [ Alpha => 1 ]);
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/zeta',
          keywordLocation => jsonp(qw(/paths /foo post parameters 6 content iMAgE/* schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 6 content iMAgE/* schema)))->to_string,
          error => 'subschema is false',
        },
      ],
    },
    'wildcard media-types in the openapi document are looked up case-insensitively too',
  );


  $request = request('POST', 'http://example.com/foo?alpha=hello&beta=3.1415',
    [ 'alpha' => 'header value' ]);    # exactly matches query parameter
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/alpha',
          keywordLocation => jsonp(qw(/paths /foo post parameters 0 schema pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 0 schema pattern)))->to_string,
          error => 'pattern does not match',
        },
        {
          instanceLocation => '/request/header/Alpha',
          keywordLocation => jsonp(qw(/paths /foo post parameters 1 $ref schema pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/parameters/foo-header/schema/pattern')->to_string,
          error => 'pattern does not match',
        },
        {
          instanceLocation => '/request/uri/query/beta',
          keywordLocation => jsonp(qw(/paths /foo post parameters 2 schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 2 schema)))->to_string,
          error => 'subschema is false',
        },
      ],
    },
    'query and header parameters are evaluated against their schemas',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    get:
      parameters:
      - name: query1
        in: query
        required: true
        content:
          application/json:
            schema:
              required: ['key']
      - name: Header1
        in: header
        required: true
        content:
          application/json:
            schema:
              required: ['key']
YAML

  $request = request('GET', 'http://example.com/foo?query1={corrupt json',
    [ 'Header1' => '{corrupt json' ]);
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/query1',
          keywordLocation => jsonp(qw(/paths /foo get parameters 0 content application/json)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 0 content application/json)))->to_string,
          error => re(qr/^could not decode content as application\/json: \'"\' expected, at character offset 1/),
        },
        {
          instanceLocation => '/request/header/Header1',
          keywordLocation => jsonp(qw(/paths /foo get parameters 1 content application/json)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 1 content application/json)))->to_string,
          error => re(qr/^could not decode content as application\/json: \'"\' expected, at character offset 1/),
        },
      ],
    },
    'errors during media-type decoding are detected',
  );

  $request = request('GET', 'http://example.com/foo?query1={"hello":"there"}',
    [ 'Header1' => '{"hello":"there"}' ]);
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/query1',
          keywordLocation => jsonp(qw(/paths /foo get parameters 0 content application/json schema required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 0 content application/json schema required)))->to_string,
          error => 'missing property: key',
        },
        {
          instanceLocation => '/request/header/Header1',
          keywordLocation => jsonp(qw(/paths /foo get parameters 1 content application/json schema required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 1 content application/json schema required)))->to_string,
          error => 'missing property: key',
        },
      ],
    },
    'parameters are decoded using the indicated media type and then validated against the content schema',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    parameters:
    - name: alpha
      in: query
      required: true
      schema:
        pattern: ^[0-9]+\$
    - name: beta
      in: query
      required: true
      schema:
        pattern: ^[0-9]+\$
    - name: alpha
      in: header
      required: true
      schema:
        pattern: ^[0-9]+\$
    - name: beta
      in: header
      required: true
      schema:
        pattern: ^[0-9]+\$
    get:
      parameters:
      - name: alpha
        in: query
        required: true
        schema:
          maxLength: 1
      - name: alpha
        in: header
        required: true
        schema:
          maxLength: 1
YAML

  $request = request('GET', 'http://example.com/foo?alpha=hihihi&beta=hihihi', [ Alpha => 'hihihi', Beta => 'hihihi' ]);
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/alpha',
          keywordLocation => jsonp(qw(/paths /foo get parameters 0 schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 0 schema maxLength)))->to_string,
          error => 'length is greater than 1',
        },
        {
          instanceLocation => '/request/header/alpha',
          keywordLocation => jsonp(qw(/paths /foo get parameters 1 schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 1 schema maxLength)))->to_string,
          error => 'length is greater than 1',
        },
        {
          instanceLocation => '/request/uri/query/beta',
          keywordLocation => jsonp(qw(/paths /foo parameters 1 schema pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo parameters 1 schema pattern)))->to_string,
          error => 'pattern does not match',
        },
        {
          instanceLocation => '/request/header/beta',
          keywordLocation => jsonp(qw(/paths /foo parameters 3 schema pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo parameters 3 schema pattern)))->to_string,
          error => 'pattern does not match',
        },
      ],
    },
    'query, header parameters: operation overshadows path-item',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    get:
      requestBody:
        \$ref: '#/i_do_not_exist'
YAML

  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo get requestBody $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody $ref)))->to_string,
          error => 'EXCEPTION: unable to find resource /api#/i_do_not_exist',
        },
      ],
    },
    'bad $ref in requestBody',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    get:
      requestBody:
        required: true
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
          tEXt/HTml:
            schema: false
          unknown/encodingtype:
            schema: false
          iMAgE/*:
            schema: false
YAML

  # note: no content!
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo get requestBody required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody required)))->to_string,
          error => 'request body is required but missing',
        },
      ],
    },
    'request body is missing',
  );


  $request = request('GET', 'http://example.com/foo', [ 'Content-Type' => 'text/plain' ], 'plain text');
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo get requestBody content)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody content)))->to_string,
          error => 'incorrect Content-Type "text/plain"',
        },
      ],
    },
    'wrong Content-Type',
  );


  $request = request('GET', 'http://example.com/foo', [ 'Content-Type' => 'TEXT/HTML' ], 'html text');
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo get requestBody content tEXt/HTml)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody content tEXt/HTml)))->to_string,
          error => 'EXCEPTION: unsupported Content-Type "text/html": add support with $openapi->add_media_type(...)',
        },
      ],
    },
    'unsupported Content-Type - but matched against the document case-insensitively',
  );


  # we have to add media-types in foldcased format
  $openapi->add_media_type('text/html' => sub ($content_ref) { $content_ref });

  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo get requestBody content tEXt/HTml schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody content tEXt/HTml schema)))->to_string,
          error => 'subschema is false',
        },
      ],
    },
    'Content-Type looked up case-insensitively and matched in the document case-insensitively too',
  );


  $openapi->add_media_type('unknown/*' => sub ($value) { $value });

  $request = request('GET', 'http://example.com/foo', [ 'Content-Type' => 'unknown/encodingtype' ], 'binary');
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo get requestBody content unknown/encodingtype schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody content unknown/encodingtype schema)))->to_string,
          error => 'subschema is false',
        },
      ],
    },
    'wildcard support in the media type registry is used to handle an otherwise-unknown content type',
  );



  # this will match against the document at image/*
  # but we have no media-type registry for image/*, only image/jpeg
  $openapi->add_media_type('image/jpeg' => sub ($value) { $value });
  $request = request('GET', 'http://example.com/foo', [ 'Content-Type' => 'image/jpeg' ], 'binary');
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo get requestBody content iMAgE/* schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody content iMAgE/* schema)))->to_string,
          error => 'subschema is false',
        },
      ],
    },
    'Content-Type header is matched to a wildcard entry in the document, then matched to a media-type implementation',
  );


  $request = request('GET', 'http://example.com/foo', [ 'Content-Type' => 'application/json; charset=UTF-8' ],
    '{"alpha": "123", "beta": "'.chr(0xe9).'clair"}');
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo get requestBody content application/json)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody content application/json)))->to_string,
          error => re(qr/^could not decode content as UTF-8: UTF-8 "\\xE9" does not map to Unicode/),
        },
      ],
    },
    'errors during charset decoding are detected',
  );


  $request = request('GET', 'http://example.com/foo', [ 'Content-Type' => 'application/json; charset=UTF-8' ],
    '{corrupt json');
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo get requestBody content application/json)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody content application/json)))->to_string,
          error => re(qr/^could not decode content as application\/json: \'"\' expected, at character offset 1/),
        },
      ],
    },
    'errors during media-type decoding are detected',
  );


  $request = request('GET', 'http://example.com/foo', [ 'Content-Type' => 'application/json; charset=ISO-8859-1' ],
    '{"alpha": "123", "beta": "'.chr(0xe9).'clair"}');
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    { valid => true },
    'content matches',
  );


  $request = request('GET', 'http://example.com/foo', [ 'Content-Type' => 'application/json; charset=UTF-8' ],
    '{"alpha": "foo", "gamma": "o.o"}');
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/alpha',
          keywordLocation => jsonp(qw(/paths /foo get requestBody content application/json schema properties alpha pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody content application/json schema properties alpha pattern)))->to_string,
          error => 'pattern does not match',
        },
        {
          instanceLocation => '/request/body/gamma',
          keywordLocation => jsonp(qw(/paths /foo get requestBody content application/json schema properties gamma const)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody content application/json schema properties gamma const)))->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo get requestBody content application/json schema properties)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody content application/json schema properties)))->to_string,
          error => 'not all properties are valid',
        },
      ],
    },
    'decoded content does not match the schema',
  );


  my $disapprove = v224.178.160.95.224.178.160; # utf-8-encoded "ಠ_ಠ"
  $request = request('GET', 'http://example.com/foo', [ 'Content-Type' => 'application/json; charset=UTF-8' ],
    '{"alpha": "123", "gamma": "'.$disapprove.'"}');
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    { valid => true },
    'decoded content matches the schema',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    get:
      requestBody:
        required: true
        content:
          '*/*':
            schema:
              minLength: 10
YAML

  $request = request('GET', 'http://example.com/foo', [ 'Content-Type' => 'unsupported/unsupported' ], '!!!');
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo get requestBody content */* schema minLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody content */* schema minLength)))->to_string,
          error => 'length is less than 10',
        },
      ],
    },
    'unknown content type can still be evaluated if */* is an acceptable media-type',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    get:
      requestBody:
        required: true
        content:
          text/plain: {}
YAML

  $request = request('GET', 'http://example.com/foo', [ 'Content-Type' => 'text/plain' ], '!!!');
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    { valid => true },
    'empty media-type object is not an error',
  );
};

subtest 'document errors' => sub {
  my $request = request('GET', 'http://example.com/foo?alpha=1');
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
components:
  parameters:
    alpha:
      name: alpha
      in: query
      required: true
      schema: {}
paths:
  /foo:
    parameters:
    - \$ref: '#/components/parameters/alpha'
    - \$ref: '#/components/parameters/alpha'
    get: {}
YAML

  cmp_deeply(
    (my $result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo parameters 1 $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/parameters/alpha')->to_string,
          error => 'duplicate query parameter "alpha"',
        },
      ],
    },
    'duplicate query parameters in path-item section',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
components:
  parameters:
    alpha:
      name: alpha
      in: query
      required: true
      schema: {}
paths:
  /foo:
    get:
      parameters:
      - \$ref: '#/components/parameters/alpha'
      - \$ref: '#/components/parameters/alpha'
YAML

  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo get parameters 1 $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/parameters/alpha')->to_string,
          error => 'duplicate query parameter "alpha"',
        },
      ],
    },
    'duplicate query parameters in operation section',
  );
};

subtest 'type handling of values for evaluation' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo/{foo_id}:
    parameters:
    - name: foo_id
      in: path
      required: true
      schema:
        pattern: ^[a-z]\$
    post:
      parameters:
      - name: bar
        in: query
        required: false
        schema:
          pattern: ^[a-z]\$
      - name: Foo-Bar
        in: header
        required: false
        schema:
          pattern: ^[a-z]\$
      requestBody:
        required: true
        content:
          text/plain:
            schema:
              pattern: ^[a-z]\$
YAML

  my $request = request('POST', 'http://example.com/foo/123?bar=456',
    [ 'Foo-Bar' => 789, 'Content-Type' => 'text/plain' ], 666);
  cmp_deeply(
    (my $result = $openapi->validate_request($request,
      { path_template => '/foo/{foo_id}', path_captures => { foo_id => 123 } }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/bar',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(post parameters 0 schema pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(post parameters 0 schema pattern)))->to_string,
          error => 'pattern does not match',
        },
        {
          instanceLocation => '/request/header/Foo-Bar',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(post parameters 1 schema pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(post parameters 1 schema pattern)))->to_string,
          error => 'pattern does not match',
        },
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(parameters 0 schema pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(parameters 0 schema pattern)))->to_string,
          error => 'pattern does not match',
        },
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(post requestBody content text/plain schema pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(post requestBody content text/plain schema pattern)))->to_string,
          error => 'pattern does not match',
        },
      ],
    },
    'numeric values are treated as strings by default',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo/{foo_id}:
    parameters:
    - name: foo_id
      in: path
      required: true
      schema:
        type: number
        maximum: 10
    post:
      parameters:
      - name: bar
        in: query
        required: false
        schema:
          type: integer
          maximum: 10
      - name: Foo-Bar
        in: header
        required: false
        schema:
          type: number
          maximum: 10
      requestBody:
        required: true
        content:
          text/plain:
            schema:
              type: number
              maximum: 10
YAML

  cmp_deeply(
    ($result = $openapi->validate_request($request,
      { path_template => '/foo/{foo_id}', path_captures => { foo_id => 123 } }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/bar',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(post parameters 0 schema maximum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(post parameters 0 schema maximum)))->to_string,
          error => 'value is larger than 10',
        },
        {
          instanceLocation => '/request/header/Foo-Bar',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(post parameters 1 schema maximum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(post parameters 1 schema maximum)))->to_string,
          error => 'value is larger than 10',
        },
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(parameters 0 schema maximum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(parameters 0 schema maximum)))->to_string,
          error => 'value is larger than 10',
        },
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(post requestBody content text/plain schema maximum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(post requestBody content text/plain schema maximum)))->to_string,
          error => 'value is larger than 10',
        },
      ],
    },
    'numeric values are treated as numbers when explicitly type-checked as numbers',
  );


  my $val = 20; my $str = sprintf("%s\n", $val);
  $request = request('POST', 'http://example.com/foo/9', [ 'Content-Type' => 'text/plain' ], $val);
  cmp_deeply(
    ($result = $openapi->validate_request($request,
      { path_template => '/foo/{foo_id}', path_captures => { foo_id => 9 } }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(post requestBody content text/plain schema maximum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(post requestBody content text/plain schema maximum)))->to_string,
          error => 'value is larger than 10',
        },
      ],
    },
    'ambiguously-typed numbers are still handled gracefully',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo:
    post:
      requestBody:
        required: false
        content:
          text/plain:
            schema:
              minLength: 10
YAML

  # bypass auto-initialization of Content-Length, Content-Type
  $request = request('POST', 'http://example.com/foo', [ 'Content-Length' => 1 ], '!');
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/header/Content-Type',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content)))->to_string,
          error => 'missing header: Content-Type',
        },
      ],
    },
    'missing Content-Type does not cause an exception',
  );

  # bypass auto-initialization of Content-Length, Content-Type; leave Content-Length empty
  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'text/plain' ], '!');
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content text/plain schema minLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content text/plain schema minLength)))->to_string,
          error => 'length is less than 10',
        },
      ],
    },
    'missing Content-Length does not prevent the request body from being checked',
  );


  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'text/plain' ]);
  cmp_deeply(
    ($result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    { valid => true },
    'request body is missing but not required',
  );
};

subtest 'max_depth' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    evaluator => JSON::Schema::Modern->new(max_traversal_depth => 15),
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
components:
  parameters:
    foo:
      \$ref: '#/components/parameters/bar'
    bar:
      \$ref: '#/components/parameters/foo'
paths:
  /foo:
    post:
      parameters:
      - \$ref: '#/components/parameters/foo'
YAML

  my $request = request('POST', 'http://example.com/foo');
  cmp_deeply(
    (my $result = $openapi->validate_request($request, { path_template => '/foo', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo post parameters 0), ('$ref')x16),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/parameters/bar')->to_string,
          error => 'EXCEPTION: maximum evaluation depth exceeded',
        },
      ],
    },
    'bad $ref in operation parameters',
  );
};

goto START if ++$type_index < @::TYPES;

done_testing;
