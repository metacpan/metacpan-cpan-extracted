package SVG::Calendar;

# Created on: 2006-04-22 10:36:43
# Create by:  ivan
# $Id$
# # $Revision$, $HeadURL$, $Date$
# # $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Scalar::Util qw/blessed/;
use Data::Dumper qw/Dumper/;
use Clone qw/clone/;
use Math::Trig;
use DateTime::Format::Strptime qw/strptime strftime/;
use Template;
use File::ShareDir qw/dist_dir/;
use Readonly;
use Image::ExifTool qw/ImageInfo/;
use English '-no_match_vars';
use base qw/Exporter/;

our $VERSION   = version->new('0.3.11');
our @EXPORT_OK = qw//;

Readonly my $MARGIN_RATIO             => 0.04;
Readonly my $DAY_COLS                 => 8;
Readonly my $ROUNDING_FACTOR          => 0.5;
Readonly my $TEXT_OFFSET_Y            => 0.1;
Readonly my $TEXT_OFFSET_X            => 0.15;
Readonly my $TEXT_WIDTH_RATIO         => 0.1;
Readonly my $TEXT_HEIGHT_RATIO        => 0.145;
Readonly my $MOON_SCALE_WIDTH         => 0.3;
Readonly my $MOON_SCALE_HEIGHT        => 0.8;
Readonly my $HEADING_WIDTH_SCALE      => 0.8;
Readonly my $HEADING_HEIGHT_SCALE     => 0.45;
Readonly my $HEADING_DOW_WIDTH_SCALE  => 2;
Readonly my $HEADING_DOW_HEIGHT_SCALE => 0.4;
Readonly my $HEADING_WOY_WIDTH_SCALE  => 4;
Readonly my $HEADING_WOY_HEIGHT_SCALE => 0.9;
Readonly my $MAX_WEEK_ROW             => 5;
Readonly my $MAX_DAYS                 => 42;
Readonly my $INTERVAL_ONE_DAY         => DateTime::Duration->new(days => 1);
Readonly my $INTERVAL_ONE_WEEK        => DateTime::Duration->new(days => 7);
Readonly my $INTERVAL_ONE_MONTH       => DateTime::Duration->new(months => 1);
Readonly my $INTERVAL_ELEVEN_MONTHS   => DateTime::Duration->new(months => 11);
Readonly my $FULL_MOON                => 100;
Readonly my $MOON_RADIAL_STEP         => 1.34;
Readonly my $MOON_AT_NIGHT            => DateTime::Duration->new(hours => 20);
Readonly my $FULL_CIRCLE_DEGREES      => 360;
Readonly my $ONE_WEEK                 => 7;

sub new {

    my ( $class, %param ) = @_;
    my $self = clone \%param;

    bless $self, $class;

    $self->init();

    return $self;
}

