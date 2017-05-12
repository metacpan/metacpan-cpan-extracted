package Spreadsheet::ReadSXC;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(read_sxc read_xml_file read_xml_string);
our $VERSION = '0.20';

use Archive::Zip;
use XML::Parser;

my %workbook = ();
my @worksheets = ();
my @sheet_order = ();
my $table = "";
my $row = -1;
my $col = -1;
my $text_p = -1;
my @cell = ();
my $repeat_cells = 1;
my $repeat_rows = 1;
my $row_hidden = 0;
my $date_value = '';
my $time_value = '';
my $max_datarow = -1;
my $max_datacol = -1;
my $col_count = -1;
my @hidden_cols = ();
my %options = ();

sub zip_error_handler {}

sub read_sxc ($;$) {
	my ($sxc_file, $options_ref) = @_;
	-f $sxc_file && -s _ or return undef;
	Archive::Zip::setErrorHandler(\&zip_error_handler);
	eval {
		my $zip = Archive::Zip->new($sxc_file);
		my $xml_string = $zip->contents('content.xml');
		return read_xml_string($xml_string, $options_ref);
	};
}

sub read_xml_file ($;$) {
	my ($xml_file, $options_ref) = @_;
	-f $xml_file && -s _ or return undef;
	local $/;
	open CONTENT, "<$xml_file" or die "$xml_file: $!\n";
	my $xml_string = <CONTENT>;
	close CONTENT;
	return read_xml_string($xml_string, $options_ref);
}

sub read_xml_string ($;$) {
	my ($xml_string, $options_ref) = @_;
	%workbook = ();
	@worksheets = ();
	if ( defined $options_ref ) { %options = %{$options_ref}}
	eval {
		my $p = XML::Parser->new(Handlers => {Start => \&handle_start,
						      End => \&handle_end,
						      Char => \&char_start});
		$p->parse($xml_string);
	};
	if ( $options{OrderBySheet} ) { return [@worksheets] } else { return {%workbook} }
}

