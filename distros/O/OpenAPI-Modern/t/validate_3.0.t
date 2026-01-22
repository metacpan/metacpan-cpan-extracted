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
use Storable 'dclone';

my $doc_uri_rel = Mojo::URL->new('/api');
my $doc_uri = $doc_uri_rel->to_abs(Mojo::URL->new('http://example.com'));
my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');
$::TYPE = 'mojo';

subtest 'basic request validation with a v3.0.x OAD' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(<<'YAML'));
openapi: 3.0.3
info:
  title: Test API
  version: 1.2.3
components:
  schemas:
    basic_subschema:
      type: string
      enum: [ '20' ]
paths:
  /foo:
    post:
      parameters:
        - name: q
          in: query
          schema:
            $ref: '#/components/schemas/basic_subschema'
      requestBody:
        required: true
        content:
          '*/*':
            schema:
              not: {}
          application/json:
            schema:
              type: object
              properties:
                not_nullable:
                  type: string
                  nullable: false
                nullable:
                  type: string
                  nullable: true
      responses:      # required in 3.0, not in 3.1
        2XX:
          description: success
YAML

  my $request = request('POST', 'http://example.com/foo?q=1',
    [ 'Content-Type' => 'application/json' ], '{"nullable":1,"not_nullable":null}');
  cmp_result(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request/uri/query/q',
          keywordLocation => jsonp(qw(/paths /foo post parameters 0 schema $ref enum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/schemas/basic_subschema/enum')->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/request/body/not_nullable',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content application/json schema properties not_nullable type)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/json schema properties not_nullable type)))->to_string,
          error => 'got null, not string',
        },
        {
          instanceLocation => '/request/body/nullable',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content application/json schema properties nullable type)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/json schema properties nullable type)))->to_string,
          error => 'got integer, not string or null',
        },
        {
          instanceLocation => '/request/body',
          keywordLocation => jsonp(qw(/paths /foo post requestBody content application/json schema properties)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /foo post requestBody content application/json schema properties)))->to_string,
          error => 'not all properties are valid',
        },
      ],
    },
    'custom nullable handling in "type" keyword is correct',
  );

  $request = request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/json' ], '{"nullable":null,"not_nullable":"foo"}');
  cmp_result(
    $openapi->validate_request($request)->TO_JSON,
    { valid => true },
    'all body properties are the correct type',
  );
};

subtest 'upgrading from 3.0' => sub {
  # example taken from https://learn.openapis.org/upgrading/v3.0-to-v3.1.html
  my $doc_3_0 = JSON::Schema::Modern::Document::OpenAPI->new(schema => $yamlpp->load_string(<<'YAML'));
---
openapi: 3.0.3
info:
  title: Test API
  version: 1.2.3
paths: {}   # only required in 3.0
components:
  schemas:
    OAS_3.0_schema:
      anyOf:
        - minimum: 1
          maximum: 2
          exclusiveMinimum: true
          exclusiveMaximum: true
          type: string
          nullable: true
          format: binary
        - nullable: false
        - type: string
          format: base64
          example: foo
        - enum: [ foo ]
        - enum: [ foo, bar ]
  responses:
    responseA:
      description: ''    # only required up to 3.1
    responseB:
      description: a non-empty description
  requestBodies:
    file_upload:
      content:
        application/octet-stream:
          schema:
            type: string
            format: binary
YAML

  like(
    dies { $doc_3_0->upgrade('3.1.foo') },
    qr/^new openapi version must be a dotted tuple or triple/,
    'die on invalid OAS version',
  );

  like(
    dies { $doc_3_0->upgrade('3.3.0') },
    qr/^\Qrequested upgrade to an unsupported version: 3.3.0\E/,
    'die on upgrading to version that is too high',
  );

  like(
    dies {
      my $doc_3_0 = JSON::Schema::Modern::Document::OpenAPI->new(schema => $yamlpp->load_string(OPENAPI_PREAMBLE."\npaths: {}\n"));
      $doc_3_0->upgrade('3.0.4');
    },
    qr/^\Qdowngrading is not supported\E/,
    'downgrading is not supported',
  );

  cmp_result(
    my $schema_3_1 = $doc_3_0->upgrade('3.1'),
    my $expected_schema_3_1 = $yamlpp->load_string(<<'YAML'),
openapi: 3.1.2
info:
  title: Test API
  version: 1.2.3
components:
  schemas:
    OAS_3.0_schema:
      anyOf:
        - exclusiveMinimum: 1
          exclusiveMaximum: 2
          type: [ string, 'null' ]
          contentMediaType: application/octet-stream
        - {}
        - type: string
          contentEncoding: base64
          examples: [ foo ]
        - const: foo
        - enum: [ foo, bar ]
  responses:
    responseA:
      description: ''    # only required up to 3.1
    responseB:
      description: a non-empty description
  requestBodies:
    file_upload:
      content:
        application/octet-stream: {}
YAML
    'upgrade to 3.1',
  );

  my $doc_3_1 = JSON::Schema::Modern::Document::OpenAPI->new(schema => $schema_3_1);
  cmp_result([ $doc_3_1->errors ], [], 'no errors in the converted 3.1 document');

  bail_if_not_passing;

  $expected_schema_3_1->{openapi} = '3.1.1';
  cmp_result(
    $doc_3_0->upgrade('3.1.1'),
    $expected_schema_3_1,
    'upgrade to an explicit version less than the current maximum point version',
  );

  my $expected_schema_3_2 = dclone($schema_3_1);
  $expected_schema_3_2->{openapi} = SUPPORTED_OAD_VERSIONS->[-1];
  delete $expected_schema_3_2->{components}{responses}{responseA}{description};

  cmp_result(
    my $schema_3_2 = $doc_3_0->upgrade('3.2'),
    $expected_schema_3_2,
    'upgrade to from 3.0 to 3.2',
  );

  cmp_result(
    $doc_3_1->upgrade('3.2'),
    $expected_schema_3_2,
    'upgrade to from 3.1 to 3.2',
  );
};

done_testing;
