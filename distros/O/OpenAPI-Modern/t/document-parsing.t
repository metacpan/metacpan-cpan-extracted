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
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::Memory::Cycle;
use lib 't/lib';
use Helper;
use JSON::Schema::Modern::Utilities 'jsonp';

my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

subtest 'basic document validation' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    schema => {
      openapi => OAD_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
        contact => { url => 'ಠ_ಠ' },
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
        keywordLocation => '/anyOf/'.$iter.'/required',
        absoluteKeywordLocation => DEFAULT_METASCHEMA->{+OAS_VERSION}.'#/anyOf/'.$iter++.'/required',
        error => 'object is missing property: '.$_,
      }, qw(paths components webhooks)),
      {
        instanceLocation => '',
        keywordLocation => '/anyOf',
        absoluteKeywordLocation => DEFAULT_METASCHEMA->{+OAS_VERSION}.'#/anyOf',
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
            error => 'not a valid uri-reference string',
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
        keywordLocation => '/properties',
        absoluteKeywordLocation => DEFAULT_METASCHEMA->{+OAS_VERSION}.'#/properties',
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
'/info/contact/url': not a valid uri-reference string
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
    schema => {
      openapi => OAD_VERSION,
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
        keywordLocation => '/properties',
        absoluteKeywordLocation => DEFAULT_METASCHEMA->{+OAS_VERSION}.'#/properties',
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

subtest '/paths correctness' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    schema => {
      openapi => OAD_VERSION,
      info => {
        title => 'my title',
        version => '1.2.3',
      },
      paths => {
        '/a/{a}' => {},
        '/a/{b}' => {},
        '/b/{a}/hi/{yes}' => {},
        '/b/{b}/hi/{yes}' => {},
        '/b/{x}/hi/{no}' => {},
        '/c/{c}/d/{c}/e/{e}/f/{e}' => {},
        '/d/{d}.d' => {},         # valid
        '/e/{e{}' => {},          # invalid
        'x-{alpha}' => {},
        'x-{beta}' => {},
        'x-{foo}-{foo}' => {},
        '/{foo}{bar}' => {},      # valid, but inadvised
        '/{foo}-{bar}' => {},     # valid
        '/{foo}%20{bar}' => {},   # valid
        '/f/?/g' => {},           # invalid
        '/h/#/i' => {},           # invalid
        '/j/{foo?bar}' => {},     # valid, but weird
        '/k/{foo#bar}' => {},     # valid, but weird
      },
    },
  );

  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        keywordLocation => '/paths/~1a~1{b}',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/paths/~1a~1{b}')),
        error => 'duplicate of templated path "/a/{a}"',
      },
      {
        keywordLocation => '/paths/~1b~1{b}~1hi~1{yes}',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/paths/~1b~1{b}~1hi~1{yes}')),
        error => 'duplicate of templated path "/b/{a}/hi/{yes}"',
      },
      {
        keywordLocation => '/paths/~1b~1{x}~1hi~1{no}',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/paths/~1b~1{x}~1hi~1{no}')),
        error => 'duplicate of templated path "/b/{a}/hi/{yes}"',
      },
      {
        keywordLocation => '/paths/~1c~1{c}~1d~1{c}~1e~1{e}~1f~1{e}',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/paths/~1c~1{c}~1d~1{c}~1e~1{e}~1f~1{e}')),
        error => 'duplicate path template variable "c"',
      },
      {
        keywordLocation => '/paths/~1c~1{c}~1d~1{c}~1e~1{e}~1f~1{e}',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/paths/~1c~1{c}~1d~1{c}~1e~1{e}~1f~1{e}')),
        error => 'duplicate path template variable "e"',
      },
      (map +{
        keywordLocation => jsonp('/paths', $_),
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#'.jsonp('/paths', $_))),
        error => 'invalid path template "'.$_.'"',
      }, '/e/{e{}', '/f/?/g', '/h/#/i'),
    ],
    'duplicate paths or template variables are not permitted',
  );

  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors');
'/paths/~1a~1{b}': duplicate of templated path "/a/{a}"
'/paths/~1b~1{b}~1hi~1{yes}': duplicate of templated path "/b/{a}/hi/{yes}"
'/paths/~1b~1{x}~1hi~1{no}': duplicate of templated path "/b/{a}/hi/{yes}"
'/paths/~1c~1{c}~1d~1{c}~1e~1{e}~1f~1{e}': duplicate path template variable "c"
'/paths/~1c~1{c}~1d~1{c}~1e~1{e}~1f~1{e}': duplicate path template variable "e"
'/paths/~1e~1{e{}': invalid path template "/e/{e{}"
'/paths/~1f~1?~1g': invalid path template "/f/?/g"
'/paths/~1h~1#~1i': invalid path template "/h/#/i"
ERRORS
};

