# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use lib 't/lib';
use Helper;
use Test2::Warnings qw(:no_end_test warnings had_no_warnings);
use JSON::Schema::Modern::Utilities qw(jsonp get_type);
use OpenAPI::Modern::Utilities 'uri_encode';

my $doc_uri_rel = Mojo::URL->new('/api');
my $doc_uri = $doc_uri_rel->to_abs(Mojo::URL->new('http://example.com'));
my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

my $type_index = 0;

START:
$::TYPE = $::TYPES[$type_index];
note 'REQUEST/RESPONSE TYPE: '.$::TYPE;

subtest $::TYPE.': missing or invalid arguments' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths: {}
YAML

  like(
    exception { $openapi->validate_request(undef) },
    qr/^missing request/,
    'request must be passed',
  );

  is_equal(
    $openapi->validate_request(bless({}, 'Bespoke::Request'), my $options = {})->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => '',
          absoluteKeywordLocation => $doc_uri->to_string,
          error => 'Failed to parse request: unknown type Bespoke::Request',
        },
      ],
    },
    'request must be a recognized type',
  );
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
    },
    'options hash is populated with the conversion attempt',
  );

  like(
    exception {
      $openapi->validate_request(
        request('GET', 'http://example.com/foo'), { request => request('GET', 'http://example.com/foo') })
    },
    qr/^\$request and \$options->\{request\} are inconsistent/,
    'if request is passed twice, it must be the same object (not just the same values)',
  );
};

subtest $::TYPE.': validation errors, request uri paths' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get:
      parameters:
      - name: foo_id
        in: path
        required: true
        schema:
          pattern: ^[0-9]+$
YAML

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/foo'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo get parameters 0 required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 0 required)))->to_string,
          error => 'missing path parameter: foo_id',
        },
      ],
    },
    'path parameter is missing',
  );

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/foo'), my $options = { path_captures => { foo_id => 1 } })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo)))->to_string,
          error => 'provided path_captures names do not match path template "/foo"',
        },
      ],
    },
    'extra path_capture value provided',
  );
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      uri => isa('Mojo::URL'),
      path_template => '/foo',
      method => 'GET',
      path_captures => { foo_id => 1 },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo get)))),
    },
    'options is populated with all inferred data so far',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{foo_id}:
    get:
      parameters:
      - name: foo_id
        in: path
        required: true
        schema:
          pattern: ^[0-9]+$
YAML

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/foo/bar'))->TO_JSON,
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
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{foo_id}:
    get:
      parameters:
      - name: foo_id
        in: path
        required: true
        content:
          application/json: {}
      - name: Bar
        in: header
        required: false
        content:
          electric/boogaloo: {}
YAML

  cmp_result(
    $openapi->validate_request(request('GET', 'http://example.com/foo/corrupt_json'))->TO_JSON,
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
    'corrupt data is detected, even when there is no schema',
  );

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/foo/{}', [ Bar => 1 ]))->TO_JSON,
    { valid => true },
    'valid encoded content is always valid when there is no schema, and unknown media types are okay',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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

  cmp_result(
    $openapi->validate_request(request('GET', 'http://example.com/foo/corrupt_json'))->TO_JSON,
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

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/foo/{"hello":"there"}'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} get parameters 0 content application/json schema required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get parameters 0 content application/json schema required)))->to_string,
          error => 'object is missing property: key',
        },
      ],
    },
    'parameters are decoded using the indicated media type and then validated against the content schema',
  );

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/foo/%7B%22key%22:1%7D'))->TO_JSON,
    { valid => true },
    'path parameter is uri-decoded first before evaluating',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{foo_id}/bar/{bar_id}:
    parameters:
    - name: foo_id
      in: path
      required: true
      schema:
        pattern: ^[0-9]+$
    - name: bar_id
      in: path
      required: true
      schema:
        pattern: ^[0-9]+$
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

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/foo/foo/bar/bar'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id}/bar/{bar_id} get parameters 0 schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id}/bar/{bar_id} get parameters 0 schema maxLength)))->to_string,
          error => 'length is greater than 1',
        },
        {
          instanceLocation => '/request/uri/path/bar_id',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id}/bar/{bar_id} parameters 1 schema pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id}/bar/{bar_id} parameters 1 schema pattern)))->to_string,
          error => 'pattern does not match',
        },
      ],
    },
    'path parameters: operation overshadows path-item',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => do {
      $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML');
paths:
  /foo/{foo_id}:
    get: {}
YAML
    },
  );

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/foo/foo'))->TO_JSON,
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

subtest $::TYPE.': path-item lookup' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.'paths: {}'),
  );
  my $result = $openapi->validate_request(request('GET', 'https://example.com'), my $options = {});
  isa_ok($result, ['JSON::Schema::Modern::Result'], 'got a result object back');
  is_equal(
    $result->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri.'#/paths',
          error => 'no match found for request GET https://example.com',
        },
      ],
    },
    'match failure from find_path_item()',
  );
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      uri => isa('Mojo::URL'),
      method => 'GET',
    },
    'options is populated with all inferred data so far',
  );
};

subtest $::TYPE.': validation errors in requests' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post: {}
YAML

  my $request = request('POST', 'http://example.com/foo');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    { valid => true },
    'operation can be empty',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      parameters:
      - $ref: 'http://example.com/otherapi#/i_do_not_exist'
YAML

  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo post parameters 0 $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 0 $ref)))->to_string,
          error => 'EXCEPTION: unable to find resource "http://example.com/otherapi#/i_do_not_exist"',
        },
      ],
    },
    'bad $ref in operation parameters',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    parameters:
    - $ref: 'http://example.com/otherapi#/i_do_not_exist'
    post: {}
YAML

  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo parameters 0 $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo parameters 0 $ref)))->to_string,
          error => 'EXCEPTION: unable to find resource "http://example.com/otherapi#/i_do_not_exist"',
        },
      ],
    },
    'bad $ref in path-item parameters',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  parameters:
    foo:
      $ref: 'http://example.com/otherapi#/i_do_not_exist'
paths:
  /foo:
    post:
      parameters:
      - $ref: '#/components/parameters/foo'
