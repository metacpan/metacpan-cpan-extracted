#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib 'lib';
use Test::More tests => 6;
use Path::Tiny;
use JSON::XS;
use Text::CSV_XS;
use JSON::Validator;

# Now we just 'use OMOP::CSV::Validator;' rather than importing specific subs
use OMOP::CSV::Validator;

#---------------------------------------------------------------------
# parse_data_sections
# Reads the __DATA__ block and returns a hash keyed by section name.
# Sections are delimited by markers like:
#   __SECTIONNAME__
#   ... content ...
#   __END_SECTIONNAME__
#---------------------------------------------------------------------
sub parse_data_sections {
    my ($data) = @_;
    my %sections;
    while ( $data =~ /__(\w+)__\n(.*?)\n__END_\1__/sg ) {
        $sections{$1} = $2;
    }
    return %sections;
}

#---------------------------------------------------------------------
# validate_csv_from_text
# Helper sub for reading CSV data (as a string), coercing numeric fields,
# and validating each row using JSON::Validator. We pass in a Validator
# object ($validator) to call methods like dotify_and_coerce_number().
#
# Returns an arrayref of error info (each element is a hashref with keys:
#   row => <row number>, errors => [ list of errors ] ).
#---------------------------------------------------------------------
sub validate_csv_from_text {
    my ( $validator, $csv_text, $schema, $sep ) = @_;
    $sep //= ',';

    open my $fh, '<', \$csv_text or die "Cannot open CSV text: $!";
    my $csv = Text::CSV_XS->new(
        { binary => 1, sep_char => $sep, auto_diag => 1 }
    ) or die "Cannot use CSV: " . Text::CSV_XS->error_diag();

    my $header  = $csv->getline($fh);
    $csv->column_names(@$header);
    my $records = $csv->getline_hr_all($fh);
    close $fh;

    my @errors;
    my $json_validator = JSON::Validator->new;
    $json_validator->schema($schema);

    for my $i ( 0 .. $#$records ) {
        my $record = $records->[$i];

        # Coerce numeric fields based on the schema
        for my $col ( keys %{ $schema->{properties} } ) {
            if ( exists $record->{$col} ) {
                my $prop = $schema->{properties}->{$col};
                if ( $prop->{type} eq 'integer' or $prop->{type} eq 'number' ) {
                    my $new_val =
                      $validator->dotify_and_coerce_number( $record->{$col} );
                    if ( defined $new_val ) {
                        $record->{$col} = $new_val;
                    }
                    else {
                        # If dotify/coerce returns undef, treat as missing
                        delete $record->{$col};
                    }
                }
            }
        }

        # Validate this row against the schema
        my $errs = [ $json_validator->validate($record) ];
        # We'll call row #2 the first data row (row #1 is header)
        push @errors, { row => $i + 2, errors => $errs } if (@$errs);
    }

    return \@errors;
}

#---------------------------------------------------------------------
# Main Test Suite
#---------------------------------------------------------------------

# Read our embedded test data
my $data     = do { local $/; <DATA> };
my %sections = parse_data_sections($data);
my $ddl_text = $sections{DDL} or die "No DDL section found in test data\n";

# Create an OMOP::CSV::Validator object
my $validator = OMOP::CSV::Validator->new();

# Build the JSON schemas by parsing the DDL
my $schemas = $validator->load_schemas_from_ddl($ddl_text);

# Test for the "person" table
my $person_schema = $schemas->{person} or die "No schema for table 'person'\n";

# (1) Person valid CSV: Should produce no errors
my $person_valid_csv = $sections{'CSV_person_valid'} // '';
my $errors_person_valid =
  validate_csv_from_text( $validator, $person_valid_csv, $person_schema, ',' );
is( scalar(@$errors_person_valid), 0, 'Valid person CSV has no errors' );

# (2) Person invalid CSV: Should produce errors (non-numeric "A" in person_id)
my $person_invalid_csv = $sections{'CSV_person_invalid'} // '';
my $errors_person_invalid =
  validate_csv_from_text( $validator, $person_invalid_csv, $person_schema, ',' );
ok( scalar(@$errors_person_invalid) > 0,
    'Invalid person CSV returns errors' );

# Test for the "observation" table
my $obs_schema = $schemas->{observation}
  or die "No schema for table 'observation'\n";

# (3) Observation valid CSV: Should produce no errors
my $obs_valid_csv = $sections{'CSV_observation_valid'} // '';
my $errors_obs_valid =
  validate_csv_from_text( $validator, $obs_valid_csv, $obs_schema, ',' );
is( scalar(@$errors_obs_valid), 0, 'Valid observation CSV has no errors' );

# (4) Observation invalid CSV: Should produce errors
my $obs_invalid_csv = $sections{'CSV_observation_invalid'} // '';
my $errors_obs_invalid =
  validate_csv_from_text( $validator, $obs_invalid_csv, $obs_schema, ',' );
ok( scalar(@$errors_obs_invalid) > 0,
    'Invalid observation CSV returns errors' );

# (5) Person invalid CSV due to varchar length violation:
#     person_source_value exceeds 50 characters.
my $person_invalid_varchar_csv = $sections{'CSV_person_invalid_varchar'} // '';
my $errors_person_invalid_varchar =
  validate_csv_from_text( $validator, $person_invalid_varchar_csv, $person_schema, ',' );
ok( scalar(@$errors_person_invalid_varchar) > 0,
    'Person CSV with varchar length violation returns errors' );

# (6) Observation invalid CSV due to varchar length violation:
#     value_as_string exceeds 60 characters.
my $obs_invalid_varchar_csv = $sections{'CSV_observation_invalid_varchar'} // '';
my $errors_obs_invalid_varchar =
  validate_csv_from_text( $validator, $obs_invalid_varchar_csv, $obs_schema, ',' );
ok( scalar(@$errors_obs_invalid_varchar) > 0,
    'Observation CSV with varchar length violation returns errors' );

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
