#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib 'lib';
use lib 't/lib';
use Test::More;
use Path::Tiny;

use OMOP::CSV::Validator;
use TestHelper qw(run_cli_json);

my $validator = OMOP::CSV::Validator->new();
my $ddl_text = path('ddl/OMOPCDM_postgresql_5.4_ddl.sql')->slurp_utf8;
my $schemas = $validator->load_schemas_from_ddl($ddl_text);

ok( scalar(keys %{$schemas}) > 20, 'Bundled OMOP DDL yields many table schemas' );
ok( exists $schemas->{person}, 'Bundled OMOP DDL includes person schema' );
ok( exists $schemas->{drug_exposure}, 'Bundled OMOP DDL includes drug_exposure schema' );
ok( exists $schemas->{visit_occurrence}, 'Bundled OMOP DDL includes visit_occurrence schema' );
ok( exists $schemas->{condition_occurrence}, 'Bundled OMOP DDL includes condition_occurrence schema' );
ok( exists $schemas->{death}, 'Bundled OMOP DDL includes death schema' );
ok( exists $schemas->{measurement}, 'Bundled OMOP DDL includes measurement schema' );

my $schema = $validator->get_schema_from_csv_filename(
    'example/DRUG_EXPOSURE.csv',
    $schemas,
);
ok( defined $schema, 'Schema inference finds the bundled DRUG_EXPOSURE table schema' );
ok(
    defined $validator->get_schema_from_csv_filename( 'input/CONDITION_OCCURRENCE.csv', $schemas ),
    'Schema inference finds condition_occurrence from a CSV filename'
);
ok(
    defined $validator->get_schema_from_csv_filename( 'input/MEASUREMENT.csv', $schemas ),
    'Schema inference finds measurement from a CSV filename'
);

my $errors = $validator->validate_csv_file(
    'example/DRUG_EXPOSURE.csv',
    $schema,
    "\t",
);
is( scalar(@{$errors}), 0, 'Bundled DRUG_EXPOSURE example validates successfully against real DDL' );

my ( $exit_code, $payload ) = run_cli_json(
    '--ddl',   'ddl/OMOPCDM_postgresql_5.4_ddl.sql',
    '--input', 'example/DRUG_EXPOSURE.csv',
    '--sep',   "\t",
    '--json',
);
is( $exit_code, 0, 'CLI JSON mode succeeds against bundled real DDL and example file' );
is( $payload->{ok}, 1, 'CLI JSON mode reports success for bundled example' );
is( $payload->{schema_name}, 'DRUG_EXPOSURE', 'CLI JSON mode reports the inferred bundled schema name' );

done_testing();
