package PDF::API2::Simple;

=head1 NAME

PDF::API2::Simple - Simplistic wrapper for the excellent PDF::API2 modules

=head1 SYNOPSIS

    use PDF::API2::Simple;

    my $pdf = PDF::API2::Simple->new( 
                                     file => 'output.pdf'
                                    );

    $pdf->add_font('VerdanaBold');
    $pdf->add_font('Verdana');
    $pdf->add_page();

    $pdf->link( 'http://search.cpan.org', 'A Hyperlink',
                x => 350,
                y => $pdf->height - 150 );

    for (my $i = 0; $i < 250; $i++) {
         my $text = "$i - All work and no play makes Jack a dull boy";

         $pdf->text($text, autoflow => 'on');
    }

    $pdf->save();

Take note that PDF coordinates are not quite what you're used to. The coordinate, (0, 0) for instance is at
the lower-left hand corner. Thus, x still grows to the right, but y grows towards the top.

=head1 METHODS

=cut

$VERSION = '1.1.4';

use strict;
use PDF::API2;

require Exporter;
require Carp;

our @ISA = qw(Exporter);

=head2 new

     PDF::API2::Simple->new(
		 'file' => 'output.txt',
		 'width' => 612,
		 'height' => 792,
		 'line_height' => 10,
		 'margin_left' => 20,
		 'margin_top' => 20,
		 'margin_right' => 20,
		 'margin_bottom' => 50,
		 'width_right' => 0,
		 'height_bottom' => 0,
		 'effective_width' => 0,
		 'effective_height' => 0,
		 'header' => undef,
		 'footer' => undef,
     );

Creates a new PDF::API2::Simple instance. A good strategy is to create a new object for each
pdf file you want to create. That is, of course, up to you.

=over

=item * file - The PDF file you want to write to. No default, parameter required

=item * width - The width of the PDF file. Defaults to 612, the 8 1/2 x 11 US Letter width

=item * height - The height of the PDF file. Defaults to 792, the 8 1/2 x 11 US Letter height

=item * line_height - The standard height you want to define for lines. The default is 10

=item * margin_left - The amount of margin space you want on the left side. Of course, you can specify whatever coordniates you want. Default is 20

=item * margin_top - The amount of margin space you want on the top of each page. Default is 20

=item * margin_right - The amount of margin space you want of the right side of each page. Default is 20

=item * margin_bottom - The amount of margin space you want on the bottom of each page. Default is 50

=item * width_right - A convenience property that contains the furthest I<x> of the page, accounting for the margins specified

=item * height_bottom - A convenience property that contains the largest C<y> of the page, accounting for the bottom margin

=item * effective_width - A convenience property that contains the width of the page, after the left and right margin have been accounted for

=item * effective_height - A convenience property that contains the height of the page, after the top and bottom margin have been accounted for

=item * header - This C<CODE> reference will be called everytime a page is appended to the PDF, allowing you to specifiy a header for your pages

=item * footer - This C<CODE> reference will be called everytime a page is ended, allowing you to specifiy a footer for your pages

=back

=cut

sub new {
  my ($self, %opts) = @_;

  $self = bless {
		 'file' => $opts{'file'} || undef,
		 'width' => $opts{'width'} || 612,
		 'height' => $opts{'height'} || 792,
		 'line_height' => exists $opts{'line_height'} ? $opts{'line_height'} : 10,
		 'margin_left' => exists $opts{'margin_left'} ? $opts{'margin_left'} : 20,
		 'margin_top' => exists $opts{'margin_top'} ? $opts{'margin_top'} : 20,
		 'margin_right' => exists $opts{'margin_right'} ? $opts{'margin_right'} : 20,
		 'margin_bottom' => exists $opts{'margin_bottom'} ? $opts{'margin_bottom'} : 50,
		 'width_right' => 0,
		 'height_bottom' => 0,
		 'effective_width' => 0,
		 'effective_height' => 0,
		 'header' => $opts{'header'} || undef,
		 'footer' => $opts{'footer'} || undef,
		 
		 '_pdf'  => PDF::API2->new( '-file' => $opts{'file'} ),
		 '_fonts' => { },

		 '_x' => 0,
		 '_y' => 0,
		 '_current_page' => 0,
		 '_current_font' => undef,
		 '_current_font_size' => 10,
		 '_current_stroke_color' => 'black',
		 '_current_fill_color' => 'black'
		}, $self;

  $self->{'_pdf'}->mediabox( $self->{'width'}, $self->{'height'} );
  $self->_set_relative_values();
  $self->_reset_x_and_y();

  return $self;
}

