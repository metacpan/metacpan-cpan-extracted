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
paths:
  /foo:
    post:
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

  my $request = request('POST', 'http://example.com/foo',
    [ 'Content-Type' => 'application/json' ], '{"nullable":1,"not_nullable":null}');
  cmp_result(
    $openapi->validate_request($request)->TO_JSON,
    {
      valid => false,
      errors => [
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

done_testing;
