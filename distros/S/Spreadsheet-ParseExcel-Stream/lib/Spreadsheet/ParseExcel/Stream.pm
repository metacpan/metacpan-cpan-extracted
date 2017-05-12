package Spreadsheet::ParseExcel::Stream;

use strict;
use warnings;

our $VERSION = '0.11';

sub new {

  my ($class, $file, $opts) = @_;
  $opts ||= {};
  my $type = $opts->{Type};

  if ($type) {
    return $class->xls($file, $opts)  if $type =~ /^xls$/i;
    return $class->xlsx($file, $opts) if $type =~ /^xlsx$/i;
    die "Can not parse file $file of type $type";
  }

  open(my $fh, "<", $file) or die "Failed to open $file: $!";
  my $cnt = read($fh, my $pk, 4);
  close $fh;
  die "Unable to read header from $file" unless $cnt == 4;

  return $class->xlsx($file, $opts) if $pk eq "PK\003\004";
  return $class->xls($file, $opts);
}

sub xls {
  my ($class, $file, $opts) = @_;
  require Spreadsheet::ParseExcel::Stream::XLS;
  return Spreadsheet::ParseExcel::Stream::XLS->new($file, $opts);
}

sub xlsx {
  my ($class, $file, $opts) = @_;
  require Spreadsheet::ParseExcel::Stream::XLSX;
  return Spreadsheet::ParseExcel::Stream::XLSX->new($file, $opts);
}

1;

__END__

=head1 NAME

Spreadsheet::ParseExcel::Stream - Simple interface to Excel data with less memory overhead

=head1 SYNOPSIS

  my $xls = Spreadsheet::ParseExcel::Stream->new($xls_file, \%options);
  while ( my $sheet = $xls->sheet() ) {
    while ( my $row = $sheet->row ) {
      my @data = @$row;
    }
  }

=head1 DESCRIPTION

A simple iterative interface to L<Spreadsheet::ParseExcel>, similar to L<Spreadsheet::ParseExcel::Simple>,
but does not parse the entire document to memory. Uses the hints provided in the L<Spreadsheet::ParseExcel>
docs to reduce memory usage, and returns the data row by row and sheet by sheet.

Will also parse XLSX files via L<Spreadsheet::XLSX>, but does not save any memory.

=head1 METHODS

=head2 new

  my $xls = Spreadsheet::ParseExcel::Stream->new($xls_or_xlsx_file, \%options);

Opens the spreadsheet and returns an object to iterate through the data.

Accepts an optional hashref with the following keys:

=over

=item Type

Specify the type (XLSX or XLS) of the document and use the appropriate library to parse it.
When not using this option, the library will try to determine which type of spreadsheet
is used, and will use L<Spreadsheet::ParseExcel::Stream::XLS> or L<Spreadsheet::ParseExcel::Stream::XLSX>
to parse the document. You may use either of those libraries directly instead of specifying this
option.

=item Password

Password to decrypt XLS documents with. This option is passed on to L<Spreadsheet::ParseExcel>.

=item TrimEmpty

If true, trims leading empty columns. Trims however many empty columns that the row with the minimum number
of empty columns has. E.g. if row 1 has data in columns B, C, and D, and row 2 has data in C, D, and E, then
row 1 will shift to A, B, and C, and row 2 will shift to B, C, and D.

Not implemented for XLSX files.

=item BindColumns

Accepts a reference to a list of references to scalars. Calls bind_columns on the list.

=back

=head2 sheet

Returns the next worksheet of the workbook.

=head2 row

Returns the next row of data from the current spreadsheet. The data is the formatted
contents of each cell as returned by the $cell->value() method of Spreadsheet::ParseExcel.

If a true argument is passed in, returns the current row of data without advancing to the
next row.

=head2 unformatted

Returns the next row of data from the current spreadsheet as returned
by the $cell->unformatted() method of Spreadsheet::ParseExcel.

If a true argument is passed in, returns the current row of data without advancing to the
next row.

=head2 next_row

Returns the next row of cells from the current spreadsheet as Spreadsheet::ParseExcel
cell objects.

If a true argument is passed in, returns the current row without advancing to the
next row.

=head2 name

Returns the name of the current worksheet.

=head2 bind_columns

Accepts an array of references to scalars. Binds the output of the row, unformatted, and next_row
methods to the list of scalars if the 'current row' argument to those methods is not true.

If output is bound, then a simple true value instead of a reference to an array
is returned from those methods if there is a next row.

=head2 unbind_columns

Unbinds any scalars bound with bind_columns().

=head2 workbook

Returns the workbook as a Spreadsheet::ParseExcel object.

=head2 worksheet

Returns the current worksheet as a Spreadsheet::ParseExcel object.

=head1 AUTHOR

Douglas Wilson, E<lt>dougw@cpan.org<gt>

=head1 BUGS AND LIMITATIONS

For spreadsheets created with L<Spreadsheet::WriteExcel> without using
C<$wb-E<gt>compatibility_mode()>, this module will read rows of a spreadsheet
out of order if the rows were written out of order, and the TrimEmpty option of 
this module will not work correctly.

=head1 COPYRIGHT AND LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Spreadsheet::ParseExcel>, L<Spreadsheet::ParseExcel::Simple>

=cut