sub init {
    my $self    = shift;
    my %size    = $self->get_page();
    my %temp    = ( page => \%size, xu => $self->{page}{width_unit}, yu => $self->{page}{height_unit}, );
    my $height  = $self->{page}{height};
    my $width   = $self->{page}{width};
    my $xu      = $self->{page}{width_unit};
    my $yu      = $self->{page}{height_unit};
    my $xmargin = $self->{page}{margin} || $self->{page}{width} * $MARGIN_RATIO;
    my $ymargin = $self->{page}{margin} || $self->{page}{height} * $MARGIN_RATIO;
    $self->{page}{x_margin}    = $xmargin;
    $self->{page}{y_margin}    = $ymargin;
    $self->{moon}{xoffset}   ||= 0;
    $self->{moon}{yoffset}   ||= 0;
    $self->{calendar_height} ||= '0.5';
    $self->{calendar_height}  =~ s/%//exms;
    if ( $self->{calendar_height} > 1 ) {
        # assume that the height is a percentage value and divide by 100
        $self->{calendar_height} /= 100;
    }
    $self->{classes} = {};

    # cal bounding box (bb)
    $temp{bb} = {
        x      => $xmargin,
        y      => ( $height * ( 1 - $self->{calendar_height} ) + $ymargin ),
        height => ( $height * $self->{calendar_height} - $ymargin * 2 ),
        width  => ( $width - $xmargin * 2 ),
    };

    my $rows              = $MAX_WEEK_ROW + 1;
    my $row_height        = $temp{bb}{height} / ( $rows + $ROUNDING_FACTOR ) * ( 0.5 + $self->{calendar_height} );
    my $row_margin_height = $row_height / ( $rows * 2 );
    my $cols              = $DAY_COLS;
    my $col_width         = $temp{bb}{width} / ( $cols + $ROUNDING_FACTOR );
    my $col_margin_width  = $col_width / ( $cols * 2 );

    # setup the day boxes row by row
    for my $i ( 2 .. $rows ) {
        my $row_y = $temp{bb}{y} + $row_margin_height * ( 2 * $i - 1 ) + $row_height * ( $i - 1 );

        # setup the individual days
        for my $j ( 2 .. $cols ) {
            my $x = ( $temp{bb}{x} + $col_margin_width * ( 2 * $j - 1 ) + $col_width * ( $j - 1 ) ) - $col_width / 2;
            my $y = $row_y - $row_height / 2;
            $temp{cal}[ $i - 1 ][ $j - 1 ] = {
                x      => $x,
                y      => $y,
                height => $row_height,
                width  => $col_width,
                text   => {
                    x      => $x + $col_margin_width * $TEXT_OFFSET_X,
                    y      => $y + $row_height * $TEXT_OFFSET_X,
                    length => $col_width * $TEXT_WIDTH_RATIO,
                    class  => 'mday ',
                    style  => 'font-size: ' . ( $row_height * $TEXT_HEIGHT_RATIO ),
                },
            };
        }
    }

    # set up the week day headings
    my $count = 1;
    for my $day (qw/Mon Tue Wed Thu Fri Sat Sun/) {
        my $x = $temp{bb}{x} + $col_margin_width * ( 2 * $count + 1 ) + $col_width * ( $count - 1 ) + $col_width / 2;
        my $y = $temp{bb}{y} + $row_margin_height;
        $temp{cal}[0][$count] = {
            x      => $x,
            y      => $y,
            height => $row_height * $self->{calendar_height},
            width  => $col_width,
            text   => {
                text   => $day,
                x      => $x + $col_width / $HEADING_DOW_WIDTH_SCALE,
                y      => $y + $row_height * $HEADING_DOW_HEIGHT_SCALE,
                length => $col_width * $HEADING_WIDTH_SCALE,
                adjust => 'spacing',                                #AndGlyphs',
                class  => 'day ' . lc $day,
                style  => 'font-size: ' . ( $row_height * $HEADING_HEIGHT_SCALE ),
            },
        };
        $count++;
    }

    # set up the week of the year column
    $count = 1;
    for my $week ( 1 .. $MAX_WEEK_ROW ) {
        my $x = $temp{bb}{x} + $col_margin_width;
        my $y = $temp{bb}{y} + $row_margin_height * ( 2 * $count + 1 ) + $row_height * ( $count - 1 ) + $row_height / 2;
        $temp{cal}[$count][0] = {
            x      => $x,
            y      => $y,
            height => $row_height,
            width  => $col_width / 2,
            text   => {
                text   => $week,
                x      => $x + $col_width / $HEADING_WOY_WIDTH_SCALE,
                y      => $y + $row_height * $HEADING_WOY_HEIGHT_SCALE,
                length => $col_width * $HEADING_WIDTH_SCALE,
                adjust => 'spacing',                                #AndGlyphs',
                class  => 'week',
                style  => 'font-size: ' . ( $row_height * $HEADING_HEIGHT_SCALE ),
            },
        };
        $count++;
    }

    # get the month display stuff
    $temp{month} = {
        x     => $temp{bb}{x} + $col_margin_width * 2,
        y     => $temp{bb}{y} - $ymargin/2,
        style => 'font-size: ' . ($row_height),
    };

    # set up the year display
    $temp{year} = {
        x     => $temp{bb}{x} + $temp{bb}{width},
        y     => $temp{bb}{y} - $ymargin/2,
        style => 'text-align: end; text-anchor: end; font-size: ' . $row_height,
    };

    $self->{template} = \%temp;

    return;
}

