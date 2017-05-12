package Spreadsheet::DataToExcel;

use warnings;
use strict;

our $VERSION = '0.0104';
use Spreadsheet::WriteExcel; 
use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors( qw/
    data
    file
    error
/ );


sub new { bless {}, shift }

sub dump {
    my ( $self, $file, $data, $opts ) = @_;
    
    $opts ||= {};
    
    %$opts = (
        width_multiplier    => 1,
        text_wrap           => 1,
        calc_column_widths  => 1,
        center_first_row    => 1,

        %$opts,
    );
    
    $self->error( undef );
    
    $file = $self->file
        unless defined $file
            and length $file;

    return $self->_set_error('Missing filename for output')
        unless defined $file
            and length $file;

    $data = $self->data
        unless defined $data
            and ref $data eq 'ARRAY';

    return $self->_set_error('Missing data for output or data is in incorrect format (needs to be an arrayref of arrayrefs)')
        unless defined $data
            and ref $data eq 'ARRAY';

    $self->file( $file );
    $self->data( $data );

    my $wb = Spreadsheet::WriteExcel->new( $file );
    my $ws = $wb->add_worksheet;

    if ( $opts->{calc_column_widths} ) {
        my $col_num = 0;
        my @sizes;
        for ( @$data ) {
            $col_num = $#$_
                if @$_ > $col_num;

            for my $idx ( 0..$#$_ ) {
                my $length;
                if ( $opts->{text_wrap} and defined $_->[$idx] ) {
                    my @lines = split /\n/, $_->[$idx];
                    my $max_line_length = 0;
                    for ( @lines ) {
                        defined
                            or next;
                        $max_line_length = length
                            if $max_line_length < length;
                    }
                    $length = $max_line_length;
                }
                else {
                    $length = defined $_->[$idx] ? length $_->[$idx] : 0;
                }

                $sizes[$idx] = $length
                    if not defined $sizes[$idx]
                        or $sizes[$idx] < $length;
            }
        }

        for ( 0..$col_num ) {
            $ws->set_column(
                $_,
                $_,
                int($sizes[$_] * $opts->{width_multiplier}) );
        }
    }

    for my $row_num ( 0..$#$data ) {
        my $row = $data->[ $row_num ];
        ref $row eq 'ARRAY'
            or next;

        if ( $opts->{text_wrap} ) {
            my $format = $wb->add_format;
            $format->set_text_wrap;

            $format->set_align('center')
                if $opts->{center_first_row}
                    and $row_num == 0;

            $ws->set_row( $row_num, undef, $format );
        }

        for my $cell_num ( 0..$#$row ) {
            my $cell_data = $row->[$cell_num];

            $ws->write( $row_num, $cell_num, $cell_data );
        }
    }
    $wb->close;

    return 1;
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error( $error );
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

Spreadsheet::DataToExcel - Simple method to generate Excel files from 2D arrayrefs

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Spreadsheet::DataToExcel;

    my @data = (
        [ qw/ID Time Number/ ],
        map [ $_, time(), rand() ], 1..10,
    );

    my $dump = Spreadsheet::DataToExcel->new;
    $dump->dump( 'dump.xls', \@data )
        or die "Error: " . $dump->error;

    # dumps out the @data into Excel file while setting text wrap on new 
    # lines, centering text in cells of the first row and settings
    # column widths to the largest size of the data

=head1 DESCRIPTION

L<Spreadsheet::WriteExcel> is a marvelous module; however, I would always
find myself digging through the huge doc, not something I enjoy when
all I ever want to do is simply dump my rows/columns centering first
row as well as setting the sizes of columns to just be large enough
to fit all the data. This is where C<Spreadsheet::DataToExcel> comes
in.

If you're looking for any more functionality than
C<Spreadsheet::DataToExcel> offers, please see L<Spreadsheet::WriteExcel>.

=head1 CONSTRUCTOR

=head2 C<new>

    my $dump = Spreadsheet::DataToExcel->new;

Takes no arguments, returns a freshly baked C<Spreadsheet::DataToExcel>
object.

=head1 METHODS

=head2 C<dump>

    # different ways to use:

    # first example
    $dump->data( \@data );
    $dump->file('dump.xls');
    $dump->dump # dumps \@data into 'dump.xls' file
        or die "Error: " . $dump->error;

    # second example
    $dump->data( \@data );
    $dump->dump( 'dump.xls', undef, { text_wrap => 0 } )
        or die "Error: " . $dump->error;

    # third example
    open my $fh, '>', 'foo.xls' or die $!;
    $dump->dump( $fh, \@data, { text_wrap => 0 } )
        or die "Error: " . $dump->error;

Instructs the object to dump out our 2D arrayref into an Excel file.
On success returns C<1> on failure returns either C<undef> or an empty
list depending on the context and the reason for failure will be
available via C<error()> method. The arguments are all optional, but 
the first two must be either set in C<dump()> method or set
prior calling C<dump()> via their respective methods (see below). 
Arguments are as follows:

=head3 first argument

    $dump->data(\@data);
    $dump->file('dump.xls');
    $dump->dump;

    # or

    $dump->data(\@data);
    $dump->dump('dump.xls');
    
    # or
    
    open my $fh, '>', 'foo.xls' or die $!;
    $dump->dump($fh, \@data);

The first argument is a filename of the Excel file into which you
want to dump your data, or an already opened filehandle for such a file.
If set to C<undef>, then the filename will be retrieved from the
C<file()> method; if that one is also C<undef>, then C<dump()> will
error out.

=head3 second argument

    $dump->data(\@data);
    $dump->dump('dump.xls');

    # or

    $dump->dump('dump.xls', \@data);

Second argument is an arrayref of arrayrefs of the data that you want
to dump; each element (that is an arrayref) represents a row of data
(and elements of that [inner] arrayref are the cells). If set to C<undef>, 
then the data will be retrieved from the C<data()> method;
if that one is also C<undef>, then C<dump()> will error out.

=head3 third argument

    $dump->dump('dump.xls', \@data, {
            text_wrap           => 1,
            calc_column_widths  => 1,
            width_multiplier    => 1,
            center_first_row    => 1,
        }
    );

The third argument takes a hashef and is completely optional. The
hashref contains keys that are dump options. The following keys are
valid:

=head4 C<text_wrap>

    $dump->dump('dump.xls', \@data, {
            text_wrap => 0, # disable
        }
    );

Takes either true or false values. When set to a true value, newlines
in the data will be interpreted as line wraping characters in the
Excel file ( see C<set_text_wrap()> format method in 
L<Spreadsheet::WriteExcel> ). B<Defaults to:> C<1>

=head4 C<calc_column_widths>

    $dump->dump('dump.xls', \@data, {
            calc_column_widths => 0, # disable
        }
    );

Takes either true or false values. When set to a true value, the module
will set the column widths to fit the largest piece of data that will
be dumped into the column, but see the notes in the C<width_multiplier>
description below. If C<text_wrap> is also set to a true value,
then the module will first split each "cell" on new lines and calculate
the width based on the length of the longest of those individual lines. 
B<Defaults to:> C<1>

=head4 C<width_multiplier>

    $dump->dump('dump.xls', \@data, {
            width_multiplier => 2,
        }
    );

Takes a positive number as a value. Applies only when 
C<calc_column_widths> option (see above) is enabled. Since calculated
width is the C<length()> of the data, it may or may not match the 
width of the "Excel column size" depending on the font that you're using.
This is a snippet of docs from L<Spreadsheet::WriteExcel>:

    The width corresponds to the column width value that is specified
    in Excel. It is approximately equal to the length of a string in the 
    default font of Arial 10. Unfortunately, there is no way to specify 
    "AutoFit" for a column in the Excel file format. This feature is only 
    available at runtime from within Excel.

By setting C<width_multiplier> to any positive number but C<1>, the
C<length()> of the data will be multiplied by C<width_multiplier> and
this gives you means to compensate for difference between font size
and Excel column size. B<Defaults to:> C<1>

=head4 C<center_first_row>

    $dump->dump('dump.xls', \@data, {
            center_first_row => 0, # disable
        }
    );

Takes either true or false values. When set to a true value, will make
the data in the first row of the dump to be center aligned; e.g. you
can specify column names there. B<Defaults to:> C<1>

=head2 C<file>

    my $old_filename = $dump->file;
    $dump->file('new_excel.xls');

Returns currently set filename of the Excel file as a dump. Takes one
optional argument, which is (when set) specifies new name of the
Excel file. See description of the first argument to C<dump()> method 
above.

=head2 C<data>

    my $old_data = $dump->data;
    $dump->data( \@new_data );

Returns currently set data for the dumping. Takes one
optional argument, which is (when set) specifies new data to dump.
See description of the second argument to C<dump()> method above.

=head2 C<error>

    $dump->dump
        or die "Error: " . $dump->error;

Returns the reason for why C<dump()> method failed.

=head1 EXAMPLE 1 (found in examples/dump.pl)

    #!/usr/bin/env perl
    
    use strict;
    use warnings;
    
    use Spreadsheet::DataToExcel;
    
    my @data = (
        [ qw/ID Time Number/ ],
        map [ $_, time(), rand() ], 1..10,
    );

    my $dump = Spreadsheet::DataToExcel->new;
    
    $dump->dump( 'dump.xls', \@data );
    
    print "Done! See dump.xls file\n";

=head1 EXAMPLE 2 (found in examples/interactive_dump.pl) 

    #!/usr/bin/env perl
    
    use strict;
    use warnings;
    
    use Spreadsheet::DataToExcel;
    
    die "Usage: perl $0 file_for_the_dump.xls\n"
        unless @ARGV;
    
    my $dump = Spreadsheet::DataToExcel->new;
    
    $dump->file( shift );
    $dump->data([]);
    
    print "Enter column names separated by spaces:\n";
    push @{ $dump->data }, [ split ' ', <STDIN> ];
    
    {
        print "Enter a row of data separated by spaces or hit CTRL+D to dump:\n";
        $_ = <STDIN>;
        defined or last;
        push @{ $dump->data }, [ split ' ' ];
        redo;
    }
    
    $dump->dump( undef, undef, { text_wrap => 0 } )
        or die "Error: " . $dump->error;
    
    print "Done! See " . $dump->file . " file\n";

=head1 AUTHOR

'Zoffix, C<< <'zoffix at cpan.org'> >>
(L<http://haslayout.net/>, L<http://zoffix.com/>, L<http://zofdesign.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-spreadsheet-datatoexcel at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spreadsheet-DataToExcel>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spreadsheet::DataToExcel

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spreadsheet-DataToExcel>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Spreadsheet-DataToExcel>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spreadsheet-DataToExcel>

=item * Search CPAN

L<http://search.cpan.org/dist/Spreadsheet-DataToExcel/>

=back



=head1 COPYRIGHT & LICENSE

Copyright 2009 'Zoffix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

