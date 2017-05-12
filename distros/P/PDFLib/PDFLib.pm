# $Id: PDFLib.pm,v 1.28 2005/10/24 18:27:55 matt Exp $

=head1 NAME

PDFLib - More OO interface to pdflib_pl.pm

=head1 SYNOPSIS

  use PDFLib;
  my $pdf = PDFLib->new("foo.pdf");

=head1 DESCRIPTION

A cleaner API than pdflib_pl.pm, which is a very low-level (non-OO) interface.

=head1 PDFLib API

=cut

package PDFLib;

use strict;
use vars qw/$VERSION/;

use pdflib_pl 4.0;
use Carp;

$VERSION = '0.14';

my %stacklevel = (
        object => 0,
        document => 1,
        page => 2,
        template => 2,
        pattern => 2,
        path => 3,
        );

my %pdfs;

=head2 new(...)

Construct a new PDF object. No parameters required.

Parameters are passed as name/value pairs (i.e. a hash):

=over 4

=item filename

A filename to save the PDF to. If not supplied the PDF will be
generated in memory.

=item papersize

The papersize can either be an array ref of [x, y], or can be a string 
containing one of the below listed paper sizes. This defaults to "a4".

=item creator

The creator of the document.

=item author

The author of the document

=item title

The title of the document

=item orientation

The orientation of the pages. This defaults to "portrait".

=back

Example:

  my $pdf = PDFLib->new(creator => "My PDF Program",
        author => "Me",
        title => "Business Report");

=cut

sub new {
    my $class = shift;
    my %params = @_; # params: filename, papersize, creator, author, title
    
    my $pdf = bless {pdf => PDF_new(), %params}, $class;

    $pdfs{$pdf + 0} = $pdf->{pdf};
    
    $pdf->filename($pdf->{filename} || "");
    for my $info (qw(creator author title)) {
        if (exists $params{$info}) {
            $pdf->info(ucfirst($info), $params{$info});
        }
    }
    
    $pdf->{images} = [];
    $pdf->{bookmarks} = [];
    $pdf->{stacklevel} = 'document';
    
    return $pdf;
}

sub DESTROY {
    my $pdf = shift;
    if (my $pdf_h = delete $pdfs{$pdf + 0}) {
        if ($pdf->stacklevel >= $stacklevel{'page'}) {
            PDF_end_page($pdf_h);
        }
        PDF_close($pdf_h) unless $pdf->{closed};
        PDF_delete($pdf_h);
    }
}

=head2 finish

Let PDFLib know you are finished processing this PDF. This method
should not normally need to be called, as it is called
automatically for you.

=cut

sub finish {
    my $pdf = shift;
    return if $pdf->{closed};
    if ($pdf->stacklevel >= $stacklevel{'page'}) {
        PDF_end_page($pdf->{pdf});
        $pdf->{stacklevel} = 'document';
    }
#    $pdf->end_page;
#    warn("closing file\n");
    PDF_close($pdf->{pdf});
    $pdf->{stacklevel} = 'object';
    $pdf->{closed}++;
}

=head2 delete

Only call this if you are manually calling finish() also. It 
deletes the used memory for this PDF.

=cut

sub delete {
    my $pdf = shift;
#    warn("PDF_delete\n");
    PDF_delete($pdf->{pdf});
}

=head2 get_buffer

If (and only if) you didn't supply a filename in the call to new(),
then get_buffer will return to you the PDF as a string. Very 
useful for generating PDFs on the fly for a web server.

=cut

sub get_buffer {
    my $pdf = shift;
    my $obj = $pdf->{pdf};
    $pdf->finish();
    return PDF_get_buffer($obj);
}

sub _pdf {
    my $pdf = shift;
    return $pdf->{pdf};
}

=head2 filename(...)

A getter and setter method for the PDF's filename. Pass in a filename as
a string to set a new filename. returns the old filename.

=cut

sub filename {
    my $pdf = shift;
    
    my $oldname = $pdf->{filename};
    if (@_) {
        $pdf->{filename} = shift @_;
        
        if (PDF_open_file($pdf->_pdf, $pdf->{filename}) == -1) {
            croak "PDF_open_file(\"$pdf->{filename}\") failed";
        }
    }
    return $oldname;
}

=head2 info(key => value)

A getter and setter method for the PDF info fields (such as Title,
Creator, Author, etc). A key is required. If you pass in a value
it will set the new value. Returns the old value.

=cut

sub info {
    my $pdf = shift;
    my $key = shift;

    my $old = $pdf->{info}{$key};
    if (@_) {
        $pdf->{info}{$key} = shift(@_);
        PDF_set_info($pdf->_pdf, $key, $pdf->{info}{$key});
    }
    return $old;
}

=head2 papersize(...)

A getter and setter for the current paper size. An optional value
that can be an array ref of [x, y], or a string from the list of
paper sizes below, will set the current paper size. Returns the
old/current paper size.

=cut

sub papersize {
    my $pdf = shift;

    my $old = $pdf->{papersize} || 'a4';
    if (@_) {
        $pdf->{papersize} = shift @_;
    }
    return $old;
}

=head2 orientation(...)

A getter and setter for the current page orientation. All this
really does is swap the x and y values in the paper size if
orientation == "landscape". Returns the current/old orientation.

=cut

sub orientation {
    my $pdf = shift;

    my $old = $pdf->{orientation};
    if (@_) {
        $pdf->{orientation} = shift @_;
    }
    return $old;
}

sub stacklevel {
    my $pdf = shift;

    return $stacklevel{$pdf->{stacklevel}};
}

=head2 start_page(...)

Start a new page. If a page has already been started, this will call
end_page() automatically for you.

Options are passed in as name/value pairs, and are passed to
PDFLib::Page->new() below.

=cut