YAML

  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo post parameters 0 $ref $ref)),
          absoluteKeywordLocation => $doc_uri.'#/components/parameters/foo/$ref',
          error => 'EXCEPTION: unable to find resource "http://example.com/otherapi#/i_do_not_exist"',
        },
      ],
    },
    'bad $ref to $ref in operation parameters',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  parameters:
    foo-header:
      name: Alpha
      in: header
      required: true
      schema:
        type: string
        pattern: ^[0-9]+$
    bar-header-ref:
      $ref: '#/components/parameters/bar-header'
    bar-header:
      name: Beta
      in: header
      required: true
      schema:
        type: string
        pattern: ^[0-9]+$
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
          pattern: ^[0-9]+$
      - $ref: '#/components/parameters/foo-header'
      - name: beta
        in: query
        required: false
        schema:
          const: 123
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
            schema:
              not: true
      - name: epsilon
        in: query
        required: false
        content:
          apPlicATion/jsON:
            schema:
              not: true
      - name: zeta
        in: query
        required: false
        content:
          iMAgE/*:
            schema:
              not: true
      - $ref: '#/components/parameters/bar-header-ref'
YAML
  # note that bar_id is not listed as a path parameter

  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => jsonp(qw(/paths /foo post parameters 0 required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 0 required)))->to_string,
          error => 'missing query parameter: alpha',
        },
        {
          instanceLocation => '/request/header',
          keywordLocation => jsonp(qw(/paths /foo post parameters 1 $ref required)),
          absoluteKeywordLocation => $doc_uri.'#/components/parameters/foo-header/required',
          error => 'missing header: Alpha',
        },
        {
          instanceLocation => '/request/header',
          keywordLocation => jsonp(qw(/paths /foo post parameters 7 $ref $ref required)),
          absoluteKeywordLocation => $doc_uri.'#/components/parameters/bar-header/required',
          error => 'missing header: Beta',
        },
      ],
    },
    'query and header parameters are missing; header names are case-insensitive',
  );

  $request = request('POST', 'http://example.com/foo?alpha=1&gamma=foo&delta=bar', [ Alpha => 1, Beta => 1 ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
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

  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/delta',
          keywordLocation => jsonp(qw(/paths /foo post parameters 4 content unknown/encodingtype schema not)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 4 content unknown/encodingtype schema not)))->to_string,
          error => 'subschema is true',
        },
      ],
    },
    'after adding wildcard support, this parameter can be parsed',
  );

  $request = request('POST', 'http://example.com/foo', [ Alpha => 1, Beta => 1 ]);
  query_params($request, [ alpha => 1, epsilon => '{"foo":42}' ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/epsilon',
          keywordLocation => jsonp(qw(/paths /foo post parameters 5 content apPlicATion/jsON schema not)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 5 content apPlicATion/jsON schema not)))->to_string,
          error => 'subschema is true',
        },
      ],
    },
    'media-types in the openapi document are looked up case-insensitively',
  );

  $openapi->add_media_type('image/*' => sub ($value) { $value });

  $request = request('POST', 'http://example.com/foo?alpha=1&zeta=binary', [ Alpha => 1, Beta => 1 ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/zeta',
          keywordLocation => jsonp(qw(/paths /foo post parameters 6 content iMAgE/* schema not)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 6 content iMAgE/* schema not)))->to_string,
          error => 'subschema is true',
        },
      ],
    },
    'wildcard media-types in the openapi document are looked up case-insensitively too',
  );

  $request = request('POST', 'http://example.com/foo?alpha=hello&beta=3.1415',
    [ 'alpha' => 'header value', Beta => 1 ]);    # exactly matches query parameter
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
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
          absoluteKeywordLocation => $doc_uri.'#/components/parameters/foo-header/schema/pattern',
          error => 'pattern does not match',
        },
        {
          instanceLocation => '/request/uri/query/beta',
          keywordLocation => jsonp(qw(/paths /foo post parameters 2 schema const)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post parameters 2 schema const)))->to_string,
          error => 'value does not match',
        },
      ],
    },
    'query and header parameters are evaluated against their schemas',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{null_path}/{boolean_path}:
    parameters:
    - name: null_path
      in: path
      required: true
      schema:
        type: 'null'
    - name: boolean_path
      in: path
      required: true
      schema:
        type: boolean
        const: true
    get:
      parameters:
      - name: null_query
        in: query
        required: false
        schema:
          type: 'null'
      - name: boolean_query
        in: query
        required: false
        schema:
          type: boolean
          const: true
      - name: NullHeader
        in: header
        required: false
        schema:
          type: 'null'
      - name: BooleanHeader
        in: header
        required: false
        schema:
          type: boolean
          const: true
YAML

  $request = request('GET', 'http://example.com/foo/bar/baz?null_query=foo&boolean_query=no',
    [ NullHeader => 'foo', BooleanHeader => 'no' ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/null_query',
          keywordLocation => jsonp(qw(/paths /foo/{null_path}/{boolean_path} get parameters 0)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{null_path}/{boolean_path} get parameters 0)))->to_string,
          error => 'cannot deserialize to requested type (null)',
        },
        {
          instanceLocation => '/request/uri/query/boolean_query',
          keywordLocation => jsonp(qw(/paths /foo/{null_path}/{boolean_path} get parameters 1)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{null_path}/{boolean_path} get parameters 1)))->to_string,
          error => 'cannot deserialize to requested type (boolean)',
        },
        {
          instanceLocation => '/request/header/NullHeader',
          keywordLocation => jsonp(qw(/paths /foo/{null_path}/{boolean_path} get parameters 2)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{null_path}/{boolean_path} get parameters 2)))->to_string,
          error => 'cannot deserialize to requested type (null)',
        },
        {
          instanceLocation => '/request/header/BooleanHeader',
          keywordLocation => jsonp(qw(/paths /foo/{null_path}/{boolean_path} get parameters 3)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{null_path}/{boolean_path} get parameters 3)))->to_string,
          error => 'cannot deserialize to requested type (boolean)',
        },
        {
          instanceLocation => '/request/uri/path/null_path',
          keywordLocation => jsonp(qw(/paths /foo/{null_path}/{boolean_path} parameters 0)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{null_path}/{boolean_path} parameters 0)))->to_string,
          error => 'cannot deserialize to requested type (null)',
        },
        {
          instanceLocation => '/request/uri/path/boolean_path',
          keywordLocation => jsonp(qw(/paths /foo/{null_path}/{boolean_path} parameters 1)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{null_path}/{boolean_path} parameters 1)))->to_string,
          error => 'cannot deserialize to requested type (boolean)',
        },
      ],
    },
    'query and header parameters are attempted to be parsed to their requested types',
  );

  $request = request('GET', 'http://example.com/foo//true?null_query=&boolean_query=1',
    [ NullHeader => '', BooleanHeader => 1 ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    { valid => true },
    'query and header parameters are successfully parsed to their requested types',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    parameters:
    - name: qs
      in: querystring
      content:
        text/plain:
          schema: {}
    get:
      parameters:
      - name: q
        in: query
        schema: {}
  /bar:
    parameters:
    - name: qs
      in: querystring
      content:
        text/plain:
          schema: {}
    get:
      parameters:
      - name: qs
        in: querystring
        content:
          text/plain:
            schema: {}
YAML

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/foo'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => jsonp(qw(/paths /foo parameters 0)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo parameters 0)))->to_string,
          error => 'cannot use query and querystring together',
        },
      ],
    },
    'query and querystring conflicting across path-item and operation is detected at runtime',
  );

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/bar'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => jsonp(qw(/paths /bar parameters 0)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /bar parameters 0)))->to_string,
          error => 'cannot use more than one querystring',
        },
      ],
    },
    'two querystrings conflicting across path-item and operation is detected at runtime',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  schemas:
    simple_object:
      type: object
      required: [key]
      minProperties: 2
      properties:
        key:
          type: string
          maxLength: 1
          const: ಠ
paths:
  /string:
    get:
      parameters:
      - name: qs      # the name is not used in the querystring
        in: querystring
        required: true
        content:
          text/plain;charset=utf-8:
            schema:
              type: string
              maxLength: 1
              const: ಠ
  /emptystring:
    get:
      parameters:
      - name: qs      # the name is not used in the querystring
        in: querystring
        required: true
        content:
          text/plain;charset=utf-8:
            schema:
              type: string
              maxLength: 0
  /application/json:
    get:
      parameters:
      - name: qs
        in: querystring
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/simple_object'
  /application/x-www-form-urlencoded:
    get:
      parameters:
      - name: qs
        in: querystring
        content:
          application/x-www-form-urlencoded:
            schema:
              $ref: '#/components/schemas/simple_object'
YAML

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/string'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => jsonp(qw(/paths /string get parameters 0 required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /string get parameters 0 required)))->to_string,
          error => 'missing querystring',
        },
      ],
    },
    'when querystring is required, the URI must have a query',
  );

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/emptystring?'))->TO_JSON,
    { valid => true },
    'empty querystring still counts as being provided',
  );

  if ($::TYPE eq 'mojo') {
    my @warnings = warnings {
      my $request = request('GET', 'http://example.com/string?hi');
      ()= $request->url->query->pairs;
      is_equal(
        $openapi->validate_request($request)->TO_JSON,
        {
          valid => false,
          errors => [
            {
              instanceLocation => '/request/uri/query',
              keywordLocation => jsonp(qw(/paths /string get parameters 0 required)),
              absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /string get parameters 0 required)))->to_string,
              error => 'missing querystring',
            },
          ],
        },
        'querystring cannot be found after something else tampered with the uri query parameters',
      );
    };
    cmp_result(
      \@warnings,
      [ re(qr{^\Qrequest uri querystring has been lost: see L<OpenAPI::Modern/LIMITATIONS> for how to avoid\E}) ],
      'warning issued after something else tampered with the uri query parameters',
    );
  }

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/string?hi'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => jsonp(qw(/paths /string get parameters 0 content text/plain;charset=utf-8 schema const)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /string get parameters 0 content text/plain;charset=utf-8 schema const)))->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => jsonp(qw(/paths /string get parameters 0 content text/plain;charset=utf-8 schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /string get parameters 0 content text/plain;charset=utf-8 schema maxLength)))->to_string,
          error => 'length is greater than 1',
        },
      ],
    },
    'text/plain querystring is parsed as a string',
  );

  is_equal(
    $openapi->validate_request($request = request('GET', 'http://example.com/string?%23'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => jsonp(qw(/paths /string get parameters 0 content text/plain;charset=utf-8 schema const)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /string get parameters 0 content text/plain;charset=utf-8 schema const)))->to_string,
          error => 'value does not match',
        },
      ],
    },
    'text/plain querystring is percent-decoded and then parsed as a string',
  );

  is_equal(
    $openapi->validate_request($request = request('GET', 'http://example.com/string?%e0%b2%a0'))->TO_JSON,
    { valid => true },
    'text/plain querystring is percent-decoded and then parsed as a string, respecting the charset',
  );

  is_equal(
    $openapi->validate_request($request = request('GET', 'http://example.com/application/json?%7B%7D'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => jsonp(qw(/paths /application/json get parameters 0 content application/json schema $ref minProperties)),
          absoluteKeywordLocation => $doc_uri.'#/components/schemas/simple_object/minProperties',
          error => 'object has fewer than 2 properties',
        },
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => jsonp(qw(/paths /application/json get parameters 0 content application/json schema $ref required)),
          absoluteKeywordLocation => $doc_uri.'#/components/schemas/simple_object/required',
          error => 'object is missing property: key',
        },
      ],
    },
    'application/json querystring is parsed as an object',
  );

  # perl -Mutf8 -MMojo::Util=url_escape -MCpanel::JSON::XS -wlE'say url_escape(Cpanel::JSON::XS->new->pretty(0)->canonical->utf8->encode({ key => "ಠ", hello => 1 }))'
  is_equal(
    $openapi->validate_request($request = request('GET', 'http://example.com/application/json?%7B%22hello%22%3A1%2C%22key%22%3A%22%E0%B2%A0%22%7D'))->TO_JSON,
    { valid => true },
    'application/json querystring is url-decoded and properly json-decoded',
  );

  is_equal(
    $openapi->validate_request($request = request('GET', 'http://example.com/application/x-www-form-urlencoded?foo=1'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => jsonp(qw(/paths /application/x-www-form-urlencoded get parameters 0 content application/x-www-form-urlencoded schema $ref minProperties)),
          absoluteKeywordLocation => $doc_uri.'#/components/schemas/simple_object/minProperties',
          error => 'object has fewer than 2 properties',
        },
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => jsonp(qw(/paths /application/x-www-form-urlencoded get parameters 0 content application/x-www-form-urlencoded schema $ref required)),
          absoluteKeywordLocation => $doc_uri.'#/components/schemas/simple_object/required',
          error => 'object is missing property: key',
        },
      ],
    },
    'application/x-www-form-urlencoded querystring is parsed as an object',
  );

  is_equal(
    $openapi->validate_request($request = request('GET', 'http://example.com/application/x-www-form-urlencoded?key=%e0%b2%a0&bar=2'))->TO_JSON,
    { valid => true },
    'application/x-www-form-urlencoded querystring is url-decoded and properly decoded',
  );


  # see examples in 3.2.0 §4.12.8
  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{username}:
    get: {}
    parameters:
      - name: username
        in: path
        description: username to fetch
        required: true
        schema:
          type: string
          enum: [ edijkstra, diṅnāga, الخوارزميّ ]
        examples:
          "Edsger Dijkstra":
            dataValue: edijkstra
            serializedValue: edijkstra
          Diṅnāga:
            dataValue: diṅnāga
            serializedValue: di%E1%B9%85n%C4%81ga
          Al-Khwarizmi:
            dataValue: "الخوارزميّ"
            serializedValue: "%D8%A7%D9%84%D8%AE%D9%88%D8%A7%D8%B1%D8%B2%D9%85%D9%8A%D9%91"
YAML

  foreach my $username (qw(diṅnāga الخوارزميّ)) {
    $request = request('GET', 'http://example.com/foo/'.$username);
    is_equal(
      (my $result = $openapi->validate_request($request))->TO_JSON,
      { valid => true },
      'all path parameters are validated',
    );
    is_equal(
      $result->data,
      { request => { uri => { path => { username => $username } } } },
      'data is correctly deserialized',
    );
  }


  # see examples in 3.2.0 §4.12.8
  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get: {}
    parameters:
      - name: thing
        in: query
        required: true
        schema:
          type: array
          items:
            type: string
          const:
            - one thing
            - another thing
        style: form
        explode: true
        examples:
          ObjectList:
            dataValue:
              - one thing
              - another thing
            serializedValue: "thing=one%20thing&thing=another%20thing"
      - name: coordinates
        in: query
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - lat
                - long
              properties:
                lat:
                  type: number
                long:
                  type: number
            examples:
              New York:
                dataValue:
                  lat: 40.6
                  long: -73.9
                serializedValue: '{"lat":40.6,"long":-73.9}'
        examples:
          New York:
            dataValue:
              lat: 40.6
              long: -73.9
            serializedValue: coordinates=%7B%22lat%22%3A40.6%2C%22long%22%3A-73.9%7D
YAML

  $request = request('GET', 'http://example.com/foo?'.join('&',
      'thing=one%20thing&thing=another%20thing',
      'coordinates=%7B%22lat%22%3A40.6%2C%22long%22%3A-73.9%7D'));
  is_equal(
    (my $result = $openapi->validate_request($request))->TO_JSON,
    { valid => true },
    'all query parameters are deserialized correctly',
  );
  is_equal(
    $result->data,
    {
      request => {
        uri => {
          query => {
            thing => [ 'one thing', 'another thing' ],
            coordinates => { lat => 40.6, long => -73.9 },
          },
        },
      },
    },
    'data is correctly deserialized',
  );


  # see examples in 3.2.0 §4.12.8
  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get: {}
    parameters:
      - description: 'A free-form query parameter, allowing arbitrary parameters of type: "integer"'
        name: freeForm
        in: query
        required: true
        schema:
          type: object
          additionalProperties:
            type: integer
          const:
            page: 4
            pageSize: 50
        style: form
        examples:
          Pagination:
            dataValue:
              page: 4
              pageSize: 50
            serializedValue: page=4&pageSize=50
YAML

  $request = request('GET', 'http://example.com/foo?page=4&pageSize=50');
  is_equal(
    ($result = $openapi->validate_request($request))->TO_JSON,
    { valid => true },
    'entire querystring is deserialized correctly into an object',
  );
  is_equal(
    $result->data,
    { request => { uri => { query => { freeForm => { page => 4, pageSize => 50 } } } } },
    'data is correctly deserialized',
  );


  # see examples in 3.2.0 §4.12.8
  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get: {}
    parameters:
      - name: selector
        in: querystring
        content:
          application/jsonpath:
            schema:
              type: string
            example: $.a.b[1:1]
        examples:
          Selector:
            serializedValue: "%24.a.b%5B1%3A1%5D"
YAML

  $openapi->add_media_type('application/jsonpath', sub ($x) { $x });
  $request = request('GET', 'http://example.com/foo?%24.a.b%5B1%3A1%5D');
  is_equal(
    ($result = $openapi->validate_request($request))->TO_JSON,
    { valid => true },
    'entire querystring is deserialized correctly as a string',
  );
  is_equal(
    $result->data,
    { request => { uri => { query => '$.a.b[1:1]' } } },
    'data is correctly deserialized',
  );


  # see examples in 3.2.0 §4.12.8
  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get: {}
    parameters:
      - description: 'A cookie parameter relying on the percent-encoding behavior of the default `style: "form"`'
        name: greeting
        in: cookie
        schema:
          $comment: this parameter will fetch just the named parameter, as a string, using style=form
          type: string
        examples:
          Greeting:
            description: |
              Note that in this approach, RFC6570's percent-encoding
              process applies, so unsafe characters are not
              pre-percent-encoded.  This results in all non-URL-safe
              characters, rather than just the one non-cookie-safe
              character, getting percent-encoded.
            dataValue: Hello, world!
            serializedValue: "greeting=Hello%2C%20world%21"
YAML

  $request = request('GET', 'http://example.com/foo', [ Cookie => 'greeting=Hello%2C%20world%21' ]);
  is_equal(
    ($result = $openapi->validate_request($request))->TO_JSON,
    { valid => true },
    'cookie parameter is validated',
  );
  is_equal(
    $result->data,
    { request => { header => { Cookie => { greeting => 'Hello, world!' } } } },
    'cookie data was correctly deserialized',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get: {}
    parameters:
      - description: 'A cookie parameter with an exploded object (the default for `style: "cookie"`)'
        name: cookie
        in: cookie
        style: cookie
        schema:
          $comment: this parameter will fetch all cookie parameters as an object
          type: object
          properties:
            greeting:
              type: string
            code:
              type: integer
              minimum: 0
        examples:
          Object:
            description: |
                Note that the comma (,) has been pre-percent-encoded
                to "%2C" in the data, as it is forbidden in
                cookie values.  However, the exclamation point (!)
                is legal in cookies, so it can be left unencoded.
                (and fixed, to remove the un-encoded space)
            dataValue:
              greeting: Hello%2C%20world!
              code: 42
            serializedValue: "greeting=Hello%2C%20world!; code=42"
YAML

  $request = request('GET', 'http://example.com/foo', [ Cookie => 'greeting=Hello%2C%20world!; code=42' ]);
  is_equal(
    ($result = $openapi->validate_request($request))->TO_JSON,
    { valid => true },
    'cookie parameter is validated',
  );
  is_equal(
    $result->data,
    { request => { header => { Cookie => { cookie => { greeting => 'Hello%2C%20world!', code => 42 } } } } },
    'cookie data was correctly deserialized',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{path_token}:
    get: {}
    parameters:
      - name: path_token
        in: path
        required: true
        schema:
          type: array
          items:
            type: integer
            format: int64
          const: [ 12345678, 90099 ]
        style: simple
        examples:
          Tokens:
            dataValue:
              - 12345678
              - 90099
            serializedValue: "12345678,90099"
      - name: X-Token
        in: header
        description: token to be passed as a header
        required: true
        schema:
          type: array
          items:
            type: integer
            format: int64
          const: [ 12345678, 90099 ]
        style: simple
        examples:
          Tokens:
            dataValue:
              - 12345678
              - 90099
            serializedValue: "12345678,90099"
YAML

  $request = request('GET', 'http://example.com/foo/12345678,90099', [ 'X-Token' => '12345678,90099' ]);
  is_equal(
    ($result = $openapi->validate_request($request))->TO_JSON,
    { valid => true },
    'all path and header parameters are validated',
  );
  is_equal(
    $result->data,
    {
      request => {
        uri => { path => { path_token => [ 12345678, 90099 ] } },
        header => { 'X-Token' => [ 12345678, 90099 ] },
      },
    },
    'header data was correctly deserialized',
  );


  # note: characters in parameter names and values that look like - are actually − U+2212 %E2%88%92
  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
servers:
  - url: http://{host}.example.com/{subdir}
    variables:
      host:
        default: prod
        enum: [dev, stg, prod, st💩g]
      subdir:
        default: blah
paths:
  /{path−simple−string}/{path−simple−array−false}/{path−simple−array−true}/{path−simple−object−false}/{path−simple−object−true}/{cølör0}/{cølör1}/{cølör2}/{cølör3}/{cølör4}/{path−label−string}/{path−label−array−false}/{path−label−array−true}/{path−label−object−false}/{path−label−object−true}:
    get: {}
    parameters:
      - name: path−simple−string
        in: path
        required: true
        schema:
          const: red﹠green
      - name: path−simple−array−false
        in: path
        required: true
        schema:
          type: array
          const: [ blue−black, blackish﹠green, 100𝑥brown ]
      - name: path−simple−array−true
        in: path
        required: true
        explode: true
        schema:
          type: array
          const: [ blue−black, blackish﹠green, 100𝑥brown ]
      - name: path−simple−object−false
        in: path
        required: true
        schema:
          type: object
          const: { blue−black: yes!, blackish﹠green: ¿no?, 100𝑥brown: fl¡p }
      - name: path−simple−object−true
        in: path
        required: true
        explode: true
        schema:
          type: object
          const: { blue−black: yes!, blackish﹠green: ¿no?, 100𝑥brown: fl¡p }
      - name: cølör0
        in: path
        required: true
        style: matrix
        schema:
          const: red﹠green
      - name: cølör1
        in: path
        required: true
        style: matrix
        schema:
          type: array
          const: [ blue−black, blackish﹠green, 100𝑥brown ]
      - name: cølör2
        in: path
        required: true
        style: matrix
        explode: true
        schema:
          type: array
          const: [ blue−black, blackish﹠green, 100𝑥brown ]
      - name: cølör3
        in: path
        required: true
        style: matrix
        schema:
          type: object
          const: { blue−black: yes!, blackish﹠green: ¿no?, 100𝑥brown: fl¡p }
      - name: cølör4
        in: path
        required: true
        style: matrix
        explode: true
        schema:
          type: object
          const: { blue−black: yes!, blackish﹠green: ¿no?, 100𝑥brown: fl¡p }
      - name: path−label−string
        in: path
        required: true
        style: label
        schema:
          const: red﹠gr.e.en
      - name: path−label−array−false
        in: path
        required: true
        style: label
        schema:
          type: array
          const: [ blue−black, blackish﹠green, 100𝑥brown ]
      - name: path−label−array−true
        in: path
        required: true
        style: label
        explode: true
        schema:
          type: array
          const: [ blue−black, blackish﹠green, 100𝑥brown ]
      - name: path−label−object−false
        in: path
        required: true
        style: label
        schema:
          type: object
          const: { blue−black: yes!, blackish﹠green: ¿no?, 100𝑥brown: fl¡p }
      - name: path−label−object−true
        in: path
        required: true
        style: label
        explode: true
        schema:
          type: object
          const: { blue−black: yes!, blackish﹠green: ¿no?, 100𝑥brown: fl¡p }
      - name: header-simple-string
        in: header
        required: true
        schema:
          const: red﹠green
      - name: header-simple-array-false
        in: header
        required: true
        schema:
          type: array
          const: [ blue−black, blackish﹠green, 100𝑥brown ]
      - name: header-simple-array-true
        in: header
        required: true
        explode: true
        schema:
          type: array
          const: [ blue−black, blackish﹠green, 100𝑥brown ]
      - name: header-simple-object-false
        in: header
        required: true
        schema:
          type: object
          const: { blue−black: yes!, blackish﹠green: ¿no?, 100𝑥brown: fl¡p }
      - name: header-simple-object-true
        in: header
        required: true
        explode: true
        schema:
          type: object
          const: { blue−black: yes!, blackish﹠green: ¿no?, 100𝑥brown: fl¡p }
      - name: query−form−string
        in: query
        required: true
        schema:
          type: string
          const: blue/blåck
      - name: query−form−array−false
        in: query
        required: true
        explode: false
        schema:
          type: array
          const: [ blue−black, black/ish﹠green, 100𝑥brown ]
      - name: query−form−array−true
        in: query
        required: true
        schema:
          type: array
          const: [ blue−black, black/ish﹠green, 100𝑥brown ]
      - name: query−form−object−false
        in: query
        required: true
        explode: false
        schema:
          type: object
          const: { réd: 100𝑥, grɘɇn: ¡ja, bløö: ¿neîn }
      # style=form, explode=true, type=object not tested here, as it pulls in the entire querystring

      - name: query−spaceDelimited−array
        in: query
        required: true
        style: spaceDelimited
        schema:
          type: array
          const: [ blue−black, black/ish﹠green, 100𝑥brown ]
      - name: query−spaceDelimited−object
        in: query
        required: true
        style: spaceDelimited
        schema:
          type: object
          const: { réd: 100𝑥, grɘɇn: ¡ja, bløö: ¿neîn }
      - name: query−pipeDelimited−array
        in: query
        required: true
        style: pipeDelimited
        schema:
          type: array
          const: [ blue−black, black/ish﹠green, 100𝑥brown ]
      - name: query−pipeDelimited−object
        in: query
        required: true
        style: pipeDelimited
        schema:
          type: object
          const: { réd: 100𝑥, grɘɇn: ¡ja, bløö: ¿neîn }
      - name: query−deepObject
        in: query
        required: true
        style: deepObject
        schema:
          const: { réd: 100𝑥, grɘɇn: ¡ja, bløö: ¿neîn }
      - name: cookie−form−string
        in: cookie
        required: true
        schema:
          type: string
          const: blue/blåck
      - name: cookie−form−array−true
        in: cookie
        required: true
        schema:
          type: array
          const: [ blue−black, black/ish﹠green, 100𝑥brown ]
      # style=form, explode=true, type=object not tested here, as it pulls in all cookie values
      - name: cookie-cookie-string
        in: cookie
        style: cookie
        required: true
        schema:
          type: string
          const: blue/black
      - name: cookie-cookie-array-true
        in: cookie
        style: cookie
        required: true
        schema:
          type: array
          const: [ blue-black, black/ish&green, 100xbrown ]
YAML

  $request = request('GET', 'http://st💩g.example.com/'.join('/', map uri_encode($_), '🐙',
    'red﹠green',
    ('blue−black,blackish﹠green,100𝑥brown')x2,
    'blue−black,yes!,blackish﹠green,¿no?,100𝑥brown,fl¡p',
    'blue−black=yes!,blackish﹠green=¿no?,100𝑥brown=fl¡p',
    ';cølör0=red﹠green',
    ';cølör1=blue−black,blackish﹠green,100𝑥brown',
    ';cølör2=blue−black;cølör2=blackish﹠green;cølör2=100𝑥brown',
    ';cølör3=blue−black,yes!,blackish﹠green,¿no?,100𝑥brown,fl¡p',
    ';blue−black=yes!;blackish﹠green=¿no?;100𝑥brown=fl¡p',
    '.red﹠gr.e.en',
    '.blue−black,blackish﹠green,100𝑥brown',
    '.blue−black.blackish﹠green.100𝑥brown',
    '.blue−black,yes!,blackish﹠green,¿no?,100𝑥brown,fl¡p',
    '.blue−black=yes!.blackish﹠green=¿no?.100𝑥brown=fl¡p',
    )
    .'?'.join('&', map uri_encode($_->[0]).'='.$_->[1], pairs(
      'query−form−string', 'blue%2Fbl%C3%A5ck',
      'query−form−array−false', 'blue%E2%88%92black,black%2Fish%EF%B9%A0green,100%F0%9D%91%A5brown',
      'query−form−array−true', 'blue%E2%88%92black',
      'query−form−array−true', 'black%2Fish%EF%B9%A0green',
      'query−form−array−true', '100%F0%9D%91%A5brown',
      'query−form−object−false', 'r%C3%A9d,100%F0%9D%91%A5,gr%C9%98%C9%87n,%C2%A1ja,bl%C3%B8%C3%B6,%C2%BFne%C3%AEn',
      'query−spaceDelimited−array', 'blue%E2%88%92black%20black%2Fish%EF%B9%A0green%20100%F0%9D%91%A5brown',
      'query−spaceDelimited−object', 'r%C3%A9d%20100%F0%9D%91%A5%20gr%C9%98%C9%87n%20%C2%A1ja%20bl%C3%B8%C3%B6%20%C2%BFne%C3%AEn',
      'query−pipeDelimited−array', 'blue%E2%88%92black%7Cblack%2Fish%EF%B9%A0green%7C100%F0%9D%91%A5brown',
      'query−pipeDelimited−object', 'r%C3%A9d%7C100%F0%9D%91%A5%7Cgr%C9%98%C9%87n%7C%C2%A1ja%7Cbl%C3%B8%C3%B6%7C%C2%BFne%C3%AEn',
      'query−deepObject[réd]', '100%F0%9D%91%A5',
      'query−deepObject[grɘɇn]', '%C2%A1ja',
      'query−deepObject[bløö]', '%C2%BFne%C3%AEn',
    )),
    [
      "header-simple-string" => "red\xef\xb9\xa0green",
      "header-simple-array-false" => "blue\xe2\x88\x92black,blackish\xef\xb9\xa0green,100\xf0\x9d\x91\xa5brown",
      "header-simple-array-true" => "blue\xe2\x88\x92black,blackish\xef\xb9\xa0green,100\xf0\x9d\x91\xa5brown",
      "header-simple-object-false" => "blue\xe2\x88\x92black,yes!,blackish\xef\xb9\xa0green,\xc2\xbfno?,100\xf0\x9d\x91\xa5brown,fl\xc2\xa1p",
      "header-simple-object-true" => "blue\xe2\x88\x92black=yes!,blackish\xef\xb9\xa0green=\xc2\xbfno?,100\xf0\x9d\x91\xa5brown=fl\xc2\xa1p",
      Cookie => join('; ',
        (map +(join '=', @$_), pairs(
          'cookie%E2%88%92form%E2%88%92string', 'blue%2Fbl%C3%A5ck',
          'cookie-cookie-string' => 'blue/black',
          'cookie-cookie-array-true' => 'blue-black',
          'cookie-cookie-array-true' => 'black/ish&green',
          'cookie-cookie-array-true' => '100xbrown',
        )),
        join('&', map +(join '=', @$_), pairs(
          'cookie%E2%88%92form%E2%88%92array%E2%88%92true', 'blue%E2%88%92black',
          'cookie%E2%88%92form%E2%88%92array%E2%88%92true', 'black%2Fish%EF%B9%A0green',
          'cookie%E2%88%92form%E2%88%92array%E2%88%92true', '100%F0%9D%91%A5brown',
        )),
      ),
    ],
  );

  is_equal(
    ($result = $openapi->validate_request($request, my $options = {}))->TO_JSON,
    { valid => true },
    'all path, header, query and cookie parameters are deserialized correctly',
  );

  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      uri => isa('Mojo::URL'),
      method => 'GET',
      path_template => '/{path−simple−string}/{path−simple−array−false}/{path−simple−array−true}/{path−simple−object−false}/{path−simple−object−true}/{cølör0}/{cølör1}/{cølör2}/{cølör3}/{cølör4}/{path−label−string}/{path−label−array−false}/{path−label−array−true}/{path−label−object−false}/{path−label−object−true}',
      do { my $path_captures = {
        'path−simple−array−false' => 'blue%E2%88%92black,blackish%EF%B9%A0green,100%F0%9D%91%A5brown',
        'path−simple−array−true' => 'blue%E2%88%92black,blackish%EF%B9%A0green,100%F0%9D%91%A5brown',
        'path−simple−object−false' => 'blue%E2%88%92black,yes!,blackish%EF%B9%A0green,%C2%BFno%3F,100%F0%9D%91%A5brown,fl%C2%A1p',
        'path−simple−object−true' => 'blue%E2%88%92black=yes!,blackish%EF%B9%A0green=%C2%BFno%3F,100%F0%9D%91%A5brown=fl%C2%A1p',
        'path−simple−string' => 'red%EF%B9%A0green',
        'cølör0' => ';c%C3%B8l%C3%B6r0=red%EF%B9%A0green',
        'cølör1' => ';c%C3%B8l%C3%B6r1=blue%E2%88%92black,blackish%EF%B9%A0green,100%F0%9D%91%A5brown',
        'cølör2' => ';c%C3%B8l%C3%B6r2=blue%E2%88%92black;c%C3%B8l%C3%B6r2=blackish%EF%B9%A0green;c%C3%B8l%C3%B6r2=100%F0%9D%91%A5brown',
        'cølör3' => ';c%C3%B8l%C3%B6r3=blue%E2%88%92black,yes!,blackish%EF%B9%A0green,%C2%BFno%3F,100%F0%9D%91%A5brown,fl%C2%A1p',
        'cølör4' => ';blue%E2%88%92black=yes!;blackish%EF%B9%A0green=%C2%BFno%3F;100%F0%9D%91%A5brown=fl%C2%A1p',
        'path−label−array−false' => '.blue%E2%88%92black,blackish%EF%B9%A0green,100%F0%9D%91%A5brown',
        'path−label−array−true' => '.blue%E2%88%92black.blackish%EF%B9%A0green.100%F0%9D%91%A5brown',
        'path−label−object−false' => '.blue%E2%88%92black,yes!,blackish%EF%B9%A0green,%C2%BFno%3F,100%F0%9D%91%A5brown,fl%C2%A1p',
        'path−label−object−true' => '.blue%E2%88%92black=yes!.blackish%EF%B9%A0green=%C2%BFno%3F.100%F0%9D%91%A5brown=fl%C2%A1p',
        'path−label−string' => '.red%EF%B9%A0gr.e.en',
      };
      path_captures => $path_captures,
      uri_captures => {
        host => 'st💩g',  # not 'xn--stg-ld23b'
        subdir => '🐙',   # not '%F0%9F%90%99'
        %$path_captures,
      }},
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /{path−simple−string}/{path−simple−array−false}/{path−simple−array−true}/{path−simple−object−false}/{path−simple−object−true}/{cølör0}/{cølör1}/{cølör2}/{cølör3}/{cølör4}/{path−label−string}/{path−label−array−false}/{path−label−array−true}/{path−label−object−false}/{path−label−object−true} get)))),
    },
    '$options are correct',
  );
  is_equal(
    $result->data,
    {
      request => {
        uri => {
          server => {
            host => 'st💩g',
            subdir => '🐙',
          },
          path => {
            'path−simple−string' => 'red﹠green',
            'path−simple−array−false' => [ qw(blue−black blackish﹠green 100𝑥brown) ],
            'path−simple−array−true' => [ qw(blue−black blackish﹠green 100𝑥brown) ],
            'path−simple−object−false' => { 'blue−black' => 'yes!', 'blackish﹠green' => '¿no?', '100𝑥brown' => 'fl¡p' },
            'path−simple−object−true' => { 'blue−black' => 'yes!', 'blackish﹠green' => '¿no?', '100𝑥brown' => 'fl¡p' },
            'cølör0' => 'red﹠green',
            'cølör1' => [ qw(blue−black blackish﹠green 100𝑥brown) ],
            'cølör2' => [ qw(blue−black blackish﹠green 100𝑥brown) ],
            'cølör3' => { 'blue−black' => 'yes!', 'blackish﹠green' => '¿no?', '100𝑥brown' => 'fl¡p' },
            'cølör4' => { 'blue−black' => 'yes!', 'blackish﹠green' => '¿no?', '100𝑥brown' => 'fl¡p' },
            'path−label−string' => 'red﹠gr.e.en',
            'path−label−array−false' => [ qw(blue−black blackish﹠green 100𝑥brown) ],
            'path−label−array−true' => [ qw(blue−black blackish﹠green 100𝑥brown) ],
            'path−label−object−false' => { 'blue−black' => 'yes!', 'blackish﹠green' => '¿no?', '100𝑥brown' => 'fl¡p' },
            'path−label−object−true' => { 'blue−black' => 'yes!', 'blackish﹠green' => '¿no?', '100𝑥brown' => 'fl¡p' },
          },
          query => {
            'query−form−string' => 'blue/blåck',
            'query−form−array−false' => [ qw(blue−black black/ish﹠green 100𝑥brown) ],
            'query−form−array−true' => [ qw(blue−black black/ish﹠green 100𝑥brown) ],
            'query−form−object−false' => { 'réd' => '100𝑥', 'grɘɇn' => '¡ja', 'bløö' => '¿neîn' },
            'query−spaceDelimited−array' => [ qw(blue−black black/ish﹠green 100𝑥brown) ],
            'query−spaceDelimited−object' => { 'réd' => '100𝑥', 'grɘɇn' => '¡ja', 'bløö' => '¿neîn' },
            'query−pipeDelimited−array' => [ qw(blue−black black/ish﹠green 100𝑥brown) ],
            'query−pipeDelimited−object' => { 'réd' => '100𝑥', 'grɘɇn' => '¡ja', 'bløö' => '¿neîn' },
            'query−deepObject' => { 'réd' => '100𝑥', 'grɘɇn' => '¡ja', 'bløö' => '¿neîn' },
          },
        },
        header => {
          'header-simple-string' => 'red﹠green',
          'header-simple-array-false' => [ qw(blue−black blackish﹠green 100𝑥brown) ],
          'header-simple-array-true' => [ qw(blue−black blackish﹠green 100𝑥brown) ],
          'header-simple-object-false' => { 'blue−black' => 'yes!', 'blackish﹠green' => '¿no?', '100𝑥brown' => 'fl¡p' },
          'header-simple-object-true' => { 'blue−black' => 'yes!', 'blackish﹠green' => '¿no?', '100𝑥brown' => 'fl¡p' },
          Cookie => {
            'cookie−form−string' => 'blue/blåck',
            'cookie−form−array−true' => [ qw(blue−black black/ish﹠green 100𝑥brown) ],
            'cookie-cookie-string' => 'blue/black',
            'cookie-cookie-array-true' =>  [ qw(blue-black black/ish&green 100xbrown) ],
          },
        },
      },
    },
    'deserialized data included in result',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /:
    get: {}
    parameters:
      - name: query-form-object-true
        in: query
        required: true
        explode: true
        schema:
          type: object
          const: { réd: 100𝑥, grɘɇn: ¡ja, bløö: ¿neîn }
YAML

  $request = request('GET', 'http://example.com?'
    .join('&', map join('=', @$_), pairs map uri_encode($_), qw(réd 100𝑥 grɘɇn ¡ja bløö ¿neîn)));

  is_equal(
    ($result = $openapi->validate_request($request))->TO_JSON,
    { valid => true },
    'query parameter with style=form, explode=true is deserialized correctly into an object',
  );
  is_equal(
    $result->data,
    {
      request => {
        uri => {
          query => {
            'query-form-object-true' => { 'réd' => '100𝑥', 'grɘɇn' => '¡ja', 'bløö' => '¿neîn' },
          },
        },
      },
    },
    'deserialized data included in result',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /:
    get: {}
    parameters:
      - name: cookie-form-object-true
        in: cookie
        required: true
        explode: true
        schema:
          type: object
          const: { réd: 100𝑥, grɘɇn: ¡ja, bløö: ¿neîn }
YAML

  $request = request('GET', 'http://example.com', [ Cookie => 'r%C3%A9d=100%F0%9D%91%A5&gr%C9%98%C9%87n=%C2%A1ja&bl%C3%B8%C3%B6=%C2%BFne%C3%AEn' ]);
  is_equal(
    ($result = $openapi->validate_request($request))->TO_JSON,
    { valid => true },
    'single cookie parameter with style=form, explode=true is deserialized correctly into an object',
  );
  is_equal(
    $result->data,
    {
      request => {
        header => {
          Cookie => { 'cookie-form-object-true' => { 'réd' => '100𝑥', 'grɘɇn' => '¡ja', 'bløö' => '¿neîn' } },
        },
      },
    },
    'deserialized data included in result',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /:
    get: {}
    parameters:
      - name: cookie-cookie-object-true
        in: cookie
        style: cookie
        required: true
        explode: true
        schema:
          type: object
          const: { red: 100x, green: ja, bloo: nein }
YAML

  $request = request('GET', 'http://example.com',
    [ Cookie => join('; ', map +($_->[0].'='.$_->[1]), pairs(qw(red 100x green ja bloo nein))) ]);
  is_equal(
    ($result = $openapi->validate_request($request))->TO_JSON,
    { valid => true },
    'all query parameters are deserialized correctly',
  );
  is_equal(
    $result->data,
    {
      request => {
        header => {
          Cookie => {
            'cookie-cookie-object-true' => { red => '100x', 'green' => 'ja', bloo => 'nein' },
          },
        },
      },
    },
    'deserialized data included in result',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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

  $request = request('GET', 'http://example.com/foo', [ 'Header1' => '{corrupt json' ]); # } for vim
  query_params($request, [ query1 => '{corrupt json' ]); # } for vim
  cmp_result(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/query1',
          keywordLocation => jsonp(qw(/paths /foo get parameters 0 content application/json)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 0 content application/json)))->to_string,
          error => re(qr/^could not decode content as application\/json: /),
        },
        {
          instanceLocation => '/request/header/Header1',
          keywordLocation => jsonp(qw(/paths /foo get parameters 1 content application/json)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 1 content application/json)))->to_string,
          error => re(qr/^could not decode content as application\/json: /),
        },
      ],
    },
    'errors during media-type decoding are detected',
  );

  $request = request('GET', 'http://example.com/foo', [ 'Header1' => '{"hello":"there"}' ]);
  query_params($request, [ query1 => '{"hello":"there"}' ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/query1',
          keywordLocation => jsonp(qw(/paths /foo get parameters 0 content application/json schema required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 0 content application/json schema required)))->to_string,
          error => 'object is missing property: key',
        },
        {
          instanceLocation => '/request/header/Header1',
          keywordLocation => jsonp(qw(/paths /foo get parameters 1 content application/json schema required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 1 content application/json schema required)))->to_string,
          error => 'object is missing property: key',
        },
      ],
    },
    'parameters are decoded using the indicated media type and then validated against the content schema',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    parameters:
    - name: alpha
      in: query
      required: true
      schema:
        type: string
        pattern: ^[0-9]+$
    - name: beta
      in: query
      required: true
      schema:
        type: string
        pattern: ^[0-9]+$
    - name: alpha
      in: header
      required: true
      schema:
        type: string
        pattern: ^[0-9]+$
    - name: beta
      in: header
      required: true
      schema:
        type: string
        pattern: ^[0-9]+$
    get:
      parameters:
      - name: alpha
        in: query
        required: true
        schema:
          type: string
          maxLength: 1
      - name: alpha
        in: header
        required: true
        schema:
          type: string
          maxLength: 1
YAML

  $request = request('GET', 'http://example.com/foo?alpha=hihihi&beta=hihihi', [ Alpha => 'hihihi', Beta => 'hihihi' ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
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
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get:
      requestBody:
        $ref: 'http://example.com/otherapi#/i_do_not_exist'
YAML

  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo get requestBody $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get requestBody $ref)))->to_string,
          error => 'EXCEPTION: unable to find resource "http://example.com/otherapi#/i_do_not_exist"',
        },
      ],
    },
    'bad $ref in requestBody',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                alpha:
                  type: string
                  pattern: ^[0-9]+$
                beta:
                  type: string
                  const: éclair
                gamma:
                  type: string
                  const: ಠ_ಠ
              additionalProperties: false
          blOOp/HTml:
            schema:
              not: true
          text/plain:
            schema:
              const: éclair
          unknown/encodingtype:
            schema:
              not: true
          iMAgE/*:
            schema:
              not: true
YAML

  {
  my $todo = todo 'Dancer2 parses chunked content at construction time' if $::TYPE eq 'dancer2';
  $request = request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'text/plain', 'Content-Length' => 4, 'Transfer-Encoding' => 'chunked' ],
    "4\r\nabcd\r\n0\r\n\r\n");
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/header/Content-Length',
          keywordLocation => jsonp(qw(/paths /foo post)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post)))->to_string,
          error => 'Content-Length cannot appear together with Transfer-Encoding',
        },
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content text/plain schema const)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content text/plain schema const)))->to_string,
          error => 'value does not match',
        },
      ],
    },
    'conflict between Content-Length + Transfer-Encoding headers (and body is still parseable)',
  );
  }

  # note: no content!
  $request = request('POST', 'http://example.com/foo');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo post requestBody required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody required)))->to_string,
          error => 'request body is required but missing',
        },
      ],
    },
    'request body is missing',
  );

  {
    my $todo = todo 'mojo will strip the content body when parsing a stringified request that lacks Content-Length'
      if $::TYPE eq 'lwp' or $::TYPE eq 'plack' or $::TYPE eq 'catalyst' or $::TYPE eq 'dancer2';

    # this works without a charset because all characters fit into a single byte, essentially
    # acting like latin1.
    $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'text/plain' ], 'éclair');
    remove_header($request, 'Content-Length');

    is_equal(
      $openapi->validate_request($request)->TO_JSON,
      {
        valid => false,
        errors => [
          {
            instanceLocation => '/request/header',
            keywordLocation => jsonp(qw(/paths /foo post)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post)))->to_string,
            error => 'missing header: Content-Length',
          },
        ],
      },
      'Content-Length is required in requests with a message body',
    );
  }

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'text/bloop' ], 'plain text');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content)))->to_string,
          error => 'incorrect Content-Type "text/bloop"',
        },
      ],
    },
    'Content-Type not allowed by the schema',
  );

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'text/plain; charset=us-ascii' ], 'ascii plain text');
  is_equal(
    ($result = $openapi->validate_request($request))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content text/plain schema const)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content text/plain schema const)))->to_string,
          error => 'value does not match',
        },
      ],
    },
    'us-ascii text can be decoded and matched',
  );
  is_equal(
    $result->data,
    { request => { body => { content => 'ascii plain text' } } },
    'body data was correctly parsed',
  );

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'blOOp/HTML' ], 'html text (bloop style)');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content blOOp/HTml)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content blOOp/HTml)))->to_string,
          error => 'EXCEPTION: unsupported media type "blOOp/HTML": add support with $openapi->add_media_type(...)',
        },
      ],
    },
    'unsupported Content-Type - but matched against the document case-insensitively',
  );


  # we have to add media-types in foldcased format
  $openapi->add_media_type('bloop/html' => sub ($content_ref) { $content_ref });

  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content blOOp/HTml schema not)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content blOOp/HTml schema not)))->to_string,
          error => 'subschema is true',
        },
      ],
    },
    'Content-Type looked up case-insensitively and matched in the document case-insensitively too',
  );


  $openapi->add_media_type('unknown/*' => sub ($value) { $value });

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'unknown/encodingtype' ], 'binary');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content unknown/encodingtype schema not)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content unknown/encodingtype schema not)))->to_string,
          error => 'subschema is true',
        },
      ],
    },
    'wildcard support in the media type registry is used to handle an otherwise-unknown content type',
  );


  # this will match against the document at image/*
  # but we have no media-type registry for image/*, only image/jpeg
  $openapi->add_media_type('image/jpeg' => sub ($value) { $value });
  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'image/jpeg' ], 'binary');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content iMAgE/* schema not)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content iMAgE/* schema not)))->to_string,
          error => 'subschema is true',
        },
      ],
    },
    'Content-Type header is matched to a wildcard entry in the document, then matched to a media-type implementation',
  );

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'text/plain; charset=UTF-8' ],
    chr(0xe9).'clair');
  cmp_result(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content text/plain)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content text/plain)))->to_string,
          error => re(qr/^could not decode content as UTF-8: UTF-8 "\\xE9" does not map to Unicode/),
        },
      ],
    },
    'errors during charset decoding are detected',
  );

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'text/plain; charset=ISO-8859-1' ],
    chr(0xe9).'clair');
  is_equal(
    ($result = $openapi->validate_request($request))->TO_JSON,
    { valid => true },
    'latin1 content can be successfully decoded',
  );
  is_equal(
    $result->data,
    { request => { body => { content => 'éclair' } } },
    'body data was correctly parsed',
  );

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'text/plain; charset=UTF-8' ],
    chr(0xe9).'clair');
  cmp_result(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content text/plain)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content text/plain)))->to_string,
          error => re(qr/^could not decode content as UTF-8: UTF-8 "\\xE9" does not map to Unicode/),
        },
      ],
    },
    'errors during charset decoding are detected',
  );

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'application/json; charset=UTF-8' ],
    '{"alpha": "123", "beta": "'.chr(0xe9).'clair"}');
  cmp_result(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content application/json)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/json)))->to_string,
          error => re(qr/^could not decode content as application\/json: malformed UTF-8 character in JSON string/),
        },
      ],
    },
    'charset encoding errors in json are decoded in the main decoding step',
  );

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'application/json; charset=UTF-8' ],
    '{corrupt json'); # } to mollify vim
  cmp_result(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content application/json)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/json)))->to_string,
          error => re(qr/^could not decode content as application\/json: /),
        },
      ],
    },
    'errors during media-type decoding are detected',
  );

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'application/json' ],
    '{"alpha": "123", "beta": "'."\x{c3}\x{a9}".'clair"}');
  is_equal(
    ($result = $openapi->validate_request($request))->TO_JSON,
    { valid => true },
    'application/json is utf-8 encoded',
  );
  is_equal(
    $result->data,
    { request => { body => { content => { alpha => '123', beta => 'éclair' } } } },
    'body data was correctly parsed',
  );

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'application/json; charset=UTF-8' ],
    '{"alpha": "123", "beta": "'."\x{c3}\x{a9}".'clair"}');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    { valid => true },
    'charset is ignored for application/json',
  );

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'application/json; charset=UTF-8' ],
    '{"alpha": "foo", "gamma": "o.o"}');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content/alpha',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content application/json schema properties alpha pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/json schema properties alpha pattern)))->to_string,
          error => 'pattern does not match',
        },
        {
          instanceLocation => '/request/body/content/gamma',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content application/json schema properties gamma const)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/json schema properties gamma const)))->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content application/json schema properties)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/json schema properties)))->to_string,
          error => 'not all properties are valid',
        },
      ],
    },
    'decoded content does not match the schema',
  );


  my $disapprove = v224.178.160.95.224.178.160; # utf-8-encoded "ಠ_ಠ"
  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'application/json; charset=UTF-8' ],
    '{"alpha": "123", "gamma": "'.$disapprove.'"}');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    { valid => true },
    'decoded content matches the schema',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        required: true
        content:
          '*/*':
            schema:
              minLength: 10
