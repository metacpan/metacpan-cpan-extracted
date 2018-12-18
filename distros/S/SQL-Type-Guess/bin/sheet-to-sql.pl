#!perl -w
use strict;
use 5.014; # for /r
use Getopt::Long;
use Pod::Usage;
use SQL::Type::Guess;
use Text::CleanFragment;
use Spreadsheet::Read;
use File::Glob qw( bsd_glob );

our $VERSION = '0.05';

GetOptions(
    's|sheet:s' => \my $sheet_num,
    'h|header:s' => \my $header_row,
    'separator:s' => \my $separator,
    'f|format:s' => \my $format,
    'k|keep-headers' => \my $keep_headers,
    'help' => \my $help,
) or pod2usage(2);
pod2usage(1) if $help;
$header_row ||= 1;
$sheet_num ||= 1;

my @format;
if( $format ) {
    @format = (parser => $format);
};

if( $separator ) {
    $separator= eval $separator if $separator =~ m/^\\\w$/;
    push @format, sep => $separator;
};

my $g= SQL::Type::Guess->new();
@ARGV= map { bsd_glob $_ } @ARGV;
my $headers;
for my $f (@ARGV) {
    my $s= ReadData( $f, @format );
    
    if(! $s ) {
        warn "Couldn't read '$f'";
        next
    };
        
    my $sheet= $s->[ $sheet_num ];
    $headers ||= [ Spreadsheet::Read::row($sheet, $header_row) ];

    if( ! $keep_headers ) {
        @$headers= map {
            clean_fragment($_) =~ s/-/_/gr
        } @$headers;
    };

    for my $row ($header_row+1..$sheet->{ maxrow }) {
        my %info;
        @info{ @$headers }= Spreadsheet::Read::row($sheet, $row );
        $g->guess( \%info );
    };
};
print $g->as_sql( columns => $headers );

=head1 NAME

sheet-to-sql - output the CREATE TABLE statement for an Excel sheet or CSV file

=head1 SYNOPSIS

  sheet-to-sql myfile.xls
  sheet-to-sql myfile.csv --header=2

=head1 OPTIONS

=over 8

=item B<--sheet=NUM>

Number of the sheet to use. Counting starts at 1. Default is 1.

=item B<--header=NUM>

Line in which the column headers are. Counting starts at 1. Default is 1.

=item B<--keep-headers>

Do not convert the headers to something that SQL wants but keep them
as they are in the sheet. Default is to convert the headers
to something nice.

=back

=cut