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
use Test2::Warnings qw(:no_end_test allow_patterns disallow_patterns had_no_warnings);
use JSON::Schema::Modern::Utilities qw(jsonp add_media_type);
use OpenAPI::Modern::Utilities 'elem';
use Mojo::UserAgent::Transactor;

my $doc_uri_rel = Mojo::URL->new('/api');
my $doc_uri = $doc_uri_rel->to_abs(Mojo::URL->new('http://example.com'));

my $raw_image = 'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAABGdBTUEAALGPC_xhBQAAADhlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAAAAqADAAQAAAABAAAAAgAAAADO0J6QAAAAEElEQVQIHWP8zwACTGCSAQANHQEDqtPptQAAAABJRU5ErkJggg==';

my $yatta_encoded = Encode::encode('Shift_JIS', 'やった');

add_media_type('text/to_upper' => sub ($ref) { \($ref->$* =~ tr/a-z/A-Z/r) });

my $type_index = 0;

START:
$::TYPE = $::TYPES[$type_index];
note 'REQUEST/RESPONSE TYPE: '.$::TYPE;

subtest $::TYPE.': corrupt multipart/form-data' => sub {
  skip_all 'Plack insists on parsing a multipart/form-data message body'
    if elem($::TYPE, [qw(plack catalyst dancer2)]);

  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /supported:
    post:
      requestBody:
        content:
          multipart/form-data: {}
YAML

  my $result = $openapi->validate_request(request('POST', 'http://example.com/supported',
    [ 'Content-Type' => 'multipart/form-data; boundary=BLOOP' ], '!!!'));

  my $todo = todo 'lwp parses this message badly' if $::TYPE eq 'lwp';

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
            keywordLocation => jsonp(qw(/paths /supported post requestBody content multipart/form-data)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /supported post requestBody content multipart/form-data)))->to_string,
            error => re(qr{^could not decode content as multipart/form-data; boundary=BLOOP: body is not multipart}),
          },
        ],
      },
      {},
    ],
    'corrupt multipart/form-data messages (not multipart) are properly handled',
  );

  undef $todo;

  my $content = Mojo::Content::MultiPart->new(parts => [
    map Mojo::Content::Single->new->asset(Mojo::Asset::Memory->new->add_chunk($_)), 1..2
  ]);
  $content->headers->content_type('multipart/form-data');
  $content->build_boundary;
  $content->headers->content_length($content->body_size);

  my $request;

  if ($::TYPE eq 'mojo') {
    $request = Mojo::Message::Request->new(method => 'POST', url => Mojo::URL->new('http://example.com/supported'));
    $request->content($content);
  }
  else {
    $request = request('POST', 'http://example.com/supported');
    $request->headers->push_header(@$_) foreach pairs $content->headers->to_hash('multi')->%*;
    $request->content(_multipart_body_string($content));
  }

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
            instanceLocation => '/request/body',
            keywordLocation => jsonp(qw(/paths /supported post requestBody content multipart/form-data)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /supported post requestBody content multipart/form-data)))->to_string,
            error => re(qr{^could not decode content as multipart/form-data; boundary=.+: missing Content-Disposition}),
          },
        ],
      },
      {},
    ],
    'corrupt multipart/form-data messages (missing Content-Disposition) are properly handled',
  );


  if ($::TYPE eq 'mojo') {
    $request = Mojo::UserAgent::Transactor->new->tx(POST => 'http://example.com/supported',
      { 'Content-Type' => 'multipart/form-data' }, form => { alpha => '42' })->req;
    $request->fix_headers;
  }
  elsif ($::TYPE eq 'lwp') {
    test_needs('HTTP::Request::Common');
    $request = HTTP::Request::Common::POST('http://example.com/supported',
      'Content-Type' => 'multipart/form-data', Content => [ alpha => '42' ]);
  }

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
            header => [ { 'Content-Disposition' => 'form-data; name="alpha"' } ],
            content => { alpha => '42' },
          },
        },
      },
    ],
    'multipart/form-data messages with a real multipart body are valid if there is no body schema',
  );
};

subtest $::TYPE.': multipart/form-data deserialization' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /empty_media_type:
    post:
      requestBody:
        content:
          multipart/form-data: {}
  /empty_schema:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema: true
  /itemSchema:
    post:
      requestBody:
        content:
          multipart/form-data:
            itemSchema: true
  /encoding_no_schema:
    post:
      requestBody:
        content:
          multipart/form-data:
            encoding:
              x:
                contentType: text/to_upper
  /nested_encoding_no_schema:
    post:
      requestBody:
        content:
          multipart/form-data:
            encoding:
              x:
                itemEncoding:
                  contentType: text/to_upper