sub start_page {
    my $pdf = shift;
    my %params = @_;
    if ($pdf->stacklevel >= $stacklevel{page}) {
        if ($pdf->{stacklevel} eq 'path') {
            $pdf->end_path;
        }
        $pdf->end_page;
    }
    $params{orientation} ||= $pdf->orientation;
    $params{papersize} ||= $pdf->papersize;
    # warn("setting papersize to $params{papersize}, orientation to $params{orientation}\n");
    $pdf->{current_page} = PDFLib::Page->new($pdf->_pdf, %params);
    $pdf->set_font(face => 'Helvetica', size => 12.0);
    $pdf->{stacklevel} = 'page';
}

=head2 end_page

End the current page. It should not normally be necessary to call this,
however you may need it if you wish to load an image after you
have called start_page (images must be loaded when no pages are open)

=cut

sub end_page {
    my $pdf = shift;
    return unless $pdf->stacklevel >= $stacklevel{page};
    if ($pdf->{stacklevel} eq 'path') {
        $pdf->end_path;
    }
    $pdf->{stacklevel} = 'document';
    delete $pdf->{current_page};
    PDF_end_page($pdf->{pdf});
}

sub _equals_font {
    my ($old, %new) = @_;

    local $^W;
    foreach my $key (qw(face bold italic)) {
        return if ($old->{$key} ne $new{$key});
    }
    return 1;
}

my %fontmap = (
    Courier => {
        plain => 'Courier',
        bold => 'Courier-Bold',
        italic => 'Courier-Oblique',
        bolditalic => 'Courier-BoldOblique',
    },
    Helvetica => {
        plain => 'Helvetica',
        bold => 'Helvetica-Bold',
        italic => 'Helvetica-Oblique',
        bolditalic => 'Helvetica-BoldOblique',
    },
    Times => {
        plain => 'Times-Roman',
        bold => 'Times-Bold',
        italic => 'Times-Italic',
        bolditalic => 'Times-BoldItalic',
    },
    Symbol => {
        plain => 'Symbol',
    },
    ZapfDingbats => {
        plain => 'ZapfDingbats',
    },
);

sub lookup_font {
    my %params = @_;

    $params{face} = ucfirst($params{face});

    if ($params{bold} || $params{italic}) {
        if (!exists($fontmap{$params{face}})) {
            croak "Don't know about $params{face} for bold/italic,\ntry specifying the bold/italic name directly\ne.g. Times-BoldItalic";
        }
        my $type = '';
        if ($params{bold}) {
            $type .= 'bold';
        }
        if ($params{italic}) {
            $type .= 'italic';
        }
        if (!exists($fontmap{$params{face}}{$type})) {
            croak "No such font $params{face}-$type";
        }
        $params{face} = $fontmap{$params{face}}{$type};
    }
    else {
        if (my $face = $fontmap{$params{face}}{plain}) {
            $params{face} = $face;
        }
    }

    return %params;
}

=head2 set_font(...)

Set the current font being used. The parameters allowed are:

=over 4

=item face

The font face to use. Best to choose from one of the builtin fonts:

  Courier
  Helvetica
  Symbol
  Times
  ZapfDingbats

=item size

The font size in points. This defaults to the current font size,
or 10.0 point.

=item bold

Set to true to get a bold font - only supported for the builtin
fonts listed above.

=item italic

Set to true to get an italicised font - only supported for the
builtin fonts listed above.

=item encoding

One of "host" (default), "builtin", "winansi", "ebcdic", or
"macroman".

See the pdflib documentation for more details.

=item embed

If set to a true value, this will embed the font in the PDF
file. This can be useful if using fonts outside of the 14
listed above, but extra font metrics information is required
and you will need to read the pdflib documentation for more
information.

=back

=cut

sub set_font {
    my $pdf = shift;
    my %params = lookup_font(@_); # expecting: face, size, bold, italic

    $params{size} ||= $pdf->get_value('fontsize') || 10.0;

    if ($params{handle}) {
        return PDF_setfont($pdf->_pdf, $params{handle}, $params{size});
    }

    if (exists $pdf->{current_font} &&
        lc($pdf->{current_font}{face}) eq lc($params{face}) )
    {
        return PDF_setfont($pdf->_pdf, $pdf->{current_font}->{handle}, $params{size});
    }

    # warn("PDF_findfont(\$p, '$fontstring', 'host', 0);\n");
    my $font = PDF_findfont($pdf->_pdf,
                $params{face},
                $params{encoding} || 'host',
                $params{embed} || 0
                );
    # warn("font: $font\n");

    $pdf->{current_font}->{handle} = $font;
    $pdf->{current_font}->{face} = $params{face};
    $pdf->{current_font}->{size} = $params{size};

    # warn("font handle: $font (size: $params{size})\n");

    PDF_setfont($pdf->_pdf, $font, $params{size});
}

=head2 string_width(text => $text)

Returns the width of the text in the current font face and size.

Alternatively pass in the following options:

=over 4

=item face

The font face to use.

=item size

Text size in the current user coordinates.

=item bold

Use a bold font (works only for Courier, Helvetica and Times)

=item italic

Use an italic font (works only for Courier, Helvetica and Times)

=item encoding

See set_font above.

=item embed

See set_font above.

=cut

sub string_width {
    my $pdf = shift;
    # expecting text, [face, size, bold, italic, encoding, embed]
    my %params = lookup_font(@_);

    $params{size} ||= $pdf->get_value("fontsize") || 10.0;
    
    my $font;
    if ( exists($pdf->{current_font}) ) {
        if ( $params{face} && lc($pdf->{current_font}{face}) ne lc($params{face})) {
            $font = PDF_findfont($pdf->_pdf,
                        $params{face},
                        $params{encoding} || 'host',
                        $params{embed} || 0,
                    );
        }
        else {
            $font = $pdf->{current_font}{handle};
        }
    }
    else {
        $font = 0;
    }

    return PDF_stringwidth($pdf->_pdf,
        $params{text}, $font, $params{size}
    );
}

=head2 set_text_pos(x, y)

Sets the current text output position.

=cut

sub set_text_pos {
    my $pdf = shift;
    
    $pdf->start_page() unless $pdf->stacklevel >= $stacklevel{'page'};
    
    my ($x, $y) = @_;
    
    PDF_set_text_pos($pdf->_pdf, $x, $y);
}

