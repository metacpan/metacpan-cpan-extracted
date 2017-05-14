package Spreadsheet::ParseExcel::Assist;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Spreadsheet::ParseExcel;

=head1 NAME

Spreadsheet::ParseExcel::Assist - The great new Spreadsheet::ParseExcel::Assist!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Spreadsheet::ParseExcel::Assist;

    my $foo = Spreadsheet::ParseExcel::Assist->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new()
{
    my $class = shift();
    my $self =
    {
        "filepath" => "",
        "workbook" => undef,
        "worksheet" => undef,
    };

    bless $self, $class;
    return $self;
}

=head2 loadExcel

Load the Excel format file and store workbook.
Set first worksheet as default sheet.

=cut

sub loadExcel
{
    my ($self, $filePath) = @_;
    $self->{"filepath"} = $filePath;
    my $parser   = Spreadsheet::ParseExcel->new();
    my $workbook = $parser->parse($filePath);
    if (!defined($workbook)) 
    {
        return 0;
    }
    
    $self->{"workbook"} = $workbook;    
    for my $worksheet ($workbook->worksheets()) 
    {
        $self->{"worksheet"} = $worksheet;
        last;
    }
    
    return 1;
}

=head2 changeWorksheet

=cut

sub changeWorksheet
{
    my ($self, $sheetName) = @_;
    
    for my $worksheet ($self->{"workbook"}->worksheets()) 
    {
        if ($worksheet->get_name() eq $sheetName)
        {
            $self->{"worksheet"} = $worksheet;
            return 1;
        }
    }
    
    return 0;
}

=head2 getWorksheetCount

=cut

sub getWorksheetCount
{
    my ($self) = @_;
        
    my @worksheets = $self->{"workbook"}->worksheets();
    return ($#worksheets+1);
}

=head2 getWorksheetNameList

=cut

sub getWorksheetNameList
{
    my ($self) = @_;
        
    my @nameList = ();
    for my $worksheet ($self->{"workbook"}->worksheets()) 
    {
        push(@nameList, $worksheet->get_name());
    }
    
    return @nameList;
}

=head2 getCell

=cut

sub getCell
{
    my ($self, $row, $col) = @_;
    my $worksheet = $self->{"worksheet"};

    if ($row < 0 || $col < 0 || !defined($worksheet))
    {
        return undef;
    }
    
    my $cell = $worksheet->get_cell($row, $col);
    return $cell;
}

=head2 readCell

=cut

sub readCell
{
    my ($self, $row, $col) = @_;
    my $worksheet = $self->{"worksheet"};

    if ($row < 0 || $col < 0 || !defined($worksheet))
    {
        return undef;
    }
    
    my $cell = $worksheet->get_cell($row, $col);
    if (!defined($cell))
    {
        return undef;
    }
    else
    {
        return $cell->value();
    }
}

=head2 readWholeRow

=cut

sub readWholeRow
{
    my ($self, $row) = @_;
    my $worksheet = $self->{"worksheet"};
    my @rowData = ();
    if ($row < 0 || !defined($worksheet))
    {
        return @rowData;
    }
    
    for (my $col=0; ; $col++)
    {
        my $cell = $worksheet->get_cell($row, $col);
        if (!defined($cell))
        {
            last;
        }
        push(@rowData, $cell->value());
    }
    
    return @rowData;
}

=head2 readRow

=cut

sub readRow
{
    my ($self, $row, $colBeg, $colEnd) = @_;
    my $worksheet = $self->{"worksheet"};
    my @rowData = ();
    if ($row < 0 || !defined($worksheet))
    {
        return @rowData;
    }
    
    for (my $col=$colBeg; $col <= $colEnd; $col++)
    {
        my $cell = $worksheet->get_cell($row, $col);
        if (!defined($cell))
        {
            push(@rowData, "");
        }
        else
        {
            push(@rowData, $cell->value());
        }        
    }
    
    return @rowData;
}

=head2 readWholeCol

=cut

sub readWholeCol
{
    my ($self, $col) = @_;
    my $worksheet = $self->{"worksheet"};
    my @colData = ();
    if ($col < 0 || !defined($worksheet))
    {
        return @colData;
    }
    
    for (my $row=0; ; $row++)
    {
        my $cell = $worksheet->get_cell($row, $col);
        if (!defined($cell))
        {
            last;
        }
        else
        {
            push(@colData, $cell->value());
        }        
    }
    
    return @colData;
}

=head2 readCol

=cut

sub readCol
{
    my ($self, $col, $rowBeg, $rowEnd) = @_;
    my $worksheet = $self->{"worksheet"};
    my @colData = ();
    if ($col < 0 || $rowBeg>$rowEnd || $rowBeg < 0 || !defined($worksheet))
    {
        return @colData;
    }
    
    for (my $row=$rowBeg; $row <= $rowEnd; $row++)
    {
        my $cell = $worksheet->get_cell($row, $col);
        if (!defined($cell))
        {
            push(@colData, "");
        }
        else
        {
            push(@colData, $cell->value());
        }        
    }
    
    return @colData;
}

=head2 getMinRowIndex

=cut

sub getMinRowIndex
{
    my ($self) = @_;
    my $worksheet = $self->{"worksheet"};
    if (!defined($worksheet))
    {
        return 0;
    }
    
    my ( $row_min, $row_max ) = $worksheet->row_range();
    
    return $row_min;    
}

=head2 getMaxRowIndex

=cut

sub getMaxRowIndex
{
    my ($self) = @_;
    my $worksheet = $self->{"worksheet"};
    if (!defined($worksheet))
    {
        return 0;
    }
    
    my ( $row_min, $row_max ) = $worksheet->row_range();
    
    return $row_max;    
}

=head2 getMinColIndex

=cut

sub getMinColIndex
{
    my ($self) = @_;
    my $worksheet = $self->{"worksheet"};
    if (!defined($worksheet))
    {
        return 0;
    }
    
    my ( $col_min, $col_max ) = $worksheet->col_range();
    
    return $col_min;    
}

=head2 getMaxColIndex

=cut

sub getMaxColIndex
{
    my ($self) = @_;
    my $worksheet = $self->{"worksheet"};
    if (!defined($worksheet))
    {
        return 0;
    }
    
    my ( $col_min, $col_max ) = $worksheet->col_range();
    
    return $col_max;    
}

=head1 AUTHOR

xiangfeng shen, C<< <xiangfeng.shen at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-spreadsheet-parseexcel-assist at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spreadsheet-ParseExcel-Assist>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spreadsheet::ParseExcel::Assist


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spreadsheet-ParseExcel-Assist>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Spreadsheet-ParseExcel-Assist>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spreadsheet-ParseExcel-Assist>

=item * Search CPAN

L<http://search.cpan.org/dist/Spreadsheet-ParseExcel-Assist/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 xiangfeng shen.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (1.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_1_0>

Aggregation of this Package with a commercial distribution is always
permitted provided that the use of this Package is embedded; that is,
when no overt attempt is made to make this Package's interfaces visible
to the end user of the commercial distribution. Such use shall not be
construed as a distribution of this Package.

The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut

1; # End of Spreadsheet::ParseExcel::Assist
