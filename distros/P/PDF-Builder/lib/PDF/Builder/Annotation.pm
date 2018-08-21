package PDF::Builder::Annotation;

use base 'PDF::Builder::Basic::PDF::Dict';

use strict;
no warnings qw[ deprecated recursion uninitialized ];

our $VERSION = '3.010'; # VERSION
my $LAST_UPDATE = '3.010'; # manually update whenever code is changed

use Encode qw(:all);

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Util;

=head1 NAME

PDF::Builder::Annotation - Add annotations to a PDF

=head1 METHODS

Note that the handling of annotations can vary from Reader to Reader. The
available icon set may be larger or smaller than given here, and some Readers
activate an annotation on a single mouse click, while others require a double
click. Not all features provided here may be available on all PDF Readers.

=over

=item $ant = PDF::Builder::Annotation->new()

Returns an annotation object (called from $page->annotation()).

=cut

sub new {
    my ($class,%opts) = @_;

    my $self = $class->SUPER::new();
    $self->{'Type'} = PDFName('Annot');
    $self->{'Border'} = PDFArray(PDFNum(0), PDFNum(0), PDFNum(1));
    return $self;
}

sub outobjdeep {
    my ($self, @opts) = @_;

    foreach my $k (qw[ api apipdf apipage ]) {
        $self->{" $k"} = undef;
        delete($self->{" $k"});
    }
    return $self->SUPER::outobjdeep(@opts);
}

# ============== start of annotation types =======================

=back

=head2 Annotation types

=over

=item $ant->link($page, %opts)

=item $ant->link($page)

Defines the annotation as a launch-page with page C<$page> (within I<this>
document) and options %opts (-rect, -border, I<fit> options).

=cut

sub link {
    my ($self, $page, %opts) = @_;

    $self->{'Subtype'} = PDFName('Link');
    if (ref $page) {
        $self->{'A'} = PDFDict();
        $self->{'A'}->{'S'} = PDFName('GoTo');
    }
    $self->dest($page, %opts);
    $self->rect(@{$opts{'-rect'}}) if defined $opts{'-rect'};
    $self->border(@{$opts{'-border'}}) if defined $opts{'-border'};
    $self->Color(@{ $opts{'-color'} }) if defined $opts{'-color'};
    # descriptive text on mouse rollover
    $self->{'T'} = PDFStr($opts{'-text'}) if exists $opts{'-text'};

    return $self;
}

=item $ant->url($url, %opts)

=item $ant->url($url)

Defines the annotation as a launch-url with url C<$url> and
options %opts (-rect, -border).

=cut

sub url {
    my ($self, $url, %opts) = @_;

    $self->{'Subtype'} = PDFName('Link');
    $self->{'A'} = PDFDict();
    $self->{'A'}->{'S'} = PDFName('URI');
    if (is_utf8($url)) {
        # URI must be 7-bit ascii
        utf8::downgrade($url);
    }
    $self->{'A'}->{'URI'} = PDFStr($url);
    # this will come again -- since the utf8 urls are coming !
    # -- fredo
    #if (is_utf8($url) || utf8::valid($url)) {
    #    $self->{'A'}->{'URI'} = PDFUtf($url);
    #} else {
    #    $self->{'A'}->{'URI'} = PDFStr($url);
    #}
    $self->rect(@{$opts{'-rect'}}) if defined $opts{'-rect'};
    $self->border(@{$opts{'-border'}}) if defined $opts{'-border'};
    $self->Color(@{ $opts{'-color'} }) if defined $opts{'-color'};
    # descriptive text on mouse rollover
    $self->{'T'} = PDFStr($opts{'-text'}) if exists $opts{'-text'};

    return $self;
}

=item $ant->file($file, %opts)

=item $ant->file($file)

Defines the annotation as a launch-file with filepath C<$file> and
options %opts (-rect, -border).

=cut

sub file {
    my ($self, $url, %opts) = @_;

    $self->{'Subtype'} = PDFName('Link');
    $self->{'A'} = PDFDict();
    $self->{'A'}->{'S'} = PDFName('Launch');
    if (is_utf8($url)) {
        # URI must be 7-bit ascii
        utf8::downgrade($url);
    }
    $self->{'A'}->{'F'} = PDFStr($url);
    # this will come again -- since the utf8 urls are coming !
    # -- fredo
    #if (is_utf8($url) || utf8::valid($url)) {
    #    $self->{'A'}->{'F'} = PDFUtf($url);
    #} else {
    #    $self->{'A'}->{'F'} = PDFStr($url);
    #}
    $self->rect(@{$opts{'-rect'}}) if defined $opts{'-rect'};
    $self->border(@{$opts{'-border'}}) if defined $opts{'-border'};
    $self->Color(@{ $opts{'-color'} }) if defined $opts{'-color'};
    # descriptive text on mouse rollover
    $self->{'T'} = PDFStr($opts{'-text'}) if exists $opts{'-text'};

    return $self;
}