YAML

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'unsupported/unsupported' ], '!!!');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content */* schema minLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content */* schema minLength)))->to_string,
          error => 'length is less than 10',
        },
      ],
    },
    'unknown content type can still be evaluated if */* is an acceptable media-type',
  );

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'a/b' ], '0');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content */* schema minLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content */* schema minLength)))->to_string,
          error => 'length is less than 10',
        },
      ],
    },
    '"false" body is still seen',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        required: true
        content:
          application/json: {}
          electric/boogaloo: {}
YAML

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'application/json' ], 'corrupt_json');
  cmp_result(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content application/json)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/json)))->to_string,
          error => re(qr/^could not decode content as application\/json: malformed JSON string/),
        },
      ],
    },
    'corrupt data is detected, even when there is no schema',
  );

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'application/json' ], '{}');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    { valid => true },
    'valid encoded content is always valid when there is no schema',
  );

  is_equal(
    $openapi->validate_request(request('POST', 'http://example.com/foo', [ 'Content-Type' => 'electric/boogaloo' ], 'blah'))->TO_JSON,
    { valid => true },
    '..even when the media-type is unknown',
  );
};

subtest $::TYPE.': document errors' => sub {
  my $request = request('GET', 'http://example.com/foo?alpha=1');
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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
    - $ref: '#/components/parameters/alpha'
    - $ref: '#/components/parameters/alpha'
    get: {}
YAML

  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo parameters 1 $ref)),
          absoluteKeywordLocation => $doc_uri.'#/components/parameters/alpha',
          error => 'duplicate query parameter "alpha"',
        },
      ],
    },
    'duplicate query parameters in path-item section',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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
      - $ref: '#/components/parameters/alpha'
      - $ref: '#/components/parameters/alpha'
