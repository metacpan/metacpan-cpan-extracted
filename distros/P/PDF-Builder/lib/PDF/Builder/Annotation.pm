package PDF::Builder::Annotation;

use base 'PDF::Builder::Basic::PDF::Dict';

use strict;
use warnings;

our $VERSION = '3.021'; # VERSION
my $LAST_UPDATE = '3.019'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::Annotation - Add annotations to a PDF

=head1 METHODS

Note that the handling of annotations can vary from Reader to Reader. The
available icon set may be larger or smaller than given here, and some Readers
activate an annotation on a single mouse click, while others require a double
click. Not all features provided here may be available on all PDF Readers.

=over

=item $annotation = PDF::Builder::Annotation->new()

Returns an annotation object (called from $page->annotation()).

It is normally I<not> necessary to explicitly call this method (see examples).

=cut

# %options removed, as there are currently none
sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new();
    $self->{'Type'}   = PDFName('Annot');
    $self->{'Border'} = PDFArray(PDFNum(0), PDFNum(0), PDFNum(1));

    return $self;
}

#sub outobjdeep {
#    my ($self, @options) = @_;
#
#    foreach my $k (qw[ api apipdf apipage ]) {
#        $self->{" $k"} = undef;
#        delete($self->{" $k"});
#    }
#    return $self->SUPER::outobjdeep(@options);
#}

# ============== start of annotation types =======================

# note that %options is given as the only format in most cases, as -rect
# is a mandatory "option"

=back

=head2 Annotation types

=over

=item $annotation->link($page, %options)

=item $annotation->link($page)

Defines the annotation as a launch-page with page C<$page> (within I<this>
document) and options %options (-rect, -border, -color, I<fit>: see 
descriptions below).

B<Note> that C<$page> is I<not> a simple page number, but is a page structure
such as C<$pdf-E<gt>openpage(page_number)>. 

=cut

sub link {  ## no critic
    my ($self, $page, %options) = @_;

    $self->{'Subtype'} = PDFName('Link');
    if (ref($page)) {
        $self->{'A'}        = PDFDict();
        $self->{'A'}->{'S'} = PDFName('GoTo');
    }
    $self->dest($page, %options);
    $self->rect(@{$options{'-rect'}}) if defined $options{'-rect'};
    $self->border(@{$options{'-border'}}) if defined $options{'-border'};
    $self->Color(@{$options{'-color'}}) if defined $options{'-color'};

    return $self;
}

=item $annotation->pdf_file($pdffile, $page_number, %options)

Defines the annotation as a PDF-file with filepath C<$pdffile>, on page 
C<$page_number>, and options %options (-rect, -border, -color, I<fit>: see 
descriptions below). This differs from the C<link> call in that the target 
is found in a different PDF file, not the current document.

C<$page_number> is the physical page number, starting at 1: 1, 2,...

=cut

# Note: renamed from pdfile() to pdf_file().

sub pdf_file {
    my ($self, $url, $page_number, %options) = @_;
    # note that although "url" is used, it may be a local file

    $self->{'Subtype'}  = PDFName('Link');
    $self->{'A'}        = PDFDict();
    $self->{'A'}->{'S'} = PDFName('GoToR');
    $self->{'A'}->{'F'} = PDFString($url, 'u');

    $page_number--;  # wants it numbered starting at 0
    $self->dest(PDFNum($page_number), %options);
    $self->rect(@{$options{'-rect'}}) if defined $options{'-rect'};
    $self->border(@{$options{'-border'}}) if defined $options{'-border'};
    $self->Color(@{$options{'-color'}}) if defined $options{'-color'};

    return $self;
}

=item $annotation->file($file, %options)

Defines the annotation as a launch-file with filepath C<$file> (a local file)
and options %options (-rect, -border, -color: see descriptions below). 
I<How> the file is displayed depends on the operating system, type of file, 
and local configuration or mapping.

=cut