# private methods
# ================================================

sub _reset_x_and_y {
  my $self = shift;

  $self->{'_x'} = $self->margin_left;
  $self->{'_y'} = ($self->height - $self->margin_top);
}

sub _set_relative_values {
  my $self = shift;

  $self->{'width_right'} = $self->width - $self->margin_right;
  $self->{'height_bottom'} = $self->height - $self->margin_bottom;
  $self->{'effective_width'} = ($self->width - ($self->margin_left + $self->margin_right));
  $self->{'effective_height'} = ($self->height - ($self->margin_top + $self->margin_bottom));
}

sub _add_page_if_exceeds_bounds {
  my ($self, $theoretical_y) = @_;

  if ($self->would_extend_page( $theoretical_y )) {
    $self->add_page();

    return 1;
  }

  return 0;
}

sub _get_text_object_for_current_page {
  my ($self, %opts) = @_;
  my $font = ((exists $opts{'font'} && $opts{'font'}) ? $self->fonts->{$opts{'font'}} : $self->current_font);
  my $font_size = $opts{'font_size'} || $opts{'fontsize'} || $self->current_font_size;
  my $stroke_color = $opts{'stroke_color'} || $opts{'strokecolor'} || $self->current_stroke_color;
  my $fill_color = $opts{'fill_color'} || $opts{'fillcolor'} || $self->current_fill_color;
  my $text_obj = $self->current_page->text();

  $self->current_font( $font );
  $self->current_font_size( $font_size );
  $self->current_stroke_color( $stroke_color );
  $self->current_fill_color( $fill_color );

  $text_obj->font( $font, $font_size );
  $text_obj->strokecolor( $stroke_color );
  $text_obj->fillcolor( $fill_color );

  return $text_obj;
}

sub _render_text_at {
  my ($self, $text_obj, $text, $x, $y, $align) = @_;

  $text_obj->translate( $x, $y );

  if (lc $align eq 'center') {
    my $width = $text_obj->text_center( $text );

    if (wantarray) {
      my $half_w = $width / 2;
      my $rect_x = $x - $half_w;
      my $rect_x_to = $x + $half_w;

      return ( $rect_x, $y, $rect_x_to, $y + $self->current_font_size );
    }

    return $width; 
  }

  if (lc $align eq 'right') {
    my $width = $text_obj->text_right( $text );

    if (wantarray) {
      my $rect_x = $x - $width;
      my $rect_x_to = $x;

      return ( $rect_x, $y, $rect_x_to, $y + $self->current_font_size );
    }

    return $width;
  }

  if (wantarray) {
    my $width = $text_obj->text( $text );
    my $rect_x = $x;
    my $rect_x_to = $x + $width;

    return ( $rect_x, $y, $rect_x_to, $y + $self->current_font_size );
  }
  else {
    return $text_obj->text( $text );
  }
}

sub _standard_content_opts {
  my ($self, $content, %opts) = @_;

  my $stroke_color = $opts{'stroke_color'} || $opts{'strokecolor'} || $self->current_stroke_color;
  my $fill_color = $opts{'fill_color'} || $opts{'fillcolor'} || $self->current_fill_color;
  my $width = $opts{'width'} || 0.5;

  $content->strokecolor( $stroke_color );
  $content->fillcolor( $fill_color );
  $content->linewidth( $width );
}

sub _render_content {
  my ($self, $content, %opts) = @_;

  my $stroke = lc $opts{'stroke'};
  my $fill = lc $opts{'fill'};

  $stroke = 'on' if (($stroke eq 'yes') || ($stroke eq 'true'));
  $fill = 'on' if (($fill eq 'yes') || ($fill eq 'true'));

  if ((!$stroke && !$fill) || (($stroke eq 'off') && ($fill eq 'off'))) {
    $fill = 'on'; # default to fill, not stroke
  }

  if ((lc $stroke eq 'on') && (lc $fill eq 'on')) {
    $content->fillstroke();
  }
  elsif (lc $fill eq 'on') {
    $content->fill();
  }
  elsif (lc $stroke eq 'on') {
    $content->stroke();
  }
}