=head2 get_text_pos

Returns the current text output position as a list (x, y).

=cut

sub get_text_pos {
    my $pdf = shift;
    
    return $pdf->get_value("textx"), $pdf->get_value("texty");
}

=head2 print($text)

Prints the text passed as a parameter to the current page (and creates
a new page if there is no current page) at the current output position.

Note: this will B<not> wrap, and text can and will fall off the edge of
your page.

=cut

sub print {
    my $pdf = shift;
    $pdf->start_page() unless $pdf->stacklevel >= $stacklevel{'page'};

    my @pos = $pdf->get_text_pos();
    PDF_show($pdf->_pdf, $_[0]);
    if ($pdf->{underline}) {
        my @newpos = $pdf->get_text_pos();
        $pdf->move_to($pos[0],$pos[1]-1);
        $pdf->line_to($newpos[0],$newpos[1]-1);
        $pdf->stroke();
        $pdf->set_text_pos(@newpos);
    }
}

=head2 print_at($text, x => $x, y => $y)

Prints text at the given X and Y coordinates.

=cut

sub print_at {
    my $pdf = shift;
    my ($text, %params) = @_;

    $pdf->start_page() unless $pdf->stacklevel >= $stacklevel{'page'};

    PDF_show_xy($pdf->_pdf, $text, @params{qw(x y)});
}

=head2 print_boxed($text, ...)

This is perhaps the most interesting output method as it allows
you to define a bounding box to put the text into, and PDFLib
will wrap the text for you. The only problem with it is that you
cannot change the font while printing into this kind of bounding
box. Better to use L<"new_bounding_box"> below.

The parameters you can pass are:

=over 4

=item mode

One of "left", "right", "center", "justify" or "fulljustify".

=item blind

This parameter allows you to output invisible text. Useful for
testing whether the text will fit into your bounding box.

=item x and y

The X and Y positions (bottom left hand corner) of your bounding box.

=item w and h

The width and height of your bounding box.

=back

Returns zero, or the number of characters from your text that
would not fit into the box.

=cut

sub print_boxed {
    my $pdf = shift;
    my ($text, %params) = @_;
    
    $pdf->start_page() unless $pdf->stacklevel >= $stacklevel{'page'};
    
    $params{mode} ||= 'left';
    $params{blind} ||= "";
    
    PDF_show_boxed($pdf->_pdf, $text, @params{qw(x y w h mode blind)});
#    PDF_rect($pdf->_pdf, @params{qw(x y w h)});
#    PDF_stroke($pdf->_pdf);
}

=head2 print_line($text)

Print the text at the current output position, with a carriage return
at the end.

=cut

sub print_line {
    my $pdf = shift;
    
    $pdf->start_page() unless $pdf->stacklevel >= $stacklevel{'page'};

    PDF_continue_text($pdf->_pdf, $_[0]);
}

=head2 get_value($key, [$modifier])

There are many values that you can retrieve from pdflib, all are
covered in the extensive documentation. This method is a wrapper
for that.

=cut

sub get_value {
    my $pdf = shift;
    my $key = shift;
    my $modifier = shift || 0;

    return PDF_get_value($pdf->_pdf, $key, $modifier);
}

=head2 set_value($key => $value)

PDFLib also allows you to set values. This method does just that.
Note that not all values that you can "get" allow you to also
"set" that value. Read the pdflib documentation for more information
on values you can set.

=cut

sub set_value {
    my $pdf = shift;
    
    PDF_set_value($pdf->_pdf, $_[0], $_[1]);
}

=head2 get_parameter($param, [$modifier])

This is very similar to get_value above. No, I don't know why
pdflib makes this distinction, before you ask :-)

=cut

sub get_parameter {
    my $pdf = shift;
    my $param = shift;
    my $modifier = shift || 0;
    
    return PDF_get_parameter($pdf->_pdf, $param, $modifier);
}

=head2 set_parameter($param => $value)

Same again. See the pdflib docs for which options are available.

=cut

sub set_parameter {
    my $pdf = shift;

    PDF_set_parameter($pdf->_pdf, $_[0], $_[1]);
}

=head2 new_bounding_box(%params)

Creates a new BoundingBox (see below) that you can print into.

Example:

  my $bb = $pdf->new_bounding_box(
        x => 30, y => 800, w => 300, h => 800
    );
  $bb->print($long_text);
  $bb->finish; # MUST call this!

Valid parameters are:

=over 4

=item x and y (required)

The x and y coordinates of the start of the bounding box.

=item w and h (required)

The width and height of the bounding box.

=item align (default = 'left')

The alignment of the text in the bounding box. Can be "centre", or
"center" (for the Americans), or "right" or "left".

=item wrap (default = 1)

Whether or not to automatically wrap the text. At the moment this will
automatically wrap at whitespace only. It will not do any fancy
hyphenation or justification. If you turn wrapping off, you are
expected to do your own wrapping using either newlines, or print_line.

=back

=cut

sub new_bounding_box {
    my $pdf = shift;
    return PDFLib::BoundingBox->new($pdf, @_);
}



=head2 load_image(...)

Load an image. Parameters available are:

=over 4

=item filetype

One of "png", "gif", "jpeg", or "tiff". Unfortunately PDFLib does
not do filetype sniffing, yet.

=item filename

The name of the image file to open.

=item stringparam and intparam

See the pdflib documentation for PDF_open_image for more details.

=back

This returns a PDFLib::Image object.

=cut

sub load_image {
    my $pdf = shift;
    croak "Cannot load images unless at document level"
                if $pdf->stacklevel > $stacklevel{document};

    my %params = @_;
    
    my $img = PDFLib::Image->open(pdf => $pdf, %params);

    push @{$pdf->{images}}, $img;

    return $img;
}

=head2 add_image(...)

Add an image to the current page (or creates a new page if necessary).

Options are passed as name/value pairs. Available options are:

=over 4

=item img

