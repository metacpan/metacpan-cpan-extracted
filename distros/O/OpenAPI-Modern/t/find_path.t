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

use Test::Fatal;
use JSON::Schema::Modern::Utilities qw(jsonp get_type);

use lib 't/lib';
use Helper;

my $openapi_preamble = <<'YAML';
---
openapi: 3.1.0
info:
  title: Test API
  version: 1.2.3
YAML

# the absolute uri we will see in errors
my $doc_uri_rel = Mojo::URL->new('/api');
my $doc_uri = $doc_uri_rel->to_abs(Mojo::URL->new('http://example.com'));
my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

subtest 'bad conversion to Mojo::Message::Request' => sub {
  test_needs('HTTP::Request', 'URI');

  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths: {}
YAML

  # start line is missing "HTTP/1.1"
  my $request = HTTP::Request->new(GET => 'http://example.com/', [ Host => 'example.com' ]);
  ok(!$openapi->find_path(my $options = { request => $request }),
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
          error => 'Bad request start-line',
        }),
      ],
    },
    'invalid request object is detected early',
  );
};

my $type_index = 0;

START:
$::TYPE = $::TYPES[$type_index];
note 'REQUEST/RESPONSE TYPE: '.$::TYPE;

subtest 'request is parsed to get path information' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo/{foo_id}:
    post:
      operationId: my-post-path
  /foo/bar:
    get:
      operationId: my-get-path
webhooks:
  my_hook:
    description: I like webhooks
    post:
      operationId: hooky
YAML

  my $request = request('GET', 'gopher://example.com/foo/bar');
  ok(!$openapi->find_path(my $options = { request => $request, path_template => '/foo/baz', path_captures => {} }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/baz',
      path_captures => {},
      method => 'get',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->scheme('gopher')->fragment('/paths')->to_string,
          error => 'missing path-item "/foo/baz"',
        }),
      ],
    },
    'unsuccessful path extraction results in the error being returned in the options hash; correct URI scheme is used in errors',
  );


  $request = request('GET', 'http://example.com/foo/bar');
  ok(!$openapi->find_path($options = { request => $request, operation_id => 'bloop', path_captures => {} }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_captures => {},
      operation_id => 'bloop',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'unknown operation_id "bloop"',
        }),
      ],
    },
    'path template does not exist under /paths',
  );


  ok(!$openapi->find_path($options = { request => $request, operation_id => 'hooky', path_captures => {} }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_captures => {},
      operation_id => 'hooky',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => '/webhooks/my_hook/post/operationId',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/webhooks/my_hook/post/operationId')->to_string,
          error => 'operation id does not have an associated path',
        }),
      ],
    },
    'path template does not exist under /paths',
  );


  ok(!$openapi->find_path($options = { request => request('GET', 'http://example.com/foo/bloop') }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'bloop' },
      _path_item => { post => ignore },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/method',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} get)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))->to_string,
          error => 'missing operation for HTTP method "get"',
        }),
      ],
    },
    'operation does not exist under /paths/<path_template>/<method>',
  );


  ok(!$openapi->find_path($options = { request => $request = request('POST', 'http://example.com/foo/bar'),
      path_template => '/foo/{foo_id}', operation_id => 'my-get-path', path_captures => {} }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/{foo_id}',
      path_captures => {},
      operation_id => 'my-get-path',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'operation does not match provided path_template',
        }),
      ],
    },
    'path_template and operation_id are inconsistent',
  );


  ok(!$openapi->find_path($options = { request => $request,
      operation_id => 'my-get-path', path_captures => {} }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_captures => {},
      operation_id => 'my-get-path',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/method',
          keywordLocation => jsonp(qw(/paths /foo/bar get)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar get)))->to_string,
          error => 'wrong HTTP method post',
        }),
      ],
    },
    'request HTTP method does not match operation',
  );


  ok(!$openapi->find_path($options = { request => $request, method => 'GET'}),
    'find_path returns false');
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
          error => 'wrong HTTP method POST',
        }),
      ],
    },
    'request HTTP method does not match method option',
  );


  ok(!$openapi->find_path($options = { request => $request,
        path_template => '/foo/{foo_id}', path_captures => { bloop => 'bar' } }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/{foo_id}',
      path_captures => { bloop => 'bar' },
      _path_item => { post => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_captures names do not match path template "/foo/{foo_id}"',
        }),
      ],
    },
    'path template does not match path captures',
  );


  ok($openapi->find_path($options = { request => request('GET', 'http://example.com/foo/bar'),
      path_template => '/foo/bar', operation_id => 'my-get-path', path_captures => {} }),
    'find_path returns successfully');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/bar',
      path_captures => {},
      operation_id => 'my-get-path',
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/bar get))),
      errors => [],
    },
    'path_template and operation_id can both be passed, if consistent',
  );


  ok(!$openapi->find_path($options = { request => request('GET', 'http://example.com/something/else'),
      path_template => '/foo/bar', path_captures => {} }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/bar',
      path_captures => {},
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/bar get))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'provided path_template does not match request URI',
        }),
      ],
    },
    'path_template is not consistent with request URI, with no captures',
  );


  ok(!$openapi->find_path($options = { request => $request = request('POST', 'http://example.com/something/else'),
      path_template => '/foo/{foo_id}', path_captures => { foo_id => 123 } }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 123 },
      _path_item => { post => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_template does not match request URI',
        }),
      ],
    },
    'path_template is not consistent with request URI, with captures',
  );


  ok(!$openapi->find_path($options = { request => $request,
      path_template => '/foo/{foo_id}' }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo/{foo_id}',
      _path_item => { post => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_template does not match request URI',
        }),
      ],
    },
    'path_template is not consistent with request URI, captures not provided',
  );


  ok(!$openapi->find_path($options = { request => request('GET', 'http://example.com/something/else'),
      operation_id => 'my-get-path', path_captures => {} }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_captures => {},
      operation_id => 'my-get-path',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/bar)))->to_string,
          error => 'provided operation_id does not match request URI',
        }),
      ],
    },
    'operation_id is not consistent with request URI',
  );


  ok(!$openapi->find_path($options = { request => request('POST', 'http://example.com/foo/hello'),
      operation_id => 'my-post-path', path_captures => { foo_id => 'goodbye' } }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_captures => { foo_id => 'goodbye' },
      operation_id => 'my-post-path',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_captures values do not match request URI',
        }),
      ],
    },
    'path_captures values are not consistent with request URI',
  );

  ok($openapi->find_path($options = { request => request('POST', 'http://example.com/foo/123'),
      operation_id => 'my-post-path', path_captures => { foo_id => 123 } }),
    'find_path returns successfully');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_captures => { foo_id => 123 },
      path_template => '/foo/{foo_id}',
      _path_item => { post => ignore },
      operation_id => 'my-post-path',
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post))),
      errors => [],
    },
    'path_capture values are returned as-is in the provided options hash',
  );
  is(get_type($options->{path_captures}{foo_id}), 'integer', 'passed-in path value is preserved as a number');


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo: {}
YAML

  ok(!$openapi->find_path($options = { request => request('POST', 'http://example.com/foo/bar'),
      path_template => '/foo', path_captures => {} }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'post',
      path_template => '/foo',
      path_captures => {},
      _path_item => {},
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/method',
          keywordLocation => jsonp(qw(/paths /foo post)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post)))->to_string,
          error => 'missing operation for HTTP method "post"',
        }),
      ],
    },
    'operation does not exist under /paths/<path-template>',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo/{foo_id}:
    get:
      operationId: my-get-path
