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

my $minimal_document = {
  openapi => OAS_VERSION,
  info => {
    title => 'Test API',
    version => '1.2.3',
  },
  paths => {},
};

subtest 'missing arguments' => sub {
  die_result(
    sub { OpenAPI::Modern->new },
    qr/missing required constructor arguments: either openapi_document, or openapi_uri/,
    'need openapi_document or openapi_uri',
  );

  die_result(
    sub { OpenAPI::Modern->new(openapi_uri => 'foo') },
    qr/missing required constructor arguments: either openapi_document, or openapi_uri and openapi_schema/,
    'need openapi_document or openapi_schema',
  );

  lives_result(
    sub {
      my $openapi = OpenAPI::Modern->new(
        openapi_document => JSON::Schema::Modern::Document::OpenAPI->new(
          canonical_uri => 'openapi.yaml',
          schema => $minimal_document,
          evaluator => JSON::Schema::Modern->new(validate_formats => 0),
        )
      );
      is($openapi->openapi_uri, 'openapi.yaml', 'got uri out of object');
      cmp_deeply($openapi->openapi_schema, $minimal_document, 'got schema out of object');
      ok(!$openapi->evaluator->validate_formats, 'original evaluator is still defined');
      memory_cycle_ok($openapi);
    },
    'no exception when the document itself is provided',
  );

  lives_result(
    sub {
      my $openapi = OpenAPI::Modern->new(
        openapi_uri => 'openapi.yaml',
        openapi_schema => $minimal_document,
        evaluator => JSON::Schema::Modern->new(validate_formats => 0),
      );
      is($openapi->openapi_uri, 'openapi.yaml', 'got uri out of object');
      cmp_deeply($openapi->openapi_schema, $minimal_document, 'got schema out of object');
      ok(!$openapi->evaluator->validate_formats, 'evaluator overrides the default');
      memory_cycle_ok($openapi, 'no cycles');
    },
    'no exception when all other arguments are provided',
  );

  lives_result(
    sub {
      my $openapi = OpenAPI::Modern->new(
        openapi_uri => 'openapi.yaml',
        openapi_schema => $minimal_document,
      );
      is($openapi->openapi_uri, 'openapi.yaml', 'got uri out of object');
      cmp_deeply($openapi->openapi_schema, $minimal_document, 'got schema out of object');
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
    evaluator => my $js = JSON::Schema::Modern->new(validate_formats => 1),
    schema => {
      %$minimal_document,
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

  cmp_deeply(
    scalar $openapi->evaluator->get('http://localhost:1234/api#/components/schemas/foo'),
    true,
    'can construct an openapi object with a pre-existing document',
  );
};

done_testing;
