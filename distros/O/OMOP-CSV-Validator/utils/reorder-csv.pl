#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Path::Tiny;
use Text::CSV_XS;

# Define variables for command-line options, default separator to tab
my ( $ddl_file, $input_csv, $output_csv, $ddl_type, $help );
my $sep_char = "\t";
my $NULL     = '\\N';

# Parse options using Getopt::Long
GetOptions(
    "ddl=s"      => \$ddl_file,
    "input=s"    => \$input_csv,
    "output=s"   => \$output_csv,
    "ddl-type=s" => \$ddl_type,
    "sep=s"      => \$sep_char,
    "help"       => \$help,
) or die "Error in command line arguments\n";

# Show usage if help requested or required arguments are missing
if ( $help || !( $ddl_file && $input_csv && $output_csv && $ddl_type ) ) {
    print <<"USAGE";
Usage:
    ./$0 --ddl DDL_FILE --ddl-type TYPE --input INPUT_CSV --output OUTPUT_CSV [--sep SEPARATOR]

Options:
    --ddl        (required) File containing the DDL (CREATE TABLE or index definitions)
    --ddl-type   (required) Type of the DDL (e.g., sqlite, postgresql)
    --input      (required) Input CSV file (with header row)
    --output     (required) Output CSV file with columns reordered to match the DDL
    --sep        Field separator character (default: tab)
    --help, -h   Show this help message.
    --version, -V  Show the script's version.

Example:
    ./$0 --ddl schema.sql --ddl-type postgresql --input PERSON.csv --output output.csv --sep ";"
USAGE
    exit;
}

( my $table = lc $input_csv ) =~ s{^.*/}{};      # remove any path and lowercase
$table =~ s/\.csv$//i;                           # remove the .csv extension

# Read the DDL file into a single string
my $ddl_text = path($ddl_file)->slurp_utf8;

# Remove comments
$ddl_text =~ s|/\*.*?\*/||gs;
$ddl_text =~ s/--.*\n/\n/g;

my @desired_order;

# Extract columns for the specified table based on DDL type
if ( $ddl_type eq 'sqlite' ) {
    if ( $ddl_text =~ /CREATE\s+TABLE\s+$table\s*\((.*?)\);/is ) {
        my $columns_text = $1;
        my @lines        = split /,/, $columns_text;
        for my $line (@lines) {
            $line =~ s/^\s+|\s+$//g;
            next unless $line;
            if ( $line =~ /^\"?(\w+)\"?\s+/ ) {
                push @desired_order, $1;
            }
        }
    }
}
elsif ( $ddl_type eq 'postgresql' ) {
    my $table_re = qr/CREATE\s+TABLE\s+[^.]*\.?$table\s*\((.*?)\);/is;
    if ( $ddl_text =~ /$table_re/ ) {
        my $columns_text = $1;
        my @lines        = split /,\n/, $columns_text;
        for my $line (@lines) {
            $line =~ s/^\s+|\s+$//g;
            next unless $line;
            if ( $line =~ /^\"?(\w+)\"?\s+/ ) {
                push @desired_order, $1;
            }
        }
    }
}

# Die if no columns were found
unless (@desired_order) {
    die
"Could not find columns for table '$table' in the DDL file (type: $ddl_type)\n";
}

# Set up CSV reading
my $csv_in = Text::CSV_XS->new( { binary => 1, sep_char => $sep_char } )
  or die "Cannot use CSV: " . Text::CSV->error_diag();
open my $fh_in, "<:encoding(utf8)", $input_csv
  or die "Cannot open '$input_csv': $!";

my $header = $csv_in->getline($fh_in);
die "Input CSV has no header row\n" unless $header;

my %header_idx = map { $header->[$_] => $_ } 0 .. $#$header;

# Set up output CSV writer
my $csv_out = Text::CSV_XS->new( { binary => 1, sep_char => $sep_char } )
  or die "Cannot use CSV: " . Text::CSV->error_diag();
open my $fh_out, ">:encoding(utf8)", $output_csv
  or die "Cannot open '$output_csv': $!";

$csv_out->print( $fh_out, \@desired_order );
print $fh_out "\n";

while ( my $row = $csv_in->getline($fh_in) ) {
    my @new_row =
      map { exists $header_idx{$_} ? $row->[ $header_idx{$_} ] : $NULL }
      @desired_order;
    $csv_out->print( $fh_out, \@new_row );
    print $fh_out "\n";
}

close $fh_in;
close $fh_out;

print "Reordered CSV written to '$output_csv'\n";