YAML

  my $result = $openapi->validate_request(request('POST', 'http://example.com/empty_media_type',
    [ 'Content-Type' => 'multipart/form-data' ],
    my $body = [
      [ x => '{"id":"123"}' ],
      [ x => '{"address":"42"}' ],
      [ x => '{"secret":"hello"}' ],
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
            header => [
              ({ 'Content-Disposition' => 'form-data; name="x"' })x3,
            ],
            content => {
              x => [ '{"id":"123"}', '{"address":"42"}', '{"secret":"hello"}' ],
            },
          },
        },
      },
    ],
    'message parts are returned as-is in an object when there is no schema or encoding object',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/empty_schema',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      $result_data,
    ],
    'message parts are returned as-is in an object when there is an empty schema',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/itemSchema',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

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
            header => [ ({ 'Content-Disposition' => 'form-data; name="x"' })x3 ],
            content => [
              { x => '{"id":"123"}' },
              { x => '{"address":"42"}' },
              { x => '{"secret":"hello"}' },
            ],
          },
        },
      },
    ],
    'message parts are returned as-is as an array when there is an empty itemSchema',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/empty_media_type',
    [ 'Content-Type' => 'multipart/form-data' ],
    [
      [ x => [ '{"id":123}', '{"address":42}' ], 'Content-Type' => 'application/json' ],
      [ x => '{"secret":true}', 'Content-Type' => 'application/json' ],
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
            header => [ ({ 'Content-Disposition' => 'form-data; name="x"', 'Content-Type' => 'application/json' })x3 ],
            content => {
              x => [ { id => 123 }, { address => 42 }, { secret => true } ],
            },
          },
        },
      },
    ],
    'message parts are json-decoded via Content-Type header, even without any schema or encoding object',
  );


  $result = $openapi->validate_request(request('POST', 'http://example.com/encoding_no_schema',
    [ 'Content-Type' => 'multipart/form-data' ],
    [ [ x => [ 'Hello, world!' ] ] ]));

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
            header => [ { 'Content-Disposition' => 'form-data; name="x"' } ],
            content => { x => 'HELLO, WORLD!' },
          },
        },
      },
    ],
    'encoding is still respected when there is no schema for that part of the data',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/nested_encoding_no_schema',
    [ 'Content-Type' => 'multipart/form-data' ],
    [ [ x => '["Hello","World!"]', 'Content-Type' => 'application/json' ] ]));

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
            header => [ { 'Content-Disposition' => 'form-data; name="x"', 'Content-Type' => 'application/json' } ],
            content => { x => [ 'HELLO', 'WORLD!' ] },
          },
        },
      },
    ],
    'itemEncoding is still respected when there is no schema for that part of the data',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
components:
  headers:
    multipart:
      content:
        multipart/form-data: {}
  parameters:
    multipart:
      in: header
      name: X-Test
      content:
        multipart/form-data: {}
  requestBodies:
    multipart:
      content:
        multipart/form-data:
          encoding:
            a:
              headers:
                X-Test:
                  $ref: '#/components/headers/multipart'
paths:
  /foo:
    post:
      parameters:
        - $ref: '#/components/parameters/multipart'
      requestBody:
        $ref: '#/components/requestBodies/multipart'
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/form-data', 'X-Test' => 1 ], [ [ a => 1, 'X-Test' => 1 ] ]));

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
            instanceLocation => '/request/header/X-Test',
            keywordLocation => jsonp(qw(/paths /foo post parameters 0 $ref content)),
            absoluteKeywordLocation => $doc_uri->clone->fragment('/components/parameters/multipart/content')->to_string,
            error => 'multipart content is not permitted outside request and response bodies',
          },
          {
            instanceLocation => '/request/body/header/0/X-Test',
            keywordLocation => jsonp(qw(/paths /foo post requestBody $ref content multipart/form-data encoding a headers X-Test $ref content)),
            absoluteKeywordLocation => $doc_uri->clone->fragment('/components/headers/multipart/content')->to_string,
            error => 'multipart content is not permitted outside request and response bodies',
          },
        ],
      },
      {
        request => {
          body => {
            header => [ { 'Content-Disposition' => 'form-data; name="a"', 'X-Test' => '1' } ],
            content => { 'a' => '1' },
          },
        },
      },
    ],
    'multipart/form-data cannot be used in parameters',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      parameters:
        - in: header
          name: X-Test
          required: true
          schema:
            const: yes
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: array
              prefixItems:
                - type: object
                  properties:
                    id:
                      # default content type for a string without `contentEncoding` is `text/plain`
                      type: string
                      format: uuid
                - type: object
                  properties:
                    # default content type for a schema without `type` is `application/octet-stream`
                    profileImage: {}
                - type: object
                  properties:
                    address:
                      # each property is an object, so the default content type
                      # for each is `application/json`
                      type: object
                      properties:
                        streetAddress:
                          type: string
                        city:
                          type: string
                        state:
                          type: string
                        zip:
                          type: string
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/form-data', 'X-Test' => 'yes' ],
    [
      [ id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6', 'X-Alpha' => 'foo' ],
      [ profileImage => $raw_image, 'X-Beta' => 'bar' ],
      [ address => $::dumper->encode(
        { streetAddress => '123 Example Dr', city => 'Somewhere', state => 'CA', zip => '99999+1234' }),
        'X-Gamma' => 'bloop', 'X-Gamma' => 'blup' ],
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
          header => { 'X-Test' => 'yes' },
          body => {
            header => [
              { 'Content-Disposition' => 'form-data; name="id"', 'X-Alpha' => 'foo' },
              { 'Content-Disposition' => 'form-data; name="profileImage"', 'X-Beta' => 'bar' },
              { 'Content-Disposition' => 'form-data; name="address"', 'X-Gamma' => [ 'bloop', 'blup' ] },
            ],
            content => [
              { id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6' },
              { profileImage => $raw_image },
              { address => { streetAddress => '123 Example Dr', city => 'Somewhere', state => 'CA', zip => '99999+1234' } },
            ],
          },
        },
      },
    ],
    'multipart/form-data content is deserialized to an array of objects',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          multipart/form-data:
            itemSchema:
              type: object
              properties:
                alpha:
                  type: boolean
                beta:
                  type: boolean
                gamma:
                  type: object
            itemEncoding:
              encoding:
                gamma:
                  # style defaults to form
                  explode: false
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/form-data' ],
    [
      [ alpha => '0', 'X-Alpha' => 'foo' ],
      [ beta => '1', 'X-Beta' => 'bar' ],
      [ gamma => 'a,b,x,y', 'X-Gamma' => 'baz' ],
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
              { 'Content-Disposition' => 'form-data; name="alpha"', 'X-Alpha' => 'foo' },
              { 'Content-Disposition' => 'form-data; name="beta"', 'X-Beta' => 'bar' },
              { 'Content-Disposition' => 'form-data; name="gamma"', 'X-Gamma' => 'baz' },
            ],
            content => [
              { alpha => false },
              { beta => true },
              { gamma => { a => 'b', x => 'y' } },
            ],
          },
        },
      },
    ],
    'multipart/form-data content is deserialized to an array of objects, using itemSchema and an encoding object',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                # default content type for a string without `contentEncoding`
                # is `text/plain`
                id:
                  type: string
                  format: uuid

                # default content type for a schema without `type`
                # is `application/octet-stream`
                profileImage: {}
            examples:
              example:
                dataValue:
                  id: f81d4fae-7dec-11d0-a765-00a0c91e6bf6
                  profileImage: ... octets ...
                serializedValue: |
                  --KJvXX
                  Content-Disposition:: form-data; name="id"

                  f81d4fae-7dec-11d0-a765-00a0c91e6bf6
                  --KJvXX
                  Content-Disposition:: form-data; name="profileImage"

                  ... octets ...
                  --KJvXX
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/form-data' ],
    [
      [ id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6', 'X-Alpha' => 'foo' ],
      [ profileImage => $raw_image, 'X-Beta' => 'bar' ],
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
              { 'Content-Disposition' => 'form-data; name="id"', 'X-Alpha' => 'foo' },
              { 'Content-Disposition' => 'form-data; name="profileImage"', 'X-Beta' => 'bar' },
            ],
            content => {
              id => 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
              profileImage => $raw_image,
            },
          },
        },
      },
    ],
    'multipart/form-data content is deserialized to an object when the schema requests it',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<"YAML"));