YAML

  ok($openapi->find_path($options = { request => $request = request('GET', 'http://example.com/foo/123') }),
    'find_path returns successfully');
  cmp_result(
    $options,
    my $expected = {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => '123' },
      method => 'get',
      operation_id => 'my-get-path',
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get))),
      errors => [],
    },
    'path_capture values are parsed from the request uri and returned in the provided options hash',
  );
  is(get_type($options->{path_captures}{foo_id}), 'string', 'captured path value is parsed as a string');

  ok($openapi->find_path($options = { request => $request, path_template => '/foo/{foo_id}' }),
    'find_path returns successfully');
  cmp_result(
    $options,
    $expected,
    'path capture values and method are extracted from the path template and request uri',
  );
  is(get_type($options->{path_captures}{foo_id}), 'string', 'captured path value is parsed as a string');

  ok($openapi->find_path($options = { request => $request, path_captures => { foo_id => '123' } }),
    'find_path returns successfully');
  cmp_result(
    $options,
    $expected,
    'path_capture values are returned as-is in the provided options hash',
  );
  is(get_type($options->{path_captures}{foo_id}), 'string', 'passed-in path value is preserved as a string');

  ok($openapi->find_path($options = { request => $request, path_template => '/foo/{foo_id}', path_captures => { foo_id => 123 } }),
    'find_path returns successfully');
  cmp_result(
    $options,
    $expected,
    'path_capture values are returned as-is in the provided options hash',
  );
  is(get_type($options->{path_captures}{foo_id}), 'integer', 'passed-in path value is preserved as a number');

  my $val = 123; my $str = sprintf("%s\n", $val);
  ok($openapi->find_path($options = { request => $request, path_template => '/foo/{foo_id}', path_captures => { foo_id => $val } }),
    'find_path returns successfully');
  cmp_result(
    $options,
    $expected,
    'path_capture values are returned as-is in the provided options hash',
  );
  # on perls >= 5.35.9, reading the string form of an integer value no longer sets the flag SVf_POK
  is(
    get_type($options->{path_captures}{foo_id}),
    "$]" >= 5.035009 ? 'integer' : 'ambiguous type',
    'passed-in path value is preserved as a dualvar',
  );

  ok($openapi->find_path($options = { request => $request, path_captures => { foo_id => 123 } }),
    'find_path returns successfully');
  cmp_result(
    $options,
    $expected,
    'path_capture values are returned as-is in the provided options hash',
  );
  is(get_type($options->{path_captures}{foo_id}), 'integer', 'passed-in path value is preserved as a number');

  ok($openapi->find_path($options = { request => $request, operation_id => 'my-get-path' }),
    'find_path returns successfully');
  cmp_result(
    $options,
    $expected,
    'path capture values are extracted from the operation id and request uri',
  );


  ok(!$openapi->find_path($options = { request => $request, path_captures => { foo_id => 'a' } }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'a' },
      _path_item => { get => ignore },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'provided path_captures values do not match request URI',
        }),
      ],
    },
    'request URI is inconsistent with provided path captures',
  );


  ok(!$openapi->find_path($options = { request => request('GET', 'http://example.com/bloop/blah') }),
    'find_path returns false');
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
          error => 'no match found for URI path "/bloop/blah"',
        }),
      ],
    },
    'failure to extract path template and capture values from the request uri',
  );


  my $uri = uri('http://example.com', '', 'foo', 'hello // there ಠ_ಠ!');
  ok($openapi->find_path($options = { request => request('GET', $uri),
      path_template => '/foo/{foo_id}', path_captures => { foo_id => 'hello // there ಠ_ಠ!' } }),
    'find_path returns successfully');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'hello // there ಠ_ಠ!' },
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get))),
      operation_id => 'my-get-path',
      errors => [],
    },
    'path_capture values are found to be consistent with the URI when some values are url-escaped',
  );

  ok($openapi->find_path($options = { request => request('GET', $uri) } ), 'find_path returns successfully');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      operation_id => 'my-get-path',
      path_captures => { foo_id => 'hello // there ಠ_ಠ!' },
      path_template => '/foo/{foo_id}',
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get))),
      errors => [],
    },
    'path captures can be properly extracted from the URI when some values are url-escaped',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
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
  ok($openapi->find_path($options = { request => $request } ), 'find_path returns successfully');
  cmp_result(
    $options,
    my $got_options = {
      request => isa('Mojo::Message::Request'),
      path_captures => {},
      path_template => '/foo/bar',
      method => 'get',
      operation_id => 'concrete-foo-bar',
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/bar get))),
      errors => [],
    },
    'paths with dots are not treated as regex wildcards when matching against URIs',
  );

  ok(!$openapi->find_path($options = { operation_id => 'dotted-foo-bar', request => $request } ), 'find_path fails');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      method => 'get',
      operation_id => 'dotted-foo-bar',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo.bar)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo.bar)))->to_string,
          error => 'provided operation_id does not match request URI',
        }),
      ],
    },
    'provided operation_id and inferred path_template does not match request uri',
  );

  ok($openapi->find_path($options = { operation_id => 'concrete-foo-bar', request => $request } ), 'find_path returns successfully');
  cmp_result(
    $options,
    { %$got_options, request => isa('Mojo::Message::Request') },
    'inferred (correct) path_template matches request uri',
  );


  $request = request('GET', 'http://example.com/foo/x.bar');
  ok($openapi->find_path($options = { request => $request } ), 'find_path returns successfully');
  cmp_result(
    $got_options = $options,
    {
      request => isa('Mojo::Message::Request'),
      path_captures => { foo_id => 'x' },
      path_template => '/foo/{foo_id}.bar',
      operation_id => 'templated-foo-bar',
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id}.bar get))),
      errors => [],
    },
    'capture values are still captured when using dots in path template',
  );

  ok(!$openapi->find_path($options = { operation_id => 'all-dots', request => $request } ), 'find_path fails');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      operation_id => 'all-dots',
      method => 'get',
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/.....)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo/.....)))->to_string,
          error => 'provided operation_id does not match request URI',
        }),
      ],
    },
    'provided operation_id and inferred path_template does not match request uri',
  );

  ok($openapi->find_path($options = { operation_id => 'templated-foo-bar', request => $request } ), 'find_path returns successfully');
  cmp_result(
    $options,
    { %$got_options, request => isa('Mojo::Message::Request') },
    'inferred (correct) path_template matches request uri',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo/{foo_id}:
    get: {}
YAML

  $request = request('GET', 'http://example.com/foo/bar');
  ok($openapi->find_path($options = { request => $request }),
    'find_path returns successfully');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'bar' },
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get))),
      errors => [],
    },
    'no path_template provided; no operation_id is recorded, because one does not exist in the schema document',
  );


  ok($openapi->find_path($options = { request => $request, path_template => '/foo/{foo_id}' }),
    'find_path returns successfully');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'bar' },
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get))),
      errors => [],
    },
    'path_template provided; no operation_id is recorded, because one does not exist in the schema document',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /:
    get: {}
