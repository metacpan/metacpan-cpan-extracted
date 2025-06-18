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

use JSON::Schema::Modern::Utilities qw(jsonp get_type);

use lib 't/lib';
use Helper;

# the absolute uri we will see in errors
my $doc_uri_rel = Mojo::URL->new('/api.json');
my $doc_uri = $doc_uri_rel->to_abs(Mojo::URL->new('http://example.com'));
my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

subtest 'invalid request type, bad conversion to Mojo::Message::Request' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths: {}
YAML

  ok(!$openapi->find_path(my $options = { request => bless({}, 'Bespoke::Request') }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request',
          keywordLocation => '',
          absoluteKeywordLocation => $doc_uri->to_string,
          error => 'Failed to parse request: unknown type Bespoke::Request',
        }),
      ],
    },
    'invalid request object is detected early',
  );


  test_needs('HTTP::Request', 'URI');

  # start line is missing "HTTP/1.1"
  my $request = HTTP::Request->new(GET => 'http://example.com/', [ Host => 'example.com' ]);
  ok(!$openapi->find_path($options = { request => $request }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request',
          keywordLocation => '',
          absoluteKeywordLocation => $doc_uri->to_string,
          error => 'Failed to parse request: Bad request start-line',
        }),
      ],
    },
    'invalid request object is detected early',
  );
};

my $type_index = 0;
my $lots_of_options;  # populated lower down, and used in multiple subtests

START:
$::TYPE = $::TYPES[$type_index];
note 'REQUEST/RESPONSE TYPE: '.$::TYPE;

subtest $::TYPE.': request is parsed to get path information' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /bar:
    post: {}
  /blech/bar:
    post: {}
  /foo/bar:
    get:
      operationId: my-get-operation
    post:
      operationId: my-post-operation
  /foo/{foo_id}:
    post:
      operationId: another-post-operation
    delete:
      operationId: another-delete-operation