The PDFLib::Image object, returned from load_image() above.

=item x

The x coordinate

=item y

The y coordinate

=item scale

The scaling of the image. This defaults to 1.0.

=item scale_x

Horizontal scaling.

=item scale_y

Vertical scaling.

=item w

The width.

=item h

The height.

Either specify scale I<or> (scale_x I<and> scale_y), I<or> (w I<and> h) I<or> none.

=item dpi

The desired image DPI. If left out, uses the image's true DPI value, if available.
B<Please Note:> This is different than before, where all images were treated as having 72dpi.
If your legacy application needs this behaviour and cannot easily be modified, set
C<$PDFLib::DPI = 72;>.

=back

=cut

our $DPI = 0;

sub add_image {
    my $pdf = shift;
    my %params = @_;
    
    $pdf->start_page() unless $pdf->stacklevel >= $stacklevel{'page'};
    
    my $dpi = $params{dpi} || $DPI;

    if ($params{w}) {
        PDF_fit_image($pdf->_pdf, $params{img}->img,
                      $params{x}, 
                      $params{y}, 
                      "dpi $dpi fitmethod entire boxsize {$params{w} $params{h}}");
    } elsif ($params{scale_x}) {
        PDF_fit_image($pdf->_pdf, $params{img}->img,
                      $params{x}, 
                      $params{y}, 
                      "dpi $dpi scale {$params{scale_x} $params{scale_y}}");
    } elsif ($params{scale}) {
        PDF_fit_image($pdf->_pdf, $params{img}->img,
                      $params{x}, 
                      $params{y}, 
                      "dpi $dpi scale $params{scale}");
    } else {
        PDF_fit_image($pdf->_pdf, $params{img}->img,
                      $params{x}, 
                      $params{y}, 
                      "dpi $dpi");
    }
}

=head2 add_bookmark(...)

Adds a bookmark to the PDF file (normally displayed in a tree
view on the left hand side of the pages in Adobe acrobat reader).
Takes the following parameters:

=over 4

=item text

The text of the bookmark

=item parent_of

The parent bookmark for generating hierarchies. This should be 
a value returned from a previous call to add_bookmark, e.g.

  my $root_bm = $pdf->add_bookmark(text => "My Root Bookmark");
  my $next_bm = $pdf->add_bookmark(text => "Child Bookmark",
                                   parent_of => $root_bm);

=item open

Whether this bookmark is expanded in the tree view by default
when the PDF is first opened.

=back

=cut

sub add_bookmark {
    my $pdf = shift;
    my %params = @_;
    
    $params{parent_of} ||= 0;
    $params{open} ||= 0;
    
    return PDF_add_bookmark($pdf->_pdf, $params{text}, $params{parent_of}, $params{open});
}

=head2 add_link(...)

Turns a square area of the page into a web link. Takes the following parameters:

=over 4

=item x, y, w, h

X and Y coordinates of the lower left hand side of the box, and width and
height of the box.

=item link

The actual link. Must start with one of "http:", "https:", "ftp:", or
"mailto:".

=back

=cut

sub add_link {
    my $pdf = shift;
    
    my %params = @_;

    my $link = $params{link};
    my ($llx, $lly) = @params{'x', 'y'};
    my ($urx, $ury) = ($llx + $params{w}, $lly + $params{h});
    if ($link =~ /^(https?|ftp|mailto):/) {
        PDF_add_weblink($pdf->_pdf, $llx, $lly, $urx, $ury, $link);
    }
}

=head2 set_border_style($style, $width)

The border in question here is a border around a link. Style must
be one of "solid" or "dashed". Note that links have a border 
around them by default, so you need to unset that with:

  $pdf->set_border_style("solid", 0);

Unless you want all your links to have ugly boxes around them

Note: This will not help broken linux clients like xpdf and
gv (or other viewers based on ghostscript) which display a border
around links anyway, sadly.

=cut

sub set_border_style {
    my $pdf = shift;
    my ($style, $width) = @_;

    PDF_set_border_style($pdf->_pdf, $style, $width);
}

sub set_border_color {
    my $pdf = shift;
    my ($r,$g,$b) = @_;

    PDF_set_border_color($pdf->_pdf, $r,$g,$b);
}

sub set_border_dash {
    my $pdf = shift;
    my ($b, $w) = @_;

    PDF_set_border_dash($pdf->_pdf, $b, $w);
}

sub add_thumbnail {
    my $pdf = shift;
    my $image = shift;

    PDF_add_thumbnail($pdf->_pdf, $image->img);
}

##################################################################
# graphics functions
##################################################################

=head1 Graphics Functions

Doing graphics in PDFLib is fairly easy, though there are some
gotchas to watch out for. For example, using line_to() does not
draw the line immediately - to finalize the line you have to call
stroke(). This is because PDFLib allows you to instead call fill(),
in case you wish to draw some funny shape and fill it in. Here's
a quick example of drawing a line:

  $pdf->start_page;

  $pdf->move_to(20, 20);
  $pdf->line_to(400, 400);
  $pdf->stroke;

Which draws a line from the bottom left to the middle of the page.

All graphics calls must be accompanied by a call to either one of
stroke, close_path_stroke, fill, fill_stroke, close_path_fill_stroke,
clip, or end_path. (note this means you can have 1 or 4 or 36
graphics calls, and a single call to one of the above, but beware
of the results).

=head2 set_dash(LIST)

Set the current dash pattern. The list should be an alternating
black/white length. For example:

  $pdf->set_dash(3,1,4,2);

The dash is reset at the beginning of each new page.

=cut

sub set_dash {
    my $pdf = shift;
    if (@_ == 2) {
        return PDF_setdash($pdf->_pdf, $_[0], $_[1]);
    }
    else {
        return PDF_setpolydash($pdf->_pdf, [@_]);
    }
}

=head2 set_flat($flatness)

Sets the flatness of lines.

Flatness describes the maximum distance (in device pixels) between
the path and an approximation constructed from straight line segments.

