package Spreadsheet::WriteExcel::Extended::FitColumnWidth;

use warnings;
use strict;
use Carp;
use base qw(Spreadsheet::WriteExcel);
use Font::TTFMetrics;

our $arial;     # Default font
our $arialbd;   # Default bold font
our $VERSION = sprintf("%d.%02d", q'$Revision: 1.2 $' =~ /(\d+)\.(\d+)/);


sub new
{
    my( $class, @args ) = @_;

    my $workbook;
    my $hr;
    if (@args == 1 && ref($args[0]) eq 'HASH')
    {
        $hr   = $args[0];
        carp "Expect hash ref with filename defined against key 'filename'" unless ( $hr->{filename} && $hr->{filename} ne '');
        $workbook = $class->SUPER::new( $hr->{filename} );
    }
    else
    {
        # This is not how we expect to use this subclass, ie default behaviour only
        # Assume default of just filename with possibly other arguments
        $workbook = $class->SUPER::new( @args );
        return $workbook;
    }

    # Create some formats for later use
    my $format_heading = $workbook->add_format();
    $format_heading->set_bold();
    $format_heading->set_bg_color('silver');
    $format_heading->set_color('blue');
    $format_heading->set_align('center');
    $workbook->{__extended_format_heading__} = $format_heading;

    my $format_bold = $workbook->add_format();
    $format_bold->set_bold();
    $workbook->{__extended_format_bold__} = $format_bold;

    # Set font and background colour formats (standard)
    foreach my $colour ('blue', 'brown', 'cyan', 'gray', 'green', 'lime', 'magenta', 'navy', 'orange', 'pink', 'purple', 'red', 'silver', 'white', 'yellow',)
    {
        my $fmt = $workbook->add_format();
        $fmt->set_color($colour);
        $workbook->{'__extended_format_' . $colour . '__'} = $fmt;

        my $fmt_bold = $workbook->add_format();
        $fmt_bold->set_color($colour);
        $fmt_bold->set_bold();
        $workbook->{'__extended_format_' . $colour . '_bold__'} = $fmt_bold;

        my $fmt_bg = $workbook->add_format();
        $fmt_bg->set_bg_color($colour);
        $workbook->{'__extended_format_' . $colour . '_bg__'} = $fmt_bg;
    }
    # Set font and background colour formats (special)
    foreach my $colour ([ 'lightblue', 0x1A], [ 'lightyellow', 0x1B], [ 'lightgreen', 0x2A], [ 'lightpurple', 0x2E],)
    {
        my $fmt = $workbook->add_format();
        $fmt->set_color($colour->[1]);
        $workbook->{'__extended_format_' . $colour->[0] . '__'} = $fmt;

        my $fmt_bold = $workbook->add_format();
        $fmt_bold->set_color($colour->[1]);
        $fmt_bold->set_bold();
        $workbook->{'__extended_format_' . $colour->[0] . '_bold__'} = $fmt_bold;

        my $fmt_bg = $workbook->add_format();
        $fmt_bg->set_bg_color($colour->[1]);
        $workbook->{'__extended_format_' . $colour->[0] . '_bg__'} = $fmt_bg;
    }
    # Finally a special light gray
    my $lgray = $workbook->set_custom_color(62, 231, 231, 231);
    $workbook->{'__extended_format_lightgray_bg__'} = $workbook->add_format(bg_color => $lgray);
    $workbook->{'__extended_format_lightgray__'} = $workbook->add_format(color => $lgray);


    # Setup any sheets (after all that's what this subclass is for)
    if ($hr->{sheets})
    {
        carp "Expect sheets value to be an array ref" unless (ref($hr->{sheets}) eq 'ARRAY');

        my $cnt = 1;
        foreach my $sht (@{ $hr->{sheets} })
        {
            # Each sheet can be either a name or a hash ref,
            # If a hash ref, it should contain keys: name, headings
            # the headings value should be an array ref of column headings for the first row

            my $worksheet;
            if (ref($sht) eq 'HASH')
            {
                $worksheet = $workbook->add_worksheet($sht->{name});
                $worksheet->add_write_handler(qr[\w], \&extended_store_string_widths);      # Based on jMcNamara example code
                $worksheet->write_row(0, 0, $sht->{headings}, $format_heading);
            }
            else
            {
                $worksheet = $workbook->add_worksheet($sht);
                $worksheet->add_write_handler(qr[\w], \&extended_store_string_widths);      # Based on jMcNamara example code
            }

            $worksheet->keep_leading_zeros();                                           # Keep leading zeros on data (good for entry_ID)
            $worksheet->freeze_panes(1, 0);                                             # Freeze the first row

            # Save it into the object
            push @{$workbook->{__extended_sheets__}}, $worksheet;
        }
    }

    # Should expand this to cater for other fonts, font sizes and location of TTF's
    my $font_file      = 'c:\windows\fonts\arial.ttf';
    my $font_file_bold = 'c:\windows\fonts\arialbd.ttf';

    if ($hr->{font})
    {
        if (-f $hr->{font})
        {
            $font_file = $hr->{font};
        }
        else
        {
            carp "Specified font file $hr->{font} does not exist\n";
        }
    }
    if ($hr->{font_bold})
    {
        if (-f $hr->{font_bold})
        {
            $font_file_bold = $hr->{font_bold};
        }
        else
        {
            carp "Specified font file $hr->{font_bold} does not exist\n";
        }
    }

    unless (-f $font_file)
    {
        carp "Could not find font file $font_file";
    }
    else
    {
        $arial  = Font::TTFMetrics->new($font_file);
    }
    unless (-f $font_file_bold)
    {
        carp "Could not find font file $font_file_bold";
    }
    else
    {
        $arialbd  = Font::TTFMetrics->new($font_file_bold);
    }

    return $workbook;
}