sub handle_start {
	my ($expat, $element, %attributes) = @_;
	if ( $element eq "text:p" ) {
# increase paragraph count if not part of an annotation
		if ( ! $expat->within_element('office:annotation') ) { $text_p++ }
	}
	elsif ( ( $element eq "table:table-cell" ) or ( $element eq "table:covered-table-cell" ) ) {
# increase cell count
		$col++;
# if number-columns-repeated is set, set $repeat_cells value accordingly for later use
		if ( exists $attributes{'table:number-columns-repeated'} ) {
			$repeat_cells = $attributes{'table:number-columns-repeated'};
		}
# if cell contains date or time values, set boolean variable for later use
		if (exists $attributes{'table:date-value'} ) {
			$date_value = $attributes{'table:date-value'};
		}
		elsif (exists $attributes{'table:time-value'} ) {
			$time_value = $attributes{'table:time-value'};
		}
	}
	elsif ( $element eq "table:table-row" ) {
# increase row count
		$row++;
# if row is hidden, set $row_hidden for later use
		if ( exists $attributes{'table:visibility'} ) { $row_hidden = 1 } else { $row_hidden = 0 }
# if number-rows-repeated is set, set $repeat_rows value accordingly for later use
		if ( exists $attributes{'table:number-rows-repeated'} ) {
			$repeat_rows = $attributes{'table:number-rows-repeated'};
		}
	}
	elsif ( $element eq "table:table-column" ) {
# increase column count
		$col_count++;
# if columns is hidden, add column number to @hidden_cols array for later use
		if ( exists $attributes{'table:visibility'} ) {
			push @hidden_cols, $col_count;
		}
# if number-columns-repeated is set and column is hidden, add affected columns to @hidden_cols
		if ( exists $attributes{'table:number-columns-repeated'} ) {
			$col_count++;
			if ( exists $attributes{'table:visibility'} ) {
				for (2..$attributes{'table:number-columns-repeated'}) {
					push @hidden_cols, $hidden_cols[$#hidden_cols] + 1;
				}
			}
		}
	}
	elsif ( $element eq "table:table" ) {
# get name of current table
		$table = $attributes{'table:name'};
	}
}

sub handle_end {
	my ($expat, $element) = @_;
	if ( $element eq "table:table") {
# decrease $max_datacol if hidden columns within range
		if ( ( ! $options{NoTruncate} ) and ( $options{DropHiddenColumns} ) ) {
			for ( 1..scalar grep { $_ <= $max_datacol } @hidden_cols ) {
				$max_datacol--;
			}
		}
# truncate table to $max_datarow and $max_datacol
		if ( ! $options{NoTruncate} ) {
			$#{$workbook{$table}} = $max_datarow;
			foreach ( @{$workbook{$table}} ) {
				$#{$_} = $max_datacol;
			}
		}
# set up alternative data structure
		if ( $options{OrderBySheet} ) {
			push @worksheets, (
				{
					label	=> $table,
					data	=> \@{$workbook{$table}},
				}
			);
		}
# reset table, column, and row values to default for next table
		$row = -1;
		$max_datarow = -1;
		$max_datacol = -1;
		$table = "";
		$col_count = -1;
		@hidden_cols = ();
	}
	elsif ( $element eq "table:table-row" ) {
# drop hidden columns from current row
		if ( $options{DropHiddenColumns} ) {
			foreach ( reverse @hidden_cols ) {
				splice @{$workbook{$table}[$row]}, $_, 1;
			}
		}
# drop current row, if hidden
		if ( ( $options{DropHiddenRows} ) and ( $row_hidden == 1 ) ) {
			pop @{$workbook{$table}};
			$row--;
		}
# repeat current row, if necessary
		else {
			for (2..$repeat_rows) {
				$row++;
				$workbook{$table}[$row] = $workbook{$table}[$row - 1]	# copy reference, not data
			}
# set max_datarow, if row not empty
			if ( grep { defined $_ } @{$workbook{$table}[$row]} ) {
				$max_datarow = $row;
			}
		}
# reset row and col values to default for next row
		$repeat_rows = 1;
		$col = -1;
	}
	elsif ( ( $element eq "table:table-cell" ) or ( $element eq "table:covered-table-cell" ) ) {
# assign date or time value to current workbook cell if requested
		if ( ( $options{StandardDate} ) and ( $date_value ) ) {
			$workbook{$table}[$row][$col] = $date_value;
			$date_value = '';
		}
		elsif ( ( $options{StandardTime} ) and ( $time_value ) ) {
			$workbook{$table}[$row][$col] = $time_value;
			$time_value = '';
		}
# join cell contents and assign to current workbook cell
		else {
			$workbook{$table}[$row][$col] = @cell ? join $options{ReplaceNewlineWith} || "", @cell : undef;
		}
# repeat current cell, if necessary
		for (2..$repeat_cells) {
			$col++;
			$workbook{$table}[$row][$col] = $workbook{$table}[$row][$col - 1];
		}
# reset cell and paragraph values to default for next cell
		@cell = ();
		$repeat_cells = 1;
		$text_p = -1;
	}
}

sub char_start {
	my ($expat, $content) = @_;
# don't include paragraph if part of an annotation
	if ( $expat->within_element('office:annotation') ) {
		return;
	}
# don't include covered cells, if not requested
	if ( ( $expat->within_element('table:covered-table-cell') ) and ( ! $options{IncludeCoveredCells} ) ) {
		return;
	}
# add paragraph or textspan to current @cell array
	if ( $table ) {
		$cell[$text_p] .= $content;
# set $max_datarow and $max_datacol to current values
		$max_datarow = $row;
		if ( $col > $max_datacol ) { $max_datacol = $col }
	}
}

1;
__END__
=head1 NAME

Spreadsheet::ReadSXC - Extract OpenOffice 1.x spreadsheet data


=head1 SYNOPSIS


  use Spreadsheet::ReadSXC qw(read_sxc);
  my $workbook_ref = read_sxc("/path/to/file.sxc");


  # Alternatively, unpack the .sxc file yourself and pass content.xml

  use Spreadsheet::ReadSXC qw(read_xml_file);
  my $workbook_ref = read_xml_file("/path/to/content.xml");


  # Alternatively, pass the XML string directly

  use Spreadsheet::ReadSXC qw(read_xml_string);
  use Archive::Zip;
  my $zip = Archive::Zip->new("/path/to/file.sxc");
  my $content = $zip->contents('content.xml');
  my $workbook_ref = read_xml_string($content);


  # Control the output through a hash of options (below are the defaults):

  my %options = (
	ReplaceNewlineWith	=> "",
	IncludeCoveredCells	=> 0,
	DropHiddenRows		=> 0,
	DropHiddenColumns	=> 0,
	NoTruncate		=> 0,
	StandardDate		=> 0,
	StandardTime		=> 0,
	OrderBySheet		=> 0,
  );
  my $workbook_ref = read_sxc("/path/to/file.sxc", \%options );


  # Iterate over every worksheet, row, and cell:

  use Unicode::String qw(utf8);

  foreach ( sort keys %$workbook_ref ) {
     print "Worksheet ", $_, " contains ", $#{$$workbook_ref{$_}} + 1, " row(s):\n";
     foreach ( @{$$workbook_ref{$_}} ) {
        foreach ( map { defined $_ ? $_ : '' } @{$_} ) {
	   print utf8(" '$_'")->as_string;
        }
        print "\n";
     }
  }


  # Cell D2 of worksheet "Sheet1"

  $cell = $$workbook_ref{"Sheet1"}[1][3];


  # Row 1 of worksheet "Sheet1":

  @row = @{$$workbook_ref{"Sheet1"}[0]};


  # Worksheet "Sheet1":

  @sheet = @{$$workbook_ref{"Sheet1"}};



=head1 DESCRIPTION


Spreadsheet::ReadSXC extracts data from OpenOffice 1.x spreadsheet
files (.sxc). It exports the function read_sxc() which takes a
filename and an optional reference to a hash of options as
arguments and returns a reference to a hash of references to
two-dimensional arrays. The hash keys correspond to the names of
worksheets in the OpenOffice workbook. The two-dimensional arrays
correspond to rows and cells in the respective spreadsheets. If
you don't like this because the order of sheets is not preserved
in a hash, read on. The 'OrderBySheet' option provides an array
of hashes instead.

If you prefer to unpack the .sxc file yourself, you can use the
function read_xml_file() instead and pass the path to content.xml
as an argument. Or you can extract the XML string from content.xml
and pass the string to the function read_xml_string(). Both
functions also take a reference to a hash of options as an
optional second argument.

Spreadsheet::ReadSXC requires XML::Parser to parse the XML
contained in .sxc files. Only the contents of text:p elements are
returned, not the actual values of table:value attributes. For
example, a cell might have a table:value-type attribute of
"currency", a table:value attribute of "-1500.99" and a
table:currency attribute of "USD". The text:p element would
contain "-$1,500.99". This is the string which is returned by the
read_sxc() function, not the value of -1500.99.

Spreadsheet::ReadSXC was written with data import into an SQL
database in mind. Therefore empty spreadsheet cells correspond to
undef values in array rows. The example code above shows how to
replace undef values with empty strings.

If the .sxc file contains an empty spreadsheet its hash element will
point to an empty array (unless you use the 'NoTruncate' option in
which case it will point to an array of an array containing one
undefined element).

OpenOffice uses UTF-8 encoding. It depends on your environment how
the data returned by the XML Parser is best handled:

  use Unicode::String qw(latin1 utf8);
  $unicode_string = utf8($$workbook_ref{"Sheet1"}[0][0])->as_string;

  # this will not work for characters outside ISO-8859-1:

  $latin1_string = utf8($$workbook_ref{"Sheet1"}[0][0])->latin1;

Of course there are other modules than Unicode::String on CPAN that
handle conversion between encodings. It's your choice.

Table rows in .sxc files may have a "table:number-rows-repeated"
attribute, which is often used for consecutive empty rows. When you
format whole rows and/or columns in OpenOffice, it sets the numbers
of rows in a worksheet to 32,000 and the number of columns to 256, even
if only a few lower-numbered rows and cells actually contain data.
Spreadsheet::ReadSXC truncates such sheets so that there are no empty
rows after the last row containing data and no empty columns after the
last column containing data (unless you use the 'NoTruncate' option).

Still it is perfectly legal for an .sxc file to apply the
"table:number-rows-repeated" attribute to rows that actually contain
data (although I have only been able to produce such files manually,
not through OpenOffice itself). To save on memory usage in these cases,
Spreadsheet::ReadSXC does not copy rows by value, but by reference
(remember that multi-dimensional arrays in Perl are really arrays of
references to arrays). Therefore, if you change a value in one row, it
is possible that you find the corresponding value in the next row
changed, too:

  $$workbook_ref{"Sheet1"}[0][0] = 'new string';
  print $$workbook_ref{"Sheet1"}[1][0];

As of version 0.20 the references returned by read_sxc() et al. remain
valid after subsequent calls to the same function. In earlier versions,
calling read_sxc() with a different file as the argument would change
the data referenced by the original return value, so you had to
derefence it before making another call. Thanks to H. Merijn Brand for
fixing this.


=head1 OPTIONS

=over 4

=item ReplaceNewlineWith

By default, newlines within cells are ignored and all lines in a cell
are concatenated to a single string which does not contain a newline. To
keep the newline characters, use the following key/value pair in your
hash of options: 

  ReplaceNewlineWith => "\n"

However, you may replace newlines with any string you like.


=item IncludeCoveredCells

By default, the content of cells that are covered by other cells is
ignored because you wouldn't see it in OpenOffice unless you unmerge
the merged cells. To include covered cells in the data structure which
is returned by parse_sxc(), use the following key/value pair in your
hash of options:

  IncludeCoveredCells => 1


=item DropHiddenRows

By default, hidden rows are included in the data structure returned by
parse_sxc(). To drop those rows, use the following key/value pair in
your hash of options:

  DropHiddenRows => 1


=item DropHiddenColumns

By default, hidden columns are included in the data structure returned
by parse_sxc(). To drop those rows, use the following key/value pair
in your hash of options:

  DropHiddenColumns => 1


=item NoTruncate

By default, the two-dimensional arrays that contain the data within
each worksheet are truncated to get rid of empty rows below the last
row containing data and empty columns beyond the last column
containing data. If you prefer to keep those rows and columns, use the
following key/value pair in your hash of options:

  NoTruncate => 1


=item StandardDate

By default, date cells are returned as formatted. If you prefer to
obtain the date value as contained in the table:date-value attribute,
use the following key/value pair in your hash of options:

  StandardDate => 1


=item StandardTime

By default, time cells are returned as formatted. If you prefer to
obtain the time value as contained in the table:time-value attribute,
use the following key/value pair in your hash of options:

  StandardTime => 1

These options are a first step on the way to a different approach at
reading data from .sxc files. There should be more options to read in
values instead of the strings OpenOffice displays. It should give
more flexibility in working with the data obtained from OpenOffice
spreadsheets. 'float' and 'percentage' values could be next.
'currency' is less obvious, though, as we need to consider both its
value and the 'table:currency' attribute. Formulas and array formulas
are yet another issue. I probably won't deal with this until I've
given this module an object-oriented interface.


=item OrderBySheet

The disadvantage of storing worksheets by name in a hash is that the
order of sheets is lost. If you prefer not to obtain such a hash, but
an array of worksheets insted, use the following key/value pair in
your hash of options:

  OrderBySheet => 1

Thus the read_sxc function will return an array of hashes, each of
which will have two keys, "label" and "data". The value of "label"
is the name of the sheet. The value of data is a reference to a
two-dimensional array containing rows and columns of the worksheet:

  my $worksheets_ref = read_sxc("/path/to/file.sxc");
  my $name_of_first_sheet = $$worksheets_ref[0]{label};
  my $first_cell_of_first_sheet = $$worksheets_ref[0]{data}[0][0];


=back



=head1 SEE ALSO


http://books.evc-cit.info/oobook/book.html has extensive documentation
of the OpenOffice 1.x XML file format (soon to be replaced by the
OASIS file format, see http://books.evc-cit.info/odbook/book.html).



=head1 AUTHOR


Christoph Terhechte, E<lt>terhechte@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE


Copyright 2005 by Christoph Terhechte

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
