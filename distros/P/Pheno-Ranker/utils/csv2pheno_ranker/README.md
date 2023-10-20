# NAME

csv2pheno-ranker: A script to convert a CSV to an input suitable for Pheno-Ranker

# SYNOPSIS

csv2pheno-ranker -i &lt;input.csv> \[-options\]

     Options:
       -i|input                       CSV file
       -primary-key                   Name of the field that you want to use as identifier (MUST BE NON-ARRAY)
       -sep|separator                 Delimiter character for CSV files [;] e.g., --sep $'\t'
       -set-primary-key               To force inserting a primary key (in case your CSV does not have one). The name will be set with --primary-key

     Generic Options;
       -debug                         Print debugging (from 1 to 5, being 5 max)
       -h|help                        Brief help message
       -man                           Full documentation
       -v|verbose                     Verbosity on
       -V|version                     Print version

# DESCRIPTION

There are hundreds of online tools available for converting CSV to JSON, and we saw no need to reinvent the wheel. Our primary focus was on efficiently getting the job done, enabling seamless compatibility between CSV and Pheno-Ranker.

This script is designed to handle both simple CSV files without nested fields in columns, as well as more complex ones with nested fields, as long as they are comma-separated.

The script will create both a JSON file and the configuration file for `Pheno-Ranker`. You can run `Pheno-Ranker` as:

    $ pheno-ranker -r my_csv.json --config --my_csv_config.yaml

Note that we load all data in memory before dumping the JSON file. If you have a huge CSV (e.g.,>5M rows) please use a computer that has enough RAM.

# SUMMARY

A script to convert a CSV to an input suitable for Pheno-Ranker

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

The software needs a csv as input file and assumes defaults. If you want to change some parameters please take a look to the synopsis.

**Examples:**

    $ ./csv2pheno-ranker -i example.csv
    
    $ ./csv2pheno-ranker -i example.csv --set-primary-key --primary-key ID

## COMMON ERRORS AND SOLUTIONS

    * Error message: Foo
      Solution: Bar

    * Error message: Foo
      Solution: Bar

# AUTHOR 

Written by Manuel Rueda, PhD. Info about CNAG can be found at [https://www.cnag.crg.eu](https://www.cnag.crg.eu).

# COPYRIGHT AND LICENSE

This PERL file is copyrighted. See the LICENSE file included in this distribution.
