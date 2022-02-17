use strict;
use warnings;
use strictures 2;
use experimental qw(signatures postderef);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::File::ShareDir -share => { -dist => { 'OpenAPI-Modern' => 'share' } };
use File::ShareDir 'dist_dir';
use Test::Deep;
use JSON::Schema::Modern;
use JSON::Schema::Modern::Document::OpenAPI;

use constant STRICT_DIALECT_URI => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/strict-dialect.json';
use constant STRICT_METASCHEMA_URI => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/strict-schema.json';

my $schema = {
  openapi => '3.1.0',
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

  cmp_deeply(
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

  cmp_deeply(
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