=item $ant->pdf_file($pdffile, $pagenum, %opts)

=item $ant->pdf_file($pdffile, $pagenum)

Defines the annotation as a PDF-file with filepath C<$pdffile>, on page 
C<$pagenum>, and options %opts (-rect, -border, I<fit> options).

The old name, I<pdfile>, is still available but is B<deprecated> and will be
removed at some time in the future.

=cut

# to be removed no earlier than November 16, 2019
sub pdfile {
    my ($self, $url, $pnum, %opts) = @_;
    return $self->pdf_file($url, $pnum, %opts);
}

sub pdf_file {
    my ($self, $url, $pnum, %opts) = @_;

    $self->{'Subtype'} = PDFName('Link');
    $self->{'A'} = PDFDict();
    $self->{'A'}->{'S'} = PDFName('GoToR');
    if (is_utf8($url)) {
        # URI must be 7-bit ascii
        utf8::downgrade($url);
    }
    $self->{'A'}->{'F'} = PDFStr($url);
    # this will come again -- since the utf8 urls are coming !
    # -- fredo
    #if (is_utf8($url) || utf8::valid($url)) {
    #    $self->{'A'}->{'F'} = PDFUtf($url);
    #} else {
    #    $self->{'A'}->{'F'} = PDFStr($url);
    #}

    $self->dest(PDFNum($pnum), %opts);
    $self->rect(@{$opts{'-rect'}}) if defined $opts{'-rect'};
    $self->border(@{$opts{'-border'}}) if defined $opts{'-border'};
    $self->Color(@{ $opts{'-color'} }) if defined $opts{'-color'};
    # descriptive text on mouse rollover
    $self->{'T'} = PDFStr($opts{'-text'}) if exists $opts{'-text'};

    return $self;
}

=item $ant->text($text, %opts)

=item $ant->text($text)

Defines the annotation as a text note with content string C<$text> and
options %opts (-rect, -border, -open). 

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

# "None" seems to be ignored.
#C<None> is a custom invisible icon defined by PDF::Builder.

sub text {
    my ($self, $text, %opts) = @_;

    $self->{'Subtype'} = PDFName('Text');
    $self->content($text);

    $self->rect(@{$opts{'-rect'}}) if defined $opts{'-rect'};
    $self->border(@{$opts{'-border'}}) if defined $opts{'-border'};
    $self->open($opts{'-open'}) if defined $opts{'-open'};
    $self->Color(@{ $opts{'-color'} }) if defined $opts{'-color'};
    # descriptive text on mouse rollover
    $self->{'T'} = PDFStr($opts{'-text'}) if exists $opts{'-text'};

    # Icon Name will be ignored if there is an AP.
    my $icon;  # perlcritic doesn't want 2 lines combined
    $icon = $opts{'-icon'} if exists $opts{'-icon'};
    $self->{'Name'} = PDFName($icon) if $icon && !ref($icon); # icon name
    # Set the icon appearance
    $self->icon_appearance($icon, %opts) if $icon;

    return $self;
}

=item $ant->movie($file, $contentType, %opts)

=item $ant->movie($file, $contentType)

Defines the annotation as a movie from C<$file> with C<$contentType> and
options %opts (-rect, -border).

=cut

sub movie {
    my ($self, $file, $contentType, %opts) = @_;

    $self->{'Subtype'} = PDFName('Movie');
    $self->{'A'} = PDFBool(1);
    $self->{'Movie'} = PDFDict();
    $self->{'Movie'}->{'F'} = PDFDict();
    $self->{' apipdf'}->new_obj($self->{'Movie'}->{'F'});
    my $f = $self->{'Movie'}->{'F'};
    $f->{'Type'} = PDFName('EmbeddedFile');
    $f->{'Subtype'} = PDFName($contentType);
    $f->{' streamfile'} = $file;

    $self->rect(@{$opts{'-rect'}}) if defined $opts{'-rect'};
    $self->border(@{$opts{'-border'}}) if defined $opts{'-border'};
    $self->Color(@{ $opts{'-color'} }) if defined $opts{'-color'};
    # descriptive text on mouse rollover
    $self->{'T'} = PDFStr($opts{'-text'}) if exists $opts{'-text'};

    return $self;
}