YAML

  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo get parameters 1 $ref)),
          absoluteKeywordLocation => $doc_uri.'#/components/parameters/alpha',
          error => 'duplicate query parameter "alpha"',
        },
      ],
    },
    'duplicate query parameters in operation section',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/header',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content)))->to_string,
          error => 'missing header: Content-Type',
        },
      ],
    },
    'missing Content-Type is an error, not an exception',
  );

  # bypass auto-initialization of Content-Length, Content-Type; leave Content-Length empty
  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'text/plain' ], '!');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content text/plain schema minLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content text/plain schema minLength)))->to_string,
          error => 'length is less than 10',
        },
      ],
    },
    'missing Content-Length does not prevent the request body from being checked',
  );

  $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'text/plain' ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    { valid => true },
    'request body is missing but not required',
  );
};

subtest $::TYPE.': type handling of values for evaluation' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{foo_id}:
    parameters:
    - name: foo_id
      in: path
      required: true
      schema:
        type: [integer, string]
        maximum: 10
        pattern: ^[a-z]+$
    post:
      parameters:
      - name: bar
        in: query
        schema:
          type: [integer, string]
          maximum: 10
          pattern: ^[a-z]+$
      - name: Foo-Bar
        in: header
        schema:
          type: [integer, string]
          maximum: 10
          pattern: ^[a-z]+$
      requestBody:
        required: true
        content:
          text/plain:
            schema:
              type: [integer, string]
              maximum: 10
              pattern: ^[a-z]+$
