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
use JSON::Schema::Modern::Document::OpenAPI;

use lib 't/lib';
use Helper;

use constant STRICT_METASCHEMA => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/strict-schema.json';

my $oad_schema = {
  openapi => OAS_VERSION,
  info => { title => 'my api', version => '1.0' },
  components => {},
};

subtest 'OAS metaschemas sanity check' => sub {
  my $evaluator = JSON::Schema::Modern->new(validate_formats => 1);
  foreach my $metaschema_uri (
      DEFAULT_METASCHEMA,
      DEFAULT_BASE_METASCHEMA,
      STRICT_METASCHEMA,
    ) {
    my $result = JSON::Schema::Modern::Document::OpenAPI->validate(
      schema => $oad_schema,
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
  foreach (DEFAULT_METASCHEMA, DEFAULT_BASE_METASCHEMA);

  is(
    $evaluator->get_document(DEFAULT_METASCHEMA)->get('/properties/jsonSchemaDialect/default'),
    DEFAULT_DIALECT,
    DEFAULT_METASCHEMA.' uses the correct jsonSchemaDialect default',
  );

  is(
    $evaluator->get_document(DEFAULT_BASE_METASCHEMA)->get($_),
    DEFAULT_DIALECT,
    DEFAULT_BASE_METASCHEMA.' forces the use of the correct jsonSchemaDialect in '.$_,
  ) foreach ('/$defs/dialect/const', '/$defs/schema/$ref');
};

done_testing;
