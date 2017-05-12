package Spreadsheet::ParseExcel::Simple;

$VERSION = '1.04';

use strict;
use Spreadsheet::ParseExcel;

=head1 NAME

Spreadsheet::ParseExcel::Simple - A simple interface to Excel data

=head1 SYNOPSIS

  my $xls = Spreadsheet::ParseExcel::Simple->read('spreadsheet.xls');
  foreach my $sheet ($xls->sheets) {
     while ($sheet->has_data) {  
         my @data = $sheet->next_row;
     }
  }

=head1 DESCRIPTION

This provides an abstraction to the Spreadsheet::ParseExcel module for
simple reading of values.

You simply loop over the sheets, and fetch rows to arrays.

For anything more complex, you probably want to use
Spreadsheet::ParseExcel directly.

=head1 BOOK METHODS

=head2 read

  my $xls = Spreadsheet::ParseExcel::Simple->read('spreadsheet.xls');

This opens the spreadsheet specified for you. Returns undef if we cannot
read the book.

=head2 sheets

  @sheets = $xls->sheets;

Each spreadsheet can contain one or more worksheets. This fetches them
all back. You can then iterate over them, or jump straight to the one
you wish to play with.

=head2 book

	my $book = $xls->book;

The Spreadsheet::ParseExcel object we are working with. You can use this
if you need to manipulate it in ways that this interface doesn't allow.

=head1 SHEET METHODS

These methods can be called on each sheet returned from $xls->sheets:

=head2 has_data

  if ($sheet->has_data) { ... }

This lets us know if there are more rows in this sheet that we haven't
read yet. This allows us to differentiate between an empty row, and 
the end of the sheet.

=head2 next_row

  my @data = $sheet->next_row;

Fetch the next row of data back.

=head2 sheet

	my $obj = $sheet->sheet;

The underlying Spreadsheet::ParseExcel object for the worksheet. You can
use this if you need to manipulate it in ways that this interface
doesn't allow (e.g. asking it for the sheet's name).

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Spreadsheet-ParseExcel-Simple@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2001-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Spreadsheet::ParseExcel>. 

=cut

sub read {
  my $class = shift;
  my $book = Spreadsheet::ParseExcel->new->Parse(shift) or return;
  bless { book => $book }, $class;
}

sub book { shift->{book} }

sub sheets {
  map Spreadsheet::ParseExcel::Simple::_Sheet->new($_), 
   @{shift->{book}->{Worksheet}};
}

package Spreadsheet::ParseExcel::Simple::_Sheet;

sub new {
  my $class = shift;
  my $sheet = shift;
  bless {
    sheet => $sheet,
    row   => $sheet->{MinRow} || 0,
  }, $class;
}

sub sheet { shift->{sheet} }

sub has_data { 
  my $self = shift;
  defined $self->{sheet}->{MaxRow} and ($self->{row} <= $self->{sheet}->{MaxRow});
}

sub next_row {
  map { $_ ? $_->Value : "" } @{$_[0]->{sheet}->{Cells}[$_[0]->{row}++]};
}

1;

