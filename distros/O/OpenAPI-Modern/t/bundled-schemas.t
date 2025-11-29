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
use JSON::Schema::Modern::Document::OpenAPI;
use JSON::Schema::Modern::Utilities 0.625 'load_cached_document';

my $oad_schema = {
  openapi => OAD_VERSION,
  info => { title => 'my api', version => '1.0' },
  components => {},
};

subtest 'OAS metaschemas sanity check for version '.$_ => sub {
  my $version = $_;
  skip_all('we don\'t support parsing an OAD of version ', $version) if $version eq '3.0';

  my $evaluator = JSON::Schema::Modern->new(validate_formats => 1);
  foreach my $metaschema_uri (
      DEFAULT_METASCHEMA->{$version},
      DEFAULT_BASE_METASCHEMA->{$version},
      STRICT_METASCHEMA->{$version},
    ) {
    my $result = JSON::Schema::Modern::Document::OpenAPI->validate(
      schema => { %$oad_schema, openapi => $version.'.0' },
      metaschema_uri => $metaschema_uri,
      evaluator => $evaluator,
    );
    cmp_result(
      $result->TO_JSON,
      { valid => true },
      $metaschema_uri.' can be used to validate a simple OAD',
    );
  }

  is(
    $evaluator->get_document($_)->get('/$schema'),
    JSON::Schema::Modern::METASCHEMA_URIS->{'draft2020-12'},
    $_.' uses the correct JSON Schema specification metaschema',
  )
  foreach (DEFAULT_METASCHEMA->{$version}, DEFAULT_BASE_METASCHEMA->{$version});

  is(
    $evaluator->get_document(DEFAULT_METASCHEMA->{$version})->get('/properties/jsonSchemaDialect/default'),
    DEFAULT_DIALECT->{$version},
    DEFAULT_METASCHEMA->{$version}.' uses the correct jsonSchemaDialect default',
  );

  is(
    $evaluator->get_document(DEFAULT_BASE_METASCHEMA->{$version})->get($_),
    DEFAULT_DIALECT->{$version},
    DEFAULT_BASE_METASCHEMA->{$version}.' forces the use of the correct jsonSchemaDialect in '.$_,
  ) foreach ('/$defs/dialect/const', '/$defs/schema/$ref');
}
foreach OAS_VERSIONS->@*;

subtest 'customized 3.1 strict schema and dialect when version is omitted' => sub {
  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    evaluator => my $evaluator = JSON::Schema::Modern->new,
    metaschema_uri => (STRICT_METASCHEMA->{3.1} =~ s{/3\.1/}{/}r),
    schema => {
      %$oad_schema,
      openapi => '3.1.0',
      jsonSchemaDialect => (STRICT_DIALECT->{3.1} =~ s{/3\.1/}{/}r),
    },
  );

  cmp_result([ map $_->TO_JSON, $doc->errors ], [], 'no document errors');
  is($doc->metaschema_uri, STRICT_METASCHEMA->{3.1}, '3.1-identified strict metaschema is swapped in');
};

subtest '3.0.x schema is also available' => sub {
  my $evaluator = JSON::Schema::Modern->new(validate_formats => 1);
  my $id = DEFAULT_METASCHEMA->{'3.0'};
  my $doc = load_cached_document($evaluator, $id);

  cmp_result(
    $evaluator->evaluate(
      {
        openapi => 'not an openapi version',
        info => {
          title => 'my api',
          version => '1.0',
        },
        paths => {},
      },
      $id,
    )->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/openapi',
          keywordLocation => '/properties/openapi/pattern',
          absoluteKeywordLocation => $id.'#/properties/openapi/pattern',
          error => 'pattern does not match',
        },
        {
          instanceLocation => '',
          keywordLocation => '/properties',
          absoluteKeywordLocation => $id.'#/properties',
          error => 'not all properties are valid',
        },
      ],
    },
    'OAS 3.0.x documents can be validated against the correct schema',
  );
};

done_testing;