sub _limit_text {
  my ($self, $text, $limit) = @_;
  my @chars;
  my $index;

  return $text if (length($text) <= $limit);

  @chars = split //, $text;
  $index = int(scalar(@chars) * 0.75);

  Carp::croak( "Limit must be > than 5" ) if ($limit < 5);

  $text = join '', @chars;

  while (scalar(@chars) > $limit) {
    splice(@chars, $index--, 1);

    last if ($index < 0);
  }

  $text = join '', @chars;
  substr($text, $index, 3) = '...'; 

  return $text;
}

=head2 open

  PDF::API2::Simple->open(
              'open_file' => 'my_pdf.pdf',
              'open_page' => 1,              # Default is 1.
              # Any other options to new.
  );

This method opens an existing PDF for editing. You can include any other
arguments that are valid for C<new> and they will be set in the resulting
object.

=cut

sub open {
    my ($self, %opts) = @_;

    die 'Must provide an open_file param for open'
        unless $opts{'open_file'};

    # Default to 1;
    my $page_num = exists $opts{open_page} ? $opts{open_page} : 1;

    my $base_pdf = PDF::API2->open($opts{open_file});
    my $page = $base_pdf->openpage($page_num);

    my $pdf = PDF::API2::Simple->new(%opts);
    $pdf->pdf($base_pdf);
    $pdf->current_page($page);

    return $pdf;
}

# public methods - space management
# ================================================

=head2 Space Management

The following methods help you to manage the space on each page of your PDF.

=head3 next_line_would_extend_page

Returns a true value if the current C<y> minus C<line_height> would write past the bottom margin.

=cut

sub next_line_would_extend_page {
  my $self = shift;

  return $self->would_extend_page( $self->y - $self->line_height );
}

=head3 would_extend_page C<theoretical_y>

Returns a true value if the C<theoretical_y> would write past the bottom margin.

=cut

sub would_extend_page {
  my ($self, $theoretical_y) = @_;

  return ($theoretical_y < $self->margin_bottom);
}

=head3 next_line

Reduces the current C<y> by C<line_height>.

=cut

sub next_line {
  my $self = shift;

  $self->{'_y'} -= $self->line_height;
}

=head3 add_page

Closes the current page, resets the C<x> and C<y> values to thier default coordinates, and calls the header callback, if specified. This method may be called for in, such as if your autoflow text wraps over a page.

=cut

sub add_page {
  my $self = shift;
  
  if ($self->current_page) {
    $self->end_page();
  }    

  $self->current_page( $self->pdf->page() );
  $self->_reset_x_and_y();

  if ($self->header) {
    $self->header->( $self );
  }
}

=head3 end_page

Closes the current page, and calls the footer callback, if specified. This method is usually called for you.

=cut

sub end_page {
  my $self = shift;

  if ($self->footer) {
    $self->footer->( $self );
  }
}

# public methods - general mangement
# ================================================

=head2 General Management

These methods help you manage the PDF itself

=head3 add_font C<font_name>

This method will add a font to be used throughout the PDF. You C<MUST> call this at least once before laying out your PDF. C<font_name> is a font name, such as 'Arial', or 'Verdana'. Appending 'Bold' seems to make the text bold, as in 'VerdanaBold'. Refer to L<PDF::API2> for more details.

You can optionally pass a font object and font size if you have loaded an
external font.

  my $font_obj = $pdf->pdf->ttfont('new_font.ttf');
  $pdf->add_font('NewFont', $font_obj, '12');

Refer to L<PDF::API2> for the various font methods, like C<ttfont>, available.

=cut

sub add_font {
  my ($self, $font_name, $font_obj, $font_size) = @_;

  if ( $font_obj ) {
    $self->current_page->text->font($font_obj, $font_size);
    $self->fonts->{$font_name} = $font_obj;
  }

  if ( ! exists $self->fonts->{$font_name} ) {
    $self->fonts->{$font_name} = $self->pdf->corefont($font_name);
  }

  $self->current_font( $self->fonts->{$font_name} );
}

