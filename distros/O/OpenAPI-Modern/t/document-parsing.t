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

use Test::Memory::Cycle;
use lib 't/lib';
use Helper;

my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

subtest 'basic document validation' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => {
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
        contact => { url => '/foo' },
      },
      map +($_ => 'not an object'), qw(servers security tags externalDocs),
    },
  );
  my $iter = 0;
  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [
      (map +{
        instanceLocation => '',
        keywordLocation => '/$ref/anyOf/'.$iter.'/required',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/anyOf/'.$iter++.'/required',
        error => 'object is missing property: '.$_,
      }, qw(paths components webhooks)),
      {
        instanceLocation => '',
        keywordLocation => '/$ref/anyOf',
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/anyOf',
        error => 'no subschemas are valid',
      },
      do {
        my @e = (map +{
          instanceLocation => '/'.$_,
          keywordLocation => ignore,  # a $defs somewhere
          absoluteKeywordLocation => ignore,
          error => re(qr/^got string, not (object|array)$/),
        }, qw(externalDocs security servers tags));
        splice @e, 1, 0,
          {
            instanceLocation => '/info/contact/url',
            keywordLocation => ignore,  # a $defs somewhere
            absoluteKeywordLocation => ignore,
            error => 'not a valid uri string',
          },
          {
            instanceLocation => '/info/contact',
            keywordLocation => ignore,  # a $defs somewhere
            absoluteKeywordLocation => ignore,
            error => 'not all properties are valid',
          },
          {
            instanceLocation => '/info',
            keywordLocation => ignore,  # a $defs somewhere
            absoluteKeywordLocation => ignore,
            error => 'not all properties are valid',
          };
        @e;
      },
      {
        instanceLocation => '',
        keywordLocation => "/\$ref/properties",
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/properties',
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
'/info/contact/url': not a valid uri string
'/info/contact': not all properties are valid
'/info': not all properties are valid
'/security': got string, not array
'/servers': got string, not array
'/tags': got string, not array
'': not all properties are valid
ERRORS

  memory_cycle_ok($doc, 'no leaks in the document object');


  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => {
      openapi => OAS_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      map +($_ => 'not an object'), qw(paths webhooks components),
    },
  );
  cmp_result(
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
        absoluteKeywordLocation => DEFAULT_METASCHEMA.'#/properties',
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

  memory_cycle_ok($doc, 'no leaks in the document object');
};

subtest 'bad subschemas' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => {
      $yamlpp->load_string(OPENAPI_PREAMBLE)->%*,
      jsonSchemaDialect => DEFAULT_DIALECT,
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

  cmp_result(
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

  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors use the instance locations');
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

  memory_cycle_ok($doc, 'no leaks in the document object');
};

subtest 'identify subschemas and other entities' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  schemas:
    alpha:
      properties:
        alpha1:
          $id: alpha_id
        alpha2:
          $comment: this collision will be found by JSM as it is in the same subschema
          $id: alpha_id
        alpha3:
          $anchor: alpha_anchor
        alpha4:
          $comment: this collision will be found by JSM as it is in the same subschema
          $anchor: alpha_anchor
    beta:
      properties:
        beta1:
          $comment: this collision will not be found until JSMDO combines extracted identifiers together
          $id: alpha_id
        beta2:
          $comment: ditto
          $anchor: alpha_anchor
        beta3:
          $id: beta_id
    gamma:
      properties:
        gamma1:
          $comment: this will collide with beta3
          $id: beta_id
        gamma2:
          $comment: this will collide with alpha3
          $anchor: alpha_anchor
YAML

  cmp_result(
    [ $doc->errors ],
    [
      methods(
        instance_location => '',
        keyword_location => '/components/schemas/alpha/properties/alpha2/$id',
        error => 'duplicate canonical uri "http://localhost:1234/alpha_id" found (original at path "/components/schemas/alpha/properties/alpha1")',
        mode => 'traverse',
      ),
      methods(
        instance_location => '',
        keyword_location => '/components/schemas/alpha/properties/alpha4/$anchor',
        error => 'duplicate anchor uri "http://localhost:1234/api#alpha_anchor" found (original at path "/components/schemas/alpha/properties/alpha3")',
        mode => 'traverse',
      ),
      methods(
        instance_location => '',
        keyword_location => '/components/schemas/beta/properties/beta1',
        error => 'duplicate canonical uri "http://localhost:1234/alpha_id" found (original at path "/components/schemas/alpha/properties/alpha1")',
        mode => 'traverse',
      ),
      methods(
        instance_location => '',
        keyword_location => '/components/schemas/beta/properties/beta2',
        error => 'duplicate anchor uri "http://localhost:1234/api#alpha_anchor" found (original at path "/components/schemas/alpha/properties/alpha3")',
        mode => 'traverse',
      ),
      methods(
        instance_location => '',
        keyword_location => '/components/schemas/gamma/properties/gamma2',
        error => 'duplicate anchor uri "http://localhost:1234/api#alpha_anchor" found (original at path "/components/schemas/alpha/properties/alpha3")',
        mode => 'traverse',
      ),
      methods(
        instance_location => '',
        keyword_location => '/components/schemas/gamma/properties/gamma1',
        error => 'duplicate canonical uri "http://localhost:1234/beta_id" found (original at path "/components/schemas/beta/properties/beta3")',
        mode => 'traverse',
      ),
    ],
    'identifier collisions within the document are found, even those between subschemas',
  );

  memory_cycle_ok($doc, 'no leaks in the document object');


  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    metaschema_uri => 'https://spec.openapis.org/oas/3.1/schema/latest',  # needed to override $schema
    evaluator => $js = JSON::Schema::Modern->new,
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  schemas:
    beta_schema:
      $id: beta
      not:
        $id: gamma
        $schema: https://json-schema.org/draft/2019-09/schema
    anchor1:
      $anchor: anchor1
    anchor2:
      $anchor: anchor2
  parameters:
    my_param1:
      name: param1
      in: query
      schema:
        $id: parameter1_id
        properties:
          foo:
            $anchor: anchor3
    my_param2:
      name: param2
      in: query
      content:
        media_type_0:
          schema:
            $id: parameter2_id
  responses:
    my_response4:
      description: bad response
      content:
        media_type_4:
          schema:
            $comment: nothing to see here
  pathItems:
    path0:
      parameters:
        - name: param0
          in: query
          schema:
            $id: pathItem0_param_id
        # TODO param2 with content/media_type_0
      get:
        parameters:
          - name: param1
            in: query
            schema:
              $id: pathItem0_get_param_id
        requestBody:
          content:
            media_type_1:
              schema:
                $id: pathItem0_get_requestBody_id
        responses:
          200:
            description: normal response
            content:
              media_type_2:
                schema:
                  $id: pathItem0_get_responses2_id
              media_type_3:
                schema:
                  $id: pathItem0_get_responses3_id
          default:
            $ref: '#/components/responses/my_response4'
        callbacks:
          my_callback:
            '{$request.query.queryUrl}':
              post: {}
paths:
  /foo/alpha: {}
  /foo/beta: {}
webhooks:
  foo: {}
  bar: {}
YAML

  cmp_result([$doc->errors], [], 'no errors during traversal');
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
        anchors => {
          anchor1 => {
            path => '/components/schemas/anchor1',
            canonical_uri => str('http://localhost:1234/api#/components/schemas/anchor1'),
          },
          anchor2 => {
            path => '/components/schemas/anchor2',
            canonical_uri => str('http://localhost:1234/api#/components/schemas/anchor2'),
          },
        },
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
        anchors => {
          anchor3 => {
            path => '/components/parameters/my_param1/schema/properties/foo',
            canonical_uri => str('http://localhost:1234/parameter1_id#/properties/foo'),
          },
        },
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

  cmp_result(
    $doc->_entities,
    {
      '/components/parameters/my_param1' => 2,
      '/components/parameters/my_param1/schema' => 0,
      '/components/parameters/my_param1/schema/properties/foo' => 0,
      '/components/parameters/my_param2' => 2,
      '/components/parameters/my_param2/content/media_type_0/schema' => 0,
      '/components/pathItems/path0' => 9,
      '/components/pathItems/path0/get/callbacks/my_callback' => 8,
      '/components/pathItems/path0/get/callbacks/my_callback/{$request.query.queryUrl}' => 9,
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
      '/components/schemas/anchor1' => 0,
      '/components/schemas/anchor2' => 0,
      '/components/schemas/beta_schema' => 0,
      '/components/schemas/beta_schema/not' => 0,
      '/paths/~1foo~1alpha' => 9,
      '/paths/~1foo~1beta' => 9,
      '/webhooks/bar' => 9,
      '/webhooks/foo' => 9,
    },
    'all entity locations are identified',
  );

  memory_cycle_ok($doc, 'no leaks in the document object');
};

subtest 'invalid servers entries' => sub {
  my $servers = $yamlpp->load_string(<<'YAML');
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
  - url: https://example.com/{foo}/{foo}
    variables: {}
  - url: http://example.com/literal
    variables:
      version:
        default: v1
        enum: [v2, v3]
  - url: http://example.com/literal2
  - url: http://example.com/
  - url: http://example.com?foo=1
  - url: http://example.com#bar
YAML

  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => {
      $yamlpp->load_string(OPENAPI_PREAMBLE)->%*,
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

  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [
      map +(
        {
          instanceLocation => '',
          keywordLocation => $_.'/servers/0/variables/version/default',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/0/variables/version/default',
          error => 'servers default is not a member of enum',
        },
        {
          instanceLocation => '',
          keywordLocation => $_.'/servers/1/url',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/1/url',
          error => 'duplicate of templated server url "https://example.com/{version}/{greeting}"',
        },
        {
          instanceLocation => '',
          keywordLocation => $_.'/servers/1',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/1',
          error => '"variables" property is required for templated server urls',
        },
        {
          instanceLocation => '',
          keywordLocation => $_.'/servers/2/variables',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/2/variables',
          error => 'missing "variables" definition for servers template variable "foo"',
        },
        {
          instanceLocation => '',
          keywordLocation => $_.'/servers/2',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/2',
          error => 'duplicate servers template variable "foo"',
        },
        {
          instanceLocation => '',
          keywordLocation => $_.'/servers/3/variables/version/default',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/3/variables/version/default',
          error => 'servers default is not a member of enum',
        },
        do {
          my $base = $_;
          map +{
            instanceLocation => '',
            keywordLocation => $base.'/servers/'.$_.'/url',
            absoluteKeywordLocation => 'http://localhost:1234/api#'.$base.'/servers/'.$_.'/url',
            error => 'server url cannot end in / or contain query or fragment components',
          }, 5,6,7
        }
      ), '', '/components/pathItems/path0', '/components/pathItems/path0/get',
    ],
    'all issues with server entries found',
  );

  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors use the instance locations');
'/servers/0/variables/version/default': servers default is not a member of enum
'/servers/1/url': duplicate of templated server url "https://example.com/{version}/{greeting}"
'/servers/1': "variables" property is required for templated server urls
'/servers/2/variables': missing "variables" definition for servers template variable "foo"
'/servers/2': duplicate servers template variable "foo"
'/servers/3/variables/version/default': servers default is not a member of enum
'/servers/5/url': server url cannot end in / or contain query or fragment components
'/servers/6/url': server url cannot end in / or contain query or fragment components
'/servers/7/url': server url cannot end in / or contain query or fragment components
'/components/pathItems/path0/servers/0/variables/version/default': servers default is not a member of enum
'/components/pathItems/path0/servers/1/url': duplicate of templated server url "https://example.com/{version}/{greeting}"
'/components/pathItems/path0/servers/1': "variables" property is required for templated server urls
'/components/pathItems/path0/servers/2/variables': missing "variables" definition for servers template variable "foo"
'/components/pathItems/path0/servers/2': duplicate servers template variable "foo"
'/components/pathItems/path0/servers/3/variables/version/default': servers default is not a member of enum
'/components/pathItems/path0/servers/5/url': server url cannot end in / or contain query or fragment components
'/components/pathItems/path0/servers/6/url': server url cannot end in / or contain query or fragment components
'/components/pathItems/path0/servers/7/url': server url cannot end in / or contain query or fragment components
'/components/pathItems/path0/get/servers/0/variables/version/default': servers default is not a member of enum
'/components/pathItems/path0/get/servers/1/url': duplicate of templated server url "https://example.com/{version}/{greeting}"
'/components/pathItems/path0/get/servers/1': "variables" property is required for templated server urls
'/components/pathItems/path0/get/servers/2/variables': missing "variables" definition for servers template variable "foo"
'/components/pathItems/path0/get/servers/2': duplicate servers template variable "foo"
'/components/pathItems/path0/get/servers/3/variables/version/default': servers default is not a member of enum
'/components/pathItems/path0/get/servers/5/url': server url cannot end in / or contain query or fragment components
'/components/pathItems/path0/get/servers/6/url': server url cannot end in / or contain query or fragment components
'/components/pathItems/path0/get/servers/7/url': server url cannot end in / or contain query or fragment components
ERRORS

  memory_cycle_ok($doc, 'no leaks in the document object');
};

subtest 'disallowed fields adjacent to $refs in path-items' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/alpha: {}
  /foo/beta: {}
YAML

  cmp_result([$doc->errors], [], 'no errors during traversal');
  memory_cycle_ok($doc, 'no leaks in the document object');

  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js,
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  callbacks:
    my_callback0:
      '{$request.query.queryUrl}':
        description: my callback
        $ref: '#/components/pathItems/path0'
    my_callback1:
      '{$request.query.queryUrl}':
        summary: blah
        parameters: []
        $ref: '#/components/pathItems/path1'
  pathItems:
    path0:
      description: my first path
      $ref: '#/components/pathItems/path1'
    path1:
      description: my second path
    path2:
      x-furble: some extra metadata
      post: {}
      $ref: '#/components/pathItems/path1'
paths:
  /foo/{foo_id}:
    description: a path
    $ref: '#/components/pathItems/path0'
  /bar/{bar_id}:
    servers: []
    $ref: '#/components/pathItems/path1'
webhooks:
  my_webhook0:
    description: my webhook
    $ref: '#/components/pathItems/path0'
  my_webhook1:
    get: {}
    $ref: '#/components/pathItems/path1'
YAML

  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors');
'/components/callbacks/my_callback1/{$request.query.queryUrl}': invalid keywords used adjacent to $ref in a path-item: parameters
'/components/pathItems/path2': invalid keywords used adjacent to $ref in a path-item: post, x-furble
'/paths/~1bar~1{bar_id}': invalid keywords used adjacent to $ref in a path-item: servers
'/webhooks/my_webhook1': invalid keywords used adjacent to $ref in a path-item: get
ERRORS

  memory_cycle_ok($doc, 'no leaks in the document object');
};

done_testing;
