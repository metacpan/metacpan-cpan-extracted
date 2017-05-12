#
#  Spreadsheet::BasicRead.pm
#
#  Synopsis: see POD at end of file
#
#-- The package
#--------------------------------------------------
package Spreadsheet::BasicRead;

$VERSION = '1.12';
#--------------------------------------------------
#

#-- Required Modules
#-------------------
use strict;
use warnings;
use Spreadsheet::ParseExcel;
use Spreadsheet::XLSX;


#-- Linage
#---------
our @ISA = qw( Spreadsheet::ParseExcel );


sub new
{
    my $proto  = shift;
    my $class  = ref($proto) || $proto;

    my $self = {};
    bless($self, $class);

    $self->{skipBlankRows} = 0;
    $self->{oldCell}       = 0;

    # Do we have any arguments to process
    #------------------------------------

    # Is there just one argument?  If so treat as filename, otherwise assume named arguments
    if (@_ == 1)
    {
        $self->{fileName} = $_[0];
        $self->openSpreadsheet($self->{fileName});

        return $self;
    }



    # If we get to here then we assume named arguments to process
    my %args = @_;

    # Is there a log object
    if (defined($args{log}) && $args{log} ne '')
    {
        $self->{log} = $args{log};
    }

    # Do we skip blank rows
    if (defined($args{skipBlankRows}))
    {
        $self->{skipBlankRows} = $args{skipBlankRows} ? 1 : 0;
    }

    # Is there a file to open
    if (defined($args{fileName}) && $args{fileName} ne '')
    {
        $self->{fileName} = $args{fileName};
        $self->openSpreadsheet($args{fileName});
    }

    # Skip headings (if defined) else skip the first row
    if (defined $args{skipHeadings})
    {
        $self->{skipHeadings} = $args{skipHeadings};
    }

    # Do we return undef on empty cells (old mode) or ''
    $self->{oldCell} = $args{oldCell} if $args{oldCell};

    return $self;
}


sub openSpreadsheet
{
    my ($self, $ssFileName) = @_;

    #-- Open the Excel spreadsheet and process
    my $ssExcel;
    my $ssBook;
    if ($ssFileName =~ /\.xls[xm]$/i)
    {
        my $converter = Spreadsheet::XLSX::XLSXConvert->new();
        $ssExcel = Spreadsheet::XLSX->new($ssFileName, $converter);
        $ssBook  = $ssExcel;
    }
    else
    {
        $ssExcel = new Spreadsheet::ParseExcel;
        $ssBook  = $ssExcel->Parse($ssFileName);
    }

    unless ($ssBook)
    {
        $self->logexp("Could not open Excel spreadsheet file '$ssFileName': $!");
    }

    # Store the objects
    $self->{ssExcel} = $ssExcel;
    $self->{ssBook}  = $ssBook;

    # Get the first sheet
    $self->getFirstSheet();

    return ($ssExcel, $ssBook)
}




sub numSheets
{
    my $self = shift;

    return defined($self->{ssBook}) ? $self->{ssBook}->{SheetCount} : undef;
}



sub currentSheetNum
{
    my $self = shift;

    return defined($self->{currentSheetNum}) ? $self->{currentSheetNum} : 0;
}



sub currentSheetName
{
    my $self = shift;

    return defined($self->{ssSheet}) ? $self->{ssSheet}->{Name} : undef;
}



sub setCurrentSheetNum
{
    my $self  = shift;
    my $shtNo = shift || 0;

    # Check if this is a valid value
    return undef unless ($shtNo >= 0 && $shtNo <= $self->numSheets());

    # Set the new sheet number and return the sheet.
    $self->{currentSheetNum} = $shtNo;
    $self->{ssSheet}         = $self->{ssBook}->{Worksheet}[$shtNo];
    $self->{ssSheetRow}      = $self->{ssSheet}->{MinRow} if (defined($self->{ssSheet}));
    $self->{ssSheetCol}      = $self->{ssSheet}->{MinCol} if (defined($self->{ssSheet}));
    $self->{ssSheetRow}      = -7;  # Flag to getNextRow that this is the first row
    return $self->{ssSheet};
}


