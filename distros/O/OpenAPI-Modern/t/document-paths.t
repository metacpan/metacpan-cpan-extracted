# vim: set ts=8 sts=2 sw=2 tw=100 et :
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

use lib 't/lib';
use Helper;

subtest '/paths correctness' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => {
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      paths => {
        '/a/{a}' => {},
        '/a/{b}' => {},
        '/b/{a}/hi' => {},
        '/b/{b}/hi' => {},
        '/c/{c}/d/{c}/e/{e}/f/{e}' => {},
        'x-{alpha}' => {},
        'x-{beta}' => {},
        'x-{foo}-{foo}' => {},
      },
    },
  );

  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [
      +{
        instanceLocation => '',
        keywordLocation => '/paths/~1a~1{b}',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/paths/~1a~1{b}')),
        error => 'duplicate of templated path "/a/{a}"',
      },
      +{
        instanceLocation => '',
        keywordLocation => '/paths/~1b~1{b}~1hi',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/paths/~1b~1{b}~1hi')),
        error => 'duplicate of templated path "/b/{a}/hi"',
      },
      +{
        instanceLocation => '',
        keywordLocation => '/paths/~1c~1{c}~1d~1{c}~1e~1{e}~1f~1{e}',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/paths/~1c~1{c}~1d~1{c}~1e~1{e}~1f~1{e}')),
        error => 'duplicate path template variable "c"',
      },
      +{
        instanceLocation => '',
        keywordLocation => '/paths/~1c~1{c}~1d~1{c}~1e~1{e}~1f~1{e}',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/paths/~1c~1{c}~1d~1{c}~1e~1{e}~1f~1{e}')),
        error => 'duplicate path template variable "e"',
      },
    ],
    'duplicate paths or template variables are not permitted',
  );

  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors');
'/paths/~1a~1{b}': duplicate of templated path "/a/{a}"
'/paths/~1b~1{b}~1hi': duplicate of templated path "/b/{a}/hi"
'/paths/~1c~1{c}~1d~1{c}~1e~1{e}~1f~1{e}': duplicate path template variable "c"
'/paths/~1c~1{c}~1d~1{c}~1e~1{e}~1f~1{e}': duplicate path template variable "e"
ERRORS
};

done_testing;