components:
  examples:
    # the serialized format is the same for both endpoints
    serialized_example_without_charset:
      serializedValue: |
        --KJvXX
        Content-Disposition: form-data; name="yatta"

        $yatta_encoded
        --KJvXX
        Content-Disposition: form-data; name="yatta2"

        $yatta_encoded
        --KJvXX
        Content-Disposition: form-data; name="yatta2"

        $yatta_encoded
        --KJvXX
    serialized_example_with_charset:
      serializedValue: |
        --KJvXX
        Content-Disposition: form-data; name="yatta"

        $yatta_encoded
        --KJvXX
        Content-Disposition: form-data; name="yatta2"

        $yatta_encoded
        --KJvXX
        Content-Disposition: form-data; name="yatta2"

        $yatta_encoded
        --KJvXX
        Content-Disposition: form-data; name="_charset_"

        Shift_JIS
        --KJvXX
paths:
  /object:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                # default content type for a string without `contentEncoding`
                # is `text/plain`; charset is respected when provided
                yatta:
                  type: string
                yatta2:
                  type: [ array, string ]
                  items:
                    type: string
                _charset_: false    # we do not expect to see this in the final data
            examples:
              serialized_example_with_charset:
                \$ref: '#/components/examples/serialized_example_with_charset'
              serialized_example_without_charset:
                \$ref: '#/components/examples/serialized_example_without_charset'
              object_example:
                dataValue:
                  yatta: やった
                  yatta2: [ やった, やった ]
  /array:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: array
              items:
                type: object
                properties:
                  yatta:
                    type: string
                  yatta2:
                    type: string
                  _charset_: false
            examples:
              serialized_example_with_charset:
                \$ref: '#/components/examples/serialized_example_with_charset'
              serialized_example_without_charset:
                \$ref: '#/components/examples/serialized_example_without_charset'
              array_example:
                dataValue:
                  - yatta: やった
                  - yatta2: やった
                  - yatta2: やった
