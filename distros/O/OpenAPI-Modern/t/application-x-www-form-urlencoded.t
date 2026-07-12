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
use JSON::Schema::Modern::Utilities qw(jsonp add_media_type delete_media_type encode_media_type);

my $doc_uri_rel = Mojo::URL->new('/api');
my $doc_uri = $doc_uri_rel->to_abs(Mojo::URL->new('http://example.com'));

my $raw_image = 'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAABGdBTUEAALGPC_xhBQAAADhlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAAAAqADAAQAAAABAAAAAgAAAADO0J6QAAAAEElEQVQIHWP8zwACTGCSAQANHQEDqtPptQAAAABJRU5ErkJggg==';

my $type_index = 0;

START:
$::TYPE = $::TYPES[$type_index];
note 'REQUEST/RESPONSE TYPE: '.$::TYPE;

subtest $::TYPE.': application/x-www-form-urlencoded encoding' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml((OPENAPI_PREAMBLE =~ s/3\.2/3.1/r).<<'YAML'));
components:
  schemas:
    my_schema:
      type: object
      properties:
        key1:
          type: number
        key2:
          type: object  # when encoding/contentType is missing, default to application/json
paths:
  /foo/{my_path}:
    post:
      parameters:
        - name: my_path
          in: path
          required: true
          content:
            application/x-www-form-urlencoded:
              schema:
                $ref: '#/components/schemas/my_schema'
        - name: my_query
          in: query
          required: true
          content:
            application/x-www-form-urlencoded:
              schema:
                $ref: '#/components/schemas/my_schema'
        - name: My-Header
          in: header
          required: true
          content:
            application/x-www-form-urlencoded:
              schema:
                $ref: '#/components/schemas/my_schema'
        - name: my_cookie
          in: cookie
          required: true
          content:
            application/x-www-form-urlencoded:
              schema:
                $ref: '#/components/schemas/my_schema'
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              $ref: '#/components/schemas/my_schema'
YAML

  my $encoded  = encode_media_type('application/x-www-form-urlencoded', # { for the editor
      \{ key1 => '1e+1', key2 => $::dumper->encode({x=>1}) })->$*;
  my $decoded = { key1 => 10, key2 => { x => 1 } };

  my $uri = uri('http://example.com', 'foo', $encoded);
  my $request = request('POST', $uri,
    [ 'My-Header' => $encoded, Cookie => 'my_cookie='.$encoded, 'Content-Type' => 'application/x-www-form-urlencoded' ], $encoded);
  query_params($request, [ my_query => $encoded ]);

  is(
    $::TYPE eq 'mojo' ? $request->url : $request->uri,
    'http://example.com/foo/key1=1e%252B1&key2=%257B%2522x%2522%253A1%257D?my_query=key1%3D1e%252B1%26key2%3D%257B%2522x%2522%253A1%257D',
    'request URI is doubly-percent-encoded, including the % and + characters'
  );

  my $result = $openapi->validate_request($request);
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
            path => { my_path => $decoded },
            query => { my_query => $decoded },
          },
          header => {
            'My-Header' => $decoded,
            Cookie => { my_cookie => $decoded },
          },
          body => { content => $decoded },
        },
      },
    ],
    'parameter and body decoding is successful, with type coercion, even on 3.1',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /supported:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema: {}
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/supported',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ], 'foo=bar'));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      { request => { body => { content => { foo => 'bar' } } } },
    ],
    'application/x-www-form-urlencoded messages can be validated if there is no encoding object',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded: {}
YAML

  $result = $openapi->validate_request($request = request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6', address => '123 Example Dr.' }));
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
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              address => '123 Example Dr.',
            },
          },
        },
      },
    ],
    'single-level object is deserialized from form=urlencoded, no schema or encoding object',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema: true
