# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use lib 't/lib';
use Helper;

# the document where most constraints are defined
use constant SCHEMA => 'https://spec.openapis.org/oas/3.1/schema/2022-10-07';

subtest 'basic construction' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new(validate_formats => 1),
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
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
        configs => {},
      },
    },
    'the document itself is recorded as a resource',
  );
};

subtest 'top level document fields' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new(validate_formats => 1),
    schema => 1,
  );

  cmp_deeply(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '',
        keywordLocation => '/type',
        absoluteKeywordLocation => SCHEMA.'#/type',
        error => 'got integer, not object',
      },
    ],
    'document is wrong type',
  );

  is(
    document_result($doc),
    q!'': got integer, not object!,
    'stringified errors',
  );


  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js = JSON::Schema::Modern->new(validate_formats => 1),
    schema => {},
  );
  cmp_deeply(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '',
        keywordLocation => '/required',
        absoluteKeywordLocation => SCHEMA.'#/required',
        error => 'object is missing property: openapi',
      },
    ],
    'missing openapi',
  );
  is(
    document_result($doc),
    q!'': object is missing property: openapi!,
    'stringified errors',
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
        error => 'object is missing properties: title, version',
      },
      {
        instanceLocation => '',
        keywordLocation => '/$ref/properties',
        absoluteKeywordLocation => SCHEMA.'#/properties',
        error => 'not all properties are valid',
      },
    ],
    'missing /info properties',
  );
  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors');
'/info': object is missing properties: title, version
'': not all properties are valid
ERRORS


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
        instanceLocation => '/openapi',
        keywordLocation => '/properties/openapi/pattern',
        absoluteKeywordLocation => SCHEMA.'#/properties/openapi/pattern',
        error => 'unrecognized openapi version 2.1.3',
      },
      {
        instanceLocation => '',
        keywordLocation => '/properties',
        absoluteKeywordLocation => SCHEMA.'#/properties',
        error => 'not all properties are valid',
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
        instanceLocation => '/jsonSchemaDialect',
        keywordLocation => '/properties/jsonSchemaDialect/type',
        absoluteKeywordLocation => SCHEMA.'#/properties/jsonSchemaDialect/type',
        error => 'got null, not string',
      },
      {
        instanceLocation => '',
        keywordLocation => '/properties',
        absoluteKeywordLocation => SCHEMA.'#/properties',
        error => 'not all properties are valid',
      },
    ],
    'null jsonSchemaDialect is rejected',
  );
  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors');
'/jsonSchemaDialect': got null, not string
'': not all properties are valid
ERRORS


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

  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors');
'/jsonSchemaDialect/$vocabulary/https:~1~1unknown': "https://unknown" is not a known vocabulary
'/jsonSchemaDialect': "https://metaschema/with/wrong/spec" is not a valid metaschema
ERRORS


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
        error => 'object is missing property: '.$_,
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
    ],
    'missing paths (etc), and bad types for top level fields',
  );

  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors');
'': object is missing property: paths
'': object is missing property: components
'': object is missing property: webhooks
'': no subschemas are valid
'/externalDocs': got string, not object
'/security': got string, not array
'/servers': got string, not array
'/tags': got string, not array
'': not all properties are valid
ERRORS


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
    ],
    'bad types for paths, webhooks, components',
  );
  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors');
'/components': got string, not object
'/paths': got string, not object
'/webhooks': got string, not object
'': not all properties are valid
ERRORS


  $js = JSON::Schema::Modern->new(validate_formats => 1);
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

  $js->${$JSON::Schema::Modern::VERSION < 0.591 ? \'add_schema' : \'add_document'}($doc);
  cmp_deeply(
    $js->{_resource_index},
    superhashof({
      # our document itself is a resource, even if it isn't a json schema itself
      'http://localhost:1234/api' => {
        canonical_uri => str('http://localhost:1234/api'),
        path => '',
        specification_version => 'draft2020-12',
        document => shallow($doc),
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
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
        configs => { eval { JSON::Schema::Modern->VERSION('0.561'); 1 } ? () : ( collect_annotations => 1 ) },
      }), 'https://spec.openapis.org/oas/3.1/meta/base', 'https://spec.openapis.org/oas/3.1/meta/base#meta'),
    }),
    'resources are properly stored on the evaluator',
  );


  $js = JSON::Schema::Modern->new(validate_formats => 1);
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

  $js->${$JSON::Schema::Modern::VERSION < 0.591 ? \'add_schema' : \'add_document'}($doc);
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
