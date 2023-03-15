use strictures 2;
use experimental qw(signatures postderef);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use JSON::Schema::Modern;
use JSON::Schema::Modern::Document::OpenAPI;
use Test::File::ShareDir -share => { -dist => { 'OpenAPI-Modern' => 'share' } };
use constant { true => JSON::PP::true, false => JSON::PP::false };

# the document where most constraints are defined
use constant SCHEMA => 'https://spec.openapis.org/oas/3.1/schema/2022-10-07';

subtest '/paths correctness' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => {
      openapi => '3.1.0',
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      paths => {
        '/a/{a}' => {},
        '/a/{b}' => {},
        '/b/{a}/hi' => {},
        '/b/{b}/hi' => {},
      },
    },
  );

  cmp_deeply(
    [ map $_->TO_JSON, $doc->errors ],
    [
      +{
        instanceLocation => '/paths/~1a~1{b}',
        keywordLocation => '',
        absoluteKeywordLocation => 'http://localhost:1234/api',
        error => 'duplicate templated path /a/{b}',
      },
      +{
        instanceLocation => '/paths/~1b~1{b}~1hi',
        keywordLocation => '',
        absoluteKeywordLocation => 'http://localhost:1234/api',
        error => 'duplicate templated path /b/{b}/hi',
      },
    ],
    'duplicate paths are not permitted',
  );
};

done_testing;