YAML

  my $request = request('GET', 'http://example.com/foo/bar');
  ok(!$openapi->find_path(my $options = { request => $request, path_template => '/blurp' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/blurp',
      method => 'get',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'missing path-item "/blurp"',
        }),
      ],
    },
    'provided path_template does not exist in /paths',
  );

  ok(!$openapi->find_path($options = { request => request('GET', 'http://example.com/foo/bar'),
      path_template => '/foo/baz' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/baz',
      method => 'get',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'missing path-item "/foo/baz"',
        }),
      ],
    },
    'provided path_template does not exist in /paths, even if request matches something else',
  );

  $request = request('GET', 'http://example.com/foo/bar');
  ok(!$openapi->find_path($options = { request => $request, operation_id => 'bloop' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      operation_id => 'bloop',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => '',
          absoluteKeywordLocation => $doc_uri->to_string,
          error => 'unknown operation_id "bloop"',
        }),
      ],
    },
    'operation_id does not exist',
  );

  ok(!$openapi->find_path($options = { request => request('PUT', 'http://example.com/foo/bloop') }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'put',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'no match found for request PUT "http://example.com/foo/bloop"',
        }),
      ],
    },
    'operation does not exist under /paths/<path_template>/<method>',
  );

  ok($openapi->find_path($options = { request => request('DELETE', 'http://example.com/foo/bar') }),
    to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'delete',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'bar' },
      uri_captures => { foo_id => 'bar' },
      _path_item => { post => ignore, delete => ignore },
      operation_id => 'another-delete-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} delete)))),
      errors => [],
    },
    'concrete path doesn\'t match where the method does not exist, but it does exist in another matching path lower down',
  );

  ok(!$openapi->find_path($options = { request => $request = request('PUT', 'http://example.com/blech/bar') }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'put',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'no match found for request PUT "http://example.com/blech/bar"',
        }),
      ],
    },
    'matching does not stop for a matching template when operation does not exist',
  );

  ok(!$openapi->find_path($options = { request => $request, path_template => '/blech/bar' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'put',
      path_template => '/blech/bar',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /blech/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /blech/bar)))->to_string,
          error => 'provided path_template does not match request URI "http://example.com/blech/bar"',
        }),
      ],
    },
    'path matching still fails on a suffix match when method is missing',
  );

  ok(!$openapi->find_path($options = { request => $request = request('POST', 'http://example.com/foo/bar'),
      path_template => '/foo/{foo_id}', operation_id => 'my-get-operation' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/{foo_id}',
      operation_id => 'my-get-operation',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => jsonp(qw(/paths /foo/bar get operationId)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar get operationId)))->to_string,
          error => 'operation at operation_id does not match provided path_template',
        }),
      ],
    },
    'path_template and operation_id are inconsistent',
  );

  ok(!$openapi->find_path($options = { request => $request, operation_id => 'my-get-operation' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/method',
          keywordLocation => jsonp(qw(/paths /foo/bar get operationId)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar get operationId)))->to_string,
          error => 'operation at operation_id does not match HTTP method "post"',
        }),
      ],
    },
    'request HTTP method does not match operation',
  );

  ok(!$openapi->find_path($options = { request => $request, method => 'GET' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'GET',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/method',
          keywordLocation => '',
          absoluteKeywordLocation => $doc_uri->to_string,
          error => 'wrong HTTP method "POST"',
        }),
      ],
    },
    'request HTTP method does not match method option',
  );

  ok($openapi->find_path($options = { request => $request, method => 'PoST' }),
    to_str($request).': find_path returns true');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'PoST',
      path_template => '/foo/bar',
      path_captures => {},
      uri_captures => {},
      _path_item => { get => ignore, post => ignore },
      operation_id => 'my-post-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar post)))),
      errors => [],
    },
    'method option is uppercased',
  );

  ok(!$openapi->find_path($options = { request => $request,
        path_template => '/foo/{foo_id}', path_captures => { bloop => 'bar' } }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/{foo_id}',
      path_captures => { bloop => 'bar' },
      _path_item => { post => ignore, delete => ignore },
      operation_id => 'another-post-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post)))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_captures names do not match path template "/foo/{foo_id}"',
        }),
      ],
    },
    'provided path template names do not match path capture names',
  );

  ok(!$openapi->find_path($options = { request => $request, path_captures => { bloop => 'bar' } }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/bar',
      path_captures => { bloop => 'bar' },
      _path_item => { get => ignore, post => ignore },
      operation_id => 'my-post-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar post)))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'provided path_captures names do not match path template "/foo/bar"',
        }),
      ],
    },
    'inferred path template does not match path captures',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://example.com/foo/bar'),
      path_template => '/foo/bar', method => 'get', operation_id => 'my-get-operation', path_captures => {} }),
    to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/bar',
      path_captures => {},
      uri_captures => {},
      operation_id => 'my-get-operation',
      _path_item => { get => ignore, post => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar get)))),
      errors => [],
    },
    'path_template, method, operation_id and path_captures can all be passed, if consistent',
  );

  ok(!$openapi->find_path($options = { request => request('GET', 'http://example.com/something/else'),
      path_template => '/foo/bar' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/bar',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'provided path_template does not match request URI "http://example.com/something/else"',
        }),
      ],
    },
    'concrete path_template does not match this request URI (no captures)',
  );

  ok(!$openapi->find_path($options = { request => $request = request('POST', 'http://example.com/something/else'),
      path_template => '/foo/{foo_id}', path_captures => { foo_id => 123 } }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 123 },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_template does not match request URI "http://example.com/something/else"',
        }),
      ],
    },
    'path_template with variables does not match this request URI (with captures)',
  );

  ok(!$openapi->find_path($options = { request => $request, path_template => '/foo/{foo_id}' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/{foo_id}',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_template does not match request URI "http://example.com/something/else"',
        }),
      ],
    },
    'path_template with variables does not match this request URI (no captures)',
  );

  ok(!$openapi->find_path($options = { request => request('GET', 'http://example.com/foo/123'), path_template => '/foo/bar' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/bar',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'provided path_template does not match request URI "http://example.com/foo/123"',
        }),
      ],
    },
    'a path matches this request URI, but not the path_template we provided',
  );

  ok(!$openapi->find_path($options = { request => request('POST', 'http://example.com/foo/123'), path_template => '/foo/bar', operation_id => 'another-post-operation' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/bar',
      operation_id => 'another-post-operation',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} post operationId)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post operationId)))->to_string,
          error => 'operation at operation_id does not match provided path_template',
        }),
      ],
    },
    'operation id matches URI, and a path matches this request URI, but not the path_template we provided',
  );

  ok(!$openapi->find_path($options = { request => request('GET', 'http://example.com/something/else'),
      operation_id => 'my-get-operation' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/bar get operationId)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar get operationId)))->to_string,
          error => 'provided operation_id does not match request GET http://example.com/something/else',
        }),
      ],
    },
    'operation_id is not consistent with request',
  );

  ok(!$openapi->find_path($options = { request => request('POST', 'http://example.com/foo/123'),
      operation_id => 'my-post-operation' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      # we should not bother to extract path_captures
      # operation_id does not match, so is deleted
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/bar post operationId)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar post operationId)))->to_string,
          error => 'provided operation_id does not match request POST http://example.com/foo/123',
        }),
      ],
    },
    'operation_id is not consistent with request URI, but the real operation does exist (with the same method)',
  );

  ok(!$openapi->find_path($options = { request => request('POST', 'http://example.com/foo/hello'),
      operation_id => 'another-post-operation', path_captures => { foo_id => 'goodbye' } }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/{foo_id}',
      method => 'post',
      path_captures => { foo_id => 'goodbye' },
      uri_captures => { foo_id => 'hello' },
      operation_id => 'another-post-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post)))),
      _path_item => { post => ignore, delete => ignore },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_captures values do not match request URI (value for foo_id differs)',
        }),
      ],
    },
    'path_captures values are not consistent with request URI',
  );

  ok($openapi->find_path($options = { request => request('POST', 'http://example.com/foo/123'),
      operation_id => 'another-post-operation', path_captures => { foo_id => 123 } }),
    to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_captures => { foo_id => 123 },
      uri_captures => { foo_id => 123 },
      path_template => '/foo/{foo_id}',
      _path_item => { post => ignore, delete => ignore },
      operation_id => 'another-post-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post)))),
      errors => [],
    },
    'path_capture values are returned as-is in the provided options hash',
  );
  is(get_type($options->{path_captures}{foo_id}), 'integer', 'passed-in path value is preserved as a number');

  ok($openapi->find_path($options = { request => request('POST', 'http://example.com/foo/123'),
      path_captures => { foo_id => 123 } }),
    to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_captures => { foo_id => 123 },
      uri_captures => { foo_id => 123 },
      path_template => '/foo/{foo_id}',
      _path_item => { post => ignore, delete => ignore },
      operation_id => 'another-post-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post)))),
      errors => [],
    },
    'path_capture values are returned as-is in the provided options hash',
  );
  is(get_type($options->{path_captures}{foo_id}), 'integer', 'passed-in path value is preserved as a number');

  ok($openapi->find_path($options = { request => $request = request('POST', 'http://example.com/foo/bar'),
      path_template => '/foo/{foo_id}' }),
    to_str($request).': find_path returns true');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'bar' },
      uri_captures => { foo_id => 'bar' },
      method => 'post',
      _path_item => { post => { operationId => 'another-post-operation' }, delete => ignore },
      operation_id => 'another-post-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post)))),
      errors => [],
    },
    'can force a lower-priority path-item to match by explicitly passing path_template',
  );

  ok($openapi->find_path($options = { request => $request, operation_id => 'another-post-operation' }),
    to_str($request).': find_path returns true');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'bar' },
      uri_captures => { foo_id => 'bar' },
      method => 'post',
      _path_item => { post => { operationId => 'another-post-operation' }, delete => ignore },
      operation_id => 'another-post-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post)))),
      errors => [],
    },
    'can force a lower-priority path-item to match by explicitly passing operation_id',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{foo_id}:
    get:
      operationId: my-get-operation