YAML

  $request = request('GET', 'http://example.com');
  ok($openapi->find_path($options = { request => $request }), 'find_path can match an empty uri path');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/',
      path_captures => {},
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths / get))),
      errors => [],
    },
    'path_template inferred from request uri',
  );

  ok($openapi->find_path($options = { request => $request, path_template => '/' }),
   'find_path can match an empty uri path when passed path_template');
  cmp_result(
    $options,
    {
      request => isa('Mojo::Message::Request'),
      path_template => '/',
      path_captures => {},
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths / get))),
      errors => [],
    },
    'provided path_template verified against request uri',
  );
};

subtest 'no request is provided: options are relied on as the sole source of truth' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo/{foo_id}:
    get:
      operationId: my-get-path
YAML

  like(
    exception { ()= $openapi->find_path(my $options = { path_captures => {} }) },
    qr/^at least one of \$options->\{request\}, \$options->\{method\} and \$options->\{operation_id\} must be provided/,
    'method can only be derived from request or operation_id',
  );

  ok(!$openapi->find_path(my $options = { operation_id => 'my-get-path', method => 'POST', path_captures => {} }),
    'find_path returns false');
  cmp_result(
    $options,
    {
      operation_id => 'my-get-path',
      method => 'POST',
      path_captures => {},
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/method',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} get)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get)))->to_string,
          error => 'wrong HTTP method POST',
        }),
      ],
    },
    'no request provided; operation method does not match passed-in method',
  );

  like(
    exception { ()= $openapi->find_path($options = { method => 'get', path_captures => {} }) },
    qr/^at least one of \$options->\{request\}, \$options->\{path_template\} and \$options->\{operation_id\} must be provided/,
    'path_template can only be derived from request or operation_id',
  );

  ok(!$openapi->find_path($options = { path_template => '/foo/{foo_id}', path_captures => {}, method => 'get' }), 'find_path failed');
  cmp_result(
    $options,
    {
      path_template => '/foo/{foo_id}',
      path_captures => {},
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get))),
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/uri/path',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id})),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id})))->to_string,
          error => 'provided path_captures names do not match path template "/foo/{foo_id}"',
        }),
      ],
    },
    'no request provided; path template does not match path captures',
  );

  ok($openapi->find_path($options = { operation_id => 'my-get-path', path_captures => { foo_id => 'a' } }), 'find_path succeeded');
  cmp_result(
    $options,
    {
      operation_id => 'my-get-path',
      path_captures => { foo_id => 'a' },
      path_template => '/foo/{foo_id}',
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get))),
      errors => [],
    },
    'no request provided; path_template and method are extracted from operation_id and path_captures',
  );

  ok($openapi->find_path($options = { method => 'get', path_template => '/foo/{foo_id}', path_captures => { foo_id => 'a' } }), 'find_path succeeded');
  cmp_result(
    $options,
    {
      operation_id => 'my-get-path',
      path_captures => { foo_id => 'a' },
      path_template => '/foo/{foo_id}',
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get))),
      errors => [],
    },
    'no request provided; operation_id are extracted from method and path_template',
  );

  ok(!$openapi->find_path($options = { path_template => '/foo/{foo_id}', path_captures => { foo_id => 'a' }, method => 'post' }), 'find_path failed');
  cmp_result(
    $options,
    {
      path_captures => { foo_id => 'a' },
      path_template => '/foo/{foo_id}',
      method => 'post',
      _path_item => { get => ignore },
      errors => [
        methods(TO_JSON => {
          instanceLocation => '/request/method',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} post)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post)))->to_string,
          error => 'missing operation for HTTP method "post"',
        }),
      ],
    },
    'no request provided; operation does not exist for path-item',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
paths:
  /foo/{foo_id}:
    get: {}
YAML

  ok($openapi->find_path(
      $options = { method => 'get', path_template => '/foo/{foo_id}', path_captures => { foo_id => 'bar' } }),
    'find_path succeeded');
  cmp_result(
    $options,
    {
      path_template => '/foo/{foo_id}',
      path_captures => { foo_id => 'bar' },
      method => 'get',
      _path_item => { get => ignore },
      operation_uri => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} get))),
      errors => [],
    },
    'no operation_id is recorded, because one does not exist in the schema document',
  );
};

goto START if ++$type_index < @::TYPES;

done_testing;
