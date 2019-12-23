package Spreadsheet::GenerateXLSX;
$Spreadsheet::GenerateXLSX::VERSION = '0.05';
use 5.008;
use strict;
use warnings;

use parent 'Exporter';

use Carp                qw/ croak /;
use Ref::Util           qw/ is_arrayref is_ref /;
use Excel::Writer::XLSX;

our @EXPORT_OK = qw/ generate_xlsx /;

my $MAX_EXCEL_COLUMN_WIDTH = 80;


my $define_formats = sub {
    my $workbook = shift;
    my $formats  = {};

    my @common_settings = (
             size => 12,
        text_wrap => 1,
            align => 'left',
    );

    $formats->{header} = $workbook->add_format(@common_settings,
                              bold => 1,
                             color => 'black',
                         );

    $formats->{cell}   = $workbook->add_format(@common_settings,
                              bold => 0,
                             color => 'gray',
                         );

    return $formats;
};

my $find_sheet_dimensions = sub {
    my $data          = shift;
    my $nrows         = int(@$data);
    my $n_header_cols = int(@{ $data->[0] });
    my $ncols         = $n_header_cols;
    my $s             = $n_header_cols == 1 ? '' : 's';

    foreach my $row (@$data) {
        $ncols = int(@$row) if int(@$row) > $ncols;
    }

    # If there are data rows with more columns than there are
    # header columns, then we let the caller know, because the
    # auto filters will look a bit goofy
    if ($ncols > $n_header_cols) {
        # TODO: this should be a carp, but need to skip a call frame
        warn "generate_xlsx(): you gave me $n_header_cols header column$s, ",
             "but at least one row has $ncols columns.\n";
    }

    return ($nrows, $ncols);
};

my $set_column_widths = sub {
    my ($sheet, $widths_ref) = @_;
    my $col_num = 0;

    foreach my $width (@$widths_ref) {
        # This is a heuristic (ok, nasty hack) for approximating the column
        # width in whatever these excel units are, based on the number of chars.
        # It works well enough most of the time.
        my $column_width = 11 + 1.1 * ($width > 9 ? ($width - 9) : 1);
        if ($column_width > $MAX_EXCEL_COLUMN_WIDTH) {
            $column_width = $MAX_EXCEL_COLUMN_WIDTH;
        }
        $sheet->set_column($col_num, $col_num, $column_width);
        $col_num++;
    }
};

my $generate_sheet = sub {
    my ($book, $formats, $sheetname, $data) = @_;
    my ($nrows, $ncols) = $find_sheet_dimensions->($data);
    my $sheet           = $book->add_worksheet($sheetname);
    my $row_num         = 0;
    my @widths;

    foreach my $row (@$data) {
        my $celltype = ($row_num == 0 ? 'header' : 'cell');
        my $col_num  = 0;

        foreach my $cell (@$row) {
            $sheet->write($row_num, $col_num, $cell, $formats->{$celltype});
            if (!defined($widths[$col_num]) || (defined($cell) && length($cell) > $widths[$col_num])) {
                $widths[$col_num] = length($cell);
            }
            $col_num++;
        }
        $row_num++;
    }

    $set_column_widths->($sheet, \@widths);

    $sheet->autofilter(0, 0, $nrows-1, $ncols-1);
    $sheet->freeze_panes(1, 0);
};

sub generate_xlsx
{
    my $filename     = shift;
    my $sheet_number = 1;
    my $book         = Excel::Writer::XLSX->new( $filename )
                       || croak "failed to create workbook\n";
    my $formats      = $define_formats->($book);
    my $sheet_name;

    # Note: if you set this then you have to write rows in order.
    #       any out-of-order writes are effectively ignored.
    #       see the doc for Excel::Writer::XLSX
    $book->set_optimization;

    while (@_ > 0) {
        my $data = shift @_;

        if (is_arrayref($data)) {
            $sheet_name = "Sheet$sheet_number";
        }
        elsif (!is_ref($data) && @_ > 0) {
            $sheet_name = $data;
            $data       = shift @_;
        }
        else {
            croak "unexpected arguments -- see the documentation\n";
        }

        $generate_sheet->($book, $formats, $sheet_name, $data);

        $sheet_number++;

    }

    $book->close;
}