=head3 set_font C<font_name>[, C<pt>]

Set the current font by name, and optionally a font size.

=cut

sub set_font {
  my ($self, $font_name, $pt) = @_;

  $self->current_font( $self->fonts->{$font_name} );

  if ($pt && ($pt > 0)) {
    $self->current_font_size( $pt );
  }
}

=head3 as_string

An alias for the stringify method

=cut

sub as_string { stringify( @_ ); }

=head3 stringify

Ends the current page, and returns the pdf as a string

=cut

sub stringify {
  my $self = shift;

  $self->end_page();
  $self->{'_pdf'}->stringify;
}

sub save_as { save( @_ ); }
sub saveas { save( @_ ); }

=head3 save [C<file>]

End the current page, and save the document to the file argument, or the file specified when instaniating the object. If not suitable file can be found to save in, a C<Carp::croak> is emitted. Aliases for this method are C<saveas> and C<save_as>.

=cut

sub save {
  my ($self, $file) = @_;

  $self->file( $file ) if ($file);

  if ( ! $self->file ) {
    Carp::croak( "No file specified" );
  }

  $self->end_page();
  $self->{'_pdf'}->saveas( $self->file );
}

# public methods - layout
# ================================================

=head2 Layout

These methods modify the actual layout of the PDF. Note that most of these methods set some internal state. Most often, the last C<x> and C<y> are set after the rendered object.

Most times, underscores may be stripped and the arguments will still work, such as is the difference between C<fill_color>, and C<fillcolor>.

=head3 popup C<text>[, C<%opts>]

Creates a 25x25 box at C<opts{x}> (or the current C<x>), C<opts{y}> (or the current C<y>) to represent an annotation at that point. The user may then click that icon for a full annotation.

=cut

sub popup {
  my ($self, $text, %opts) = @_;
  my $x = exists $opts{'x'} ? $opts{'x'} : $self->x;
  my $y = exists $opts{'y'} ? $opts{'y'} : $self->y;
  my $annotation = $self->current_page->annotation;
  
  $annotation->rect( $x, $y, $x + 25, $y + 25 );
  $annotation->text( $text );
}

=head3 url

This is an alias for the C<link> method.

=cut

sub url {
  my $self = shift;

  return $self->link( @_ );
}

=head3 link C<url>, C<text>[, C<%opts>]

Specifies a link to C<url>, having C<text>. C<%opts> may contain:

=over

=item * C<x> - The x position of the link. Defaults to C<x>.

=item * C<y> - The y position of the link. Defaults to C<y>.

=item * C<limit> - The amount to "limit" the text. This will add an ellipis (...) a few characters from the end if the text length is greater than this numerical value. Defaults to 0, which is to mean "do not limit".

=item * C<align> - Which alignment you want for your text. The choices are 'left', 'center', and 'right'. Defaults to 'left'.

=item * C<font> - Specifies via font name, the font to use. This sets the current font.

=item * C<font_size> - Specifies the font size. This sets the current font size.

=item * C<fill_color> - Specifies the fill color. This sets the current fill color.

=item * C<stroke_color> - Specifies the stroke color. This sets the current stroke color.

=back

This method returns the width of the text.

=cut

sub link {
  my ($self, $url, $text, %opts) = @_;
  my $x = exists $opts{'x'} ? $opts{'x'} : $self->x;
  my $y = exists $opts{'y'} ? $opts{'y'} : $self->y;
  my $limit = $opts{'limit'} || 0;
  my $align = $opts{'align'} || 'left';
  my $text_obj = $self->_get_text_object_for_current_page( %opts );
  my @rect;
  my $annotation;

  $text = $self->_limit_text( $text, $limit ) if ($limit);

  @rect = $self->_render_text_at( $text_obj, $text, $x, $y, $align );
  $annotation = $self->current_page->annotation;

  $annotation->rect( @rect );
  $annotation->url( $url );

  # return text width
  return ($rect[2] - $rect[0]);
}

