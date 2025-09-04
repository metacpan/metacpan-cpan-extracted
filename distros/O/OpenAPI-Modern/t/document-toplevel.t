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
use Test::Warnings qw(:no_end_test warnings had_no_warnings);

use lib 't/lib';
use Helper;

use constant STRICT_DIALECT_URI => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/strict-dialect.json';
use constant STRICT_METASCHEMA_URI => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/strict-schema.json';

my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

subtest 'basic construction' => sub {
  cmp_result(
    [ warnings {
      JSON::Schema::Modern::Document::OpenAPI->new(
        canonical_uri => 'http://localhost:1234/api',
        schema => {},
        json_schema_dialect => 'https://example.com/metaschema',
      )
    } ],
    [ re(qr/^json_schema_dialect has been removed as a constructor attribute: use jsonSchemaDialect in your document instead/) ],
    'json_schema_dialect may no longer be overridden via the constructor',
  );

  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths: {}
YAML

  cmp_result(
    { $doc->resource_index },
    {
      'http://localhost:1234/api' => {
        path => '',
        canonical_uri => str('http://localhost:1234/api'),
        specification_version => 'draft2020-12',
        vocabularies => bag(OAS_VOCABULARIES->@*),
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
        schema => 1,
      );
    },
    qr/^Value "1" did not pass type constraint "HashRef"/,
    'document is wrong type',
  );


  my $doc;
  cmp_result(
    [ warnings {
      $doc = JSON::Schema::Modern::Document::OpenAPI->new(
        specification_version => 'draft7',
        schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  schemas:
    test_schema:
      $id: /foo/bar
YAML
    } ],
    [ re(qr/^specification_version argument is ignored by this subclass: use jsonSchemaDialect in your document instead/) ],
    'unsupported construction arguments (but supported in the base class) generate warnings',
  );

  cmp_result(
    $doc->{resource_index},
    {
      '' => {
        canonical_uri => str(''),
        path => '',
        specification_version => 'draft2020-12',
        vocabularies => bag(OAS_VOCABULARIES->@*),
      },
      '/foo/bar' => {
        canonical_uri => str('/foo/bar'),
        path => '/components/schemas/test_schema',
        specification_version => 'draft2020-12',
        vocabularies => bag(OAS_VOCABULARIES->@*),
      },
    },
    '...and also gracefully removed from consideration',
  );


  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
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
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
$self: '#frag\\ment'
YAML

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
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
jsonSchemaDialect: /foo
YAML

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


  my $js = JSON::Schema::Modern->new;
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
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
jsonSchemaDialect: https://metaschema/with/wrong/spec
YAML

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
};

subtest 'custom dialects via jsonSchemaDialect' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
# no jsonSchemaDialect
paths: {}
YAML

  cmp_result([ $doc->errors ], [], 'no errors with default jsonSchemaDialect');
  is($doc->metaschema_uri, DEFAULT_BASE_METASCHEMA, 'default metaschema is saved for the document');

  $js->add_document($doc);
  cmp_result(
    $js->{_resource_index},
    superhashof({
      # our document itself is a resource, even if it isn't a json schema itself
      'http://localhost:1234/api' => {
        canonical_uri => str('http://localhost:1234/api'),
        path => '',
        specification_version => 'draft2020-12',
        document => shallow($doc),
        vocabularies => bag(OAS_VOCABULARIES->@*),
      },
      # the oas vocabulary, and the dialect that uses it
      DEFAULT_DIALECT() => {
        canonical_uri => str(DEFAULT_DIALECT),
        path => '',
        specification_version => 'draft2020-12',
        document => ignore,
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated)),
        anchors => {
          meta => {
            path => '',
            canonical_uri => str(DEFAULT_DIALECT),
            dynamic => 1,
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
        anchors => {
          meta => {
            path => '',
            canonical_uri => str(OAS_VOCABULARY),
            dynamic => 1,
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
    metaschema_uri => DEFAULT_METASCHEMA, # '#meta' is now just {"type": ["object","boolean"]}
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
jsonSchemaDialect: https://mymetaschema
components:
  schemas:
    Foo:
      maxLength: false  # this is a bad schema, but our custom dialect does not detect that
YAML

  cmp_result([ $doc->errors ], [], 'no errors with a custom jsonSchemaDialect');
  is($doc->metaschema_uri, DEFAULT_METASCHEMA, 'default (permissive) metaschema is saved');

  $js->add_document($doc);
  cmp_result(
    $js->{_resource_index},
    superhashof({
      # our document itself is a resource, even if it isn't a json schema itself
      'http://localhost:1234/api' => {
        canonical_uri => str('http://localhost:1234/api'),
        path => '',
        specification_version => 'draft2020-12',
        document => shallow($doc),
        vocabularies => [ map 'JSON::Schema::Modern::Vocabulary::'.$_, qw(Core Applicator) ],
      },
      'https://mymetaschema' => {
        canonical_uri => str('https://mymetaschema'),
        path => '',
        specification_version => 'draft2020-12',
        document => shallow($mymetaschema_doc),
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated)),
      },
    }),
    'dialect resources are properly stored on the evaluator',
  );


  $js = JSON::Schema::Modern->new;
  $js->add_document($mymetaschema_doc);
  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    # metaschema_uri is not set, but autogenerated
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
jsonSchemaDialect: https://mymetaschema
components:
  schemas:
    Foo:
      maxLength: false,  # this is a bad schema, but our custom dialect does not detect that
YAML

  cmp_result([ $doc->errors ], [], 'no errors with a custom jsonSchemaDialect');
  like($doc->metaschema_uri, qr{^https://custom-dialect\.example\.com/[[:xdigit:]]{32}$}, 'dynamic metaschema is used');

  $js->add_document($doc);
  cmp_result(
    $js->{_resource_index},
    superhashof({
      # our document itself is a resource, even if it isn't a json schema itself
      'http://localhost:1234/api' => {
        canonical_uri => str('http://localhost:1234/api'),
        path => '',
        specification_version => 'draft2020-12',
        document => shallow($doc),
        vocabularies => [ map 'JSON::Schema::Modern::Vocabulary::'.$_, qw(Core Applicator) ],
      },
      'https://mymetaschema' => {
        canonical_uri => str('https://mymetaschema'),
        path => '',
        specification_version => 'draft2020-12',
        document => shallow($mymetaschema_doc),
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated)),
      },
      $doc->metaschema_uri => {
        canonical_uri => str($doc->metaschema_uri),
        path => '',
        specification_version => 'draft2020-12',
        document => ignore,
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated)),
        anchors => {
          meta => {
            path => '/$defs/schema',
            canonical_uri => str($doc->metaschema_uri.'#/$defs/schema'),
            dynamic => 1,
          },
        },
      },
    }),
    'dialect resources are properly stored on the evaluator',
  );
};

subtest 'custom dialects, via metaschema_uri' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    metaschema_uri => STRICT_METASCHEMA_URI,
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  schemas:
    Foo:
      blah: unrecognized keyword!
    Bar:
      x-todo: this one is okay
YAML

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

subtest 'custom dialects, via metaschema_uri and jsonSchemaDialect' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    metaschema_uri => STRICT_METASCHEMA_URI,
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<YAML));
jsonSchemaDialect: ${\ STRICT_DIALECT_URI() }
components:
  schemas:
    Foo:
      blah: unrecognized keyword!
    Bar:
      x-todo: this one is okay
