# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';

use Test::More 0.88;
use Test::Fatal;
use Test::Deep;
use Test::Memory::Cycle;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use JSON::Schema::Modern::Document::OpenAPI;
use Test::File::ShareDir -share => { -dist => { 'OpenAPI-Modern' => 'share' } };
use constant { true => JSON::PP::true, false => JSON::PP::false };
use Feature::Compat::Try;
use OpenAPI::Modern;

my $minimal_document = {
  openapi => '3.1.0',
  info => {
    title => 'Test API',
    version => '1.2.3',
  },
  paths => {},
};

subtest 'missing arguments' => sub {
  like(
    exception { OpenAPI::Modern->new },
    qr/missing required constructor arguments: either openapi_document, or openapi_uri/,
    'need openapi_document or openapi_uri',
  );

  like(
    exception { OpenAPI::Modern->new(openapi_uri => 'foo') },
    qr/missing required constructor arguments: either openapi_document, or openapi_schema/,
    'need openapi_document or openapi_schema',
  );

  is(
    exception {
      my $openapi = OpenAPI::Modern->new(
        openapi_document => JSON::Schema::Modern::Document::OpenAPI->new(
          canonical_uri => 'openapi.yaml',
          schema => $minimal_document,
          evaluator => JSON::Schema::Modern->new,
        )
      );
      is($openapi->openapi_uri, 'openapi.yaml', 'got uri out of object');
      cmp_deeply($openapi->openapi_schema, $minimal_document, 'got schema out of object');
      ok(!$openapi->evaluator->validate_formats, 'original evaluator is still defined');
      memory_cycle_ok($openapi);
    },
    undef,
    'no exception when the document itself is provided',
  );

  is(
    exception {
      my $openapi = OpenAPI::Modern->new(
        openapi_uri => 'openapi.yaml',
        openapi_schema => $minimal_document,
        evaluator => JSON::Schema::Modern->new,
      );
      is($openapi->openapi_uri, 'openapi.yaml', 'got uri out of object');
      cmp_deeply($openapi->openapi_schema, $minimal_document, 'got schema out of object');
      ok(!$openapi->evaluator->validate_formats, 'evaluator overrides the default');
      memory_cycle_ok($openapi, 'no cycles');
    },
    undef,
    'no exception when all other arguments are provided',
  );

  is(
    exception {
      my $openapi = OpenAPI::Modern->new(
        openapi_uri => 'openapi.yaml',
        openapi_schema => $minimal_document,
      );
      is($openapi->openapi_uri, 'openapi.yaml', 'got uri out of object');
      cmp_deeply($openapi->openapi_schema, $minimal_document, 'got schema out of object');
      ok($openapi->evaluator->validate_formats, 'default evaluator is used');
      memory_cycle_ok($openapi, 'no cycles');
    },
    undef,
    'no exception when evaluator is not provided',
  );
};

subtest 'document errors' => sub {
  my $result;
  try {
    OpenAPI::Modern->new(
      openapi_uri => '/api',
      openapi_schema => [ 'this is not a valid openapi document' ],
    )
  }
  catch ($e) {
    $result = $e;
  }

  cmp_deeply(
    $result->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/type',
          absoluteKeywordLocation => 'https://spec.openapis.org/oas/3.1/schema/2022-10-07#/type',
          error => 'got array, not object',
        },
      ],
    },
    'bad document causes validation to immediately fail',
  );

  is(
    "$result",
    q!'': got array, not object!,
    'exception during construction serializes the error correctly',
  );
};

done_testing;
