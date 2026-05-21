#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib 'lib';
use lib 't/lib';
use Test::More;
use File::Temp qw(tempdir);

use OMOP::CSV::Validator;
use TestHelper qw(write_fixture);

sub parse_data_sections {
    my ($data) = @_;
    my %sections;
    while ( $data =~ /__(\w+)__\n(.*?)\n__END_\1__/sg ) {
        $sections{$1} = $2;
    }
    return %sections;
}

sub validate_csv_fixture {
    my (%args) = @_;
    my $dir = tempdir( CLEANUP => 1 );

    my $ddl_path = write_fixture( $dir, 'schema.sql', $args{ddl_text} );
    my $csv_path = write_fixture( $dir, $args{csv_name}, $args{csv_text} );

    my $validator = OMOP::CSV::Validator->new();
    my $schemas   = $validator->load_schemas_from_ddl( $ddl_path->slurp_utf8 );
    my $schema    = $args{table_name}
      ? $schemas->{ lc $args{table_name} }
      : $validator->get_schema_from_csv_filename( $csv_path->stringify, $schemas );

    return $validator->validate_csv_file(
        $csv_path->stringify,
        $schema,
        $args{sep},
        {
            ( defined $args{validation_mode}
                ? ( validation_mode => $args{validation_mode} )
                : () ),
        },
    );
}

my $data     = do { local $/; <DATA> };
my %sections = parse_data_sections($data);
my $ddl_text = $sections{DDL} or die "No DDL section found in test data\n";

my $errors_person_valid = validate_csv_fixture(
    ddl_text => $ddl_text,
    csv_name => 'PERSON.csv',
    csv_text => $sections{CSV_person_valid},
);
is( scalar(@$errors_person_valid), 0, 'Valid person CSV has no errors' );

my $errors_person_valid_turbo = validate_csv_fixture(
    ddl_text         => $ddl_text,
    csv_name         => 'PERSON.csv',
    csv_text         => $sections{CSV_person_valid},
    validation_mode  => 'turbo',
);
is( scalar(@$errors_person_valid_turbo), 0, 'Turbo mode accepts a valid person CSV' );

my $errors_person_invalid = validate_csv_fixture(
    ddl_text => $ddl_text,
    csv_name => 'PERSON.csv',
    csv_text => $sections{CSV_person_invalid},
);
ok( scalar(@$errors_person_invalid) > 0, 'Invalid person CSV returns errors' );
is( $errors_person_invalid->[0]{row}, 1, 'Module reports first data row as row 1' );

my $errors_person_invalid_turbo = validate_csv_fixture(
    ddl_text         => $ddl_text,
    csv_name         => 'PERSON.csv',
    csv_text         => $sections{CSV_person_invalid},
    validation_mode  => 'turbo',
);
ok( scalar(@$errors_person_invalid_turbo) > 0, 'Turbo mode returns errors for invalid person CSV' );
is( $errors_person_invalid_turbo->[0]{row}, 1, 'Turbo mode keeps the same row numbering' );
like(
    $errors_person_invalid_turbo->[0]{errors}[0],
    qr/Expected integer/,
    'Turbo mode reports readable type errors'
);

my $errors_obs_valid = validate_csv_fixture(
    ddl_text => $ddl_text,
    csv_name => 'OBSERVATION.csv',
    csv_text => $sections{CSV_observation_valid},
);
is( scalar(@$errors_obs_valid), 0, 'Valid observation CSV has no errors' );

my $errors_obs_invalid = validate_csv_fixture(
    ddl_text => $ddl_text,
    csv_name => 'OBSERVATION.csv',
    csv_text => $sections{CSV_observation_invalid},
);
ok( scalar(@$errors_obs_invalid) > 0, 'Invalid observation CSV returns errors' );
is( $errors_obs_invalid->[0]{row}, 1, 'Observation row numbering matches module convention' );

my $errors_person_invalid_varchar = validate_csv_fixture(
    ddl_text => $ddl_text,
    csv_name => 'PERSON.csv',
    csv_text => $sections{CSV_person_invalid_varchar},
);
ok(
    scalar(@$errors_person_invalid_varchar) > 0,
    'Person CSV with varchar length violation returns errors'
);

my $errors_obs_invalid_varchar = validate_csv_fixture(
    ddl_text => $ddl_text,
    csv_name => 'OBSERVATION.csv',
    csv_text => $sections{CSV_observation_invalid_varchar},
);
ok(
    scalar(@$errors_obs_invalid_varchar) > 0,
    'Observation CSV with varchar length violation returns errors'
);

