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
use Test::Deep;
use JSON::Schema::Modern;
use JSON::Schema::Modern::Document::OpenAPI;
use Test::File::ShareDir -share => { -dist => { 'OpenAPI-Modern' => 'share' } };
use constant { true => JSON::PP::true, false => JSON::PP::false };

# the document where most constraints are defined
use constant SCHEMA => 'https://spec.openapis.org/oas/3.1/schema/2021-09-28';

subtest 'basic construction' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => {
      openapi => '3.1.0',
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      paths => {},
    },
  );

  cmp_deeply(
    { $doc->resource_index },
    {
      'http://localhost:1234/api' => {
        path => '',
        canonical_uri => str('http://localhost:1234/api'),
        specification_version => 'draft2020-12',
        vocabularies => [ map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI) ],
        configs => {},
      },
    },
    'the document itself is recorded as a resource',
  );
};

subtest 'top level document fields' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => 1,
  );
  cmp_deeply(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '',
        keywordLocation => '',
        absoluteKeywordLocation => 'http://localhost:1234/api',
        error => 'invalid document type: integer',
      },
    ],
    'document is wrong type',
  );

  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js = JSON::Schema::Modern->new,
    schema => {},
  );
  cmp_deeply(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '',
        keywordLocation => '/openapi',
        absoluteKeywordLocation => 'http://localhost:1234/api#/openapi',
        error => 'openapi keyword is required',
      },
    ],
    'missing openapi',
  );

  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => '3.1.0',
      info => {},
      paths => {},
    },
  );
  cmp_deeply(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '/info',
        keywordLocation => '/$ref/properties/info/$ref/required',
        absoluteKeywordLocation => SCHEMA.'#/$defs/info/required',
        error => 'missing properties: title, version',
      },
      {
        instanceLocation => '',
        keywordLocation => '/$ref/properties',
        absoluteKeywordLocation => SCHEMA.'#/properties',
        error => 'not all properties are valid',
      },
      (ignore)x4, # useless unevaluatedProperties errors
    ],
    'missing /info properties',
  );

  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => '2.1.3',
    },
  );
  cmp_deeply(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '',
        keywordLocation => '/openapi',
        absoluteKeywordLocation => 'http://localhost:1234/api#/openapi',
        error => 'unrecognized openapi version 2.1.3',
      },
    ],
    'invalid openapi version',
  );


  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => '3.1.0',
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      jsonSchemaDialect => undef,
    },
  );
  cmp_deeply(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '',
        keywordLocation => '/jsonSchemaDialect',
        absoluteKeywordLocation => 'http://localhost:1234/api#/jsonSchemaDialect',
        error => 'jsonSchemaDialect value is not a string',
      },
    ],
    'null jsonSchemaDialect is rejected',
  );


  $js->add_schema({
    '$id' => 'https://metaschema/with/wrong/spec',
    '$vocabulary' => {
      'https://json-schema.org/draft/2020-12/vocab/core' => true,
      'https://unknown' => true,
    },
  });

  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => '3.1.0',
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      jsonSchemaDialect => 'https://metaschema/with/wrong/spec',
    },
  );

  cmp_deeply(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '',
        keywordLocation => '/jsonSchemaDialect/$vocabulary/https:~1~1unknown',
        absoluteKeywordLocation => 'https://metaschema/with/wrong/spec#/$vocabulary/https:~1~1unknown',
        error => '"https://unknown" is not a known vocabulary',
      },
      {
        instanceLocation => '',
        keywordLocation => '/jsonSchemaDialect',
        absoluteKeywordLocation => 'http://localhost:1234/api#/jsonSchemaDialect',
        error => '"https://metaschema/with/wrong/spec" is not a valid metaschema',
      },
    ],
    'bad jsonSchemaDialect is rejected',
  );


  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => '3.1.0',
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      map +($_ => 'not an object'), qw(servers security tags externalDocs),
    },
  );
  my $iter = 0;
  cmp_deeply(
    [ map $_->TO_JSON, $doc->errors ],
    [
      (map +{
        instanceLocation => '',
        keywordLocation => '/$ref/anyOf/'.$iter.'/required',
        absoluteKeywordLocation => SCHEMA.'#/anyOf/'.$iter++.'/required',
        error => 'missing property: '.$_,
      }, qw(paths components webhooks)),
      {
        instanceLocation => '',
        keywordLocation => '/$ref/anyOf',
        absoluteKeywordLocation => SCHEMA.'#/anyOf',
        error => 'no subschemas are valid',
      },
      (map +{
        instanceLocation => '/'.$_,
        keywordLocation => ignore,  # a $defs somewhere
        absoluteKeywordLocation => ignore,
        error => re(qr/^got string, not (object|array)$/),
      }, qw(externalDocs security servers tags)),
      {
        instanceLocation => '',
        keywordLocation => "/\$ref/properties",
        absoluteKeywordLocation => SCHEMA.'#/properties',
        error => 'not all properties are valid',
      },
      (ignore)x7, # useless unevaluatedProperties errors
    ],
    'missing paths (etc), and bad types for top level fields',
  );

  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => '3.1.0',
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      map +($_ => 'not an object'), qw(paths webhooks components),
    },
  );
  cmp_deeply(
    [ map $_->TO_JSON, $doc->errors ],
    [
      (map +{
        instanceLocation => '/'.$_,
        keywordLocation => ignore,  # a $defs somewhere
        absoluteKeywordLocation => ignore,
        error => 'got string, not object',
      }, qw(components paths webhooks)),
      {
        instanceLocation => '',
        keywordLocation => '/$ref/properties',
        absoluteKeywordLocation => SCHEMA.'#/properties',
        error => 'not all properties are valid',
      },
      (ignore)x6, # useless unevaluatedProperties errors
    ],
    'bad types for paths, webhooks, components',
  );

  $js = JSON::Schema::Modern->new;
  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => '3.1.0',
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      # no jsonSchemaDialect
      paths => {},
    },
  );

  cmp_deeply([ $doc->errors ], [], 'no errors with default jsonSchemaDialect');
  is($doc->json_schema_dialect, 'https://spec.openapis.org/oas/3.1/dialect/base', 'default jsonSchemaDialect is saved in the document');

  $js->add_schema($doc);
  cmp_deeply(
    $js->{_resource_index},
    superhashof({
      # our document itself is a resource, even if it isn't a json schema itself
      'http://localhost:1234/api' => {
        canonical_uri => str('http://localhost:1234/api'),
        path => '',
        specification_version => 'draft2020-12',
        document => shallow($doc),
        vocabularies => [ map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI) ],
        configs => {},
      },
      # the oas vocabulary, and the dialect that uses it
      (map +($_ => {
        canonical_uri => str('https://spec.openapis.org/oas/3.1/dialect/base'),
        path => '',
        specification_version => 'draft2020-12',
        document => ignore,
        vocabularies => ignore,
        configs => {},
      }), 'https://spec.openapis.org/oas/3.1/dialect/base', 'https://spec.openapis.org/oas/3.1/dialect/base#meta'),
      (map +($_ => {
        canonical_uri => str('https://spec.openapis.org/oas/3.1/meta/base'),
        path => '',
        specification_version => 'draft2020-12',
        document => ignore,
        vocabularies => ignore,
        configs => { collect_annotations => 1 },
      }), 'https://spec.openapis.org/oas/3.1/meta/base', 'https://spec.openapis.org/oas/3.1/meta/base#meta'),
    }),
    'resources are properly stored on the evaluator',
  );


  $js = JSON::Schema::Modern->new;
  $js->add_schema({
    '$id' => 'https://mymetaschema',
    '$vocabulary' => {
      'https://json-schema.org/draft/2020-12/vocab/core' => true,
      'https://json-schema.org/draft/2020-12/vocab/applicator' => false,
    },
  });

  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => '3.1.0',
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      jsonSchemaDialect => 'https://mymetaschema',
      paths => {},
    },
    metaschema_uri => 'https://spec.openapis.org/oas/3.1/schema', # '#meta' is now just {"type": ["object","boolean"]}
  );
  cmp_deeply([], [ map $_->TO_JSON, $doc->errors ], 'no errors with a custom jsonSchemaDialect');
  is($doc->json_schema_dialect, 'https://mymetaschema', 'custom jsonSchemaDialect is saved in the document');

  $js->add_schema($doc);
  cmp_deeply(
    $js->{_resource_index},
    superhashof({
      # our document itself is a resource, even if it isn't a json schema itself
      'http://localhost:1234/api' => {
        canonical_uri => str('http://localhost:1234/api'),
        path => '',
        specification_version => 'draft2020-12',
        document => shallow($doc),
        vocabularies => [ map 'JSON::Schema::Modern::Vocabulary::'.$_, qw(Core Applicator) ],
        configs => {},
      },
      (map +($_ => {
        canonical_uri => str('https://mymetaschema'),
        path => '',
        specification_version => 'draft2020-12',
        document => ignore,
        vocabularies => ignore,
        configs => {},
      }), 'https://mymetaschema'),
    }),
    'resources are properly stored on the evaluator',
  );
};

done_testing;