subtest 'extract operationIds and identify duplicates' => sub {
  my $yaml = OPENAPI_PREAMBLE.<<'YAML';
components:
  callbacks:
    callback_a:
      $url_a:
        patch:
          operationId: operation_id_a
          callbacks:
            callback_z:
              $url_z:
                delete:
                  operationId: operation_id_z
  pathItems:
    path_item_c:
      get:
        operationId: operation_id_c
        callbacks:
          callback_d:
            $url_d:
              patch:
                operationId: operation_id_d
paths:
  /foo/{foo_id}:
    post:
      operationId: operation_id_e
      callbacks:
        callback_f:
          $url_f:
            patch:
              operationId: operation_id_f
webhooks:
  webhook_b:
    put:
      operationId: operation_id_b
YAML

  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    schema => $yamlpp->load_string($yaml),
  );

  cmp_result([ $doc->errors ], [], 'no errors when parsing this document');
  cmp_result(
    $doc->_operationIds,
    {
      operation_id_a => '/components/callbacks/callback_a/$url_a/patch',
      operation_id_b => '/webhooks/webhook_b/put',
      operation_id_c => '/components/pathItems/path_item_c/get',
      operation_id_d => '/components/pathItems/path_item_c/get/callbacks/callback_d/$url_d/patch',
      operation_id_e => '/paths/~1foo~1{foo_id}/post',
      operation_id_f => '/paths/~1foo~1{foo_id}/post/callbacks/callback_f/$url_f/patch',
      operation_id_z => '/components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete',
    },
    'extracted the correct location of all operationIds',
  );


  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    schema => $yamlpp->load_string($yaml =~ s/operation_id_[a-z]/operation_id_dupe/gr),
  );

  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [ map +{
        keywordLocation => $_.'/operationId',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#'.$_.'/operationId')),
        error => 'duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete',
      },
      (
        # sorted alphabetically, longer paths before shorter ones
        #'/components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete',
        '/components/callbacks/callback_a/$url_a/patch',
        '/components/pathItems/path_item_c/get/callbacks/callback_d/$url_d/patch',
        '/components/pathItems/path_item_c/get',
        '/paths/~1foo~1{foo_id}/post/callbacks/callback_f/$url_f/patch',
        '/paths/~1foo~1{foo_id}/post',
        '/webhooks/webhook_b/put',
      )
    ],
    'duplicate operationIds all identified',
  );

  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors');
'/components/callbacks/callback_a/$url_a/patch/operationId': duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete
'/components/pathItems/path_item_c/get/callbacks/callback_d/$url_d/patch/operationId': duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete
'/components/pathItems/path_item_c/get/operationId': duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete
'/paths/~1foo~1{foo_id}/post/callbacks/callback_f/$url_f/patch/operationId': duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete
'/paths/~1foo~1{foo_id}/post/operationId': duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete
'/webhooks/webhook_b/put/operationId': duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete
ERRORS
};

subtest 'bad subschemas' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
  schemas:
    alpha_schema:
      $id: alpha
      not:
        minimum: not a number
YAML

  cmp_result(
    [ $doc->errors ],
    [
      methods(
        keyword_location => '/components/schemas/alpha_schema/not/minimum',
        absolute_keyword_location => str('http://localhost:1234/alpha#/not/minimum'),
        error => 'minimum value is not a number',
        mode => 'traverse',
      ),
    ],
    'subschemas identified during traverse pass, and error found',
  );

  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors use the instance locations');
'/components/schemas/alpha_schema/not/minimum': minimum value is not a number
ERRORS

  memory_cycle_ok($doc, 'no leaks in the document object');
};

