package PDF::Builder::Resource::XObject::Image::SVG;

use base 'PDF::Builder::Resource::XObject::Image';

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use Carp;

=head1 NAME

PDF::Builder::Resource::XObject::Image::SVG - Support routines for SVG (Scalable Vector Graphics) image library

Inherits from L<PDF::Builder::Resource::XObject::Image>

Note that, unlike the output of other image formats, C<image_svg()> returns
an I<array> of anonymous hashes, one for each E<lt>svgE<gt> tag within the
SVG input. See L</What is returned> below for details.

=head2 METHODS

=head2 new

    $res = PDF::Builder::Resource::XObject::Image::SVG->new($pdf, $file, %opts)

C<$file> gives the SVG input (see the SVGPDF library for details and 
limitations). It may be a filename, a string reference (with SVG content),
or a filehandle.

=over

Options:

=over

=item subimage => n

If multiple C<svg> entries are in an SVG file, and they are not combined by
the SVGPDF C<combine> option into one image, this permits selection of which
image to display. 
Any I<n> may be given, from 0 up to the number of C<svg> images minus 1. The 
n-th element will be retained, and all others discarded. The default
is to return the entire array, and not remove any elements, permitting display
of mulitple images in any desired order.
See the discussion on combining multiple images 
L</Dealing with multiple image objects, and combining them>. 
The default behavior of the display routine
(C<object>) is to display only the first element (there must be at least one). 

=item MScore => flag

If set to true (a non-zero value), a font callback for the 14 Microsoft
Windows "core" extensions will be added to any other font callbacks given by
the user. These include "Georgia" serif, "Verdana" sans-serif, and "Trebuchet" 
sans-serif fonts, and "Wingdings" and "Webdings" symbology fonts. Non-Windows
systems usually don't include these "core" fonts, so it may be unsafe to use
them.

This option is enabled for all operating systems, not just MS Windows, so you
can create PDFs that make use of Windows "core" fonts (extension). This does
not guarantee that such fonts I<will> be available on the machine used to read
the resulting PDF!

=item compress => flag

If set to true (a non-zero value; default is 1), the resulting XObject stream 
will be compressed. This is what you would normally do. On the other hand,
setting it to false (0) leaves the stream uncompressed. You may wish to do this
if you want to examine the stream in the finished PDF, such as is done for the
t-test.

=back

SVGPDF Options:

These are options which, if given, are passed on to the SVGPDF library. Some of
them are fixed by C<image_svg> and can not be changed, while others are 
defaulted by C<image_svg> but I<can> be overridden by the user.

You should consult the SVGPDF library documentation for more details on such
options.

=over

=item pdf => PDF object

This is automatically set by the SVG routine, and can B<not> be overridden by
the user. It is passed to C<SVGPDF-E<gt>new()>.

=item fontsize => n

This is the font size (in points) for SVGPDF to use to scale text and figure
the I<em> and I<ex> sizes. The default is 12 points. It is passed on to
both the C<SVGPDF-E<gt>new()> and C<$svg-E<gt>process()> SVGPDF methods.

=item pagesize => [ width, height ]

This is the maximum dimensions of the resulting object, in case there are no
dimensions given, or they are too large to display. The default is 595 pt x
842 pt (A4 page size), internal to SVGPDF. It is passed to C<SVGPDF-E<gt>new()>.

=item grid => n

The default is 0. A value greater than 0 indicates the spacing (in points) of
a grid for development/debugging purposes. It is passed to C<SVGPDF-E<gt>new()>.

=item verbose => n

It defaults to 0 (fatal messages only), but the user may set it to a higher 
value for outputting informational messages. It is passed to 
C<SVGPDF-E<gt>new()>.

=item fc => \&fonthandler_callback

This is a list of one or more callbacks for the font handler. If the C<MScore>
flag is true (see above), another callback will be added to the list to handle
MS Windows "core" font faces. It is passed to C<SVGPDF-E<gt>new()>.

Note that some supporting packages, such as GnuPlot, make use of Windows fonts 
such as B<Arial>, which may or may not be installed on non-Windows platforms, 
and even for Windows, would need to be added to FontManager. You should check 
the resulting SVG files produced by Third-Party packages to see what fonts 
they are expecting. MathJax creates text characters as filled outlines in SVG,
and does not appear to use any standard fonts.

=item combine => 'method'