YAML

  $result = $openapi->validate_request($request);
  is_equal($result->TO_JSON, { valid => true }, 'boolean schema is okay here');


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                id:
                  type: string
                  format: uuid
                quantity:
                  type: number
                quantities:
                  type: [ number, array ]
                  items:
                    type: number
              enum:
                - id: f81d4fae-7dec-11d0-a765-00a0c91e6bf6
                  quantity: 42.5
                - id: f81d4fae-7dec-11d0-a765-00a0c91e6bf6
                  quantities: 42.5
                - id: f81d4fae-7dec-11d0-a765-00a0c91e6bf6
                  quantities: [ 42.5, 10 ]
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6', quantity => 42.5 }));
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
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              quantity => 42.5,
            },
          },
        },
      },
    ],
    'single-level object is deserialized from form=urlencoded, no encoding object, with coercion',
  );


  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6', quantities => 42.5 }));
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
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              quantities => 42.5,
            },
          },
        },
      },
    ],
    'single string value is coerced to a number',
  );


  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6', quantities => [ 42.5, 10 ] },
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
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              quantities => [ 42.5, 10 ],
            },
          },
        },
      },
    ],
    'repeated name in the form is represented as an array; values are coerced',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                name:
                  type: string
                quantity:
                  type: number
              const:
                name: 'éclair'
                quantity: 42.5
            encoding:
              name:
                contentType: text/plain; charset=UTF-8
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { name => Encode::encode('UTF-8', 'éclair'), quantity => '42.5' }));
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
            content => {
              name => 'éclair',
              quantity => 42.5,
            },
          },
        },
      },
    ],
    'repeated name in the form is represented as an array; values are coerced',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                name:
                  type: string
                alias:
                  type: [ string, array ]
                  items:                  # used when multiple values are passed
                    type: string
            encoding:
              name:
                contentType: text/rot13
              alias:
                contentType: text/rot13
YAML

  add_media_type('text/rot13' => sub ($ref) { \($ref->$* =~ tr/n-za-mN-ZA-M/a-zA-Z/r) });
  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { name => 'karen', alias => [ 'ether', 'miyu' ] }));

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
            content => {
              name => 'xnera',
              alias => [ 'rgure', 'zvlh' ],
            },
          },
        },
      },
    ],
    'encoding object is applied to each item in the array of repeated values',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                name: {}
                deep_thing:
                  type: array
                things:
                  type: array
                  items:
                    type: [ string, array ]
            encoding:
              name:
                contentType: application/json
              deep_thing:
                style: deepObject
              things:
                prefixEncoding:
                  - contentType: application/json
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { deep_thing => 'a[b]=c' }));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => false,
        errors => [
          {
            instanceLocation => '/request/body/content/deep_thing',
            keywordLocation => jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded encoding deep_thing style)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded encoding deep_thing style)))->to_string,
            error => 'deepObject style can only deserialize to objects',
          },
          {
            instanceLocation => '/request/body/content/deep_thing',
            keywordLocation => jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded schema properties deep_thing type)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded schema properties deep_thing type)))->to_string,
            error => 'got string, not array',
          },
          {
            instanceLocation => '/request/body/content',
            keywordLocation => jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded schema properties)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded schema properties)))->to_string,
            error => 'not all properties are valid',
          },
        ],
      },
      { request => { body => { content => { deep_thing => 'a[b]=c' } } } },
    ],
    'correct error location is used when style-decoding fails',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { name => 'not json', things => '["not json"]' }));

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
            instanceLocation => '/request/body/content/name',
            keywordLocation => jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded encoding name contentType)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded encoding name contentType)))->to_string,
            error => re(qr{^could not decode content as application/json}),
          },
          {
            instanceLocation => '/request/body/content/things/0',
            keywordLocation => jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded encoding things prefixEncoding 0 contentType)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded encoding things prefixEncoding 0 contentType)))->to_string,
            error => re(qr{^could not decode content as application/json}),
          },
        ],
      },
      {
        request => {
          body => {
            content => {
              name => 'not json',
              things => [ 'not json' ],
            },
          },
        },
      },
    ],
    'correct error location is used when media-type decoding an object property or array item fails',
  );


  # see examples in 3.2.0 §4.15.3.1
  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                id:
                  type: string
                  format: uuid
                address:
                  type: object
                  required: [ streetAddress, city, state, zip ]
                  properties: {}
              const:
                id: 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6'
                address:
                  streetAddress: 123 Example Dr.
                  city: Somewhere
                  state: CA
                  zip: 99999+1234
