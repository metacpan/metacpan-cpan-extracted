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
use JSON::Schema::Modern::Utilities qw(jsonp add_media_type jsonp_elements);
use Mojo::UserAgent::Transactor;

my $doc_uri_rel = Mojo::URL->new('/api');
my $doc_uri = $doc_uri_rel->to_abs(Mojo::URL->new('http://example.com'));

add_media_type('text/to_upper' => sub ($ref) { \($ref->$* =~ tr/a-z/A-Z/r) });
add_media_type('text/rot13' => sub ($ref) { \($ref->$* =~ tr/n-za-mN-ZA-M/a-zA-Z/r) });

my $type_index = 0;

START:
$::TYPE = $::TYPES[$type_index];
note 'REQUEST/RESPONSE TYPE: '.$::TYPE;

subtest $::TYPE.': corrupt multipart/mixed' => sub {
  skip_all 'there is no nice way to construct a multipart/mixed in lwp' if $::TYPE eq 'lwp';
  skip_all 'Plack insists on parsing a multipart/mixed message body'
    if elem($::TYPE, [qw(plack catalyst dancer2)]);

  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /supported:
    post:
      requestBody:
        content:
          multipart/mixed: {}
YAML

  my $result = $openapi->validate_request(request('POST', 'http://example.com/supported',
    [ 'Content-Type' => 'multipart/mixed; boundary=BLOOP' ], '!!!'));

  cmp_result(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => false,
        errors => [
          {
            instanceLocation => '/request/body',
            keywordLocation => jsonp(qw(/paths /supported post requestBody content multipart/mixed)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /supported post requestBody content multipart/mixed)))->to_string,
            error => re(qr{^could not decode content as multipart/mixed; boundary=BLOOP: body is not multipart}),
          },
        ],
      },
      {},
    ],
    'corrupt multipart/mixed messages are properly handled',
  );

  my $request = Mojo::UserAgent::Transactor->new->tx(POST => 'http://example.com/supported',
    { 'Content-Type' => 'multipart/mixed' }, multipart => [ 'alpha', '42' ])->req;
  $request->fix_headers;

  $result = $openapi->validate_request($request);

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      { request => { body => { content => [ 'alpha', '42' ] } } },
    ],
    'multipart/mixed messages with a real multipart body are valid if there is no body schema',
  );
};

subtest $::TYPE.': multipart/mixed and other multipart/* deserialization' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /empty_media_type:
    post:
      requestBody:
        content:
          multipart/mixed: {}
  /empty_schema:
    post:
      requestBody:
        content:
          multipart/mixed:
            schema: true
  /itemSchema:
    post:
      requestBody:
        content:
          multipart/mixed:
            itemSchema: true
  /itemEncoding_no_schema:
    post:
      requestBody:
        content:
          multipart/mixed:
            itemEncoding:
              contentType: text/to_upper
  /nested_itemEncoding_no_schema:
    post:
      requestBody:
        content:
          multipart/mixed:
            itemEncoding:
              itemEncoding:
                contentType: text/to_upper