my $errors_nullable_nulls = validate_csv_fixture(
    ddl_text => $sections{DDL_nullable_fields},
    csv_name => 'NULL_TEST.csv',
    csv_text => $sections{CSV_nullable_fields_with_null_markers},
);
is(
    scalar(@$errors_nullable_nulls),
    0,
    'Nullable date, timestamp, and varchar fields accept \\N markers'
);

my $errors_nullable_nulls_turbo = validate_csv_fixture(
    ddl_text         => $sections{DDL_nullable_fields},
    csv_name         => 'NULL_TEST.csv',
    csv_text         => $sections{CSV_nullable_fields_with_null_markers},
    validation_mode  => 'turbo',
);
is(
    scalar(@$errors_nullable_nulls_turbo),
    0,
    'Turbo mode accepts \\N markers for nullable date, timestamp, and varchar fields'
);

my $errors_person_tab_autodetect = validate_csv_fixture(
    ddl_text => $ddl_text,
    csv_name => 'PERSON.csv',
    csv_text => $sections{CSV_person_valid_tab},
);
is(
    scalar(@$errors_person_tab_autodetect),
    0,
    'Module infers tab separator when --sep is omitted'
);

my $large_csv = "person_id,gender_concept_id,year_of_birth,person_source_value\n"
  . join(
    "\n",
    map { join ',', $_, 8532, 1963, "source$_" } 1 .. 250
  )
  . "\nA,8532,1963,source251\n";
my $errors_large_stream = validate_csv_fixture(
    ddl_text => $sections{DDL_large_stream_person},
    csv_name => 'PERSON.csv',
    csv_text => $large_csv,
);
is( scalar(@$errors_large_stream), 1, 'Large synthetic CSV still reports only the failing row' );
is( $errors_large_stream->[0]{row}, 251, 'Large synthetic CSV preserves row numbering deep into the file' );

my $validator = OMOP::CSV::Validator->new();
my $schema_less_schemas =
  $validator->load_schemas_from_ddl( $sections{DDL_without_schema} );
ok(
    exists $schema_less_schemas->{person},
    'Schema loading accepts CREATE TABLE definitions without schema qualifier'
);

my $placeholder_schemas =
  $validator->load_schemas_from_ddl( $sections{DDL_with_placeholder_schema} );
ok(
    exists $placeholder_schemas->{person},
    'Schema loading accepts CREATE TABLE definitions with placeholder schema qualifier'
);

my $column_order = $validator->load_column_order_from_ddl( $ddl_text, 'person' );
is_deeply(
    [ @{$column_order}[ 0 .. 3 ] ],
    [ qw(person_id gender_concept_id year_of_birth month_of_birth) ],
    'Column-order extraction preserves DDL order'
);

my $misc_schemas = $validator->load_schemas_from_ddl( $sections{DDL_misc_types_and_comments} );
ok(
    exists $misc_schemas->{misc_table}{properties}{custom_text},
    'Schema loading keeps string-like columns from mixed DDL blocks'
);
ok(
    !exists $misc_schemas->{misc_table}{properties}{primary},
    'Schema loading ignores non-column lines such as constraints'
);

my $dir = tempdir( CLEANUP => 1 );
my $headerless_path = write_fixture( $dir, 'HEADERLESS.csv', '' );
my $missing_schema_error = eval {
    $validator->validate_csv_file( $headerless_path->stringify, undef, ',' );
    1;
};
like(
    $@,
    qr/Schema is required/,
    'Validation fails cleanly when schema is missing'
);

my $headerless_schema = {
    type       => 'object',
    properties => { row_id => { type => 'integer' } },
};
my $missing_header_error = eval {
    $validator->validate_csv_file( $headerless_path->stringify, $headerless_schema, ',' );
    1;
};
like(
    $@,
    qr/Input CSV has no header row/,
    'Validation fails cleanly when the CSV has no header row'
);

my $ambiguous_path = write_fixture( $dir, 'AMBIGUOUS.csv', $sections{CSV_ambiguous_separator} );
my $person_schema = $validator->load_schemas_from_ddl($ddl_text)->{person};
my $ambiguous_error = eval {
    $validator->validate_csv_file( $ambiguous_path->stringify, $person_schema );
    1;
};
like(
    $@,
    qr/Ambiguous field separator/,
    'Validation fails cleanly when separator inference is ambiguous'
);