sub skipHeadings
{
    $_[0]->{skipHeadings} = $_[1] || 0;
}


sub getNextSheet
{
    my $self = shift;

    my $currentSheet = $self->currentSheetNum();

    # No sheet, so get the first sheet
    return $self->getFirstSheet() unless (defined($self->{ssSheet}));

    # Get the next sheet
    if (defined($self->{ssSheet}) && $currentSheet < $self->numSheets())
    {
        $self->setCurrentSheetNum(++$currentSheet);
        $self->{ssSheet}    = $self->{ssBook}->{Worksheet}[$currentSheet];
#       $self->{ssSheetRow} = $self->{ssSheet}->{MinRow} if (defined($self->{ssSheet}));
        $self->{ssSheetRow} = -7;   # So we then find the correct start, setting to min will skip the min row! - Thanks Tim Rossiter
        $self->{ssSheetCol} = $self->{ssSheet}->{MinCol} if (defined($self->{ssSheet}));
        return $self->{ssSheet};
    }

    return undef;
}



sub getFirstSheet
{
    my $self = shift;

    $self->{setCurrentSheetNum} = 0;
    $self->{ssSheet}    = $self->{ssBook}->{Worksheet}[0] if (defined($self->{ssBook}));
    $self->{ssSheetRow} = -7;  # Flag to getNextRow that this is the first row
    $self->{ssSheetCol} = $self->{ssSheet}->{MinCol}      if (defined($self->{ssSheet}));
    return $self->{ssSheet};
}


sub cellValue
{
    my ($self, $r, $c) = @_;
    return ($self->{oldCell}? undef : '') unless (defined($self->{ssSheet}) && defined($self->{ssSheet}->{Cells}[$r][$c]));


    #return $self->{ssSheet}->{Cells}[$r][$c]->Value;
    # V1.8 2006/03/05 Changes to cater for OpenOffice returning 'GENERAL'
    my $cell_value = $self->{ssSheet}->{Cells}[$r][$c]->Value;
    if ( $cell_value eq 'GENERAL' ) {
           $cell_value = $self->{ssSheet}->{Cells}[$r][$c]->{Val};
    }
    return $cell_value;
}



sub setHeadingRow
{
    my $self = shift;
    my $headingRow = shift;

    $self->{headingRow} = ($headingRow >= $self->{ssSheet}->{MinRow} &&
                           $headingRow <= $self->{ssSheet}->{MaxRow}) ?
                           $headingRow : $self->{ssSheet}->{MinRow};
}


sub getFirstRow
{
    my $self = shift;

    return undef unless defined($self->{ssSheet});

    my $row = $self->{headingRow} || $self->{ssSheet}->{MinRow};
    $self->{ssSheetRow} = $row;


    # Loop through each column and put into array
    my $x     = 0;
    my @data  = ();
    my $blank = 0;
    for (my $col = $self->{ssSheet}->{MinCol}; $col <= $self->{ssSheet}->{MaxCol}; $x++, $col++)
    {
        no warnings qw(uninitialized);

        # Note that this is the formatted value of the cell (ie what you see, no the real value)
        $data[$x] = $self->cellValue($row, $col);

        # remove leading and trailing whitespace
        $data[$x] =~ s/^\s+//;
        $data[$x] =~ s/\s+$//;
        $blank++ unless $data[$x] =~ /^$/;
    }


    return ($self->{skipHeadings} || ($self->{skipBlankRows} && $blank == 0)) ? $self->getNextRow() : \@data;
}



