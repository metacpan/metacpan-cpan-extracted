package PDF::Builder::Annotation;

use base 'PDF::Builder::Basic::PDF::Dict';

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.028'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;
use List::Util qw(min max);
use Carp;

=head1 NAME

PDF::Builder::Annotation - Add annotations to a PDF

Inherits from L<PDF::Builder::Basic::PDF::Dict>

=head1 SYNOPSIS

An "annotation" is an extra feature on a page that may change the appearance
(e.g., highlighting), or perform some action when
clicked on. Some actions may require a single click and others a double click;
this depends on the PDF Reader used. Some may warn you and/or ask permission
to perform a certain action, while others may refuse to do something (which
may be configurable).

    my $pdf = PDF::Builder->new();
    my $font = $pdf->font('Helvetica');
    my $page1 = $pdf->page();
    my $page2 = $pdf->page();

    my $content = $page1->text();
    my $message = 'Go to Page 2';
    my $size = 18;

    $content->distance(1 * 72, 9 * 72);
    $content->font($font, $size);
    $content->text($message);

    my $annotation = $page1->annotation();
    my $width = $content->text_width($message);
    $annotation->rect(1 * 72, 9 * 72, 1 * 72 + $width, 9 * 72 + $size);
    $annotation->link($page2);

    $pdf->save('sample.pdf');

=head1 METHODS

Note that the handling of annotations can vary from Reader to Reader. The
available icon set may be larger or smaller than given here, and some Readers
activate an annotation on a single mouse click, while others require a double
click. Not all features provided here may be available on all PDF Readers.
In particular, Named Destinations seem to be handled in widely varying ways!

=head2 new

    $annotation = PDF::Builder::Annotation->new()

=over

Returns an annotation object (called from $page->annotation()).

It is normally I<not> necessary to explicitly call this method (see examples).

=back

=cut

# %opts removed, as there are currently none
sub new {
    my $class = shift;

    my $self = $class->SUPER::new();
    $self->{'Type'}   = PDFName('Annot');
    $self->{'Border'} = PDFArray(PDFNum(0), PDFNum(0), PDFNum(0)); # no border

    return $self;
}

#sub outobjdeep {
#    my ($self, @opts) = @_;
#
#    foreach my $k (qw[ api apipdf apipage ]) {
#        $self->{" $k"} = undef;
#        delete($self->{" $k"});
#    }
#    return $self->SUPER::outobjdeep(@opts);
#}

# ============== start of annotation types =======================

# note that %opts is given as the only format in most cases, as rect
# is a mandatory "option"

=head2 Common parameters

For the annotation calls given below, all require a clickable rectangular area 
(button) on the page to activate the call. These all share common parameters to 
define this "button". Note that I<your> code is responsible for creating the 
visible content of the button (if any), while the 'rect' parameter tells the 
annotation what (invisible) area on the page activates it, and the 'border' 
and 'color' parameters describe the border drawn around the button.

Note that this is in contrast to C<NamedDestination>, which ignores any of
these entries, as it does not define a "button" to press.

    'rect'   => [ LLx,LLy, URx,URy ]

This defines the rectangle of the "button". Your code is responsible for any
fill or text visible to the user, via normal text and graphics calls.
As an alternative (mandatory if 'rect' is not given), you may
specify the rectangle with the C<$ann-E<gt>rect(LLx,LLy, URx,URy);> call.
I<Note:> the other diagonals (UL to LR, LR to UL, UR to LL) are usually allowed.

Instead of this hash element being used, the 

    $ann->rect( LLx,LLy, URx,URy )

method may be used (I<before> the annotation method itself is invoked).

    'border' => [ Rx,Ry, w, [dash-pattern] ]

This defines the border around the button. If not given, the default is 
[ 0, 0, 1 ]. Rx and Ry are corner radii (0 for sharp corners), I<w> is the
stroke width (0 for no visible border), and an optional dash-pattern may be 
given to draw something other than a solid line (e.g., [5, 5] for a 5pt long
dash and 5pt space pattern). Note that the square brackets [ ] are actually
used, as the dash-pattern is an anonymous array.

Instead of this hash element being used, the

    $ann->border(Rx,Ry, w, [dash-pattern]) 

method may be used (I<before> the annotation method itself is invoked).

    'color'  => [ Red, Green, Blue ]

This defines the stroke color of the button border, using the RGB triplet way
of describing a color (RGB anonymous array, each value 0 to 1). 
If 0 width does not work on all Readers to suppress the border, selecting a 
color that matches any fill or background color in the button may work instead.

Instead of this hash element being used, the

    $ann->Color(Red, Green, Blue)

method may be used (I<before> the annotation method itself is invoked). Note
that Color is capitalized, unlike the hash option method.

It's a matter of stylistic choice whether to give these settings as options
to the annotation object in the call, or call their methods directly I<before> 
the annotation action method itself is called.

Some calls have additional optional parameters, which will be described in
their section.

=head2 Annotation types

=head3 goto, link

    $annotation->goto($page, $location, @args, %opts) # preferred

    $annotation->goto($page, %opts)  # location info as a hash element

=over