sub get_page {

    my $self = shift;
    my $page = ref $self->{page} ? $self->{page}{page} : $self->{page};
    my %size = ( width => '210.00mm', height => '297.00mm' );

    if ($page) {
        %size =
              $page eq 'A0' ? ( width => '840.00mm', height => '1188.00mm' )
            : $page eq 'A1' ? ( width => '594.00mm', height => '840.00mm' )
            : $page eq 'A2' ? ( width => '420.00mm', height => '594.00mm' )
            : $page eq 'A3' ? ( width => '297.00mm', height => '420.00mm' )
            : $page eq 'A4' ? ( width => '210.00mm', height => '297.00mm' )
            : $page eq 'A5' ? ( width => '148.50mm', height => '210.00mm' )
            : $page eq 'A6' ? ( width => '105.00mm', height => '148.50mm' )
            :                 croak "Unknown page type '$page'!\n";
    }

    if ( ref $self->{page} && $self->{page}{width} ) {
        $size{width} = $self->{page}{width};
    }
    if ( ref $self->{page} && $self->{page}{height} ) {
        $size{height} = $self->{page}{height};
    }

    # Get the values to internal variables
    my ( $width, $width_unit ) = $size{width} =~ /\A(.+?)(px|pt|mm|cm|m|in)?\Z/xms;
    $width *= 1.0;
    croak "Unable to get a width from $self->{page} or $self->{width}" if !$width;
    $width_unit ||= 'px';

    my ( $height, $height_unit ) = $size{height} =~ /\A(.+?)(px|pt|mm|cm|m|in)?\Z/xms;
    $height *= 1.0;
    croak "Unable to get a height from $self->{page} or $self->{height}" if !$height;
    $height_unit ||= 'px';

    # store the internal variables
    if ( !ref $self->{page} ) {
        $self->{page} = {};
    }
    $self->{page}{width}       = $width;
    $self->{page}{width_unit}  = $width_unit;
    $self->{page}{height}      = $height;
    $self->{page}{height_unit} = $height_unit;

    return (
        width       => $width,
        width_unit  => $width_unit,
        height      => $height,
        height_unit => $height_unit,
    );
}

sub output_year {

    my ( $self, @params ) = @_;
    my $file = pop @params;
    my ( $start, $end ) = @params;

    return if !$start;

    if ($end) {
        $start = strptime('%F', "$start-01");
        $end   = strptime('%F', "$end-01");
    }
    else {
        $start = strptime('%F', "$start-01-01");
        $end   = $start + $INTERVAL_ELEVEN_MONTHS;
    }

    my @files;
    while ( $start <= $end ) {
        my $month = $start->strftime('%Y-%m');
        push @files, "$file-$month.svg";
        $self->output_month( $month, "$file-$month.svg" );
        $start += $INTERVAL_ONE_MONTH;
    }

    return @files;
}