If there are multiple XObjects defined by an SVG (due to multiple C<svg>
entries), they may be combined into a single XObject. The default is B<none>,
which does I<not> combine XObjects. Currently, the only other supported method 
is B<stacked>, which vertically stacks images, with C<sep> spacing between
them. At this writing, the B<bbox> combine method is I<not> supported by
SVGPDF, but may be in the future. It is passed to C<$svg-E<gt>process()>.

=item sep => n

Vertical space (in points) to add between individual images when C<combine> is 
not 'none'. The default is 0 (no space between images). 
It is passed to C<$svg-E<gt>process()>.

=back

=back

=head3 What is returned

Returns an image in the SVG. Unlike other image formats, it is I<not> actually
some form of image object, but an array (of at least one element) containing 
XObjects of the SVG converted into PDF graphics and text commands. If an SVG 
includes a pixel-based image, that image will be scaled up and down in the 
normal image way, while PDF graphics and text are always fully scalable, both 
when setting an image size I<and> when zooming in and out in a PDF Reader.

A returned "object" is always an array of hashes (including the XObject as one
of the elements), one per C<svg> tag. Note that C<svg>s must be peers 
(top-level), and may B<not> be nested one within another! In most applications, 
an SVG file will have one C<svg> tag and thus a single element in the array.
However, some SVGs will produce multiple array elements from multiple C<svg>
tags. 

=head3 Dealing with multiple image objects, and combining them

If you don't set C<subimage>, the full array will be returned. If
you set C<subimage =E<gt> n>, where I<n> is a valid element number (0...), all
elements I<except> the n-th will be discarded, leaving a single element array.
When it comes time for C<object()> to display this XObject array, the first 
(0th) element will be displayed, and any other elements will be ignored. Thus, 
the default behavior is effectively C<subimage =E<gt> 0>. You may call either 
C<object> or C<image>, as C<image> will simply pass everything on to C<object>.

Remember that I<not> setting C<subimage> will cause the entire array to be 
returned. You are free to rearrange and/or subset this array, if you wish.
If you want to display (in the PDF) multiple images, you can select one or more
of the array elements to be processed (see the examples). If you want to stack
all of them vertically, perhaps with some space between them, consider using
the C<combine =E<gt> 'stacked'> option, but be aware that the total height of
the single resulting image may be too large for your page! You may need to
output them separately, as many as will fit on a page.

This leaves the possibility of I<overlaying> multiple images to overlap in one
large combined image. You have the various width and height (and bounding box
coordinates), so it I<is> possible to align images to have the same origin.
SVGPDF I<may> get C<combine =E<gt> 'bbox'> at some point in the future, to
automate this, but for the time being you need to do it yourself. Keep an eye
out for different C<svg>s scaled at different sizes; they may need rescaling
to overlay properly.

=cut

# -------------------------------------------------------------------
# produce an array of XObject hashes describing one or more <svg> tags in
# the input, by calling SVGPDF new() and process(). if 'subimage' is given,
# discard all other array elements.
sub new {
    my ($class, $pdf, $file, %opts) = @_;

    my $verbose  = $opts{'verbose'}  || 0;
    my $fontsz   = $opts{'fontsize'} || 12;
    my $callbacks = $opts{'fc'}; # either routine or array ref of routines

    my $subimage = $opts{'subimage'};
    my $MScore   = $opts{'MScore'}   || 0;
    if ($MScore) { # TBD
    }

    # delete modified options
    delete $opts{'verbose'};
    delete $opts{'fontsize'};

    # TBD for 'display' SVG's with tags, remove tag (nested <svg>) and
    #     deal with separately. must remove before call new(). might extract
    #     back in Builder.pm (image_svg) and could let high-level code in
    #     examples/SVG.pl handle its placement? or possibly as separate array
    #     element (if includes sufficient positioning information).

    my $svg;
    if ($MScore) {
        if (defined $callbacks) {
    	    # existing callback(s) to add MScore processing to
            delete $opts{'fc'};
	    $callbacks = [ ($callbacks), &MScoreCB ];
            $svg = SVGPDF->new( 'pdf'=>$pdf, 'verbose'=>$verbose, 
		                'fc'=>$callbacks,
 	                        'fontsize'=>$fontsz, %opts );
        } else {
	    # no existing callback(s) in %opts to add MScore processing to
	    $callbacks = \&MScoreCB;
            $svg = SVGPDF->new( 'pdf'=>$pdf, 'verbose'=>$verbose, 
		                'fc'=>$callbacks,
 	                        'fontsize'=>$fontsz, %opts );
        }
    } else {
	# not adding MScore, any existing callbacks still in %opts
        $svg = SVGPDF->new( 'pdf'=>$pdf, 'verbose'=>$verbose,
 	                    'fontsize'=>$fontsz, %opts );
    }

    my $xof = $svg->process($file, 'fontsize'=>$fontsz, %opts);
    # $xof is anonymous array ref with one element per <svg> (should be
    # at minimum, one), and each element is a hash of width, vwidth,
    # height, vheight, vbox, bbox(), and the xobject itself, xo

    # if subimage given, return only that subimage (0th if invalid number)
    if (defined $subimage) {
	my @array = @$xof;
	if ($subimage < 0 || $subimage > $#array ) {
	    carp "Invalid subimage number ignored, using 0";
	    $subimage = 0;
	}
	$xof = [ $array[$subimage] ];
    }

    return $xof;
}