Defines the annotation as a PDF launch-page with page object C<$page> (within 
I<this> document), 'fit', and opts %opts (common parameters and optionally 
I<fit>: see descriptions below).

B<Note> that C<$page> is I<not> a simple page number, but is either a page 
I<object> such as C<$pdf-E<gt>openpage(page_number)>, I<or> a Named 
Destination defined elsewhere (a prefix of '#' or '/' is optional, except when 
the Named Destination is entirely numeric, and then it is required). 'foo', 
'#foo', and '/3659' are examples of Named Destinations.
If a Named Destination is given, the page fit (location) is ignored, as the 
Named Destination handles that.

Note that the I<options> %opts is a hash, permitting 'rect', 'border', and 
'color' to be described in a more natural manner than flattening the hash into 
an array. The location and its arguments (fit data) may be either a list
(in the PDF::API2 style) or another hash element.

B<Alternate name:> C<link>

Originally this method was named C<link>, but PDF::API2 changed it to
C<goto>, to correspond to the B<GoTo> PDF command used. For compatibility, it 
has been changed to C<goto>, with C<link> still available as an alias.

=back

=cut

# this nonsense seems to be necessary (to alias goto with link) because
# Perl gets confused and thinks it's a "goto label" statement!
sub link {   ## no critic
    my $self = shift;
    return $self->goto(@_); }