YAML

  $result = $openapi->validate_request($request = request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    {
      id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
      address => $::dumper->encode({
        streetAddress => '123 Example Dr.',
        city => 'Somewhere',
        state => 'CA',
        zip => '99999+1234',
      }),
    },
  ));

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
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              address => {
                streetAddress => '123 Example Dr.',
                city => 'Somewhere',
                state => 'CA',
                zip => '99999+1234',
              },
            },
          },
        },
      },
    ],
    'two-level nested object is deserialized from form-urlencoded, no encoding object',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
components:
  schemas:
    my_schema:
      type: object
      properties:
        id:
          type: string
          format: uuid
        address:
          type: object
          required: [ streetAddress, city, state, zip ]
          properties: {}
      const:
        id: 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6'
        address:
          streetAddress: 123 Example Dr.
          city: Somewhere
          state: CA
          zip: 99999+1234
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              $ref: '#/components/schemas/my_schema'
YAML

  $result = $openapi->validate_request($request);
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      $result_data,
    ],
    'two-level nested object uses schema via $ref to determine types',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                my_object:
                  type: object
                  properties:
                    another_object:
                      type: object
                      required: [ a, b ]
                      properties:
                        a:
                          type: number
                        b:
                          type: string
                        c:
                          type: 'null'
                        d:
                          type: boolean
              const:
                my_object:
                  another_object:
                    a: 1
                    b: '2'
                    c: null
                    d: false
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { my_object => $::dumper->encode({ another_object => { a => '1', b => 2, c => undef, d => '' }}) },
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
            content => {
              my_object => {
                another_object => { a => 1, b => '2', c => undef, d => false },
              },
            },
          },
        },
      },
    ],
    'multi-level nested object is deserialized from form-urlencoded and application/json; terminal values are still coerced',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              patternProperties:
                '^foo':
                  type: object
                  additionalProperties:
                    type: boolean
              additionalProperties:
                type: integer
              const:
                food:
                  x: true
                blah: 42
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { blah => '42', food => $::dumper->encode({ x => '1' }) },
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
            content => { food => { x => true }, blah => 42 },
          },
        },
      },
    ],
    'patternProperties and additionalProperties are followed to find properties in the data',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            encoding:
              address:
                style: deepObject
YAML

  $result = $openapi->validate_request($request = request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    [
      id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
      address => [
        'address[streetAddress]' => '123 Example Dr.',
        'address[city]' => 'Somewhere',
        'address[state]' => 'CA',
        'address[zip]' => '99999+1234'
      ],
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
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              address => {
                streetAddress => '123 Example Dr.',
                city => 'Somewhere',
                state => 'CA',
                zip => '99999+1234',
              },
            },
          },
        },
      },
    ],
    'two-level nested object is deserialized from form-urlencoded, with an encoding object using style',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml((OPENAPI_PREAMBLE =~ s/3\.2/3.1/r).<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            encoding:
              address:
                style: deepObject
                explode: false
YAML

  $result = $openapi->validate_request($request);
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => false,
        errors => [
          {
            instanceLocation => '/request/body/content/address',
            keywordLocation => jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded encoding address explode)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded encoding address explode)))->to_string,
            error => '"explode" cannot be false with style=deepObject',
          },
        ],
      },
      {
        request => {
          body => {
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              address => 'address%5BstreetAddress%5D=123+Example+Dr.&address%5Bcity%5D=Somewhere&address%5Bstate%5D=CA&address%5Bzip%5D=99999%2B1234',
            },
          },
        },
      },
    ],
    'error encountered in encoding object using style',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    validate_content_schemas => 1,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            encoding:
              icon:
                contentType: image/png