sub file {
    my ($self, $file, %options) = @_;

    $self->{'Subtype'}  = PDFName('Link');
    $self->{'A'}        = PDFDict();
    $self->{'A'}->{'S'} = PDFName('Launch');
    $self->{'A'}->{'F'} = PDFString($file, 'f');
    $self->rect(@{$options{'-rect'}}) if defined $options{'-rect'};
    $self->border(@{$options{'-border'}}) if defined $options{'-border'};
    $self->Color(@{$options{'-color'}}) if defined $options{'-color'};

    return $self;
}

=item $annotation->url($url, %options)

Defines the annotation as a launch-url with url C<$url> and
options %options (-rect, -border, -color: see descriptions below). 
This page is usually brought up in a browser, and may be remote.

=cut

sub url {
    my ($self, $url, %options) = @_;

    $self->{'Subtype'}    = PDFName('Link');
    $self->{'A'}          = PDFDict();
    $self->{'A'}->{'S'}   = PDFName('URI');
    $self->{'A'}->{'URI'} = PDFString($url, 'u');
    $self->rect(@{$options{'-rect'}}) if defined $options{'-rect'};
    $self->border(@{$options{'-border'}}) if defined $options{'-border'};
    $self->Color(@{$options{'-color'}}) if defined $options{'-color'};

    return $self;
}

=item $annotation->text($text, %options)

Defines the annotation as a text note with content string C<$text> and
options %options (-rect, -color, -text, -open: see descriptions below). 
The C<$text> may include newlines \n for multiple lines.

C<-text> is the popup's label string, not to be confused with the main C<$text>.

The icon appears in the upper left corner of the C<-rect> selection rectangle,
and its active clickable area is fixed by the icon (it is I<not> equal to the 
rectangle). The icon size is fixed, and its fill color set by C<-color>.

Additional options:

=over

=item -icon => name_string

=item -icon => reference

Specify the B<icon> to be used. The default is Reader-specific (usually 
C<Note>), and others may be 
defined by the Reader. C<Comment>, C<Key>, C<Help>, C<NewParagraph>, 
C<Paragraph>, and C<Insert> are also supposed to 
be available on all PDF Readers. Note that the name I<case> must exactly match.
The icon is of fixed size.
Any I<AP> dictionary entry will override the -icon setting. 

A I<reference> to an icon may be passed instead of a name.

=back

=cut

# the icon size appears to be fixed. the last font size used does not affect it
# and enabling icon_appearance() for it doesn't seem to do anything

sub text {
    my ($self, $text, %options) = @_;

    $self->{'Subtype'} = PDFName('Text');
    $self->content($text);

    $self->rect(@{$options{'-rect'}}) if defined $options{'-rect'};
    $self->open($options{'-open'}) if defined $options{'-open'};
    $self->Color(@{$options{'-color'}}) if defined $options{'-color'};
    # popup label (title)
    $self->{'T'} = PDFString($options{'-text'}, 'p') if exists $options{'-text'};

    # Icon Name will be ignored if there is an AP.
    my $icon;  # perlcritic doesn't want 2 lines combined
    $icon = $options{'-icon'} if exists $options{'-icon'};
    $self->{'Name'} = PDFName($icon) if $icon && !ref($icon); # icon name
    # Set the icon appearance
    $self->icon_appearance($icon, %options) if $icon;

    return $self;
}

=item $annotation->movie($file, $contentType, %options)

Defines the annotation as a movie from C<$file> with 
content (MIME) type C<$contentType> and
options %options (-rect, -border, -color: see descriptions below).

The C<-rect> rectangle also serves as the area where the movie is played, so it
should be of usable size and aspect ratio. It does not use a separate popup
player. It is known to play .avi and .wav files -- others have not been tested.
Using Adobe Reader, it will not play .mpg files (unsupported type). More work
is probably needed on this annotation method.

=cut

sub movie {
    my ($self, $file, $contentType, %options) = @_;

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

    $self->rect(@{$options{'-rect'}}) if defined $options{'-rect'};
    $self->border(@{$options{'-border'}}) if defined $options{'-border'};
    $self->Color(@{$options{'-color'}}) if defined $options{'-color'};
    # popup label (title)  DOESN'T SEEM TO SHOW UP ANYWHERE
    #  self->A->T and self->T also fail to display
    $self->{'Movie'}->{'T'} = PDFString($options{'-text'}, 'p') if exists $options{'-text'};

    return $self;
}

