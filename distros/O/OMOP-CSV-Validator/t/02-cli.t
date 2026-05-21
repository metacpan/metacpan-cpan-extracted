#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib 'lib';
use lib 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use JSON::XS;
use Path::Tiny;
use Text::CSV_XS;
use OMOP::CSV::Validator;

use TestHelper qw(write_fixture run_cli_capture run_cli_json slurp_zip_member);

my $ddl_text = <<'DDL';
CREATE TABLE public.person (
    person_id integer NOT NULL,
    gender_concept_id integer NOT NULL,
    year_of_birth integer NOT NULL,
    person_source_value varchar(50) NULL
);
DDL

my $valid_csv = <<'CSV';
person_id,gender_concept_id,year_of_birth,person_source_value
1,8532,1963,source1
CSV

my $valid_tsv = <<'TSV';
person_id	gender_concept_id	year_of_birth	person_source_value
1	8532	1963	source1
TSV

my $invalid_csv = <<'CSV';
person_id,gender_concept_id,year_of_birth,person_source_value
A,8532,1963,source1
CSV

my $mixed_csv = <<'CSV';
person_id,gender_concept_id,year_of_birth,person_source_value
1,8532,1963,source1
A,8532,1963,source2
CSV

my $valid_dir = tempdir( CLEANUP => 1 );
my $invalid_dir = tempdir( CLEANUP => 1 );
my $mismatch_dir = tempdir( CLEANUP => 1 );

my $ddl_path = write_fixture( $valid_dir, 'schema.sql', $ddl_text );
my $valid_path = write_fixture( $valid_dir, 'PERSON.csv', $valid_csv );
my $invalid_ddl_path = write_fixture( $invalid_dir, 'schema.sql', $ddl_text );
my $invalid_path = write_fixture( $invalid_dir, 'PERSON.csv', $invalid_csv );
my $mismatch_ddl_path = write_fixture( $mismatch_dir, 'schema.sql', $ddl_text );
my $mismatch_path = write_fixture( $mismatch_dir, 'MISMATCH.csv', $valid_csv );
my $schemas_out = path( $valid_dir, 'schemas.json' );
my $report_path = path( $valid_dir, 'validation-report.tsv' );
my $xlsx_report_path = path( $valid_dir, 'validation-report.xlsx' );
my $mixed_path = write_fixture( $valid_dir, 'PERSON_MIXED.csv', $mixed_csv );
my $valid_tsv_path = write_fixture( $valid_dir, 'PERSON_TSV.csv', $valid_tsv );
my $ambiguous_path = write_fixture(
    $valid_dir,
    'PERSON_AMBIGUOUS.csv',
    "person_id,gender_concept_id;year_of_birth|person_source_value\n1,8532;1963|source1\n"
);

my ( $json_valid_exit, $json_valid_payload ) = run_cli_json(
    '--ddl',   $ddl_path->stringify,
    '--input', $valid_path->stringify,
    '--json',
);
is( $json_valid_exit, 0, 'JSON mode exits 0 on valid CSV' );
is( $json_valid_payload->{ok}, 1, 'JSON mode reports success' );
is( $json_valid_payload->{error_count}, 0, 'JSON mode reports zero row errors' );
is( $json_valid_payload->{schema_name}, 'PERSON', 'JSON mode includes inferred schema name' );

my ( $json_valid_turbo_exit, $json_valid_turbo_payload ) = run_cli_json(
    '--ddl',   $ddl_path->stringify,
    '--input', $valid_path->stringify,
    '--json',
    '--turbo',
);
is( $json_valid_turbo_exit, 0, 'Turbo JSON mode exits 0 on valid CSV' );
is( $json_valid_turbo_payload->{ok}, 1, 'Turbo JSON mode reports success' );
is( $json_valid_turbo_payload->{error_count}, 0, 'Turbo JSON mode reports zero row errors' );

my ( $human_success_exit, $human_success_stdout, $human_success_stderr ) = run_cli_capture(
    '--ddl',      $ddl_path->stringify,
    '--input',    $valid_path->stringify,
    '--no-color',
);
is( $human_success_exit, 0, 'Human mode exits 0 on valid CSV' );
like( $human_success_stdout, qr/is valid against the 'PERSON' schema/, 'Human mode prints a readable success message' );

my ( $help_exit, $help_stdout, $help_stderr ) = run_cli_capture('--help');
is( $help_exit, 1, '--help exits through pod2usage' );
like( $help_stdout, qr/Usage:/, '--help prints usage text' );

my ( $version_exit, $version_stdout, $version_stderr ) = run_cli_capture('--version');
is( $version_exit, 0, '--version exits 0' );
like(
    $version_stdout,
    qr/Version \Q$OMOP::CSV::Validator::VERSION\E/,
    '--version prints the CLI version'
);