my $uninferable_path = write_fixture( $dir, 'UNINFERABLE.csv', $sections{CSV_uninferable_separator} );
my $uninferable_error = eval {
    $validator->detect_csv_separator( $uninferable_path->stringify );
    1;
};
like(
    $@,
    qr/Could not infer a field separator/,
    'Separator detection fails cleanly when no candidate produces a usable table shape'
);

my $missing_order_error = eval {
    $validator->load_column_order_from_ddl( $ddl_text, 'missing_table' );
    1;
};
like(
    $@,
    qr/Could not find columns for table 'missing_table'/,
    'Column-order extraction fails cleanly for unknown tables'
);

my $turbo_schema = {
    type                 => 'object',
    properties           => {
        person_id => { type => 'integer' },
        name      => { type => [ 'string', 'null' ], maxLength => 3 },
        born_at   => { type => [ 'string', 'null' ], format => 'date-time' },
    },
    required             => ['person_id'],
    additionalProperties => 0,
};

my $turbo_extra_path = write_fixture(
    $dir,
    'TURBO_EXTRA.csv',
    "person_id,name,born_at,extra\n1,abc,1980-01-01T00:00:00Z,unexpected\n",
);
my $turbo_extra_errors = $validator->validate_csv_file(
    $turbo_extra_path->stringify,
    $turbo_schema,
    ',',
    { validation_mode => 'turbo' },
);
is( scalar(@$turbo_extra_errors), 1, 'Turbo mode flags rows with unexpected extra columns' );
like(
    $turbo_extra_errors->[0]{errors}[0],
    qr/Properties not allowed: extra/,
    'Turbo mode reports additionalProperties failures'
);

my $turbo_missing_path = write_fixture(
    $dir,
    'TURBO_MISSING.csv',
    "name,born_at\nabc,1980-01-01T00:00:00Z\n",
);
my $turbo_missing_errors = $validator->validate_csv_file(
    $turbo_missing_path->stringify,
    $turbo_schema,
    ',',
    { validation_mode => 'turbo' },
);
is( scalar(@$turbo_missing_errors), 1, 'Turbo mode flags rows missing required columns' );
like(
    join( ' ', @{ $turbo_missing_errors->[0]{errors} } ),
    qr{/person_id: Missing property\.},
    'Turbo mode reports missing required properties'
);

my $turbo_bad_datetime_path = write_fixture(
    $dir,
    'TURBO_BAD_DT.csv',
    "person_id,name,born_at\n1,abc,1980-01-01\n",
);
my $turbo_bad_datetime_errors = $validator->validate_csv_file(
    $turbo_bad_datetime_path->stringify,
    $turbo_schema,
    ',',
    { validation_mode => 'turbo' },
);
is( scalar(@$turbo_bad_datetime_errors), 1, 'Turbo mode flags invalid date-time values' );
like(
    join( ' ', @{ $turbo_bad_datetime_errors->[0]{errors} } ),
    qr/Does not match date-time format/,
    'Turbo mode reports invalid date-time format clearly'
);

done_testing();

__DATA__
__DDL__
-- Postgres DDL for OMOP CDM
CREATE TABLE public.person (
    person_id integer NOT NULL,
    gender_concept_id integer NOT NULL,
    year_of_birth integer NOT NULL,
    month_of_birth integer NULL,
    day_of_birth integer NULL,
    birth_datetime TIMESTAMP NULL,
    race_concept_id integer NOT NULL,
    ethnicity_concept_id integer NOT NULL,
    location_id integer NULL,
    provider_id integer NULL,
    care_site_id integer NULL,
    person_source_value varchar(50) NULL,
    gender_source_value varchar(50) NULL,
    gender_source_concept_id integer NULL,
    race_source_value varchar(50) NULL,
    race_source_concept_id integer NULL,
    ethnicity_source_value varchar(50) NULL,
    ethnicity_source_concept_id integer NULL
);
CREATE TABLE public.observation (
    observation_id integer NOT NULL,
    person_id integer NOT NULL,
    observation_date date NOT NULL,
    observation_datetime TIMESTAMP NULL,
    value_as_number NUMERIC NULL,
    value_as_string varchar(60) NULL
);
__END_DDL__

__DDL_without_schema__
CREATE TABLE person (
    person_id integer NOT NULL,
    person_source_value varchar(50) NULL
);
__END_DDL_without_schema__

