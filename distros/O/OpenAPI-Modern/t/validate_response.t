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
use JSON::Schema::Modern::Utilities 'jsonp';

my $doc_uri_rel = Mojo::URL->new('/api');
my $doc_uri = $doc_uri_rel->to_abs(Mojo::URL->new('http://example.com'));

subtest 'missing or invalid arguments' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /:
    get:
      operationId: my_op
      responses:
        default: {}
YAML

  like(
    exception { $openapi->validate_response(undef) },
    qr/^missing response/,
    'response must be passed',
  );

  package Bespoke::Response {
    sub request { shift->{request} }
  }

  is_equal(
    $openapi->validate_response(bless({}, 'Bespoke::Response'), my $options = { operation_id => 'my_op' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => jsonp(qw(/paths / get)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths / get)))->to_string,
          error => 'Failed to parse response: unknown type Bespoke::Response',
        },
      ],
    },
    'response must be a recognized type',
  );
  cmp_result(
    $options,
    {
      response => isa('Mojo::Message::Response'),
      method => 'GET',
      operation_id => 'my_op',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths / get)))),
    },
    'options hash is populated',
  );

  is_equal(
    $openapi->validate_response(bless({ request => bless({}, 'Bespoke::Request') }, 'Bespoke::Response'))->TO_JSON,
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
    'request on response object, if passed, must be a recognized type',
  );

  is_equal(
    $openapi->validate_response(bless({}, 'Bespoke::Response'), { request => bless({}, 'Bespoke::Request') })->TO_JSON,
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
    'request in options, if passed, must be a recognized type',
  );

  like(
    exception {
      $openapi->validate_response(bless({ request => bless({}, 'Bespoke::Request') }, 'Bespoke::Response'), { request => bless({}, 'Bespoke::Request') })
    },
    qr/^\$response->request and \$options->\{request\} are inconsistent/,
    'if request is passed twice, it must be the same object (not just the same values)',
  );
};

my $type_index = 0;

START:
$::TYPE = $::TYPES[$type_index];
note 'REQUEST/RESPONSE TYPE: '.$::TYPE;

subtest $::TYPE.': match failure' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      operationId: foo_operation
YAML

  my $result = $openapi->validate_response(response(200), my $options = { operation_id => 'foo' });
  isa_ok($result, ['JSON::Schema::Modern::Result'], 'got a result object back');
  is_equal(
    $result->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => '',
          absoluteKeywordLocation => $doc_uri->to_string,
          error => 'unknown operation_id "foo"',
        },
      ],
    },
    'match failure from find_path_item with operation_id',
  );
  is_equal(
    $options,
    {
      operation_id => 'foo',
    },
    'options is populated with all inferred data so far',
  );


  if ($::TYPE eq 'lwp') {
    my $response = response(404);
    $response->request(request('GET', 'http://example.com/foo'));

    is_equal(
      $openapi->validate_response($response)->TO_JSON,
      {
        valid => false,
        errors => [
          {
            instanceLocation => '/request',
            keywordLocation => '/paths',
            absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
            error => 'no match found for request '.to_str($response->request),
          },
        ],
      },
      'request can be retrieved from the HTTP::Response object',
    );

    $response->request(request('POST', 'http://example.com/foo'));
    is_equal(
      $openapi->validate_response($response, my $options = {})->TO_JSON,
      { valid => true },
      'operation is successfully found using the request on the response',
    );
    cmp_result(
      $options,
      {
        request => isa('Mojo::Message::Request'),
        response => isa('Mojo::Message::Response'),
        uri => isa('Mojo::URL'),
        path_template => '/foo',
        method => 'POST',
        path_captures => {},
        uri_captures => {},
        operation_id => 'foo_operation',
        operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo post)))),
      },
      'additional information is filled in in $options',
    );
  }
};

subtest $::TYPE.': validation errors in responses' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
components:
  pathItems:
    bar:
      post:
        operationId: bar_operation
paths:
  /foo:
    post:
      operationId: foo_operation
      responses:
        200: {}
        2XX: {}
