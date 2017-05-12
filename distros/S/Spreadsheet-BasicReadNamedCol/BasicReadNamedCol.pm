#
#  BasicReadNamedCol.pm
#
#  Synopsis:        see POD at end of file
#  Description:     see POD at end of file
#
#--------------------------------------------------

package Spreadsheet::BasicReadNamedCol;

our $VERSION = sprintf("%d.%02d", q'$Revision: 1.3 $' =~ /(\d+)\.(\d+)/);

#--------------------------------------------------
#
#

#-- Linage
#---------
our @ISA = ( 'Spreadsheet::BasicRead' );


#-- Required Modules
#-------------------
use strict;
use warnings;
use Spreadsheet::BasicRead;


sub new
{
    my $self = shift;
    $self = $self->SUPER::new(@_);

    # Process any arguments specific to this package
    my %args = @_ if (@_ > 1);

    if (defined $args{columns})
    {
        unless (ref($args{columns}) eq 'ARRAY')
        {
            $self->logexp("Expected the argument to 'columns' to be an ARRAY reference! BYE\n");
        }

        $self->{columns} = $args{columns};
    }

    if (defined $args{skipHeadings})
    {
        $self->{skipHeadings} = $args{skipHeadings};
    }

    # By default, data has not been ordered
    $self->{isOrdered}  = 0;

    return $self;
}



sub setColumns
{
    my $self = shift;
    my @cols = @_;

    if (ref($cols[0]) eq 'ARRAY')
    {
        $self->{columns} = $cols[0];
    }
    else
    {
        $self->{columns} = \@cols;
    }
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

    # Do we have the columns defined?
    unless (defined $self->{columns})
    {
        $self->logexp("Need to define the name of the columns before calling getFirstRow\nDefine the column names either in the call to new() or using setColumns()\n");
    }

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

    # Check if this row is blank, if it is keep getting rows until we have some data
    if ($blank == 0)
    {
        my $currentBlankSetting = $self->{skipBlankRows};
        $self->{skipBlankRows} = 1;
        my $res = $self->getNextRow();
        $self->{skipBlankRows} = $currentBlankSetting;
        @data = @$res;
    }

    # Determine the correct order to return the rows
    my @order;
    foreach my $name (@{$self->{columns}})
    {
        next unless (defined($name) && $name ne ''); # Skip this column

        my $colNum = 0;
        my $found  = 0;
        foreach my $realColName (@data)
        {
            if ($realColName =~ /^\Q$name/i)
            {
                push @order, $colNum;
                $found = 1;
                last;
            }

            $colNum++;
        }

        # Quit if we can't find a column name
        unless ($found)
        {
            $self->logexp("Could not find column '$name' on sheet '", $self->currentSheetName(), "', Quitting\n");
            return undef;
        }
    }

    # Store the order
    $self->{colOrder} = \@order;

    return $self->{skipHeadings} ? $self->getNextRow() : $self->returnOrdered(\@data);
}



sub getNextRow
{
    my $self = shift;

    $self->{isOrdered}  = 0;
    my $data = $self->SUPER::getNextRow();

    return $self->returnOrdered($data);
}



sub returnOrdered
{
    my ($self, $data) = @_;

    return $data if ($self->{isOrdered} || !defined($data));

    my @ordered;

    foreach my $col (@{$self->{colOrder}})
    {
        push @ordered, $data->[$col];
    }

    $self->{isOrdered} = 1;
    return \@ordered;
}



#####################################################################
# DO NOT REMOVE THE FOLLOWING LINE, IT IS NEEDED TO LOAD THIS LIBRARY
1;


=head1 NAME

Spreadsheet::BasicReadNamedCol - Methods to easily read data from spreadsheets with columns in the order you want based on the names of the column headings


=head1 DESCRIPTION

Provides methods for simple reading of a Excel spreadsheet, where the columns
are returned in the order defined.

Assumes a specific format of the spreadsheet where the first row of
data defined the names of the columns.