sub output_month {

    my ( $self, $month, $file, ) = @_;

    # add the month specific details to a clone of the general settings
    my $templ = clone $self->{template};
    my %size  = $self->get_page();
    $self->{full_moon} = 0;

    carp "Month '$month' is not the correct format (YYYY-MM) " if !$month || $month !~ /\A\d{4}-\d{2}\Z/xms;

    my $date = strptime('%F', "$month-01");
    $templ->{year}{text}  = $date->year();
    $templ->{month}{text} = $date->month_name();
    my $month_day = $date - $INTERVAL_ONE_WEEK;
    my $row       = 1;
    my $wrap      = 0;

    # make sure that we start on a monday
    while ( $month_day->wday() != 2 ) {
        $month_day += $INTERVAL_ONE_DAY;
    }

    DAY:
    for my $count ( 1 .. $MAX_DAYS ) {

        # get the day of the week (of the first day of the month)
        my $wday = $month_day->wday();
        $wday = $wday == 1 ? $ONE_WEEK : $wday - 1;
        my $r = $templ->{cal}[$row][$wday]{width} / $DAY_COLS;
        if ( $self->{moon}{radius} ) {
            $r *= $self->{moon}{radius};
        }

        $templ->{cal}[$row][$wday]{text}{text} = $month_day->mday();
        $templ->{cal}[$row][$wday]{current} = $date->month() == $month_day->month() ? 1 : 2;
        if ( $date->month() == $month_day->month() ) {
            $templ->{cal}[$row][$wday]{text}{class} .= 'current_month';
        }

        if ( $self->{moon} && $self->{moon}{display} ) {

            # get the phase info at 8:00pm
            my $moon_date = $month_day + $MOON_AT_NIGHT;
            my $phase     = $self->get_moon_phase($moon_date);
            $templ->{cal}[$row][$wday]{moon} = $self->moon(
                phase => $phase,
                id    => 'moon_' . $month_day->strftime('%Y-%m-%d'),
                x     => $templ->{cal}[$row][$wday]{x} + $r + $templ->{cal}[$row][$wday]{width} * $MOON_SCALE_WIDTH   + $self->{moon}{xoffset},
                y     => $templ->{cal}[$row][$wday]{y} - $r + $templ->{cal}[$row][$wday]{height} * $MOON_SCALE_HEIGHT + $self->{moon}{yoffset},
                r     => $r,
            );
        }

        if ( $wday == $ONE_WEEK ) {
            $row++;
        }
        if ( $row > $MAX_WEEK_ROW ) {
            $row  = 1;
            $wrap = 1;
        }
        $month_day += $INTERVAL_ONE_DAY;

        # stop if we leave the current month.
        last DAY if $wrap && $date->month() != $month_day->month();
    }

    # process the image if present
    if ( $self->{image} && ( $self->{image}{src} || $self->{image}{$month} ) ) {
        my $image = $self->{image}{$month} || $self->{image}{src};
        $templ->{image}{src} = $image;

        $templ->{image}{x} = $self->{page}{x_margin};
        $templ->{image}{y} = $self->{page}{y_margin};

        if ( -f $image ) {
            my $info = ImageInfo($image);
            if ( $info->{ImageHeight} && $info->{ImageWidth} ) {
                $templ->{image}{x}      = $self->{page}{x_margin};
                $templ->{image}{y}      = $self->{page}{y_margin};
                $templ->{image}{width}  = $self->{page}{width}  - 2 * $self->{page}{x_margin};
                $templ->{image}{height} = $self->{page}{height} * (1 - $self->{calendar_height}) - $self->{page}{y_margin} * 2;

                my $image_scale = $info->{ImageHeight}    / $info->{ImageWidth};
                my $page_scale  = $templ->{image}{height} / $templ->{image}{width};

                if ($image_scale < $page_scale) {
                    $templ->{image}{y}      -= ( $templ->{image}{height} - ( $templ->{image}{height} * $page_scale / $image_scale ) ) / 2;
                    $templ->{image}{height} *= $image_scale / $page_scale;
                }
                else {
                    $templ->{image}{x}     += ( $templ->{image}{width} - ( $templ->{image}{width} * $page_scale / $image_scale ) ) / 2;
                    $templ->{image}{width} *= $page_scale / $image_scale;
                }
            }
            else {
                die "The image $image doesn't apear to have a height or width\n";
            }
        }
    }

    return $self->output( $file, $templ );
}

