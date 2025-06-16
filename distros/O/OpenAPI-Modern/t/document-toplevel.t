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

subtest 'basic construction' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => {
      openapi => OAS_VERSION,
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

subtest 'top level document checks' => sub {
  die_result(
    sub {
      JSON::Schema::Modern::Document::OpenAPI->new(
        canonical_uri => 'http://localhost:1234/api',
        evaluator => JSON::Schema::Modern->new,
        schema => 1,
      );
    },
    qr/^Value "1" did not pass type constraint "HashRef"/,
    'document is wrong type',
  );


  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => {},
  );
  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '',
        keywordLocation => '/required',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/required',
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
      openapi => OAS_VERSION,
      info => {},
      paths => {},
    },
  );
  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '/info',
        keywordLocation => '/$ref/properties/info/$ref/required',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/$defs/info/required',
        error => 'object is missing properties: title, version',
      },
      {
        instanceLocation => '',
        keywordLocation => '/$ref/properties',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/properties',
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

  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '/openapi',
        keywordLocation => '/properties/openapi/pattern',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/properties/openapi/pattern',
        error => 'unrecognized openapi version 2.1.3',
      },
      {
        instanceLocation => '',
        keywordLocation => '/properties',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/properties',
        error => 'not all properties are valid',
      },
    ],
    'invalid openapi version',
  );


  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      jsonSchemaDialect => undef,
    },
  );
  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '/jsonSchemaDialect',
        keywordLocation => '/properties/jsonSchemaDialect/type',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/properties/jsonSchemaDialect/type',
        error => 'got null, not string',
      },
      {
        instanceLocation => '',
        keywordLocation => '/properties',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/properties',
        error => 'not all properties are valid',
      },
    ],
    'null jsonSchemaDialect is rejected',
  );
  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors');
