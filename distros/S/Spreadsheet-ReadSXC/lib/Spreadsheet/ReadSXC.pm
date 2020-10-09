package Spreadsheet::ReadSXC;

use 5.006;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(read_sxc read_sxc_fh read_xml_file read_xml_string);
our $VERSION = '0.32';

use Archive::Zip ':ERROR_CODES';
use Carp qw(croak);
use Spreadsheet::ParseODS;
use PerlX::Maybe;

our @CARP_NOT = qw(Spreadsheet::ParseODS);

sub zip_error_handler {}

sub read_sxc ($;$) {
    my ($sxc_file, $options_ref) = @_;
    #if( !$options_ref->{StrictErrors}) {
    #    -f $sxc_file && -s _ or return undef;
    #};
    #open my $fh, '<', $sxc_file
    #    or croak "Couldn't open '$sxc_file': $!";
    #read_sxc_fh( $fh, $options_ref );
    _parse_xml( {}, $options_ref, $sxc_file );
}

sub read_sxc_fh {
    my( $stream, $options_ref ) = @_;
    _parse_xml( {},  $options_ref, $stream );
}

sub read_xml_file ($;$) {
    my ($xml_file, $options_ref) = @_;
    if( !$options_ref->{StrictErrors}) {
        -f $xml_file && -s _ or return undef;
    };
    _parse_xml({ method => 'parsefile', type => 'xml' }, $options_ref, $xml_file);
}

sub read_xml_string ($;$) {
    my ($xml_string, $options_ref) = @_;
    _parse_xml( { type => 'xml' }, $options_ref, \$xml_string );
}

sub _parse_xml {
    my ($internal_options, $options_ref, $xml_thing) = @_;

    $options_ref ||= {};

    my $type;
    if( $internal_options->{ type } ) {
        $type = $internal_options->{ type };
    };

    my $line_sep = $options_ref->{ReplaceNewlineWith} || "";

    my $workbook;
    my $ok = eval {
        $workbook = Spreadsheet::ParseODS->new(
                       line_separator => $line_sep,
                        #%$options_ref,
                    )->parse( $xml_thing,
                              maybe inputtype => $type );
        1;
   };
   if( my $err = $@ and $options_ref->{ StrictErrors } ) {
       die "$@\n"
   };
   return unless $workbook;

    # Cut off trailing columns if any
    # Down-convert from ::Cell to raw values, depending on the options

    # This conversion is likely best done in an immediate callback to
    # speed up things
    my $res = {};
    for my $s ($workbook->worksheets) {
        my $rs = $res->{ $s->label } = [];
        for my $r ($s->row_min..$s->row_max) {
            if( $options_ref->{DropHiddenRows} and $s->is_row_hidden( $r ) ) {
                next;
            };

            my $rowref;
            for my $c ($s->col_min..$s->col_max) {
                # Depending on what type we want, use ->value or ->unformatted
                # depending on $options_ref->{ ... }
                if( ! $rowref ) {
                    push @$rs, ($rowref = []);
                };

                my $cell = $s->get_cell( $r,$c );
                if( $options_ref->{DropHiddenColumns} and $s->is_col_hidden($c)) {
                    next;
                };

                my ($method,$type) = ('value',$cell->type);
                $type ||= '';

                if( $options_ref->{StandardCurrency} and $type =~ qr/^(float|currency|percentage)/) {
                    $method = 'unformatted';
                };
                if( $options_ref->{StandardDate} and $type =~ qr/^(date)/) {
                    $method = 'unformatted';
                };
                if( $options_ref->{StandardTime} and $type =~ qr/^(time)/) {
                    $method = 'unformatted';
                };

                push @$rowref, $s->get_cell( $r,$c )->$method;
            }
        }
    };

    if ( $options_ref->{OrderBySheet} ) {
        return [ map { $res->{ $_ } } $workbook->worksheets ]
    } else {
        return $res
    }
}

1;

__END__
=head1 NAME

Spreadsheet::ReadSXC - Extract OpenOffice 1.x spreadsheet data

=head1 NOTICE

This is a legacy API wrapper. Most likely you want to look at
L<Spreadsheet::ParseODS>, which implements an API more compatible with
L<Spreadsheet::ParseXLSX>. That module is also the backend for this API.

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
    ReplaceNewlineWith  => "",
    IncludeCoveredCells => 0,
    DropHiddenRows      => 0,
    DropHiddenColumns   => 0,
    NoTruncate          => 0,
    StandardCurrency    => 0,
    StandardDate        => 0,
    StandardTime        => 0,
    OrderBySheet        => 0,
    StrictErrors        => 0,
  );
  my $workbook_ref = read_sxc("/path/to/file.sxc", \%options );


  # Iterate over every worksheet, row, and cell:

  use Encode 'decode';

  foreach ( sort keys %$workbook_ref ) {
     print "Worksheet ", $_, " contains ", $#{$$workbook_ref{$_}} + 1, " row(s):\n";
     foreach ( @{$$workbook_ref{$_}} ) {
        foreach ( map { defined $_ ? $_ : '' } @{$_} ) {
          my $str = decode('UTF-8', $_);
          print " '$str'";
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

Spreadsheet::ReadSXC uses XML::Twig to parse the XML
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

=item StrictErrors

Turn on error reporting by using C<croak>. Otherwise, functions silently
return C<undef> when errors are encountered.

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


=item StandardCurrency

By default, cells are returned as formatted. If you prefer to
obtain the value as contained in the table:value attribute,
use the following key/value pair in your hash of options:

  StandardCurrency => 1


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

=head1 FUNCTIONS

=head2 read_sxc

  my $workbook_ref = read_sxc("/path/to/file.sxc");

Reads an SXC or ODS file given a filename and returns the worksheets as a
data structure.

=head2 read_sxc_fh

    open my $fh = 'example.ods';
    my $sheet = read_sxc_fh( $fh );

Reads an SXC or ODS file given a filehandle and returns the worksheets as a
data structure.

=head2 read_xml_file

  my $workbook_ref = read_xml_file("/path/to/content.xml");

Reads an XML file from a SXC or ODS file returns the worksheets as a
data structure.

=head2 read_xml_string

Parses an XML string and eturns the worksheets as a data structure.

=head1 Reading an SXC file from an URL

    use HTTP::Tiny;
    use Spreadsheet::Read;

    # Fetch data and return a filehandle to that data
    sub fetch_url {
        my( $url ) = @_;
        my $ua = HTTP::Tiny->new;
        my $res = $ua->get( $url );
        open my $fh, '<', \$res->{content};
        return $fh
    }
    my $fh = fetch_url('http://example.com/example.ods');
    my $sheet = read_sxc_fh( $fh );

=head1 SEE ALSO

L<https://www.openoffice.org/xml/general.html> has extensive documentation
of the OpenOffice 1.x XML file format (soon to be replaced by the
OASIS file format (ODS), see L<http://docs.oasis-open.org/office/v1.2/OpenDocument-v1.2.pdf>).

=head1 AUTHOR

Christoph Terhechte, E<lt>terhechte@cpan.orgE<gt>

=head1 MAINTAINER

Max Maischein, L<mailto:corion@cpan.org>


=head1 COPYRIGHT AND LICENSE


Copyright 2005-2019 by Christoph Terhechte
Copyright 2019- by Max Maischein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