YAML

  ok(!$openapi->find_path($options = { request => request('POST', 'http://example.com/foo/blah'),
      path_template => '/foo/{foo_id}', path_captures => { foo_id => 'blah' } }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'blah' },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_template does not match request URI "http://example.com/foo/blah"',
        }),
      ],
    },
    'operation does not exist under /paths/<path-template>',
  );

  ok($openapi->find_path($options = { request => $request = request('GET', 'http://example.com/foo/123') }),
    to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    my $expected = {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => '123' },
      uri_captures => { foo_id => '123' },
      method => 'get',
      operation_id => 'my-get-operation',
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))),
      errors => [],
    },
    'path_capture values are parsed from the request uri and returned in the provided options hash',
  );
  is(get_type($options->{path_captures}{foo_id}), 'string', 'captured path value is parsed as a string');

  ok($openapi->find_path($options = { request => $request, path_captures => { foo_id => '123' } }),
    to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    $expected,
    'path_capture values are returned as-is in the provided options hash',
  );
  is(get_type($options->{path_captures}{foo_id}), 'string', 'passed-in path value is preserved as a string');

  ok($openapi->find_path($options = { request => $request, path_template => '/foo/{foo_id}', path_captures => { foo_id => 123 } }),
    to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    $expected,
    'path_capture values are returned as-is in the provided options hash',
  );
  is(get_type($options->{path_captures}{foo_id}), 'integer', 'passed-in path value is preserved as a number');

  my $val = 123; my $str = sprintf("%s\n", $val);
  ok($openapi->find_path($options = { request => $request, path_captures => { foo_id => $val } }),
    to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    $expected,
    'path_capture values are returned as-is (even ambiguous type) in the provided options hash',
  );
  ok(Scalar::Util::isdual($options->{path_captures}{foo_id}), 'passed-in path value is preserved as a dualvar');

  ok(!$openapi->find_path($options = { request => $request, path_captures => { foo_id => 'a' } }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'a' },
      uri_captures => { foo_id => 123 },
      _path_item => { get => ignore },
      operation_id => 'my-get-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_captures values do not match request URI (value for foo_id differs)',
        }),
      ],
    },
    'request URI is inconsistent with provided path captures',
  );

  $OpenAPI::Modern::DEBUG = 1;
  ok(!$openapi->find_path($options = { request => request('GET', 'http://example.com/bloop/blah') }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'no match found for request GET "http://example.com/bloop/blah"',
        }),
      ],
      debug => { uri_patterns => [ '\/foo\/([^/?#]*)$' ] },
    },
    'no match for URI against /paths',
  );
  $OpenAPI::Modern::DEBUG = 0;

  my $uri = uri('http://example.com', '', 'foo', 'hello // there ಠ_ಠ!');
  ok($openapi->find_path($options = { request => request('GET', $uri),
      path_template => '/foo/{foo_id}', path_captures => { foo_id => 'hello // there ಠ_ಠ!' } }),
    to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    $expected = {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'hello // there ಠ_ಠ!' },
      uri_captures => { foo_id => 'hello // there ಠ_ಠ!' },
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))),
      operation_id => 'my-get-operation',
      errors => [],
    },
    'path_capture values are found to be consistent with the URI when some values are url-escaped',
  );

  ok($openapi->find_path($options = { request => request('GET', $uri) }), to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    $expected,
    'path captures can be properly derived from the URI when some values are url-escaped',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo.bar: # dot sorts higher than /, so this will match if we are sloppy with regexes
    get:
      operationId: dotted-foo-bar
  /foo/bar:
    get:
      operationId: concrete-foo-bar
  /foo/{foo_id}.bar:
    get:
      operationId: templated-foo-bar
  /foo/.....:
    get:
      operationId: all-dots
YAML

  $request = request('GET', 'http://example.com/foo/bar');
  ok($openapi->find_path($options = { request => $request }), to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    $expected = {
      request => isa('Mojo::Message::Request'),
      path_captures => {},
      uri_captures => {},
      path_template => '/foo/bar',
      method => 'get',
      operation_id => 'concrete-foo-bar',
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar get)))),
      errors => [],
    },
    'paths with dots are not treated as regex wildcards when matching against URIs',
  );

  ok(!$openapi->find_path($options = { request => $request, operation_id => 'dotted-foo-bar' }), 'find_path fails');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo.bar get operationId)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo.bar get operationId)))->to_string,
          error => 'provided operation_id does not match request GET http://example.com/foo/bar',
        }),
      ],
    },
    'provided operation_id and inferred path_template does not match request',
  );

  ok($openapi->find_path($options = { request => $request, operation_id => 'concrete-foo-bar' }), to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    $expected,
    'inferred (correct) path_template matches request uri',
  );

  $request = request('GET', 'http://example.com/foo/x.bar');
  ok($openapi->find_path($options = { request => $request }), to_str($request).': find_path returns successfully');
  cmp_result(
    my $got_options = $options,
    {
      request => isa('Mojo::Message::Request'),
      path_captures => { foo_id => 'x' },
      uri_captures => { foo_id => 'x' },
      path_template => '/foo/{foo_id}.bar',
      operation_id => 'templated-foo-bar',
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id}.bar get)))),
      errors => [],
    },
    'capture values are still captured when using dots in path template',
  );

  ok(!$openapi->find_path($options = { request => $request, operation_id => 'all-dots' }), 'find_path fails');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/..... get operationId)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/..... get operationId)))->to_string,
          error => 'provided operation_id does not match request GET http://example.com/foo/x.bar',
        }),
      ],
    },
    'provided operation_id and inferred path_template does not match request',
  );

  ok($openapi->find_path($options = { request => $request, operation_id => 'templated-foo-bar' }), to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    { %$got_options, request => isa('Mojo::Message::Request'), operation_uri => str($got_options->{operation_uri}) },
    'inferred (correct) path_template matches request uri',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{foo_id}:
    get: {}
YAML

  $request = request('GET', 'http://example.com/foo/bar');
  ok($openapi->find_path($options = { request => $request }), to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'bar' },
      uri_captures => { foo_id => 'bar' },
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))),
      errors => [],
    },
    'no path_template provided, but is inferred; no operation_id is recorded, because one does not exist in the schema document',
  );

  ok($openapi->find_path($options = { request => $request, path_template => '/foo/{foo_id}' }),
    to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'bar' },
      uri_captures => { foo_id => 'bar' },
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))),
      errors => [],
    },
    'path_template provided; no operation_id is recorded, because one does not exist in the schema document',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /:
    get: {}
