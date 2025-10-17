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

use Test::Memory::Cycle;
use Feature::Compat::Try;

use lib 't/lib';
use Helper;

my $minimal_schema = {
  openapi => OAD_VERSION,
  info => {
    title => 'Test API',
    version => '1.2.3',
  },
  paths => {},
};

subtest 'missing arguments' => sub {
  die_result(
    sub { OpenAPI::Modern->new },
    qr/missing required constructor arguments: either openapi_document or openapi_schema/,
    'need something in constructor arguments',
  );

  die_result(
    sub { OpenAPI::Modern->new(openapi_uri => 'foo') },
    qr/missing required constructor arguments: either openapi_document or openapi_schema/,
    'need openapi_document or openapi_schema',
  );

  my $openapi;
  lives_result(
    sub {
      $openapi = OpenAPI::Modern->new(openapi_schema => $minimal_schema);
      memory_cycle_ok($openapi, 'no cycles');
    },
    'openapi_schema is sufficient',
  );

  lives_result(
    sub {
      $openapi = OpenAPI::Modern->new(
        openapi_uri => 'http://example.com/openapi.yaml',
        openapi_schema => $minimal_schema,
      );
      memory_cycle_ok($openapi, 'no cycles');
    },
    'canonical_uri and schema is sufficient',
  );

  cmp_result(
    $openapi->validate_request(request('GET', 'http://example.com'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => '/paths',
          absoluteKeywordLocation => 'http://example.com/openapi.yaml#/paths',
          error => 'no match found for request GET http://example.com',
        },
      ],
    },
    'validation can be performed with this OpenAPI object',
  );


  my $js = JSON::Schema::Modern->new;
  my $mymetaschema_doc = $js->add_schema({
    '$id' => 'https://mymetaschema',
    '$vocabulary' => {
      'https://json-schema.org/draft/2020-12/vocab/core' => true,
      'https://json-schema.org/draft/2020-12/vocab/applicator' => true,
    },
  });

  die_result(
    sub {
      OpenAPI::Modern->new(
        openapi_uri => 'http://example.com/openapi.yaml',
        openapi_schema => { %$minimal_schema, jsonSchemaDialect => 'https://mymetaschema' },
        # note: no evaluator!
      );
    },
    qr!EXCEPTION: unable to find resource "https://mymetaschema"!,
    'cannot load an OpenAPI using a dialect not known to the default evaluator',
  );


  lives_result(
    sub {
      $openapi = OpenAPI::Modern->new(
        openapi_uri => 'http://example.com/openapi.yaml',
        openapi_schema => { %$minimal_schema, jsonSchemaDialect => 'https://mymetaschema' },
        evaluator => $js,
      );
    },
    'no exception when the evaluator is provided that knows the dialect',
  );

  cmp_result(
    $openapi->evaluator->_fetch_from_uri('http://example.com/openapi.yaml'),
    superhashof({
      vocabularies => [ map 'JSON::Schema::Modern::Vocabulary::'.$_, qw(Core Applicator) ],
    }),
    'correct vocabulary list is being used for this OpenAPI document',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_document => JSON::Schema::Modern::Document::OpenAPI->new(
      canonical_uri => 'http://example.com/openapi.yaml',
      schema => $minimal_schema,
    ));

  # this works because the vocabulary list for the document was added to the evaluator
  # at OpenAPI construction time, and vocabulary classes are global.
  # What won't work (without further intervention) is trying to add a json schema that uses
  # the jsonSchemaDialect to the evaluator.
  cmp_result(
    $openapi->validate_request(request('GET', 'http://example.com'))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/request',
          keywordLocation => '/paths',
          absoluteKeywordLocation => 'http://example.com/openapi.yaml#/paths',
          error => 'no match found for request GET http://example.com',
        },
      ],
    },
    'validation can be performed with this OpenAPI object',
  );


  lives_result(
    sub {
      my $js = JSON::Schema::Modern->new(collect_annotations => 1);
      my $openapi = OpenAPI::Modern->new(
        openapi_document => JSON::Schema::Modern::Document::OpenAPI->new(
          canonical_uri => 'openapi.yaml',
          schema => $minimal_schema,
        ),
        evaluator => $js,
      );
      is($openapi->openapi_uri, 'openapi.yaml', 'got uri out of object');
      cmp_result($openapi->openapi_schema, $minimal_schema, 'got schema out of object');
      ok($openapi->evaluator->collect_annotations, 'original evaluator is still defined');
      memory_cycle_ok($openapi, 'no cycles');
    },
    'no exception when the document itself is provided',
  );

  lives_result(
    sub {
      my $openapi = OpenAPI::Modern->new(
        openapi_uri => 'openapi.yaml',
        openapi_schema => $minimal_schema,
        evaluator => JSON::Schema::Modern->new(validate_formats => 0),
      );
      is($openapi->openapi_uri, 'openapi.yaml', 'got uri out of object');
      cmp_result($openapi->openapi_schema, $minimal_schema, 'got schema out of object');
      ok(!$openapi->evaluator->validate_formats, 'evaluator overrides the default');
      memory_cycle_ok($openapi, 'no cycles');
    },
    'no exception when all other arguments are provided',
  );

  lives_result(
    sub {
      my $openapi = OpenAPI::Modern->new(
        openapi_uri => 'openapi.yaml',
        openapi_schema => $minimal_schema,
      );
      is($openapi->openapi_uri, 'openapi.yaml', 'got uri out of object');
      cmp_result($openapi->openapi_schema, $minimal_schema, 'got schema out of object');
      ok($openapi->evaluator->validate_formats, 'default evaluator is used');
      memory_cycle_ok($openapi, 'no cycles');
    },
    'no exception when evaluator is not provided',
  );
};

subtest 'document errors' => sub {
  die_result(
    sub { OpenAPI::Modern->new(openapi_uri => '/api', openapi_schema => [ 'invalid openapi document' ]) },
    qr/^Reference \["invalid openapi document"\] did not pass type constraint "HashRef"/,
    'bad document causes validation to immediately fail',
  );
};

subtest 'construct with document' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    schema => {
      %$minimal_schema,
      components => {
        schemas => {
          foo => true,
        },
      },
    },
  );

  cmp_result([$doc->errors], [], 'no errors during traversal');

  my $openapi = OpenAPI::Modern->new(
    openapi_document => $doc,
  );

  is(
    $openapi->openapi_uri,
    'http://localhost:1234/api',
    'canonical uri is taken from the document',
  );

  cmp_result(
    scalar $openapi->evaluator->get('http://localhost:1234/api#/components/schemas/foo'),
    true,
    'can construct an openapi object with a pre-existing document',
  );

  cmp_result(
    scalar $openapi->evaluator->get('https://spec.openapis.org/oas/'.OAS_VERSION.'/schema/latest#/type'),
    'object',
    'the main OAD schema is available from the evaluator used in OpenAPI::Modern construction',
  );

  cmp_result(
    $openapi->evaluator->_get_vocabulary_class('https://spec.openapis.org/oas/'.OAS_VERSION.'/vocab/base'),
    [
      'draft2020-12',
      'JSON::Schema::Modern::Vocabulary::OpenAPI',
    ],
    'the OpenAPI vocabulary is also available on the evaluator',
  );

  cmp_result(
    $openapi->evaluator->_get_format_validation('int32'),
    {
      type => 'number',
      sub => reftype('CODE'),
    },
    'OpenAPI format validations are also available on the evaluator',
  );
};

done_testing;