sub goto { 
    my ($self, $page, @args) = @_;
    # page may be a page object, or a Named Destination string
    # if location and its parms are a list, made a hash element,
    # like any rect/color/border hash elements

    # dest() will process it again, but we need hash for button settings
    my %opts = PDF::Builder::NamedDestination->list2hash(@args);
    $self->{'Subtype'}  = PDFName('Link');
    $self->{'A'}        = PDFDict();
    $self->{'A'}->{'S'} = PDFName('GoTo');
    if (ref($page)) {
	# page structure
        $self->{'A'}->{'D'} = 
	   PDF::Builder::NamedDestination->dest($page, %opts);  
           # fit type and parameters in args
    } else {
	# named destination
	# strip off any # or /, make sure it's a string
	if ($page =~ /^[#\/](.+)/) {
            $page = "$1";
	}
	$self->{'A'}->{'D'} = PDFString($page, 'n');
    }

    # click area rectangle (button)
    $self->rect(@{$opts{'rect'}}) if defined $opts{'rect'};
    $self->border(@{$opts{'border'}}) if defined $opts{'border'};
    $self->Color(@{$opts{'color'}}) if defined $opts{'color'};

    return $self;
}

=head3 pdf, pdfile, pdf_file

    $annotation->pdf($pdffile, $page_number, $location, @args, %opts) # preferred

    $annotation->pdf($pdffile, $page_number, %opts) # including location & data

=over

Defines the annotation as an B<external> PDF-file with filepath C<$pdffile>, 
on page C<$page_number>, and options %opts (common parameters and I<fit>: see 
descriptions below). This differs from the C<goto> call in that the target 
is found in a I<different> PDF file, not the current document. Your operating
system may warn you that you are going to a different file.

C<$page_number> is the physical page number, starting at 1: 1, 2,..., I<or> a 
Named Destination defined in that document (a prefix of '#' or '/' is optional, 
except when the Named Destination is entirely numeric, and then it is 
required). 'foo', '/foo', and '#3659' are examples of Named Destinations.
If a Named Destination is used, the page fit (location) is ignored, as the 
Named Destination handles that.

Note that the I<options> %opts is a hash, while the location and fit @args 
may be described as a list (PDF::API2 style), or as another hash element.
This permits 'rect', 'border', and 'color' to be
described in a more natural manner than flattening the hash into an array.

B<Alternate names:> C<pdfile> and C<pdf_file>

Originally this method was named C<pdfile>, and then C<pdf_file> but 
PDF::API2 changed it to C<pdf>. For compatibility, it has been changed to 
C<pdf>, with C<pdfile> and C<pdf_file> still available as aliases.

=back

=cut

sub pdfile { return pdf(@_); } ## no critic 
sub pdf_file { return pdf(@_); } ## no critic 

sub pdf {
    # page may be a page number, or a Named Destination string
    # args include location and its parms as either hash element or a list,
    # and optionally (if not set externally), rect/color/border hash elements

    my ($self, $file, $page_number, @args) = @_;
    # dest() will process it again, but we need hash for button settings
    my %opts = PDF::Builder::NamedDestination->list2hash(@args);

    $self->{'Subtype'}  = PDFName('Link');
    $self->{'A'}        = PDFDict();
    $self->{'A'}->{'S'} = PDFName('GoToR');
    $self->{'A'}->{'F'} = PDFString($file, 'u');

    # if an integer $page_number, /D [page_num fit]
    if ($page_number =~ /^\d+$/) {
        $page_number--;  # wants it numbered starting at 0
        $self->{'A'}->{'D'} = 
	    PDF::Builder::NamedDestination->dest($page_number, %opts); 
            # fit info opts
    } else {
	# string 'page_number' is a Named Destination, /D (foo)
	# any prefix of '#' or '/' will be stripped off
	if ($page_number =~ /^[#\/](.+)$/) {
	    $page_number = "$1"; # if all numeric, make sure it's a string
	}
        $self->{'A'}->{'D'} = PDFString("$page_number", 'n');
    }

    $self->rect(@{$opts{'rect'}}) if defined $opts{'rect'};
    $self->border(@{$opts{'border'}}) if defined $opts{'border'};
    $self->Color(@{$opts{'color'}}) if defined $opts{'color'};

    return $self;
}

=head3 uri, url

    $annotation->uri($url, %opts)

=over

Defines the annotation as a launch-url with url C<$url> and
options %opts (common parameters). 
This page is usually brought up in a browser, and may be remote. This
depends on your operating system configuration.

B<Alternate name:> C<url>

Originally this method was named C<url>, but PDF::API2 changed it to
C<uri> to correspond to the B<URI> PDF command used. For compatibility, it has 
been changed to C<uri>, with C<url> still available as an alias.

=back

=cut

sub url { return uri(@_); } ## no critic

sub uri {
    my ($self, $url, %opts) = @_;
    # copy dashed names over to preferred non-dashed names
    # there are no other options, unlike goto() and pdf(), so no call dest()
    %opts = dashed2nondashed(%opts);

    $self->{'Subtype'}    = PDFName('Link');
    $self->{'A'}          = PDFDict();
    # note that the following code produces /A << /S /URI /URI (url) >>
    $self->{'A'}->{'S'}   = PDFName('URI');
    $self->{'A'}->{'URI'} = PDFString($url, 'u');

    $self->rect(@{$opts{'rect'}}) if defined $opts{'rect'};
    $self->Color(@{$opts{'color'}}) if defined $opts{'color'};
    $self->border(@{$opts{'border'}}) if defined $opts{'border'};

    return $self;
}

=head3 launch, file

    $annotation->launch($file, %opts)

=over

Defines the annotation as a launch-file with filepath C<$file> (a local file,
often an executable or script/batch file)
and options %opts (common parameters). 
I<How> the file is "launched" or displayed depends on the operating system, 
type of file, and local configuration or mapping. Common applications are to
bring up a text editor to display a file, or start a photo viewer.

B<Alternate name:> C<file>

Originally this method was named C<file>, but PDF::API2 changed it to
C<launch> to correspond to the B<Launch> PDF command used. For compatibility, 
it has been changed to C<launch>, with C<file> 
still available as an alias.

=back

=cut

sub file { return launch(@_); } ## no critic

sub launch {
    my ($self, $file, %opts) = @_;
    # copy dashed names over to preferred non-dashed names
    %opts = dashed2nondashed(%opts);

    $self->{'Subtype'}  = PDFName('Link');
    $self->{'A'}        = PDFDict();
    $self->{'A'}->{'S'} = PDFName('Launch');
    $self->{'A'}->{'F'} = PDFString($file, 'f');

    $self->rect(@{$opts{'rect'}}) if defined $opts{'rect'};
    $self->Color(@{$opts{'color'}}) if defined $opts{'color'};
    $self->border(@{$opts{'border'}}) if defined $opts{'border'};

    return $self;
}

=head3 text

    $annotation->text($text, %opts)

=over

Defines the annotation as a text note with content string C<$text> and
options %opts (common parameters, text, open: see descriptions below). 
The C<$text> may include newlines \n for multiple lines. Note that the option 
'border' is ignored, since an I<icon> is used.

The option C<text> is the popup's label string, not to be confused with the 
main C<$text>.

The icon appears in the upper left corner of the C<rect> selection rectangle,
and its active clickable area is fixed by the icon (it is I<not> equal to the 
rectangle). The icon size is fixed, and its fill color set by C<color>.

Additional options:

=back

=over

=item icon => name_string

=item icon => reference

Specify the B<icon> to be used. The default is Reader-specific (usually 
C<Note>), and others may be 
defined by the Reader. C<Comment>, C<Key>, C<Help>, C<NewParagraph>, 
C<Paragraph>, and C<Insert> are also supposed to 
be available on all PDF Readers. Note that the name I<case> must exactly match.
The icon is of fixed size.
Any I<AP> dictionary entry will override the icon setting. 

A I<reference> to an icon may be passed instead of a name.

=item opacity => I<value>

Define the opacity (non-transparency, opaqueness) of the icon. This value
ranges from 0.0 (transparent) to 1.0 (fully opaque), and applies to both
the outline and the fill color. The default is 1.0.

=back

=cut

# the icon size appears to be fixed. the last font size used does not affect it
# and enabling icon_appearance() for it doesn't seem to do anything

sub text {
    my ($self, $text, %opts) = @_;
    # copy dashed names over to preferred non-dashed names
    %opts = dashed2nondashed(%opts);

    $self->{'Subtype'} = PDFName('Text');
    $self->content($text);

    $self->rect(@{$opts{'rect'}}) if defined $opts{'rect'};
    $self->Color(@{$opts{'color'}}) if defined $opts{'color'};
   #$self->border($opts{'border'}) if defined $opts{'border'}; # ignored
    $self->open($opts{'open'}) if defined $opts{'open'};
    # popup label (title)
    # have seen /T as (xFEFF UTF-16 chars)
    $self->{'T'} = PDFString($opts{'text'}, 'p') if exists $opts{'text'};
    # icon opacity?
    if (defined $opts{'opacity'}) {
        $self->{'CA'} = PDFNum($opts{'opacity'});
    }

    # Icon Name will be ignored if there is an AP.
    my $icon;  # perlcritic doesn't want 2 lines combined
    $icon = $opts{'icon'} if exists $opts{'icon'};
    $self->{'Name'} = PDFName($icon) if $icon && !ref($icon); # icon name
    # Set the icon appearance
    $self->icon_appearance($icon, %opts) if $icon;

    return $self;
}

=head3 markup

    $annotation->markup($text, $PointList, $highlight, %opts)

=over

Defines the annotation as a text note with content string C<$text> and
options %opts (color, text, open, opacity: see descriptions below). 
The C<$text> may include newlines \n for multiple lines.

C<text> is the popup's label string, not to be confused with the main C<$text>.

There is no icon. Instead, the annotated text marked by C<$PointList> is
highlighted in one of four ways specified by C<$highlight>. 

=back

=over

=item $PointList => [ 8n numbers ]

One or more sets of numeric coordinates are given, defining the quadrilateral
(usually a rectangle) around the text to be highlighted and selectable
(clickable, to bring up the annotation text). These
are four sets of C<x,y> coordinates, given (for Left-to-Right text) as the 
upper bound Upper Left to Upper Right and then the lower bound Lower Left to 
Lower Right. B<Note that this is different from what is (erroneously)
documented in some PDF specifications!> It is important that the coordinates 
be given in this order.

Multiple sets of quadrilateral corners may be given, such as for highlighted
text that wraps around to new line(s). The minimum is one set (8 numbers).
Any I<AP> dictionary entry will override the C<$PointList> setting. Finally,
the "Rect" selection rectangle is created I<just outside> the convex bounding
box defined by C<$PointList>.

=item $highlight => 'string'

The following highlighting effects are permitted. The C<string> must be 
spelled and capitalized I<exactly> as given:

=over

=item Highlight

The effect of a translucent "highlighter" marker.

=item Squiggly 

The effect is an underline written in a "squiggly" manner.

=item StrikeOut

The text is struck-through with a straight line. 

=item Underline 

The text is marked by a straight underline.

=back

=item color => I<array of values>

If C<color> is not given (an array of numbers in the range 0.0-1.0), a 
medium gray should be used by default. 
Named colors are not supported at this time.

=item opacity => I<value>

Define the opacity (non-transparency, opaqueness) of the icon. This value
ranges from 0.0 (transparent) to 1.0 (fully opaque), and applies to both
the outline and the fill color. The default is 1.0.

=back

=cut

sub markup {
    my ($self, $text, $PointList, $highlight, %opts) = @_;
    # copy dashed names over to preferred non-dashed names
    %opts = dashed2nondashed(%opts);

    my @pointList = @{ $PointList };
    if ((scalar @pointList) == 0 || (scalar @pointList)%8) {
	die "markup point list does not have 8*N entries!\n";
    }
    $self->{'Subtype'} = PDFName($highlight);
    delete $self->{'Border'};
    $self->{'QuadPoints'} = PDFArray(map {PDFNum($_)} @pointList);
    $self->content($text);

    my $minX = min($pointList[0], $pointList[2], $pointList[4], $pointList[6]);
    my $maxX = max($pointList[0], $pointList[2], $pointList[4], $pointList[6]);
    my $minY = min($pointList[1], $pointList[3], $pointList[5], $pointList[7]);
    my $maxY = max($pointList[1], $pointList[3], $pointList[5], $pointList[7]);
    $self->rect($minX-.5,$minY-.5, $maxX+.5,$maxY+.5);

    $self->open($opts{'open'}) if defined $opts{'open'};
    if (defined $opts{'color'}) {
        $self->Color(@{$opts{'color'}});
    } else {
        $self->Color([]);
    }
    # popup label (title)
    # have seen /T as (xFEFF UTF-16 chars)
    $self->{'T'} = PDFString($opts{'text'}, 'p') if exists $opts{'text'};
    # opacity?
    if (defined $opts{'opacity'}) {
        $self->{'CA'} = PDFNum($opts{'opacity'});
    }

    return $self;
}

=head3 movie

    $annotation->movie($file, $contentType, %opts)

=over

Defines the annotation as a movie from C<$file> with 
content (MIME) type C<$contentType> and
options %opts (common parameters, text: see descriptions below).

The C<rect> rectangle B<also serves as the area where the movie is played>, so 
it should be of usable size and aspect ratio. It does not use a separate popup
player. It is known to play .avi and .wav files -- others have not been tested.
Using Adobe Reader, it will not play .mpg files (unsupported type). More work
is probably needed on this annotation method.

=back

=cut

sub movie {
    my ($self, $file, $contentType, %opts) = @_;
    # copy dashed names over to preferred non-dashed names
    %opts = dashed2nondashed(%opts);

    $self->{'Subtype'}      = PDFName('Movie'); # subtype = movie (req)
    $self->{'A'}            = PDFBool(1); # play using default activation parms
    $self->{'Movie'}        = PDFDict();
   #$self->{'Movie'}->{'S'} = PDFName($contentType);
    $self->{'Movie'}->{'F'} = PDFString($file, 'f');

# PDF::API2 2.034 changes don't seem to work
#    $self->{'Movie'}->{'F'} = PDFString($file, 'f'); line above removed
#$self->{'Movie'}->{'F'} = PDFDict();
#$self->{' apipdf'}->new_obj($self->{'Movie'}->{'F'});
#my $f = $self->{'Movie'}->{'F'};
#$f->{'Type'}    = PDFName('EmbeddedFile');
#$f->{'Subtype'} = PDFName($contentType);
#$f->{' streamfile'} = $file;

    $self->rect(@{$opts{'rect'}}) if defined $opts{'rect'};
    $self->border(@{$opts{'border'}}) if defined $opts{'border'};
    $self->Color(@{$opts{'color'}}) if defined $opts{'color'};
    # popup label (title)  DOESN'T SEEM TO SHOW UP ANYWHERE
    #  self->A->T and self->T also fail to display
    $self->{'Movie'}->{'T'} = PDFString($opts{'text'}, 'p') if exists $opts{'text'};

    return $self;
}

=head3 file_attachment

    $annotation->file_attachment($file, %opts)

=over

Defines the annotation as a file attachment with file $file and options %opts
(common parameters: see descriptions below). Note that C<color> applies to
the icon fill color, not to a selectable area outline. The icon is resized
(including aspect ratio changes) based on the selectable rectangle given by
C<rect>, so watch your rectangle dimensions!

The file, along with its name, is I<embedded> in the PDF document and may be
extracted for viewing with the appropriate viewer.

This differs from the C<file> method in that C<file> looks for and launches
a file I<already> on the Reader's machine, while C<file_attachment> embeds the 
file in the PDF, and makes it available on the Reader's machine for actions
of the user's choosing. 

B<Note 1:> some Readers may only permit an "open" action, and may also restrict 
file types (extensions) that will be handled. This may be configurable with
your Reader's security settings.

B<Note 2:> the displayed file name (pop-up during mouse rollover of the target 
rectangle) is given with the I<path> trimmed off (file name only). If you want
the displayed name to exactly match the path that was passed to the call, 
including the path, give the C<notrimpath> option.

Options: 

=back

=over 

=item icon => name_string

=item icon => reference

Specify the B<icon> to be used. The default is Reader-specific (usually 
C<PushPin>), and others may be 
defined by the Reader. C<Paperclip>, C<Graph>, and C<Tag> are also supposed to 
be available on all PDF Readers. Note that the name I<case> must exactly match.
C<None> is a custom invisible icon defined by PDF::Builder.
The icon is stretched/squashed to fill the defined target rectangle, so take
care when defining C<rect> dimensions.
Any I<AP> dictionary entry will override the icon setting. 

A I<reference> to an icon may be passed instead of a name.

=item opacity => I<value>

Define the opacity (non-transparency, opaqueness) of the icon. This value
ranges from 0.0 (transparent) to 1.0 (fully opaque), and applies to both
the outline and the fill color. The default is 1.0.

=item notrimpath => 1

If given, show the entire path and file name on mouse rollover, rather than
just the file name.

=item text => string

A text label for the popup (on mouseover) that contains the file name.

=back

Note that while PDF permits different specifications (paths) to DOS/Windows,
Mac, and Unix (including Linux) versions of a file, and different format copies 
to be embedded, at this time PDF::Builder only permits a single file (format of
your choice) to be embedded. If there is user demand for multiple file formats
to be referenced and/or embedded, we could look into providing this, I<although
separate OS version paths B<may> be considered obsolescent!>.

=cut

# TBD it is possible to specify different files for DOS, Mac, Unix
#     (see PDF 1.7 7.11.4.2). This might solve problem of different line
#     ends, at the cost of 3 copies of each file.

sub file_attachment {
    my ($self, $file, %opts) = @_;
    # copy dashed names over to preferred non-dashed names
    %opts = dashed2nondashed(%opts);

    my $icon;  # defaults to Reader's default (usually PushPin)
    $icon = $opts{'icon'} if exists $opts{'icon'};

    $self->rect(@{$opts{'rect'}}) if defined $opts{'rect'};
    # descriptive text on mouse rollover
    $self->{'T'} = PDFString($opts{'text'}, 'p') if exists $opts{'text'};
    # icon opacity?
    if (defined $opts{'opacity'}) {
        $self->{'CA'} = PDFNum($opts{'opacity'});
    }

    $self->{'Subtype'} = PDFName('FileAttachment');

    # 9 0 obj <<
    #    /Type /Annot
    #    /Subtype /FileAttachment
    #    /Name /PushPin
    #    /C [ 1 1 0 ]
    #    /Contents (test.txt)
    #    /FS <<
    #        /Type /F
    #        /EF << /F 10 0 R >>
    #        /F (test.txt)
    #    >>
    #    /Rect [ 100 100 200 200 ]
    #    /Border [ 0 0 1 ]
    # >> endobj
    #
    # 10 0 obj <<
    #    /Type /EmbeddedFile
    #    /Length ...
    # >> stream
    # ...
    # endstream endobj

    # text label on pop-up for mouse rollover
    my $cName = $file;
    # trim off any path, leaving just the file name. less confusing that way
    if (!defined $opts{'notrimpath'}) {
        if ($cName =~ m#([^/\\]+)$#) { $cName = $1; }
    }
    $self->{'Contents'} = PDFString($cName, 's');

    # Icon Name will be ignored if there is an AP.
    $self->{'Name'} = PDFName($icon) if $icon && !ref($icon); # icon name
   #$self->{'F'} = PDFNum(0b0);  # flags default to 0
    $self->Color(@{ $opts{'color'} }) if defined $opts{'color'};

    # The File Specification.
    $self->{'FS'} = PDFDict();
    $self->{'FS'}->{'F'} = PDFString($file, 'f');
    $self->{'FS'}->{'Type'} = PDFName('Filespec');
    $self->{'FS'}->{'EF'} = PDFDict($file);
    $self->{'FS'}->{'EF'}->{'F'} = PDFDict($file);
    $self->{' apipdf'}->new_obj($self->{'FS'}->{'EF'}->{'F'});
    $self->{'FS'}->{'EF'}->{'F'}->{'Type'} = PDFName('EmbeddedFile');
    $self->{'FS'}->{'EF'}->{'F'}->{' streamfile'} = $file;

    # Set the icon appearance
    $self->icon_appearance($icon, %opts) if $icon;

    return $self;
}

# TBD additional annotation types without icons
# free text, line, square, circle, polygon (1.5), polyline (1.5), highlight,
# underline, squiggly, strikeout, caret (1.5), ink, popup, sound, widget, 
# screen (1.5), printermark, trapnet, watermark (1.6), 3D (1.6), redact (1.7)

# TBD additional annotation types with icons
# stamp
# icons: Approved, Experimental, NotApproved, Asis, Expired, 
#        NotForPublicRelease, Confidential, Final, Sold, Departmental, 
#        ForComment, TopSecret, Draft (def.), ForPublicRelease
# sound
# icons: Speaker (def.), Mic

# =============== end of annotation types ========================

=head2 Internal routines and common options

The common options may be called separately (applied against $annotation before
calling the action routine), or passed as options to the call.

=head3 rect

    $annotation->rect($llx,$lly, $urx,$ury)

=over

Sets the rectangle (active click area) of the annotation, given by 'rect' 
option. This is any pair of diagonally opposite corners of the rectangle.

The default clickable area is the icon itself.

Defining option. I<Note that this "option" is actually B<required>.>

I<This call may be replaced by a hash element 'rect'=E<gt> in many calls
(see Common parameters).>

=back

=over

=item rect => [LLx, LLy, URx, URy]

Set annotation rectangle I<as an option> at C<[LLx,LLy]> to C<[URx,URy]> 
(lower left and upper right coordinates). 
LL to UR is customary, but any diagonal is allowed.

=back

=cut

sub rect {
    my ($self, @r) = @_;

    die "Insufficient parameters to annotation->rect() " unless scalar @r == 4;
    $self->{'Rect'} = PDFArray( map { PDFNum($_) } $r[0],$r[1],$r[2],$r[3]);
    return $self;
}

=head3 border

    $annotation->border(@b)

=over

Sets the border-style of the annotation, if applicable, as given by the
border option. There are three entries in the array:
horizontal and vertical corner radii, and border width.
An optional fourth entry (described below) may be used for a dashed or dotted
line.

A border is used in annotations where text or some other material is put down,
and a clickable rectangle is defined over it (rect). A border is not shown
when an B<icon> is being used to mark the clickable area.

A I<PDF Reader> normally defaults to [0 0 1] (solid line of width 1, with 
sharp corners) if no border (C</Border>) is specified. Keeping compatibility
with PDF::API2's longstanding practice, PDF::Builder defaults to no visible
border C<[0 0 0]> (solid line of width 0, and thus invisible).

Defining option:

=back

=over

=item border => [CRh, CRv, W]

=item border => [CRh, CRv, W, [on, off...]]

Note that the square brackets [ and ] are literally I<there>, indicating a 
vector or array of values. They do B<not> indicate optional values!

Set annotation B<border style> of horizontal and vertical corner radii C<CRh> 
and C<CRv> (value 0 for squared corners) and width C<W> (value 0 for no border).
The PDF::Builder default is no border (while a I<PDF Reader> typically defaults
to no border ([0 0 0]), if no /Border entry is given).
Optionally, a dash pattern array may be given (C<on> length, C<off> length,
as one or more I<pairs>). The default is a solid line.

The border vector seems to ignore the first two settings (corner radii), but 
the line thickness works, on basic Readers. 
The corner radii I<may> work on some other Readers.

=back

I<This call may be replaced by a hash element 'border'=E<gt> in many calls
(see Common parameters).>

=cut

sub border {
    my ($self, @b) = @_;

    if      (scalar @b == 3) {
        $self->{'Border'} = PDFArray( map { PDFNum($_) } $b[0],$b[1],$b[2]);
    } elsif (scalar @b == 4) {
	# b[3] is an anonymous array
	my @first = map { PDFNum($_) } $b[0], $b[1], $b[2];
        $self->{'Border'} = PDFArray( @first, PDFArray( map { PDFNum($_) } @{$b[3]} ));
    } else {
        die "annotation->border() style requires 3 or 4 parameters ";
    }
    return $self;
}

=head3 Color

    $annotation->Color(@color)

=over

Set the icon's fill color I<or> the click area's border color. The color is 
an array of 1, 3, or 4 numbers, each
in the range 0.0 to 1.0. If 1 number is given, it is the grayscale value (0 = 
black to 1 = white). If 3 numbers are given, it is an RGB color value. If 4
numbers are given, it is a CMYK color value. Currently, named colors (strings)
are not handled.

For link and url annotations, this is the color of the rectangle border 
(border given with a width of at least 1).

If an invalid array length or numeric value is given, a medium gray ( [0.5] ) 
value is used, without any message. If no color is given, the usual fill color
is black.

Defining option:

Named colors (e.g., 'black') are not supported at this time.

=back

=over

=item color => [ ] or not 1, 3, or 4 numbers 0.0-1.0

A medium gray (0.5 value) will be used if an invalid color is given.

=item color => [ g ]

If I<g> is between 0.0 (black) and 1.0 (white), the fill color will be gray.

=item color => [ r, g, b ]

If I<r> (red), I<g> (green), and I<b> (blue) are all between 0.0 and 1.0, the 
fill color will be the defined RGB hue. [ 0, 0, 0 ] is black, [ 1, 1, 0 ] is
yellow, and [ 1, 1, 1 ] is white.

=item color => [ c, m, y, k ]

If I<c> (red), I<m> (magenta), I<y> (yellow), and I<k> (black) are all between 
0.0 and 1.0, the fill color will be the defined CMYK hue. [ 0, 0, 0, 0 ] is
white, [ 1, 0, 1, 0 ] is green, and [ 1, 1, 1, 1 ] is black.

=back

I<This call may be replaced by a hash element 'color'=E<gt> in many calls
(see Common parameters).>

=cut

sub Color {
    my ($self, @color) = @_;

    if      (scalar @color == 1 &&
             $color[0] >= 0 && $color[0] <= 1.0) {
        $self->{'C'} = PDFArray(map { PDFNum($_) } $color[0]);
    } elsif (scalar @color == 3 &&
             $color[0] >= 0 && $color[0] <= 1.0 &&
             $color[1] >= 0 && $color[1] <= 1.0 &&
             $color[2] >= 0 && $color[2] <= 1.0) {
        $self->{'C'} = PDFArray(map { PDFNum($_) } $color[0], $color[1], $color[2]);
    } elsif (scalar @color == 4 &&
             $color[0] >= 0 && $color[0] <= 1.0 &&
             $color[1] >= 0 && $color[1] <= 1.0 &&
             $color[2] >= 0 && $color[2] <= 1.0 &&
             $color[3] >= 0 && $color[3] <= 1.0) {
        $self->{'C'} = PDFArray(map { PDFNum($_) } $color[0], $color[1], $color[2], $color[3]);
    } else {
        # invalid color entry. just set to medium gray without message
        $self->{'C'} = PDFArray(map { PDFNum($_) } 0.5 );
    }

    return $self;
}

=head3 content

    $annotation->content(@lines)

=over

Sets the text-content of the C<text()> annotation.
This is a text string or array of strings.

=back

=cut

sub content {
    my ($self, @lines) = @_;
    my $text = join("\n", @lines);
    
    $self->{'Contents'} = PDFString($text, 's');
    return $self;
}

# unused internal routine? TBD
sub name {
    my ($self, $name) = @_;
    $self->{'Name'} = PDFName($name);
    return $self;
}

=head3 open

    $annotation->open($bool)

=over

Display the C<text()> annotation either open or closed, if applicable.

Both are editable; the "open" form brings up the page with the entry area
already open for editing, while "closed" has to be clicked on to edit it.

Defining option:

=back

=over

=item open => boolean

If true (1), the annotation will be marked as initially "open".
If false (0), or the option is not given, the annotation is initially "closed".

=back

=cut

sub open {  ## no critic
    my ($self, $bool) = @_;
    $self->{'Open'} = PDFBool($bool? 1: 0);
    return $self;
}

=head3 text string

    'text' => string

=over

Specify an optional B<text label> for annotation. This text or comment only
shows up I<as a title> in the pop-up containing the file or text.

=back

=cut

sub icon_appearance {
    my ($self, $icon, %opts) = @_;
    # $icon is a string with name of icon (confirmed not empty) or a reference.
    # if a string (text), has already defined /Name. "None" and ref handle here.
    # options of interest: rect (to define size of icon)

    # copy dashed names over to preferred non-dashed names
    if (defined $opts{'-rect'} && !defined $opts{'rect'}) { $opts{'rect'} = delete($opts{'-rect'}); }
    
   # text also permits icon and custom icon, including None
   #return unless $self->{'Subtype'}->val() eq 'FileAttachment';

    my @r;  # perlcritic doesn't want 2 lines combined
    @r = @{$opts{'rect'}} if defined $opts{'rect'};
    # number of parameters should be 4, checked above (rect method)

    # Handle custom icon type 'None' and icon reference.
    if      ($icon eq 'None') {
        # It is not clear what viewers will do, so provide an
        # appearance dict with no graphics content.

	# 9 0 obj <<
	#    ...
	#    /AP << /D 11 0 R /N 11 0 R /R 11 0 R >>
	#    ...
	# >>
	# 11 0 obj <<
	#    /BBox [ 0 0 100 100 ]
	#    /FormType 1
	#    /Length 6
	#    /Matrix [ 1 0 0 1 0 0 ]
	#    /Resources <<
	#        /ProcSet [ /PDF ]
	#    >>
	# >> stream
	# 0 0 m
	# endstream endobj

	$self->{'AP'} = PDFDict();
	my $d = PDFDict();
	$self->{' apipdf'}->new_obj($d);
	$d->{'FormType'} = PDFNum(1);
	$d->{'Matrix'} = PDFArray(map { PDFNum($_) } 1, 0, 0, 1, 0, 0);
	$d->{'Resources'} = PDFDict();
	$d->{'Resources'}->{'ProcSet'} = PDFArray( map { PDFName($_) } qw(PDF));
	$d->{'BBox'} = PDFArray( map { PDFNum($_) } 0, 0, $r[2]-$r[0], $r[3]-$r[1] );
	$d->{' stream'} = "0 0 m";
	$self->{'AP'}->{'N'} = $d;	# normal appearance
	# Should default to N, but be sure.
	$self->{'AP'}->{'R'} = $d;	# Rollover
	$self->{'AP'}->{'D'} = $d;	# Down

    # Handle custom icon.
    } elsif (ref $icon) {
        # Provide an appearance dict with the image.

	# 9 0 obj <<
	#    ...
	#    /AP << /D 11 0 R /N 11 0 R /R 11 0 R >>
	#    ...
	# >>
	# 11 0 obj <<
	#    /BBox [ 0 0 1 1 ]
	#    /FormType 1
	#    /Length 13
	#    /Matrix [ 1 0 0 1 0 0 ]
	#    /Resources <<
	#        /ProcSet [ /PDF /Text /ImageB /ImageC /ImageI ]
	#        /XObject << /PxCBA 7 0 R >>
	#    >>
	# >> stream
	# q /PxCBA Do Q
	# endstream endobj

	$self->{'AP'} = PDFDict();
	my $d = PDFDict();
	$self->{' apipdf'}->new_obj($d);
	$d->{'FormType'} = PDFNum(1);
	$d->{'Matrix'} = PDFArray(map { PDFNum($_) } 1, 0, 0, 1, 0, 0);
	$d->{'Resources'} = PDFDict();
	$d->{'Resources'}->{'ProcSet'} = PDFArray(map { PDFName($_) } qw(PDF Text ImageB ImageC ImageI));
	$d->{'Resources'}->{'XObject'} = PDFDict();
	my $im = $icon->{'Name'}->val();
	$d->{'Resources'}->{'XObject'}->{$im} = $icon;
	# Note that the image is scaled to one unit in user space.
	$d->{'BBox'} = PDFArray(map { PDFNum($_) } 0, 0, 1, 1);
	$d->{' stream'} = "q /$im Do Q";
	$self->{'AP'}->{'N'} = $d;	# normal appearance

	if (0) {
	    # Testing... Provide an alternative for R and D.
	    # Works only with Adobe Reader.
	    $d = PDFDict();
	    $self->{' apipdf'}->new_obj($d);
	    $d->{'Type'} = PDFName('XObject');
	    $d->{'Subtype'} = PDFName('Form');
	    $d->{'FormType'} = PDFNum(1);
	    $d->{'Matrix'} = PDFArray(map { PDFNum($_) } 1, 0, 0, 1, 0, 0);
	    $d->{'Resources'} = PDFDict();
	    $d->{'Resources'}->{'ProcSet'} = PDFArray(map { PDFName($_) } qw(PDF));
	    $d->{'BBox'} = PDFArray(map { PDFNum($_) } 0, 0, $r[2]-$r[0], $r[3]-$r[1]);
	    $d->{' stream'} =
	      join( " ",
		    # black outline
		    0, 0, 'm',
		    0, $r[2]-$r[0], 'l',
		    $r[2]-$r[0], $r[3]-$r[1], 'l',
		    $r[2]-$r[0], 0, 'l',
		    's',
		  );
        }

	# Should default to N, but be sure.
	$self->{'AP'}->{'R'} = $d;	# Rollover
	$self->{'AP'}->{'D'} = $d;	# Down
    }

    return $self;
}

# strip off any leading - from all options (hash keys)
sub dashed2nondashed {
    my @opts = @_;
    for (my $i=0; $i<@opts; $i+=2) {
	if ($opts[$i] =~ /^-(.*)$/) {
	    $opts[$i] = $1;
	}
    }
    return @opts;
}

1;