YAML

  allow_patterns(my $dancer_pattern = qr/Invalid UTF-8 in body parameters; leaving bytes unchanged/)
    if $::TYPE eq 'dancer2';

  $result = $openapi->validate_request(request('POST', 'http://example.com/object',
    [ 'Content-Type' => 'multipart/form-data' ],
    $body = [
      [ yatta => $yatta_encoded ],
      [ _charset_ => 'Shift_JIS' ],
      [ yatta2 => [ ($yatta_encoded)x2 ] ],
    ],
  ));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      my $object_data = {
        request => {
          body => {
            header => [
              { 'Content-Disposition' => 'form-data; name="yatta"' },
              ({ 'Content-Disposition' => 'form-data; name="yatta2"' })x2,
            ],
            content => {
              yatta => 'やった',
              yatta2 => [ ('やった')x2 ],
            },
          },
        },
      },
    ],
    'multipart/form-data decoding respects the _charset_ named part for objects',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      my $array_data = {
        request => {
          body => {
            header => [
              { 'Content-Disposition' => 'form-data; name="yatta"' },
              ({ 'Content-Disposition' => 'form-data; name="yatta2"' })x2,
            ],
            content => [
              { yatta => 'やった' },
              ({ yatta2 => 'やった' })x2,
            ],
          },
        },
      },
    ],
    'multipart/form-data decoding respects the _charset_ named part for arrays',
  );


  $result = $openapi->validate_request(request('POST', 'http://example.com/object',
    [ 'Content-Type' => 'multipart/form-data' ],
    $body = [
      [ yatta => $yatta_encoded, 'Content-Type' => 'text/plain; charset=Shift_JIS' ],
      [ yatta2 => [ ($yatta_encoded)x2 ], 'Content-Type' => 'text/plain; charset=Shift_JIS' ],
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
              {
                'Content-Type' => 'text/plain; charset=Shift_JIS',
                'Content-Disposition' => 'form-data; name="yatta"',
              },
              ({
                'Content-Type' => 'text/plain; charset=Shift_JIS',
                'Content-Disposition' => 'form-data; name="yatta2"',
              })x2,
            ],
            $object_data->{request}{body}->%{content},
          },
        },
      },
    ],
    'multipart/form-data decoding uses just Content-Type, for object',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

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
              {
                'Content-Type' => 'text/plain; charset=Shift_JIS',
                'Content-Disposition' => 'form-data; name="yatta"',
              },
              ({
                'Content-Type' => 'text/plain; charset=Shift_JIS',
                'Content-Disposition' => 'form-data; name="yatta2"',
              })x2,
            ],
            $array_data->{request}{body}->%{content},
          },
        },
      },
    ],
    'multipart/form-data decoding uses just Content-Type, for array',
  );


  $result = $openapi->validate_request(request('POST', 'http://example.com/object',
    [ 'Content-Type' => 'multipart/form-data' ],
    $body = [
      [ yatta => $yatta_encoded ],
      [ yatta2 => [ ($yatta_encoded)x2 ] ],
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
              { 'Content-Disposition' => 'form-data; name="yatta"' },
              ({ 'Content-Disposition' => 'form-data; name="yatta2"' })x2,
            ],
            content => {
              yatta => $yatta_encoded,
              yatta2 => [ ($yatta_encoded)x2 ],
            },
          },
        },
      },
    ],
    'multipart/form-data decoding fails due to lack of charset, for object',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

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
              { 'Content-Disposition' => 'form-data; name="yatta"' },
              ({ 'Content-Disposition' => 'form-data; name="yatta2"' })x2,
            ],
            content => [
              { yatta => $yatta_encoded },
              ({ yatta2 => $yatta_encoded })x2,
            ],
          },
        },
      },
    ],
    'multipart/form-data decoding fails due to lack of charset, for array',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /object:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                yatta:
                  type: [ array, string ]
                  items:
                    type: string
                yatta2:
                  type: [ array, string ]
                  items:
                    type: string
            encoding:
              yatta:
                contentType: text/plain; charset=Shift_JIS
              yatta2:
                contentType: text/plain; charset=Shift_JIS
  /array:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: array
              items:
                type: object
                properties:
                  yatta:
                    type: string
                  yatta2:
                    type: string
            itemEncoding:
              encoding:
                yatta:
                  contentType: text/plain; charset=Shift_JIS
                yatta2:
                  contentType: text/plain; charset=Shift_JIS
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/object',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      $object_data,
    ],
    'multipart/form-data decoding uses contentType for objects',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      $array_data,
    ],
    'multipart/form-data decoding uses contentType for arrays',
  );


  $result = $openapi->validate_request(request('POST', 'http://example.com/object',
    [ 'Content-Type' => 'multipart/form-data' ],
    $body = [
      [ yatta => $yatta_encoded, 'Content-Type' => 'text/plain; charset=Shift_JIS' ],
      [ yatta2 => [ ($yatta_encoded)x2 ], 'Content-Type' => 'text/plain; charset=Shift_JIS' ],
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
              {
                'Content-Type' => 'text/plain; charset=Shift_JIS',
                'Content-Disposition' => 'form-data; name="yatta"',
              },
              ({
                'Content-Type' => 'text/plain; charset=Shift_JIS',
                'Content-Disposition' => 'form-data; name="yatta2"',
              })x2,
            ],
            $object_data->{request}{body}->%{content},
          },
        },
      },
    ],
    'multipart/form-data decoding uses both contentType and Content-Type for objects',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

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
              {
                'Content-Type' => 'text/plain; charset=Shift_JIS',
                'Content-Disposition' => 'form-data; name="yatta"',
              },
              ({
                'Content-Type' => 'text/plain; charset=Shift_JIS',
                'Content-Disposition' => 'form-data; name="yatta2"',
              })x2,
            ],
            $array_data->{request}{body}->%{content},
          },
        },
      },
    ],
    'multipart/form-data decoding uses both contentType and Content-Type for arrays',
  );


  $result = $openapi->validate_request(request('POST', 'http://example.com/object',
    [ 'Content-Type' => 'multipart/form-data' ],
    $body = [
      [ yatta => Encode::encode('UTF-8', 'やった'), 'Content-Type' => 'text/plain; charset=UTF-8' ],
      [ yatta2 => [ (Encode::encode('UTF-8', 'やった'))x2 ], 'Content-Type' => 'text/plain; charset=UTF-8' ],
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
          {
            instanceLocation => '/request/body/header/0/Content-Type',
            keywordLocation => jsonp(qw(/paths /object post requestBody content multipart/form-data encoding yatta contentType)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /object post requestBody content multipart/form-data encoding yatta contentType)))->to_string,
            error => 'incorrect Content-Type "text/plain; charset=UTF-8"',
          },
          map +{
            instanceLocation => '/request/body/header/'.$_.'/Content-Type',
            keywordLocation => jsonp(qw(/paths /object post requestBody content multipart/form-data encoding yatta2 contentType)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /object post requestBody content multipart/form-data encoding yatta2 contentType)))->to_string,
            error => 'incorrect Content-Type "text/plain; charset=UTF-8"',
          }, 1..2,
        ],
      },
      {
        request => {
          body => {
            header => [
              {
                'Content-Disposition' => 'form-data; name="yatta"',
                'Content-Type' => 'text/plain; charset=UTF-8',
              },
              ({
                'Content-Disposition' => 'form-data; name="yatta2"',
                'Content-Type' => 'text/plain; charset=UTF-8',
              })x2,
            ],
            # message payload still successfully decodes using UTF-8 decoding
            $object_data->{request}{body}->%{content},
          },
        },
      },
    ],
    'multipart/form-data object decoding, prefer Content-Type over encoding/contentType, with object',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

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
            instanceLocation => '/request/body/header/0/Content-Type',
            keywordLocation => jsonp(qw(/paths /array post requestBody content multipart/form-data itemEncoding encoding yatta contentType)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /array post requestBody content multipart/form-data itemEncoding encoding yatta contentType)))->to_string,
            error => 'incorrect Content-Type "text/plain; charset=UTF-8"',
          },
          map +{
            instanceLocation => '/request/body/header/'.$_.'/Content-Type',
            keywordLocation => jsonp(qw(/paths /array post requestBody content multipart/form-data itemEncoding encoding yatta2 contentType)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /array post requestBody content multipart/form-data itemEncoding encoding yatta2 contentType)))->to_string,
            error => 'incorrect Content-Type "text/plain; charset=UTF-8"',
          }, 1..2,
        ],
      },
      {
        request => {
          body => {
            header => [
              {
                'Content-Disposition' => 'form-data; name="yatta"',
                'Content-Type' => 'text/plain; charset=UTF-8',
              },
              ({
                'Content-Disposition' => 'form-data; name="yatta2"',
                'Content-Type' => 'text/plain; charset=UTF-8',
              })x2,
            ],
            # message payload still successfully decodes using UTF-8 decoding
            $array_data->{request}{body}->%{content},
          },
        },
      },
    ],
    'multipart/form-data object decoding, prefer Content-Type over encoding/contentType, with array',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /object:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                yatta:
                  type: [ array, string ]
                  items:
                    type: string
                yatta2:
                  type: [ array, string ]
                  items:
                    type: string
            encoding:
              yatta:
                contentType: text/plain
              yatta2:
                contentType: text/plain
  /array:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: array
              items:
                type: object
                properties:
                  yatta:
                    type: string
                  yatta2:
                    type: string
            itemEncoding:
              encoding:
                yatta:
                  contentType: text/plain
                yatta2:
                  contentType: text/plain
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/object',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

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
              {
                'Content-Disposition' => 'form-data; name="yatta"',
                'Content-Type' => 'text/plain; charset=UTF-8',
              },
              ({
                'Content-Disposition' => 'form-data; name="yatta2"',
                'Content-Type' => 'text/plain; charset=UTF-8',
              })x2,
            ],
            # message payload still successfully decodes using UTF-8 decoding
            $object_data->{request}{body}->%{content},
          },
        },
      },
    ],
    'multipart/form-data object decoding, more specific Content-Type is used over encoding/contentType, with object',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

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
              {
                'Content-Disposition' => 'form-data; name="yatta"',
                'Content-Type' => 'text/plain; charset=UTF-8',
              },
              ({
                'Content-Disposition' => 'form-data; name="yatta2"',
                'Content-Type' => 'text/plain; charset=UTF-8',
              })x2,
            ],
            # message payload still successfully decodes using UTF-8 decoding
            $array_data->{request}{body}->%{content},
          },
        },
      },
    ],
    'multipart/form-data object decoding, more specific Content-Type is used over encoding/contentType, with array',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /object:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                yatta:  # single part, json-decodes to an array
                  # default encoding for array is application/json
                  # the string is already unicode in the json; _charset_ should NOT apply
                  type: array
                  items:
                    type: string
                yatta2: # single part, json-decodes to an object
                  type: object
                  additionalProperties:
                    type: string
                yatta3: # multiple values, json-decodes to an array
                  type: array
                  items:
                    type: array
                    items:
                      type: string
                yatta4: # multiple values, json decodes to an object
                  type: array
                  items:
                    type: object
                    additionalProperties:
                      type: string
  /array:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: array
              items:
                type: object
                properties:
                  # default encoding for array is application/json
                  # the string is already unicode in the json; _charset_ should NOT apply
                  yatta:              # single part, json-decoes to an array
                    type: array
                    items:
                      type: string
                  yatta2:             # single part, json-decodes to an object
                    type: object
                    additionalProperties:
                      type: string
                  yatta3:             # multiple parts, json-decodes to an array
                    type: array
                    items:
                      type: string
                  yatta4:             # multiple parts, json-decodes to an object
                    type: object
                    additionalProperties:
                      type: string