=head1 SYNOPSIS

 use Spreadsheet::BasicReadNamedCol;

 my $xlsFileName = 'Excel Price Sheet 021203.xls';
 my @columnHeadings = (
    'Supplier Part Number',
    'Customer Price',
    'Currency Code',
    'Price UOM',
    'Short Description',
    'Long Description',
 );

 my $ss = new Spreadsheet::BasicReadNamedCol($xlsFileName) ||
    die "Could not open '$xlsFileName': $!";
 $ss->setColumns(@columnHeadings);

 # Print each row of the spreadsheet in the order defined in
 # the columnHeadings array
 my $row = 0;
 while (my $data = $ss->getNextRow())
 {
    $row++;
    print join('|', $row, @$data), "\n";
 }


=head1 REQUIRED MODULES

The following modules are required:

 Spreadsheet::BasicRead
 Spreadsheet::ParseExcel


=head1 METHODS

There are no class methods, the object methods are described below.
Private class method start with the underscore character '_' and
should be treated as I<Private>.


=head2 new

Called to create a new BasicReadNamedCol object.  The arguments can
be either a single string (see L<'SYNOPSIS'|"SYNOPSIS">)
which is taken as the filename of the spreadsheet of as named arguments.

 eg.  my $ss = Spreadsheet::BasicReadNamedCol->new(
                  columns       => \@columnNames,
                  fileName      => 'MyExcelSpreadSheet.xls',
                  skipHeadings  => 1,
                  skipBlankRows => 1,
                  log           => $log,
                  );

The following named arguments are available:

=over 4

=item columns

Value expected to be an array reference to a list of column
names that appear in the first line of the spreadsheet.  The
order of the column names defines the order in which the data
is returned by the L<'getNextRow'|"getNextRow"> method.

This is really useful where spreadsheet files from sources out
of your control are not consistant in the ordering of columns.

Note that the match on column name uses the following pattern match:

 if ($realColName =~ /^\Q$name/i)

 where:
   realColName - is the actual column name in the spreadsheet and
   name        - is the pattern to match


=item skipHeadings

Don't output the headings line in the first call to
L<'getNextRow'|"getNextRow"> if true.


=item skipBlankRows

Skip blank lines in the spreadsheet if true.


=item setColumns(array or array_ref)

Sets the order that columns will be returned in based on the
names in the array provided.  The names are expected to match
the values in the first row of the spreadsheet.

=item log

Use the File::Log object to log exceptions.


=item fileName

The name (and optionally path) of the spreadsheet file to process.

=back

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
column headings  L<'skipHeadings'|"new">) as an array reference.


=head2 setHeadingRow(rowNumber)

Sets the effective minimum row for the spreadsheet to 'rowNumber', since it
is assumed that the heading is on this row and anything above the heading is
not relavent.

B<Note:> the row (and column) numbers are zero indexed.


=head2 logexp(message)

Logs an exception message (can be a list of strings) using the File::Log
object if it was defined and then calls die message.


=head2 logmsg(debug, message)

If a File::Log object was passed as a named argument L<'new'|"new">) and
if 'debug' (integer value) is equal to or greater than the current debug
Level (see File::Log) then the message is added to the log file.

If a File::Log object was not passed to new then the message is output to
STDERR.


=head1 KNOWN ISSUES

None

=head1 SEE ALSO

Spreadsheet::BasicRead

=head1 AUTHOR

 Greg George, IT Technology Solutions P/L, Australia
 Mobile: 0404-892-159, Email: gng@cpan.org

=head1 LICENSE

Copyright (c) 1999- Greg George. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 CVS ID

$Id: BasicReadNamedCol.pm,v 1.3 2006/04/30 05:57:29 Greg Exp $


=head1 UPDATE HISTORY

$Log: BasicReadNamedCol.pm,v $
Revision 1.3  2006/04/30 05:57:29  Greg
- removed tabs from file

Revision 1.2  2006/03/07 10:03:26  Greg
- minor pod changes

Revision 1.1  2006/03/05 03:07:58  Greg
- initial CPAN upload


Revision 1.0  2003/12/02 23:58:34  gxg6
- Initial development, need POD

=cut


#---< End of File >---#