sub getNextRow
{
    my $self = shift;

    # Must have a sheet defined
    return undef unless defined($self->{ssSheet});

    # Find the next row and make sure it's valid
    my $row = ++$self->{ssSheetRow};
    # Check to make sure there is something on this sheet
    return undef if (! defined($self->{ssSheet}->{MaxRow}) || $row > $self->{ssSheet}->{MaxRow});

    # If row is zero or negative then this is the first row
    return $self->getFirstRow() if ($row <= 0);


    # Loop through each column and put into array
    my $x     = 0;
    my @data  = ();
    my $blank = 0;
    for (my $col = $self->{ssSheet}->{MinCol}; $col <= $self->{ssSheet}->{MaxCol}; $x++, $col++)
    {
        no warnings qw(uninitialized);

        # Note that this is the formatted value of the cell (ie what you see, no the real value)
        $data[$x] = $self->cellValue($row, $col);

        # remove leading and trailing whitespace
        $data[$x] =~ s/^\s+//;
        $data[$x] =~ s/\s+$//;
        $blank++ unless $data[$x] =~ /^$/;
    }

    return ($self->{skipBlankRows} && $blank == 0) ? $self->getNextRow() : \@data;
}


sub setRow
{
    $_[0]->{ssSheetRow} = ($_[1] || 0) - 1;
}


sub getRowNumber
{
    return $_[0]->{ssSheetRow} || -1;
}


sub logexp
{
    my $self = shift;

    my $msg = join('', @_);
    if (defined $self->{log})
    {
        $self->{log}->exp($msg);
    }

    die $msg;
}



sub logmsg
{
    my $self  = shift;
    my $level = shift;

    my $msg = join('', @_);
    if (defined $self->{log})
    {
        $self->{log}->msg($level, $msg);
    }
    else
    {
        print STDERR $msg;
    }
}

{
    package Spreadsheet::XLSX::XLSXConvert;
    sub new {
        my $module = shift;

        return bless( {  }, $module );
    }
    sub convert {
        my $self = shift;
        my ($raw) = @_;
        utf8::decode($raw);
        #also decode html escapes,
        $raw =~ s/\&amp;/&/g;
        $raw =~ s/\&lt;/\</g;
        $raw =~ s/\&gt;/\>/g;
        return $raw;
    }
}

#####################################################################
# DO NOT REMOVE THE FOLLOWING LINE, IT IS NEEDED TO LOAD THIS LIBRARY
1;

__END__

## POD DOCUMENTATION ##


=head1 NAME

Spreadsheet::BasicRead - Methods to easily read data from spreadsheets (.xls, .xlxs and .xlxm)


=head1 DESCRIPTION

Provides methods for simple reading of a Excel spreadsheet row
at a time returning the row as an array of column values.
Properties can be set so that blank rows are skipped.  The heading
row can also be set so that reading always starts at this row which
is the first row of the sheet by default.
Properties can also be set to skip the heading row.

 Note 1. Leading and trailing white space is removed from cell values.

 Note 2. Row and column references are zero (0) indexed. That is cell
         A1 is row 0, column 0

 Note 3. Now handles .xlxs and .xlsm files

=head1 SYNOPSIS

 use Spreadsheet::BasicRead;

 my $xlsFileName = 'Test.xls';

 my $ss = new Spreadsheet::BasicRead($xlsFileName) ||
    die "Could not open '$xlsFileName': $!";

 # Print the row number and data for each row of the
 # spreadsheet to stdout using '|' as a separator
 my $row = 0;
 while (my $data = $ss->getNextRow())
 {
    $row++;
    print join('|', $row, @$data), "\n";
 }

 # Print the number of sheets
 print "There are ", $ss->numSheets(), " in the spreadsheet\n";

 # Set the heading row to 4
 $ss->setHeadingRow(4);

 # Skip the first data line, it's assumed to be a heading
 $ss->skipHeadings(1);

 # Print the name of the current sheet
 print "Sheet name is ", $ss->currentSheetName(), "\n";

 # Reset back to the first row of the sheet
 $ss->getFirstRow();


=head1 REQUIRED MODULES

The following modules are required:

 Spreadsheet::ParseExcel
 Spreadsheet::XLSX

Optional module File::Log can be used to allow simple logging of errors.


=head1 METHODS

There are no class methods, the object methods are described below.
Private class method start with the underscore character '_' and
should be treated as I<Private>.


