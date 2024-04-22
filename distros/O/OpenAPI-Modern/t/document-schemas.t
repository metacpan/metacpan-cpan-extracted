# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::Fatal;

use lib 't/lib';
use Helper;

# the document where most constraints are defined
use constant SCHEMA => 'https://spec.openapis.org/oas/3.1/schema/2022-10-07';

my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');
my $openapi_preamble = <<'YAML';
---
openapi: 3.1.0
info:
  title: Test API
  version: 1.2.3
YAML

subtest 'bad subschemas' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new(validate_formats => 1),
    schema => {
      $yamlpp->load_string($openapi_preamble)->%*,
      jsonSchemaDialect => JSON::Schema::Modern::Document::OpenAPI->DEFAULT_DIALECT,
      components => {
        schemas => {
          alpha_schema => {
            '$id' => 'alpha',
            not => {
              minimum => 'not a number',
            },
          },
        },
      },
    },
  );

  cmp_deeply(
    ($doc->errors)[0],
    methods(
      instance_location => '/components/schemas/alpha_schema/not/minimum',
      keyword_location => re(qr{/\$ref/properties/minimum/type$}),
      absolute_keyword_location => str('https://json-schema.org/draft/2020-12/meta/validation#/properties/minimum/type'),
      error => 'got string, not number',
      mode => 'evaluate',
    ),
    'subschemas identified, and error found',
  );

  is(
    index(document_result($doc), "'/components/schemas/alpha_schema/not/minimum': got string, not number\n"), 0,
    'errors serialize using the instance locations within the document',
  );
  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors');
'/components/schemas/alpha_schema/not/minimum': got string, not number
'/components/schemas/alpha_schema/not': not all properties are valid
'/components/schemas/alpha_schema/not': subschema 3 is not valid
'/components/schemas/alpha_schema/not': subschema 0 is not valid
'/components/schemas/alpha_schema': not all properties are valid
'/components/schemas/alpha_schema': subschema 1 is not valid
'/components/schemas/alpha_schema': subschema 0 is not valid
'/components/schemas': not all additional properties are valid
'/components': not all properties are valid
'': not all properties are valid
ERRORS
};

subtest 'identify subschemas and other entities' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    metaschema_uri => 'https://spec.openapis.org/oas/3.1/schema',
    evaluator => my $js = JSON::Schema::Modern->new(validate_formats => 1),
    schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
components:
  schemas:
    beta_schema:
      \$id: beta
      not:
        \$id: gamma
        \$schema: https://json-schema.org/draft/2019-09/schema
  parameters:
    my_param1:
      name: param1
      in: query
      schema:
        \$id: parameter1_id
    my_param2:
      name: param2
      in: query
      content:
        media_type_0:
          schema:
            \$id: parameter2_id
  responses:
    my_response4:
      description: bad response
      content:
        media_type_4:
          schema:
            \$comment: nothing to see here
  pathItems:
    path0:
      parameters:
        - name: param0
          in: query
          schema:
            \$id: pathItem0_param_id
        # TODO param2 with content/media_type_0
      get:
        parameters:
          - name: param1
            in: query
            schema:
              \$id: pathItem0_get_param_id
        requestBody:
          content:
            media_type_1:
              schema:
                \$id: pathItem0_get_requestBody_id
        responses:
          200:
            description: normal response
            content:
              media_type_2:
                schema:
                  \$id: pathItem0_get_responses2_id
              media_type_3:
                schema:
                  \$id: pathItem0_get_responses3_id
          default:
            \$ref: '#/components/responses/my_response4'
