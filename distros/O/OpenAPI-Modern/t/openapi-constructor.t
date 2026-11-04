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

use lib 't/lib';
use Helper;
use Test::Memory::Cycle;
use Feature::Compat::Try;

my $minimal_schema = {
  openapi => OAD_VERSION,
  info => {
    title => 'Test API',
    version => '1.2.3',
  },
  paths => {},
};

subtest 'constructor arguments' => sub {
  die_result(
    sub { OpenAPI::Modern->new },
    qr/^missing required constructor arguments: either "documents", "openapi_document", or "openapi_schema"/,
    'need something in constructor arguments',
  );

  die_result(
    sub { OpenAPI::Modern->new(openapi_uri => 'foo') },
    qr/^missing required constructor arguments: either "documents", "openapi_document", or "openapi_schema"/,
    'need openapi_document(s) or openapi_schema',
  );

  die_result(
    sub { OpenAPI::Modern->new(openapi_document => 1, documents => 1) },
    qr/^cannot provide both "openapi_document" and "documents"/,
    'incompatible arguments',
  );

  die_result(
    sub { OpenAPI::Modern->new(openapi_documents => []) },
    qr/^cannot provide "openapi_documents"; use "documents" instead/,
    'unsupported argument',
  );


  my $openapi;
  lives_result(
    sub {
      $openapi = OpenAPI::Modern->new(openapi_schema => $minimal_schema);
      memory_cycle_ok($openapi, 'no cycles');
    },
    'openapi_schema is sufficient',
  );

  cmp_result(
    $openapi->openapi_documents,
    [ isa('JSON::Schema::Modern::Document::OpenAPI') ],
    'schema is used to construct an openapi document',
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

  is($openapi->entry_document->canonical_uri, 'http://example.com/openapi.yaml', 'doc uri is saved');

  is_equal(
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
      $openapi = OpenAPI::Modern->new(
        openapi_document => JSON::Schema::Modern::Document::OpenAPI->new(
          canonical_uri => 'http://example.com/openapi.yaml',
          schema => $minimal_schema,
        )
      );
      memory_cycle_ok($openapi, 'no cycles');
    },
    'openapi_document is sufficient',
  );
};

