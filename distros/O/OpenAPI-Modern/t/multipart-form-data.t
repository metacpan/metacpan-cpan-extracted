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
use Test2::Warnings qw(:no_end_test warnings had_no_warnings);
use JSON::Schema::Modern::Utilities 'jsonp';
use OpenAPI::Modern::Utilities 'elem';

my $doc_uri_rel = Mojo::URL->new('/api');
my $doc_uri = $doc_uri_rel->to_abs(Mojo::URL->new('http://example.com'));

my $type_index = 0;

START:
$::TYPE = $::TYPES[$type_index];
note 'REQUEST/RESPONSE TYPE: '.$::TYPE;


subtest $::TYPE.': multipart/form-data' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /supported:
    post:
      requestBody:
        content:
          multipart/form-data: {}
  /unsupported:
    post:
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: array
YAML

  skip_all 'Plack insists on parsing a multipart/form-data message body' if $::TYPE eq 'dancer2';
  my $todo = todo 'Plack insists on parsing a multipart/form-data message body'
    if elem($::TYPE, [qw(plack catalyst)]);

  my $result = $openapi->validate_request(request('POST', 'http://example.com/supported',
    [ 'Content-Type' => 'multipart/form-data' ], '!!!'));
  is_equal(
    [
      $result->TO_JSON,
      $result->data,
    ],
    [
      { valid => true },
      { request => { body => { content => '!!!' } } },
    ],
    'multipart/form-data messages can be validated if there is no body schema',
  );
  $result = $openapi->validate_request(request('POST', 'http://example.com/unsupported',
    [ 'Content-Type' => 'multipart/form-data' ], '!!!'));
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
            instanceLocation => '/request/body',
            keywordLocation => jsonp(qw(/paths /unsupported post requestBody content multipart/form-data)),
            absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp(qw(/paths /unsupported post requestBody content multipart/form-data)))->to_string,
            error => 'EXCEPTION: unimplemented media type "multipart/form-data"',
          },
        ]
      },
      {},
    ],
    'multipart/form-data messages cannot be validated when there is a body schema',
  );
};

if (++$type_index < @::TYPES) {
  bail_if_not_passing if $ENV{AUTHOR_TESTING};
  goto START;
}

had_no_warnings() if $ENV{AUTHOR_TESTING};
done_testing;