YAML

  my $json_encoder = JSON::Schema::Modern::_JSON_BACKEND()->new->allow_nonref(1)->utf8(1);

  $result = $openapi->validate_request(request('POST', 'http://example.com/object',
    [ 'Content-Type' => 'multipart/form-data' ],
    $body = [
      [ yatta => $json_encoder->encode([ ('やった')x2 ]) ],
      [ yatta2 => $json_encoder->encode({ x => 'やった' }) ],
      [ _charset_ => 'Shift_JIS' ],
      [ yatta3 => [ ($json_encoder->encode([ ('やった')x2 ]))x2 ] ],
      [ yatta4 => [ ($json_encoder->encode({ x => 'やった' }))x2 ] ],
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
              { 'Content-Disposition' => 'form-data; name="yatta"' },
              { 'Content-Disposition' => 'form-data; name="yatta2"' },
              ({ 'Content-Disposition' => 'form-data; name="yatta3"' })x2,
              ({ 'Content-Disposition' => 'form-data; name="yatta4"' })x2,
            ],
            content => {
              yatta => [ ('やった')x2 ],
              yatta2 => { x => 'やった' },
              yatta3 => [ ([ ('やった')x2 ])x2 ],
              yatta4 => [ ({ x => 'やった' })x2 ],
            },
          },
        },
      },
    ],
    'multipart/form-data decoding does not apply _charset_ to strings in decoded arrays, as object',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

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
              { 'Content-Disposition' => 'form-data; name="yatta"' },
              { 'Content-Disposition' => 'form-data; name="yatta2"' },
              ({ 'Content-Disposition' => 'form-data; name="yatta3"' })x2,
              ({ 'Content-Disposition' => 'form-data; name="yatta4"' })x2,
            ],
            content => [
              { yatta => [ ('やった')x2 ] },
              { yatta2 => { x => 'やった' } },
              { yatta3 => [ ('やった')x2 ] },
              { yatta3 => [ ('やった')x2 ] },
              { yatta4 => { x => 'やった' } },
              { yatta4 => { x => 'やった' } },
            ],
          },
        },
      },
    ],
    'multipart/form-data decoding does not apply _charset_ to strings in decoded arrays, as array',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /object:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                yatta:
                  type: [ array, string ]
                  items:
                    type: string
                yatta2:
                  type: [ array, string ]
                  items:
                    type: string
            encoding:
              yatta:
                contentType: text/plain
              yatta2:
                contentType: text/plain
  /array:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: array
              items:
                type: object
                properties:
                  yatta:
                    type: string
                  yatta2:
                    type: string
            itemEncoding:
              encoding:
                yatta:
                  contentType: text/plain
                yatta2:
                  contentType: text/plain
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/object',
    [ 'Content-Type' => 'multipart/form-data' ],
    $body = [
      [ yatta => $yatta_encoded ],
      [ _charset_ => 'Shift_JIS' ],
      [ yatta2 => [ ($yatta_encoded)x2 ] ],
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
              { 'Content-Disposition' => 'form-data; name="yatta"' },
              ({ 'Content-Disposition' => 'form-data; name="yatta2"' })x2,
            ],
            content => {
              yatta => 'やった',
              yatta2 => [ ('やった')x2 ],
            },
          },
        },
      },
    ],
    'multipart/form-data decoding appends charset to contentType=text/plain, for objects',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

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
              { 'Content-Disposition' => 'form-data; name="yatta"' },
              ({ 'Content-Disposition' => 'form-data; name="yatta2"' })x2,
            ],
            content => [
              { yatta => 'やった' },
              ({ yatta2 => 'やった' })x2,
            ],
          },
        },
      },
    ],
    'multipart/form-data decoding appends charset to contentType=text/plain, for arrays',
  );

  disallow_patterns($dancer_pattern);


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
components:
  headers:
    MyRequiredHeader:
      required: true
      schema:
        # default deserialization is style=simple, explode=false
        type: array
        items:
          type: number
    MyOptionalHeader:
      schema: {}