sub output {

    my ( $self, $file, $template ) = @_;

    my $fh;
    my %option = ( EVAL_PERL => 1 );
    $option{INCLUDE_PATH} = $self->{INCLUDE_PATH} || dist_dir('SVG-Calendar');
    if ( $self->{path} ) {
        $option{INCLUDE_PATH} .= ':' . $self->{path};
    }

    my $tmpl = $self->{tt} || Template->new(%option);

    my $text;
    print Dumper($template) if $self->{verbose};

    $tmpl->process( 'calendar.svg', $template, \$text )
        or croak( $tmpl->error );

    if ($file) {
        if ( $file eq q/-/ ) {
            print $text or carp "Could not write to STDOUT: $OS_ERROR\n";
        }
        else {
            open $fh, q/>/, $file or croak "Cannot write SVG to file '$file': $!\n";

            print {$fh} $text or carp "Could not write to file '$file': $OS_ERROR\n";

            close $fh or carp "There was an issue closing file '$file': $OS_ERROR\n";

            if ( -f $file && $self->{inkscape} ) {
                if ( $self->{inkscape}{pdf} ) {
                    # get inkscape to convert svg to PDF
                }
                if ( $self->{inkscape}{print} ) {
                    # get inkscape to print out the document
                }
            }
        }
    }

    $self->{tt} = $tmpl;
    return $text;
}

sub moon {
    my ( $self, %params ) = @_;

    my $phase  = $params{phase};
    my $id     = $params{id};
    my $x      = $params{x} || $FULL_MOON;
    my $y      = $params{y} || $FULL_MOON;
    my $r      = $params{r} || $FULL_MOON;
    my $class  = q//;

    # approx error of less than one lunar day
    my $error = 2 * pi / 56;  ## no critic

    my $moon = { id => $id };

    # moon phases 0 == new moon 3 == last quarter

    my ( $sx, $sy ) = ( $x, $y );
    my ( $ex, $ey ) = ( $x, $y + 2 * $r );

    if ( $phase < $error || 2 * pi - $error < $phase ) {
        $class = ' new-moon';
    }
    elsif ( pi - $error < $phase && $phase < pi + $error ) {

        # approx full moon
        my $moon_type = $self->{full_moon}++ ? 'blue-moon' : 'full-moon';
        $moon->{highlight} = {
            type  => 'circle',
            id    => $id,
            class => $moon_type,
            cx    => $x,
            cy    => ( $sy + $ey ) / 2,
            r     => $r,
        };
    }
    elsif ( $phase < pi ) {

        # moon waxing partial
        my $d = "M $sx\t$sy C ";
        $d .= ( $sx + $r * $MOON_RADIAL_STEP ) . q/ / . $sy . q/,/;
        $d .= ( $sx + $r * $MOON_RADIAL_STEP ) . q/ / . $ey;
        $d .= ",$ex\t$ey C ";
        $d .= ( $ex - $r * $MOON_RADIAL_STEP * ( -cos($phase) ) ) . q/ / . ( $ey + $r / 2 * ( -sin($phase) ) ) . q/,/;
        $d .= ( $ex - $r * $MOON_RADIAL_STEP * ( -cos($phase) ) ) . q/ / . ( $sy - $r / 2 * ( -sin($phase) ) );
        $d .= ", $sx\t$sy Z";
        $moon->{highlight} = {
            type  => 'path',
            id    => $id,
            d     => $d,
        };
    }
    elsif ( $phase > pi ) {

        # moon waning partial
        my $d = "M $sx\t$sy C ";
        $d .= ( $sx - $r * $MOON_RADIAL_STEP ) . q/ / . $sy . q/,/;
        $d .= ( $sx - $r * $MOON_RADIAL_STEP ) . q/ / . $ey;
        $d .= ",$ex\t$ey C ";
        $d .= ( $ex + $r * $MOON_RADIAL_STEP * ( -cos($phase) ) ) . q/ / . ( $ey - $r / 2 * ( -sin($phase) ) ) . q/,/;
        $d .= ( $ex + $r * $MOON_RADIAL_STEP * ( -cos($phase) ) ) . q/ / . ( $sy + $r / 2 * ( -sin($phase) ) );
        $d .= ", $sx\t$sy Z";
        $moon->{highlight} = {
            type  => 'path',
            id    => $id,
            d     => $d,
        };
    }

    $moon->{border} = {
        id    => "moon_border_$id",
        class => "outline$class",
        cx    => $x,
        cy    => ( $sy + $ey ) / 2,
        r     => $r,
    };

    return $moon;
}