YAML

  my $result = $openapi->validate_request(request('POST', 'http://example.com/empty_media_type',
    [ 'Content-Type' => 'multipart/mixed' ],
    my $body = [
      [ '["id","123"]' ],
      [ '["address","42"]' ],
      [ '["secret","hello"]' ],
    ]));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      my $result_data = {
        request => {
          body => {
            content => [
              '["id","123"]',
              '["address","42"]',
              '["secret","hello"]',
            ],
          },
        },
      },
    ],
    'message parts are returned as-is in an array when there is no schema or encoding object',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/empty_schema',
    [ 'Content-Type' => 'multipart/mixed' ], $body));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      $result_data,
    ],
    'message parts are returned as-is in an array when there is an empty schema',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/itemSchema',
    [ 'Content-Type' => 'multipart/mixed' ], $body));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      $result_data,
    ],
    'message parts are returned as-is as an array when there is an empty itemSchema',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/empty_media_type',
    [ 'Content-Type' => 'multipart/mixed' ],
    [
      [ '{"id":123}', 'Content-Type' => 'application/json' ],
      [ '{"address":42}', 'Content-Type' => 'application/json' ],
      [ '{"secret":true}', 'Content-Type' => 'application/json' ],
    ]));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          body => {
            header => [ ({ 'Content-Type' => 'application/json' })x3 ],
            content => [
              { id => 123 },
              { address => 42 },
              { secret => true },
            ],
          },
        },
      },
    ],
    'message parts are json-decoded via Content-Type header, even without any schema or encoding object',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/itemEncoding_no_schema',
    [ 'Content-Type' => 'multipart/mixed' ],
    [ [ 'Hello' ], [ 'World!' ] ]));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          body => {
            content => [ 'HELLO', 'WORLD!' ],
          },
        },
      },
    ],
    'itemEncoding is still respected when there is no schema for that part of the data',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/nested_itemEncoding_no_schema',
    [ 'Content-Type' => 'multipart/mixed' ],
    [ [ '["Hello","World!"]', 'Content-Type' => 'application/json' ] ]));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          body => {
            header => [ { 'Content-Type' => 'application/json' } ],
            content => [ [ 'HELLO', 'WORLD!' ] ],
          },
        },
      },
    ],
    'nested itemEncoding is still respected when there is no schema for that part of the data',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /schema:
    post:
      requestBody:
        content:
          multipart/mixed:
            schema:
              type: array
              prefixItems:
                - type: array
                  items:
                    type: string
              items:
                type: object
                properties:
                  id:
                    type: string
                  address:
                    type: number
            prefixEncoding:
              - itemEncoding:
                  contentType: text/rot13
            itemEncoding:
              encoding:
                secret:
                  contentType: text/rot13
  /itemSchema:
    post:
      requestBody:
        content:
          multipart/mixed:
            itemSchema:
              type: [ object, array ]
              properties:
                id:
                  type: string
                address:
                  type: number
              items:
                type: string
            prefixEncoding:
              - itemEncoding:
                  contentType: text/rot13
            itemEncoding:
              encoding:
                secret:
                  contentType: text/rot13
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/schema',
    [ 'Content-Type' => 'multipart/mixed' ],
    $body = [
      [ '["hello"]' ],
      [ '{"id":"123"}' ],
      [ '{"address":"42"}' ],
      [ '{"secret":"hello"}' ],
    ]));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      $result_data = {
        request => {
          body => {
            # no headers, so this section is entirely absent
            content => [
              [ 'uryyb' ],
              { id => '123' },
              { address => 42 },
              { secret => 'uryyb' },
            ],
          },
        },
      },
    ],
    'object parts are deserialized from multipart/mixed using the schema keyword',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/itemSchema',
    [ 'Content-Type' => 'multipart/mixed' ], $body));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      $result_data,
    ],
    'object parts are deserialized from multipart/mixed using the itemSchema keyword',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/itemSchema',
    [ 'Content-Type' => 'multipart/mixed' ],
    [
      [ '{"id":"123"}', 'X-Test' => '1' ],
      [ '{"id":"456"}' ],
      [ '{"id":"789"}', 'X-Test' => '3' ],
      [ '{"id":"abc"}' ],
    ],
  ));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          body => {
            header => [
              { 'X-Test' => '1' },
              {},
              { 'X-Test' => '3' },
            ],
            content => [
              { id => '123' },
              { id => '456' },
              { id => '789' },
              { id => 'abc' },
            ],
          },
        },
      },
    ],
    'empty header items are removed, but only from the end of the array',
  );


  my $yatta_encoded = Encode::encode('Shift_JIS', 'やった');

  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<"YAML"));
components:
  examples:
    serialized_example:
      serializedValue: |
        --KJvXX

        $yatta_encoded
        --KJvXX

        $yatta_encoded
        --KJvXX