YAML

  is($doc->errors, 0, 'no errors during traversal');
  cmp_deeply(
    my $index = { $doc->resource_index },
    {
      'http://localhost:1234/api' => {
        path => '',
        canonical_uri => str('http://localhost:1234/api'),
        specification_version => 'draft2020-12',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
        configs => {},
      },
      'http://localhost:1234/beta' => {
        path => '/components/schemas/beta_schema',
        canonical_uri => str('http://localhost:1234/beta'),
        specification_version => 'draft2020-12',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
        configs => {},
      },
      'http://localhost:1234/gamma' => {
        path => '/components/schemas/beta_schema/not',
        canonical_uri => str('http://localhost:1234/gamma'),
        specification_version => 'draft2019-09',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData)), # overridden "$schema" keyword
        configs => {},
      },
      'http://localhost:1234/parameter1_id' => {
        path => '/components/parameters/my_param1/schema',
        canonical_uri => str('http://localhost:1234/parameter1_id'),
        specification_version => 'draft2020-12',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
        configs => {},
      },
      'http://localhost:1234/parameter2_id' => {
        path => '/components/parameters/my_param2/content/media_type_0/schema',
        canonical_uri => str('http://localhost:1234/parameter2_id'),
        specification_version => 'draft2020-12',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
        configs => {},
      },
      'http://localhost:1234/pathItem0_param_id' => {
        path => '/components/pathItems/path0/parameters/0/schema',
        canonical_uri => str('http://localhost:1234/pathItem0_param_id'),
        specification_version => 'draft2020-12',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
        configs => {},
      },
      'http://localhost:1234/pathItem0_get_param_id' => {
        path => '/components/pathItems/path0/get/parameters/0/schema',
        canonical_uri => str('http://localhost:1234/pathItem0_get_param_id'),
        specification_version => 'draft2020-12',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
        configs => {},
      },
      'http://localhost:1234/pathItem0_get_requestBody_id' => {
        path => '/components/pathItems/path0/get/requestBody/content/media_type_1/schema',
        canonical_uri => str('http://localhost:1234/pathItem0_get_requestBody_id'),
        specification_version => 'draft2020-12',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
        configs => {},
      },
      map +('http://localhost:1234/pathItem0_get_responses'.$_.'_id' => {
        path => '/components/pathItems/path0/get/responses/200/content/media_type_'.$_.'/schema',
        canonical_uri => str('http://localhost:1234/pathItem0_get_responses'.$_.'_id'),
        specification_version => 'draft2020-12',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI)),
        configs => {},
      }), 2..3,
    },
    'subschema resources are correctly identified in the document',
  );

  cmp_deeply(
    $doc->_entities,
    {
      '/components/parameters/my_param1' => 2,
      '/components/parameters/my_param1/schema' => 0,
      '/components/parameters/my_param2' => 2,
      '/components/parameters/my_param2/content/media_type_0/schema' => 0,
      '/components/pathItems/path0' => 9,
      '/components/pathItems/path0/get/parameters/0' => 2,
      '/components/pathItems/path0/get/parameters/0/schema' => 0,
      '/components/pathItems/path0/get/requestBody' => 4,
      '/components/pathItems/path0/get/requestBody/content/media_type_1/schema' => 0,
      '/components/pathItems/path0/get/responses/200' => 1,
      '/components/pathItems/path0/get/responses/200/content/media_type_2/schema' => 0,
      '/components/pathItems/path0/get/responses/200/content/media_type_3/schema' => 0,
      '/components/pathItems/path0/get/responses/default' => 1,
      '/components/pathItems/path0/parameters/0' => 2,
      '/components/pathItems/path0/parameters/0/schema' => 0,
      '/components/responses/my_response4' => 1,
      '/components/responses/my_response4/content/media_type_4/schema' => 0,
      '/components/schemas/beta_schema' => 0,
      '/components/schemas/beta_schema/not' => 0,
    },
    'all entity locations are identified',
  );
};

subtest 'invalid servers entries' => sub {
  my $servers = $yamlpp->load_string(<<YAML);
servers:
  - url: https://example.com/{version}/{greeting}
    variables:
      version:
        default: v1
        enum: [v2, v3]
      greeting:
        default: hi
      unused:
        default: nope
  - url: https://example.com/{v}/{greeting}
  - url: https://example.com/{foo}
    variables: {}
  - url: http://example.com/literal
    variables:
      version:
        default: v1
        enum: [v2, v3]
  - url: http://example.com/literal2
YAML

  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    metaschema_uri => 'https://spec.openapis.org/oas/3.1/schema',
    # Note: OpenAPI::Modern sets this value to true, but the current 3.1 schema disallows templated
    # server urls (via the uri-reference format requirement).
    evaluator => my $js = JSON::Schema::Modern->new(validate_formats => 0),
    schema => {
      $yamlpp->load_string($openapi_preamble)->%*,
      %$servers,
      components => {
        pathItems => {
          path0 => {
            %$servers,
            get => $servers,
          },
        },
      },
    },
  );

  cmp_deeply(
    [ $doc->errors ],
    [
      map +(
        methods(TO_JSON => {
          instanceLocation => $_.'/servers/0/variables/version/default',
          keywordLocation => '',
          absoluteKeywordLocation => SCHEMA,
          error => 'servers default is not a member of enum',
        }),
        methods(TO_JSON => {
          instanceLocation => $_.'/servers/1/url',
          keywordLocation => '',
          absoluteKeywordLocation => SCHEMA,
          error => 'duplicate of templated server url "https://example.com/{version}/{greeting}"',
        }),
        methods(TO_JSON => {
          instanceLocation => $_.'/servers/1',
          keywordLocation => '',
          absoluteKeywordLocation => SCHEMA,
          error => '"variables" property is required for templated server urls',
        }),
        methods(TO_JSON => {
          instanceLocation => $_.'/servers/2/variables',
          keywordLocation => '',
          absoluteKeywordLocation => SCHEMA,
          error => 'missing "variables" definition for templated variable "foo"',
        }),
        methods(TO_JSON => {
          instanceLocation => $_.'/servers/3/variables/version/default',
          keywordLocation => '',
          absoluteKeywordLocation => SCHEMA,
          error => 'servers default is not a member of enum',
        }),
      ), '', '/components/pathItems/path0', '/components/pathItems/path0/get',
    ],
    'all issues with server entries found',
  );
};

done_testing;