=head3 text C<text>[, C<%opts>]

Renders text onto the PDF.

=over

=item * C<x> - The x position of the link. Defaults to C<x>.

=item * C<y> - The y position of the link. Defaults to C<y>.

=item * C<limit> - The amount to "limit" the text. This will add an ellipis (...) a few characters from the end if the text length is greater than this numerical value. Defaults to 0, which is to mean "do not limit".

=item * C<align> - Which alignment you want for your text. The choices are 'left', 'center', and 'right'. Defaults to 'left'.

=item * C<autoflow> - Any value but 'off' will notify this method to use "autoflowing" heuristics to gracefully wrap your text over lines and pages. Useful for variable length text. Note that due to laziness, this option is mutually exclusive with C<limit>.

=item * C<font> - Specifies via font name, the font to use. This sets the current font.

=item * C<font_size> - Specifies the font size. This sets the current font size.

=item * C<fill_color> - Specifies the fill color. This sets the current fill color.

=item * C<stroke_color> - Specifies the stroke color. This sets the current stroke color.

=back

If C<autoflow> was B<not> specified, this method returns the width of the text in scalar context, the bounding box of the text in list context. In autoflow mode, this method returns nothing.

=cut

sub text {
  my ($self, $text, %opts) = @_;
  my $x = exists $opts{'x'} ? $opts{'x'} : $self->x;
  my $y = exists $opts{'y'} ? $opts{'y'} : $self->y;
  my $limit = $opts{'limit'} || 0;
  my $align = $opts{'align'} || 'left';
  my $autoflow = $opts{'autoflow'} || 'off';
  my $text_obj = $self->_get_text_object_for_current_page( %opts );
  my @words;
  my $org_x;
  my $sentance;

  # don't get fancy. just render.
  if (lc $autoflow eq 'off') {
    $text = $self->_limit_text( $text, $limit ) if ($limit);
    
    return $self->_render_text_at( $text_obj, $text, $x, $y, $align );
  }

  Carp::croak( "May not use limit when autoflow is on!" ) if ($limit);

  $org_x = $x;
  @words = split /\s/, $text;

  for (my $i = 0; $i < scalar(@words); $i++) {
    my $word = $words[$i];
    my $width;
    my $flush = 0;

    if (($i + 1) <= scalar(@words)) {
      $word .= ' ';
    }

    $width = $text_obj->advancewidth( $word ); 

    if ( $align eq 'center' ) {
      my $delta = abs($org_x - ($x + ($width / 2)));
      my ($left, $right) = (($org_x - $delta), ($org_x + $delta));

      $flush = (($left < $self->margin_left) || ($right > $self->width_right));
    }
    elsif ( $align eq 'right' ) {
      $flush = (($x - $width) < $self->margin_left);
    }
    else {
      $flush = (($x + $width) > $self->effective_width + $self->margin_left);
    }

    if ( $flush ) {
      $self->_render_text_at( $text_obj, $sentance, $org_x, $y, $align );
      $sentance = '';

      $x = $org_x;
      $y -= $self->line_height;
    }

    if ($self->_add_page_if_exceeds_bounds( $y )) {
      $x = $org_x;
      $y = $self->y;

      $text_obj = $self->_get_text_object_for_current_page( %opts );
    }

    $sentance .= $word;

    if ( $align eq 'center' ) {
      $x += ($width / 2);
    }
    elsif ( $align eq 'right' ) {
      $x -= $width;
    }
    else {
      $x += $width;
    }
  }

  $self->_render_text_at( $text_obj, $sentance, $org_x, $y, $align );
  
  $y -= $self->line_height;
  if (!$self->_add_page_if_exceeds_bounds( $y )) {  
    $self->y( $y );
  }
}

=head3 image C<src>[, C<%opts>]

Renders an image onto the PDF. The following image types are supported: JPG, TIFF, PNM, PNG, GIF, and PDF. Note that the module determines the image type by file extension.

=over

=item * C<x> - The x position of the link. Defaults to C<x>.

=item * C<y> - The y position of the link. Defaults to C<y>.

=item * C<width> - The width of the image. Defaults to 100.

=item * C<height> - The height of the image. Defaults to 100.