=item $annotation->file_attachment($file, %options)

Defines the annotation as a file attachment with file $file and options %options
(-rect, -color: see descriptions below). Note that C<-color> applies to
the icon fill color, not to a selectable area outline. The icon is resized
(including aspect ratio changes) based on the selectable rectangle given by
C<-rect>, so watch your rectangle dimensions!

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
including the path, give the C<-notrimpath> option.

Options: 

=over 

=item -icon => name_string

=item -icon => reference

Specify the B<icon> to be used. The default is Reader-specific (usually 
C<PushPin>), and others may be 
defined by the Reader. C<Paperclip>, C<Graph>, and C<Tag> are also supposed to 
be available on all PDF Readers. Note that the name I<case> must exactly match.
C<None> is a custom invisible icon defined by PDF::Builder.
The icon is stretched/squashed to fill the defined target rectangle, so take
care when defining C<-rect> dimensions.
Any I<AP> dictionary entry will override the -icon setting. 

A I<reference> to an icon may be passed instead of a name.

=item -notrimpath => 1

If given, show the entire path and file name on mouse rollover, rather than
just the file name.

=item -text => string

A text label for the popup (on mouseover) that contains the file name.

=back

=cut

# TBD it is possible to specify different files for DOS, Mac, Unix
#     (see PDF 1.7 7.11.4.2). This might solve problem of different line
#     ends, at the cost of 3 copies of each file.