paths:
  /array:
    post:
      requestBody:
        content:
          multipart/mixed:
            schema:
              type: array
              items:
                type: string
            examples:
              serialized_example:
                \$ref: '#/components/examples/serialized_example'
              array_example:
                dataValue:
                  - やった
                  - やった
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/mixed' ],
    [ ([ $yatta_encoded, 'Content-Type' => 'text/plain; charset=Shift_JIS' ])x2 ],
  ));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      my $request_data = {
        request => {
          body => {
            header => [ ({ 'Content-Type' => 'text/plain; charset=Shift_JIS' })x2 ],
            content => [ ('やった')x2 ],
          },
        },
      },
    ],
    'multipart/mixed decoding with Content-Type',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/mixed' ],
    [ ([ $yatta_encoded ])x2 ],
  ));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          body => {
            content => [ ($yatta_encoded)x2 ],
          },
        },
      },
    ],
    'multipart/mixed decoding fails due to lack of charset, for object',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /array:
    post:
      requestBody:
        content:
          multipart/mixed:
            schema:
              type: array
              items:
                const: やった
            itemEncoding:
              contentType: text/plain; charset=Shift_JIS
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/mixed' ],
    [ ([ $yatta_encoded ])x2 ],
  ));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          body => {
            content => [ ('やった')x2 ],
          },
        },
      },
    ],
    'multipart/mixed decoding uses contentType',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/mixed' ],
    [ ([ $yatta_encoded, 'Content-Type' => 'text/plain; charset=Shift_JIS' ])x2 ],
  ));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          body => {
            header => [
              ({ 'Content-Type' => 'text/plain; charset=Shift_JIS' })x2,
            ],
            content => [ ('やった')x2 ],
          },
        },
      },
    ],
    'multipart/mixed decoding uses both contentType and Content-Type',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/mixed' ],
    [
      ([ Encode::encode('UTF-8', 'やった'), 'Content-Type' => 'text/plain; charset=UTF-8' ])x2,
    ],
  ));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => false,
        errors => [
          map +{
            instanceLocation => '/request/body/header/'.$_.'/Content-Type',
            keywordLocation => jsonp(qw(/paths /array post requestBody content multipart/mixed itemEncoding contentType)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /array post requestBody content multipart/mixed itemEncoding contentType)))->to_string,
            error => 'incorrect Content-Type "text/plain; charset=UTF-8"',
          }, 0..1,
        ],
      },
      {
        request => {
          body => {
            header => [
              ({ 'Content-Type' => 'text/plain; charset=UTF-8' })x2,
            ],
            # message payload still successfully decodes using UTF-8 decoding
            content => [ ('やった')x2 ],
          },
        },
      },
    ],
    'multipart/mixed object decoding, prefer Content-Type over encoding/contentType',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /array:
    post:
      requestBody:
        content:
          multipart/mixed:
            schema:
              type: array
              items:
                const: やった
            itemEncoding:
              contentType: text/plain
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/mixed' ],
    [
      ([ Encode::encode('UTF-8', 'やった') , 'Content-Type' => 'text/plain; charset=UTF-8' ])x2,
    ]
  ));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          body => {
            header => [ ({ 'Content-Type' => 'text/plain; charset=UTF-8' })x2 ],
            # message payload still successfully decodes using UTF-8 decoding
            content => [ ('やった')x2 ],
          },
        },
      },
    ],
    'multipart/mixed object decoding, more specific Content-Type is used over encoding/contentType',
  );
};