=item $ant->file_attachment($file, %opts)

Defines the annotation as a file attachment with file $file and options %opts.

The file, along with its name, is embedded in the PDF document and may be
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
The icon is stretched to fill the defined target rectangle.
Any I<AP> dictionary entry will override the -icon setting. 

A I<reference> to an icon may be passed instead of a name.

=item -notrimpath => 1

If given, show the entire path and file name on mouse rollover, rather than
just the file name.

=back

=cut

# TBD it is possible to specify different files for DOS, Mac, Unix
#     (see PDF 1.7 7.11.4.2). This might solve problem of different line
#     ends, at the cost of 3 copies of each file.

sub file_attachment {
    my ($self, $file, %opts) = @_;

    my $icon;  # defaults to Reader's default (usually PushPin)
    $icon = $opts{'-icon'} if exists $opts{'-icon'};

    $self->rect(@{$opts{'-rect'}}) if defined $opts{'-rect'};
    $self->border(@{$opts{'-border'}}) if defined $opts{'-border'};

    $self->{'Subtype'} = PDFName('FileAttachment');
    # descriptive text on mouse rollover
    $self->{'T'} = PDFStr($opts{'-text'}) if exists $opts{'-text'};

    if (is_utf8($file)) {
	# URI must be 7-bit ascii
	utf8::downgrade($file);
    }
    # UTF-8 file names are coming?
    #if (is_utf8($file) || utf8::valid($file)) {
    #    $self->{'FS'}->{'F'} = PDFUtf($file);
    #} else {
    #    $self->{'FS'}->{'F'} = PDFStr($file);
    #}

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
    if (!defined $opts{'-notrimpath'}) {
        if ($cName =~ m#([^/\\]+)$#) { $cName = $1; }
    }
    $self->{'Contents'} = PDFStr($cName);

    # Icon Name will be ignored if there is an AP.
    $self->{'Name'} = PDFName($icon) if $icon && !ref($icon); # icon name
   #$self->{'F'} = PDFNum(0b0);  # flags default to 0
    $self->Color(@{ $opts{'-color'} }) if defined $opts{'-color'};

    # The File Specification.
    $self->{'FS'} = PDFDict();
    $self->{'FS'}->{'F'} = PDFStr($file);
    $self->{'FS'}->{'Type'} = PDFName('F');
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

=back

=head2 Internal routines and common options

=over

=item $ant->rect($llx,$lly, $urx,$ury)

Sets the rectangle (active click area) of the annotation, given by -rect option.
This is any pair of diagonally opposite corners of the rectangle.

The default clickable area is the icon itself.

Defining option. I<Note that this "option" is actually B<required>.>

=over

=item -rect => [LLx LLy URx URy]

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

=item $ant->border(@b)

Sets the border-style of the annotation, if applicable, as given by the
-border option. There are three or four entries in the array:
horizontal and vertical corner radii, border width, and (optionally) dash
pattern array [len_on, len_off].

The default is [0 0 1] (solid line of width 1, sharp corners).

Defining option:

=over

=item -border => [CRh CRv W [on off]]

=item -border => [CRh CRv W]

Set annotation B<border style> of horizontal and vertical corner radii C<CRh> 
and C<CRv> (value 0 for squared corners) and width C<W> (value 0 for no border).
The default is squared corners and a solid line of width 1 ([0 0 1]).

A dash pattern [C<on> length, C<off> length] may optionally be given.
The default is a solid line.

=back

=cut

sub border {
    my ($self, @b) = @_;

    if      (scalar @b == 3) {
        $self->{'Border'} = PDFArray( map { PDFNum($_) } $b[0],$b[1],$b[2]);
    } elsif (scalar @b == 4) {
	# b[3] is an anonymous array
        $self->{'Border'} = PDFArray( map { PDFNum($_) } $b[0],$b[1],$b[2],$b[3]);
    } else {
        die "annotation->border() style requires 3 or 4 parameters ";
    }
    return $self;
}

=item $ant->content($text)

Sets the text-content of the C<text()> annotation.
This is a text string.

=cut

sub content {
    my ($self, $t) = @_;
    
   # originally @t, but caller only passed a single text string (scalar) anyway
   #my $t = join("\n", @t);
    if (is_utf8($t) || utf8::valid($t)) {
        $self->{'Contents'} = PDFUtf($t);
    } else {
        $self->{'Contents'} = PDFStr($t);
    }
    return $self;
}

sub name {
    my ($self, $n) = @_;

    $self->{'Name'} = PDFName($n);
    return $self;
}

=item $ant->open($bool)

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

sub open {
    my ($self, $n) = @_;

    $self->{'Open'} = PDFBool($n? 1: 0);
    return $self;
}

=item $ant->dest($page, I<fit_setting>)

For certain annotation types (C<link> or C<pdf_file>), the I<fit_setting> 
specifies how the content of the page C<$page> is to be fit to the window,
while preserving its aspect ratio. 
These options are:

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

=back

=item $ant->dest($name)

Connect the Annotation to a "Named Destination" defined elsewhere.

=cut

sub dest {
    my ($self, $page, %opts) = @_;

    if (ref $page) {
        $opts{'-xyz'} = [undef,undef,undef] if scalar(keys %opts) < 1;

        $self->{'A'} ||= PDFDict();

        if      (defined $opts{'-fit'}) {
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('Fit'));
        } elsif (defined $opts{'-fith'}) {
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('FitH'), PDFNum($opts{'-fith'}));
        } elsif (defined $opts{'-fitb'}) {
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('FitB'));
        } elsif (defined $opts{'-fitbh'}) {
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('FitBH'), PDFNum($opts{'-fitbh'}));
        } elsif (defined $opts{'-fitv'}) {
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('FitV'), PDFNum($opts{'-fitv'}));
        } elsif (defined $opts{'-fitbv'}) {
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('FitBV'), PDFNum($opts{'-fitbv'}));
        } elsif (defined $opts{'-fitr'}) {
            die "Insufficient parameters to ->dest(page, -fitr => []) " unless scalar @{$opts{'-fitr'}} == 4;
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('FitR'), map {PDFNum($_)} @{$opts{'-fitr'}});
        } elsif (defined $opts{'-xyz'}) {
            die "Insufficient parameters to ->dest(page, -xyz => []) " unless scalar @{$opts{'-xyz'}} == 3;
            $self->{'A'}->{'D'} = PDFArray($page, PDFName('XYZ'), map {defined $_ ? PDFNum($_) : PDFNull()} @{$opts{'-xyz'}});
        }
    } else {
        $self->{'Dest'} = PDFStr($page);
    }

    return $self;
}