paths:
  /object:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                hello:
                  type: string
                hello2:
                  type: [ array, string ]
                  items:
                    type: string
            encoding:
              hello:
                headers:
                  X-Test:
                    $ref: '#/components/headers/MyRequiredHeader'
                  Content-Type:
                    required: true
                    schema: false
                  'Null':
                    $ref: '#/components/headers/MyOptionalHeader'
              hello2:
                headers:
                  X-Test:
                    $ref: '#/components/headers/MyRequiredHeader'
                  Content-Type:
                    required: true
                    schema: false
  /array:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: array
              items:
                type: object
                properties:
                  hello:
                    type: string
                  hello2:
                    type: string
            itemEncoding:
              encoding:
                hello:
                  headers:
                    X-Test:
                      $ref: '#/components/headers/MyRequiredHeader'
                    Content-Type:
                      required: true
                      schema: false
                    X-Test2:
                      $ref: '#/components/headers/MyOptionalHeader'
                hello2:
                  headers:
                    X-Test:
                      $ref: '#/components/headers/MyRequiredHeader'
                    Content-Type:
                      required: true
                      schema: false
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/object',
    [ 'Content-Type' => 'multipart/form-data' ],
    $body = [
      [ hello => 'yes', 'Content-Type' => 'text/plain' ],
      ([ hello2 => 'yes', 'Content-Type' => 'text/plain' ])x2,
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
          {
            instanceLocation => '/request/body/header/0',
            keywordLocation => jsonp(qw(/paths /object post requestBody content multipart/form-data encoding hello headers X-Test $ref required)),
            absoluteKeywordLocation => $doc_uri->clone->fragment('/components/headers/MyRequiredHeader/required')->to_string,
            error => 'missing header: X-Test',
          },
          map +{
            instanceLocation => '/request/body/header/'.$_,
            keywordLocation => jsonp(qw(/paths /object post requestBody content multipart/form-data encoding hello2 headers X-Test $ref required)),
            absoluteKeywordLocation => $doc_uri->clone->fragment('/components/headers/MyRequiredHeader/required')->to_string,
            error => 'missing header: X-Test',
          }, 1..2,
        ],
      },
      {
        request => {
          body => {
            header => [
              { 'Content-Disposition' => 'form-data; name="hello"', 'Content-Type' => 'text/plain' },
              ({ 'Content-Disposition' => 'form-data; name="hello2"', 'Content-Type' => 'text/plain' })x2,
            ],
            content => {
              hello => 'yes',
              hello2 => [ 'yes', 'yes' ],
            },
          },
        },
      },
    ],
    'multipart/form-data object decoding, error when a part header is missing, as object',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

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
            instanceLocation => '/request/body/header/0',
            keywordLocation => jsonp(qw(/paths /array post requestBody content multipart/form-data itemEncoding encoding hello headers X-Test $ref required)),
            absoluteKeywordLocation => $doc_uri->clone->fragment('/components/headers/MyRequiredHeader/required')->to_string,
            error => 'missing header: X-Test',
          },
          map +{
            instanceLocation => '/request/body/header/'.$_,
            keywordLocation => jsonp(qw(/paths /array post requestBody content multipart/form-data itemEncoding encoding hello2 headers X-Test $ref required)),
            absoluteKeywordLocation => $doc_uri->clone->fragment('/components/headers/MyRequiredHeader/required')->to_string,
            error => 'missing header: X-Test',
          }, 1..2,
        ],
      },
      {
        request => {
          body => {
            header => [
              { 'Content-Disposition' => 'form-data; name="hello"', 'Content-Type' => 'text/plain' },
              ({ 'Content-Disposition' => 'form-data; name="hello2"', 'Content-Type' => 'text/plain' })x2,
            ],
            content => [
              { hello => 'yes' },
              ({ hello2 => 'yes' })x2,
            ],
          },
        },
      },
    ],
    'multipart/form-data array decoding, error when a part header is missing, as array',
  );


  $result = $openapi->validate_request(request('POST', 'http://example.com/object',
    [ 'Content-Type' => 'multipart/form-data' ],
    $body = [
      [ hello => 'yes', 'Content-Type' => 'text/plain', 'X-Test' => '42,99' ],
      [ hello2 => 'yes', 'Content-Type' => 'text/plain', 'X-Test' => '50,61' ],
      [ hello2 => 'yes', 'Content-Type' => 'text/plain', 'X-Test' => '90', 'X-Test' => '91' ],
    ],
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
            header => [
              {
                'Content-Disposition' => 'form-data; name="hello"',
                'Content-Type' => 'text/plain',
                'X-Test' => [ 42, 99 ],
              },
              {
                'Content-Disposition' => 'form-data; name="hello2"',
                'Content-Type' => 'text/plain',
                'X-Test' => [ 50, 61 ],
              },
              {
                'Content-Disposition' => 'form-data; name="hello2"',
                'Content-Type' => 'text/plain',
                'X-Test' => [ 90, 91 ],
              },
            ],
            content => {
              hello => 'yes',
              hello2 => [ 'yes', 'yes' ],
            },
          },
        },
      },
    ],
    'multipart/form-data object decoding, part headers are style-deserialized, as object',
  );

  $result = $openapi->validate_request(request('POST', 'http://example.com/array',
    [ 'Content-Type' => 'multipart/form-data' ], $body));

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
              { hello => 'yes' },
              ({ hello2 => 'yes' })x2,
            ],
          },
        },
      },
    ],
    'multipart/form-data object decoding, part headers are style-deserialized, as array',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                thing:
                  type: object
            encoding:
              thing:
                style: form
                explode: false
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/form-data' ],
    [ [ thing => "dessert,\xc3\xa9clair" ] ],
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
              { 'Content-Disposition' => 'form-data; name="thing"' },
            ],
            content => {
              thing => { dessert => 'éclair' },
            },
          },
        },
      },
    ],
    'multipart/form-data style-encoded content is not percent-encoded',
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
          multipart/form-data:
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
                summary: a single address part
                description: |
                  addresses appears in the request body as a single part named "addresses"
                dataValue:
                  addresses:
                    streetAddress: 123 Example Dr
                    city: Somewhere
                    state: CA
                    zip: 99999+1234
                serializedValue: |
                  --KJvXX
                  Content-Disposition: form-data; name="address"

                  {"city":"Somewhere","state":"CA","streetAddress":"123 Example Dr","zip":"99999+1234"}
                  --KJvXX--
              example2:
                summary: multiple address parts, each part encoded separately
                description: |
                  Depending on whether the serializer works independently of
                  the OpenAPI specification or not, the "addresses" data can
                  appear in the request body as either:
                  - two parts, each named "addresses" whose value is a
                  json-encoded object containing data for a single address,
                  which is the same as how application/x-www-form-urlencoded
                  handles duplicate names;
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
                serializedValue: |
                  --oqG4X
                  Content-Disposition: form-data; name="addresses"

                  {"city":"Somewhere","state":"CA","streetAddress":"123 Example Dr","zip":"99999+1234"}
                  --oqG4X
                  Content-Disposition: form-data; name="addresses"

                  {"city":"Lillooet","state":"BC","streetAddress":"996 Orchard Dr","zip":"V0K 1V0"}
                  --oqG4X--
              example3:
                summary: multiple address, encoded together as one part
                description: |
                  When encoded as a single part named "addresses" whose value
                  is a json-encoded array of two objects, the dataValue is the
                  same as in the last example, but the serialized form differs:
                serializedValue: |
                  --GdtAX
                  Content-Disposition: form-data; name="addresses"

                  [{"city":"Somewhere","state":"CA","streetAddress":"123 Example Dr","zip":"99999+1234"},{"city":"Lillooet","state":"BC","streetAddress":"996 Orchard Dr","zip":"V0K 1V0"}]
                  --GdtAX--
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/form-data' ],
    [
      [ addresses => $::dumper->encode(
        { streetAddress => '123 Example Dr', city => 'Somewhere', state => 'CA', zip => '99999+1234' }) ],
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
              { 'Content-Disposition' => 'form-data; name="addresses"' },
            ],
            content => {
              addresses => { streetAddress => '123 Example Dr', city => 'Somewhere', state => 'CA', zip => '99999+1234' },
            },
          },
        },
      },
    ],
    'example1: multipart/form-data content with a single value, deserialized to an object',
  );


  my $idx = 0;
  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/form-data' ],
    [
      map +[ addresses => $::dumper->encode($_), 'X-Item' => $idx++ ],
        { streetAddress => '123 Example Dr', city => 'Somewhere', state => 'CA', zip => '99999+1234' },
        { streetAddress => '996 Orchard Dr', city => 'Lillooet', state => 'BC', zip => 'V0K 1V0' },
    ],
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
            header => [
              { 'Content-Disposition' => 'form-data; name="addresses"', 'X-Item' => '0' },
              { 'Content-Disposition' => 'form-data; name="addresses"', 'X-Item' => '1' },
            ],
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
    'example2: multipart/form-data content is deserialized to an object with duplicate part names',
  );


  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/form-data' ],
    [
      [ addresses => $::dumper->encode([
        { streetAddress => '123 Example Dr', city => 'Somewhere', state => 'CA', zip => '99999+1234' },
        { streetAddress => '996 Orchard Dr', city => 'Lillooet', state => 'BC', zip => 'V0K 1V0' },
      ]) ],
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
            header => [ { 'Content-Disposition' => 'form-data; name="addresses"' } ],
            $result_data->{request}{body}->%{content},
          },
        },
      },
    ],
    'example3: multipart/form-data content is deserialized to an object with repeated part values encoded together as one part',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                alpha: true
                beta: false
