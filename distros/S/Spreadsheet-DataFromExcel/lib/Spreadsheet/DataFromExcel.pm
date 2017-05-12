package Spreadsheet::DataFromExcel;

use warnings;
use strict;

our $VERSION = '1.001003';

use Spreadsheet::ParseExcel;

sub new { bless {}, shift }

sub load {
    my ( $self, $file, $sheet_name, $start_row, $end_row ) = @_;
    
    $self->error( undef );
    
    return $self->_set_error("File $file not found")
        unless -e $file;

    my $parser   = Spreadsheet::ParseExcel->new();
    my $workbook = $parser->Parse($file)
        or return $self->_set_error("Could not load Excel file; perhaps it's not a real Excel file or is damaged?");

    my $worksheet = defined $sheet_name
    ? $workbook->Worksheet($sheet_name)
    : ($workbook->worksheets)[0];

    unless ( defined $worksheet ) {
        if ( defined $sheet_name ) {
            return $self->_set_error("Specified worksheet $sheet_name was not found in the Excel file");
        }
        else {
            return $self->_set_error("Could not obtain any worksheets");
        }
    }

    my @data;

    my ( $row_min, $row_max ) = $worksheet->row_range;
    $row_min = $start_row
        if defined $start_row;

    $row_max = $end_row
        if defined $end_row;

    my ( $col_min, $col_max ) = $worksheet->col_range;

    for my $row ( $row_min .. $row_max ) {
        my @row;
        for my $col ( $col_min .. $col_max ) {
            my $cell = $worksheet->get_cell( $row, $col );
            unless ( $cell ) {
                push @row, undef;
                next;
            }

            push @row, $cell->unformatted;
        }
        push @data, \@row;
    }

    return \@data;
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error( $error );
    return;
}

sub error {
    my $self = shift;

    @_ and $self->{ERROR} = shift;

    return $self->{ERROR};
}

1;
__END__

=encoding utf8

=head1 NAME

Spreadsheet::DataFromExcel - read a sheet from Excel file into a simple arrayref of arrayrefs

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Spreadsheet::DataFromExcel;

    my $p = Spreadsheet::DataFromExcel->new;

    # Excel file has three columns and five rows
    my $data = $p->load('file.xls')
        or die $p->error;

    use Data::Dumper;
    print Dumper $data;

    # prints:
    $VAR1 = [
          [
            'ID',
            'Time',
            'Number'
          ],
          [
            1,
            '1248871908',
            '0.020068370810808'
          ],
          [
            2,
            '1248871908',
            '0.765251959066035'
          ],
          [
            3,
            '1248871908',
            '0.146082393164885'
          ],
          [
            4,
            undef,
            '0.618001895581024'
          ],
    ]

=head1 DESCRIPTION

For some lucky reason I often and up given data to work with in Excel 
format. Nothing fancy, just one sheet with basic string data.

My steps to utilize it in a perl program were either copy/pasting it
into a text file and splitting on \t or firing up 
L<Spreadsheet::ParseExcel> and trying to figure out what exactly that I
needed was. No more! Welcome the C<Spreadsheet::DataFromExcel>!

C<Spreadsheet::DataFromExcel> to L<Spreadsheet::ParseExcel> is
what a bycicle is to a freight truck. C<Spreadsheet::DataFromExcel>
offers a "no crust" loading of Excel sheets into an arrayref of arrayrefs
where each inner arrayref represents a row and its elements represent 
cells.

If you're looking for any more control or data,
see L<Spreadsheet::ParseExcel> or L<Spreadsheet::Read>

=head1 CONSTRUCTOR

=head2 C<new>

    my $p = Spreadsheet::DataFromExcel->new;

Takes no arguments, returns a freshly baked C<Spreadsheet::DataFromExcel>
object.

=head1 METHODS

=head2 C<load>

    # simple
    my $data = $p->load('file.xls')
        or die $p->error;

    # with all the optionals set
    my $data = $p->load(
        'file.xls',
        'SheetName',
        0,   # start row number; starting counting with 0
        10,  # end row number
    ) or die $p->error;

On success returns
an arrayref of arrayrefs where each inner arrayref represents a row
in the Excel sheet and each element of those inner arreyrefs is a scalar
that contains the data for each cell in that row. If a particular cell
is empty, it will be represented with an C<undef>. On error returns
either C<undef> or an empty list (depending on the context) and the
reason for failure will be available via C<error()> method.

Takes one mandatory and three optional arguments; if you want want to
keep an argument at its default, set it to C<undef>. The arguments
are as follows:

=head3 first argument (the filename)

    my $data = $p->load('file.xls')
        or die $p->error;

B<Mandatory>. Specifies the filename of the Excel file to read. If the
file was not found or is not an Excel file, C<load()> will error out.

=head3 second argument (sheet name)

    my $data = $p->load(
        'file.xls',
        'SheetName', # sheet name
    ) or die $p->error;

    my $data = $p->load(
        'file.xls',
        1, # sheet number
    ) or die $p->error;

B<Optional>. Takes either a string or a number as a value that specifies
the name or sheet number to load. B<Note:> if some sheet's name is a number
and it matches the number you pass as the second argumnet (in attempt
to load a sheet by number) then that number will be taken as sheet's name
and you may end up with the wrong sheet.
If the specified sheet was not found, C<load()> will error out.
B<By default> C<load()> will load up the B<first sheet> as returned
by L<Spreadsheet::ParseExcel>'s workbook C<worksheets()> method.

=head3 third argumnet (start row number)

    my $data = $p->load(
        'file.xls',
        undef, # leave the second argument at its default
        0,     # start row number; starting counting with 0
    ) or die $p->error;

B<Optional>. Specifies the starting row number from which to start
loading of data. Note that counting starts from B<zero> (in Excel
it starts from one). B<By default> will start with whatever
L<Spreadsheet::ParseExcel>'s C<< $worksheet->row_range >> thinks
as the first starting row with data.

=head3 fourth argument (end row number)

    my $data = $p->load(
        'file.xls',
        undef, # default sheet
        undef, # default starting row
        10,    # end row number
    ) or die $p->error;

B<Optional>. Specifies the end row number at which to stop
loading of data. Note that counting starts from B<zero> (in Excel
it starts from one). B<By default> will end with whatever
L<Spreadsheet::ParseExcel>'s C<< $worksheet->row_range >> thinks
as the last row with data. There's no real harm of specifying too high
of end row number; you'll only end up with a bunch of undefs as cell
values in those arrayref-rows that went above the limit.

=head2 C<error>

    my $data = $p->load('file.xls')
        or die $p->error;

Takes no arguments, returns the reason for why C<load()> failed.

=head1 SEE ALSO

L<Spreadsheet::ParseExcel>, L<Spreadsheet::Read>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Spreadsheet-DataFromExcel>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests on GitHub
L<https://github.com/zoffixznet/Spreadsheet-DataFromExcel/issues>
or, alternatively and not preferred, RT: 

C<bug-spreadsheet-datafromexcel at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spreadsheet-DataFromExcel>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spreadsheet::DataFromExcel

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spreadsheet-DataFromExcel>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Spreadsheet-DataFromExcel>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spreadsheet-DataFromExcel>

=item * Search CPAN

L<http://search.cpan.org/dist/Spreadsheet-DataFromExcel/>

=back



=head1 COPYRIGHT & LICENSE

Copyright 2009 'Zoffix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