=item * C<scale> - Amount to scale the image. Defaults to 1. (only available for PDF types)

=back

=cut

sub image {
  my ($self, $src, %opts) = @_;
  my $x = exists $opts{'x'} ? $opts{'x'} : $self->x;
  my $y = exists $opts{'y'} ? $opts{'y'} : $self->y;
  my $width = $opts{'width'} || 100;
  my $height = $opts{'height'} || 100;
  my $scale = $opts{'scale'} || 1;
  my $image = $self->current_page->gfx;
  my $data;

  local $_ = $src;

  if (m/[.]jp(?:e)?g$/i) {
    $data = $self->pdf->image_jpeg( $_ );
  }
  elsif (m/[.]tif(?:f)?$/i) {
    $data = $self->pdf->image_tiff( $_ );
  }
  elsif (m/[.]pnm$/i) {
    $data = $self->pdf->image_pnm( $_ );
  }
  elsif (m/[.]png$/i) {
    $data = $self->pdf->image_png( $_ );
  }
  elsif (m/[.]gif$/i) {
    $data = $self->pdf->image_gif( $_ );
  }
  elsif (m/[.]pdf$/i) {
    my $p = PDF::API2->open( $_ );
    my $xo = $self->pdf->importPageIntoForm($p, 1);
    
    $self->current_page->gfx->formimage($xo, $x, $y, $scale);
    $self->x( $x );
    $self->y( $y );

    return;
  }
  else {
    Carp::croak("Cannot ascertain image type of $src\n");
  }

  $image->image($data, $x, $y, $width, $height);

  $self->x( $x + $width );
  $self->y( $y );
}

=head3 line [, C<%opts>]

Renders a line onto the PDF.

=over

=item * C<x> - The x position of the line. Defaults to C<x>.

=item * C<y> - The y position of the line. Defaults to C<y>.

=item * C<to_x> - The x position where to draw the line to.

=item * C<to_y> - The y position where to draw the line to.

=item * C<fill_color> - Specifies the fill color. This sets the current fill color. Defaults to C<current_fill_color>.

=item * C<stroke_color> - Specifies the stroke color. This sets the current stroke color. Defaults to C<current_stroke_color>.

=item * C<width> - Specifies the width of the line. Defaults to 0.5.

=back

=cut

sub line {
  my ($self, %opts) = @_;
  my $x = exists $opts{'x'} ? $opts{'x'} : $self->x;
  my $y = exists $opts{'y'} ? $opts{'y'} : $self->y;
  my $to_x = $opts{'to_x'};
  my $to_y = $opts{'to_y'};
  my $line = $self->current_page->gfx;

  $self->_standard_content_opts( $line, %opts );

  $line->move( $x, $y );
  $line->line( $to_x, $to_y );

  $self->_render_content( $line, %opts );

  $self->x( $to_x );
  $self->y( $to_y );
}

=head3 rect [, C<%opts>]

Renders a rectangle onto the PDF. Rectangles are usually drawn specifying two coordinates diagonal from each other. (5, 5) to (30, 30) for example, would produce a 25 x 25 square.

=over

=item * C<x> - The x position of the rect. Defaults to C<x>.

=item * C<y> - The y position of the rect. Defaults to C<y>.

=item * C<to_x> - The x position where to draw the rect to.

=item * C<to_y> - The y position where to draw the rect to.

=item * C<stroke> - A value of 'on', 'true', or 'yes' will enable the stroke. Defaults to 'on'.

=item * C<fill> - A value of 'on', 'true', or 'yes' will enable the fill. Defaults to 'off'.

=item * C<fill_color> - Specifies the fill color. This sets the current fill color. Defaults to C<current_fill_color>.

=item * C<stroke_color> - Specifies the stroke color. This sets the current stroke color. Defaults to C<current_stroke_color>.

=item * C<width> - Specifies the width of the line. Defaults to 0.5.

=back

=cut