subtest 'deserialize_multipart' => sub {
  skip_all 'this test works directly with mojo objects' if $::TYPE ne 'mojo';

  my $request = request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/mixed' ],
    [
      [                               # first level, first part
        [                             # ...contains a multipart/mixed:
          [ '1', 'X-Test' => 'a' ],   # second level, first part
          [ '2', 'X-Test' => 'b' ],   # second level, second part
        ],
        'Content-Type' => 'multipart/mixed',
        'X-Test' => 'alpha',
      ],
      [
        [
          [ '1', 'X-Test' => 'x' ],
          [ '2', 'X-Test' => 'y' ],
        ],
        'Content-Type' => 'multipart/mixed',
        'X-Test' => 'beta',
      ],
    ],
  );

  my @boundaries = get_part_boundaries($request);

  is_equal(
    [ my ($content, $headers) = OpenAPI::Modern::Utilities::deserialize_multipart($request->content) ],
    [
      [
        [ '1', '2' ],
        [ '1', '2' ],
      ],
      [
        { # headers for top level part #0.
          'Content-Type' => 'multipart/mixed; boundary='.$boundaries[0],
          'X-Test' => 'alpha',
          0 => { 'X-Test' => 'a' },
          1 => { 'X-Test' => 'b' },
        },
        { # headers for top level part #1.
          'Content-Type' => 'multipart/mixed; boundary='.$boundaries[1],
          'X-Test' => 'beta',
          0 => { 'X-Test' => 'x' },
          1 => { 'X-Test' => 'y' },
        },
      ],
    ],
    'recursively deserialized content and headers from nested multipart/mixed body',
  );

  is_equal(
    jsonp_elements($headers),
    {
      '/0/Content-Type' => 'multipart/mixed; boundary='.$boundaries[0],
      '/0/X-Test' => 'alpha',
      '/0/0/X-Test' => 'a',
      '/0/1/X-Test' => 'b',
      '/1/Content-Type' => 'multipart/mixed; boundary='.$boundaries[1],
      '/1/X-Test' => 'beta',
      '/1/0/X-Test' => 'x',
      '/1/1/X-Test' => 'y',
    },
    'JSON pointer locations for body headers',
  );


  $request = request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/mixed' ],
    [
      [                                   # first level, first part
        [                                 # ...contains a multipart/form-data
          [ a => '1', 'X-Test' => 'a' ],  # second level, first part
          [ b => '2', 'X-Test' => 'b' ],  # second level, second part
        ],
        'Content-Type' => 'multipart/form-data',
        'X-Test' => 'alpha',
      ],
      [
        [
          [ x => '1', 'X-Test' => 'x' ],
          [ y => '2', 'X-Test' => 'y' ],
        ],
        'Content-Type' => 'multipart/form-data',
        'X-Test' => 'beta',
      ],
    ],
  );

  @boundaries = get_part_boundaries($request);

  is_equal(
    [ ($content, $headers) = OpenAPI::Modern::Utilities::deserialize_multipart($request->content) ],
    [
      # content
      [
        [ { a => '1' }, { b => '2' } ],
        [ { x => '1' }, { y => '2' } ],
      ],
      # headers
      [
        { # headers for top level part #0.
          'Content-Type' => 'multipart/form-data; boundary='.$boundaries[0],
          'X-Test' => 'alpha',
          0 => { 'Content-Disposition' => 'form-data; name="a"', 'X-Test' => 'a' },
          1 => { 'Content-Disposition' => 'form-data; name="b"', 'X-Test' => 'b' },
        },
        { # headers for top level part #1.
          'Content-Type' => 'multipart/form-data; boundary='.$boundaries[1],
          'X-Test' => 'beta',
          0 => { 'Content-Disposition' => 'form-data; name="x"', 'X-Test' => 'x' },
          1 => { 'Content-Disposition' => 'form-data; name="y"', 'X-Test' => 'y' },
        },
      ],
    ],
    'recursively deserialized headers and content from multipart/form-data nested in a multipart/mixed',
  );

  is_equal(
    jsonp_elements($headers),
    {
      '/0/Content-Type' => 'multipart/form-data; boundary='.$boundaries[0],
      '/0/X-Test' => 'alpha',
      '/0/0/Content-Disposition' => 'form-data; name="a"',
      '/0/0/X-Test' => 'a',
      '/0/1/Content-Disposition' => 'form-data; name="b"',
      '/0/1/X-Test' => 'b',
      '/1/Content-Type' => 'multipart/form-data; boundary='.$boundaries[1],
      '/1/X-Test' => 'beta',
      '/1/0/Content-Disposition' => 'form-data; name="x"',
      '/1/0/X-Test' => 'x',
      '/1/1/Content-Disposition' => 'form-data; name="y"',
      '/1/1/X-Test' => 'y',
    },
    'JSON pointer locations for body headers',
  );
};