YAML

  $result = $openapi->validate_request($request = request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    'name=example&icon='.($raw_image =~ s/=/%3D/gr)));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      { request => {
          body => {
            content => {
              name => 'example',
              icon => $raw_image,
            },
          },
        },
      },
    ],
    'no error due to decoder being undefined, as there is no schema; image is returned raw',
  );


  # 4.15.3.2 Example: URL Encoded Form with Binary Values
  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    validate_content_schemas => 1,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                name:
                  type: string
                icon:
                  # The default content type with `contentEncoding` present
                  # is `application/octet-stream`, so we need to set the correct
                  # image media type(s) in the Encoding Object.
                  type: string
                  contentEncoding: base64url
                  contentSchema:
                    type: string
                    pattern: "^\x89PNG\x0D\x0A\x1A\x0A"
            encoding:
              icon:
                contentType: image/png
YAML

  $result = $openapi->validate_request($request);

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
            instanceLocation => '/request/body/content/icon',
            keywordLocation => jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded encoding icon contentType)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded encoding icon contentType)))->to_string,
            error => re(qr{unsupported media type \"image/png\"}),
          },
        ],
      },
      {},
    ],
    'error location is correct for encoding error; decoded data is not returned because we aborted',
  );

  add_media_type('image/*', sub ($x) { $x });
  $result = $openapi->validate_request($request);
  delete_media_type('image/*');

  cmp_result(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      { request => {
          body => {
            content => {
              name => 'example',
              icon => re(qr/^\x89PNG\x0D\x0A\x1A\x0A/),
            },
          },
        },
      },
    ],
    'successfully deserialized binary data using an encoding object',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                id:
                  type: string
                  format: uuid
                address:
                  type: object
                  required: [ streetAddress, city, state, zip ]
              const:
                id: 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6'
                address:
                  streetAddress: 123 Example Dr.
                  city: Somewhere
                  state: CA
                  zip: 99999+1234
            encoding:
              address:
                style: form
                # explode defaults to true
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    {
      id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
      address => {
        streetAddress => '123 Example Dr.',
        city => 'Somewhere',
        state => 'CA',
        zip => '99999+1234',
      },
    },
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
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              address => {
                streetAddress => '123 Example Dr.',
                city => 'Somewhere',
                state => 'CA',
                zip => '99999+1234',
              },
            },
          },
        },
      },
    ],
    'two-level nested object is deserialized from form-urlencoded, no encoding object',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                id:
                  type: string
                  format: uuid
                address:
                  type: object
                  properties:
                    streetAddress:
                      type: object
                      properties:
                        number:
                          type: number
                        name:
                          type: string
                        type:
                          type: string
              const:
                id: 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6'
                address:
                  streetAddress:
                    number: 123
                    name: Example
                    type: Dr.
                  city: Somewhere
                  state: CA
                  zip: 99999+1234
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    {
      id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
      address => $::dumper->encode({
        streetAddress => $::dumper->encode({
          number => 123,
          name => 'Example',
          type => 'Dr.',
        }),
        city => 'Somewhere',
        state => 'CA',
        zip => '99999+1234',
      }),
    },
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
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              address => {
                streetAddress => {
                  number => 123,
                  name => 'Example',
                  type => 'Dr.',
                },
                city => 'Somewhere',
                state => 'CA',
                zip => '99999+1234',
              },
            },
          },
        },
      },
    ],
    'two-level nested object, with schema to coerce property to number; no encoding object',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            encoding:
              address:
                contentType: application/json
              streetAddress:
                style: deepObject
                explode: false
