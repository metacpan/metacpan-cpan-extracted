# reorder-csv.pl

## Overview

**reorder-csv.pl** is a Perl utility that reorders the columns of an input CSV file to match the column order specified in a DDL file. It is mainly useful as a load-preparation step for workflows where column position matters, such as SQLite `.import` or positional PostgreSQL loads.

## Features

- **DDL-Based Reordering:** Extracts the column order from a DDL file (using either `CREATE TABLE` or `CREATE INDEX` statements).
- **Flexible Input/Output:** Reads a CSV file with a header row and writes a new CSV with columns reordered according to the DDL.
- **Customizable Field Separator:** Defaults to a tab (`\t`) but supports a custom separator.
- **Missing Columns Handling:** Inserts a predefined NULL value (`\N`) for any columns missing from the input CSV.
- **Built-In Help:** Displays usage information when required arguments are missing or when the help flag is used.

## Dependencies

#### Note: If you installed `omop-csv-validator` this should work out-of-the-box.

- **Perl:** Make sure Perl is installed on your system.
- **Modules:**
  - `Text::CSV_XS` for CSV processing.

## Usage

Run the script with the following options:

```bash
perl reorder-csv.pl --ddl DDL_FILE --input INPUT_CSV --output OUTPUT_CSV [--ddl-type postgresql|sqlite] [--sep SEPARATOR]
```

### Arguments

- `--ddl`: File containing the DDL (either `CREATE TABLE` or index definitions).
- `--input`: Input CSV file (must include a header row).
- `--output`: Output CSV file with columns reordered to match the DDL.
- `--sep`: *(Optional)* Field separator character (defaults to tab `\t`).
- `--table`: *(Optional)* Override the table name to look up in the DDL. If not provided, the script derives it from the CSV filename.
- `--ddl-type`: Type of the DDL format. Supported values: `sqlite`, `postgresql` (optional, defaults to `postgresql`).

### Example

```bash
perl reorder-csv.pl --ddl schema_postgres.sql --input PERSON.csv --output reordered_data.csv
perl reorder-csv.pl --ddl schema_postgres.sql --input my_table.csv --output reordered_data.csv --table person
perl reorder-csv.pl --ddl schema_sqlite.sql --ddl-type sqlite --input PERSON.csv --output reordered_data.csv
```

## Author 

Written by Manuel Rueda, PhD. Info about CNAG can be found at [https://www.cnag.eu](https://www.cnag.eu).

## License

This project is released under the [Artistic License 2.0](../LICENSE).