sub rect {
  my ($self, %opts) = @_;
  my $x = exists $opts{'x'} ? $opts{'x'} : $self->x;
  my $y = exists $opts{'y'} ? $opts{'y'} : $self->y;
  my $to_x = $opts{'to_x'};
  my $to_y = $opts{'to_y'};
  my $stroke = $opts{'stroke'} || 'on';
  my $fill = $opts{'fill'} || 'off';
  my $rect = $self->current_page->gfx;

  $self->_standard_content_opts( $rect, %opts );

  $rect->rectxy( $x, $y, $to_x, $to_y );

  $self->_render_content( $rect, %opts );

  $self->x( $to_x );
  $self->y( $to_y );
}

# properties
# ================================================

=head1 PROPERTIES

The following properties are read/write, and may be used as $pdf->prop to read, $pdf->prop('val') to set.

=head2 header

Gets/sets the header callback.

=cut

sub header {
  my $self = shift;

  if (@_) {
    $self->{'header'} = shift;
  }

  return $self->{'header'};
}

=head2 footer

Gets/sets the footer callback.

=cut

sub footer {
  my $self = shift;

  if (@_) {
    $self->{'footer'} = shift;
  }

  return $self->{'footer'};
}

=head2 file

Gets/sets the file used to save the PDF. It's recommended that you B<do not set this>.

=cut

sub file {
  my $self = shift;

  if (@_) {
    $self->{'file'} = shift;
  }

  return $self->{'file'};
}

=head2 width

Gets/sets the width of the current page. It's recommended that you B<do not set this>.

=cut

sub width {
  my $self = shift;

  if (@_) {
    $self->{'width'} = shift;
    $self->_set_relative_values();
  }

  return $self->{'width'};
}

=head2 height

Gets/sets the height of the current page. It's recommended that you B<do not set this>.

=cut

sub height {
  my $self = shift;

  if (@_) {
    $self->{'height'} = shift;
    $self->_set_relative_values();
  }

  return $self->{'height'};
}

=head2 line_height

Gets/sets the default line height. This is used in most space layout methods.

=cut

sub line_height {
  my $self = shift;

  if (@_) {
    $self->{'line_height'} = shift;
  }

  return $self->{'line_height'};
}

=head2 margin_left

Gets/sets the left margin.

=cut

sub margin_left {
  my $self = shift;

  if (@_) {
    $self->{'margin_left'} = shift;
    $self->_set_relative_values();                                                                                                                                                 
    $self->_reset_x_and_y(); 
  }

  return $self->{'margin_left'};
}

=head2 margin_top

Gets/sets the top margin.

=cut

sub margin_top {
  my $self = shift;

  if (@_) {
    $self->{'margin_top'} = shift;
    $self->_set_relative_values();                                                                                                                                                 
    $self->_reset_x_and_y();
  }

  return $self->{'margin_top'};
}

=head2 margin_right

Gets/sets the right margin.

=cut

sub margin_right {
  my $self = shift;

  if (@_) {
    $self->{'margin_right'} = shift;
    $self->_set_relative_values();
  }

  return $self->{'margin_right'};
}

=head2 margin_bottom

Gets/sets the bottom margin.

=cut

sub margin_bottom {
  my $self = shift;

  if (@_) {
    $self->{'margin_bottom'} = shift;
    $self->_set_relative_values(); 
  }

  return $self->{'margin_bottom'};
}

=head2 width_right

Gets/sets the calculated value, C<width> - C<margin_right>

=cut

sub width_right {
  my $self = shift;

  if (@_) {
    $self->{'width_right'} = shift;
  }

  return $self->{'width_right'};
}

=head2 height_bottom

Gets/sets the calculated value, C<height> - C<margin_bottom>

=cut

sub height_bottom {
  my $self = shift;

  if (@_) {
    $self->{'height_bottom'} = shift;
  }

  return $self->{'height_bottom'};
}

=head2 effective_width

Gets/sets the calculated value, C<width> - (C<margin_left> + C<margin_right>)

=cut

sub effective_width {
  my $self = shift;

  if (@_) {
    $self->{'effective_width'} = shift;
  }

  return $self->{'effective_width'};
}

=head2 effective_height

Gets/sets the calculated value, C<height> - (C<margin_top> + C<margin_bottom>)

=cut

sub effective_height {
  my $self = shift;

  if (@_) {
    $self->{'effective_height'} = shift;
  }

  return $self->{'effective_height'};
}