YAML

  allow_patterns($dancer_pattern) if $::TYPE eq 'dancer2';

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/form-data' ],
    [
      [ alpha => $yatta_encoded ],
      [ _charset_ => 'UTF-8' ],
      [ beta => $yatta_encoded ],  # Shift_JIS: not decodable as UTF-8
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
          {
            instanceLocation => '/request/body/content/beta',
            keywordLocation => jsonp(qw(/paths /foo post requestBody content multipart/form-data schema properties beta)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content multipart/form-data schema properties beta)))->to_string,
            error => 'property not permitted',
          },
          {
            instanceLocation => '/request/body/content',
            keywordLocation => jsonp(qw(/paths /foo post requestBody content multipart/form-data schema properties)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content multipart/form-data schema properties)))->to_string,
            error => 'not all properties are valid',
          },
        ],
      },
      {
        request => {
          body => {
            header => [
              { 'Content-Disposition' => 'form-data; name="alpha"' },
              { 'Content-Disposition' => 'form-data; name="beta"' },
            ],
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

  disallow_patterns($dancer_pattern) if $::TYPE eq 'dancer2';


  $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                a_form_primitive:
                  type: number
                b_form_array_explode_true:
                  type: array
                c_form_object_explode_true:
                  type: object
                  additionalProperties:
                    type: number
                d_form_array_explode_false:
                  type: array
                e_form_object_explode_false:
                  type: object
                  additionalProperties:
                    type: number
                f_spaceDelimited_array:
                  type: array
                g_spaceDelimited_object:
                  type: object
                  additionalProperties:
                    type: number
                h_pipeDelimited_array:
                  type: array
                i_pipeDelimited_object:
                  type: object
                  additionalProperties:
                    type: number
                j_deepObject_object:
                  type: object
                  additionalProperties:
                    type: number
            encoding:
              a_form_primitive:
                style: form
              b_form_array_explode_true:    # not allowed
                style: form
              c_form_object_explode_true:   # not allowed
                style: form
              d_form_array_explode_false:
                explode: false
              e_form_object_explode_false:
                explode: false
              f_spaceDelimited_array:
                style: spaceDelimited
                explode: false
              g_spaceDelimited_object:
                style: spaceDelimited
                explode: false
              h_pipeDelimited_array:
                style: pipeDelimited
                explode: false
              i_pipeDelimited_object:
                style: pipeDelimited
                explode: false
              j_deepObject_object:          # not allowed
                style: deepObject
YAML

  $result = $openapi->validate_request(request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'multipart/form-data' ],
    [
      [ a_form_primitive              => '42' ],
      [ b_form_array_explode_true     => 'a=1&a=2' ],
      [ c_form_object_explode_true    => 'a=1&b=2' ],
      [ d_form_array_explode_false    => 'blue,black,brown' ],
      [ e_form_object_explode_false   => 'R,100,G,200,B,150' ],
      [ f_spaceDelimited_array        => 'blue black brown' ],
      [ g_spaceDelimited_object       => 'R 100 G 200 B 150' ],
      [ h_pipeDelimited_array         => 'blue|black|brown' ],
      [ i_pipeDelimited_object        => 'R|100|G|200|B|150' ],
      [ j_deepObject_object           => 'j_deepObject_object[R]=100&j_deepObject_object[G]=200&j_deepObject_object[B]=150' ],
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
          (map +{
            instanceLocation => '/request/body/content/'.$_,
            keywordLocation => jsonp(qw(/paths /foo post requestBody content multipart/form-data encoding), $_, 'explode'),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content multipart/form-data encoding), $_, 'explode'))->to_string,
            error => 'explode=true is not supported for '.(split(/_/, $_))[2].'s using style='.(split(/_/, $_))[1].' in forms',
          }, qw(b_form_array_explode_true c_form_object_explode_true)),
          {
            instanceLocation => '/request/body/content/j_deepObject_object',
            keywordLocation => jsonp(qw(/paths /foo post requestBody content multipart/form-data encoding j_deepObject_object style)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content multipart/form-data encoding j_deepObject_object style)))->to_string,
            error => 'deepObject style cannot be used in forms',
          },
          (map +{
            instanceLocation => '/request/body/content/'.$_,
            keywordLocation => jsonp(qw(/paths /foo post requestBody content multipart/form-data schema properties), $_, 'type'),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content multipart/form-data schema properties), $_, 'type'))->to_string,
            error => 'got string, not '.(split(/_/, $_))[2],
          }, qw(b_form_array_explode_true c_form_object_explode_true j_deepObject_object)),
          {
            instanceLocation => '/request/body/content',
            keywordLocation => jsonp(qw(/paths /foo post requestBody content multipart/form-data schema properties)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content multipart/form-data schema properties)))->to_string,
            error => 'not all properties are valid',
          },
        ],
      },
      {
        request => {
          body => {
            header => [
              map +{ 'Content-Disposition' => 'form-data; name="'.$_.'"' }, qw(
                a_form_primitive
                b_form_array_explode_true
                c_form_object_explode_true
                d_form_array_explode_false
                e_form_object_explode_false
                f_spaceDelimited_array
                g_spaceDelimited_object
                h_pipeDelimited_array
                i_pipeDelimited_object
                j_deepObject_object
              ),
            ],
            content => {
              a_form_primitive              => 42,
              b_form_array_explode_true     => 'a=1&a=2',
              c_form_object_explode_true    => 'a=1&b=2',
              d_form_array_explode_false    => [ qw(blue black brown) ],
              e_form_object_explode_false   => { R => 100 => G => 200, B => 150 },
              f_spaceDelimited_array        => [ qw(blue black brown) ],
              g_spaceDelimited_object       => { R => 100 => G => 200, B => 150 },
              h_pipeDelimited_array         => [ qw(blue black brown) ],
              i_pipeDelimited_object        => { R => 100 => G => 200, B => 150 },
              j_deepObject_object           => 'j_deepObject_object[R]=100&j_deepObject_object[G]=200&j_deepObject_object[B]=150',
            },
          },
        },
      },
    ],
    'some style/explode/type combinations are not valid in forms',
  );
};

if (++$type_index < @::TYPES) {
  bail_if_not_passing if $ENV{AUTHOR_TESTING};
  goto START;
}

had_no_warnings() if $ENV{AUTHOR_TESTING};
done_testing;
