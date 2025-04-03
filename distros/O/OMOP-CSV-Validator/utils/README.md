# reorder-csv.pl

## Overview

**reorder-csv.pl** is a Perl utility that reorders the columns of an input CSV file to match the column order specified in a DDL file. The DDL can contain either a `CREATE TABLE` statement or index definitions, making it easier to prepare CSV files for database imports.

## Features

- **DDL-Based Reordering:** Extracts the column order from a DDL file (using either `CREATE TABLE` or `CREATE INDEX` statements).
- **Flexible Input/Output:** Reads a CSV file with a header row and writes a new CSV with columns reordered according to the DDL.
- **Customizable Field Separator:** Defaults to a tab (`\t`) but supports a custom separator.
- **Missing Columns Handling:** Inserts a predefined NULL value (`\N`) for any columns missing from the input CSV.
- **Built-In Help:** Displays usage information when required arguments are missing or when the help flag is used.

## Dependencies

- **Perl:** Make sure Perl is installed on your system.
- **Modules:**
  - `Getopt::Long` for command-line option parsing.
  - `Text::CSV_XS` for CSV processing.

## Usage

Run the script with the following options:

```bash
perl reorder-csv.pl -ddl-type postgresql --ddl DDL_FILE --input INPUT_CSV --output OUTPUT_CSV [--sep SEPARATOR]
```

### Arguments

- `--ddl`: File containing the DDL (either `CREATE TABLE` or index definitions).
- `--input`: Input CSV file (must include a header row).
- `--output`: Output CSV file with columns reordered to match the DDL.
- `--sep`: *(Optional)* Field separator character (defaults to tab `\t`).
- `--table`: *(Optional)* Override the table name to look up in the DDL. If not provided, the script derives it from the CSV filename.
- `--ddl-type`: Type of the DDL format. Supported values: `sqlite`, `postgresql` (required).

### Example

```bash
perl reorder-csv.pl --ddl schema_postgres.sql --ddl-type postgresql --input PERSON.csv --output reordered_data.csv --sep $'\t'
perl reorder-csv.pl --ddl schema_postgres.sql --ddl-type postgresql --input my_table.csv --output reordered_data.csv --sep $'\t' --table person
```

## Author 

Written by Manuel Rueda, PhD. Info about CNAG can be found at [https://www.cnag.eu](https://www.cnag.eu).

## License

This project is released under the [Artistic License 2.0](../LICENSE).