subtest 'find identifiers, subschemas and other entities' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
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
        keyword_location => '/components/schemas/alpha/properties/alpha2/$id',
        error => 'duplicate canonical uri "http://localhost:1234/alpha_id" found (original at path "/components/schemas/alpha/properties/alpha1")',
        mode => 'traverse',
      ),
      methods(
        keyword_location => '/components/schemas/alpha/properties/alpha4/$anchor',
        error => 'duplicate anchor uri "http://localhost:1234/api#alpha_anchor" found (original at path "/components/schemas/alpha/properties/alpha3")',
        mode => 'traverse',
      ),
      methods(
        keyword_location => '/components/schemas/beta/properties/beta1',
        error => 'duplicate canonical uri "http://localhost:1234/alpha_id" found (original at path "/components/schemas/alpha/properties/alpha1")',
        mode => 'traverse',
      ),
      methods(
        keyword_location => '/components/schemas/beta/properties/beta2',
        error => 'duplicate anchor uri "http://localhost:1234/api#alpha_anchor" found (original at path "/components/schemas/alpha/properties/alpha3")',
        mode => 'traverse',
      ),
      methods(
        keyword_location => '/components/schemas/gamma/properties/gamma2',
        error => 'duplicate anchor uri "http://localhost:1234/api#alpha_anchor" found (original at path "/components/schemas/alpha/properties/alpha3")',
        mode => 'traverse',
      ),
      methods(
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
    metaschema_uri => DEFAULT_METASCHEMA->{+OAS_VERSION},  # needed to override $schema
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
        additionalProperties: false
    my_param2:
      name: param2
      in: query
      content:
        media_type_0:
          schema:
            $id: parameter2_id
    my_param3:
      name: param3
      in: query
      schema: false
  responses:
    my_response4:
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

  cmp_result([ $doc->errors ], [], 'no errors when parsing this document');
  cmp_result(
    my $index = { $doc->resource_index },
    {
      'http://localhost:1234/api' => {
        path => '',
        canonical_uri => str('http://localhost:1234/api'),
        specification_version => 'draft2020-12',
        vocabularies => bag(OAS_VOCABULARIES->@*),
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
        vocabularies => bag(OAS_VOCABULARIES->@*),
      },
      'http://localhost:1234/gamma' => {
        path => '/components/schemas/beta_schema/not',
        canonical_uri => str('http://localhost:1234/gamma'),
        specification_version => 'draft2019-09',
        vocabularies => bag(map 'JSON::Schema::Modern::Vocabulary::'.$_,
          qw(Core Applicator Validation FormatAnnotation Content MetaData)), # overridden "$schema" keyword
      },
      'http://localhost:1234/parameter1_id' => {
        path => '/components/parameters/my_param1/schema',
        canonical_uri => str('http://localhost:1234/parameter1_id'),
        specification_version => 'draft2020-12',
        vocabularies => bag(OAS_VOCABULARIES->@*),
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
        vocabularies => bag(OAS_VOCABULARIES->@*),
      },
      'http://localhost:1234/pathItem0_param_id' => {
        path => '/components/pathItems/path0/parameters/0/schema',
        canonical_uri => str('http://localhost:1234/pathItem0_param_id'),
        specification_version => 'draft2020-12',
        vocabularies => bag(OAS_VOCABULARIES->@*),
      },
      'http://localhost:1234/pathItem0_get_param_id' => {
        path => '/components/pathItems/path0/get/parameters/0/schema',
        canonical_uri => str('http://localhost:1234/pathItem0_get_param_id'),
        specification_version => 'draft2020-12',
        vocabularies => bag(OAS_VOCABULARIES->@*),
      },
      'http://localhost:1234/pathItem0_get_requestBody_id' => {
        path => '/components/pathItems/path0/get/requestBody/content/media_type_1/schema',
        canonical_uri => str('http://localhost:1234/pathItem0_get_requestBody_id'),
        specification_version => 'draft2020-12',
        vocabularies => bag(OAS_VOCABULARIES->@*),
      },
      map +('http://localhost:1234/pathItem0_get_responses'.$_.'_id' => {
        path => '/components/pathItems/path0/get/responses/200/content/media_type_'.$_.'/schema',
        canonical_uri => str('http://localhost:1234/pathItem0_get_responses'.$_.'_id'),
        specification_version => 'draft2020-12',
        vocabularies => bag(OAS_VOCABULARIES->@*),
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
      '/components/parameters/my_param1/schema/additionalProperties' => 0,
      '/components/parameters/my_param2' => 2,
      '/components/parameters/my_param2/content/media_type_0' => 10,
      '/components/parameters/my_param2/content/media_type_0/schema' => 0,
      '/components/parameters/my_param3' => 2,
      '/components/parameters/my_param3/schema' => 0,
      '/components/pathItems/path0' => 9,
      '/components/pathItems/path0/get/callbacks/my_callback' => 8,
      '/components/pathItems/path0/get/callbacks/my_callback/{$request.query.queryUrl}' => 9,
      '/components/pathItems/path0/get/parameters/0' => 2,
      '/components/pathItems/path0/get/parameters/0/schema' => 0,
      '/components/pathItems/path0/get/requestBody' => 4,
      '/components/pathItems/path0/get/requestBody/content/media_type_1' => 10,
      '/components/pathItems/path0/get/requestBody/content/media_type_1/schema' => 0,
      '/components/pathItems/path0/get/responses/200' => 1,
      '/components/pathItems/path0/get/responses/200/content/media_type_2' => 10,
      '/components/pathItems/path0/get/responses/200/content/media_type_2/schema' => 0,
      '/components/pathItems/path0/get/responses/200/content/media_type_3' => 10,
      '/components/pathItems/path0/get/responses/200/content/media_type_3/schema' => 0,
      '/components/pathItems/path0/get/responses/default' => 1,
      '/components/pathItems/path0/parameters/0' => 2,
      '/components/pathItems/path0/parameters/0/schema' => 0,
      '/components/responses/my_response4' => 1,
      '/components/responses/my_response4/content/media_type_4' => 10,
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
        default: v1                       # invalid default
        enum: [v2, v3]
      greeting:
        default: hi
      unused:                             # valid, but inadvised
        default: nope
  - url: https://example.com/{v}/{g}      # invalid: missing 'variables'
  - url: https://example.com/{foo}/{foo}  # invalid: duplicate variable
    variables: {}
  - url: http://example.com/literal
    variables:
      unused:
        default: v1                       # invalid default, even if unused
        enum: [v2, v3]
  - url: http://example.com/literal2      # valid
  - url: http://example.com/              # valid, but inadvised
  - url: http://example.com?foo=1         # invalid
  - url: http://example.com#bar           # invalid
  - url: http://{host}.com/{path1}{path2} # valid, but inadvised
    variables:
      host:
        default: a
      path1:
        default: b
      path2:
        default: c
  - url: http://{host}.com/{pa{th}        # invalid
  - url: http://example.com/^illegal      # invalid
  - url: http://example.com/d/{d}.d       # valid
    variables:
      d:
        default: d
  - url: http://example.com/{foo}%20{bar} # valid
    variables:
      foo:
        default: foo
      bar:
        default: bar
  - url: http://example.com/x/{foo?bar}   # valid, but weird
    variables:
      foo?bar:
        default: foo
  - url: http://example.com/y/{foo#bar}   # valid, but weird
    variables:
      foo#bar:
        default: foo
YAML

  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
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
          keywordLocation => $_.'/servers/0/variables/version/default',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/0/variables/version/default',
          error => 'servers default is not a member of enum',
        },
        {
          keywordLocation => $_.'/servers/1/url',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/1/url',
          error => 'duplicate of templated server url "https://example.com/{version}/{greeting}"',
        },
        {
          keywordLocation => $_.'/servers/1',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/1',
          error => '"variables" property is required for templated server urls',
        },
        {
          keywordLocation => $_.'/servers/2/url',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/2/url',
          error => 'duplicate of templated server url "https://example.com/{v}/{g}"',
        },
        {
          keywordLocation => $_.'/servers/2/variables',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/2/variables',
          error => 'missing "variables" definition for servers template variable "foo"',
        },
        {
          keywordLocation => $_.'/servers/2',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/2',
          error => 'duplicate servers template variable "foo"',
        },
        {
          keywordLocation => $_.'/servers/3/variables/unused/default',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/3/variables/unused/default',
          error => 'servers default is not a member of enum',
        },
        do {
          my $base = $_;
          map +{
            keywordLocation => $base.'/servers/'.$_.'/url',
            absoluteKeywordLocation => 'http://localhost:1234/api#'.$base.'/servers/'.$_.'/url',
            error => 'invalid server url "'.$doc->schema->{servers}[$_]{url}.'"',
          }, 6,7
        },
        {
          keywordLocation => $_.'/servers/9/url',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/9/url',
          error => 'invalid server url "http://{host}.com/{pa{th}"',
        },
        {
          keywordLocation => $_.'/servers/10/url',
          absoluteKeywordLocation => 'http://localhost:1234/api#'.$_.'/servers/10/url',
          error => 'invalid server url "http://example.com/^illegal"',
        },
      ), '', '/components/pathItems/path0', '/components/pathItems/path0/get',
    ],
    'all issues with server entries found',
  );

  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors use the instance locations');
'/servers/0/variables/version/default': servers default is not a member of enum
'/servers/1/url': duplicate of templated server url "https://example.com/{version}/{greeting}"
'/servers/1': "variables" property is required for templated server urls
'/servers/2/url': duplicate of templated server url "https://example.com/{v}/{g}"
'/servers/2/variables': missing "variables" definition for servers template variable "foo"
'/servers/2': duplicate servers template variable "foo"
'/servers/3/variables/unused/default': servers default is not a member of enum
'/servers/6/url': invalid server url "http://example.com?foo=1"
'/servers/7/url': invalid server url "http://example.com#bar"
'/servers/9/url': invalid server url "http://{host}.com/{pa{th}"
'/servers/10/url': invalid server url "http://example.com/^illegal"
'/components/pathItems/path0/servers/0/variables/version/default': servers default is not a member of enum
'/components/pathItems/path0/servers/1/url': duplicate of templated server url "https://example.com/{version}/{greeting}"
'/components/pathItems/path0/servers/1': "variables" property is required for templated server urls
'/components/pathItems/path0/servers/2/url': duplicate of templated server url "https://example.com/{v}/{g}"
'/components/pathItems/path0/servers/2/variables': missing "variables" definition for servers template variable "foo"
'/components/pathItems/path0/servers/2': duplicate servers template variable "foo"
'/components/pathItems/path0/servers/3/variables/unused/default': servers default is not a member of enum
'/components/pathItems/path0/servers/6/url': invalid server url "http://example.com?foo=1"
'/components/pathItems/path0/servers/7/url': invalid server url "http://example.com#bar"
'/components/pathItems/path0/servers/9/url': invalid server url "http://{host}.com/{pa{th}"
'/components/pathItems/path0/servers/10/url': invalid server url "http://example.com/^illegal"
'/components/pathItems/path0/get/servers/0/variables/version/default': servers default is not a member of enum
'/components/pathItems/path0/get/servers/1/url': duplicate of templated server url "https://example.com/{version}/{greeting}"
'/components/pathItems/path0/get/servers/1': "variables" property is required for templated server urls
'/components/pathItems/path0/get/servers/2/url': duplicate of templated server url "https://example.com/{v}/{g}"
'/components/pathItems/path0/get/servers/2/variables': missing "variables" definition for servers template variable "foo"
'/components/pathItems/path0/get/servers/2': duplicate servers template variable "foo"
'/components/pathItems/path0/get/servers/3/variables/unused/default': servers default is not a member of enum
'/components/pathItems/path0/get/servers/6/url': invalid server url "http://example.com?foo=1"
'/components/pathItems/path0/get/servers/7/url': invalid server url "http://example.com#bar"
'/components/pathItems/path0/get/servers/9/url': invalid server url "http://{host}.com/{pa{th}"
'/components/pathItems/path0/get/servers/10/url': invalid server url "http://example.com/^illegal"
ERRORS

  memory_cycle_ok($doc, 'no leaks in the document object');
};

