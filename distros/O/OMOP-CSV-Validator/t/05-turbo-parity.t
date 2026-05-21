#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib 'lib';
use lib 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use Path::Tiny;

use OMOP::CSV::Validator;
use TestHelper qw(write_fixture run_cli_json);

sub parse_data_sections {
    my ($data) = @_;
    my %sections;
    while ( $data =~ /__(\w+)__\n(.*?)\n__END_\1__/sg ) {
        $sections{$1} = $2;
    }
    return %sections;
}

sub module_validate {
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

sub assert_module_parity {
    my ( $label, %args ) = @_;
    my $default = module_validate(%args);
    my $turbo   = module_validate( %args, validation_mode => 'turbo' );
    is_deeply( $turbo, $default, $label );
}

sub assert_cli_json_parity {
    my ( $label, @args ) = @_;
    my ( $default_exit, $default_payload ) = run_cli_json(@args);
    my ( $turbo_exit,   $turbo_payload )   = run_cli_json( @args, '--turbo' );
    is( $turbo_exit, $default_exit, "$label exit code matches" );
    is_deeply( $turbo_payload, $default_payload, "$label payload matches exactly" );
}

my $data     = do { local $/; <DATA> };
my %sections = parse_data_sections($data);
my $ddl_text = $sections{DDL} or die "No DDL section found in test data\n";

assert_module_parity(
    'Module parity for valid PERSON fixture',
    ddl_text => $ddl_text,
    csv_name => 'PERSON.csv',
    csv_text => $sections{CSV_person_valid},
);

assert_module_parity(
    'Module parity for invalid PERSON fixture',
    ddl_text => $ddl_text,
    csv_name => 'PERSON.csv',
    csv_text => $sections{CSV_person_invalid},
);

assert_module_parity(
    'Module parity for PERSON varchar failure fixture',
    ddl_text => $ddl_text,
    csv_name => 'PERSON.csv',
    csv_text => $sections{CSV_person_invalid_varchar},
);

assert_module_parity(
    'Module parity for invalid OBSERVATION fixture',
    ddl_text => $ddl_text,
    csv_name => 'OBSERVATION.csv',
    csv_text => $sections{CSV_observation_invalid},
);

assert_module_parity(
    'Module parity for nullable null-marker fixture',
    ddl_text => $sections{DDL_nullable_fields},
    csv_name => 'NULL_TEST.csv',
    csv_text => $sections{CSV_nullable_fields_with_null_markers},
);

assert_module_parity(
    'Module parity for tab-separated PERSON fixture',
    ddl_text => $ddl_text,
    csv_name => 'PERSON.csv',
    csv_text => $sections{CSV_person_valid_tab},
);

my $large_csv = "person_id,gender_concept_id,year_of_birth,person_source_value\n"
  . join(
    "\n",
    map { join ',', $_, 8532, 1963, "source$_" } 1 .. 250
  )
  . "\nA,8532,1963,source251\n";

assert_module_parity(
    'Module parity for large synthetic stream fixture',
    ddl_text => $sections{DDL_large_stream_person},
    csv_name => 'PERSON.csv',
    csv_text => $large_csv,
);

my $custom_ddl = <<'DDL';
CREATE TABLE public.custom (
    person_id integer NOT NULL,
    name varchar(3) NULL,
    born_at TIMESTAMP NULL
);
DDL

assert_module_parity(
    'Module parity for extra-column failure fixture',
    ddl_text => $custom_ddl,
    csv_name => 'CUSTOM.csv',
    csv_text => "person_id,name,born_at,extra\n1,abc,1980-01-01T00:00:00Z,unexpected\n",
);

assert_module_parity(
    'Module parity for missing-property failure fixture',
    ddl_text => $custom_ddl,
    csv_name => 'CUSTOM.csv',
    csv_text => "name,born_at\nabc,1980-01-01T00:00:00Z\n",
);

assert_module_parity(
    'Module parity for bad date-time fixture',
    ddl_text => $custom_ddl,
    csv_name => 'CUSTOM.csv',
    csv_text => "person_id,name,born_at\n1,abc,1980-01-01\n",
);

my $cli_dir = tempdir( CLEANUP => 1 );
my $cli_ddl_path = write_fixture( $cli_dir, 'schema.sql', $ddl_text );
my $cli_valid_path = write_fixture( $cli_dir, 'PERSON.csv', $sections{CSV_person_valid} );
my $cli_invalid_path = write_fixture( $cli_dir, 'OBSERVATION.csv', $sections{CSV_observation_invalid} );

assert_cli_json_parity(
    'CLI JSON parity for valid PERSON fixture',
    '--ddl',   $cli_ddl_path->stringify,
    '--input', $cli_valid_path->stringify,
    '--json',
);

assert_cli_json_parity(
    'CLI JSON parity for invalid OBSERVATION fixture',
    '--ddl',   $cli_ddl_path->stringify,
    '--input', $cli_invalid_path->stringify,
    '--json',
);

assert_cli_json_parity(
    'CLI JSON parity for bundled real DDL example',
    '--ddl',   'ddl/OMOPCDM_postgresql_5.4_ddl.sql',
    '--input', 'example/DRUG_EXPOSURE.csv',
    '--sep',   "\t",
    '--json',
);

done_testing();

__DATA__
__DDL__
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

__CSV_observation_invalid__
observation_id,person_id,observation_date,observation_datetime,value_as_number,value_as_string
X,1,1963-12-31,"not a timestamp",abc,invalid observation
__END_CSV_observation_invalid__

__CSV_nullable_fields_with_null_markers__
row_id,nullable_date,nullable_timestamp,nullable_text
1,\N,\N,\N
__END_CSV_nullable_fields_with_null_markers__
