# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use lib 't/lib';
use Helper;

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
        absoluteKeywordLocation => SCHEMA,
        error => 'duplicate of templated path /a/{a}',
      },
      +{
        instanceLocation => '/paths/~1b~1{b}~1hi',
        keywordLocation => '',
        absoluteKeywordLocation => SCHEMA,
        error => 'duplicate of templated path /b/{a}/hi',
      },
    ],
    'duplicate paths are not permitted',
  );

  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors');
'/paths/~1a~1{b}': duplicate of templated path /a/{a}
'/paths/~1b~1{b}~1hi': duplicate of templated path /b/{a}/hi
ERRORS
};

done_testing;