(I don't really know what that means, explanations would be welcome!)

=cut

sub set_flat {
    my $pdf = shift;
    PDF_setflat($pdf->_pdf, shift);
}

my %linejoins = (
    miter => 0,
    round => 1,
    bevel => 2,
);

=head2 set_line_join

Sets the shape of the corners of paths that are stroked.

Pass in a single option, one of: "miter", "round", or "bevel".

Think of them like this:

 miter: \
         \
          >
         /
        /

 round: \
         \
          )
         /
        /

 bevel: \
         \
          |
         /
        /

=cut

sub set_line_join {
    my $pdf = shift;
    my $join = shift;
    PDF_setlinejoin($pdf->_pdf, $linejoins{$join} || $join);
}

my %linecaps = (
    butt_end => 0,
    round_end => 1,
    square_end => 2,
);

=head2 set_line_cap

Sets the shape at the end of a path with respect to stroking.

Pass in a single option, one of: "butt_end", "round_end", or
"square_end".

Think of them like this:

  butt_end   ----|

  round_end  ----)

  square_end ----] (protrudes line_width/2 beyond end point)

=cut

sub set_line_cap {
    my $pdf = shift;
    my $cap = shift;
    PDF_setlinecap($pdf->_pdf, $linecaps{$cap} || $cap);
}

=head2 set_miter_limit($limit)

Sets the miter limit. See the pdflib manual for more information

=cut

sub set_miter_limit {
    my $pdf = shift;
    PDF_setmiterlimit($pdf->_pdf, shift);
}

=head2 set_line_width($width)

Set the current line width. $width is in units of the current user
coordinate system.

=cut

sub set_line_width {
    my $pdf = shift;
    PDF_setlinewidth($pdf->_pdf, shift);
}

=head2 reset_graphics

Resets all the graphics options to their defaults.

=cut

sub reset_graphics {
    my $pdf = shift;
    PDF_initgraphics($pdf->_pdf);
}

=head2 save_graphics_state

Save the current graphics state. Must be balanced by a
restore_graphics_state().

save/restore graphics states can be nested, though at the moment
it is up to you to ensure they balance on a page. This may be
changed for some Perl magic in the future though.

=cut

sub save_graphics_state {
    my $pdf = shift;
    PDF_save($pdf->_pdf);
}

=head2 restore_graphics_state

Restore the last saved graphics state.

=cut

sub restore_graphics_state {
    my $pdf = shift;
    PDF_restore($pdf->_pdf);
}

=head2 move_to($x, $y)

Set the current point.

=cut

sub move_to {
    my $pdf = shift;
    croak "Invalid number of params (need two)" unless @_ == 2;
    croak "Cannot draw without a page" unless $pdf->stacklevel >= $stacklevel{page};
    $pdf->{stacklevel} = 'path';
    PDF_moveto($pdf->_pdf, $_[0], $_[1]);
}

=head2 line_to($x, $y)

Draw a line from the current point to the coordinates specified.

=cut

sub line_to {
    my $pdf = shift;
    croak "Invalid number of params (need two)" unless @_ == 2;
    croak "Cannot draw without a page" unless $pdf->stacklevel >= $stacklevel{page};
    $pdf->{stacklevel} = 'path';
    PDF_lineto($pdf->_pdf, $_[0], $_[1]);
}

=head2 bezier

Draw a bezier curve from the current point to (x3, y3), using
the points (x1, y1) and (x2, y2) as control points. Parameters
are passed as a hash:

  $pdf->bezier(
      x1 => 20, y1 => 20,
      x2 => 40, y1 => 0,
      x3 => 20, y1 => 60,
  );

=cut

sub bezier {
    my $pdf = shift;
    croak "Cannot draw without a page" unless $pdf->stacklevel >= $stacklevel{page};
    my %params = @_;
    $pdf->{stacklevel} = 'path';
    PDF_curveto($pdf->_pdf, @params{qw(x1 y1 x2 y2 x3 y3)});
}

=head2 circle

Draw a circle using parameters x, y and r (radius).

=cut

sub circle {
    my $pdf = shift;
    croak "Cannot draw without a page" unless $pdf->stacklevel >= $stacklevel{page};
    my %params = @_;
    $pdf->{stacklevel} = 'path';
    PDF_circle($pdf->_pdf, @params{qw(x y r)});
}

=head2 arc

Draw an arc. Parameters are:

=over 4

=item x, y

The coordinates of the centre of the circular arc segment

=item r

The radius of the arc.

=item alpha, beta

The start and end angles of the arc.

=back

=cut

sub arc {
    my $pdf = shift;
    croak "Cannot draw without a page" unless $pdf->stacklevel >= $stacklevel{page};
    my %params = @_;
    $pdf->{stacklevel} = 'path';
    if ($params{clockwise}) {
        PDF_arcn($pdf->_pdf, @params{qw(x y r alpha beta)});
    }
    else {
        PDF_arc($pdf->_pdf, @params{qw(x y r alpha beta)});
    }
}

=head2 rect

Draw a rectangle. Parameters are passed as a hash, and are
simply x, y, w, h.

=cut

sub rect {
    my $pdf = shift;
    croak "Cannot draw without a page" unless $pdf->stacklevel >= $stacklevel{page};
    my %params = @_;
    $pdf->{stacklevel} = 'path';
    PDF_rect($pdf->_pdf, @params{qw(x y w h)});
}

=head2 close_path

Close the current path.

This draws a line from the current point to the starting point
of the subpath.

=cut

sub close_path {
    my $pdf = shift;
    return unless $pdf->stacklevel >= $stacklevel{path};
    $pdf->{stacklevel} = 'page'; # hmm, could be template?
    PDF_closepath($pdf->_pdf);
}

=head2 stroke

Draws the current path as line.

You must call this (or one of the path ending functions) or no line
will be drawn.

=cut

sub stroke {
    my $pdf = shift;
    return unless $pdf->stacklevel >= $stacklevel{path};
    $pdf->{stacklevel} = 'page'; # hmm, could be template?
    PDF_stroke($pdf->_pdf);
}