subtest 'disallowed fields adjacent to $refs in path-items' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/alpha: {}
  /foo/beta: {}
YAML

  cmp_result([ $doc->errors ], [], 'no errors when parsing this document');
  memory_cycle_ok($doc, 'no leaks in the document object');

  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
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

subtest 'query and querystring' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo:
    get:
      parameters:
      - name: q
        in: query
        schema: {}
      - name: qs
        in: querystring
        content:
          application/x-www-form-urlencoded:
            schema: {}
YAML

  cmp_result(
    ($doc->errors)[0]->TO_JSON,
    {
      instanceLocation => jsonp(qw(/paths /foo get parameters)),
      keywordLocation => '',
      error => 'cannot use query and querystring together',
    },
    'using query and querystring together gives a user-friendly error',
  );

  is(
    (split(/\R/, document_result($doc)))[0],
    '\'/paths/~1foo/get/parameters\': cannot use query and querystring together',
    'stringified error',
  ),
};

subtest 'extract tags and identify duplicates' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components: {}
tags:
  - name: foo
  - name: bar
    parent: blech
  - name: baz
    parent: foo
  - name: foo
  - name: bar
  - name: alpha
    parent: beta
  - name: beta
    parent: alpha
  - name: foo
    parent: foo
YAML

  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        keywordLocation => '/tags/1/parent',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/tags/1/parent')),
        error => 'parent of tag "bar" does not exist: "blech"',
      },
      {
        keywordLocation => '/tags/3/name',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/tags/3/name')),
        error => 'duplicate of tag at /tags/0: "foo"',
      },
      {
        keywordLocation => '/tags/4/name',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/tags/4/name')),
        error => 'duplicate of tag at /tags/1: "bar"',
      },
      {
        keywordLocation => '/tags/5/parent',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/tags/5/parent')),
        error => 'circular reference between tags: "alpha" -> "beta" -> "alpha"',
      },
      {
        keywordLocation => '/tags/6/parent',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/tags/6/parent')),
        error => 'circular reference between tags: "beta" -> "alpha" -> "beta"',
      },
      {
        keywordLocation => '/tags/7/name',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/tags/7/name')),
        error => 'duplicate of tag at /tags/0: "foo"',
      },
      {
        keywordLocation => '/tags/7/parent',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#/tags/7/parent')),
        error => 'circular reference between tags: "foo" -> "foo"',
      },
    ],
    'all tag errors identified: duplicates, missing parents, circular heirarchy',
  );


  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