YAML

  $result = $openapi->validate_request($request = request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    {
      id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
      address => $::dumper->encode({
        city => 'Somewhere',
        state => 'CA',
        zip => '99999+1234',
      }),
      streetAddress => {
        'streetAddress[number]' => 123,
        'streetAddress[name]' => 'Example',
        'streetAddress[type]' => 'Dr.',
      },
    },
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
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              address => {
                city => 'Somewhere',
                state => 'CA',
                zip => '99999+1234',
              },
              streetAddress => {
                number => '123',    # we don't know that this is supposed to be a number
                name => 'Example',
                type => 'Dr.',
              },
            },
          },
        },
      },
    ],
    'two-level nested object, with no schema, but encoding object',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                id:
                  type: string
                  format: uuid
                address:
                  type: object
                streetAddress:
                  type: object
                  properties:
                    number:
                      type: number
                    name:
                      type: string
                    type:
                      type: string
              const:
                id: 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6'
                address:
                  city: Somewhere
                  state: CA
                  zip: 99999+1234
                streetAddress:
                  number: 123
                  name: Example
                  type: Dr.
            encoding:
              address:
                contentType: application/json
              streetAddress:
                style: deepObject
                explode: false
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
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              address => {
                city => 'Somewhere',
                state => 'CA',
                zip => '99999+1234',
              },
              streetAddress => {
                number => 123,    # now we know that this is supposed to be a number
                name => 'Example',
                type => 'Dr.',
              },
            },
          },
        },
      },
    ],
    'two-level nested object, with encoding object and schema',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                id:
                  type: string
                  format: uuid
                address:
                  type: array
                  prefixItems:
                    - type: number  # streetAddress number
                  items:
                    type: string
              const:
                id: 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6'
                address:
                  - 123
                  - Example
                  - Dr.
                  - Somewhere
                  - CA
                  - 99999+1234
            encoding:
              address:
                # style defaults to form
                explode: false
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    {
      id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
      address => 'address='.join(',', '123', 'Example,Dr.', 'Somewhere', 'CA', '99999%2B1234'),
    },
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
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              address => [ 123, 'Example', 'Dr.', 'Somewhere', 'CA', '99999+1234' ],
            },
          },
        },
      },
    ],
    'object containing an array is deserialized from form=urlencoded, with style encoding',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                id:
                  type: string
                thing:
                  type: array
                  prefixItems:
                    - type: array
                      prefixItems:
                        - type: number    # json contains a string "6"; this will numify
                      items:
                        type: string
              const:
                id: '123'
                thing: [ [ 6, v, w ], x, y, z ]
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    [
      id => '123',
      thing => $::dumper->encode([ $::dumper->encode(['6', 'v', 'w']), 'x', 'y', 'z' ])
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
            content => {
              id => '123',
              thing => [ [ 6, 'v', 'w' ], 'x', 'y', 'z' ],
            },
          },
        },
      },
    ],
    'object containing nested arrays is deserialized using default application/json',
  );


  add_media_type('text/add1' => sub ($ref) { \($ref->$* + 1) });

  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                thing:
                  type: array
                  prefixItems:
                    - type: array
                      prefixItems:
                        - {}  # no numification here, but text/add1 will numify
                      items:
                        type: string
              const:
                thing: [ [ 7, v, w ], x, y, z ]
            encoding:
              thing:
                explode: true
                # style defaults to form - same as contentType application/x-www-form-urlencoded
                # due to style decoding, we use type: array to deserialize to an array
                prefixEncoding:
                  - # default is contentType: application/json     # /thing/0
                    prefixEncoding:
                      - contentType: text/add1        # /thing/0/0
                    itemEncoding:
                      contentType: text/rot13         # /thing/0/1..
                itemEncoding:
                  contentType: text/rot13             # /thing/1..
YAML

  $result = $openapi->validate_request($request = request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    {
      thing => {
        thing => [
          $::dumper->encode([ '6', 'i', 'j' ]),
          'k',
          'l',
          'm',
        ],
      },
    },
  ));

  # one level of decoding gives us:
  # { 'thing' => 'thing=%5B%226%22%2C%22i%22%2C%22j%22%5D&thing=k&thing=l&thing=m' }
  # property "thing" style-deserializes to [ '["6","i","j"]', 'k', 'l', 'm' ];
  # item "thing/0" application/json-deserializes to [ '6', 'i', 'j' ]
  # item "thing/0", after decoding all items, is now:  [ 7, 'v', 'w' ]
  # item "thing", after decoding all items, is now:  [ [ 7, 'v', 'w' ], 'x', 'y', 'z' ]

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
            content => { thing => [ [ 7, 'v', 'w' ], 'x', 'y', 'z' ] },
          },
        },
      },
    ],
    'object containing nested arrays is deserialized using encoding objects',
  );


  # same specification as before, except missing some encoding objects
  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                thing:
                  type: array
                  prefixItems:
                    - type: array
                      items:
                        type: string
                      # since we don't have text/add1 to numify, 6 remains a string
              const:
                thing: [ [ '6', i, j ], k, l, m ]
            encoding:
              thing:
                explode: true
                # style defaults to form - same as contentType application/x-www-form-urlencoded
                # due to style decoding, we use type: array to deserialize to an array
                # There no prefixEncoding/itemEncoding here to show how to go further, but
                # the default default is contentType: application/json