YAML

  is_equal(
    $openapi->validate_response(response(404), my $options = { operation_id => 'bar_operation' })->TO_JSON,
    { valid => true },
    'no responses object - nothing to validate against',
  );
  cmp_result(
    $options,
    {
      response => isa('Mojo::Message::Response'),
      method => 'POST',
      operation_id => 'bar_operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/components pathItems bar post)))),
    },
    'additional information is filled in in $options',
  );

  is_equal(
    $openapi->validate_response(response(404), $options = { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/code',
          keywordLocation => jsonp(qw(/paths /foo post responses)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses)))->to_string,
          error => 'no response object found for code 404',
        },
      ],
    },
    'response code not found - nothing to validate against',
  );
  cmp_result(
    $options,
    {
      response => isa('Mojo::Message::Response'),
      path_template => '/foo',
      method => 'POST',
      operation_id => 'foo_operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo post)))),
    },
    'additional information is filled in in $options',
  );

  is_equal(
    $openapi->validate_response(response(200), { path_template => '/foo', method => 'POST' })->TO_JSON,
    { valid => true },
    'response code matched exactly',
  );

  is_equal(
    $openapi->validate_response(response(202), { path_template => '/foo', method => 'POST' })->TO_JSON,
    { valid => true },
    'response code matched wildcard',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
components:
  responses:
    foo: {}
paths:
  /foo:
    post:
      responses:
        200:
          $ref: 'http://example.com/otherapi#/components/headers/foo'
YAML

  $openapi->evaluator->add_document(JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://example.com/otherapi',
    schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML')));
components:
  headers:
    foo:
      schema: {}
YAML

  is_equal(
    $openapi->validate_response(response(200), { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses 200 $ref)))->to_string,
          error => 'EXCEPTION: bad $ref to http://example.com/otherapi#/components/headers/foo: not a "response"',
        },
      ],
    },
    '$ref in responses points to the wrong type',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
components:
  responses:
    foo:
      $ref: 'http://example.com/otherapi#/i_do_not_exist'
    default:
      headers:
        Content-Type:
          # this is ignored!
          required: true
          schema: false
        Foo-Bar:
          $ref: '#/components/headers/foo-header'
  headers:
    foo-header:
      required: true
      schema:
        pattern: ^[0-9]+$
paths:
  /foo:
    post:
      responses:
        303:
          $ref: '#/components/responses/foo'
        default:
          $ref: '#/components/responses/default'
YAML

  is_equal(
    $openapi->validate_response(response(303), { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => jsonp(qw(/paths /foo post responses 303 $ref $ref)),
          absoluteKeywordLocation => $doc_uri.'#/components/responses/foo/$ref',
          error => 'EXCEPTION: unable to find resource "http://example.com/otherapi#/i_do_not_exist"',
        },
      ],
    },
    'bad $ref in responses',
  );

  is_equal(
    $openapi->validate_response(response(500), { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref headers Foo-Bar $ref required)),
          absoluteKeywordLocation => $doc_uri.'#/components/headers/foo-header/required',
          error => 'missing header: Foo-Bar',
        },
      ],
    },
    'header is missing',
  );

  is_equal(
    $openapi->validate_response(response(500, [ 'FOO-BAR' => 'header value' ]), { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Foo-Bar',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref headers Foo-Bar $ref schema pattern)),
          absoluteKeywordLocation => $doc_uri.'#/components/headers/foo-header/schema/pattern',
          error => 'pattern does not match',
        },
      ],
    },
    'header is evaluated against its schema',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get:
      responses:
        default:
          headers:
            MultipleValuesAsArray:
              schema:
                type: array
                uniqueItems: true
                minItems: 3
                maxItems: 3
                items:
                  enum: [one, two, three]
          content:
            '*/*':
              schema: {}