# -------------------------------------------------------------------
# sample font callback to implement MS Windows core font extensions.
# enable for all OSs, not just $^O eq 'MSWin32'.
sub MScoreCB {
    my ($self, %args) = @_;
    my $pdf = $args{'pdf'};

    my $family = $args{'style'}->{'font-family'};
    my $style  = $args{'style'}->{'font-style'};
    my $weight = $args{'style'}->{'font-weight'};
    my $fontsz = $args{'style'}->{'font-size'}; # ignored

    my $font;
    my $Wfam = '';
    # check $family requested and style and weight, return a font object
    # via FontManager
    if ($family =~ m/^Verdana/i) { $Wfam = 'Verdana'; }
    if ($family =~ m/^Georgia/i) { $Wfam = 'Georgia'; }
    if ($family =~ m/^Trebuchet/i) { $Wfam = 'Trebuchet'; }
    if ($family =~ m/^Wingdings/i) { $Wfam = 'Wingdings'; }
    if ($family =~ m/^Webdings/i) { $Wfam = 'Webdings'; }
    if ($Wfam ne '') {
	# acceptable Windows "core" font names
	
	# if includes Bold and/or Italic, override $weight and $style
	if ($family =~ m/Bold/i) { $weight = 'bold'; }
	if ($family =~ m/Italic/i) { $style = 'italic'; }
	if ($family =~ m/Oblique/i) { $style = 'italic'; }
	# Wingdings and Webdings NOT bold or italic
	if ($Wfam eq 'Wingdings' || $Wfam eq 'Webdings') {
	    $style = 'normal'; 
	    $weight = 'normal';
	}
	$style = lc($style);
	$weight = lc($weight);
	# core only supports two styles: normal and italic
	# TBD 'oblique' with optional number of degrees is apparently valid 
	#   CSS, so need to be more general in FontManager
	if ($style eq 'oblique' || $style eq 'slant' || $style eq 'slanted') {
	    $style = 'italic'; 
        } else {
	    $style = 'normal'; 
        }
	# core only supports two weights: normal and bold
	# following lists standard CSS names and numeric weights
	# TBD other weight names and numbers HAVE been seen in the wild, also
	#   'bolder' and 'lighter', so need to be more general in FontManager
	if ($weight eq 'normal' || $weight eq 'regular' || $weight eq '400' ||
	    $weight eq 'thin' || $weight eq 'hairline' || $weight eq '100' ||
	    $weight =~ m/^extra\s+light$/ || $weight =~ m/^ultra\s+light$/ || 
	    $weight eq '200' ||
	    $weight eq 'light' || $weight eq '300' || 
	    $weight eq 'medium' || $weight eq '500') {
	    $weight = 'normal';
	} elsif ($weight eq 'bold' || $weight eq '700' ||
	    $weight =~ m/^semi\s+bold$/ || $weight =~ m/^demi\s+bold$/ || 
	    $weight eq '600' ||
	    $weight =~ m/^extra\s+bold$/ || $weight =~ m/^ultra\s+bold$/ || 
	    $weight eq '800' ||
	    $weight eq 'black' || $weight eq 'heavy' || $weight eq '900') {
	    $weight = 'bold';
	} else {
	    # who knows... not a standard designation
	    $weight = 'bold';
	}

	$font = $pdf->get_font('face' => $family,
	    'italic' => ($style eq 'italic')? 1:0,
	    'bold' => ($weight eq 'bold')? 1:0);
    }
    
    return $font;
} # end of MScoreCB()

1;