=head2 new

Called to create a new BasicReadNamedCol object.  The arguments can
be either a single string (see L<'SYNOPSIS'|"SYNOPSIS">)
which is taken as the filename of the spreadsheet of as named arguments.

 eg.  my $ss = Spreadsheet::BasicReadNamedCol->new(
                  fileName      => 'MyExcelSpreadSheet.xls',
                  skipHeadings  => 1,
                  skipBlankRows => 1,
                  log           => $log,
                  oldCell       => 1,
              );

The following named arguments are available:

=over 4

=item skipHeadings

Don't output the headings line in the first call to
L<'getNextRow'|"getNextRow"> if true.  This is the first row of the
spreadsheet unless the setHeadingRow function has been called to set
the heading row.


=item skipBlankRows

Skip blank lines in the spreadsheet if true.


=item log

Use the File::Log object to log exceptions.
If not provided error conditions are logged to STDERR


=item fileName

The name (and optionally path) of the spreadsheet file to process.


=item oldCell

Empty cells returned undef pre version 1.5.  They now return ''.

The old functionality can be turned on by setting argument I<oldCell> to true

=back

B<Note that new will die if the spreadsheet can not be successfully opened.>
As such you may wish to wrap the call to new in a eval block. See xlsgrep|EXAMPLE APPLICATIONS
for an example of when this might be desirable.

=head2 getNextRow()

Get the next row of data from the spreadsheet.  The data is
returned as an array reference.

 eg.  $rowDataArrayRef = $ss->getNextRow();


=head2 numSheets()

Returns the number of sheets in the spreadsheet


=head2 openSpreadsheet(fileName)

Open a new spreadsheet file and set the current sheet to the first
sheet.  The name and optionally path of the
spreadsheet file is a required argument to this method.


=head2 currentSheetNum()

Returns the current sheet number or undef if there is no current sheet.
L<'setCurrentSheetNum'|"setCurrentSheetNum"> can be called to set the
current sheet.


=head2 currentSheetName()

Return the name of the current sheet or undef if the current sheet is
not defined.  see L<'setCurrentSheetNum'|"setCurrentSheetNum">.


=head2 setCurrentSheetNum(num)

Sets the current sheet to the integer value 'num' passed as the required
argument to this method.  Note that this should not be bigger than
the value returned by L<'numSheets'|"numSheets">.


=head2 getNextSheet()

Returns the next sheet "ssBook" object or undef if there are no more sheets
to process.  If there is no current sheet defined the first sheet
is returned.


=head2 getFirstSheet()

Returns the first sheet "ssBook" object.


=head2 cellValue(row, col)

Returns the value of the cell defined by (row, col)in the current sheet.


=head2 getFirstRow()