YAML

  my $response = response(404, [
    MultipleValuesAsArray => '  one',
    MultipleValuesAsArray => ' one ',
    MultipleValuesAsArray => ' three ',
  ]);
  is_equal(
    (my $result = $openapi->validate_response($response,
      { path_template => '/foo', method => 'GET' }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/MultipleValuesAsArray',
          keywordLocation => jsonp(qw(/paths /foo get responses default headers MultipleValuesAsArray schema uniqueItems)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get responses default headers MultipleValuesAsArray schema uniqueItems)))->to_string,
          error => 'items at indices 0 and 1 are not unique',
        },
      ],
    },
    'headers that appear more than once are parsed into an array',
  );
  is_equal(
    $result->data,
    { response => { header => { MultipleValuesAsArray => [ qw(one one three) ] } } },
    'header data was correctly parsed',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
components:
  responses:
    my_default:
      content:
        text/*:
          schema:
            type: string
            maxLength: 3
paths:
  /foo:
    get:
      responses:
        default:
          $ref: '#/components/responses/my_default'
    additionalOperations:
      CONNECT:
        operationId: foo_connect_response
        responses:
          default:
            $ref: '#/components/responses/my_default'
YAML

  is_equal(
    $openapi->validate_response(response($_, [ 'Content-Type' => 'text/plain', 'Transfer-Encoding' => 'chunked' ], "4\r\nabcd\r\n0\r\n\r\n"), { path_template => '/foo', method => 'GET' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Transfer-Encoding',
          keywordLocation => jsonp(qw(/paths /foo get)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get)))->to_string,
          error => 'RFC9112 §6.1-10: "A server MUST NOT send a Transfer-Encoding header field in any response with a status code of 1xx (Informational) or 204 (No Content)"',
        },
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo get responses default $ref content text/* schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/components responses my_default content text/* schema maxLength)))->to_string,
          error => 'length is greater than 3',
        },
      ],
    },
    'Transfer-Encoding header is detected with status code '.$_.' (and body is still parseable)',
  )
  foreach 102, 204;

  is_equal(
    $openapi->validate_response(
      response(200, [ 'Content-Type' => 'text/plain', 'Transfer-Encoding' => 'chunked' ], "4\nabcd\n0\n\n"),
      { operation_id => 'foo_connect_response' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Transfer-Encoding',
          keywordLocation => jsonp(qw(/paths /foo additionalOperations CONNECT)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo additionalOperations CONNECT)))->to_string,
          error => 'RFC9112 §6.1-10: "A server MUST NOT send a Transfer-Encoding header field in any 2xx (Successful) response to a CONNECT request"',
        },
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo additionalOperations CONNECT responses default $ref content text/* schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/components responses my_default content text/* schema maxLength)))->to_string,
          error => 'length is greater than 3',
        },
      ],
    },
    'Transfer-Encoding header is detected in response to a CONNECT request (and body is still parseable)',
  );

  is_equal(
    $openapi->validate_response(response(200,
      [ 'Content-Type' => 'text/plain', 'Content-Length' => 4, 'Transfer-Encoding' => 'chunked' ],
      "4\r\nabcd\r\n0\r\n\r\n"), { path_template => '/foo', method => 'GET' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Content-Length',
          keywordLocation => jsonp(qw(/paths /foo get)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo get)))->to_string,
          error => 'Content-Length cannot appear together with Transfer-Encoding',
        },
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo get responses default $ref content text/* schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/components responses my_default content text/* schema maxLength)))->to_string,
          error => 'length is greater than 3',
        },
      ],
    },
    'conflict between Content-Length + Transfer-Encoding headers (and body is still parseable)',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
components:
  responses:
    default:
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
        bloop/html:
          schema: false
        text/plain:
          schema:
            const: éclair
    foo:
      content:
        application/json:
          schema: {}
paths:
  /foo:
    post:
      responses:
        303:
          $ref: '#/components/responses/foo'
        default:
          $ref: '#/components/responses/default'
YAML

  # response has no content-type, content-length or body.
  is_equal(
    $openapi->validate_response(response(200), { path_template => '/foo', method => 'POST' })->TO_JSON,
    { valid => true },
    'missing Content-Type does not cause an exception',
  );

  $response = response(200, [ 'Content-Type' => 'application/json' ], 'null');
  remove_header($response, 'Content-Length');

  is_equal(
    $openapi->validate_response($response, { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header',
          keywordLocation => jsonp(qw(/paths /foo post)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post)))->to_string,
          error => 'missing header: Content-Length',
        },
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content application/json schema type)),
          absoluteKeywordLocation => $doc_uri.'#/components/responses/default/content/application~1json/schema/type',
          error => 'got null, not object',
        },
      ],
    },
    'missing Content-Length does not prevent the response body from being checked',
  );

  is_equal(
    $openapi->validate_response(response(200, [ 'Content-Type' => 'text/bloop' ], 'plain text'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content)),
          absoluteKeywordLocation => $doc_uri.'#/components/responses/default/content',
          error => 'incorrect Content-Type "text/bloop"',
        },
      ],
    },
    'Content-Type not allowed by the schema',
  );

  is_equal(
    $openapi->validate_response(response(200, [ 'Content-Type' => 'bloop/html' ], 'html text'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content bloop/html)),
          absoluteKeywordLocation => $doc_uri.'#/components/responses/default/content/bloop~1html',
          error => 'EXCEPTION: unsupported media type "bloop/html": add support with JSON::Schema::Modern::Utilities::add_media_type(...)',
        },
      ],
    },
    'unsupported Content-Type',
  );

  is_equal(
    ($result = $openapi->validate_response(response(200,
        [ 'Content-Type' => 'text/plain; charset=ISO-8859-1' ],
        chr(0xe9).'clair'),
      { path_template => '/foo', method => 'POST' }))->TO_JSON,
    { valid => true },
    'latin1 content can be successfully decoded',
  );
  is_equal(
    $result->data,
    { response => { body => { content => 'éclair' } } },
    'body data was correctly parsed',
  );

  is_equal(
    $openapi->validate_response(response(200, [ 'Content-Type' => 'application/json' ],
        '{"alpha": "foo", "gamma": "o.o"}'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body/content/alpha',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content application/json schema properties alpha pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/components responses default content application/json schema properties alpha pattern)))->to_string,
          error => 'pattern does not match',
        },
        {
          instanceLocation => '/response/body/content/gamma',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content application/json schema properties gamma const)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/components responses default content application/json schema properties gamma const)))->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content application/json schema properties)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/components responses default content application/json schema properties)))->to_string,
          error => 'not all properties are valid',
        },
      ],
    },
    'decoded content does not match the schema',
  );


  my $disapprove = v224.178.160.95.224.178.160; # utf-8-encoded "ಠ_ಠ"
  is_equal(
    ($result = $openapi->validate_response(response(200, [ 'Content-Type' => 'application/json' ],
        '{"alpha": "123", "gamma": "'.$disapprove.'"}'),
      { path_template => '/foo', method => 'POST' }))->TO_JSON,
    { valid => true },
    'decoded content matches the schema',
  );
  is_equal(
    $result->data,
    { response => { body => { content => { alpha => '123', gamma => 'ಠ_ಠ' } } } },
    'body data was correctly parsed',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      responses:
        200:
          headers:
            Content-Length:
              description: if present, the value must be 0
              required: false
              schema:
                type: integer
                const: 0
            # NOTE: this schema definition is ignored!
            Content-Type:
              required: true
              schema: false
          content:
            '*/*':
              schema:
                type: string
                maxLength: 0
        204:
          description: no content permitted, and no Content-Length either
          headers:
            Content-Length:
              required: false
              schema: false
            # NOTE: this schema definition is ignored!
            Content-Type:
              required: true
              schema: false
          content:
            '*/*':
              schema: false
        default:
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

  is_equal(
    $openapi->validate_response(response(400, [ 'Content-Length' => 10 ], 'plain text'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header',
          keywordLocation => jsonp(qw(/paths /foo post responses default content)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses default content)))->to_string,
          error => 'missing header: Content-Type',
        },
      ],
    },
    'missing Content-Type does not cause an exception',
  );

  is_equal(
    $openapi->validate_response(
      response(400, [ 'Content-Length' => 12, 'Content-Type' => 'text/plain' ], ''), # Content-Length lies!
        { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo post responses default content text/plain schema minLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses default content text/plain schema minLength)))->to_string,
          error => 'length is less than 10',
        },
      ],
    },
    'missing body (with a lying Content-Length) does not cause an exception, but is detectable',
  );

  is_equal(
    $openapi->validate_response(
      response(400, [ 'Content-Type' => 'text/plain' ], '0'), { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo post responses default content text/plain schema minLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses default content text/plain schema minLength)))->to_string,
          error => 'length is less than 10',
        },
      ],
    },
    '"false" body is still seen',
  );


  $response = response(400, [ 'Content-Type' => 'text/plain' ], 'éclair');
  remove_header($response, 'Content-Length');

  is_equal(
    $openapi->validate_response($response, { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header',
          keywordLocation => jsonp(qw(/paths /foo post)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post)))->to_string,
          error => 'missing header: Content-Length',
        },
        {
          instanceLocation => '/response/header',
          keywordLocation => jsonp(qw(/paths /foo post responses default headers Content-Length required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses default headers Content-Length required)))->to_string,
          error => 'missing header: Content-Length',
        },
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo post responses default content text/plain schema minLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses default content text/plain schema minLength)))->to_string,
          error => 'length is less than 10',
        },
      ],
    },
    'Content-Length is required in responses with a message body',
  );

  is_equal(
    $openapi->validate_response(response(200, [ 'Content-Type' => 'text/plain', 'Content-Length' => 25 ], 'I should not have content'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Content-Length',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 headers Content-Length schema const)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses 200 headers Content-Length schema const)))->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 content */* schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses 200 content */* schema maxLength)))->to_string,
          error => 'length is greater than 0',
        },
      ],
    },
    'an undesired response body is detectable',
  );


  # note: when 204, mojo's $message->body always returns '' and Content-Length is stripped.
  # this test is only possible (for HTTP::Response) if we manually add a Content-Length; it will not
  # be added via parse().
  {
  my $todo = todo 'Mojolicious will strip Content-Length for 204 responses' if $::TYPE eq 'mojo';
  is_equal(
    $openapi->validate_response(response(204, [ 'Content-Type' => 'text/plain', 'Content-Length' => 20 ], 'I should not have content'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Content-Length',
          keywordLocation => jsonp(qw(/paths /foo post responses 204 headers Content-Length schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses 204 headers Content-Length schema)))->to_string,
          error => 'response header not permitted',
        },
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo post responses 204 content */* schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses 204 content */* schema)))->to_string,
          error => 'response body not permitted',
        },
      ],
    },
    'an undesired response body is detectable for 204 responses',
  );
  }


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      responses:
        default:
          content:
            '*/*':
              schema:
                maxLength: 0