my ( $missing_args_exit, $missing_args_stdout, $missing_args_stderr ) = run_cli_capture();
is( $missing_args_exit, 1, 'Missing required arguments exits 1' );
like( $missing_args_stderr, qr/--ddl and --input are required parameters/, 'Missing required arguments print a readable error' );

my ( $json_invalid_exit, $json_invalid_payload ) = run_cli_json(
    '--ddl',   $invalid_ddl_path->stringify,
    '--input', $invalid_path->stringify,
    '--json',
);
is( $json_invalid_exit, 1, 'JSON mode exits 1 on validation failure' );
is( $json_invalid_payload->{ok}, 0, 'JSON mode reports failure' );
is( $json_invalid_payload->{error_count}, 1, 'JSON mode reports one failing row' );
is( $json_invalid_payload->{row_errors}[0]{row}, 1, 'JSON row numbering matches CLI contract' );
ok(
    scalar( @{ $json_invalid_payload->{row_errors}[0]{messages} } ) > 0,
    'JSON mode includes row-level error messages'
);

my ( $json_invalid_turbo_exit, $json_invalid_turbo_payload ) = run_cli_json(
    '--ddl',   $invalid_ddl_path->stringify,
    '--input', $invalid_path->stringify,
    '--json',
    '--turbo',
);
is( $json_invalid_turbo_exit, 1, 'Turbo JSON mode exits 1 on validation failure' );
is( $json_invalid_turbo_payload->{ok}, 0, 'Turbo JSON mode reports failure' );
is( $json_invalid_turbo_payload->{error_count}, 1, 'Turbo JSON mode reports one failing row' );
like(
    $json_invalid_turbo_payload->{row_errors}[0]{messages}[0],
    qr/Expected integer/,
    'Turbo JSON mode keeps readable type errors'
);

my ( $json_detected_sep_exit, $json_detected_sep_payload ) = run_cli_json(
    '--ddl',   $ddl_path->stringify,
    '--input', $valid_tsv_path->stringify,
    '--table', 'person',
    '--json',
);
is( $json_detected_sep_exit, 0, 'JSON mode succeeds when separator is inferred' );
is( $json_detected_sep_payload->{ok}, 1, 'JSON mode reports success with inferred separator' );

my ( $json_fatal_exit, $json_fatal_payload ) = run_cli_json(
    '--ddl',   $mismatch_ddl_path->stringify,
    '--input', $mismatch_path->stringify,
    '--json',
);
is( $json_fatal_exit, 2, 'JSON mode exits 2 on fatal setup errors' );
is( $json_fatal_payload->{ok}, 0, 'JSON fatal result reports failure' );
ok( defined $json_fatal_payload->{fatal_error}, 'JSON fatal result includes a fatal error message' );

my ( $json_ambiguous_exit, $json_ambiguous_payload ) = run_cli_json(
    '--ddl',   $ddl_path->stringify,
    '--input', $ambiguous_path->stringify,
    '--table', 'person',
    '--json',
);
is( $json_ambiguous_exit, 2, 'JSON mode exits 2 when separator inference is ambiguous' );
like(
    $json_ambiguous_payload->{fatal_error},
    qr/Ambiguous field separator/,
    'JSON fatal result reports ambiguous separator inference'
);

my ( $json_table_exit, $json_table_payload ) = run_cli_json(
    '--ddl',   $mismatch_ddl_path->stringify,
    '--input', $mismatch_path->stringify,
    '--table', 'person',
    '--json',
);
is( $json_table_exit, 0, 'Explicit --table works when filename does not match schema name' );
is( $json_table_payload->{schema_name}, 'person', 'JSON result preserves explicit table override name' );

my ( $json_save_exit, $json_save_payload ) = run_cli_json(
    '--ddl',          $ddl_path->stringify,
    '--input',        $valid_path->stringify,
    '--save-schemas', $schemas_out->stringify,
    '--json',
);
is( $json_save_exit, 0, 'JSON mode still succeeds when saving schemas' );
ok( -f $schemas_out, '--save-schemas writes the schema file' );
my $saved_schemas = JSON::XS->new->decode( $schemas_out->slurp_utf8 );
ok( exists $saved_schemas->{person}, 'Saved schema JSON contains the parsed table' );

my ( $human_fatal_exit, $human_fatal_stdout, $human_fatal_stderr ) = run_cli_capture(
    '--ddl',      $mismatch_ddl_path->stringify,
    '--input',    $mismatch_path->stringify,
    '--no-color',
);
is( $human_fatal_exit, 2, 'Human mode exits 2 on fatal setup errors' );
like( $human_fatal_stderr, qr/No schema found/, 'Human fatal mode reports a readable error' );

my ( $report_exit, $report_stdout, $report_stderr ) = run_cli_capture(
    '--ddl',        $ddl_path->stringify,
    '--input',      $mixed_path->stringify,
    '--table',      'person',
    '--report-tsv', $report_path->stringify,
    '--no-color',
);
is( $report_exit, 1, 'Report mode preserves validation-failure exit code' );
ok( -f $report_path, '--report-tsv writes a TSV report file' );
like( $report_stdout, qr/TSV report saved/, 'Human mode reports where the TSV was written' );
like( $report_stdout, qr/Validation failed with 1 failing row\(s\)/, 'Report mode prints a compact failure summary' );
unlike( $report_stdout, qr/Row 1 validation failed/, 'Report mode suppresses row-level error dumps on stdout' );