=head2 close_path_stroke

Closes the path and strokes it.

=cut

sub close_path_stroke {
    my $pdf = shift;
    return unless $pdf->stacklevel >= $stacklevel{path};
    $pdf->{stacklevel} = 'page'; # hmm, could be template?
    PDF_closepath_stroke($pdf->_pdf);
}

=head2 fill

Fills the current path using the currently selected colour.

=cut

sub fill {
    my $pdf = shift;
    return unless $pdf->stacklevel >= $stacklevel{path};
    $pdf->{stacklevel} = 'page'; # hmm, could be template?
    PDF_fill($pdf->_pdf);
}

=head2 fill_stroke

Fills the current path and strokes it.

=cut

sub fill_stroke {
    my $pdf = shift;
    return unless $pdf->stacklevel >= $stacklevel{path};
    $pdf->{stacklevel} = 'page'; # hmm, could be template?
    PDF_fill_stroke($pdf->_pdf);
}

=head2 close_path_fill_stroke

Closes the current path, fills it, and strokes it.

=cut

sub close_path_fill_stroke {
    my $pdf = shift;
    return unless $pdf->stacklevel >= $stacklevel{path};
    $pdf->{stacklevel} = 'page'; # hmm, could be template?
    PDF_closepath_fill_stroke($pdf->_pdf);
}

=head2 clip

Uses the current path as a clipping region. Often useful in
conjunction with save/restore_graphics_state.

=cut

sub clip {
    my $pdf = shift;
    return unless $pdf->stacklevel >= $stacklevel{path};
    $pdf->{stacklevel} = 'page'; # hmm, could be template?
    PDF_clip($pdf->_pdf);
}

=head2 end_path

Ends the path without doing anything.

=cut

sub end_path {
    my $pdf = shift;
    return unless $pdf->stacklevel >= $stacklevel{path};
    $pdf->{stacklevel} = 'page'; # hmm, could be template?
    PDF_endpath($pdf->_pdf);
}

=head1 Changing the Coordinate System

PDFLib allows you to alter the coordinate system in various ways while you are working.
This is affected by save/restore_graphics_state, so it's always useful to wrap these
methods around a save/restore block.

The most useful thing this allows you to do is draw shapes not listed above, like ellipses,
parallelograms, etc.

=head2 coord_translate ($x, $y)

Translate the coordinate system by x, y

=cut

sub coord_translate {
    my $pdf = shift;
    my ($x, $y) = @_;
    PDF_translate($pdf->_pdf, $x, $y);
}

=head2 coord_scale ($xscale, $yscale)

Scale the coordinate system.

=cut

sub coord_scale {
    my $pdf = shift;
    my ($xscale, $yscale) = @_;
    PDF_scale($pdf->_pdf, $xscale, $yscale);
}

=head2 coord_rotate ($degrees)

Rotate the coordinate system the given number of degrees (0 - 360)

=cut

sub coord_rotate {
    my $pdf = shift;
    my ($degrees) = @_;
    PDF_rotate($pdf->_pdf, $degrees);
}

=head2 coord_skew ($xshear, $yshear)

Skew (or shear) the coordinate system by the number of degrees given in the X
and Y directions.

=cut

sub coord_skew {
    my $pdf = shift;
    my ($xshear, $yshear) = @_;
    PDF_skew($pdf->_pdf, $xshear, $yshear);
}

=head2 coord_set_matrix (%params)

Set the current transformation matrix. This is heavy stuff - use the other
functions instead unless you know what you're doing.

Params are a hash containing a, b, c, d, e and f entries.

=cut

sub coord_set_matrix {
    my $pdf = shift;
    my %params = @_;
    PDF_setmatrix($pdf->_pdf, @params{qw(a b c d e f)});
}

=head2 coord_concat_matrix (%params)

Concatenate to the current transformation matrix.

Params are the same as coord_set_matrix.

=cut

sub coord_concat_matrix {
    my $pdf = shift;
    my %params = @_;
    PDF_concat($pdf->_pdf, @params{qw(a b c d e f)});
}

=head1 Colour Functions

=head2 set_colour/set_color

This function allows you to set the current colour.

The color can be specified in a number of ways, but always as
a hash parameter somehow. It is easiest to show using examples:

  # 40% grayscale.
  $pdf->set_color(gray => 0.4);

  $pdf->set_color(rgb => [$r, $g, $b]);

  $pdf->set_color(cmyk => [$c, $m, $y, $k]);

  # see make_spot_color below
  $pdf->set_color(spot => { handle => $h, tint => 0.3 });

  # see make_pattern below
  $pdf->set_color(pattern => $pattern);

You can also pass in a type parameter to set either the "stroke" or
the "fill" colour, or "both". The default is "both":

  $pdf->set_color(type => 'stroke', gray => 0.5);

=cut

sub set_color {
    my $pdf = shift;
    my %params = @_;

    $params{type} ||= "both";

    if (my $grayscale = $params{gray} || $params{grey}) {
        return PDF_setcolor($pdf->_pdf,
            $params{type}, "gray", $grayscale, 0, 0, 0);
    }
    elsif (my $rgb = $params{rgb}) {
        return PDF_setcolor($pdf->_pdf, $params{type}, "rgb",
                $rgb->[0], $rgb->[1], $rgb->[2], 0);
    }
    elsif (my $cmyk = $params{cmyk}) {
        return PDF_setcolor($pdf->_pdf, $params{type}, "cmyk",
                @{$cmyk}[0..3]);
    }
    elsif (my $spot = $params{spot}) {
        return PDF_setcolor($pdf->_pdf, $params{type}, "spot",
                $spot->{handle}, $spot->{tint}, 0, 0);
    }
    elsif (my $pattern = $params{pattern}) {
        return PDF_setcolor($pdf->_pdf, $params{type}, "pattern",
                $pattern, 0, 0, 0);
    }
}

*set_colour = \&set_color; # yicky americanisms!

sub set_decoration {
    my ($self,$val) = @_;
    $self->{underline} = ($val eq 'underline');
}