=head2 current_page

Gets/sets the current page object. It's hard to find a good reason to set this, but it is possible to do so.

=cut

sub current_page {
  my $self = shift;

  if (@_) {
    $self->{'_current_page'} = shift;
  }

  return $self->{'_current_page'};
}

=head2 pdf

Gets/sets the raw L<PDF::API2> object. This allows you great flexibility in your applications.

=cut

sub pdf {
  my $self = shift;

  if (@_) {
    $self->{'_pdf'} = shift;
  }

  return $self->{'_pdf'};
}

=head2 fonts

Gets/sets the array of fonts we have been storing via the C<add_font> method.

=cut

sub fonts {
  my $self = shift;

  if (@_) {
    $self->{'_fonts'} = shift;
  }

  return $self->{'_fonts'};
}

=head2 current_font

Gets/sets the current font.

=cut

sub current_font {
  my $self = shift;

  if (@_) {
    $self->{'_current_font'} = shift;
    
    if (@_) {
      $self->current_font_size( shift );
    }
  }

  return $self->{'_current_font'};
}

=head2 current_font_size

Gets/sets the current font size.

=cut

sub current_font_size {
  my $self = shift;

  if (@_) {
    $self->{'_current_font_size'} = shift;
  }

  return $self->{'_current_font_size'};
}

=head2 current_stroke_color

Gets/sets the current stroke color. Aliases for this method are C<stroke_color>, and C<strokecolor>

=cut

sub stroke_color {
  return current_stroke_color( @_ );
}

sub strokecolor {
  return current_stroke_color( @_ );
}

sub current_stroke_color {
  my $self = shift;

  if (@_) {
    $self->{'_current_stroke_color'} = shift;
  }

  return $self->{'_current_stroke_color'};
}

=head2 current_fill_color

Gets/sets the current fill color. Aliases for this method are C<fontcolor>, C<set_font_color>, C<font_color>, C<fillcolor>, and C<fill_color>.

=cut

sub fontcolor {
  return current_fill_color( @_ );
}

sub set_font_color {
  return current_fill_color( @_ );
}

sub font_color {
  return current_fill_color( @_ );
}

sub fill_color {
  return current_fill_color( @_ );
}

sub fillcolor {
  return current_fill_color( @_ );
}

sub current_fill_color {
  my $self = shift;

  if (@_) {
    $self->{'_current_fill_color'} = shift;
  }

  return $self->{'_current_fill_color'};
}

=head2 x

Gets/sets the current x position.

=cut

sub x {
  my $self = shift;

  if (@_) {
    $self->{'_x'} = shift;
  }

  return $self->{'_x'};
}

=head2 y

Gets/sets the current y position.

=cut

sub y { # } sub emacs-hack {
  my $self = shift;

  if (@_) {
    $self->{'_y'} = shift;
  }

  return $self->{'_y'};
}

=head1 BUGS / FIXES

Please mail all bug reports, fixes, improvements, and suggestions to bugs -at- redtreesystems -dot- com.

=head1 PLUG AND LICENSE

This project belongs to Red Tree Systems, LLC - L<http://www.redtreesystems.com>, but is placed into the public domain in the hopes that it will be educational and/or useful. Red Tree Systems, LLC requests that this section be kept intact with any modification of this module, or derivitive work thereof.

=head1 THANKS

Thanks to Jim Brandt for noting that the default values didn't do well with false values.

Thanks to Denis Evdokimov for submitting more margin-fixing goodness.

Thanks to Jonathan A. Marshall for fixing a long standing margin issue, and pointing out further documentation shortcomings.

Thanks to Jim Brandt for the open method, contributing code to add_font, and offering beer.

Thanks to Pradeep N Menon and Alfred Reibenschuh for pointing out optimizaiton issues, and helping to resolve them.

Thanks to Simon Wistow for uncovering several bugs and offering up code.

Thanks to Bryan Krone for pointing out our documentation shortcomings.

=head1 SEE ALSO

L<PDF::API2>

There is an examples folder with this dist that should help you get started. You may contact pdfapi2simple -AT- redtreesystems _dot_ com for support on an individual or commercial basis.

=cut

1;