subtest 'construction with explicit document list' => sub {
  die_result(
    sub { OpenAPI::Modern->new(documents => $_) },
    qr/^"documents" must be a non-empty array/,
    '"documents" is invalid: '.$::dumper->encode($_),
  ) foreach undef, 'not an array', {}, [];

  die_result(
    sub { OpenAPI::Modern->new(documents => [ $_ ]) },
    qr/^the first document must be a JSON::Schema::Modern::Document::OpenAPI object/,
    'first document must be a blessed OpenAPI document',
  ) foreach undef, 'string', false, true, {}, [], JSON::Schema::Modern::Document->new(schema => {});

  die_result(
    sub {
      OpenAPI::Modern->new(documents => [
        JSON::Schema::Modern::Document::OpenAPI->new(schema => decode_yaml(OPENAPI_PREAMBLE."\npaths: {}\n")),
        $_,
      ])
    },
    qr/all "documents" must be JSON::Schema::Modern::Document::OpenAPI or JSON::Schema::Modern::Document objects/,
    'all "documents" values must be valid documents',
  ) foreach undef, 'string', false, true, {}, [];


  my $evaluator = JSON::Schema::Modern->new;

  my $doc1 = JSON::Schema::Modern::Document::OpenAPI->new(
    evaluator => $evaluator,
    schema => my $schema1 = decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
$self: http://example.com/main_api
components:
  responses:
    response0:
      $ref: 'http://example.com/external_doc#/components/responses/foo'
  schemas:
    schema0:
      $ref: 'http://example.com/schemas#/$defs/my_schema0'
YAML

  my $doc2 = JSON::Schema::Modern::Document::OpenAPI->new(
    evaluator => $evaluator,
    schema => my $schema2 = decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
$self: http://example.com/secondary_api
components:
  responses:
    response1:
      $ref: 'http://example.com/external_doc#/components/responses/bar'
  schemas:
    schema1:
      $ref: 'http://example.com/schemas#/$defs/my_schema1'
YAML

  cmp_result(
    [ $doc1->_deferred_references, $doc2->_deferred_references ],
    [
      [
        [ '$ref', '/components/responses/response0', str('http://example.com/external_doc#/components/responses/foo'), 'response' ],
        [ '$ref', '/components/schemas/schema0', str('http://example.com/schemas#/$defs/my_schema0'), 'schema' ],
      ],
      [
        [ '$ref', '/components/responses/response1', str('http://example.com/external_doc#/components/responses/bar'), 'response' ],
        [ '$ref', '/components/schemas/schema1', str('http://example.com/schemas#/$defs/my_schema1'), 'schema' ],
      ],
    ],
    'references to external docs that cannot be verified are identified for each document',
  );

  my $openapi = OpenAPI::Modern->new(documents => [ $doc1, $doc2,
    my $doc3 = JSON::Schema::Modern::Document::OpenAPI->new(
      evaluator => $evaluator,
      schema => my $schema3 = decode_yaml(OPENAPI_PREAMBLE.<<'YAML')),
$self: http://example.com/external_doc
components:
  responses:
    foo: {}
    bar: {}
YAML
    my $doc4 = JSON::Schema::Modern::Document->new(
      evaluator => $evaluator,
      schema => my $schema4 = decode_yaml(<<'YAML')),
$id: http://example.com/schemas
$defs:
  my_schema0: {}
  my_schema1: {}
YAML
  ]);

  is_equal(
    [ map $_->_deferred_references, $doc1, $doc2, $doc3, $doc4 ],
    [ ([])x4 ],
    'deferred references are now removed, as they resolve to the third doc now added',
  );

  $openapi = OpenAPI::Modern->new(documents => my $documents = [
    (map +JSON::Schema::Modern::Document::OpenAPI->new(evaluator => $evaluator, schema => $_),
      $schema1, $schema2, $schema3),
    JSON::Schema::Modern::Document->new(evaluator => $evaluator, schema => $schema4),
  ]);

  is_equal(
    [ map $_->_deferred_references, $documents->@* ],
    [ ([])x4 ],
    'deferred references are resolved automatically when all documents are added at once',
  );
};

subtest 'custom dialects' => sub {
  my $js = JSON::Schema::Modern->new;
  my $my_custom_dialect_doc = $js->add_schema({
    '$id' => 'https://my_custom_dialect',
    '$vocabulary' => {
      'https://json-schema.org/draft/2020-12/vocab/core' => true,
      'https://json-schema.org/draft/2020-12/vocab/applicator' => true,
    },
  });

  die_result(
    sub {
      OpenAPI::Modern->new(
        openapi_uri => 'http://example.com/openapi.yaml',
        openapi_schema => { %$minimal_schema, jsonSchemaDialect => 'https://my_custom_dialect' },
        # note: no evaluator!
      );
    },
    qr!EXCEPTION: unable to find resource "https://my_custom_dialect"!,
    'cannot load an OpenAPI using a dialect not known to the default evaluator',
  );


  my $openapi;
  lives_result(
    sub {
      $openapi = OpenAPI::Modern->new(
        openapi_uri => 'http://example.com/openapi.yaml',
        openapi_schema => { %$minimal_schema, jsonSchemaDialect => 'https://my_custom_dialect' },
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
  is_equal(
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
      is($openapi->entry_document->canonical_uri, 'openapi.yaml', 'got uri out of object');
      is_equal($openapi->entry_document->schema, $minimal_schema, 'got schema out of object');
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
      is($openapi->entry_document->canonical_uri, 'openapi.yaml', 'got uri out of object');
      is_equal($openapi->entry_document->schema, $minimal_schema, 'got schema out of object');
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
      is($openapi->entry_document->canonical_uri, 'openapi.yaml', 'got uri out of object');
      is_equal($openapi->entry_document->schema, $minimal_schema, 'got schema out of object');
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

  is_equal([$doc->errors], [], 'no errors during traversal');

  my $openapi = OpenAPI::Modern->new(
    openapi_document => $doc,
  );

  is(
    $openapi->entry_document->canonical_uri,
    'http://localhost:1234/api',
    'canonical uri is taken from the document',
  );

  is_equal(
    scalar $openapi->evaluator->get('http://localhost:1234/api#/components/schemas/foo'),
    true,
    'can construct an openapi object with a pre-existing document',
  );

  is_equal(
    scalar $openapi->evaluator->get('https://spec.openapis.org/oas/'.OAS_VERSION.'/schema/latest#/type'),
    'object',
    'the main OAD schema is available from the evaluator used in OpenAPI::Modern construction',
  );

  is_equal(
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