__DDL_with_placeholder_schema__
CREATE TABLE @cdmDatabaseSchema.person (
    person_id integer NOT NULL,
    person_source_value varchar(50) NULL
);
__END_DDL_with_placeholder_schema__

__DDL_nullable_fields__
CREATE TABLE public.null_test (
    row_id integer NOT NULL,
    nullable_date date NULL,
    nullable_timestamp TIMESTAMP NULL,
    nullable_text varchar(20) NULL
);
__END_DDL_nullable_fields__

__DDL_large_stream_person__
CREATE TABLE public.person (
    person_id integer NOT NULL,
    gender_concept_id integer NOT NULL,
    year_of_birth integer NOT NULL,
    person_source_value varchar(50) NULL
);
__END_DDL_large_stream_person__

__DDL_misc_types_and_comments__
CREATE TABLE public.misc_table (
    row_id integer NOT NULL,
    -- comment line that should be ignored
    custom_text text NULL,
    PRIMARY KEY (row_id)
);
__END_DDL_misc_types_and_comments__

__CSV_person_valid__
person_id,gender_concept_id,year_of_birth,month_of_birth,day_of_birth,birth_datetime,race_concept_id,ethnicity_concept_id,location_id,provider_id,care_site_id,person_source_value,gender_source_value,gender_source_concept_id,race_source_value,race_source_concept_id,ethnicity_source_value,ethnicity_source_concept_id
1,8532,1963,12,31,"1966-12-31T00:00:00Z",8516,0,\N,\N,\N,source1,F,0,black,0,west_indian,0
__END_CSV_person_valid__

__CSV_person_invalid__
person_id,gender_concept_id,year_of_birth,month_of_birth,day_of_birth,birth_datetime,race_concept_id,ethnicity_concept_id,location_id,provider_id,care_site_id,person_source_value,gender_source_value,gender_source_concept_id,race_source_value,race_source_concept_id,ethnicity_source_value,ethnicity_source_concept_id
A,8532,1963,12,31,"1966-12-31T00:00:00Z",8516,0,\N,\N,\N,source1,F,0,black,0,west_indian,0
__END_CSV_person_invalid__

__CSV_person_invalid_varchar__
person_id,gender_concept_id,year_of_birth,month_of_birth,day_of_birth,birth_datetime,race_concept_id,ethnicity_concept_id,location_id,provider_id,care_site_id,person_source_value,gender_source_value,gender_source_concept_id,race_source_value,race_source_concept_id,ethnicity_source_value,ethnicity_source_concept_id
2,8532,1963,12,31,"1966-12-31T00:00:00Z",8516,0,\N,\N,\N,"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",F,0,black,0,west_indian,0
__END_CSV_person_invalid_varchar__

__CSV_person_valid_tab__
person_id	gender_concept_id	year_of_birth	month_of_birth	day_of_birth	birth_datetime	race_concept_id	ethnicity_concept_id	location_id	provider_id	care_site_id	person_source_value	gender_source_value	gender_source_concept_id	race_source_value	race_source_concept_id	ethnicity_source_value	ethnicity_source_concept_id
1	8532	1963	12	31	"1966-12-31T00:00:00Z"	8516	0	\N	\N	\N	source1	F	0	black	0	west_indian	0
__END_CSV_person_valid_tab__

__CSV_observation_valid__
observation_id,person_id,observation_date,observation_datetime,value_as_number,value_as_string
1,1,1963-12-31,"1963-12-31T00:00:00Z",123.45,valid observation
__END_CSV_observation_valid__

__CSV_observation_invalid__
observation_id,person_id,observation_date,observation_datetime,value_as_number,value_as_string
X,1,1963-12-31,"not a timestamp",abc,invalid observation
__END_CSV_observation_invalid__

__CSV_observation_invalid_varchar__
observation_id,person_id,observation_date,observation_datetime,value_as_number,value_as_string
2,1,1963-12-31,"1963-12-31T00:00:00Z",123.45,"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
__END_CSV_observation_invalid_varchar__

__CSV_nullable_fields_with_null_markers__
row_id,nullable_date,nullable_timestamp,nullable_text
1,\N,\N,\N
__END_CSV_nullable_fields_with_null_markers__

__CSV_ambiguous_separator__
person_id,gender_concept_id;year_of_birth|person_source_value
1,8532;1963|source1
__END_CSV_ambiguous_separator__

__CSV_uninferable_separator__
single_column
value1
__END_CSV_uninferable_separator__