YAML

  $result = $openapi->validate_request($request);

  # one level of decoding gives us:
  # { 'thing' => 'thing=%5B%226%22%2C%22i%22%2C%22j%22%5D&thing=k&thing=l&thing=m' }
  # property "thing" style-deserializes to [ '["6","i","j"]', 'k', 'l', 'm' ];
  # and now we can't go any further, because we ran out of encoding objects

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
            content => { thing => [ [ '6', 'i', 'j' ], 'k', 'l', 'm' ] },
          },
        },
      },
    ],
    'object containing nested arrays is not fully deserialized, due to lack of some encoding objects',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                id:
                  type: string
                  format: uuid
                address:
                  type: object
                  properties:
                    streetAddress:
                      type: array
                      minItems: 3
                      maxItems: 3
                      prefixItems:
                        - type: number
                        - type: string
                        - type: string
              const:
                id: 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6'
                address:
                  streetAddress:
                    - 123
                    - Example
                    - Dr.
                  city: Somewhere
                  state: CA
                  zip: 99999+1234
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    [
      id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
      address => $::dumper->encode({
        streetAddress => $::dumper->encode([ '123', 'Example', 'Dr.' ]),
        city => 'Somewhere',
        state => 'CA',
        zip => '99999+1234'
      }),
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
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              address => {
                streetAddress => [
                  123,
                  'Example',
                  'Dr.',
                ],
                city => 'Somewhere',
                state => 'CA',
                zip => '99999+1234',
              },
            },
          },
        },
      },
    ],
    'nested arrays within object, with schema to coerce array item to number; no encoding object',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