YAML

  my $request = request('POST', 'http://example.com/foo/123?bar=456',
    [ 'Foo-Bar' => 789, 'Content-Type' => 'text/plain' ], 666);
  is_equal(
    $openapi->validate_request($request, my $options = { path_captures => { foo_id => 123 } })->TO_JSON,
    my $expected = {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/bar',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} post parameters 0 schema maximum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post parameters 0 schema maximum)))->to_string,
          error => 'value is greater than 10',
        },
        # no error from pattern - query value is a number
        {
          instanceLocation => '/request/header/Foo-Bar',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} post parameters 1 schema maximum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post parameters 1 schema maximum)))->to_string,
          error => 'value is greater than 10',
        },
        # no error from pattern - header value is a number
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} parameters 0 schema maximum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} parameters 0 schema maximum)))->to_string,
          error => 'value is greater than 10',
        },
        # no error from pattern - path value is a number
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} post requestBody content text/plain schema pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post requestBody content text/plain schema pattern)))->to_string,
          error => 'pattern does not match',
        },
        # no error from maximum - text/plain request body is a string
      ],
    },
    'numeric values are correctly deserialized when type=number or type=integer is specified',
  );
  is(get_type($options->{path_captures}{foo_id}), 'integer', 'passed-in path value is preserved as a number');

  is_equal(
    $openapi->validate_request($request, $options = {})->TO_JSON,
    $expected,
    'parsed numeric values are treated as both strings and numbers, when no explicit type is requested',
  );
   is(get_type($options->{path_captures}{foo_id}), 'string', 'captured path value is parsed as a string');


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{foo_id}:
    parameters:
    - name: foo_id
      in: path
      required: true
      schema:
        type: string
    post:
      parameters:
      - name: bar
        in: query
        required: false
        schema:
          type: string
      - name: Foo-Bar
        in: header
        required: false
        schema:
          type: string
      requestBody:
        required: true
        content:
          text/plain:
            schema:
              type: string
YAML

  $request = request('POST', 'http://example.com/foo/123?bar=456',
    [ 'Foo-Bar' => 789, 'Content-Type' => 'text/plain' ], 666);
  is_equal(
    $openapi->validate_request($request, { path_captures => { foo_id => 123 } })->TO_JSON,
    { valid => true },
    'all parameter and body values are treated as strings',
  );

  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    { valid => true },
    'all parameter and body values are parsed from the request as strings',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{foo_id}:
    parameters:
    - name: foo_id
      in: path
      required: true
      schema:
        type: number
    post:
      parameters:
      - name: bar
        in: query
        required: false
        schema:
          type: number
      - name: Foo-Bar
        in: header
        required: false
        schema:
          type: number
      requestBody:
        required: true
        content:
          text/plain:
            schema:
              type: number
YAML

  is_equal(
    $openapi->validate_request($request, { path_captures => { foo_id => 123 } })->TO_JSON,
    $expected = {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} post requestBody content text/plain schema type)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post requestBody content text/plain schema type)))->to_string,
          error => 'got string, not number',
        },
      ],
    },
    'numeric values are seen as numeric types when requested, but only in parameters and not bodies',
  );

  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    $expected,
    'parsed numeric values are seen as numeric types when requested, but only in parameters and not bodies',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{path_plain}/bar/{path_encoded}:
    parameters:
    - name: path_plain
      in: path
      required: true
      schema:
        type: integer
        maximum: 10
    - name: path_encoded
      in: path
      required: true
      content:
        text/plain:
          schema:
            type: integer
            maximum: 10
    post:
      parameters:
      - name: query_plain
        in: query
        required: false
        schema:
          type: integer
          maximum: 10
      - name: query_encoded
        in: query
        required: false
        content:
          text/plain:
            schema:
              type: integer
              maximum: 10
      - name: Header-Plain
        in: header
        required: false
        schema:
          type: integer
          maximum: 10
      - name: Header-Encoded
        in: header
        required: false
        content:
          text/plain:
            schema:
              type: integer
              maximum: 10
      requestBody:
        required: true
        content:
          text/plain:
            schema:
              type: integer
              maximum: 10
YAML

  $request = request('POST', 'http://example.com/foo/11/bar/12?query_plain=13&query_encoded=14',
    [ 'Header-Plain' => 15, 'Header-Encoded' => 16, 'Content-Type' => 'text/plain' ], 17);
  is_equal(
    $openapi->validate_request($request, { path_captures => { path_plain => 11, path_encoded => 12 } })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/query_plain',
          keywordLocation => jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} post parameters 0 schema maximum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} post parameters 0 schema maximum)))->to_string,
          error => 'value is greater than 10',
        },
        {
          instanceLocation => '/request/uri/query/query_encoded',
          keywordLocation => jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} post parameters 1 content text/plain schema type)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} post parameters 1 content text/plain schema type)))->to_string,
          error => 'got string, not integer',
        },
        {
          instanceLocation => '/request/header/Header-Plain',
          keywordLocation => jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} post parameters 2 schema maximum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} post parameters 2 schema maximum)))->to_string,
          error => 'value is greater than 10',
        },
        {
          instanceLocation => '/request/header/Header-Encoded',
          keywordLocation => jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} post parameters 3 content text/plain schema type)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} post parameters 3 content text/plain schema type)))->to_string,
          error => 'got string, not integer',
        },
        {
          instanceLocation => '/request/uri/path/path_plain',
          keywordLocation => jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} parameters 0 schema maximum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} parameters 0 schema maximum)))->to_string,
          error => 'value is greater than 10',
        },
        {
          instanceLocation => '/request/uri/path/path_encoded',
          keywordLocation => jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} parameters 1 content text/plain schema type)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} parameters 1 content text/plain schema type)))->to_string,
          error => 'got string, not integer',
        },
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} post requestBody content text/plain schema type)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} post requestBody content text/plain schema type)))->to_string,
          error => 'got string, not integer',
        },
      ],
    },
    'numeric values are treated as numbers when explicitly type-checked as numbers, but only when not encoded',
  );


  my $val = 20; my $str = sprintf("%s\n", $val);
  $request = request('POST', 'http://example.com/foo/20/bar/hi', [ 'Content-Type' => 'text/plain' ], $val);
  is_equal(
    $openapi->validate_request($request,
      { path_captures => { path_plain => $val, path_encoded => 'hi' } })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path/path_plain',
          keywordLocation => jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} parameters 0 schema maximum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} parameters 0 schema maximum)))->to_string,
          error => 'value is greater than 10',
        },
        {
          instanceLocation => '/request/uri/path/path_encoded',
          keywordLocation => jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} parameters 1 content text/plain schema type)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} parameters 1 content text/plain schema type)))->to_string,
          error => 'got string, not integer',
        },
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} post requestBody content text/plain schema type)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{path_plain}/bar/{path_encoded} post requestBody content text/plain schema type)))->to_string,
          error => 'got string, not integer',
        },
      ],
    },
    'ambiguously-typed numbers are still handled gracefully',
  );
};

subtest $::TYPE.': parameter parsing' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get:
      parameters:
      - name: SingleValue
        in: header
        schema:
          const: mystring
      - name: MultipleValuesAsString
        in: header
        schema:
          const: 'one,two,three'
      - name: MultipleValuesAsArray
        in: header
        schema:
          type: array
          uniqueItems: true
          minItems: 3
          maxItems: 3
          items:
            enum: [one, two, three]
      - name: MultipleValuesAsObjectExplodeFalse
        in: header
        schema:
          type: object
          minProperties: 3
          maxProperties: 3
          properties:
            R:
              const: 100
            G:
              type: integer
            B:
              maximum: 300
              minimum: 300    # "number" is an acceptable type therefore it is used
      - name: MultipleValuesAsObjectExplodeTrue
        in: header
        explode: true
        schema:
          $ref: '#/paths/~1foo/get/parameters/3/schema' # MultipleValuesAsObjectExplodeFalse
      - name: ArrayWithRef
        in: header
        schema:
          $ref: '#/paths/~1foo/get/parameters/2/schema' # MultipleValuesAsArray
      - name: ArrayWithRefAndOtherKeywords
        in: header
        schema:
          $ref: '#/paths/~1foo/get/parameters/2/schema' # MultipleValuesAsArray
          type: [ array, string ]
      - name: MultipleValuesAsRawString
        in: header
        schema:
          const: 'one , two  , three'
      - name: ArrayWithLocalTypeAndRef
        in: header
        schema:
          type: array
          $ref: '#/paths/~1foo/get/parameters/3/schema' # MultipleValuesAsObjectExplodeFalse
      - name: ArrayWithAllOfAndRef
        in: header
        schema:
          allOf:
            - $ref: '#/paths/~1foo/get/parameters/2/schema' # MultipleValuesAsArray
            - true
      # must be evaluated last, as broken $refs abort all validation
      - name: ArrayWithBrokenRef
        in: header
        schema:
          $ref: 'http://example.com/otherapi#/components/schemas/i_do_not_exist'
