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

use JSON::Schema::Modern::Utilities 'jsonp';

use lib 't/lib';
use Helper;

my $doc_uri_rel = Mojo::URL->new('/api');
my $doc_uri = $doc_uri_rel->to_abs(Mojo::URL->new('http://example.com'));
my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

subtest 'missing or invalid arguments' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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

  cmp_result(
    $openapi->validate_response(bless({}, 'Bespoke::Response'), { operation_id => 'my_op' })->TO_JSON,
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

  cmp_result(
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

subtest $::TYPE.': validation errors in responses' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post: {}
YAML

  my $result = $openapi->validate_response(response(200), { operation_id => 'foo' });
  isa_ok($result, ['JSON::Schema::Modern::Result'], 'got a result object back');
  cmp_result(
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
    'match failure from find_path_item()',
  );

  if ($::TYPE eq 'lwp') {
    my $response = response(404);
    $response->request(request('GET', 'http://example.com/foo'));

    cmp_result(
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
    cmp_result(
      $openapi->validate_response($response)->TO_JSON,
      { valid => true },
      'operation is successfully found using the request on the response',
    );
  }
};

subtest $::TYPE.': validation errors in responses' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  pathItems:
    bar:
      post:
        operationId: bar_operation
paths:
  /foo:
    post:
      responses:
        200: {}
        2XX: {}
YAML

  cmp_result(
    $openapi->validate_response(response(404), { operation_id => 'bar_operation' })->TO_JSON,
    { valid => true },
    'no responses object - nothing to validate against',
  );

  cmp_result(
    $openapi->validate_response(response(404), { path_template => '/foo', method => 'POST' })->TO_JSON,
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
    $openapi->validate_response(response(200), { path_template => '/foo', method => 'POST' })->TO_JSON,
    { valid => true },
    'response code matched exactly',
  );

  cmp_result(
    $openapi->validate_response(response(202), { path_template => '/foo', method => 'POST' })->TO_JSON,
    { valid => true },
    'response code matched wildcard',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  responses:
    foo: {}
  headers:
    foo:
      schema: {}
paths:
  /foo:
    post:
      responses:
        200:
          $ref: '#/components/headers/foo'
YAML

  cmp_result(
    $openapi->validate_response(response(200), { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses 200 $ref)))->to_string,
          error => 'EXCEPTION: bad $ref to '.$doc_uri.'#/components/headers/foo: not a "response"',
        },
      ],
    },
    '$ref in responses points to the wrong type',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  responses:
    foo:
      $ref: '#/i_do_not_exist'
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

  cmp_result(
    $openapi->validate_response(response(303), { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => jsonp(qw(/paths /foo post responses 303 $ref $ref)),
          absoluteKeywordLocation => $doc_uri.'#/components/responses/foo/$ref',
          error => 'EXCEPTION: unable to find resource "'.$doc_uri.'#/i_do_not_exist"',
        },
      ],
    },
    'bad $ref in responses',
  );

  cmp_result(
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

  cmp_result(
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
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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
  cmp_result(
    $openapi->validate_response($response, { path_template => '/foo', method => 'GET' })->TO_JSON,
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


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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

  cmp_result(
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
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo get responses default $ref content text/* schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/components responses my_default content text/* schema maxLength)))->to_string,
          error => 'length is greater than 3',
        },
      ],
    },
    'Transfer-Encoding header is detected with status code '.$_.' (and body is still parseable)',
  )
  foreach 102, 204;

  cmp_result(
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
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo additionalOperations CONNECT responses default $ref content text/* schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/components responses my_default content text/* schema maxLength)))->to_string,
          error => 'length is greater than 3',
        },
      ],
    },
    'Transfer-Encoding header is detected in response to a CONNECT request (and body is still parseable)',
  );

  cmp_result(
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
          instanceLocation => '/response/body',
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
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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
  cmp_result(
    $openapi->validate_response(response(200), { path_template => '/foo', method => 'POST' })->TO_JSON,
    { valid => true },
    'missing Content-Type does not cause an exception',
  );

  $response = response(200, [ 'Content-Type' => 'application/json' ], 'null');
  remove_header($response, 'Content-Length');

  cmp_result(
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
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content application/json schema type)),
          absoluteKeywordLocation => $doc_uri.'#/components/responses/default/content/application~1json/schema/type',
          error => 'got null, not object',
        },
      ],
    },
    'missing Content-Length does not prevent the response body from being checked',
  );

  cmp_result(
    $openapi->validate_response(response(200, [ 'Content-Type' => 'text/bloop' ], 'plain text'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content)),
          absoluteKeywordLocation => $doc_uri.'#/components/responses/default/content',
          error => 'incorrect Content-Type "text/bloop"',
        },
      ],
    },
    'Content-Type not allowed by the schema',
  );

  cmp_result(
    $openapi->validate_response(response(200, [ 'Content-Type' => 'bloop/html' ], 'html text'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content bloop/html)),
          absoluteKeywordLocation => $doc_uri.'#/components/responses/default/content/bloop~1html',
          error => 'EXCEPTION: unsupported media type "bloop/html": add support with $openapi->add_media_type(...)',
        },
      ],
    },
    'unsupported Content-Type',
  );

  cmp_result(
    $openapi->validate_response(response(200, [ 'Content-Type' => 'text/plain; charset=ISO-8859-1' ],
        chr(0xe9).'clair'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    { valid => true },
    'latin1 content can be successfully decoded',
  );

  cmp_result(
    $openapi->validate_response(response(200, [ 'Content-Type' => 'application/json' ],
        '{"alpha": "foo", "gamma": "o.o"}'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body/alpha',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content application/json schema properties alpha pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/components responses default content application/json schema properties alpha pattern)))->to_string,
          error => 'pattern does not match',
        },
        {
          instanceLocation => '/response/body/gamma',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content application/json schema properties gamma const)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/components responses default content application/json schema properties gamma const)))->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses default $ref content application/json schema properties)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/components responses default content application/json schema properties)))->to_string,
          error => 'not all properties are valid',
        },
      ],
    },
    'decoded content does not match the schema',
  );


  my $disapprove = v224.178.160.95.224.178.160; # utf-8-encoded "ಠ_ಠ"
  cmp_result(
    $openapi->validate_response(response(200, [ 'Content-Type' => 'application/json' ],
        '{"alpha": "123", "gamma": "'.$disapprove.'"}'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    { valid => true },
    'decoded content matches the schema',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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

  cmp_result(
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

  cmp_result(
    $openapi->validate_response(
      response(400, [ 'Content-Length' => 12, 'Content-Type' => 'text/plain' ], ''), # Content-Length lies!
        { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses default content text/plain schema minLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses default content text/plain schema minLength)))->to_string,
          error => 'length is less than 10',
        },
      ],
    },
    'missing body (with a lying Content-Length) does not cause an exception, but is detectable',
  );

  cmp_result(
    $openapi->validate_response(
      response(400, [ 'Content-Type' => 'text/plain' ], '0'), { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
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

  cmp_result(
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
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses default content text/plain schema minLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses default content text/plain schema minLength)))->to_string,
          error => 'length is less than 10',
        },
      ],
    },
    'Content-Length is required in responses with a message body',
  );

  cmp_result(
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
          instanceLocation => '/response/body',
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
  if ($::TYPE eq 'mojo') {
  todo 'Mojolicious will strip Content-Length for 204 responses' => sub {
  cmp_result(
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
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses 204 content */* schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses 204 content */* schema)))->to_string,
          error => 'response body not permitted',
        },
      ],
    },
    'an undesired response body is detectable for 204 responses',
  );
  }}


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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

  cmp_result(
    $openapi->validate_response(
      response(400, [ 'Content-Length' => 1, 'Content-Type' => 'unknown/unknown' ], '!!!'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
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
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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

  cmp_result(
    $openapi->validate_response(
      response(200, [ 'Content-Type' => 'application/json' ], '{"foo":1}'),
      { path_template => '/foo', method => 'POST' })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body/foo',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 content application/json schema unevaluatedProperties)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses 200 content application/json schema unevaluatedProperties)))->to_string,
          error => 'additional property not permitted',
        },
        {
          instanceLocation => '/response/body',
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
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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

  cmp_result(
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
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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

  cmp_result(
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
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo post responses 200 content */* schema)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post responses 200 content */* schema)))->to_string,
          error => 'response body not permitted',
        },
      ],
    },
    'custom error message when the entity is not permitted',
  );
};

if (++$type_index < @::TYPES) {
  bail_if_not_passing if $ENV{AUTHOR_TESTING};
  goto START;
}

done_testing;