sub get_moon_phase {

    my ( $self, $date ) = @_;

    if ( !blessed $date || !$date->isa('DateTime') ) {
        $date = strptime('%F %T', "$date 20:00:00");
    }

    if ( !$date ) {
        carp 'Unable to create a date!';
    }

    # check if we have a way to calculate the phase of the moon
    if ( !$self->{moon_phase} ) {
        my @packages = qw/Astro::Coord::ECI::Moon Astro::MoonPhase/;

        PACKAGE:
        for my $package (@packages) {
            my $package_file = $package;
            $package_file =~ s{::}{/}gxms;

            eval{ require $package_file . '.pm' };  ## no critic
            if ( !$EVAL_ERROR ) {
                $self->{moon_phase} = $package;
                last PACKAGE;
            }
        }

        # croak if there is no way to calculate the phase of the moon
        if ( !$self->{moon_phase} ) {
            die "Cannot find any packages installed to calculate the moon phase\nTry installing one of:\ncpan "
                . join( "\ncpan ", @packages ) . "\n";
        }
    }

    my $phase;
    if ( $self->{moon_phase} eq 'Astro::Coord::ECI::Moon' ) {

        # phase in radians
        $phase = Astro::Coord::ECI::Moon->phase( $date->epoch() );
    }
    elsif ( $self->{moon_phase} eq 'Astro::MoonPhase' ) {

        # phase in fraction of circle
        ($phase) = Astro::MoonPhase::phase( $date->epoch() );
        $phase *= 2 * pi;
    }

    return $phase;
}

1;

__DATA__

=head1 NAME

SVG::Calendar - Creates calendars in SVG format which can be printed

=head1 VERSION

This documentation refers to SVG::Calendar version 0.3.11.

=head1 SYNOPSIS

   use SVG::Calendar;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

   # Create a new (basic) SVG::Calendar object for producing A4 calendars
   my $svg = SVG::Calendar->new( page => 'A4' );

   # print to standard out the calendar for June 2006
   print $svg->output_month( '2006-06' );

   # create a calendar for the year 2007 with filenames
   #   my-calendar-2015-01.svg
   #   ...
   #   my-calendar-2015-12.svg
   $svg->output_year( '2007', 'my-calendar' );

=head1 DESCRIPTION

This module generates an SVG image for one or more months for a calendar.

=head1 SUBROUTINES/METHODS

=head3 C<new ( %args )>

Arg: C<page> - hash ref - description

Arg: C<moon> - hash ref - description

Arg: C<image> - hash ref - description

Arg: C<path> - string - Directory containing alternate svg template version

Arg: C<inkscape> - hash ref - Use inkscape to convert the SVG to a PDF or to
print out the generated SVG calendar.

Return: SVG::Calendar - A new SVG::Calendar object

Description: Creates and sets up a new SVG::Calendar object

=head3 C<init ( )>

Initialises the calendar object

=head3 C<get_page ( )>

Return: hash - contains the page height and width and the units used

Description: Gets the dimensions of the page based on the parameters
supplied at creation time

=head3 C<output_year ( ($start, $end | $year), $file  )>