YAML

  my $request = request('GET', 'http://example.com/foo', [ SingleValue => '  mystring  ' ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    { valid => true },
    'a single header value has its leading and trailing whitespace stripped',
  );

  $request = request('GET', 'http://example.com/foo', [ MultipleValuesAsRawString => '  one , two  , three  ' ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    { valid => true },
    'multiple values in a single header are validated as a string, with only leading and trailing whitespace stripped',
  );

  {
  my $todo = todo 'HTTP::Message::to_psgi fetches all headers as a single concatenated string'
    if $::TYPE eq 'plack' or $::TYPE eq 'catalyst' or $::TYPE eq 'dancer2';
  $request = request('GET', 'http://example.com/foo', [
      MultipleValuesAsString => '  one ',
      MultipleValuesAsString => ' two  ',
      MultipleValuesAsString => 'three  ',
    ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    { valid => true },
    'multiple headers on separate lines are validated as a string, with leading and trailing whitespace stripped',
  );
  }

  $request = request('GET', 'http://example.com/foo', [ MultipleValuesAsArray => '  one, two, three  ' ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    { valid => true },
    'headers can be parsed into an array in order to test multiple values without sorting',
  );

  {
  my $todo = todo 'HTTP::Message::to_psgi fetches all headers as a single concatenated string'
    if $::TYPE eq 'plack' or $::TYPE eq 'catalyst' or $::TYPE eq 'dancer2';
  $request = request('GET', 'http://example.com/foo', [
    MultipleValuesAsArray => '  one',
    MultipleValuesAsArray => ' one ',
    MultipleValuesAsArray => ' three ',
  ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/header/MultipleValuesAsArray',
          keywordLocation => jsonp(qw(/paths /foo get parameters 2 schema uniqueItems)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 2 schema uniqueItems)))->to_string,
          error => 'items at indices 0 and 1 are not unique',
        },
      ],
    },
    'headers that appear more than once are parsed into an array',
  );
  }


  {
  my $todo = todo 'HTTP::Message::to_psgi fetches all headers as a single concatenated string'
    if $::TYPE eq 'plack' or $::TYPE eq 'catalyst' or $::TYPE eq 'dancer2';
  $request = request('GET', 'http://example.com/foo', [
      MultipleValuesAsObjectExplodeFalse => ' R, 100 ',
      MultipleValuesAsObjectExplodeFalse => ' B, 150,  G , 200 ',
      MultipleValuesAsObjectExplodeTrue => ' R=100  , B=150 ',
      MultipleValuesAsObjectExplodeTrue => '  G=200 ',
    ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/header/MultipleValuesAsObjectExplodeFalse/B',
          keywordLocation => jsonp(qw(/paths /foo get parameters 3 schema properties B minimum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 3 schema properties B minimum)))->to_string,
          error => 'value is less than 300',
        },
        {
          instanceLocation => '/request/header/MultipleValuesAsObjectExplodeFalse',
          keywordLocation => jsonp(qw(/paths /foo get parameters 3 schema properties)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 3 schema properties)))->to_string,
          error => 'not all properties are valid',
        },
        {
          instanceLocation => '/request/header/MultipleValuesAsObjectExplodeTrue/B',
          keywordLocation => jsonp(qw(/paths /foo get parameters 4 schema $ref properties B minimum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 3 schema properties B minimum)))->to_string,
          error => 'value is less than 300',
        },
        {
          instanceLocation => '/request/header/MultipleValuesAsObjectExplodeTrue',
          keywordLocation => jsonp(qw(/paths /foo get parameters 4 schema $ref properties)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 3 schema properties)))->to_string,
          error => 'not all properties are valid',
        },
      ],
    },
    'headers can be parsed into an object, represented in two ways depending on explode value',
  );
  }

  $request = request('GET', 'http://example.com/foo', [
      ArrayWithRef => 'one, one, three',
      ArrayWithRefAndOtherKeywords => 'one, one, three',
      ArrayWithLocalTypeAndRef => 'one, two, two',
      ArrayWithAllOfAndRef => 'one, three, three',
      ArrayWithBrokenRef => 'hi',
    ]);
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/header/ArrayWithRef',
          keywordLocation => jsonp(qw(/paths /foo get parameters 5 schema $ref uniqueItems)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 2 schema uniqueItems)))->to_string,
          error => 'items at indices 0 and 1 are not unique',
        },
        {
          instanceLocation => '/request/header/ArrayWithRefAndOtherKeywords',
          keywordLocation => jsonp(qw(/paths /foo get parameters 6 schema $ref uniqueItems)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 2 schema uniqueItems)))->to_string,
          error => 'items at indices 0 and 1 are not unique',
        },
        {
          instanceLocation => '/request/header/ArrayWithLocalTypeAndRef',
          keywordLocation => jsonp(qw(/paths /foo get parameters 8)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 8)))->to_string,
          error => 'cannot deserialize to any type',
        },
        {
          instanceLocation => '/request/header/ArrayWithAllOfAndRef',
          keywordLocation => jsonp(qw(/paths /foo get parameters 9 schema allOf 0 $ref uniqueItems)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 2 schema uniqueItems)))->to_string,
          error => 'items at indices 1 and 2 are not unique',
        },
        {
          instanceLocation => '/request/header/ArrayWithAllOfAndRef',
          keywordLocation => jsonp(qw(/paths /foo get parameters 9 schema allOf)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 9 schema allOf)))->to_string,
          error => 'subschema 0 is not valid',
        },
        {
          instanceLocation => '/request/header/ArrayWithBrokenRef',
          keywordLocation => jsonp(qw(/paths /foo get parameters 10 schema $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get parameters 10 schema $ref)))->to_string,
          error => 'EXCEPTION: unable to find resource "http://example.com/otherapi#/components/schemas/i_do_not_exist"',
        },
      ],
    },
    'header schemas can use a $ref and we follow it correctly, updating locations, and respect adjacent keywords',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get:
      parameters:
      - name: ZeroSchema
        in: header
        schema:
          $ref: '0'
YAML

  $openapi->evaluator->add_schema(
    Mojo::URL->new('0')->to_abs($doc_uri),
    { type => 'array', minItems => 3 },
  );

  is_equal(
    $openapi->validate_request(request('GET', 'http://example.com/foo', [ ZeroSchema => 'foo,bar' ]))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/header/ZeroSchema',
          keywordLocation => jsonp(qw(/paths /foo get parameters 0 schema $ref minItems)),
          absoluteKeywordLocation => 'http://example.com/0#/minItems',
          error => 'array has fewer than 3 items',
        },
      ],
    },
    'can correctly use a $ref to "0" when parsing parameter schemas for type hints',
  );
};

subtest $::TYPE.': max_depth' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    max_traversal_depth => 15,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  parameters:
    foo:
      $ref: '#/components/parameters/bar'
    bar:
      $ref: '#/components/parameters/foo'
paths:
  /foo:
    post:
      parameters:
      - $ref: '#/components/parameters/foo'
YAML

  my $request = request('POST', 'http://example.com/foo');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /foo post parameters 0), ('$ref')x17),
          absoluteKeywordLocation => $doc_uri.'#/components/parameters/bar/$ref',
          error => 'EXCEPTION: maximum evaluation depth exceeded',
        },
      ],
    },
    'bad $ref in operation parameters',
  );
};

subtest $::TYPE.': unevaluatedProperties and annotations' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                bar: true
              unevaluatedProperties: false
YAML

  my $request = request('POST', 'http://example.com/foo', [ 'Content-Type' => 'application/json' ], '{"foo":1}');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content/foo',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content application/json schema unevaluatedProperties)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/json schema unevaluatedProperties)))->to_string,
          error => 'additional property not permitted',
        },
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content application/json schema unevaluatedProperties)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/json schema unevaluatedProperties)))->to_string,
          error => 'not all additional properties are valid',
        },
      ],
    },
    'unevaluatedProperties can be used in schemas',
  );
};

subtest $::TYPE.': readOnly' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      parameters:
      - name: a
        in: query
        schema:
          readOnly: true
          writeOnly: true
      - name: b
        in: query
        schema:
          readOnly: false
          writeOnly: false
      requestBody:
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
          text/plain:
            schema: {}
YAML

  my $request = request('POST', 'http://example.com/foo?a=1&b=2',
    [ 'Content-Type' => 'application/json' ], '{"c":1,"d":2}');
  is_equal(
    $openapi->validate_request($request)->TO_JSON,
    { valid => true },
    'readOnly values are still valid in a request',
  );

  is_equal(
    $openapi->validate_request(request('POST', 'http://example.com/foo', [ 'Content-Type' => 'text/plain' ], 'hi'))->TO_JSON,
    { valid => true },
    'no errors when processing an empty body schema',
  );
};

subtest $::TYPE.': no bodies in GET or HEAD requests without requestBody' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    head: {}
    get: {}
    post: {}
YAML

  is_equal(
    $openapi->validate_request(request($_, 'http://example.com/foo', [], 'content'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo), lc),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo), lc))->to_string,
          error => 'unspecified body is present in '.$_.' request',
        },
      ],
    },
    'no body permitted for '.$_,
  ) foreach qw(GET HEAD);

  is_equal(
    $openapi->validate_request(request('POST', 'http://example.com/foo', [], 'content'))->TO_JSON,
    { valid => true },
    'no errors from POST with body',
  );

SKIP: {
  # "Bad Content-Length: maybe client disconnect? (1 bytes remaining)"
  skip 'plack dies on this input', 3 if $::TYPE eq 'plack' or $::TYPE eq 'catalyst' or $::TYPE eq 'dancer2';
  is_equal(
    $openapi->validate_request(request($_, 'http://example.com/foo', [ 'Content-Length' => 1 ]))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo), lc),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo), lc))->to_string,
          error => 'unspecified body is present in '.$_.' request',
        },
      ],
    },
    'non-zero Content-Length not permitted for '.$_,
  ) foreach qw(GET HEAD);

  is_equal(
    $openapi->validate_request(request('POST', 'http://example.com/foo', [ 'Content-Length' => 1 ]))->TO_JSON,
    { valid => true },
    'no errors from POST with Content-Length',
  );
} # end SKIP
};

subtest $::TYPE.': custom error messages for false schemas' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{foo_id}/{bar_id}:
    post:
      parameters:
      - name: foo_id
        in: path
        required: true
        schema: false
      - name: Foo
        in: header
        required: true
        schema: false
      - name: foo
        in: query
        required: true
        schema: false
      - name: foo
        in: cookie
        required: true
        schema: false
      - name: bar_id
        in: path
        required: true
        content:
          text/plain:
            schema:
              false
      - name: Bar
        in: header
        required: true
        content:
          text/plain:
            schema:
              false
      - name: bar
        in: query
        required: true
        content:
          text/plain:
            schema:
              false
      - name: bar
        in: cookie
        required: true
        content:
          text/plain:
            schema:
              false
      requestBody:
        content:
          '*/*':
            schema: false
  /bar:
    post:
      parameters:
      - name: bar
        in: querystring
        required: true
        content:
          text/plain:
            schema:
              false
YAML

  is_equal(
    $openapi->validate_request(request('POST', 'http://example.com/foo/1/2?foo=1&bar=2',
      [ Foo => 1, Bar => 2, Cookie => 'foo=1; bar=2', 'Content-Type' => 'text/plain' ], 'hi'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 0 schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 0 schema)))->to_string,
          error => 'path parameter not permitted',
        },
        {
          instanceLocation => '/request/header/Foo',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 1 schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 1 schema)))->to_string,
          error => 'request header not permitted',
        },
        {
          instanceLocation => '/request/uri/query/foo',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 2 schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 2 schema)))->to_string,
          error => 'query parameter not permitted',
        },
        {
          instanceLocation => '/request/header/Cookie/foo',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 3 schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 3 schema)))->to_string,
          error => 'cookie parameter not permitted',
        },
        {
          instanceLocation => '/request/uri/path/bar_id',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 4 content text/plain schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 4 content text/plain schema)))->to_string,
          error => 'path parameter not permitted',
        },
        {
          instanceLocation => '/request/header/Bar',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 5 content text/plain schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 5 content text/plain schema)))->to_string,
          error => 'request header not permitted',
        },
        {
          instanceLocation => '/request/uri/query/bar',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 6 content text/plain schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 6 content text/plain schema)))->to_string,
          error => 'query parameter not permitted',
        },
        {
          instanceLocation => '/request/header/Cookie/bar',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 7 content text/plain schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id}/{bar_id} post parameters 7 content text/plain schema)))->to_string,
          error => 'cookie parameter not permitted',
        },
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id}/{bar_id} post requestBody content */* schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id}/{bar_id} post requestBody content */* schema)))->to_string,
          error => 'request body not permitted',
        },
      ],
    },
    'custom error message when the entity is not permitted',
  );

  is_equal(
    $openapi->validate_request(request('POST', 'http://example.com/bar?bar=1'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => jsonp(qw(/paths /bar post parameters 0 content text/plain schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /bar post parameters 0 content text/plain schema)))->to_string,
          error => 'query parameter not permitted',
        },
      ],
    },
    'custom error message when the querystring is not permitted',
  );
};

subtest $::TYPE.': multiple documents' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{foo_id}:
    get:
      parameters:
      - name: foo_id
        in: path
        required: true
        schema:
          type: number
          minimum: 4
          $ref: https://otherdoc.com#my_schema
