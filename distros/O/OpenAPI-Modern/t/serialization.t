# vim: set ft=perl ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::Needs qw(Sereal::Encoder Sereal::Decoder);
use if $ENV{AUTOMATED_TESTING}, 'Test::Warnings';
use lib 't/lib';
use Helper;

my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');
my $openapi = OpenAPI::Modern->new(
  openapi_uri => '/api',
  openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get: {}
YAML

my $req = Mojo::Message::Request->new(
  method => 'GET',
  url => Mojo::URL->new('https://example.com/foo'),
);

cmp_result(
  $openapi->validate_request($req)->TO_JSON,
  { valid => true },
  'request validates',
);

my $frozen = Sereal::Encoder->new({ freeze_callbacks => 1 })->encode($openapi);
my $thawed = Sereal::Decoder->new->decode($frozen);

cmp_result(
  $thawed->validate_request($req)->TO_JSON,
  { valid => true },
  'request can still validate',
);

done_testing;