Param: C<$start> - string ('YYYY-MM') - description

Param: C<$end> - string ('YYYY-MM') - description

Param: C<$year> - int (year) - description

Param: C<$file> - string - The base name for the SVG files calendars for each
year

Return: list - A list of the files created

Description: Creates the SVG calendar files for each month of the year (or for
each month from start and end)

 eg $svg->output_year( 2006, 'folowers' );

 Will result in the following files created

 flowers-2006-01.svg
 flowers-2006-02.svg
 ..
 flowers-2006-11.svg
 flowers-2006-12.svg

=head3 C<output_month ( $month, $file,  )>

Param: C<$month> - string (detail) - The month that the calendar page should
display (format YYYY-MM)

Param: C<$file> - string (detail) - The file to save the output to if defined.
if $file eq '-' prints to STDOUT

Return: string - The SVG text to display the calendar page

Description: Outputs a particular months calendar...

(Adds the week of the year and the

=head3 C<output ( $file )>

Param: C<$file> - string (detail) - The file name to print the SVG file to (if undefined it will print nothing)

Return: scalar - The SVG text.

Description:

  <path
     style="fill:none;fill-opacity:0.75000000;fill-rule:evenodd;stroke:#000000;stroke-width:0.25000000pt;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1.0000000"
     d="M 264.88031,225.97672 C 518.24408,341.14207 267.18361,490.85702 267.18361,490.85702 L 264.88031,225.97672 z "
     id="path1460"
     sodipodi:nodetypes="ccc" />
  <path
     style="fill:none;fill-opacity:0.75000000;fill-rule:evenodd;stroke:#000000;stroke-width:0.25000000pt;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1.0000000"
     d="M 628.80282,189.12380 C 854.52691,299.68254 847.54045,393.30582 626.49951,477.03718 C 579.56639,494.81567 769.30455,334.23215 628.80282,189.12380 z "
     id="path1464"
     sodipodi:nodetypes="csc" />
  <path
     style="fill: green; fill-opacity: 0.25; stroke: black;"
     d="M 0 0 C 133.3333 8, 133.3333 192, 0 200 C -133.333 192 -133.3333 8 Z"
        M 0 0 C 133.3333 8  133.3333 192, 0 200 C -133.333 192 -133.3333 8 Z
     id="test" />
  <circle
     style="fill: none; stroke: red; stroke-opacity: 0.5"
     cx="0"
     cy="100"
     r="100"
     id="circle" />

=head3 C<moon ( %params )>

Param: C<phase> - float - 0 <= $phase < 2 * pi, represents the phase of the moon

Param: C<id> - string - The id that the moon SVG part should use

Param: C<x> - float - The X coordinate of the left hand side of the moon to be drawn

Param: C<y> - float - The Y coordinate of the top side of the moon to be drawn

Param: C<r> - float - The Radius of the the moon to be drawn

Return: SVG part - The SVG to display the moon in the phase passed in

Description: From the phase information this function calculates the details
of the curve to represent the phase of the moon and puts it on the diagram
based on the x, y and r parameters.

=head3 C<get_moon_phase ( $date )>

Param: C<$date> - date (DateTime object or string to convert to one) - The
date that the moon phase is desired

Return: float - The phase of the moon from 0 (new moon) via 2 (full moon) to
< 4 (next new moon)

Description: This method calculates the phase of the moon (it will what ever
it can find to calculate the phase)

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate (even
the ones that will "never happen"), with a full explanation of each problem,
one or more likely causes, and any suggested remedies.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module, including
the names and locations of any configuration files, and the meaning of any
environment variables or properties that can be set. These descriptions must
also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all of the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.

Also, a list of restrictions on the features the module does provide: data types
that cannot be handled, performance issues and the circumstances in which they
may arise, practical limitations on the size of data sets, special cases that
are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)
<Author name(s)>  (<contact address>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2009 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077)
All rights reserved.


This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
