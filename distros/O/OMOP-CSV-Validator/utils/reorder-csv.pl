#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Getopt::Long;
use Path::Tiny;
use Text::CSV_XS;
use OMOP::CSV::Validator;

my ( $ddl_file, $input_csv, $output_csv, $ddl_type, $help, $table_name, $sep_char );
my $NULL = '\\N';
my $VERSION = '0.03';

GetOptions(
    "ddl=s"      => \$ddl_file,
    "input=s"    => \$input_csv,
    "output=s"   => \$output_csv,
    "ddl-type=s" => \$ddl_type,
    "table|t=s"  => \$table_name,
    "sep=s"      => \$sep_char,
    "help|h"     => \$help,
    "version|V"  => sub {
        print "$0 Version $VERSION\n";
        exit;
    },
) or die "Error in command line arguments\n";

$ddl_type //= 'postgresql';

if ( $help || !( $ddl_file && $input_csv && $output_csv ) ) {
    print <<"USAGE";
Usage:
    $0 --ddl DDL_FILE --input INPUT_CSV --output OUTPUT_CSV
       [--table TABLE_NAME] [--sep SEPARATOR] [--ddl-type postgresql] [--help] [--version]

Options:
    --ddl           (required) File containing the DDL
    --input         (required) Input CSV file (with header row)
    --output        (required) Output CSV file with columns reordered to match the DDL
    --table, -t     (optional) Override the table name to look up in the DDL.
                      If not provided, the script derives it from the CSV filename.
    --sep           (optional) Field separator override. If omitted, the script tries
                      to infer the separator from the input file.
    --ddl-type      (optional) DDL type. Defaults to postgresql. Supported values:
                      postgresql, sqlite
    --help, -h      Show this help message
    --version, -V   Show the script's version

Example:
    $0 --ddl schema.sql --input PERSON.csv --output output.csv
    $0 --ddl schema.sql --table person --input ANY_CSV.csv --output output.csv
    $0 --ddl schema.sql --input PERSON.csv --output output.csv --sep $'\\t'

USAGE
    exit;
}

my $validator = OMOP::CSV::Validator->new();
my $ddl_text  = path($ddl_file)->slurp_utf8;
my $table =
  $table_name
  ? lc $table_name
  : $validator->_table_name_from_csv_filename($input_csv);
$ddl_text =~ s|/\*.*?\*/||gs if $ddl_type eq 'sqlite';
$ddl_text =~ s/--.*\n/\n/g   if $ddl_type eq 'sqlite';

sub sqlite_column_order_from_ddl {
    my ( $ddl_text, $table ) = @_;
    my @desired_order;

    if ( $ddl_text =~ /CREATE\s+TABLE\s+$table\s*\((.*?)\);/is ) {
        my $columns_text = $1;
        my @lines        = split /,/, $columns_text;
        for my $line (@lines) {
            $line =~ s/^\s+|\s+$//g;
            next unless $line;
            if ( $line =~ /^\"?(\w+)\"?\s+/ ) {
                push @desired_order, lc $1;
            }
        }
    }

    die "Could not find columns for table '$table' in the DDL file\n"
      unless @desired_order;
    return \@desired_order;
}

my $desired_order =
    $ddl_type eq 'postgresql' ? $validator->load_column_order_from_ddl( $ddl_text, $table )
  : $ddl_type eq 'sqlite'     ? sqlite_column_order_from_ddl( $ddl_text, $table )
  : die "Unsupported --ddl-type '$ddl_type'. Supported values: postgresql, sqlite.\n";
$sep_char = defined $sep_char ? $sep_char : $validator->detect_csv_separator($input_csv);

sub csv_parser_for_sep {
    my ($sep) = @_;
    my $csv = Text::CSV_XS->new(
        {
            binary         => 1,
            sep_char       => $sep,
            auto_diag      => 1,
            blank_is_undef => 0,
        }
    );
    die "Cannot use CSV: " . Text::CSV_XS->error_diag() unless $csv;
    return $csv;
}

my $csv_in = csv_parser_for_sep($sep_char);
my $fh_in  = path($input_csv)->openr_utf8;
my $header = $csv_in->getline($fh_in);
die "Input CSV has no header row\n" unless $header;
my %header_idx = map { lc( $header->[$_] ) => $_ } 0 .. $#$header;

my $csv_out = csv_parser_for_sep($sep_char);
my $fh_out  = path($output_csv)->openw_utf8;

$csv_out->print( $fh_out, $desired_order );
print {$fh_out} "\n";

while ( my $row = $csv_in->getline($fh_in) ) {
    my @new_row = map {
        my $source_index = $header_idx{ lc $_ };
        defined $source_index ? $row->[$source_index] : $NULL;
    } @{$desired_order};

    $csv_out->print( $fh_out, \@new_row );
    print {$fh_out} "\n";
}

$fh_in->close;
$fh_out->close;

print "Reordered CSV written to '$output_csv'.\n";