YAML

  is_equal(
    $openapi->validate_response(
      response(400, [ 'Content-Length' => 1, 'Content-Type' => 'unknown/unknown' ], '!!!'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo post responses default content */* schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses default content */* schema maxLength)))->to_string,
          error => 'length is greater than 0',
        },
      ],
    },
    'demonstrate recipe for guaranteeing that there is no response body',
  );
};

subtest $::TYPE.': unevaluatedProperties and annotations' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      responses:
        200:
          content:
            application/json:
              schema:
                type: object
                properties:
                  bar: true
                unevaluatedProperties: false
YAML

  is_equal(
    $openapi->validate_response(
      response(200, [ 'Content-Type' => 'application/json' ], '{"foo":1}'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body/content/foo',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 content application/json schema unevaluatedProperties)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses 200 content application/json schema unevaluatedProperties)))->to_string,
          error => 'additional property not permitted',
        },
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 content application/json schema unevaluatedProperties)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses 200 content application/json schema unevaluatedProperties)))->to_string,
          error => 'not all additional properties are valid',
        },
      ],
    },
    'unevaluatedProperties can be used in schemas',
  );
};

subtest $::TYPE.': writeOnly' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      responses:
        200:
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

  is_equal(
    $openapi->validate_response(
      response(200, [ 'Content-Type' => 'application/json', A => 1, B => 2 ], '{"c":1,"d":2}'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    { valid => true },
    'writeOnly values are still valid in a response',
  );
};

subtest $::TYPE.': custom error messages for false schemas' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      responses:
        200:
          headers:
            Foo:
              schema: false
          content:
            '*/*':
              schema: false
YAML

  is_equal(
    $openapi->validate_response(
      response(200, [ Foo => 1, 'Content-Type' => 'text/plain' ], 'hi'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Foo',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 headers Foo schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses 200 headers Foo schema)))->to_string,
          error => 'response header not permitted',
        },
        {
          instanceLocation => '/response/body/content',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 content */* schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses 200 content */* schema)))->to_string,
          error => 'response body not permitted',
        },
      ],
    },
    'custom error message when the entity is not permitted',
  );
};