tags:
  - name: foo
  - name: bar
    parent: foo
  - name: baz
    parent: bar
  - name: blech
    parent: bar
paths:
  /foo:
    get:
      tags: [foo, blech]
    post:
      tags: [bar, zip, baz]
  /bar:
    get:
      tags: [whee, baz]
YAML

  cmp_result([ $doc->errors ], [], 'no errors when parsing this document');

  cmp_result(
    $doc->{_tags},
    {
      foo => '/tags/0',
      bar => '/tags/1',
      baz => '/tags/2',
      blech => '/tags/3',
    },
    'all tag object paths',
  );

  is($doc->tag_path('foo'), '/tags/0', 'tag_path for foo');
  is($doc->tag_path('bar'), '/tags/1', 'tag_path for bar');
  is($doc->tag_path('baz'), '/tags/2', 'tag_path for baz');
  is($doc->tag_path('blech'), '/tags/3', 'tag_path for blech');
  is($doc->tag_path('zip'), undef, 'tag_path for zip');

  cmp_result(
    $doc->{_operation_tags},
    {
      foo => ['/paths/~1foo/get'],
      bar => ['/paths/~1foo/post'],
      baz => ['/paths/~1bar/get', '/paths/~1foo/post'],
      blech => ['/paths/~1foo/get'],
      zip => ['/paths/~1foo/post'],
      whee => ['/paths/~1bar/get'],
    },
    'all tag operation locations, even those not defined by a tag object',
  );

  cmp_result([$doc->operations_with_tag('foo')], ['/paths/~1foo/get'], 'operations_with_tag("foo")');
  cmp_result([$doc->operations_with_tag('bar')], ['/paths/~1foo/post'], 'operations_with_tag("bar")');
  cmp_result([$doc->operations_with_tag('baz')], ['/paths/~1bar/get', '/paths/~1foo/post'], 'operations_with_tag("baz")');
  cmp_result([$doc->operations_with_tag('blech')], ['/paths/~1foo/get'], 'operations_with_tag("blech")');
  cmp_result([$doc->operations_with_tag('zip')], ['/paths/~1foo/post'], 'operations_with_tag("zip")');
  cmp_result([$doc->operations_with_tag('yup')], [], 'operations_with_tag("yup")');
};

subtest '3.0 checks' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    schema => {
      openapi => '3.0.4',
      info => {
        title => 'my title',
        version => '1.2.3',
        contact => { url => 'ಠ_ಠ' },
      },
      map +($_ => 'not an array'), qw(servers security tags),
    },
  );
  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [
      {
        instanceLocation => '',
        keywordLocation => '/required',
        absoluteKeywordLocation => DEFAULT_METASCHEMA->{'3.0'}.'#/required',
        error => 'object is missing property: paths',
      },
      (map +{
        instanceLocation => '/'.$_,
        keywordLocation => '/properties/'.$_.'/type',
        absoluteKeywordLocation => DEFAULT_METASCHEMA->{'3.0'}.'#/properties/'.$_.'/type',
        error => re(qr/^got string, not (object|array)$/),
      }, qw(security servers tags)),
      {
        instanceLocation => '',
        keywordLocation => "/properties",
        absoluteKeywordLocation => DEFAULT_METASCHEMA->{'3.0'}.'#/properties',
        error => 'not all properties are valid',
      },
    ],
    'missing paths (etc), and bad types for top level fields',
  );
};

done_testing;