sub get_formats
{
    my $workbook = shift;

    return sort grep { /^__extended_format/ } keys %$workbook;
}

sub get_format
{
    my ($workbook, $name) = @_;

    if ($workbook->{'__extended_format_' . lc($name) . '__'})
    {
        return $workbook->{'__extended_format_' . lc($name) . '__'};
    }

    my $msg = "Extended format $name does not exist, valid values are:\n";
    $msg .= join("\n", map { /__extended_format_(.*)__/; $1 } $workbook->get_formats());

    croak $msg;
}

sub get_number_sheets
{
    my $workbook = shift;

    return scalar(@{$workbook->{__extended_sheets__}});
}

sub get_worksheets_extended
{
    my $workbook = shift;

    return @{ $workbook->{__extended_sheets__} };
}



###############################################################################
#
# The following function is a callback that was added via add_write_handler()
# above. It modifies the write() function so that it stores the maximum
# unwrapped width of a string in a column.
#
sub extended_store_string_widths
{
    my $worksheet = shift;
    my $row       = $_[0];
    my $col       = $_[1];
    my $token     = $_[2];

    # Ignore some tokens that we aren't interested in.
    return if not defined $token;       # Ignore undefs.
    return if $token eq '';             # Ignore blank cells.
    return if ref $token eq 'ARRAY';    # Ignore array refs.
    return if $token =~ /^=/;           # Ignore formula

    # Ignore numbers
    return if $token =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;

    # Ignore various internal and external hyperlinks. In a real scenario
    # you may wish to track the length of the optional strings used with
    # urls.
    return if $token =~ m{^[fh]tt?ps?://};
    return if $token =~ m{^mailto:};
    return if $token =~ m{^(?:in|ex)ternal:};


    # We store the string width as data in the Worksheet object. We use
    # a double underscore key name to avoid conflicts with future names.
    #
    my $old_width = $worksheet->{__extended_col_widths}->[$col];
    my $string_width;
    if ($arial)
    {
        $string_width = string_width_fancy($token, $arial);
    }
    else
    {
        $string_width = string_width_simple($token);
    }

    # Hack to cater for header row being bold - this needs to be done better
    if ($row == 0 && $arialbd)
    {
        $string_width = string_width_fancy($token, $arialbd);
    }
    elsif ($row == 0)
    {
        $string_width *= 1.15;
    }

    if (not defined $old_width or $string_width > $old_width)
    {
        # Set a minium of 4 - this should be configurable
        $worksheet->{__extended_col_widths}->[$col] = $string_width > 4 ? $string_width : 4;
    }

    # Return control to write();
    return undef;
}


###############################################################################
#
# Very simple conversion between string length and string width for Arial 10.
# See below for a more sophisticated method.
#
sub string_width_simple
{
    return 0.9 * length $_[0];
}


###############################################################################
#
# This function uses an external module to get a more accurate width for a
# string. Note that in a real program you could "use" the module instead of
# "require"-ing it and you could make the Font object global to avoid repeated
# initialisation.
#
# Note also that the $pixel_width to $cell_width is specific to Arial. For
# other fonts you should calculate appropriate relationships. A future version
# of S::WE will provide a way of specifying column widths in pixels instead of
# cell units in order to simplify this conversion.
#
sub string_width_fancy
{
    my ($str, $font_metrics) = @_;

    my $font_size    = 10;
    my $dpi          = 96;
    my $units_per_em = $font_metrics->get_units_per_em();
    my $font_width   = $font_metrics->string_width($str);

    # Convert to pixels as per TTFMetrics docs.
    my $pixel_width  = 6 + $font_width *$font_size *$dpi /(72 *$units_per_em);

    # Add extra pixels for border around text.
    $pixel_width  += 6;

    # Convert to cell width (for Arial) and for cell widths > 1.
    my $cell_width   = ($pixel_width -5) /7;

    return $cell_width;
}


###############################################################################
#
# Adjust the column widths to fit the longest string in the column.
#
sub extended_autofit_columns
{
    my $worksheet = shift;
    my $col       = 0;

    for my $width (@{$worksheet->{__extended_col_widths}})
    {
        $worksheet->set_column($col, $col, $width) if $width;
        $col++;
    }
}


sub close
{
    my $workbook = shift;

    # Do the autofit of columns
    foreach my $worksheet (@{$workbook->{__extended_sheets__}})
    {
        extended_autofit_columns($worksheet);
    }

    # Now close
    $workbook->SUPER::close();
}


#####################################################################
# DO NOT REMOVE THE FOLLOWING LINE, IT IS NEEDED TO LOAD THIS LIBRARY
1;


__END__

=head1 NAME

Spreadsheet::WriteExcel::Extended::FitColumnWidth - Extends Spreadsheet::WriteExcel with autofit of columns and a few other nice things


=head1 SYNOPSIS

use Spreadsheet::WriteExcel::Extended::FitColumnWidth where you would otherwise use Spreadsheet::WriteExcel except that the call
to new has been enhanced and there are a number of things done by default, like autofit of columns, setup of header line,
pre defined formats.

 use warnings;
 use strict;
 use Spreadsheet::WriteExcel::Extended::FitColumnWidth;

 my @headings = qw{ Fruit Colour Price/Kg };
 my $workbook = Spreadsheet::WriteExcel::Extended::FitColumnWidth->new({
        filename  => 'test.xls',
        sheets    => [ { name => 'Test Data', headings => \@headings}, ],
        font      => '/myfonts/arial.ttf'    # optional, defaults to 'c:\windows\fonts\arial.ttf'
        font_bold => '/myfonts/arialbd.ttf'  # optional, defaults to 'c:\windows\fonts\arialbd.ttf'
        });
 my $worksheet = $workbook->{__extended_sheets__}[0];
 my $row = 1;  # First row after the header row

 $worksheet->write_row($row++, 0, [ 'Apple - Pink Lady', 'Red', '3.25' ], $workbook->get_format('red'));
 $worksheet->write_row($row++, 0, [ 'Apple - Granny Smith', 'Green', '2.95' ], $workbook->{__extended_format_green__});
 # Note:  The autofit does not currently take bold fonts into account, bit is may soon :)
 $worksheet->write_row($row++, 0, [ 'Original Carrot', 'Purple', '5.95' ], $workbook->{__extended_format_purple_bold__});
 $worksheet->write_row($row++, 0, [ 'Orange', 'Orange', '6.15' ], $workbook->{__extended_format_orange_bg__});

 $workbook->close();

You B<MUST> call close();

Note that the default font is assumed to be Arial 10pt

=head1 METHODS

=head2 new

  my $workbook = Spreadsheet::WriteExcel::Extended::FitColumnWidth->new({
        filename => 'filename.xls',
        sheets   => [
            { name => 'Test Data', headings => \@headings},
            { name => 'Sheet Number 2', headings => [ 'Component', 'Component Description' ]},
            ...
            ],
        font      => 'path/to/default/ttf'      # optional, defaults to 'c:\windows\fonts\arial.ttf'
        font_bold => 'path/to/header_row/ttf'   # optional, defaults to 'c:\windows\fonts\arialbd.ttf'
        });

The main difference here is that you pre-define the sheets you want and what heading they should have.
The headings are added with a format of:

 $format_heading->set_bold();
 $format_heading->set_bg_color('silver');
 $format_heading->set_color('blue');
 $format_heading->set_align('center');

Which is also stored as:
 $workbook->{__extended_format_heading__} = $format_heading;

=head2 close

$workbook->close();

Don't call this and you will not have any autofit!

=head2 get_format

Get one of the predefined formats eg $workbook->get_format('blue');

Note that the name provided does not include the prefix '__extended_format_' or suffix '__'

=head2 get_worksheets_extended

my @sheets = $workbook->get_worksheets_extended();

Returns an array of Spreadsheet::WriteExcel::Worksheet objects in the order
they were originally defined in the call to new

=head1 PRE DEFINED FORMATS

The pre defined formats are listed below (as returned by get_formats())

=head2 get_formats

The following formats are pre defined and accessable as $workbook->{format_name_blow}:

 __extended_format_blue__
 __extended_format_blue_bg__
 __extended_format_blue_bold__
 __extended_format_bold__
 __extended_format_brown__
 __extended_format_brown_bg__
 __extended_format_brown_bold__
 __extended_format_cyan__
 __extended_format_cyan_bg__
 __extended_format_cyan_bold__
 __extended_format_gray__
 __extended_format_gray_bg__
 __extended_format_gray_bold__
 __extended_format_green__
 __extended_format_green_bg__
 __extended_format_green_bold__
 __extended_format_heading__
 __extended_format_lightblue__
 __extended_format_lightblue_bg__
 __extended_format_lightblue_bold__
 __extended_format_lightgray__
 __extended_format_lightgray_bg__
 __extended_format_lightgreen__
 __extended_format_lightgreen_bg__
 __extended_format_lightgreen_bold__
 __extended_format_lightpurple__
 __extended_format_lightpurple_bg__
 __extended_format_lightpurple_bold__
 __extended_format_lightyellow__
 __extended_format_lightyellow_bg__
 __extended_format_lightyellow_bold__
 __extended_format_lime__
 __extended_format_lime_bg__
 __extended_format_lime_bold__
 __extended_format_magenta__
 __extended_format_magenta_bg__
 __extended_format_magenta_bold__
 __extended_format_navy__
 __extended_format_navy_bg__
 __extended_format_navy_bold__
 __extended_format_orange__
 __extended_format_orange_bg__
 __extended_format_orange_bold__
 __extended_format_pink__
 __extended_format_pink_bg__
 __extended_format_pink_bold__
 __extended_format_purple__
 __extended_format_purple_bg__
 __extended_format_purple_bold__
 __extended_format_red__
 __extended_format_red_bg__
 __extended_format_red_bold__
 __extended_format_silver__
 __extended_format_silver_bg__
 __extended_format_silver_bold__
 __extended_format_white__
 __extended_format_white_bg__
 __extended_format_white_bold__
 __extended_format_yellow__
 __extended_format_yellow_bg__
 __extended_format_yellow_bold__

This list can be generated using:

 print "Formats:\n", join("\n", $workbook->get_formats()), "\n";

=head2 get_number_sheets

$workbook->get_number_sheets(); returns the number of sheets defined in call to new.

=head1 INTERAL USE ONLY

=head2 extended_autofit_columns

=head2 extended_store_string_widths

=head2 string_width_fancy

=head2 string_width_simple

=head1 KNOWN ISSUES

None

=head1 SEE ALSO

Spreadsheet::WriteExcel

The fantastic module by John McNamara (jmcnamara @ cpan.org) which is the basis of this module.
The autofit code is also based on the example code that John put together.

=head1 TODO

- Change autofit to cater for Bold fonts in general (ie other than the header line)
- Allow for different font sizes (currently assumes Arial 10pt)
- Better approach to finding the arial.ttf to allow the use of font metrics (ie with out having to specify a location)

=head1 CVS ID

 $Id: FitColumnWidth.pm,v 1.2 2012/04/11 11:49:17 Greg Exp $

=head1 CVS LOG

 $Log: FitColumnWidth.pm,v $
 Revision 1.2  2012/04/11 11:49:17  Greg
 - Minor but annoying correction

 Revision 1.1  2012/04/10 10:46:29  Greg
 Initial development


=head1 AUTHOR

 Greg George, IT Technology Solutions P/L,
 Email: gng@cpan.org


=head1 BUGS

Please report any bugs or feature requests to C<bug-spreadsheet-writeexcel-extended-fitcolumnwidth at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spreadsheet-WriteExcel-Extended-FitColumnWidth>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spreadsheet::WriteExcel::Extended::FitColumnWidth

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spreadsheet-WriteExcel-Extended-FitColumnWidth>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Spreadsheet-WriteExcel-Extended-FitColumnWidth>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spreadsheet-WriteExcel-Extended-FitColumnWidth>

=item * Search CPAN

L<http://search.cpan.org/dist/Spreadsheet-WriteExcel-Extended-FitColumnWidth/>

=back


=head1 ACKNOWLEDGEMENTS

John McNamara the creator of Spreadsheet::WriteExcel and who defined the basis of
this auto column fit code

=head1 COPYRIGHT & LICENSE

Copyright 2012 Greg George.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

#---< End of File >---#