YAML

  $request = request('GET', 'http://example.com');
  ok($openapi->find_path($options = { request => $request }), 'find_path can match an empty uri path');
  cmp_result(
    $options,
    $expected = {
      request => isa('Mojo::Message::Request'),
      path_template => '/',
      path_captures => {},
      uri_captures => {},
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths / get)))),
      errors => [],
    },
    'path_template inferred from request uri; empty path maps to /',
  );

  ok($openapi->find_path($options = { request => $request, path_template => '/' }),
   'find_path can match an empty uri path when passed path_template');
  cmp_result(
    $options,
    $expected,
    'provided path_template verified against request uri',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $lots_of_options = $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  pathItems:
    my_path_item:
      description: good luck finding a path_template
      post:
        operationId: my_components_pathItem_operation
        callbacks:
          my_callback:
            '{$request.query.queryUrl}': # note this is a path-item
              post:
                operationId: my_components_pathItem_callback_operation
    my_path_item2:
      description: this should be useable, as it is $ref'd by a /paths/<template> path item
      post:
        operationId: my_reffed_component_operation
paths:
  /foo:
    $ref: '#/components/pathItems/my_path_item2'
  /foo/bar:
    post:
      callbacks:
        my_callback:
          '{$request.query.queryUrl}': # note this is a path-item
            post:
              operationId: my_paths_pathItem_callback_operation
webhooks:
  my_hook:  # note this is a path-item
    description: good luck here too
    post:
      operationId: my_webhook_operation
YAML

  $request = request('POST', 'http://example.com/foo/bar');
  ok(!$openapi->find_path($options = { request => $request, operation_id => 'my_components_pathItem_operation' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/bar',
      _path_item => { post => ignore },
      method => 'post',
      operation_id => 'my_components_pathItem_operation',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'templated operation does not match provided operation_id',
        }),
      ],
    },
    'operation is not under a path-item with a path template',
  );

  ok(!$openapi->find_path($options = { request => $request, path_template => '/foo/bar', operation_id => 'my_components_pathItem_operation' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/bar',
      _path_item => { post => ignore },
      method => 'post',
      operation_id => 'my_components_pathItem_operation',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'templated operation does not match provided operation_id',
        }),
      ],
    },
    'this operation cannot be reached by using this path template',
  );

  # TODO: no way at present to match a webhook request to its path-item (and OpenAPI 3.1 does not
  # provide for specifying a path_template for webhooks)
  ok(!$openapi->find_path($options = { request => $request, operation_id => 'my_webhook_operation' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/bar',
      _path_item => { post => ignore },
      operation_id => 'my_webhook_operation',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'templated operation does not match provided operation_id',
        }),
      ],
    },
    'operation is not under a path-item with a path template',
  );

  # TODO: no way at present to match a callback request to its path-item embedded under the
  # operation, rather than to the top level /paths/*
  ok(!$openapi->find_path($options = { request => $request, operation_id => 'my_paths_pathItem_callback_operation' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/bar',
      _path_item => { post => ignore },
      operation_id => 'my_paths_pathItem_callback_operation',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'templated operation does not match provided operation_id',
        }),
      ],
    },
    'operation is not directly under a path-item with a path template',
  );

  ok(!$openapi->find_path($options = { request => $request, operation_id => 'my_components_pathItem_callback_operation' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/bar',
      _path_item => { post => ignore },
      operation_id => 'my_components_pathItem_callback_operation',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'templated operation does not match provided operation_id',
        }),
      ],
    },
    'operation is not under a path-item with a path template',
  );

  $request = request('POST', 'http://example.com/foo');

  ok($openapi->find_path($options = { request => $request }), to_str($request).': find_path succeeded');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      operation_id => 'my_reffed_component_operation',
      path_captures => {},
      uri_captures => {},
      path_template => '/foo',
      method => 'post',
      _path_item => { description => ignore, post => { operationId => 'my_reffed_component_operation' }},
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/my_path_item2/post')),
      errors => [],
    },
    'found path-item on the far side of a $ref using the request uri',
  );

  ok($openapi->find_path($options = { request => $request, operation_id => 'my_reffed_component_operation' }), to_str($request).': find_path succeeded');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      operation_id => 'my_reffed_component_operation',
      path_captures => {},
      uri_captures => {},
      path_template => '/foo',
      method => 'post',
      _path_item => { description => ignore, post => { operationId => 'my_reffed_component_operation' }},
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/my_path_item2/post')),
      errors => [],
    },
    'found path-item on the far side of a $ref using an operationId, and verified against the request uri',
  );

  ok($openapi->find_path($options = { request => $request, path_template => '/foo' }), to_str($request).': find_path succeeded');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      operation_id => 'my_reffed_component_operation',
      path_captures => {},
      uri_captures => {},
      path_template => '/foo',
      method => 'post',
      _path_item => { description => ignore, post => { operationId => 'my_reffed_component_operation' }},
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/my_path_item2/post')),
      errors => [],
    },
    'found path-item and method on the far side of a $ref using path_template, and verified against the request uri',
  );

  ok($openapi->find_path($options = { request => $request, path_template => '/foo', operation_id => 'my_reffed_component_operation' }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      _path_item => { description => ignore, post => { operationId => 'my_reffed_component_operation' }},
      path_template => '/foo',
      path_captures => {},
      uri_captures => {},
      method => 'post',
      operation_id => 'my_reffed_component_operation',
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/my_path_item2/post')),
      errors => [],
    },
    'can find a path-item by operation_id, and then verify the provided path_template against the request despite there being a $ref in the way',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  pathItems:
    bar:
      post: {}
    foo-bar:
      get: {}
paths:
  /bar:
    $ref: '#/components/pathItems/bar'
  /foo/bar:
    $ref: '#/components/pathItems/foo-bar'
YAML

  ok(!$openapi->find_path($options = { request => $request = request('POST', 'http://example.com/blech/bar' ) }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'no match found for request POST "http://example.com/blech/bar"',
        }),
      ],
    },
    'error locations are correct after multiple unanchored matches of uri against paths',
  );

  ok(!$openapi->find_path($options = { request => $request, path_template => '/bar' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/bar',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /bar)))->to_string,
          error => 'provided path_template does not match request URI "http://example.com/blech/bar"',
        }),
      ],
    },
    'error locations are correct after a single unanchored match of uri against paths',
  );

  ok(!$openapi->find_path($options = { request => $request = request('POST', 'http://example.com/foo/bar' ) }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'no match found for request POST "http://example.com/foo/bar"',
        }),
      ],
    },
    'error locations are correct after multiple unanchored matches of uri against paths, with bad method',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  pathItems:
    foo-fooid:
      get:
        servers:
          - url: http://dev.example.com
          - url: http://dev.example.com/subdir
          - url: http://{host}.example2.com
            variables:
              host:
                default: prod
                enum: [dev, stg, prod]
    bar-barid:
      servers:
        - url: http://stg.example.com
        - url: http://stg.example.com/subdir
        - url: http://{host}.example2.com
          variables:
            host:
              default: prod
              enum: [dev, stg, prod]
      get: {}
      post:
        servers: []   # overrides the entry at the path-item level, defaulting to [{url=>'/'}]
    qux-quxid:
      get: {}
    bad-host:
      get:
        servers:
          - url: http://{host}.example2.com
            variables:
              host:
                default: boo
      post: {}
      servers:
        - url: http://{host}.example2.com
          variables:
            host:
              default: boo
    worse-host:
      get: {}