my $report_csv = Text::CSV_XS->new( { binary => 1, sep_char => "\t" } );
my $report_fh = $report_path->openr_utf8;
my $report_header = $report_csv->getline($report_fh);
is_deeply(
    $report_header,
    [
        'person_id',
        'gender_concept_id',
        'year_of_birth',
        'person_source_value',
        '_validation_row',
        '_validation_status',
        '_validation_error_count',
        '_validation_messages',
    ],
    'Report header preserves input columns and appends validation columns'
);

my $report_first_row = $report_csv->getline($report_fh);
is( $report_first_row->[0], '1', 'Report preserves original column values for valid rows' );
is( $report_first_row->[4], '1', 'Report stores the first data-row number' );
is( $report_first_row->[5], 'OK', 'Report marks valid rows as OK' );
is( $report_first_row->[6], '0', 'Report sets zero validation errors for valid rows' );
is( $report_first_row->[7], '', 'Report leaves validation messages empty for valid rows' );

my $report_second_row = $report_csv->getline($report_fh);
is( $report_second_row->[0], 'A', 'Report preserves original invalid values' );
is( $report_second_row->[4], '2', 'Report stores the failing data-row number' );
is( $report_second_row->[5], 'ERROR', 'Report marks invalid rows as ERROR' );
is( $report_second_row->[6], '1', 'Report counts row-level validation errors' );
like(
    $report_second_row->[7],
    qr/Expected integer/,
    'Report includes validation messages for invalid rows'
);
$report_fh->close;

my $has_xlsx_writer = eval { require Excel::Writer::XLSX; 1 };
if ($has_xlsx_writer) {
    my ( $xlsx_exit, $xlsx_stdout, $xlsx_stderr ) = run_cli_capture(
        '--ddl',         $ddl_path->stringify,
        '--input',       $mixed_path->stringify,
        '--table',       'person',
        '--report-xlsx', $xlsx_report_path->stringify,
        '--no-color',
    );
    is( $xlsx_exit, 1, 'XLSX report mode preserves validation-failure exit code' );
    ok( -f $xlsx_report_path, '--report-xlsx writes an XLSX report file' );
    like( $xlsx_stdout, qr/XLSX report saved/, 'Human mode reports where the XLSX was written' );
    like( $xlsx_stdout, qr/Validation failed with 1 failing row\(s\)/, 'XLSX report mode prints a compact failure summary' );
    unlike( $xlsx_stdout, qr/Row 1 validation failed/, 'XLSX report mode suppresses row-level error dumps on stdout' );

    my $workbook_xml = slurp_zip_member( $xlsx_report_path->stringify, 'xl/workbook.xml' );
    like( $workbook_xml, qr/name="Summary"/, 'XLSX workbook contains a Summary sheet' );
    like( $workbook_xml, qr/name="Validation"/, 'XLSX workbook contains a Validation sheet' );

    my $shared_strings_xml =
      slurp_zip_member( $xlsx_report_path->stringify, 'xl/sharedStrings.xml' );
    like( $shared_strings_xml, qr/_validation_status/, 'XLSX shared strings include validation columns' );
    like( $shared_strings_xml, qr/ERROR/, 'XLSX shared strings include failing status values' );
    like( $shared_strings_xml, qr/OK/, 'XLSX shared strings include success status values' );

    my $validation_sheet_xml =
      slurp_zip_member( $xlsx_report_path->stringify, 'xl/worksheets/sheet2.xml' );
    like(
        $validation_sheet_xml,
        qr/conditionalFormatting/,
        'XLSX validation sheet includes conditional formatting for spreadsheet review'
    );

    my $missing_zip_member_error = eval {
        slurp_zip_member( $xlsx_report_path->stringify, 'xl/worksheets/missing.xml' );
        1;
    };
    like(
        $@,
        qr/Archive member 'xl\/worksheets\/missing\.xml' not found/,
        'ZIP helper fails cleanly when a requested workbook member is absent'
    );
}
else {
    my ( $xlsx_exit, $xlsx_stdout, $xlsx_stderr ) = run_cli_capture(
        '--ddl',         $ddl_path->stringify,
        '--input',       $mixed_path->stringify,
        '--table',       'person',
        '--report-xlsx', $xlsx_report_path->stringify,
        '--no-color',
    );
    is( $xlsx_exit, 2, 'Missing XLSX dependency fails with a fatal exit code' );
    like(
        $xlsx_stderr,
        qr/Excel::Writer::XLSX is required/,
        'Missing XLSX dependency reports a clear installation hint'
    );
}

done_testing();