subtest 'multipart/mixed with nested multipart/mixed' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          multipart/mixed: {}
YAML

  my $request = request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/mixed' ],
    [
      [                               # first level, first part
        [                             # ...contains a multipart/mixed:
          [ '1', 'X-Test' => 'a' ],   # second level, first part
          [ '2', 'X-Test' => 'b' ],   # second level, second part
        ],
        'Content-Type' => 'multipart/mixed',
        'X-Test' => 'alpha',
      ],
      [
        [
          [ '1', 'X-Test' => 'x' ],
          [ '2', 'X-Test' => 'y' ],
        ],
        'Content-Type' => 'multipart/mixed',
        'X-Test' => 'beta',
      ],
    ],
  );

  my @boundaries = get_part_boundaries($request);
  my $result = $openapi->validate_request($request);

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      my $result_data = {
        request => {
          body => {
            header => [
              { # headers for top level part #0.
                'Content-Type' => 'multipart/mixed; boundary='.$boundaries[0],
                'X-Test' => 'alpha',
                0 => { 'X-Test' => 'a' },
                1 => { 'X-Test' => 'b' },
              },
              { # headers for top level part #1.
                'Content-Type' => 'multipart/mixed; boundary='.$boundaries[1],
                'X-Test' => 'beta',
                0 => { 'X-Test' => 'x' },
                1 => { 'X-Test' => 'y' },
              },
            ],
            content => [
              [ '1', '2' ],
              [ '1', '2' ],
            ],
          },
        },
      },
    ],
    'nested multipart/mixed with no schema or encoding deserializes to arrays inside array',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          multipart/mixed:
            itemSchema:
              type: array
              items:
                type: number
YAML

  $result = $openapi->validate_request($request);

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          body => {
            $result_data->{request}{body}->%{header},
            content => [
              [ 1, 2 ],
              [ 1, 2 ],
            ],
          },
        },
      },
    ],
    'nested multipart/mixed, deserialized to nested arrays, with primitive coercion',
  );
};

subtest 'multipart/mixed with nested multipart/form-data' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          multipart/mixed: {}
YAML

  my $request = request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/mixed' ],
    [
      [                                   # first level, first part
        [                                 # ...contains a multipart/form-data
          [ a => '1', 'X-Test' => 'a' ],  # second level, first part
          [ b => '2', 'X-Test' => 'b' ],  # second level, second part
        ],
        'Content-Type' => 'multipart/form-data',
        'X-Test' => 'alpha',
      ],
      [
        [
          [ x => '1', 'X-Test' => 'x' ],
          [ y => '2', 'X-Test' => 'y' ],
        ],
        'Content-Type' => 'multipart/form-data',
        'X-Test' => 'beta',
      ],
    ],
  );

  my @boundaries = get_part_boundaries($request);
  my $result = $openapi->validate_request($request);

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      my $result_data = {
        request => {
          body => {
            header => [
              { # headers for top level part #0.
                'Content-Type' => 'multipart/form-data; boundary='.$boundaries[0],
                'X-Test' => 'alpha',
                0 => { 'Content-Disposition' => 'form-data; name="a"', 'X-Test' => 'a' },
                1 => { 'Content-Disposition' => 'form-data; name="b"', 'X-Test' => 'b' },
              },
              { # headers for top level part #1.
                'Content-Type' => 'multipart/form-data; boundary='.$boundaries[1],
                'X-Test' => 'beta',
                0 => { 'Content-Disposition' => 'form-data; name="x"', 'X-Test' => 'x' },
                1 => { 'Content-Disposition' => 'form-data; name="y"', 'X-Test' => 'y' },
              },
            ],
            content => [
              { a => '1', b => '2' },
              { x => '1', y => '2' },
            ],
          },
        },
      },
    ],
    'multipart/form-data nested in multipart/mixed with no schema or encoding defaults to objects inside array',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          multipart/mixed:
            itemSchema:
              type: object
              additionalProperties:
                type: number
YAML

  $result = $openapi->validate_request($request);

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          body => {
            $result_data->{request}{body}->%{header},
            content => [
              { a => 1, b => 2 },
              { x => 1, y => 2 },
            ],
          },
        },
      },
    ],
    'multipart/form-data nested inside multipart/mixed (objects inside array), with primitive coercion',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          multipart/mixed:
            itemSchema:
              type: array
              items:
                type: object
                additionalProperties:
                  type: number
YAML

  $result = $openapi->validate_request($request);

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => {
          body => {
            $result_data->{request}{body}->%{header},
            content => [
              [ { a => 1 }, { b => 2 } ],
              [ { x => 1 }, { y => 2 } ],
            ],
          },
        },
      },
    ],
    'multipart/form-data nested inside multipart/mixed (arrays inside array), with primitive coercion',
  );
};

if (++$type_index < @::TYPES) {
  bail_if_not_passing if $ENV{AUTHOR_TESTING};
  goto START;
}

done_testing;