=head2 make_spot_color/make_spot_colour

Makes a named spot colour using the name passed as a parameter.

Useful for saving away the current colour to restore it later.

=cut

sub make_spot_color {
    my $pdf = shift;
    my $colour = shift;
    PDF_makespotcolor($pdf->_pdf, $colour, length($colour));
}

*make_spot_colour = \&make_spot_color;

=head2 begin_patter

Starts a pattern. Parameters are passed as a hash of width,
height, xstep, ystep, and painttype. See the pdflib manual
for more details.

=cut

sub begin_pattern {
    my $pdf = shift;
    my %params = @_;

    PDF_begin_pattern($pdf->_pdf,
        @params{qw(width height xstep ystep painttype)});
}

=head2 end_pattern

Finishes the current pattern.

=cut

sub end_pattern {
    my $pdf = shift;
    PDF_end_pattern($pdf->_pdf);
}

package PDFLib::Page;

use pdflib_pl 4.0;

use vars qw(%Size);

=head1 PDFLib::Page

=head2 %Size

You can access the built-in page sizes directly via the
C<%PDFLib::Page::Size> hash. For example:

  my @a4 = @{ $PDFLib::Page::Size{a4} };

Which gives you a width and a height in the array. This can
be useful for making sure you don't overstep the bounds of a
page when drawing. See "Default Paper Sizes" below for the
available sizes.

=cut

%Size = (
        a0 => [2380, 3368],
        a1 => [1684, 2380],
        a2 => [1190, 1684],
        a3 => [842, 1190],
        a4 => [595, 842],
        a5 => [421, 595],
        a6 => [297, 421],
        b5 => [501, 709],
        letter => [612, 792],
        legal => [612, 1008],
        ledger => [1224, 792],
        11x17 => [792, 1224],
        slides => [612, 450],
        );

sub new {
    my $class = shift;
    my ($pdf, %params) = @_;

    $params{papersize} ||= 'a4';
    $params{orientation} ||= 'portrait';

    my ($x, $y) = @{$Size{$params{papersize}}};
    if ($params{orientation} eq 'landscape') {
#        warn("swapping aspect\n");
        ($x, $y) = ($y, $x); # swap around!
    }

#    warn("PDF_begin_page($x, $y)\n");
    PDF_begin_page($pdf, $x, $y);

    $params{pdf} = $pdf;

    return bless \%params, $class;
}

sub DESTROY {
    my $self = shift;
}

##################################################################
# PDFLib::Image - Image Support Class
##################################################################

=head1 PDFLib::Image API

The following methods are available on the object returned from
C<$pdf->load_image()> above.

=cut

package PDFLib::Image;

use pdflib_pl 4.0;
use Carp;

sub open {
    my $class = shift;
    my %params = @_;

    $params{pdf}->set_parameter(imagewarning => "true");

    if (!-e $params{filename}) {
        croak("File '$params{filename}' doesn't exist!");
    }

    my $image_handle = PDF_open_image_file(
                $params{pdf}->_pdf,
                $params{filetype},
                $params{filename},
                $params{stringparam} || "",
                $params{intparam} || 0,
                );

    if ($image_handle == -1) {
        PDF_set_parameter($params{pdf}->_pdf, "imagewarning", "true");
        croak "Cannot open image file '$params{filename}': $!";
    }

    $params{handle} = $image_handle;
    return bless \%params, $class;
}

sub img {
    my $self = shift;
    return $self->{handle};
}

=head2 width

Return the image's width in points.

=cut

sub width {
    my $self = shift;
    return $self->{pdf}->get_value("imagewidth", $self->img);
}

=head2 height

Return the image's height in points.

=cut

sub height {
    my $self = shift;
    return $self->{pdf}->get_value("imageheight", $self->img);
}

sub close {
    my $self = shift;
    PDF_close_image(shift, $self->{handle});
}

##################################################################
# PDFLib::BoundingBox - Bounded Printing
##################################################################

package PDFLib::BoundingBox;

use vars qw(@ISA);
@ISA = qw(PDFLib);
use pdflib_pl 4.0;
use Carp;

=head1 PDFLib::BoundingBox

BoundingBox is a bounded printing API. You create a bounding box, then print
into it, and it wraps and/or ensures you don't print outside of that box.

For details of bounding boxes, see L<"new_bounding_box"> above.

When you are finished with a bounding box, you B<must> call finish() on
it so that it can clean up.

Also note that if you create subsequent bounding boxes one after the other,
a font change on the bounding box B<will> have effect on the next bounding
box - it's transparently passed through to the page level. This is probably
desirable (see the output of t/06bounding.t in the distribution for example).

=cut

sub new {
    my $class = shift;
    my ($pdf, %args) = @_;

    croak "Invalid BoundingBox params" unless
        exists($args{x}) && exists($args{y}) && $args{w} && $args{h};

    $args{wrap} = 1 if (!exists($args{wrap}));
    $args{align} ||= 'left';
    $args{align} = 'centre' if $args{align} eq 'center';

    my $self = bless {%$pdf, %args, todo => [], cur_width => 0},
                     $class;

    if ($self->{align} eq 'centre') {
    	$self->{x} = $self->{x} + ($self->{w}/2);
    }

    $self->{y2} = $self->{y};
    $self->{finished} = 0;
    $self->{fontname} = $self->SUPER::get_parameter("fontname");
    $self->{fontsize} = $self->SUPER::get_value("fontsize");
    
    $self->set_text_pos($self->{x}, $self->{y});

    return $self;
}

sub finish {
    my $self = shift;
    return if $self->{finished};
    my $xpos = $self->{align} eq 'centre' ?
            ($self->{x} - ($self->{cur_width}/2))
            :
        $self->{align} eq 'right' ?
            ($self->{x} - $self->{cur_width})
            :
        $self->{align} eq 'left' ?
            $self->{x}
            :
            croak "No such alignment: $self->{align}";
    $self->set_text_pos($xpos, $self->{y2});
    $self->run_todo;
    $self->{finished} = 1;
}