YAML

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

subtest 'custom $self value' => sub {
  # relative $self, absolute original_uri - $self is resolved with original_uri
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/foo/api.json',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
$self: user/api.json  # the 'user' family of APIs
paths: {}
YAML

  is($doc->original_uri, 'http://localhost:1234/foo/api.json', 'retrieval uri');
  is($doc->canonical_uri, 'http://localhost:1234/foo/user/api.json', 'canonical uri is $self resolved against retrieval uri');
  cmp_result(
    $doc->{resource_index},
    {
      'http://localhost:1234/foo/user/api.json' => {
        canonical_uri => str('http://localhost:1234/foo/user/api.json'),
        path => '',
        specification_version => 'draft2020-12',
        vocabularies => bag(OAS_VOCABULARIES->@*),
      },
    },
    'resource is properly indexed',
  );


  # absolute $self, absolute original_uri - $self is used as is
  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/foo/api.json',
    evaluator => $js,
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
$self: http://localhost:5555/user/api.json  # the 'user' family of APIs
paths: {}
YAML

  is($doc->original_uri, 'http://localhost:1234/foo/api.json', 'retrieval uri');
  is($doc->canonical_uri, 'http://localhost:5555/user/api.json', 'canonical uri is $self, already absolute');
  cmp_result(
    $doc->{resource_index},
    {
      'http://localhost:5555/user/api.json' => {
        canonical_uri => str('http://localhost:5555/user/api.json'),
        path => '',
        specification_version => 'draft2020-12',
        vocabularies => bag(OAS_VOCABULARIES->@*),
      },
    },
    'resource is properly indexed',
  );


  # relative $self, relative original_uri - $self is resolved with original_uri
  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'foo/api.json',
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
$self: user/api.json  # the 'user' family of APIs
paths: {}
YAML

  is($doc->original_uri, 'foo/api.json', 'retrieval uri');
  is($doc->canonical_uri, 'foo/user/api.json', 'canonical uri is $self resolved against retrieval uri');
  cmp_result(
    $doc->{resource_index},
    {
      'foo/user/api.json' => {
        canonical_uri => str('foo/user/api.json'),
        path => '',
        specification_version => 'draft2020-12',
        vocabularies => bag(OAS_VOCABULARIES->@*),
      },
    },
    'resource is properly indexed',
  );


  # absolute $self, relative original_uri - $self is used as is
  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'foo/api.json',
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
$self: http://localhost:5555/user/api.json  # the 'user' family of APIs
paths: {}
YAML

  is($doc->original_uri, 'foo/api.json', 'retrieval uri');
  is($doc->canonical_uri, 'http://localhost:5555/user/api.json', 'canonical uri is $self, already absolute');
  cmp_result(
    $doc->{resource_index},
    {
      'http://localhost:5555/user/api.json' => {
        canonical_uri => str('http://localhost:5555/user/api.json'),
        path => '',
        specification_version => 'draft2020-12',
        vocabularies => bag(OAS_VOCABULARIES->@*),
      },
    },
    'resource is properly indexed',
  );
};

had_no_warnings() if $ENV{AUTHOR_TESTING};
done_testing;