Returns the first row of data from the spreadsheet (possibly skipping the
column headings  L<'skipHeadings'|"new"> as an array reference.


=head2 setHeadingRow(rowNumber)

Sets the effective minimum row for the spreadsheet to 'rowNumber', since it
is assumed that the heading is on this row and anything above the heading is
not relavent.

B<Note:> the row (and column) numbers are zero indexed.


=head2 setRow(rowNumber)

Sets the row to be returned by the next call to L<'getNextRow'|"getNextRow">.
Note that if the heading row has been defined and the row number set with setRow
is less than the heading row, data will be returned from the heading row regardless,
unless skip heading row has been set, in which case it will be the row after the
heading row.


=head2 getRowNumber()

Returns the number of the current row (that has been retrieved).  Note that
row numbers are zero indexed.  If a row has not been retrieved as yet, -1 is
returned.


=head2 logexp(message)

Logs an exception message (can be a list of strings) using the File::Log
object if it was defined and then calls die message.


=head2 logmsg(debug, message)

If a File::Log object was passed as a named argument L<'new'|"new"> and
if 'debug' (integer value) is equal to or greater than the current debug
Level (see File::Log) then the message is added to the log file.

If a File::Log object was not passed to new then the message is output to
STDERR.


=head1 EXAMPLE APPLICATIONS

Two sample (but usefull) applications are included with this distribution.

The simplest is dumpSS.pl which will dump the entire contents of a spreadsheet
to STDOUT.  Each sheet is preceeded by the sheet name (enclosed in ***) on
a line, followed by each row of the spreadsheet, with cell values separated by
the pipe '|' character.  There is no special handling provided for cells containing
the pipe character.

A more complete example is xlsgrep.  This application can be used to do a perl
pattern match for cell values within xls files in the current and sub directories.
There are no special grep flags, however this should not be a problem since perl's
pattern matching allows for most requirements within the search pattern.

 Usage is: xlsgrep.pl pattern

To do a case insensative search for "Some value" in any xls file in the current directory
you would use:

 xlsgrep '(?i)Some value'

For further details, see each applications POD.


=head1 ACKNOWLEDGEMENTS

I would like to acknowledge the input and patches recieved from the following:

Ilia Lobsanov, Bryan Maloney, Bill (from Datacraft), nadim and D. Dewey Allen


=head1 KNOWN ISSUES

None, however please contact the author at gng@cpan.org should you
find any problems and I will endevour to resolve then as soon as
possible.

If you have any enhancement suggestions please send me
an email and I will try to accommodate your suggestion.


=head1 SEE ALSO

Spreadsheet:ParseExcel on CPAN does all the hard work, thanks
Kawai Takanori (Hippo2000) kwitknr@cpan.org

The included applications dumpSS.pl and xlsgrep.pl


=head1 AUTHOR

 Greg George, IT Technology Solutions P/L, Australia
 Mobile: +61-404-892-159, Email: gng@cpan.org


=head1 LICENSE

Copyright (c) 1999- Greg George. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.


=head1 VERSION

This is version 1.12


=head1 UPDATE HISTORY

 Revision 1.12  2017/05/01 Greg
 - Added handling of .xlxs & .xlxm files
 - Added utf8 conversion for .xls[x|m] files as well as decoding of html escapes &amp; &lt; and &gt;

 Revision 1.11  2012/04/10 11:08:42  Greg
 - Added handling of .xlxs files

 Revision 1.10  2006/04/30 05:35:13  Greg
 - added getRowNumber()

 Revision 1.9  2006/03/05 02:43:34  Greg
 - Update of Acknowledgments

 Revision 1.8  2006/03/05 02:31:41  Greg
 - Changes to cellValue return to cater for 'GENERAL' value sometimes returned from OpenOffice spreadsheets
   patch provided by Ilia Lobsanov <samogon@gmail.com>
   see http://www.annocpan.org/~KWITKNR/Spreadsheet-ParseExcel-0.2602/ParseExcel.pm#note_18

 Revision 1.7  2006/01/25 22:17:47  Greg
 - Correction to reading of the first row of the next sheet (without calling getFirstRow).
   Error detected and reported by Tim Rossiter
 - Reviewed memory useage as reported by Ilia Lobsanov - this seems to be in the underlying OLE::Storage_Lite

 Revision 1.6  2005/02/21 09:54:08  Greg
 - Update to setCurrentSheetNum() so that the new sheet is handled by BasicRead functions

 Revision 1.5  2004/10/08 22:40:27  Greg
 - Changed cellValue to return '' for an empty cell rather than undef (requested by D D Allen).  Old functionality can be maintained by setting named parameter 'oldCell' to true in call to new().
 - Added examples to POD

 Revision 1.4  2004/10/01 11:02:21  Greg
 - Updated getNextRow to skip sheets that have nothing on them

 Revision 1.3  2004/09/30 12:32:25  Greg
 - Update to currentSheetNum and getNextSheet functions

 Revision 1.2  2004/08/21 02:30:29  Greg
 - Added setHeadingRow and setRow
 - Updated documentation
 - Remove irrelavant use lib;

 Revision 1.1.1.1  2004/07/31 07:45:02  Greg
 - Initial release to CPAN

=cut

#---< End of File >---#