sub file_attachment {
    my ($self, $file, %options) = @_;

    my $icon;  # defaults to Reader's default (usually PushPin)
    $icon = $options{'-icon'} if exists $options{'-icon'};

    $self->rect(@{$options{'-rect'}}) if defined $options{'-rect'};
    # descriptive text on mouse rollover
    $self->{'T'} = PDFString($options{'-text'}, 'p') if exists $options{'-text'};

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
    if (!defined $options{'-notrimpath'}) {
        if ($cName =~ m#([^/\\]+)$#) { $cName = $1; }
    }
    $self->{'Contents'} = PDFString($cName, 's');

    # Icon Name will be ignored if there is an AP.
    $self->{'Name'} = PDFName($icon) if $icon && !ref($icon); # icon name
   #$self->{'F'} = PDFNum(0b0);  # flags default to 0
    $self->Color(@{ $options{'-color'} }) if defined $options{'-color'};

    # The File Specification.
    $self->{'FS'} = PDFDict();
    $self->{'FS'}->{'F'} = PDFString($file, 'f');
    $self->{'FS'}->{'Type'} = PDFName('F');
    $self->{'FS'}->{'EF'} = PDFDict($file);
    $self->{'FS'}->{'EF'}->{'F'} = PDFDict($file);
    $self->{' apipdf'}->new_obj($self->{'FS'}->{'EF'}->{'F'});
    $self->{'FS'}->{'EF'}->{'F'}->{'Type'} = PDFName('EmbeddedFile');
    $self->{'FS'}->{'EF'}->{'F'}->{' streamfile'} = $file;

    # Set the icon appearance
    $self->icon_appearance($icon, %options) if $icon;

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

=back

=head2 Internal routines and common options

=over

=item $annotation->rect($llx,$lly, $urx,$ury)

Sets the rectangle (active click area) of the annotation, given by -rect option.
This is any pair of diagonally opposite corners of the rectangle.

The default clickable area is the icon itself.

Defining option. I<Note that this "option" is actually B<required>.>

=over

=item -rect => [LLx, LLy, URx, URy]

Set annotation rectangle at C<[LLx,LLy]> to C<[URx,URy]> (lower left and
upper right coordinates). LL to UR is customary, but any diagonal is allowed.

=back

=cut

sub rect {
    my ($self, @r) = @_;

    die "Insufficient parameters to annotation->rect() " unless scalar @r == 4;
    $self->{'Rect'} = PDFArray( map { PDFNum($_) } $r[0],$r[1],$r[2],$r[3]);
    return $self;
}

=item $annotation->border(@b)

Sets the border-style of the annotation, if applicable, as given by the
-border option. There are three entries in the array:
horizontal and vertical corner radii, and border width.

A border is used in annotations where text or some other material is put down,
and a clickable rectangle is defined over it (-rect). A border is not used
when an icon is being used to mark the clickable area.

The default is [0 0 1] (solid line of width 1, with sharp corners).

Defining option:

=over

=item -border => [CRh, CRv, W]

=item -border => [CRh, CRv, W [, on, off...]]

Set annotation B<border style> of horizontal and vertical corner radii C<CRh> 
and C<CRv> (value 0 for squared corners) and width C<W> (value 0 for no border).
The default is squared corners and a solid line of width 1 ([0 0 1]).
Optionally, a dash pattern array may be given (C<on> length, C<off> length,
as one or more I<pairs>). The default is a solid line.

The border vector seems to ignore the first two settings (corner radii), but 
the line thickness works, on basic Readers. 
The radii I<may> work on some other Readers.

=back

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

=item $annotation->content(@lines)

Sets the text-content of the C<text()> annotation.
This is a text string or array of strings.

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

=item $annotation->open($bool)

Display the C<text()> annotation either open or closed, if applicable.

Both are editable; the "open" form brings up the page with the entry area
already open for editing, while "closed" has to be clicked on to edit it.

Defining option:

=over

=item -open => boolean

If true (1), the annotation will be marked as initially "open".
If false (0), or the option is not given, the annotation is initially "closed".

=back

=cut

sub open {  ## no critic
    my ($self, $bool) = @_;
    $self->{'Open'} = PDFBool($bool? 1: 0);
    return $self;
}

=item $annotation->dest($page, I<fit_setting>)

For certain annotation types (C<link> or C<pdf_file>), the I<fit_setting> 
specifies how the content of the page C<$page> is to be fit to the window,
while preserving its aspect ratio. 
These fit settings are:

=over

=item -fit => 1

Display the page with its contents magnified just enough
to fit the entire page within the window both horizontally and vertically. If 
the required horizontal and vertical magnification factors are different, use 
the smaller of the two, centering the page within the window in the other 
dimension.

=item -fith => $top

Display the page with the vertical coordinate C<$top> 
positioned at the top edge of the window and the contents of the page magnified 
just enough to fit the entire width of the page within the window.

=item -fitv => $left

Display the page with the horizontal coordinate C<$left>
positioned at the left edge of the window and the contents of the page magnified
just enough to fit the entire height of the page within the window.

=item -fitr => [$left, $bottom, $right, $top]

Display the page with its contents magnified just enough
to fit the rectangle specified by the coordinates C<$left>, C<$bottom>, 
C<$right>, and C<$top> entirely within the window both horizontally and 
vertically. If the required horizontal and vertical magnification factors are 
different, use the smaller of the two, centering the rectangle within the window
in the other dimension.

=item -fitb => 1

Display the page with its contents magnified 
just enough to fit its bounding box entirely within the window both horizontally
and vertically. If the required horizontal and vertical magnification factors 
are different, use the smaller of the two, centering the bounding box within the
window in the other dimension.

=item -fitbh => $top

Display the page with the vertical coordinate 
C<$top> positioned at the top edge of the window and the contents of the page 
magnified just enough to fit the entire width of its bounding box within the 
window.

=item -fitbv => $left

Display the page with the horizontal 
coordinate C<$left> positioned at the left edge of the window and the contents 
of the page magnified just enough to fit the entire height of its bounding box 
within the window.

=item -xyz => [$left, $top, $zoom]

Display the page with the coordinates C<[$left, $top]> 
positioned at the top-left corner of the window and the contents of the page 
magnified by the factor C<$zoom>. A zero (0) value for any of the parameters 
C<$left>, C<$top>, or C<$zoom> specifies that the current value of that 
parameter is to be retained unchanged.

This is the B<default> fit setting, with position (left and top) and zoom
the same as the calling page's ([undef, undef, undef]).

=back

=item $annotation->dest($name)

Connect the Annotation to a "Named Destination" defined elsewhere, including
the optional desired I<fit> (default: -xyz undef*3).

=cut

sub dest {
    my ($self, $page, %position) = @_;

    if (ref $page) {
        $self->{'A'} ||= PDFDict();

        if      (defined $position{'-fit'}) {
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('Fit'));
        } elsif (defined $position{'-fith'}) {
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('FitH'), PDFNum($position{'-fith'}));
        } elsif (defined $position{'-fitb'}) {
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('FitB'));
        } elsif (defined $position{'-fitbh'}) {
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('FitBH'), PDFNum($position{'-fitbh'}));
        } elsif (defined $position{'-fitv'}) {
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('FitV'), PDFNum($position{'-fitv'}));
        } elsif (defined $position{'-fitbv'}) {
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('FitBV'), PDFNum($position{'-fitbv'}));
        } elsif (defined $position{'-fitr'}) {
            die "Insufficient parameters to -fitr => []) " unless scalar @{$position{'-fitr'}} == 4;
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('FitR'), map {PDFNum($_)} @{$position{'-fitr'}});
        } elsif (defined $position{'-xyz'}) {
            die "Insufficient parameters to -xyz => []) " unless scalar @{$position{'-xyz'}} == 3;
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('XYZ'), map {defined $_ ? PDFNum($_) : PDFNull()} @{$position{'-xyz'}});
        } else {
	    # no "fit" option found. use default.
            $position{'-xyz'} = [undef,undef,undef];
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('XYZ'), map {defined $_ ? PDFNum($_) : PDFNull()} @{$position{'-xyz'}});
        }
    } else {
        $self->{'Dest'} = PDFString($page, 'n');
    }

    return $self;
}