YAML

  $openapi->evaluator->add_schema({
    '$id' => 'https://otherdoc.com',
    '$anchor' => 'my_schema',
    minimum => 5,
  });

  is_equal(
    $openapi->validate_request(request('GET', 'http://mycorp.com/foo/1'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} get parameters 0 schema $ref minimum)),
          absoluteKeywordLocation => 'https://otherdoc.com#/minimum',
          error => 'value is less than 5',
        },
        {
          instanceLocation => '/request/uri/path/foo_id',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} get parameters 0 schema minimum)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get parameters 0 schema minimum)))->to_string,
          error => 'value is less than 4',
        },
      ],
    },
    'correct error location is used when json schema $ref goes to another document',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/mydoc/api',  # intentionally relative, to see how uris resolve
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /alpha:
    $ref: /otherdoc/api/definitions#/components/pathItems/alpha_path
  /beta:
    get:
      parameters:
      - $ref: /otherdoc/api/definitions#/components/parameters/beta_parameter
      requestBody:
        $ref: /otherdoc/api/definitions#/components/requestBodies/beta_requestBody
components:
  requestBodies:
    alpha_requestBody:
      required: true
      content:
        'text/plain':
          schema: {}
YAML

  $openapi->evaluator->add_schema({
    '$id' => 'https://my_custom_dialect',
    '$vocabulary' => {
      'https://json-schema.org/draft/2020-12/vocab/core' => true,
      'https://json-schema.org/draft/2020-12/vocab/applicator' => true,
    },
  });

  $openapi->evaluator->add_media_type('application/yaml' => sub ($dataref) { \ $yamlpp->load_string($$dataref) });

  $openapi->evaluator->add_document(
    JSON::Schema::Modern::Document::OpenAPI->new(
      canonical_uri => '/otherdoc/api/definitions', # intentionally relative, to see how uris resolve
      evaluator => $openapi->evaluator,
      metaschema_uri => DEFAULT_METASCHEMA->{+OAS_VERSION}, # more lax, as we use multiple $schema values in schemas
      schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML')));
jsonSchemaDialect: https://my_custom_dialect
components:
  pathItems:
    alpha_path:
      get:
        parameters:
        - name: Blah
          in: header
          required: true
          schema: {}
        requestBody:
          $ref: '/mydoc/api#/components/requestBodies/alpha_requestBody'
  parameters:
    beta_parameter:
      name: Blah
      in: header
      required: true
      schema: {}
  requestBodies:
    beta_requestBody:
      content:
        'application/json':
          schema:
            $id: beta_subdir
            type: object
            properties:
              a:
                minLength: 10   # should not fail, as Validation vocabulary is not used here
              b: false
        'application/yaml':
          schema:
            $id: second_beta_subdir
            $schema: https://json-schema.org/draft/2019-09/schema
            type: array
            items:              # array form of items is not valid in the latest draft
              - minLength: 10   # should not fail, as Validation vocabulary is not used here
              - false
YAML

  # path-item in main document refs to second document.
  # now the path-item parameter starts here, a header has an error.
  is_equal(
    $openapi->validate_request(request('GET', 'https://example.com/alpha', ['Content-Type' => 'text/plain'], 'hi'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/header',
          keywordLocation => jsonp(qw(/paths /alpha $ref get parameters 0 required)),
          absoluteKeywordLocation => '/otherdoc/api/definitions#/components/pathItems/alpha_path/get/parameters/0/required',
          error => 'missing header: Blah',
        },
      ],
    },
    'correct error location is used when path-item $ref goes to another document',
  );

  # path-item in main document
  # we jump to a parameter in the second document
  # that parameter has an error.
  is_equal(
    $openapi->validate_request(request('GET', 'https://example.com/beta'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/header',
          keywordLocation => jsonp(qw(/paths /beta get parameters 0 $ref required)),
          absoluteKeywordLocation => '/otherdoc/api/definitions#/components/parameters/beta_parameter/required',
          error => 'missing header: Blah',
        },
      ],
    },
    'correct error location is used when parameter $ref goes to another document',
  );

  # path-item in main document refs to second document
  # parameter passes validation
  # but the requestBody is a $ref back to the main document, and it has an error.
  is_equal(
    $openapi->validate_request(request('GET', 'https://example.com/alpha', [ Blah => 'a' ]))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => jsonp(qw(/paths /alpha $ref get requestBody $ref required)),
          absoluteKeywordLocation => '/mydoc/api#/components/requestBodies/alpha_requestBody/required',
          error => 'request body is required but missing',
        },
      ],
    },
    'correct error location is used when requestBody $ref goes back to the original document',
  );

  # $ref to a secondary document, in which we evaluate a json schema with an $id in it
  # and this document uses a custom dialect via jsonSchemaDialect
  is_equal(
    $openapi->validate_request(request('GET', 'https://example.com/beta',
        [Blah => 1, 'Content-Type' => 'application/json'], '{"a":"hi","b":"oh noes"}'))->TO_JSON,
    {
      valid => false,
      errors => [
        # no error for 'length is less than 10'
        {
          instanceLocation => '/request/body/content/b',
          keywordLocation => jsonp(qw(/paths /beta get requestBody $ref content application/json schema properties b)),
          absoluteKeywordLocation => '/otherdoc/api/beta_subdir#/properties/b',
          error => 'property not permitted',
        },
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /beta get requestBody $ref content application/json schema properties)),
          absoluteKeywordLocation => '/otherdoc/api/beta_subdir#/properties',
          error => 'not all properties are valid',
        },
      ],
    },
    'correct dialect is used (via document\'s jsonSchemaDialect) in a secondary document',
  );


  # now we switch dialects via $schema in the subschema
  is_equal(
    $openapi->validate_request(request('GET', 'https://example.com/beta',
        [Blah => 1, 'Content-Type' => 'application/yaml'], '["hi","oh noes"]'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content/0',
          keywordLocation => jsonp(qw(/paths /beta get requestBody $ref content application/yaml schema items 0 minLength)),
          absoluteKeywordLocation => '/otherdoc/api/second_beta_subdir#/items/0/minLength',
          error => 'length is less than 10',
        },
        {
          instanceLocation => '/request/body/content/1',
          keywordLocation => jsonp(qw(/paths /beta get requestBody $ref content application/yaml schema items 1)),
          absoluteKeywordLocation => '/otherdoc/api/second_beta_subdir#/items/1',
          error => 'item not permitted',
        },
        {
          instanceLocation => '/request/body/content',
          keywordLocation => jsonp(qw(/paths /beta get requestBody $ref content application/yaml schema items)),
          absoluteKeywordLocation => '/otherdoc/api/second_beta_subdir#/items',
          error => 'not all items are valid',
        },
      ],
    },
  'correct dialect is used (via json schema\'s $schema keyword) in a secondary document',
  );
};

subtest $::TYPE.': example of cookie decomposition with encoding and media-type' => sub {
  my ($openapi, $result);
  my $schema = $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML');
paths:
  /foo:
    get:
      parameters:
        - in: cookie
          name: token
          content:
            text/plain:
              schema:
                contentEncoding: base64
                contentMediaType: application/json
                contentSchema:
                  type: object
                  required: [ a, b ]
                  additionalProperties:
                    type: integer
YAML

  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $schema,
    validate_content_schemas => 1,
  );

  # perl -wlE'require MIME::Base64; say MIME::Base64::encode_base64url(q!{"a":1,"b":2}!)'
  $result = $openapi->validate_request(request(GET => 'http://example.com/foo',
    [ Cookie => 'token=eyJhIjoxLCJiIjoyfQ' ]));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          header => {
            Cookie => {
              token => { a => 1, b => 2 },
            },
          },
        },
      },
    ],
    'json- and base64-encoded object is properly decoded and returned in the validation result',
  );
};