=item $ant->Color(@color)

Set the icon's fill color. The color is an array of 1, 3, or 4 numbers, each
in the range 0.0 to 1.0. If 1 number is given, it is the grayscale value (0 = 
black to 1 = white). If 3 numbers are given, it is an RGB color value. If 4
numbers are given, it is a CMYK color value.

If an invalid array length or numeric value is given, a medium gray ( [0.5] ) 
value is used, without any message. If no color is given, the usual fill color
is black.

Defining option:

=over

=item -color => [ g ]

If I<g> is between 0.0 (black) and 1.0 (white), the fill color will be gray.

=item -color => [ r, g, b ]

If I<r> (red), I<g> (green), and I<b> (blue) are all between 0.0 and 1.0, the 
fill color will be the defined RGB hue. [ 0, 0, 0 ] is black, [ 1, 1, 0 ] is
yellow, and [ 1, 1, 1] is white.

=item -color => [ c, m, y, k ]

If I<c> (red), I<m> (magenta), I<y> (yellow), and I<k> (black) are all between 
0.0 and 1.0, the fill color will be the defined CMYK hue. [ 0, 0, 0, 0 ] is
white, [ 1, 0, 1, 0 ] is green, and [ 1, 1, 1, 1] is black.

=back

=cut

# possible future enhancement: if array is empty (0 length), set color to
# some default such as medium gray (0.5).

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
shows up in the pop-up containing the file or text, when the mouse is rolled
over the target rectangle.

=cut

sub icon_appearance {
    my ($self, $icon, %opts) = @_;
    # $icon is a string with name of icon (confirmed not empty) or a reference.
    # if a string (text), has already defined /Name. "None" and ref handle here.
    # options of interest: -rect (to define size of icon)

    return unless $self->{'Subtype'}->val() eq 'FileAttachment';

    my @r;  # perlcritic doesn't want 2 lines combined
    @r = @{$opts{'-rect'}} if defined $opts{'-rect'};
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