servers:
  - url: http://prod.example.com
  - url: http://prod.example.com/subdir
  - url: /subdir
  - url: http://{host}.example2.com
    variables:
      host:
        default: prod
        enum: [dev, stg, prod]
paths:
  /subdir-operation:
    get:
      servers:
        - url: /subdir
  /subdir-path-item:
    get: {}
    servers:
      - url: /subdir
  /subdir-global:
    get: {}
  /foo/{foo_id}:
    $ref: '#/components/pathItems/foo-fooid'    # servers at operation level
  /bar/{bar_id}:
    $ref: '#/components/pathItems/bar-barid'    # servers at path-item level
  /qux/{qux_id}:
    $ref: '#/components/pathItems/qux-quxid'    # no custom servers; fall back to global
  /bad/{host}:
    $ref: '#/components/pathItems/bad-host'
  /worse/{host}:
    $ref: '#/components/pathItems/worse-host'
YAML

  ok(!$openapi->find_path($options = { request => request('GET', 'http://bloop.example.com/foo?x=1') }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'no match found for request GET "http://bloop.example.com/foo"',
        }),
      ],
    },
    'matching path_template but not any server urls is a match failure',
  );

  local $OpenAPI::Modern::DEBUG = 1;
  ok($openapi->find_path($options = { request => request('GET', 'http://dev.example.com/foo/1?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 1 },
      uri_captures => { foo_id => 1 },
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/foo-fooid/get')),
      errors => [],
      debug => { uri_patterns => [
          '\/bad\/([^/?#]*)$',
          '\/bar\/([^/?#]*)$',
          '\/foo\/([^/?#]*)$',
          '^http\:\/\/dev\.example\.com\/foo\/([^/?#]*)$',
        ] },
    },
    'with the correct host, the uri matches on a server url from operation + path_template',
  );
  local $OpenAPI::Modern::DEBUG = 0;

  ok($openapi->find_path($options = { request => request('GET', 'http://stg.example.com/bar/1?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/bar/{bar_id}',
      path_captures => { bar_id => 1 },
      uri_captures => { bar_id => 1 },
      _path_item => { get => ignore, post => ignore, servers => ignore },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/bar-barid/get')),
      errors => [],
    },
    'with the correct host, the uri matches on a server url from path-item + path_template',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://prod.example.com/qux/1?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/qux/{qux_id}',
      path_captures => { qux_id => 1 },
      uri_captures => { qux_id => 1 },
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/qux-quxid/get')),
      errors => [],
    },
    'with the correct host, the uri matches on a server url from global servers + path_template',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://dev.example.com/subdir/foo/1?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 1 },
      uri_captures => { foo_id => 1 },
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/foo-fooid/get')),
      errors => [],
    },
    'the uri can match on a server url with a path prefix, even when another match comes first, servers at operation level',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://stg.example.com/subdir/bar/1?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/bar/{bar_id}',
      path_captures => { bar_id => 1 },
      uri_captures => { bar_id => 1 },
      _path_item => { get => ignore, post => ignore, servers => ignore },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/bar-barid/get')),
      errors => [],
    },
    'the uri can match on a server url with a path prefix, even when another match comes first, servers at path-item level',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://prod.example.com/subdir/qux/1?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/qux/{qux_id}',
      path_captures => { qux_id => 1 },
      uri_captures => { qux_id => 1 },
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/qux-quxid/get')),
      errors => [],
    },
    'the uri can match on a server url with a path prefix, even when another match comes first, servers at global level',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://example.com/subdir/subdir-operation?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/subdir-operation',
      path_captures => {},
      uri_captures => {},
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /subdir-operation get)))),
      errors => [],
    },
    'a relative server url is resolved against the absolute retrieval uri to match the request, with servers at operation level',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://example.com/subdir/subdir-path-item?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/subdir-path-item',
      path_captures => {},
      uri_captures => {},
      _path_item => { get => ignore, servers => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /subdir-path-item get)))),
      errors => [],
    },
    'a relative server url is resolved against the absolute retrieval uri to match the request, with servers at path-item level',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://example.com/subdir/subdir-global?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/subdir-global',
      path_captures => {},
      uri_captures => {},
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /subdir-global get)))),
      errors => [],
    },
    'a relative server url is resolved against the absolute retrieval uri to match the request, with servers at global level',
  );

  ok(!$openapi->find_path($options = { request => request('GET', 'http://operation.example2.com/bad/bar') }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/bad/{host}',
      _path_item => { get => ignore, post => ignore, servers => ignore },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /bad/{host} $ref get servers 0 url)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/pathItems/bad-host/get/servers/0/url')->to_string,
          error => 'duplicate template name "host" in server url and path template',
        }),
      ],
    },
    'cannot reuse a template name between a server url and the path template, with operation level servers',
  );

  ok(!$openapi->find_path($options = { request => request('POST', 'http://path-item.example2.com/bad/bar') }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/bad/{host}',
      _path_item => { get => ignore, post => ignore, servers => ignore },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /bad/{host} $ref servers 0 url)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/pathItems/bad-host/servers/0/url')->to_string,
          error => 'duplicate template name "host" in server url and path template',
        }),
      ],
    },
    'cannot reuse a template name between a server url and the path template, with path-item level servers',
  );

  ok(!$openapi->find_path($options = { request => request('GET', 'http://global.example2.com/worse/bar') }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/worse/{host}',
      _path_item => { get => ignore },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /worse/{host} $ref servers 3 url)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/servers/3/url')->to_string,
          error => 'duplicate template name "host" in server url and path template',
        }),
      ],
    },
    'cannot reuse a template name between a server url and the path template, with global servers',
  );

  ok(!$openapi->find_path($options = { request => request('GET', 'http://zip.example2.com/foo/1') }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/{foo_id}',
      _path_item => { get => ignore },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} $ref get servers 2 variables host enum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/pathItems/foo-fooid/get/servers/2/variables/host/enum')->to_string,
          error => 'server url value does not match any of the allowed values',
        }),
      ],
    },
    'server url templated value must match the enum specification; error from servers at operation',
  );

  ok(!$openapi->find_path($options = { request => request('GET', 'http://zip.example2.com/bar/1') }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/bar/{bar_id}',
      _path_item => { get => ignore, post => ignore, servers => ignore },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /bar/{bar_id} $ref servers 2 variables host enum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/pathItems/bar-barid/servers/2/variables/host/enum')->to_string,
          error => 'server url value does not match any of the allowed values',
        }),
      ],
    },
    'server url templated value must match the enum specification; error from servers at path-item',
  );

  ok(!$openapi->find_path($options = { request => request('GET', 'http://zip.example2.com/qux/1') }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/qux/{qux_id}',
      _path_item => { get => ignore },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /qux/{qux_id} $ref servers 3 variables host enum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/servers/3/variables/host/enum')->to_string,
          error => 'server url value does not match any of the allowed values',
        }),
      ],
    },
    'server url templated value must match the enum specification; error from servers at global level',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://dev.example2.com/foo/1?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 1 },
      uri_captures => { host => 'dev', foo_id => 1 },
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/foo-fooid/get')),
      errors => [],
    },
    'the uri matches on a templated server url from operation + path_template',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://stg.example2.com/bar/1?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/bar/{bar_id}',
      path_captures => { bar_id => 1 },
      uri_captures => { host => 'stg', bar_id => 1 },
      _path_item => { get => ignore, post => ignore, servers => ignore },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/bar-barid/get')),
      errors => [],
    },
    'the uri matches on a templated server url from path-item + path_template',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://prod.example2.com/qux/1?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/qux/{qux_id}',
      path_captures => { qux_id => 1 },
      uri_captures => { host => 'prod', qux_id => 1 },
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/qux-quxid/get')),
      errors => [],
    },
    'the uri matches on a templated server url from global servers + path_template',
  );

  ok($openapi->find_path($options = { request => request('POST', 'http://example.com/bar/1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/bar/{bar_id}',
      path_captures => { bar_id => 1 },
      uri_captures => { bar_id => 1 },
      _path_item => { get => ignore, post => ignore, servers => ignore },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/bar-barid/post')),
      errors => [],
    },
    'operation-level servers object overrides one at path-item; because it is empty the default is used (which resolves to the retrieval uri)',
  );

  ok(!$openapi->find_path($options = { request => request('GET', 'http://dev.example2.com/foo/1?x=1'),
        uri_captures => { not_host => 'dev', foo_id => 1 } }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/{foo_id}',
      _path_item => { get => ignore },
      uri_captures => { not_host => 'dev', foo_id => 1 },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/foo-fooid/get')),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/pathItems/foo-fooid')->to_string,
          error => 'provided uri_captures names do not match extracted values',
        }),
      ],
    },
    'uri_captures names are not correct',
  );

  ok(!$openapi->find_path($options = { request => request('GET', 'http://dev.example2.com/foo/1?x=1'),
      uri_captures => { host => 'not_dev', foo_id => 1 } }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/{foo_id}',
      _path_item => { get => ignore },
      uri_captures => { host => 'not_dev', foo_id => 1 },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/foo-fooid/get')),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/pathItems/foo-fooid')->to_string,
          error => 'provided uri_captures values do not match request URI (value for host differs)'
        }),
      ],
    },
    'uri_captures values are not correct',
  );

  ok(!$openapi->find_path($options = { request => request('GET', 'http://dev.example2.com/foo/1?x=1'),
      uri_captures => { host => 'dev', foo_id => 1 }, path_captures => { foo_id => 2 } }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/{foo_id}',
      _path_item => { get => ignore },
      uri_captures => { host => 'dev', foo_id => 1 },
      path_captures => { foo_id => 2 },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/foo-fooid/get')),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/pathItems/foo-fooid')->to_string,
          error => 'provided path_captures values do not match request URI (value for foo_id differs)'
        }),
      ],
    },
    'path_captures values are inconsistent with uri_captures values',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://dev.example2.com/foo/1?x=1'),
      uri_captures => { host => 'dev', foo_id => 1 }, path_captures => { foo_id => 1 } }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/{foo_id}',
      _path_item => { get => ignore },
      uri_captures => { host => 'dev', foo_id => 1 },
      path_captures => { foo_id => 1 },
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/foo-fooid/get')),
      errors => [],
    },
    'path_captures and uri_captures are consistent',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  pathItems:
    foo:
      get:
        servers:
          - url: /subdir
    bar:
      get: {}
      servers:
        - url: /subdir
    baz:
      get: {}