'/jsonSchemaDialect': got null, not string
'': not all properties are valid
ERRORS


  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      '$self' => '#frag\\ment',
    },
  );

  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '/$self',
        keywordLocation => '/properties/$self/pattern',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/properties/$self/pattern',
        error => '$self cannot contain a fragment',
      },
      {
        instanceLocation => '/$self',
        keywordLocation => '/properties/$self/format',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/properties/$self/format',
        error => 'not a valid uri-reference string',
      },
      {
        instanceLocation => '',
        keywordLocation => '/properties',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/properties',
        error => 'not all properties are valid',
      },
    ],
    'invalid $self uri, with custom error message',
  );


  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      jsonSchemaDialect => '/foo',
    },
  );

  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '/jsonSchemaDialect',
        keywordLocation => '/properties/jsonSchemaDialect/format',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/properties/jsonSchemaDialect/format',
        error => 'not a valid uri string',
      },
      {
        instanceLocation => '',
        keywordLocation => '/properties',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/properties',
        error => 'not all properties are valid',
      },
    ],
    'invalid jsonSchemaDialect uri',
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
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      jsonSchemaDialect => 'https://metaschema/with/wrong/spec',
    },
  );

  cmp_result(
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
    evaluator => $js = JSON::Schema::Modern->new,
    schema => {
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      # no jsonSchemaDialect
      paths => {},
    },
  );

  cmp_result([ $doc->errors ], [], 'no errors with default jsonSchemaDialect');
  is($doc->json_schema_dialect, DEFAULT_DIALECT, 'default jsonSchemaDialect is saved in the document');

  $js->add_document($doc);
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
      DEFAULT_DIALECT() => {
        canonical_uri => str(DEFAULT_DIALECT),
        path => '',
        specification_version => 'draft2020-12',
        document => ignore,
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated)),
        configs => {},
        anchors => {
          meta => {
            path => '',
            canonical_uri => str(DEFAULT_DIALECT),
          },
        },
      },
      OAS_VOCABULARY() => {
        canonical_uri => str(OAS_VOCABULARY),
        path => '',
        specification_version => 'draft2020-12',
        document => ignore,
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated)),
        configs => {},
        anchors => {
          meta => {
            path => '',
            canonical_uri => str(OAS_VOCABULARY),
          },
        },
      },
    }),
    'dialect resources are properly stored on the evaluator',
  );


  $js = JSON::Schema::Modern->new;
  my $mymetaschema_doc = $js->add_schema({
    '$id' => 'https://mymetaschema',
    '$vocabulary' => {
      'https://json-schema.org/draft/2020-12/vocab/core' => true,
      'https://json-schema.org/draft/2020-12/vocab/applicator' => true,
    },
  });


  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      jsonSchemaDialect => 'https://mymetaschema',
      components => {
        schemas => {
          Foo => {
            maxLength => false,  # this is a bad schema, but our custom dialect does not detect that
          },
        },
      },
    },
    metaschema_uri => DEFAULT_METASCHEMA, # '#meta' is now just {"type": ["object","boolean"]}
  );
  cmp_result([ $doc->errors ], [], 'no errors with a custom jsonSchemaDialect');
  is($doc->json_schema_dialect, 'https://mymetaschema', 'custom jsonSchemaDialect is saved in the document');
  is($doc->metaschema_uri, DEFAULT_METASCHEMA, 'custom metaschema is saved');

  $js->add_document($doc);
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
      'https://mymetaschema' => {
        canonical_uri => str('https://mymetaschema'),
        path => '',
        specification_version => 'draft2020-12',
        document => shallow($mymetaschema_doc),
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated)),
        configs => {},
      },
    }),
    'dialect resources are properly stored on the evaluator',
  );


  $js = JSON::Schema::Modern->new;
  $js->add_document($mymetaschema_doc);
  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      jsonSchemaDialect => 'https://mymetaschema',
      components => {
        schemas => {
          Foo => {
            maxLength => false,  # this is a bad schema, but our custom dialect does not detect that
          },
        },
      },
    },
    # metaschema_uri is not set, but autogenerated
  );
  cmp_result([ $doc->errors ], [], 'no errors with a custom jsonSchemaDialect');
  is($doc->json_schema_dialect, 'https://mymetaschema', 'custom jsonSchemaDialect is saved in the document');
  like($doc->metaschema_uri, qr{^https://custom-dialect\.example\.com/[[:xdigit:]]{32}$}, 'dynamic metaschema is used');

  $js->add_document($doc);
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
      'https://mymetaschema' => {
        canonical_uri => str('https://mymetaschema'),
        path => '',
        specification_version => 'draft2020-12',
        document => shallow($mymetaschema_doc),
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated)),
        configs => {},
      },
      $doc->metaschema_uri => {
        canonical_uri => str($doc->metaschema_uri),
        path => '',
        specification_version => 'draft2020-12',
        document => ignore,
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated)),
        configs => {},
        anchors => {
          meta => {
            path => '/$defs/schema',
            canonical_uri => str($doc->metaschema_uri.'#/$defs/schema'),
          },
        },
      },
    }),
    'dialect resources are properly stored on the evaluator',
  );


  # relative $self, absolute original_uri - $self is resolved with original_uri
  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/foo/api.json',
    evaluator => $js,
    schema => {
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      '$self' => 'user/api.json',  # the 'user' family of APIs
      paths => {},
    },
  );

  is($doc->original_uri, 'http://localhost:1234/foo/api.json', 'retrieval uri');
  is($doc->canonical_uri, 'http://localhost:1234/foo/user/api.json', 'canonical uri is $self resolved against retrieval uri');
  cmp_deeply(
    $doc->{resource_index},
    {
      'http://localhost:1234/foo/user/api.json' => {
        canonical_uri => str('http://localhost:1234/foo/user/api.json'),
        path => '',
        specification_version => 'draft2020-12',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
        configs => {},
      },
    },
    'resource is properly indexed',
  );


  # absolute $self, absolute original_uri - $self is used as is
  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/foo/api.json',
    evaluator => $js,
    schema => {
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      '$self' => 'http://localhost:5555/user/api.json',  # the 'user' family of APIs
      paths => {},
    },
  );

  is($doc->original_uri, 'http://localhost:1234/foo/api.json', 'retrieval uri');
  is($doc->canonical_uri, 'http://localhost:5555/user/api.json', 'canonical uri is $self, already absolute');
  cmp_deeply(
    $doc->{resource_index},
    {
      'http://localhost:5555/user/api.json' => {
        canonical_uri => str('http://localhost:5555/user/api.json'),
        path => '',
        specification_version => 'draft2020-12',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
        configs => {},
      },
    },
    'resource is properly indexed',
  );


  # relative $self, relative original_uri - $self is resolved with original_uri
  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'foo/api.json',
    evaluator => $js,
    schema => {
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      '$self' => 'user/api.json',  # the 'user' family of APIs
      paths => {},
    },
  );

  is($doc->original_uri, 'foo/api.json', 'retrieval uri');
  is($doc->canonical_uri, 'foo/user/api.json', 'canonical uri is $self resolved against retrieval uri');
  cmp_deeply(
    $doc->{resource_index},
    {
      'foo/user/api.json' => {
        canonical_uri => str('foo/user/api.json'),
        path => '',
        specification_version => 'draft2020-12',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
        configs => {},
      },
    },
    'resource is properly indexed',
  );


  # absolute $self, relative original_uri - $self is used as is
  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'foo/api.json',
    evaluator => $js,
    schema => {
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      '$self' => 'http://localhost:5555/user/api.json',  # the 'user' family of APIs
      paths => {},
    },
  );

  is($doc->original_uri, 'foo/api.json', 'retrieval uri');
  is($doc->canonical_uri, 'http://localhost:5555/user/api.json', 'canonical uri is $self, already absolute');
  cmp_deeply(
    $doc->{resource_index},
    {
      'http://localhost:5555/user/api.json' => {
        canonical_uri => str('http://localhost:5555/user/api.json'),
        path => '',
        specification_version => 'draft2020-12',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
        configs => {},
      },
    },
    'resource is properly indexed',
  );
};

done_testing;