components:
  schemas:
    Address:
      # intentionally does not use type, so this schema will not fail if
      # it is applied to an array instead of an object
      properties:
        streetAddress:
          type: string
        city:
          type: string
        state:
          type: string
        zip:
          type: string
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                # when addresses is an array, the Encoding Object is applied
                # to each item individually and determines the default content type
                # based on the type in the `items` subschema, which in this example
                # is an object, so the default content type for each item is
                # `application/json`
                # This construct will deserialize correctly whether the part name is
                # used twice in the request, or if both addresses are json-encoded
                # together as a single array
                addresses:
                  type: [ object, array ]
                  $ref: '#/components/schemas/Address'
                  items:
                    type: object
                    $ref: '#/components/schemas/Address'
            examples:
              example1:
                summary: a single address value
                description: |
                  addresses appears in the request body as a single value named "addresses"
                dataValue:
                  addresses:
                    streetAddress: 123 Example Dr
                    city: Somewhere
                    state: CA
                    zip: 99999+1234
                serializedValue: address={"city":"Somewhere","state":"CA","streetAddress":"123 Example Dr","zip":"99999+1234"}
              example2:
                summary: multiple address values, each encoded separately
                description: |
                  Depending on whether the serializer works independently of
                  the OpenAPI specification or not, the "addresses" data can
                  appear in the request body as either:
                  - two values, each named "addresses" whose value is a
                  json-encoded object containing data for a single address,
                  - or in the form shown in the next example..
                dataValue:
                  addresses:
                    - streetAddress: 123 Example Dr
                      city: Somewhere
                      state: CA
                      zip: 99999+1234
                    - streetAddress: 996 Orchard Dr
                      city: Lillooet
                      state: BC
                      zip: V0K 1V0
                serializedValue: addresses={"city":"Somewhere","state":"CA","streetAddress":"123 Example Dr","zip":"99999+1234"}&addresses={"city":"Lillooet","state":"BC","streetAddress":"996 Orchard Dr","zip":"V0K 1V0"}
              example3:
                summary: multiple addresses, encoded together as one value
                description: |
                  When encoded as a single value named "addresses" whose value
                  is a json-encoded array of two objects, the dataValue is the
                  same as in the last example, but the serialized form differs:
                serializedValue: addresses=[{"city":"Somewhere","state":"CA","streetAddress":"123 Example Dr","zip":"99999+1234"},{"city":"Lillooet","state":"BC","streetAddress":"996 Orchard Dr","zip":"V0K 1V0"}]
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    'addresses={"city":"Somewhere","state":"CA","streetAddress":"123 Example Dr","zip":"99999%2B1234"}',
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
            content => {
              addresses => { streetAddress => '123 Example Dr', city => 'Somewhere', state => 'CA', zip => '99999+1234' },
            },
          },
        },
      },
    ],
    'example1: urlencoded content with a single value',
  );


  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    'addresses={"city":"Somewhere","state":"CA","streetAddress":"123 Example Dr","zip":"99999%2B1234"}&addresses={"city":"Lillooet","state":"BC","streetAddress":"996 Orchard Dr","zip":"V0K 1V0"}',
  ));

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
            content => {
              addresses => [
                { streetAddress => '123 Example Dr', city => 'Somewhere', state => 'CA', zip => '99999+1234' },
                { streetAddress => '996 Orchard Dr', city => 'Lillooet', state => 'BC', zip => 'V0K 1V0' },
              ],
            },
          },
        },
      },
    ],
    'example2: urlencoded content is deserialized to an object with duplicate names',
  );


  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    'addresses=[{"city":"Somewhere","state":"CA","streetAddress":"123 Example Dr","zip":"99999%2B1234"},{"city":"Lillooet","state":"BC","streetAddress":"996 Orchard Dr","zip":"V0K 1V0"}]',
  ));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      $result_data,
    ],
    'example3: urlencoded content is deserialized to an object with repeated names encoded together as one part',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                thing:
                  type: [ array, object ]
                  items:
                    type: object
                    additionalProperties:
                      type: number
                    const: { x: 4, y: 5 }
                  additionalProperties:
                    type: number
                  enum:
                    - [ { x: 4, y: 5 }, { x: 4, y: 5 } ]
                    - { x: 4, y: 5 }
              enum:
                - { thing: [ { x: 4, y: 5 }, { x: 4, y: 5 } ] }
                - { thing: { x: 4, y: 5 } }
            encoding:
              thing:
                style: form
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    [ (thing => { x => 4, y => 5 })x2 ]
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
            content => { thing => [ { x => 4, y => 5 }, { x => 4, y => 5 } ] },
          },
        },
      },
    ],
    'encoded array inside data with duplicate name',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { thing => { x => 4, y => 5 } },
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
            content => { thing => { x => 4, y => 5 } },
          },
        },
      },
    ],
    'encoded object inside data with just one encoded string value',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                thing:
                  type: object
                  additionalProperties:
                    $ref: 'https://example.com/does_not_exist'
            encoding:
              thing:
                style: form
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { thing => { x => 4 } },
  ));

  is_equal(
    $result->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/body/content/thing/x',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded schema properties thing additionalProperties $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded schema properties thing additionalProperties $ref)))->to_string,
          error => 'EXCEPTION: unable to find resource "https://example.com/does_not_exist"',
        },
      ],
    },
    'error inside style decoding: locations are correct',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                alpha: true
                beta: false