paths:
  /foo:
    $ref: '#/components/pathItems/foo'
  /bar:
    $ref: '#/components/pathItems/bar'
  /baz:
    $ref: '#/components/pathItems/baz'
servers:
  - url: /subdir
YAML

  ok($openapi->find_path($options = { request => request('GET', 'http://example.com/subdir/foo?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo',
      path_captures => {},
      uri_captures => {},
      _path_item => { get => ignore },
      operation_uri => str($doc_uri_rel->clone->fragment('/components/pathItems/foo/get')),
      errors => [],
    },
    'a relative server url is resolved against the relative retrieval uri to match the request, with servers at the operation level',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://example.com/subdir/bar?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/bar',
      path_captures => {},
      uri_captures => {},
      _path_item => { get => ignore, servers => ignore },
      operation_uri => str($doc_uri_rel->clone->fragment('/components/pathItems/bar/get')),
      errors => [],
    },
    'a relative server url is resolved against the relative retrieval uri to match the request, with servers at the path-item level',
  );

  ok($openapi->find_path($options = { request => request('GET', 'http://example.com/subdir/baz?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/baz',
      path_captures => {},
      uri_captures => {},
      _path_item => { get => ignore },
      operation_uri => str($doc_uri_rel->clone->fragment('/components/pathItems/baz/get')),
      errors => [],
    },
    'a relative server url is resolved against the relative retrieval uri to match the request, with servers at the global level',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get: {}
YAML

  ok($openapi->find_path($options = { request => request('GET', 'http://example.com:'.int(300+int(rand(1000))).'/foo?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo',
      path_captures => {},
      uri_captures => {},
      _path_item => { get => ignore },
      operation_uri => str($doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo get)))),
      errors => [],
    },
    'the default (relative) server url is resolved against the relative retrieval uri to match the request; request has a custom and unpredictable port',
  );

  ok($openapi->find_path($options = { request => request('GET', '/foo?x=1') }),
    to_str($request).': find_path returns success');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo',
      path_captures => {},
      uri_captures => {},
      _path_item => { get => ignore },
      operation_uri => str($doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo get)))),
      errors => [],
    },
    'a relative server url is resolved against the relative retrieval uri to match the request; request has no host or scheme',
  );
};

