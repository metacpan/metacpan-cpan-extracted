package PDF::FromHTML::Template::Constants;

use strict;

BEGIN {
    use Exporter ();

    use vars qw(@ISA @EXPORT_OK);

    @ISA = qw(Exporter);

    @EXPORT_OK = qw(
        %PointsPer
        %Verify
    );
}

# This is a list of conversions from various units of measure to points.
# The key will be the first letter of the unit.
our %PointsPer = (
    I => 72.27,    # Inches
    P => 1,        # Points
);
$PointsPer{C} = ($PointsPer{I} / 2.54); # Centimeters

#GGG Add:
#    PDFTemplate properties (to go with %NoSetProperty)

our %Verify = (

#GGG This also needs improvement ... Not all available fonts are listed
    'FACE' => {
        '__DEFAULT__' => 'Times-Bold',
        ( map { $_ => 1 } qw(
            Courier Courier-Bold Courier-Oblique Courier-BoldOblique
            Helvetica Helvetica-Bold Helvetica-Oblique Helvetica-BoldOblique
            Times-Roman Times-Bold Times-Italic Times-BoldItalic
            Symbol ZapfDingbats
        )),
    },

    'ALIGN' => {
        '__DEFAULT__' => 'left',
#GGG Add a full-justify option - this requires a lot of coding prowess
        ( map { $_ => 1 } qw(
            center left right
        )),
    },

    'OPENACTION' => {
        '__DEFAULT__' => 'fitpage',
        ( map { $_ => 1 } qw(
            fitbox fitheight fitpage fitwidth retain
        )),
    },

    'OPENMODE' => {
        '__DEFAULT__' => 'none',
        ( map { $_ => 1 } qw(
            bookmarks fullscreen none thumbnails
        )),
    },

    # Pagesize is specified in points
    'PAGESIZE' => {
        '__DEFAULT__' => 'Letter',
        'Letter' => {
            PAGE_WIDTH  => 8.5 * $PointsPer{I},
            PAGE_HEIGHT => 11 * $PointsPer{I},
        },
        'Legal' => {
            PAGE_WIDTH  => 8.5 * $PointsPer{I},
            PAGE_HEIGHT => 14 * $PointsPer{I},
        },
        'A0' => {
            PAGE_WIDTH  => 2380,
            PAGE_HEIGHT => 3368,
        },
        'A1' => {
            PAGE_WIDTH  => 1684,
            PAGE_HEIGHT => 2380,
        },
        'A2' => {
            PAGE_WIDTH  => 1190,
            PAGE_HEIGHT => 1684,
        },
        'A3' => {
            PAGE_WIDTH  => 842,
            PAGE_HEIGHT => 1190,
        },
        'A4' => {
            PAGE_WIDTH  => 595,
            PAGE_HEIGHT => 842,
        },
    },
);

1;
__END__
