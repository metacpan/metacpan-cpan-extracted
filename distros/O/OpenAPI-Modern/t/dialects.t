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

use constant STRICT_DIALECT_URI => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/strict-dialect.json';
use constant STRICT_METASCHEMA_URI => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/strict-schema.json';

my $schema = {
  openapi => OAS_VERSION,
  info => {
    title => 'my title',
    version => '1.2.3',
  },
  components => {
    schemas => {
      Foo => {
        #'$schema' => [],
        blah => 'unrecognized keyword!',
      },
      Bar => {
        'x-todo' => 'this one is okay',
      },
    },
  },
};

subtest 'normal case' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    evaluator => JSON::Schema::Modern->new,
    schema => $schema,
  );

  cmp_deeply(
    [ $doc->errors ],
    [],
    'unrecognized keywords cause no errors in the default case',
  );
};

subtest 'dialect, via metaschema_uri' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    metaschema_uri => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/strict-schema.json',
    evaluator => JSON::Schema::Modern->new,
    schema => $schema,
  );

  cmp_result(
    ($doc->errors)[0]->TO_JSON,
    {
      instanceLocation => '/components/schemas/Foo/blah',
      keywordLocation => '/$ref/properties/components/$ref/properties/schemas/additionalProperties/$dynamicRef/$ref/unevaluatedProperties',
      absoluteKeywordLocation => STRICT_DIALECT_URI.'#/unevaluatedProperties',
      error => 'additional property not permitted',
    },
    'subschemas identified, and error found',
  );
};

subtest 'dialect, via metaschema_uri and jsonSchemaDialect too' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    metaschema_uri => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/strict-schema.json',
    evaluator => JSON::Schema::Modern->new,
    schema => {
      %$schema,
      jsonSchemaDialect => STRICT_DIALECT_URI,
    },
  );

  cmp_result(
    ($doc->errors)[0]->TO_JSON,
    {
      instanceLocation => '/components/schemas/Foo/blah',
      keywordLocation => '/$ref/properties/components/$ref/properties/schemas/additionalProperties/$dynamicRef/$ref/unevaluatedProperties',
      absoluteKeywordLocation => STRICT_DIALECT_URI.'#/unevaluatedProperties',
      error => 'additional property not permitted',
    },
    'subschemas identified, and error found',
  );
};

done_testing;