subtest $::TYPE.': validation with schema defaults' => sub {
  my ($openapi, $result);
  my $schema = decode_yaml(OPENAPI_PREAMBLE.<<'YAML');
paths:
  /:
    get:
      operationId: me
      parameters: []
      responses:
        default:
          headers: {}
          content:
            application/json:
              schema:
                type: object
                properties: {}
YAML

  $schema->{paths}{'/'}{get}{responses}{default}{headers}->%* = (
    'header-array' => +{
      explode => false,
      schema => {
        type => 'array',
        prefixItems => [ map +{ type => 'number', default => $_ }, 0..1 ],
        items => { type => 'number', default => 42 },
      },
    },
    'header-object' => {
      explode => false, # forces form style to use ?$name=$key0,$val0,$key1,$val1,$key2,$val2
      schema => {
        type => 'object',
        properties => +{ map +($_ => +{ type => 'string', default => $_.'_value' }), 'a'..'b' },
      },
    },
  );

  $schema->{paths}{'/'}{get}{responses}{default}{content}{'application/json'}{schema}{properties}->%* = (
    'body-array' => {
      type => 'array',
      prefixItems => [ map +{ type => 'number', default => $_ }, 0..1 ],
      items => { type => 'number', default => 42 },
    },
    'body-object' => {
      type => 'object',
      properties => +{ map +($_ => +{ type => 'string', default => $_.'_value' }), 'a'..'b' },
    },
  );

  $openapi = OpenAPI::Modern->new(openapi_uri => $doc_uri_rel, openapi_schema => $schema);

  is_equal(
    ($result = $openapi->validate_response(response('200',
        [ 'header-array' => '', 'header-object' => '', 'Content-Type' => 'application/json' ],
        '{"body-array":[],"body-object":{}}',
    ), { operation_id => 'me' }))->TO_JSON,
    { valid => true },
    'no defaults are included by default',  # ha!
  );
  is_equal(
    $result->data,
    {
      response => {
        header => {
          'header-array' => [],
          'header-object' => {},
        },
        body => {
          content => {
            'body-array' => [],
            'body-object' => {},
          },
        },
      },
    },
    'data is correctly deserialized, without defaults',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $schema,
    with_defaults => 1,
  );

  is_equal(
    ($result = $openapi->validate_response(response('200',
        [ 'header-array' => '', 'header-object' => '' ],
    ), { operation_id => 'me' }))->TO_JSON,
    {
      valid => true,
      defaults => {
        '/response/header/header-array/0' => 0,
        '/response/header/header-array/1' => 1,
        '/response/header/header-object/a' => 'a_value',
        '/response/header/header-object/b' => 'b_value',
      },
    },
    'with empty headers, styled header defaults are included when with_defaults is set on the evaluator',
  );
  is_equal(
    $result->data,
    {
      response => {
        header => {
          'header-array' => [ 0, 1 ],
          'header-object' => { a => 'a_value', b => 'b_value' },
        },
      },
    },
    'styled parameter data now includes defaults',
  );


  $schema->{paths}{'/'}{get}{responses}{default}{headers}->%* = (
    'header-array' => +{
      content => {
        'application/json' => {
          schema => {
            type => 'array',
            prefixItems => [ map +{ type => 'number', default => $_ }, 0..1 ],
            items => { type => 'number', default => 42 },
            default => [ 10, 11, 12 ],
          },
        },
      },
    },
    'header-object' => {
      content => {
        'application/json' => {
          schema => {
            type => 'object',
            properties => +{ map +($_ => +{ type => 'string', default => $_.'_value' }), 'a'..'b' },
            default => { x => 'j', y => 'k', z => 'l' },
          },
        },
      },
    },
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $schema,
    with_defaults => 1,
  );

  is_equal(
    ($result = $openapi->validate_response(response('200',
        [ 'header-array' => '[]', 'header-object' => '{}', 'Content-Type' => 'application/json' ],
        '{"body-array":[],"body-object":{}}',
    ), { operation_id => 'me' }))->TO_JSON,
    {
      valid => true,
      defaults => {
        '/response/header/header-array/0' => 0,
        '/response/header/header-array/1' => 1,
        '/response/header/header-object/a' => 'a_value',
        '/response/header/header-object/b' => 'b_value',
        '/response/body/content/body-array/0' => 0,
        '/response/body/content/body-array/1' => 1,
        '/response/body/content/body-object/a' => 'a_value',
        '/response/body/content/body-object/b' => 'b_value',
      },
    },
    'with empty parameters, media-type parameter and body defaults are included when with_defaults is set on the evaluator',
  );
  is_equal(
    $result->data,
    {
      response => {
        header => {
          'header-array' => [ 0, 1 ],
          'header-object' => { a => 'a_value', b => 'b_value' },
        },
        body => {
          content => {
            'body-array' => [ 0, 1 ],
            'body-object' => { a => 'a_value', b => 'b_value' },
          },
        },
      },
    },
    'media-type parameter and body data now includes defaults',
  );
};

if (++$type_index < @::TYPES) {
  bail_if_not_passing if $ENV{AUTHOR_TESTING};
  goto START;
}

done_testing;