YAML

  my $yatta_encoded = Encode::encode('Shift_JIS', 'やった');

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { alpha => $yatta_encoded, beta => $yatta_encoded }));  # Shift_JIS: not decodable as UTF-8

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      {
        valid => false,
        errors => [
          {
            instanceLocation => '/request/body/content/beta',
            keywordLocation => jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded schema properties beta)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded schema properties beta)))->to_string,
            error => 'property not permitted',
          },
          {
            instanceLocation => '/request/body/content',
            keywordLocation => jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded schema properties)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/x-www-form-urlencoded schema properties)))->to_string,
            error => 'not all properties are valid',
          },
        ],
      },
      {
        request => {
          body => {
            content => {
              alpha => $yatta_encoded,
              beta => $yatta_encoded,
            },
          },
        },
      },
    ],
    # schema = false comes back as 'string' from _type_in_schema, which means text/plain + charset
    # decoding is applied to the property
    'property with false schema is not attempted to be decoded as a string',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                thing:
                  type: object
            encoding:
              thing:
                encoding:
                  foo:
                    # 3.2.0 4.15.1.2: "This field SHALL be ignored if the media type
                    # is not application/x-www-form-urlencoded or multipart/form-data."
                    style: form
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    [ thing => '{"foo":"foo=bar"}' ],
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
            content => {
              thing => {
                foo => 'foo=bar',   # NOT 'bar'
              },
            },
          },
        },
      },
    ],
    'style-encoded content embedded within another encoded string is not decoded',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                thing:
                  type: object
                  properties:
                    subthing:
                      type: object
                      properties:
                        tiny_thing:
                          type: object
                          const: { a: b, c: d }
            encoding:
              thing:
                contentType: application/json
                encoding:
                  subthing:
                    contentType: application/x-www-form-urlencoded
                    encoding:
                      tiny_thing:
                        style: form
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    { thing => '{"subthing":"tiny_thing=a%3Db%26c%3Dd"}' },
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
            content => {
              thing => {
                subthing => {
                  tiny_thing => {
                    a => 'b', c => 'd',
                  },
                },
              },
            },
          },
        },
      },
    ],
    'style-encoded content will be decoded when inside an urlencoded form embedded within another urlencoded form',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            encoding:
              thing:
                contentType: text/rot13
              forms:
                contentType: application/x-www-form-urlencoded
                encoding:
                  thing:
                    contentType: text/rot13
                  forms:
                    contentType: application/x-www-form-urlencoded
                    encoding:
                      thing:
                        contentType: text/rot13
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    [
      forms => { forms => { thing => [ 'alpha', 'beta' ] } },
      forms => { forms => { thing => [ 'gamma', 'delta' ] } },
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
            content => {
              forms => [
                { forms => { thing => [ 'nycun', 'orgn' ] } },
                { forms => { thing => [ 'tnzzn', 'qrygn' ] } },
               ],
            },
          },
        },
      },
    ],
    'forms can be embedded within forms, and duplicate names handled at each level',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object      # from urlencoded string
              properties:
                thing:
                  type: object  # from json-encoded string
                  properties:
                    thing2:     # from urlencoded string
                      type: object
                      properties:
                        thing3:
                          type: object    # from form-style-encoded string
                          const: { a: '1', b: '2' }
            encoding:
              thing:
                contentType: application/json
                encoding:
                  thing2:
                    contentType: application/x-www-form-urlencoded
                    encoding:
                      thing3:
                        style: form   # this is valid as the container is urlencoded
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
    'thing={"thing2":"thing3%3Da%253D1%2526b%253d2"}'));

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
            content => {
              thing => { thing2 => { thing3 => { a => '1', b => '2' } } },
            },
          },
        },
      },
    ],
    'style-encoded content is decoded when inside a doubly-form-encoded string',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              properties:
                x:
                  type: boolean
            encoding:
              x:
                style: form   # to test that the encoding property is seen
                headers:
                  X-Test:
                    required: true
                    schema: true
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/x-www-form-urlencoded' ], { x => 1 }));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      {
        request => { body => { content => { x => true } } },
      },
    ],
    '"headers" object is not used for validation for non-multipart content',
  );
};

if (++$type_index < @::TYPES) {
  bail_if_not_passing if $ENV{AUTHOR_TESTING};
  goto START;
}

done_testing;
