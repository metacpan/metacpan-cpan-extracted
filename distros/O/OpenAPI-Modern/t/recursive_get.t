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

subtest recursive_get => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new(max_depth => 15),
    schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
components:
  parameters:
    foo: { $ref: '#/components/parameters/bar', description: foo description }
    bar: { $ref: '#/components/parameters/foo', description: bar description }
    baz: { name: baz, in: query, schema: {}, description: baz description }
    blip: { $ref: 'http://far_far_away/api2#/components/schemas/beta/properties/alpha' }
  schemas:
    foo: { $ref: 'http://localhost:5678/api#/properties/foo', description: foo description }
    bar:
      $id: http://localhost:5678/api
      type: object
      properties: { foo: { type: string } }
    baz:
      $ref: 'http://far_far_away/api2#/components/schemas/alpha'
paths:
  /foo:
    post:
      parameters:
        - $ref: 'http://far_far_away/api2#/i_do_not_exist'
        - $ref: '#/components/parameters/foo'
        - $ref: '#/components/parameters/baz'
        - $ref: '#/components/parameters/blip' # -> parameter -> schema
  /bar:
    summary: /bar path summary
    $ref: 'http://far_far_away/api2#/components/pathItems/my_path'
YAML

  cmp_result([$doc->errors], [], 'no errors during traversal');

  my $openapi = OpenAPI::Modern->new(
    openapi_document => $doc,
    evaluator => $js,
  );

  my $doc2 = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://far_far_away/api2',
    evaluator => $js,
    schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
components:
  parameters:
    foo: { $ref: 'http://localhost:1234/api#/components/parameters/baz' }
  schemas:
    alpha: { type: integer }
    beta: { properties: { alpha: { type: string } } }
  pathItems:
    my_path:
      summary: my_path summary
      description: my_path description
      get: {}
YAML

  cmp_result([$doc2->errors], [], 'no errors during traversal');
  $openapi->evaluator->add_document($doc2);

  like(
    exception { $openapi->recursive_get('#/paths/~1foo/post/parameters/0') },
    qr'^unable to find resource "http://far_far_away/api2#/i_do_not_exist"',
    'failure to resolve $ref',
  );

  like(
    exception { $openapi->recursive_get('#/paths/~1foo/post/parameters/1') },
    qr{^maximum evaluation depth exceeded},
    'endless loop',
  );

  like(
    exception { $openapi->recursive_get('#/components/parameters/baz', 'example') },
    qr{^bad \$ref to http://localhost:1234/api\#/components/parameters/baz: not an "example"},
    'incorrect expected entity type',
  );

  cmp_result(
    [ $openapi->recursive_get('#/paths/~1foo/post/parameters/2') ],
    [
      { name => 'baz', in => 'query', schema => {}, description => 'baz description' },
      str('http://localhost:1234/api#/components/parameters/baz'),
    ],
    'successful get through a $ref',
  );

  like(
    exception { $openapi->recursive_get('#/paths/~1foo/post/parameters/3') },
    qr!^bad \$ref to http://far_far_away/api2#/components/schemas/beta/properties/alpha: not a "parameter"!,
    'multiple $refs, landing on the wrong type',
  );

  cmp_result(
    [ $openapi->recursive_get('#/components/schemas/foo') ],
    [ { type => 'string' }, str('http://localhost:5678/api#/properties/foo') ],
    'successful get through multiple $refs, with a change of base uri',
  );

  cmp_result(
    [ $openapi->recursive_get('#/components/schemas/baz') ],
    [ { type => 'integer' }, str('http://far_far_away/api2#/components/schemas/alpha') ],
    'successful get through multiple $refs, with a change of document',
  );

  cmp_result(
    [ $openapi->recursive_get('http://far_far_away/api2#/components/parameters/foo') ],
    [
      { name => 'baz', in => 'query', schema => {}, description => 'baz description' },
      str('http://localhost:1234/api#/components/parameters/baz'),
    ],
    'successful get through multiple $refs, with a change in document, starting with an absolute uri',
  );

  cmp_result(
    [ $openapi->recursive_get('http://localhost:1234/api#/paths/~1bar') ],
    [
      {
        summary => '/bar path summary',
        # my_path summary overridden by root path-item
        description => 'my_path description',
        get => {},
      },
      str('http://far_far_away/api2#/components/pathItems/my_path'),
    ],
    'fetching an object with overridden summary or description keeps the values from the ref object',
  );
};

done_testing;
