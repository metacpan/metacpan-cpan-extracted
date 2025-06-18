# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use 5.020;
use Test::More 0.88;
use Test::Warnings 0.033 qw(:no_end_test had_no_warnings allow_patterns);
use stable 0.031 'postderef';
use experimental 'signatures';
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8
use Test::Deep;
use Mojolicious::Plugin::OpenAPI::Modern;
use Path::Tiny;
use Test::Mojo;
use Test::Memory::Cycle;
use constant { true => JSON::PP::true, false => JSON::PP::false };
use JSON::Schema::Modern::Utilities 'jsonp';

# this comes from Test::Memory::Cycle, when looking at Mojo::Routes
allow_patterns(qr{^Unhandled type: REGEXP at .*/Devel/Cycle.pm});

use lib 't/lib';
use Helper;

my $openapi_preamble = {
  openapi => '3.1.0',
  info => {
    title => 'Test API with raw schema',
    version => '1.2.3',
  },
};

my $doc_uri_rel = Mojo::URL->new('/api');

subtest 'validate_request helper' => sub {
  my $t = Test::Mojo->new(
    'BasicApp',
    {
      openapi => {
        document_uri => $doc_uri_rel,
        schema => YAML::PP->new(boolean => 'JSON::PP')->load_string(<<'YAML')} });
openapi: 3.1.1
info:
  title: Test API with raw schema
  version: 1.2.3
components:
  responses:
    validation_response:
      description: capture validation result
      content:
        application/json:
          schema:
            additionalProperties: false
            properties:
              result:
                properties:
                  valid:
                    type: boolean
                  errors:
                    type: array
                    items:
                      type: object
paths:
  /foo/{foo_id}:
    parameters:
    - name: foo_id
      in: path
      required: true
      schema:
        type: string
        pattern: ^[a-z]+$
    post:
      operationId: operation_foo
      requestBody:
        content:
          text/plain:
            schema:
              type: string
              pattern: ^[a-z]+$
      responses:
        200:
          $ref: '#/components/responses/validation_response'
        400:
          $ref: '#/components/responses/validation_response'
        500:
          description: this response code is produced via ?status=500 in the request
          content:
            application/json:
              schema: false
  /skip_validate_request:
    get:
      operationId: operation_skip_validate_request
      responses:
        200:
          description: request not validated; response body not permitted
          content:
            text/plain:
              schema:
                false
YAML

  $t->post_ok('/foo/hi/there')
    ->status_is(400, 'path_template cannot be found')
    ->json_is({
      result => my $expected_result = {
        valid => false,
        errors => [
          {
            instanceLocation => '/request',
            keywordLocation => '/paths',
            absoluteKeywordLocation => $doc_uri_rel->clone->fragment('/paths')->to_string,
            error => 'no match found for request POST "/foo/hi/there"',
          },
        ],
      },
    });

  memory_cycle_ok($t->app);


  cmp_result(
    $BasicApp::LAST_VALIDATE_REQUEST_STASH,
    my $expected_stash = superhashof({
      method => 'post',
      request => isa('Mojo::Message::Request'),
    }),
    'stash is set in validate_request',
  );

  cmp_result(
    $BasicApp::LAST_VALIDATE_RESPONSE_STASH,
    $expected_stash,
    'stash is set in validate_response',
  );

  cmp_result(
    $BasicApp::LAST_VALIDATE_RESPONSE_RESULT->TO_JSON,
    $expected_result,
    'validate_response attempts to parse the request URI again, producing the same result',
  );


  $t->get_ok('/foo/hi')
    ->status_is(400, 'wrong HTTP method')
    ->json_is({
      result => $expected_result = {
        valid => false,
        errors => [
          {
            instanceLocation => '/request',
            keywordLocation => '/paths',
            absoluteKeywordLocation => $doc_uri_rel->clone->fragment('/paths')->to_string,
            error => 'no match found for request GET "/foo/hi"',
          },
        ],
      },
    });

  memory_cycle_ok($t->app);

  cmp_result(
    $BasicApp::LAST_VALIDATE_REQUEST_STASH,
    $expected_stash = superhashof({
      method => 'get',
      request => isa('Mojo::Message::Request'),
    }),
    'stash is set in validate_request',
  );

  cmp_result(
    $BasicApp::LAST_VALIDATE_RESPONSE_STASH,
    $expected_stash,
    'stash is set in validate_response',
  );

  cmp_result(
    $BasicApp::LAST_VALIDATE_RESPONSE_RESULT->TO_JSON,
    $expected_result,
    'validate_response attempts to parse the request URI again, producing the same result',
  );


  $t->post_ok('/foo/123')
    ->status_is(400, 'path parameter will fail validation')
    ->json_is({
      result => {
        valid => false,
        errors => [
          {
            instanceLocation => '/request/uri/path/foo_id',
            keywordLocation => jsonp(qw(/paths /foo/{foo_id} parameters 0 schema pattern)),
            absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} parameters 0 schema pattern))),
            error => 'pattern does not match',
          },
        ],
      },
    });

  memory_cycle_ok($t->app);

  cmp_result(
    $BasicApp::LAST_VALIDATE_REQUEST_STASH,
    $expected_stash = superhashof({
      method => 'post',
      operation_id => 'operation_foo',
      path_template => '/foo/{foo_id}',
      request => isa('Mojo::Message::Request'),
    }),
    'stash is set in validate_request',
  );

  cmp_result(
    $BasicApp::LAST_VALIDATE_RESPONSE_STASH,
    $expected_stash,
    'stash is set in validate_response',
  );

  cmp_result(
    $BasicApp::LAST_VALIDATE_RESPONSE_RESULT->TO_JSON,
    { valid => true },
    'validate_response ran successfully',
  );


  $t->post_ok('/foo/hi', { 'Content-Type' => 'text/plain' }, '123')
    ->status_is(400, 'valid path; body does not match')
    ->json_is({
      result => {
        valid => false,
        errors => [
          {
            instanceLocation => '/request/body',
            keywordLocation => jsonp(qw(/paths /foo/{foo_id} post requestBody content text/plain schema pattern)),
            absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post requestBody content text/plain schema pattern))),
            error => 'pattern does not match',
          },
        ],
      },
    });

  memory_cycle_ok($t->app);

  cmp_result(
    $BasicApp::LAST_VALIDATE_REQUEST_STASH,
    superhashof({
      method => 'post',
      operation_id => 'operation_foo',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'hi' },
      request => isa('Mojo::Message::Request'),
    }),
    'stash is set in validate_request',
  );

  $t->post_ok('/foo/hi?status=500', { 'Content-Type' => 'text/plain' }, 'hi')
    ->status_is(500, 'custom status code')
    ->json_is({
      result => { valid => true },
    });

  memory_cycle_ok($t->app);

  cmp_result(
    $BasicApp::LAST_VALIDATE_REQUEST_STASH,
    $expected_stash = superhashof({
      method => 'post',
      operation_id => 'operation_foo',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'hi' },
      request => isa('Mojo::Message::Request'),
    }),
    'stash is set in validate_request',
  );

  cmp_result(
    $BasicApp::LAST_VALIDATE_RESPONSE_STASH,
    $expected_stash,
    'stash is set in validate_response',
  );

  cmp_result(
    $BasicApp::LAST_VALIDATE_RESPONSE_RESULT->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} post responses 500 content application/json schema)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post responses 500 content application/json schema)))->to_string,
          error => 'response body not permitted',
        },
      ],
    },
    'validate_response does not like error responses',
  );


  $t->get_ok('/skip_validate_request')
    ->status_is(200)
    ->content_is('ok');

  memory_cycle_ok($t->app);

  cmp_result(
    $BasicApp::LAST_VALIDATE_REQUEST_STASH,
    undef,
    'stash was not set in validate_request',
  );

  cmp_result(
    $BasicApp::LAST_VALIDATE_RESPONSE_STASH,
    superhashof({
      method => 'get',
      operation_id => 'operation_skip_validate_request',
      path_template => '/skip_validate_request',
      path_captures => {},
    }),
    'stash is set in validate_response, even though validate_request never ran',
  );

  cmp_result(
    $BasicApp::LAST_VALIDATE_RESPONSE_RESULT->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /skip_validate_request get responses 200 content text/plain schema)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /skip_validate_request get responses 200 content text/plain schema)))->to_string,
          error => 'response body not permitted',
        },
      ],
    },
    'response from this endpoint never passes the specification',
  );
};

had_no_warnings() if $ENV{AUTHOR_TESTING};
done_testing;
