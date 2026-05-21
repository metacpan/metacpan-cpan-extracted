#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib 'lib';
use lib 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use Path::Tiny;

use TestHelper qw(write_fixture run_reorder_capture);

my $postgres_ddl = <<'DDL';
CREATE TABLE public.person (
    person_id integer NOT NULL,
    gender_concept_id integer NOT NULL,
    year_of_birth integer NOT NULL,
    person_source_value varchar(50) NULL
);
DDL

my $sqlite_ddl = <<'DDL';
CREATE TABLE person (
    person_id INTEGER NOT NULL,
    gender_concept_id INTEGER NOT NULL,
    year_of_birth INTEGER NOT NULL,
    person_source_value TEXT NULL
);
DDL

my $comma_csv = <<'CSV';
gender_concept_id,person_source_value,person_id
8532,source1,1
CSV

my $tab_csv = <<'CSV';
gender_concept_id	person_source_value	person_id
8532	source1	1
CSV

my $override_csv = <<'CSV';
gender_concept_id,person_source_value,person_id
8532,source2,2
CSV

my $semicolon_csv = <<'CSV';
gender_concept_id;person_source_value;person_id
8532;source3;3
CSV

my $dir = tempdir( CLEANUP => 1 );
my $pg_ddl_path = write_fixture( $dir, 'postgres.sql', $postgres_ddl );
my $sqlite_ddl_path = write_fixture( $dir, 'sqlite.sql', $sqlite_ddl );
my $comma_csv_path = write_fixture( $dir, 'PERSON.csv', $comma_csv );
my $tab_csv_path = write_fixture( $dir, 'TAB_INPUT.csv', $tab_csv );
my $override_csv_path = write_fixture( $dir, 'EXPORT.csv', $override_csv );
my $semicolon_csv_path = write_fixture( $dir, 'SEMICOLON.csv', $semicolon_csv );
my $pg_out_path = path( $dir, 'PERSON.reordered.csv' );
my $sqlite_out_path = path( $dir, 'PERSON.sqlite.csv' );
my $override_out_path = path( $dir, 'EXPORT.reordered.csv' );
my $semicolon_out_path = path( $dir, 'SEMICOLON.reordered.csv' );

my ( $help_exit, $help_stdout, $help_stderr ) = run_reorder_capture('--help');
is( $help_exit, 0, 'Reorder utility --help exits 0' );
like( $help_stdout, qr/Usage:/, 'Reorder utility --help prints usage text' );

my ( $version_exit, $version_stdout, $version_stderr ) = run_reorder_capture('--version');
is( $version_exit, 0, 'Reorder utility --version exits 0' );
like( $version_stdout, qr/Version 0\.03/, 'Reorder utility --version prints its version' );

my ( $pg_exit, $pg_stdout, $pg_stderr ) = run_reorder_capture(
    '--ddl',    $pg_ddl_path->stringify,
    '--input',  $comma_csv_path->stringify,
    '--output', $pg_out_path->stringify,
);
is( $pg_exit, 0, 'Reorder utility succeeds for PostgreSQL DDL without explicit ddl-type' );
like( $pg_stdout, qr/Reordered CSV written/, 'Reorder utility reports the output path' );
my @pg_lines = split /\n/, $pg_out_path->slurp_utf8;
is( $pg_lines[0], 'person_id,gender_concept_id,year_of_birth,person_source_value', 'PostgreSQL reorder writes DDL column order' );
is( $pg_lines[1], '1,8532,\N,source1', 'PostgreSQL reorder inserts \\N for missing columns' );

my ( $sqlite_exit, $sqlite_stdout, $sqlite_stderr ) = run_reorder_capture(
    '--ddl',      $sqlite_ddl_path->stringify,
    '--ddl-type', 'sqlite',
    '--input',    $tab_csv_path->stringify,
    '--output',   $sqlite_out_path->stringify,
    '--table',    'person',
);
is( $sqlite_exit, 0, 'Reorder utility still supports SQLite DDL' );
my @sqlite_lines = split /\n/, $sqlite_out_path->slurp_utf8;
is( $sqlite_lines[0], "person_id\tgender_concept_id\tyear_of_birth\tperson_source_value", 'SQLite reorder keeps tab output when separator is inferred' );
is( $sqlite_lines[1], "1\t8532\t\\N\tsource1", 'SQLite reorder preserves positional-import shape with \\N filler' );

my ( $override_exit, $override_stdout, $override_stderr ) = run_reorder_capture(
    '--ddl',    $pg_ddl_path->stringify,
    '--input',  $override_csv_path->stringify,
    '--output', $override_out_path->stringify,
    '--table',  'person',
);
is( $override_exit, 0, '--table override works when filename does not match table name' );
my @override_lines = split /\n/, $override_out_path->slurp_utf8;
is( $override_lines[1], '2,8532,\N,source2', '--table override uses the requested table order' );

my ( $semicolon_exit, $semicolon_stdout, $semicolon_stderr ) = run_reorder_capture(
    '--ddl',    $pg_ddl_path->stringify,
    '--input',  $semicolon_csv_path->stringify,
    '--output', $semicolon_out_path->stringify,
    '--table',  'person',
    '--sep',    ';',
);
is( $semicolon_exit, 0, 'Reorder utility accepts an explicit separator override' );
my @semicolon_lines = split /\n/, $semicolon_out_path->slurp_utf8;
is( $semicolon_lines[0], 'person_id;gender_concept_id;year_of_birth;person_source_value', 'Separator override is preserved in the output header' );
is( $semicolon_lines[1], '3;8532;\N;source3', 'Separator override is preserved in reordered data rows' );

my ( $bad_type_exit, $bad_type_stdout, $bad_type_stderr ) = run_reorder_capture(
    '--ddl',      $pg_ddl_path->stringify,
    '--ddl-type', 'mysql',
    '--input',    $comma_csv_path->stringify,
    '--output',   $pg_out_path->stringify,
);
isnt( $bad_type_exit, 0, 'Unsupported ddl-type exits non-zero' );
like( $bad_type_stderr, qr/Unsupported --ddl-type 'mysql'/, 'Unsupported ddl-type prints a readable error' );

done_testing();