=item $annotation->Color(@color)

Set the icon's fill color. The color is an array of 1, 3, or 4 numbers, each
in the range 0.0 to 1.0. If 1 number is given, it is the grayscale value (0 = 
black to 1 = white). If 3 numbers are given, it is an RGB color value. If 4
numbers are given, it is a CMYK color value. Currently, named colors (strings)
are not handled.

For link and url annotations, this is the color of the rectangle border 
(-border given with a width of at least 1).

If an invalid array length or numeric value is given, a medium gray ( [0.5] ) 
value is used, without any message. If no color is given, the usual fill color
is black.

Defining option:

=over

=item -color => [ ] or not 1, 3, or 4 numbers 0.0-1.0

A medium gray (0.5 value) will be used if an invalid color is given.

=item -color => [ g ]

If I<g> is between 0.0 (black) and 1.0 (white), the fill color will be gray.

=item -color => [ r, g, b ]

If I<r> (red), I<g> (green), and I<b> (blue) are all between 0.0 and 1.0, the 
fill color will be the defined RGB hue. [ 0, 0, 0 ] is black, [ 1, 1, 0 ] is
yellow, and [ 1, 1, 1 ] is white.

=item -color => [ c, m, y, k ]

If I<c> (red), I<m> (magenta), I<y> (yellow), and I<k> (black) are all between 
0.0 and 1.0, the fill color will be the defined CMYK hue. [ 0, 0, 0, 0 ] is
white, [ 1, 0, 1, 0 ] is green, and [ 1, 1, 1, 1 ] is black.

=back

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
        # invalid -color entry. just set to medium gray without message
        $self->{'C'} = PDFArray(map { PDFNum($_) } 0.5 );
    }

    return $self;
}

=item -text => string

Specify an optional B<text label> for annotation. This text or comment only
shows up I<as a title> in the pop-up containing the file or text.

=cut

sub icon_appearance {
    my ($self, $icon, %options) = @_;
    # $icon is a string with name of icon (confirmed not empty) or a reference.
    # if a string (text), has already defined /Name. "None" and ref handle here.
    # options of interest: -rect (to define size of icon)

   # text also permits icon and custom icon, including None
   #return unless $self->{'Subtype'}->val() eq 'FileAttachment';

    my @r;  # perlcritic doesn't want 2 lines combined
    @r = @{$options{'-rect'}} if defined $options{'-rect'};
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

=back

=cut

1;