subtest $::TYPE.': no request is provided: options are relied on as the sole source of truth' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  pathItems:
    my_path_item:
      post:
        operationId: my_reffed_component_operation
paths:
  /foo:
    $ref: '#/components/pathItems/my_path_item'
  /foo/{foo_id}:
    get:
      operationId: my-get-operation
YAML

  ok(!$openapi->find_path(my $options = { path_template => '/foo/{foo_id}' }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      path_template => '/foo/{foo_id}',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => '',
          absoluteKeywordLocation => $doc_uri->to_string,
          error => 'at least one of $options->{request}, ($options->{path_template} and $options->{method}), or $options->{operation_id} must be provided',
        }),
      ],
    },
    'method can only be derived from request or operation_id',
  );

  ok(!$openapi->find_path($options = { path_captures => {} }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      path_captures => {},
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => '',
          absoluteKeywordLocation => $doc_uri->to_string,
          error => 'at least one of $options->{request}, ($options->{path_template} and $options->{method}), or $options->{operation_id} must be provided',
        }),
      ],
    },
    'method can only be derived from request or operation_id',
  );

  ok(!$openapi->find_path($options = { operation_id => 'my-get-operation', method => 'POST' }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      method => 'POST',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} get operationId)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get operationId)))->to_string,
          error => 'operation at operation_id does not match HTTP method "POST"',
        }),
      ],
    },
    'no request provided; operation method does not match passed-in method',
  );

  ok(!$openapi->find_path($options = { method => 'get' }), 'find_path returns false');
  cmp_result(
    $options,
    {
      method => 'get',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => '',
          absoluteKeywordLocation => $doc_uri->to_string,
          error => 'at least one of $options->{request}, ($options->{path_template} and $options->{method}), or $options->{operation_id} must be provided',
        }),
      ],
    },
    'path_template can only be derived from request or operation_id',
  );

  ok(!$openapi->find_path($options = {}), 'find_path returns false');
  cmp_result(
    $options,
    {
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => '',
          absoluteKeywordLocation => $doc_uri->to_string,
          error => 'at least one of $options->{request}, ($options->{path_template} and $options->{method}), or $options->{operation_id} must be provided',
        }),
      ],
    },
    'cannot do any lookup when provided no options',
  );

  ok(!$openapi->find_path($options = { path_template => '/blurp', method => 'get' }), 'find_path failed');
  cmp_result(
    $options,
    {
      path_template => '/blurp',
      method => 'get',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'missing path-item "/blurp"',
        }),
      ],
    },
    'no request provided; path template cannot be found under /paths',
  );

  ok(!$openapi->find_path($options = { path_template => '/foo/{foo_id}', path_captures => {}, method => 'get' }), 'find_path failed');
  cmp_result(
    $options,
    {
      path_template => '/foo/{foo_id}',
      path_captures => {},
      method => 'get',
      _path_item => { get => ignore },
      operation_id => 'my-get-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_captures names do not match path template "/foo/{foo_id}"',
        }),
      ],
    },
    'no request provided; path template does not match path captures',
  );

  ok($openapi->find_path($options = { operation_id => 'my-get-operation', path_captures => { foo_id => 'a' } }), 'find_path succeeded');
  cmp_result(
    $options,
    {
      operation_id => 'my-get-operation',
      path_captures => { foo_id => 'a' },
      path_template => '/foo/{foo_id}',
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))),
      errors => [],
    },
    'no request provided; path_captures and method are derived from operation_id',
  );

  ok($openapi->find_path($options = { method => 'get', path_template => '/foo/{foo_id}', path_captures => { foo_id => 'a' } }), 'find_path succeeded');
  cmp_result(
    $options,
    {
      operation_id => 'my-get-operation',
      path_captures => { foo_id => 'a' },
      path_template => '/foo/{foo_id}',
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))),
      errors => [],
    },
    'no request provided; operation_id is derived from method and path_template',
  );

  ok($openapi->find_path($options = { method => 'get', path_template => '/foo/{foo_id}' }), 'find_path succeeded');
  cmp_result(
    $options,
    {
      operation_id => 'my-get-operation',
      path_template => '/foo/{foo_id}',
      # note: no path_captures
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))),
      errors => [],
    },
    'no request provided; path_captures is not required for verification',
  );

  ok(!$openapi->find_path($options = { path_template => '/foo/{foo_id}', method => 'post' }), 'find_path failed');
  cmp_result(
    $options,
    {
      path_template => '/foo/{foo_id}',
      method => 'post',
      _path_item => { get => ignore },
      errors => [ methods(
        TO_JSON => {
          instanceLocation => '/request/method',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'missing operation for HTTP method "POST" under "/foo/{foo_id}"',
        },
        recommended_response => [ 405, 'Method Not Allowed' ],
      )],
    },
    'no request provided; operation does not exist for path-item',
  );

  ok($openapi->find_path($options = { operation_id => 'my-get-operation' }), 'find_path succeeds');
  cmp_result(
    $options,
    {
      operation_id => 'my-get-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))),
      _path_item => { get => ignore },
      # note: no path_captures
      path_template => '/foo/{foo_id}',
      method => 'get',
      errors => [],
    },
    'method and path_item are derived from operation_id; path_captures cannot be determined without request',
  );

  ok(!$openapi->find_path($options = { operation_id => 'bloop' }), 'find_path returns false');
  cmp_result(
    $options,
    {
      operation_id => 'bloop',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => '',
          absoluteKeywordLocation => $doc_uri->to_string,
          error => 'unknown operation_id "bloop"',
        }),
      ],
    },
    'operation id does not exist',
  );

  ok(!$openapi->find_path($options = { path_template => '/foo', operation_id => 'my-get-operation' }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      path_template => '/foo',
      operation_id => 'my-get-operation',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} get operationId)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get operationId)))->to_string,
          error => 'operation at operation_id does not match provided path_template',
        }),
      ],
    },
    'path_template and operation_id are inconsistent',
  );

  ok($openapi->find_path($options = { operation_id => 'my_reffed_component_operation' }), 'find_path succeeded');
  cmp_result(
    $options,
    {
      operation_id => 'my_reffed_component_operation',
      # note: no path_captures or path_template
      method => 'post',
      _path_item => { post => { operationId => 'my_reffed_component_operation' }},
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/my_path_item/post')),
      errors => [],
    },
    'found path_item on the far side of a $ref using operation_id',
  );

  ok($openapi->find_path($options = { path_template => '/foo', method => 'post' }), 'find_path succeeded');
  cmp_result(
    $options,
    {
      operation_id => 'my_reffed_component_operation',
      # note: no path_captures
      path_template => '/foo',
      method => 'post',
      _path_item => { post => { operationId => 'my_reffed_component_operation' }},
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/my_path_item/post')),
      errors => [],
    },
    'found path_item on the far side of a $ref using path_template and method',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{foo_id}:
    get: {}
YAML

  ok($openapi->find_path($options = { method => 'get', path_template => '/foo/{foo_id}' }), 'find_path succeeded');
  cmp_result(
    $options,
    {
      path_template => '/foo/{foo_id}',
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))),
      errors => [],
    },
    'no operation_id is recorded, because one does not exist in the schema document',
  );

  ok($openapi->find_path(
      $options = { method => 'gET', path_template => '/foo/{foo_id}' }), 'find_path succeeded');
  cmp_result(
    $options,
    {
      method => 'gET',
      path_template => '/foo/{foo_id}',
      _path_item => { get => ignore },
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))),
      errors => [],
    },
    'method option is uppercased',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $lots_of_options,
  );

  ok($openapi->find_path($options = { operation_id => 'my_components_pathItem_operation' }),
    'find_path succeeded');
  cmp_result(
    $options,
    {
      method => 'post',
      _path_item => $lots_of_options->{components}{pathItems}{my_path_item},
      operation_id => 'my_components_pathItem_operation',
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/my_path_item/post')),
      errors => [],
    },
    'operation is not under a path-item with a path template, but still exists',
  );

  ok(!$openapi->find_path($options = { path_template => '/foo/bar', operation_id => 'my_components_pathItem_operation' }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      path_template => '/foo/bar',
      _path_item => { post => ignore },
      method => 'post',
      operation_id => 'my_components_pathItem_operation',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'templated operation does not match provided operation_id',
        }),
      ],
    },
    'this operation cannot be reached by using this path template',
  );

  ok($openapi->find_path($options = { operation_id => 'my_webhook_operation' }),
    'find_path succeeded');
  cmp_result(
    $options,
    {
      method => 'post',
      _path_item => $lots_of_options->{webhooks}{my_hook},
      operation_id => 'my_webhook_operation',
      operation_uri => str($doc_uri->clone->fragment('/webhooks/my_hook/post')),
      errors => [],
    },
    'operation is not under a path-item with a path template, but still exists',
  );

  ok($openapi->find_path($options = { operation_id => 'my_paths_pathItem_callback_operation' }),
    'find_path succeeded');
  cmp_result(
    $options,
    {
      method => 'post',
      _path_item => $lots_of_options->{paths}{'/foo/bar'}{post}{callbacks}{my_callback}{'{$request.query.queryUrl}'},
      operation_id => 'my_paths_pathItem_callback_operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar post callbacks my_callback {$request.query.queryUrl} post)))),
      errors => [],
    },
    'operation is not directly under a path-item with a path template, but still exists',
  );

  ok($openapi->find_path($options = { operation_id => 'my_components_pathItem_callback_operation' }),
    'find_path succeeded');
  cmp_result(
    $options,
    {
      method => 'post',
      _path_item => $lots_of_options->{components}{pathItems}{my_path_item}{post}{callbacks}{my_callback}{'{$request.query.queryUrl}'},
      operation_id => 'my_components_pathItem_callback_operation',
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/my_path_item/post/callbacks/my_callback/{$request.query.queryUrl}/post')),
      errors => [],
    },
    'operation is not under a path-item with a path template, but still exists',
  );
};