subtest $::TYPE.': validation with schema defaults' => sub {

  # 1. empty values for parameters provided:  [], {}
  #  a. no defaults configs: no defaults in result; data is not populated with defaults.
  #   b. with_defaults is enabled. defaults in result; data is populated with defaults.
  #
  # 2. parameter data is entirely missing (for query, no querystring; for Cookies and headers,
  #    headers entirely missing)
  #   a. no defaults configs: no defaults in result; data is not populated with defaults.
  #   b. with_defaults is enabled. top-level defaults in result: default: false. data is populated
  #      with top-level defaults.
  #
  # ---- schemas change here
  #   c. with_defaults is enabled; now schemas are 'true' (not a hashref!). no defaults in result;
  #      data is not populated with anything.
  #   d. with_defaults is enabled; now schemas are missing. (only valid for media-types)
  #
  # 3. applicable to cookies only: Cookie header exists, but the named parameter does not exist.
  #   a. no defaults configs: no defaults in result; data is not populated with defaults.
  #   b. with_defaults is enabled. top-level defaults in result: default: false. data is populated
  #      with top-level defaults.

  my ($openapi, $result);
  my $schema = $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML');
paths:
  /{path-array}/{path-object}:    # styled parameters, and media-type parameters and body
    get:
      parameters: []
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties: {}
  /querystring-array:             # querystring
    get:
      parameters: []
  /querystring-object:            # querystring
    get:
      parameters: []
YAML

  ### styled parameters

  $schema->{paths}{'/{path-array}/{path-object}'}{get}{parameters}->@* = map +(
    +{
      name => $_.'-array',
      in => $_,
      $_ eq 'path' ? (required => true) : (),
      explode => ($_ eq 'cookie' ? true : false),
      schema => {
        type => 'array',
        prefixItems => [ map +{ type => 'number', default => $_ }, 0..1 ],
        items => { type => 'number', default => 42 },
        $_ eq 'path' ? () : (default => [ 10, 11 ]),
        default => false, # this is okay because we do not validate the default values
      },
    },
    {
      name => $_.'-object',
      in => $_,
      $_ eq 'cookie' ? (style => 'cookie') : (),
      $_ eq 'path' ? (required => true) : (),
      explode => ($_ eq 'cookie' ? true : false),
      schema => {
        type => 'object',
        properties => +{ map +($_ => +{ type => 'string', default => $_.'_value' }), 'a'..'b' },
        default => false,
      },
    },
  ), qw(path query header cookie);

  $openapi = OpenAPI::Modern->new(openapi_uri => $doc_uri_rel, openapi_schema => $schema);

  # 1a
  $result = $openapi->validate_request(request(GET => 'http://example.com//?query-array=&query-object=',
    [ 'header-array' => '', 'header-object' => '', Cookie => 'cookie-array=4' ]));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          uri => {
            path => {
              'path-array' => [],
              'path-object' => {},
            },
            query => {
              'query-array' => [],
              'query-object' => {},
            },
          },
          header => {
            'header-array' => [],
            'header-object' => {},
            Cookie => {
              'cookie-array' => [ 4 ],
              'cookie-object' => { 'cookie-array' => '4' },
            },
          },
        },
      },
    ],
    'styled parameter data with missing items/properties is deserialized, with no defaults by default',
  );

  # 2a
  $result = $openapi->validate_request(request(GET => 'http://example.com//'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      { request => { uri => { path => { 'path-array' => [], 'path-object' => {} } } } },
    ],
    'styled parameters with missing data is deserialized, with no defaults by default',
  );

  # 3a
  $result = $openapi->validate_request(request(GET => 'http://example.com//',
    [ Cookie => 'alpha=1; beta=2' ]));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      { request => {
          uri => { path => { 'path-array' => [], 'path-object' => {} } },
          header => {
            Cookie => {
              'cookie-object' => { alpha => '1', beta => '2' },
            },
          },
        },
      },
    ],
    'styled cookie data with missing values is deserialized, with no defaults by default',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $schema,
    with_defaults => 1,
  );

  # 1b
  $result = $openapi->validate_request(request(GET => 'http://example.com//?query-array=&query-object=',
    [ 'header-array' => '', 'header-object' => '', Cookie => 'cookie-array=4' ]));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => true,
        defaults => {
          '/request/uri/path/path-array/0' => 0,
          '/request/uri/path/path-array/1' => 1,
          '/request/uri/path/path-object/a' => 'a_value',
          '/request/uri/path/path-object/b' => 'b_value',
          '/request/uri/query/query-array/0' => 0,
          '/request/uri/query/query-array/1' => 1,
          '/request/uri/query/query-object/a' => 'a_value',
          '/request/uri/query/query-object/b' => 'b_value',
          '/request/header/header-array/0' => 0,
          '/request/header/header-array/1' => 1,
          '/request/header/header-object/a' => 'a_value',
          '/request/header/header-object/b' => 'b_value',
          '/request/header/Cookie/cookie-array/1' => 1,
          '/request/header/Cookie/cookie-object/a' => 'a_value',
          '/request/header/Cookie/cookie-object/b' => 'b_value',
        },
      },
      {
        request => {
          uri => {
            path => {
              'path-array' => [ 0, 1 ],
              'path-object' => { a => 'a_value', b => 'b_value' },
            },
            query => {
              'query-array' => [ 0, 1 ],
              'query-object' => { a => 'a_value', b => 'b_value' },
            },
          },
          header => {
            'header-array' => [ 0, 1 ],
            'header-object' => { a => 'a_value', b => 'b_value' },
            Cookie => {
              'cookie-array' => [ 4, 1 ],
              'cookie-object' => { 'cookie-array' => '4', a => 'a_value', b => 'b_value' },
            },
          },
        },
      },
    ],
    'styled parameter data with empty values, missing items or properties are included when with_defaults is set',
  );

  # 2b
  $result = $openapi->validate_request(request(GET => 'http://example.com//'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => true,
        defaults => {
          '/request/uri/path/path-array/0' => 0,          # path parameters are never entirely missing
          '/request/uri/path/path-array/1' => 1,
          '/request/uri/path/path-object/a' => 'a_value',
          '/request/uri/path/path-object/b' => 'b_value',
          '/request/uri/query/query-array' => false,
          '/request/uri/query/query-object' => false,
          '/request/header/header-array' => false,
          '/request/header/header-object' => false,
          '/request/header/Cookie/cookie-array' => false,
          '/request/header/Cookie/cookie-object' => false,
          # no body default - how would we know what media-type to use?
        },
      },
      {
        request => {
          uri => {
            path => {
              'path-array' => [ 0, 1 ],
              'path-object' => { a => 'a_value', b => 'b_value' },
            },
            query => { 'query-array' => false, 'query-object' => false },
          },
          header => {
            'header-array' => false,
            'header-object' => false,
            Cookie => { 'cookie-array' => false, 'cookie-object' => false },
          },
        },
      }
    ],
    'styled parameter data now includes defaults when values are missing',
  );

  # 3b
  $result = $openapi->validate_request(request(GET => 'http://example.com//',
    [ Cookie => 'alpha=1; beta=2' ]));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => true,
        defaults => {
          '/request/uri/path/path-array/0' => 0,          # path parameters are never entirely missing
          '/request/uri/path/path-array/1' => 1,
          '/request/uri/path/path-object/a' => 'a_value',
          '/request/uri/path/path-object/b' => 'b_value',
          '/request/uri/query/query-array' => false,
          '/request/uri/query/query-object' => false,
          '/request/header/header-array' => false,
          '/request/header/header-object' => false,
          '/request/header/Cookie/cookie-array' => false,
          '/request/header/Cookie/cookie-object/a' => 'a_value',
          '/request/header/Cookie/cookie-object/b' => 'b_value',
          # no body default - how would we know what media-type to use?
        },
      },
      {
        request => {
          uri => {
            path => {
              'path-array' => [ 0, 1 ],
              'path-object' => { a => 'a_value', b => 'b_value' },
            },
            query => { 'query-array' => false, 'query-object' => false },
          },
          header => {
            'header-array' => false,
            'header-object' => false,
            Cookie => {
              'cookie-array' => false,
              'cookie-object' => {
                alpha => '1',
                beta => '2',
                a => 'a_value',
                b => 'b_value',
              },
            },
          },
        },
      }
    ],
    'styled cookie data now includes defaults when some values are missing',
  );


  # 2c
  $schema->{paths}{'/{path-array}/{path-object}'}{get}{parameters}[$_]{schema} = true
    foreach 0..7; # (array, object) x (path, query, header, cookie)

  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $schema,
    with_defaults => 1,
  );

  $result = $openapi->validate_request(request(GET => 'http://example.com//'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => true,
        defaults => {},
      },
      # we no longer know to style this as an array
      { request => { uri => { path => { 'path-array' => '', 'path-object' => '' } } } },
    ],
    'styled parameter data does not include any defaults when schemas are a boolean',
  );


  ### media-type parameters and body

  $schema->{paths}{'/{path-array}/{path-object}'}{get}{parameters}->@* = map +(
    +{
      name => $_.'-array',
      in => $_,
      content => {
        'application/json' => {
          schema => {
            type => 'array',
            prefixItems => [ map +{ type => 'number', default => $_ }, 0..1 ],
            items => { type => 'number', default => 42 },
            default => false, # this is okay because we do not validate the default values
          },
        },
      },
    },
    {
      name => $_.'-object',
      in => $_,
      content => {
        'application/json' => {
          schema => {
            type => 'object',
            properties => +{ map +($_ => +{ type => 'string', default => $_.'_value' }), 'a'..'b' },
            default => false,
          },
        },
      },
    },
  ), qw(path query header cookie);

  $schema->{paths}{'/{path-array}/{path-object}'}{get}{requestBody}{content}{'application/json'}{schema}{properties}->%* = (
    'body-array' => {
      type => 'array',
      prefixItems => [ map +{ type => 'number', default => $_ }, 0..1 ],
      items => { type => 'number', default => 42 },
      default => false, # never used: what media-type would we use?
    },
    'body-object' => {
      type => 'object',
      properties => +{ map +($_ => +{ type => 'string', default => $_.'_value' }), 'a'..'b' },
      default => false, # never used: what media-type would we use?
    },
  );

  $openapi = OpenAPI::Modern->new(openapi_uri => $doc_uri_rel, openapi_schema => $schema);

  # 1a
  $result = $openapi->validate_request(request(GET => 'http://example.com/[]/{}?query-array=[]&query-object={}',
    [ 'header-array' => '[]', 'header-object' => '{}', Cookie => 'cookie-array=[]; cookie-object={}', 'Content-Type' => 'application/json' ],
    '{"body-array":[],"body-object":{}}'));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          uri => {
            path => { 'path-array' => [], 'path-object' => {} },
            query => { 'query-array' => [], 'query-object' => {} },
          },
          header => {
            'header-array' => [],
            'header-object' => {},
            Cookie => { 'cookie-array' => [], 'cookie-object' => {} },
          },
          body => { content => { 'body-array' => [], 'body-object' => {} } },
        },
      },
    ],
    'media-type parameter and body data with incomplete values is deserialized, with no defaults',
  );

  # 2a
  $result = $openapi->validate_request(request(GET => 'http://example.com/[]/{}'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      { request => { uri => { path => { 'path-array' => [], 'path-object' => {} } } } },
    ],
    'media-type parameters with missing data is deserialized, with no defaults by default',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $schema,
    with_defaults => 1,
  );

  # 1b
  $result = $openapi->validate_request(request(GET => 'http://example.com/[]/{}?query-array=[]&query-object={}',
    [ 'header-array' => '[]', 'header-object' => '{}', Cookie => 'cookie-array=[]; cookie-object={}', 'Content-Type' => 'application/json' ],
    '{"body-array":[],"body-object":{}}'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => true,
        defaults => {
          '/request/uri/path/path-array/0' => 0,
          '/request/uri/path/path-array/1' => 1,
          '/request/uri/path/path-object/a' => 'a_value',
          '/request/uri/path/path-object/b' => 'b_value',
          '/request/uri/query/query-array/0' => 0,
          '/request/uri/query/query-array/1' => 1,
          '/request/uri/query/query-object/a' => 'a_value',
          '/request/uri/query/query-object/b' => 'b_value',
          '/request/header/header-array/0' => 0,
          '/request/header/header-array/1' => 1,
          '/request/header/header-object/a' => 'a_value',
          '/request/header/header-object/b' => 'b_value',
          '/request/header/Cookie/cookie-array/0' => 0,
          '/request/header/Cookie/cookie-array/1' => 1,
          '/request/header/Cookie/cookie-object/a' => 'a_value',
          '/request/header/Cookie/cookie-object/b' => 'b_value',
          '/request/body/content/body-array/0' => 0,
          '/request/body/content/body-array/1' => 1,
          '/request/body/content/body-object/a' => 'a_value',
          '/request/body/content/body-object/b' => 'b_value',
        },
      },
      {
        request => {
          uri => {
            path => {
              'path-array' => [ 0, 1 ],
              'path-object' => { a => 'a_value', b => 'b_value' },
            },
            query => {
              'query-array' => [ 0, 1 ],
              'query-object' => { a => 'a_value', b => 'b_value' },
            },
          },
          header => {
            'header-array' => [ 0, 1 ],
            'header-object' => { a => 'a_value', b => 'b_value' },
            Cookie => {
              'cookie-array' => [ 0, 1 ],
              'cookie-object' => { a => 'a_value', b => 'b_value' },
            },
          },
          body => {
            content => {
              'body-array' => [ 0, 1 ],
              'body-object' => { a => 'a_value', b => 'b_value' },
            },
          },
        },
      },
    ],
    'media-type parameter and body data with empty values, missing items or properties are included when with_defaults is set',
  );

  # 2b
  $result = $openapi->validate_request(request(GET => 'http://example.com/[]/{}'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => true,
        defaults => {
          '/request/uri/path/path-array/0' => 0,          # path parameters are never entirely missing
          '/request/uri/path/path-array/1' => 1,
          '/request/uri/path/path-object/a' => 'a_value',
          '/request/uri/path/path-object/b' => 'b_value',
          '/request/uri/query/query-array' => false,
          '/request/uri/query/query-object' => false,
          '/request/header/header-array' => false,
          '/request/header/header-object' => false,
          '/request/header/Cookie/cookie-array' => false,
          '/request/header/Cookie/cookie-object' => false,
          # no body default - how would we know what media-type to use?
        },
      },
      {
        request => {
          uri => {
            path => {
              'path-array' => [ 0, 1 ],
              'path-object' => { a => 'a_value', b => 'b_value' },
            },
            query => { 'query-array' => false, 'query-object' => false },
          },
          header => {
            'header-array' => false,
            'header-object' => false,
            Cookie => { 'cookie-array' => false, 'cookie-object' => false, },
          },
          # no body default - how would we know what media-type to use?
        },
      },
    ],
    'media-type parameter and body data now includes defaults when values are missing',
  );


  $schema->{paths}{'/{path-array}/{path-object}'}{get}{requestBody}{content}{'application/json'}{schema} = true;
  $schema->{paths}{'/{path-array}/{path-object}'}{get}{parameters}[$_]{content}{'application/json'}{schema} = true
    foreach 0..7; # (array, object) x (path, query, header, cookie)

  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $schema,
    with_defaults => 1,
  );

  # 2c
  $result = $openapi->validate_request(request(GET => 'http://example.com/1/2'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => true,
        defaults => {},
      },
      { request => { uri => { path => { 'path-array' => 1, 'path-object' => 2 } } } },
    ],
    'media-type parameter and body data does not include any defaults when schemas are a boolean',
  );


  $schema->{paths}{'/{path-array}/{path-object}'}{get}{requestBody}{content}{'application/json'} = {};
  $schema->{paths}{'/{path-array}/{path-object}'}{get}{parameters}[$_]{content}{'application/json'} = {}
    foreach 0..7; # (array, object) x (path, query, header, cookie)

  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $schema,
    with_defaults => 1,
  );

  # 2d
  $result = $openapi->validate_request(request(GET => 'http://example.com/1/2'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => true,
        defaults => {},
      },
      { request => { uri => { path => { 'path-array' => 1, 'path-object' => 2 } } } },
    ],
    'media-type parameter and body data does not include any defaults when schemas do not exist',
  );

  ### querystring parameters

  $schema->{paths}{'/querystring-array'}{get}{parameters}->@* = +{
    name => 'querystring-array',
    in => 'querystring',
    content => {
      'application/json' => {
        schema => {
          type => 'array',
          prefixItems => [ map +{ type => 'number', default => $_ }, 0..1 ],
          items => { type => 'number', default => 42 },
          default => false, # this is okay because we do not validate the default values
        },
      },
    },
  };

  $schema->{paths}{'/querystring-object'}{get}{parameters}->@* = +{
    name => 'querystring-object',
    in => 'querystring',
    content => {
      'application/json' => {
        schema => {
          type => 'object',
          properties => +{ map +($_ => +{ type => 'string', default => $_.'_value' }), 'a'..'b' },
          default => false,
        },
      },
    },
  };

  $openapi = OpenAPI::Modern->new(openapi_uri => $doc_uri_rel, openapi_schema => $schema);

  # 1a
  $result = $openapi->validate_request(request(GET => 'http://example.com/querystring-array?[]'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      { request => { uri => { query => [] } } },
    ],
    'querystring array parameter data with incomplete values is deserialized, with no defaults by default',
  );

  # 1a
  $result = $openapi->validate_request(request(GET => 'http://example.com/querystring-object?{}'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      { request => { uri => { query => {} } } },
    ],
    'querystring object parameter data with incomplete values is deserialized, with no defaults by default',
  );

  # 2a
  $result = $openapi->validate_request(request(GET => 'http://example.com/querystring-array'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {},
    ],
    'missing querystring is deserialized, with no defaults by default',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $schema,
    with_defaults => 1,
  );

  # 1b
  $result = $openapi->validate_request(request(GET => 'http://example.com/querystring-array?[]'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => true,
        defaults => {
          '/request/uri/query/0' => 0,
          '/request/uri/query/1' => 1,
        },
      },
      { request => { uri => { query => [ 0, 1 ] } } },
    ],
    'querystring array parameter data with empty values, missing items are included when with_defaults is set',
  );

  # 1b
  $result = $openapi->validate_request(request(GET => 'http://example.com/querystring-object?{}'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => true,
        defaults => {
          '/request/uri/query/a' => 'a_value',
          '/request/uri/query/b' => 'b_value',
        },
      },
      { request => { uri => { query => { a => 'a_value', b => 'b_value' } } } },
    ],
    'querystring object parameter data with empty values, missing properties are included when with_defaults is set',
  );

  # 2b
  $result = $openapi->validate_request(request(GET => 'http://example.com/querystring-array'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => true,
        defaults => {
          '/request/uri/query' => false,
        },
      },
      { request => { uri => { query => false } } },
    ],
    'querystring parameter array data now includes defaults when values are missing',
  );


  $schema->{paths}{'/querystring-array'}{get}{parameters}[0]{content}{'application/json'}{schema} = true;

  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $schema,
    with_defaults => 1,
  );

  # 2c
  $result = $openapi->validate_request(request(GET => 'http://example.com/querystring-array'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => true,
        defaults => {},
      },
      {},
    ],
    'querystring parameter data does not include any defaults when schemas are a boolean',
  );


  $schema->{paths}{'/querystring-array'}{get}{parameters}[0]{content}{'application/json'} = {};

  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $schema,
    with_defaults => 1,
  );

  # 2d
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => true,
        defaults => {},
      },
      {},
    ],
    'querystring parameter data does not include any defaults when schemas do not exist',
  );
};

if (++$type_index < @::TYPES) {
  bail_if_not_passing if $ENV{AUTHOR_TESTING};
  goto START;
}

had_no_warnings() if $ENV{AUTHOR_TESTING};
done_testing;
