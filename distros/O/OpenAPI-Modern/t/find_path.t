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
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use JSON::Schema::Modern::Utilities qw(jsonp get_type);

use lib 't/lib';
use Helper;

# the absolute uri we will see in errors
my $doc_uri_rel = Mojo::URL->new('/api');
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
  /foo/{foo_id}:
    post:
      operationId: my-post-operation
  /foo/bar:
    get:
      operationId: my-get-operation
    post:
      operationId: another-post-operation
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
          instanceLocation => '/request/uri/path',
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
          instanceLocation => '/request/uri/path',
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
      path_template => '/foo/{foo_id}',
      _path_item => { post => ignore },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/method',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'missing operation for HTTP method "put"',
        }),
      ],
    },
    'operation does not exist under /paths/<path_template>/<method>',
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
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
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
          keywordLocation => jsonp(qw(/paths /foo/bar get)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar get)))->to_string,
          error => 'wrong HTTP method "post"',
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
      _path_item => { get => ignore, post => ignore },
      operation_id => 'another-post-operation',
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
      _path_item => { post => ignore },
      operation_id => 'my-post-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post)))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
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
      operation_id => 'another-post-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar post)))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
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
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'provided path_template does not match request URI',
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
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_template does not match request URI',
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
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_template does not match request URI',
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
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'provided path_template does not match request URI',
        }),
      ],
    },
    'a path matches this request URI, but not the path_template we provided',
  );

  ok(!$openapi->find_path($options = { request => request('POST', 'http://example.com/foo/123'), path_template => '/foo/bar', operation_id => 'my-post-operation' }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/bar',
      operation_id => 'my-post-operation',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
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
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/bar get)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar get)))->to_string,
          error => 'provided operation_id does not match request URI',
        }),
      ],
    },
    'operation_id is not consistent with request URI',
  );

  ok(!$openapi->find_path($options = { request => request('POST', 'http://example.com/foo/123'),
      operation_id => 'another-post-operation' }),
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
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/bar post)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar post)))->to_string,
          error => 'provided operation_id does not match request URI',
        }),
      ],
    },
    'operation_id is not consistent with request URI, but the real operation does exist (with the same method)',
  );

  ok(!$openapi->find_path($options = { request => request('POST', 'http://example.com/foo/hello'),
      operation_id => 'my-post-operation', path_captures => { foo_id => 'goodbye' } }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/{foo_id}',
      method => 'post',
      path_captures => { foo_id => 'goodbye' },
      operation_id => 'my-post-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post)))),
      _path_item => { post => ignore },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_captures values do not match request URI (value for foo_id differs)',
        }),
      ],
    },
    'path_captures values are not consistent with request URI',
  );

  ok($openapi->find_path($options = { request => request('POST', 'http://example.com/foo/123'),
      operation_id => 'my-post-operation', path_captures => { foo_id => 123 } }),
    to_str($request).': find_path returns successfully');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_captures => { foo_id => 123 },
      path_template => '/foo/{foo_id}',
      _path_item => { post => ignore },
      operation_id => 'my-post-operation',
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
      path_template => '/foo/{foo_id}',
      _path_item => { post => ignore },
      operation_id => 'my-post-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post)))),
      errors => [],
    },
    'path_capture values are returned as-is in the provided options hash',
  );
  is(get_type($options->{path_captures}{foo_id}), 'integer', 'passed-in path value is preserved as a number');


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
      _path_item => { get => ignore },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/method',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'missing operation for HTTP method "post"',
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
      _path_item => { get => ignore },
      operation_id => 'my-get-operation',
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_captures values do not match request URI (value for foo_id differs)',
        }),
      ],
    },
    'request URI is inconsistent with provided path captures',
  );

  ok(!$openapi->find_path($options = { request => request('GET', 'http://example.com/bloop/blah') }),
    to_str($request).': find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'no match found for request URI "http://example.com/bloop/blah"',
        }),
      ],
    },
    'no match for URI against /paths',
  );

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
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo.bar get)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo.bar get)))->to_string,
          error => 'provided operation_id does not match request URI',
        }),
      ],
    },
    'provided operation_id and inferred path_template does not match request uri',
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
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/..... get)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/..... get)))->to_string,
          error => 'provided operation_id does not match request URI',
        }),
      ],
    },
    'provided operation_id and inferred path_template does not match request uri',
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
      method => 'post',
      operation_id => 'my_reffed_component_operation',
      operation_uri => str($doc_uri->clone->fragment('/components/pathItems/my_path_item2/post')),
      errors => [],
    },
    'can find a path-item by operation_id, and then verify the provided path_template against the request despite there being a $ref in the way',
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
          instanceLocation => '/request/method',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} get)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))->to_string,
          error => 'wrong HTTP method "POST"',
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
          instanceLocation => '/request/uri/path',
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
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/method',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'missing operation for HTTP method "post"',
        }),
      ],
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
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
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

subtest $::TYPE.': URIs are resolved against openapi document URI first, then request URI' => sub {
  TODO: {
    # we do not resolve any document URIs against the request URI, but the request URI needs to
    # be aligned with the retrieval_uri (original_uri) in order for uris to match when server urls
    # are defined.
    local $TODO = 'these tests need to be rewritten to take server urls into account';
    fail('this test is broken for now');
    return;
  }

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
      operation_uri => str(Mojo::URL->new('gopher://mycorp.com/api')->fragment(jsonp(qw(/paths /foo get)))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo)),
          absoluteKeywordLocation => Mojo::URL->new('gopher://mycorp.com/api')->clone->fragment(jsonp(qw(/paths /foo)))->to_string,
          error => 'provided path_captures names do not match path template "/foo"',
        }),
      ],
    },
    'scheme and host from URI are used for error locations and operation_uri when openapi document URI is relative',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,  # absolute
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
      operation_uri => str($doc_uri->clone->fragment(jsonp(qw(/paths /foo get)))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo)))->to_string,
          error => 'provided path_captures names do not match path template "/foo"',
        }),
      ],
    },
    'when openapi document URI is absolute, request scheme and host are not used in error locations or operation_uri',
  );
};

goto START if ++$type_index < @::TYPES;

done_testing;