1;

=head1 NAME

Spreadsheet::GenerateXLSX - function to generate XLSX spreadsheet from array ref(s)

=head1 SYNOPSIS

 use Spreadsheet::GenerateXLSX qw/ generate_xlsx /;

 my @data = (
             ['Heading 1', 'Heading 2', 'Heading 2'],
             ['blah',      'blah',      'blah'],
             ['blah',      'blah',      'blah'],
            );
 generate_xlsx('example.xlsx', \@data);

=head1 DESCRIPTION

This module provides a function C<generate_xlsx> which takes
an array of Perl data and generates a simple Excel spreadsheet
in the XLSX format.
The generated sheets have the first row frozen,
and auto filters enabled for every column.

Each sheet in the spreadsheet is generated from an array of rows,
where each row is an arrayref.
The first row is treated as a header row.
Here's an example:

 my @sheet1 = (
    ['Pokemon',  'Type',      'Number'],
    ['Pikachu',  'Electric',  25],
    ['Vulpix',   'Fire',      37],
    ['Ditto',    'Normal',    132],
 );

The generated spreadsheet can have any numbers of sheets:

 generate_xslx('pokemon.xlsx', \@sheet1, \@sheet2);

If you just pass arrayrefs, the sheets will be named B<Sheet1>, B<Sheet2>, etc.
You can also pass the name of the sheet:

 generate_xslx('pokemon.xlsx', 'All Pokemon' => \@sheet1, 'Hit List' => \@sheet2);


=head1 SEE ALSO

The following modules can all generate the XLSX format.
I also wrote a L<blog post|http://neilb.org/2016/12/10/spreadsheet-generate-xlsx.html>
which gives more details on some of these.

=over 4

L<Excel::Writer::XLSX> - the underlying module used to generate the spreadsheet.
Gives you full control over the spreadsheet generated, but as a result has a much
more complex interface.

L<Spreadsheet::WriteExcel::Styler> - helps with formatting of cells when
using C<Excel::Writer::XLSX> or C<Spreadsheet::WriteExcel>.

L<Spreadsheet::Template> - used to generate spreadsheets from
"JSON files which describe the desired content and formatting".
By default it generates XLSX format.

L<Data::Table::Excel> - converts between L<Data::Table> objects and XLS or XLSX format spreadsheets.

L<XLS::Simple> - provides a simple interface for both reading and writing spreadsheets.
Minimal documentation, and what there is is written in Japanese.
The function for creating a spreadsheet is called `write_xls()`,
but it generates the XLSX format.

=back

The following modules only generate Microsoft's earlier xls binary format.

=over 4

L<Spreadsheet::WriteExcel> - provides the same interface as C<Excel::Writer::XLSX>,
but generates the XLS format.

L<Spreadsheet::WriteExcel::FromDB> - converts a database table to an XLS format spreadsheet.

L<Spreadsheet::WriteExcel::FromDB::Query> - converts a query to an XLS spreadsheet,
as opposed to a table.

L<Spreadsheet::WriteExcel::Simple> - provides a simpler OO interface
for generating single-sheet XLS spreadsheets.

L<Spreadsheet::Write> - another simplified OO interface, which can write CSV or XLS output,
but not XLSX.

L<Spreadsheet::Wright> - a fork of C<Spreadsheet::Write> which supports more output formats
(CSV, XLS, HTML, XHTML, XML, ODS, and JSON), but doesn't (appear to) support XLSX.

L<Spreadsheet::DataToExcel> - provides a simple OO interface for generating XLS spreadsheets,
and provides some control over the generated format.
But, as with most of the modules listed here, only XLS output is supported.

L<Spreadsheet::WriteExcel::Simple::Tabs> - a very simple OO interface built on C<Spreadsheet::WriteExcel>.
This one is close to the spirit of C<Spreadsheet::GenerateXLSX>, but only generates XLS.

=back

=head1 TODO

 * smarter auto-formatting of columns
 * more tests
 * better error handler


=head1 REPOSITORY

L<https://github.com/neilb/Spreadsheet-GenerateXLSX>


=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

