# NAME

csv2pheno-ranker: A script to convert a CSV to an input suitable for Pheno-Ranker

# SYNOPSIS

    csv2pheno-ranker -i <input.csv> [-options]

      Arguments:
        -i, --input <input.csv>          CSV file

      Options:
        -generate-primary-key            Generates a primary key if absent. Use --primary-key-name to set its name
        -primary-key-name <name>         Sets the name for the primary key. Must be a single, non-array field
        -sep, --separator <char>         Delimiter for CSV fields [;] (e.g., --sep $'\t' for tabs)
        -array-separator <char>          Delimiter for nested arrays [|] (e.g., --array-separator ';' for semicolons)
        -output-dir <directory>          Specify the directory where output files will be stored. If not specified, outputs will be placed in the same directory as the input file

      Generic Options:
        -debug <level>                   Print debugging (from 1 to 5, being 5 max)
        -h, --help                       Brief help message
        -man                             Full documentation
        -v, --verbose                    Verbosity on
        -V, --version                    Print version

# DESCRIPTION

Numerous tools exist for CSV to JSON conversion, but our focus here was on creating JSON specifically for `Pheno-Ranker`. The script supports both basic CSV files and complex, comma-separated CSV files with nested fields, ensuring seamless `Pheno-Ranker` integration.

The script will create both a JSON file and the configuration file for `Pheno-Ranker`. Then, you can run `Pheno-Ranker` as:

    $ pheno-ranker -r my_csv.json --config --my_csv_config.yaml

Note that we load all data in memory before dumping the JSON file. If you have a huge CSV (e.g.,>5M rows) please use a computer that has enough RAM.

# SUMMARY

A script to convert a CSV to an input suitable for `Pheno-Ranker`

# INSTALLATION

(only needed if you did not install `Pheno-Ranker`)

    $ cpanm --sudo --installdeps .

### System requirements

    * Ideally a Debian-based distribution (Ubuntu or Mint), but any other (e.g., CentOs, OpenSuse) should do as well.
    * Perl 5 (>= 5.10 core; installed by default in most Linux distributions). Check the version with "perl -v"
    * 1GB of RAM.
    * 1 core (it only uses one core per job).
    * At least 1GB HDD.

# HOW TO RUN CSV2PHENO-RANKER

The software requires a CSV file as the input and operates with default settings. By default, both the `JSON` file and the configuration file will be created in the same directory as the input file, and will share the same basename.

If you have columns with nested values make sure that you use `--array-separator` to define the delimiting character (default is "|").

If you want to change some parameters please take a look to the synopsis.

**Examples:**

    $ ./csv2pheno-ranker -i example.csv
    
    $ ./csv2pheno-ranker -i example.csv --generate-primary-key --primary-key-name ID

    $ ./csv2pheno-ranker -i example.csv --generate-primary-key --primary-key-name ID  --output-dir /my-path --sep ';' --array-separator ','

## COMMON ERRORS AND SOLUTIONS

    * Error message: Foo
      Solution: Bar

    * Error message: Foo
      Solution: Bar

# AUTHOR 

Written by Manuel Rueda, PhD. Info about CNAG can be found at [https://www.cnag.eu](https://www.cnag.eu).

# COPYRIGHT AND LICENSE

This PERL file is copyrighted. See the LICENSE file included in this distribution.