sub DESTROY {
    my $self = $_[0];
    bless($_[0], 'PDFLib::BoundingBox');
    $self->finish;
}

sub push_todo {
    my $self = shift;
    push @{$self->{todo}}, [ @_ ];
}

sub run_todo {
    my $self = shift;
    my $fontname = $self->SUPER::get_parameter("fontname");
    my $fontsize = $self->SUPER::get_value("fontsize");
    my $underline = $self->{underline};
    $self->SUPER::set_font(face => $self->{fontname}, size => $self->{fontsize});
    for my $ref (@{$self->{todo}}) {
	my ($method, @params) = @$ref;
        $method = "PDFLib"->can($method);
        $method->($self, @params);
    }
    $self->{fontname} = $self->SUPER::get_parameter("fontname");
    $self->{fontsize} = $self->SUPER::get_value("fontsize");
    $self->SUPER::set_font(face => $fontname, size => $fontsize);
    $self->SUPER::set_decoration($underline?'underline':'none');
    $self->{todo} = [];
}

sub set_font {
    my $self = shift;
    my @params = @_;
    $self->push_todo(set_font => @params);
    $self->SUPER::set_font(@params);
}

sub set_decoration {
    my $self = shift;
    my @params = @_;
    $self->push_todo(set_decoration => @params);
#    $self->SUPER::set_decoration(@params);
}

sub set_color {
    my $self = shift;
    my @params = @_;
    $self->push_todo(set_color => @params);
#    $self->SUPER::set_color(@params);
}

*set_colour = \&set_color;

sub print_line {
    my $self = shift;
    my @params = @_;
    $self->push_todo(print_line => @params);
    $self->{cur_width} = 0;
#    $self->SUPER::print_line(@params);
}

sub set_value {
    my $self = shift;
    my @params = @_;
    $self->push_todo(set_value => @params);
#    $self->SUPER::set_value(@params);
}

sub set_parameter {
    my $self = shift;
    my @params = @_;
    $self->push_todo(set_parameter => @params);
#    $self->SUPER::set_parameter(@params);
}

=head2 print($text)

Returns the characters it could not fit into the bounding box,
which is useful if you are doing multiple bounding boxes or pages.

=cut

sub print {
    my $self = shift;
    if (!$self->{wrap}) {
        my $text = shift;
        my @lines = split(/\n/, $text, -1);
        my $last = pop(@lines);
        while (@lines) {
            my $line = shift(@lines);
            $self->SUPER::print($line);
            
            # font resets on newline...
#            my $font = $self->{"fontname"};
#            my $size = $self->{"fontsize"};
#            my $leading = $self->get_value("leading");
            
            $self->SUPER::print_line("");
            (undef, $self->{y2}) = $self->get_text_pos;
            # if ($self->{y2} < (($PDFLib::Page::Size{$self->papersize}[1] - $self->{y}) - $self->{h})) {
            if ($self->{y2} < ($self->{y} - $self->{h})) {
                # gone overboard
                return join("\n", @lines, $last);
            }
            
#            $self->SUPER::set_font(face => $font, size => $size);
#            $self->SUPER::set_value(leading => $leading);
        }
        $self->SUPER::print($last) if ($last);
    }
    else {
        my $text = shift;
        my $width = $self->string_width(text => $text);
        if (($width + $self->{cur_width}) <= $self->{w}) {
            $self->{cur_width} += $width;
            $self->push_todo(print => $text);
        }
        else {
            # too wide - split into words and print
            $text =~ s/(\x0D?\x0A|\x0D)/ /g;
            while (length($text)) {
                $text =~ s/^(\S*\s*)// or last;
                my $word = $1;
                my $width = $self->string_width(text => $word);
                if (($width + $self->{cur_width}) <= $self->{w}) {
                    $self->{cur_width} += $width;
                    $self->push_todo(print => $word);
                }
                else {
                    # word carries us over the line
                    my $xpos = $self->{align} eq 'centre' ?
                            ($self->{x} - ($self->{cur_width}/2))
                            :
                        $self->{align} eq 'right' ?
                            ($self->{x} - $self->{cur_width})
                            :
                        $self->{align} eq 'left' ?
                            $self->{x}
                            :
                            croak "No such alignment: $self->{align}";
                    $self->set_text_pos($xpos, $self->{y2});
                    $self->run_todo;

                    # font resets on newline...
#                    my $font = $self->get_parameter("fontname");
#                    my $size = $self->get_value("fontsize");
#                    my $leading = $self->get_value("leading");

                    $self->SUPER::print_line("");
                    (undef, $self->{y2}) = $self->get_text_pos;
                    if ($self->{y2} < ($self->{y} - $self->{h})) {
                        # gone overboard
                        return $word . $text;
                    }

#                    $self->set_font(face => $font, size => $size);
#                    $self->set_value(leading => $leading);
                    $self->push_todo( print => $word );
                    $self->{cur_width} = $width;
                }
            }
        }
    }
    return;
}

1;
__END__

=head1 Default Paper Sizes

The following paper sizes are available. Units are in "points".
Any of these can be rotated by providing an orientation of
"landscape". Alternate paper sizes can be used by passing an
array ref of [x, y] to anything requiring a papersize, but that
generally shouldn't be necessary.

=over 4

=item a0

2380 x 3368

=item a1

1684 x 2380

=item a2

1190 x 1684

=item a3

842 x 1190

=item a4

595 x 842

=item a5

421 x 595

=item a6

297 x 421

=item b5

501 x 709

=item letter

612 x 792

=item legal

612 x 1008

=item ledger

1224 x 792

=item 11x17

792 x 1224

=item slides

612 x 450

=back

=head1 TODO

Lots more of the pdflib API needs to be added and tested here.
Notably the support for other types of attachments, and support
for all of the graphics primatives.

=head1 AUTHOR

AxKit.com Ltd,

Matt Sergeant, matt@axkit.com

=head1 LICENSE

This is free software. You may distribute it under the same
terms as Perl itself.

=cut