subtest $::TYPE.': URI resolution' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get:
      operationId: foo
YAML

  my $request = request('GET', 'gopher://mycorp.com/foo');
  ok(!$openapi->find_path(my $options = { request => $request, path_captures => { a => 1 } }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      _path_item => { get => ignore },
      path_captures => { a => 1 },
      path_template => '/foo',
      operation_id => 'foo',
      operation_uri => str(Mojo::URL->new('/api')->fragment(jsonp(qw(/paths /foo get)))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo)),
          absoluteKeywordLocation => Mojo::URL->new('/api')->clone->fragment(jsonp(qw(/paths /foo)))->to_string,
          error => 'provided path_captures names do not match path template "/foo"',
        }),
      ],
    },
    'scheme and host from URI are used for error locations and operation_uri when openapi document URI is relative',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => Mojo::URL->new('gopher://mycorp.com/api'),
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get:
      operationId: foo
YAML

  ok(!$openapi->find_path($options = { request => $request, path_captures => { a => 1 } }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      _path_item => { get => ignore },
      path_captures => { a => 1 },
      path_template => '/foo',
      operation_id => 'foo',
      operation_uri => str(Mojo::URL->new('gopher://mycorp.com/api')->fragment(jsonp(qw(/paths /foo get)))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri',
          keywordLocation => jsonp(qw(/paths /foo)),
          absoluteKeywordLocation => Mojo::URL->new('gopher://mycorp.com/api')->fragment(jsonp(qw(/paths /foo)))->to_string,
          error => 'provided path_captures names do not match path template "/foo"',
        }),
      ],
    },
    'when openapi document URI is absolute, request scheme and host are not used in error locations or operation_uri',
  );
};

goto START if ++$type_index < @::TYPES;

done_testing;
