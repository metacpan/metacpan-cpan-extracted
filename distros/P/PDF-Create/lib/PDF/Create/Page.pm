package PDF::Create::Page;

our $VERSION = '1.43';

=encoding utf8

=head1 NAME

PDF::Create::Page - PDF pages tree for PDF::Create

=head1 VERSION

Version 1.43

=cut

use 5.006;
use strict; use warnings;

use Carp;
use FileHandle;
use Data::Dumper;
use POSIX qw(setlocale LC_NUMERIC);
use Scalar::Util qw(weaken);
use PDF::Font;

our $DEBUG = 0;
our $DEFAULT_FONT_WIDTH = 1000;

my $font_widths = &init_widths;
# Global variable for text function
my $ptext       = '';

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=cut

sub new {
    my ($this) = @_;

    my $class = ref($this) || $this;
    my $self  = {};
    bless $self, $class;
    $self->{'Kids'}    = [];
    $self->{'Content'} = [];

    return $self;
}

=head1 METHODS

=head2 add($id, $name)

Adds a page to the PDF document.

=cut

sub add {
    my ($self, $id, $name) = @_;

    my $page = PDF::Create::Page->new();
    $page->{'pdf'}    = $self->{'pdf'};
    weaken $page->{pdf};
    $page->{'Parent'} = $self;
    weaken $page->{Parent};
    $page->{'id'}     = $id;
    $page->{'name'}   = $name;
    push @{$self->{'Kids'}}, $page;

    return $page;
}

=head2 count()

Returns page count.

=cut

sub count {
    my ($self) = @_;

    my $c = 0;
    $c++ unless scalar @{$self->{'Kids'}};
    foreach my $page (@{$self->{'Kids'}}) {
        $c += $page->count;
    }

    return $c;
}

=head2 kids()

Returns ref to a list of page ids.

=cut

sub kids {
    my ($self) = @_;

    my $t = [];
    map { push @$t, $_->{'id'} } @{$self->{'Kids'}};

    return $t;
}

=head2 list()

Returns page list.

=cut

sub list {
    my ($self) = @_;

    my @l;
    foreach my $e (@{$self->{'Kids'}}) {
        my @t = $e->list;
        push @l, $e;
        push @l, @t if scalar @t;
    }

    return @l;
}

=head2 new_page()

Return new page.

=cut

sub new_page {
    my ($self, @params) = @_;

    return $self->{'pdf'}->new_page('Parent' => $self, @params);
}

#
#
# Drawing functions

=head2 moveto($x, $y)

Moves the current point to (x, y), omitting any connecting line segment.


=cut

sub moveto {
    my ($self, $x, $y) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("$x $y m");
}

=head2 lineto($x, $y)

Appends a straight line segment from the current point to (x, y).

=cut

sub lineto {
    my ($self, $x, $y) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("$x $y l");
}

=head2 curveto($x1, $y1, $x2, $y2, $x3, $y3)

Appends a Bezier  curve  to the path. The curve extends from the current point to
(x3 ,y3) using (x1 ,y1) and (x2 ,y2) as the Bezier control points.The new current
point is (x3 ,y3).

=cut

sub curveto {
    my ($self, $x1, $y1, $x2, $y2, $x3, $y3) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("$x1 $y1 $x2 $y2 $x3 $y3 c");
}

=head2 rectangle($x, $y, $w, $h)

Adds a rectangle to the current path.

=cut

sub rectangle {
    my ($self, $x, $y, $w, $h) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("$x $y $w $h re");
}

=head2 closepath()

Closes the current subpath by appending a straight line segment from the current
point to the starting point of the subpath.

=cut

sub closepath {
    my ($self) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("h");
}

=head2 newpath()

Ends the path without filling or stroking it.

=cut

sub newpath {
    my ($self) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("n");
}

=head2 stroke()

Strokes the path.

=cut

sub stroke {
    my ($self) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("S");
}

=head2 closestroke()

Closes and strokes the path.

=cut

sub closestroke {
    my ($self) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("s");
}

=head2 fill()

Fills the path using the non-zero winding number rule.

=cut

sub fill {
    my ($self) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("f");
}

=head2 fill2()

Fills the path using the even-odd rule.

=cut

sub fill2 {
    my ($self) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("f*");
}

=head2 line($x1, $y1, $x2, $y2)

Draw a  line between ($x1, $y1) and ($x2, $y2). Combined moveto / lineto / stroke
command.

=cut

sub line {
    my ($self, $x1, $y1, $x2, $y2) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("$x1 $y1 m $x2 $y2 l S");
}

=head2 set_width($w)

Set the width of subsequent lines to C<w> points.

=cut

sub set_width {
    my ($self, $w) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("$w w");
}

#
#
# Color functions

=head2 setgray($value)

Sets the color space to DeviceGray and sets the gray tint to use for filling paths.

=cut

sub setgray {
    my ($self, $val) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("$val g");
}

=head2 setgraystroke($value)

Sets the color space to DeviceGray and sets the gray tint to use for stroking paths.

=cut

sub setgraystroke {
    my ($self, $val) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("$val G");
}

=head2 setrgbcolor($r, $g, $b)

Sets the fill colors used for normal text or filled objects.

=cut

sub setrgbcolor {
    my ($self, $r, $g, $b) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("$r $g $b rg");
}

=head2 setrgbcolorstroke($r, $g, $b)

Set the color  of the subsequent drawing operations. Valid r, g, and b values are
each between 0.0 and 1.0, inclusive.

Each color ranges from 0.0 to 1.0, i.e., darkest red (0.0) to brightest red(1.0).
The same holds for green and blue.  These three colors mix  additively to produce
the colors between black (0.0, 0.0, 0.0) and white (1.0, 1.0, 1.0).

PDF distinguishes between  the stroke  and  fill operations and provides separate
color settings for each.

=cut

sub setrgbcolorstroke {
    my ($self, $r, $g, $b) = @_;

    croak "Error setting colors, need three values" if !defined $b;
    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->add("$r $g $b RG");
}

#
#
# Text functions

=head2 text(%params)

Renders the text. Parameters are explained as below:

    +--------+------------------------------------------------------------------+
    | Key    | Description                                                      |
    +--------+------------------------------------------------------------------+
    | start  | The start marker, add directive BT                               |
    | end    | The end marker, add directive ET                                 |
    | text   | Text to add to the pdf                                           |
    | F      | Font index to be used, add directive /F<font_index>              |
    | Tf     | Font size for the text, add directive <font_size> Tf             |
    | Ts     | Text rise (super/subscript), add directive <mode> Ts             |
    | Tr     | Text rendering mode, add directive <mode> Tr                     |
    | TL     | Text leading, add directive <number> TL                          |
    | Tc     | Character spacing, add directive <number> Tc                     |
    | Tw     | Word spacing, add directive <number> Tw                          |
    | Tz     | Horizontal scaling, add directive <number> Tz                    |
    | Td     | Move to, add directive <x> <y> Td                                |
    | TD     | Move to and set TL, add directive <x> <y> TD                     |
    | rot    | Move to and rotate (<r> <x> <y>), add directive                  |
    |        | <cos(r)>, <sin(r)>, <sin(r)>, <cos(r)>, <x>, <y> Tm              |
    | T*     | Add new line.                                                    |
    +--------+------------------------------------------------------------------+

=cut

sub text {
    my ($self, %params) = @_;

    PDF::Create::debug( 2, "text(%params):" );

    my @directives = ();

    if (defined $params{'start'}) { push @directives, "BT"; }

    # Font index
    if (defined $params{'F'})  {
        push @directives, "/F$params{'F'}";
        $self->{'pdf'}->uses_font($self, $params{'F'});
    }
    # Font size
    if (defined $params{'Tf'}) { push @directives, "$params{'Tf'} Tf"; }
    # Text Rise (Super/Subscript)
    if (defined $params{'Ts'}) { push @directives, "$params{'Ts'} Ts"; }
    # Rendering Mode
    if (defined $params{'Tr'}) { push @directives, "$params{'Tr'} Tr"; }
    # Text Leading
    if (defined $params{'TL'}) { push @directives, "$params{'TL'} TL"; }
    # Character spacing
    if (defined $params{'Tc'}) { push @directives, "$params{'Tc'} Tc"; }
    # Word Spacing
    if (defined $params{'Tw'}) { push @directives, "$params{'Tw'} Tw"; } else { push @directives, "0 Tw"; }
    # Horizontal Scaling
    if (defined $params{'Tz'}) { push @directives, "$params{'Tz'} Tz"; }
    # Moveto
    if (defined $params{'Td'}) { push @directives, "$params{'Td'} Td"; }
    # Moveto and set TL
    if (defined $params{'TD'}) { push @directives, "$params{'TD'} TD"; }

    # Moveto and rotateOA
    my $pi = atan2(1, 1) * 4;
    my $piover180 = $pi / 180;
    if (defined $params{'rot'}) {
        my ($r, $x, $y) = split( /\s+/, $params{'rot'}, 3 );
        $x = 0 unless ($x > 0);
        $y = 0 unless ($y > 0);
        my $cos = cos($r * $piover180);
        my $sin = sin($r * $piover180);
        push @directives, sprintf("%.5f %.5f -%.5f %.5f %s %s Tm", $cos, $sin, $sin, $cos, $x, $y);
    }

    # New line
    if (defined $params{'T*'}) { push @directives, "T*"; }

    if (defined $params{'text'}) {
        $params{'text'} =~ s|([()])|\\$1|g;
        push @directives, "($params{'text'}) Tj";
    }

    if (defined $params{'end'}) {
        push @directives, "ET";
        $ptext = join(' ', @directives);
        $self->{'pdf'}->page_stream($self);
        $self->{'pdf'}->add($ptext);
    }

    PDF::Create::debug( 3, "text(): $ptext" );

    1;
}

=head2 string($font, $size, $x, $y, $text $alignment)

Add text to the current page using the font object at the given size and position.
The point (x, y) is the bottom left corner of the rectangle containing the text.

The optional alignment can be 'r' for right-alignment and 'c' for centered.

Example :

    my $f1 = $pdf->font(
       'Subtype'  => 'Type1',
       'Encoding' => 'WinAnsiEncoding',
       'BaseFont' => 'Helvetica'
    );

    $page->string($f1, 20, 306, 396, "some text");

=cut

sub string {
    my ($self, $font, $size, $x, $y, $string, $align,
        $char_spacing, $word_spacing) = @_;

    $align = 'L' unless defined $align;

    if (uc($align) eq "R") {
        $x -= $size * $self->string_width($font, $string);
    } elsif (uc($align) eq "C") {
        $x -= $size * $self->string_width($font, $string) / 2;
    }

    my @directives = (
        'BT',
        "/F$font",
        "$size Tf",
    );

    if (defined $char_spacing && $char_spacing =~ m/[0-9]+\.?[0-9]*/) {
        push @directives, sprintf("%s Tc", $char_spacing);
    }

    if (defined $word_spacing && $word_spacing =~ m/[0-9]+\.?[0-9]*/) {
        push @directives, sprintf("%s Tw", $word_spacing);
    }

    $string =~ s|([()])|\\$1|g;

    push @directives,
        "$x $y Td",
        "($string) Tj",
        'ET';

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->uses_font($self, $font);
    $self->{'pdf'}->add(join(' ', @directives));
}

=head2 string_underline($font, $size, $x, $y, $text, $alignment)

Draw a line for underlining.The parameters are the same as for the string function
but only the line is drawn. To draw an underlined string you must call both,string
and string_underline. To change the color of  your text  use the C<setrgbcolor()>.
It  returns the length of the string. So its return value can be used directly for
the bounding box of an annotation.

Example :

    $page->string($f1, 20, 306, 396, "some underlined text");

    $page->string_underline($f1, 20, 306, 396, "some underlined text");

=cut

sub string_underline {
    my ($self, $font, $size, $x, $y, $string, $align) = @_;

    $align = 'L' unless defined $align;
    my $len1 = $self->string_width($font, $string) * $size;
    my $len2 = $len1 / 2;
    if (uc($align) eq "R") {
        $self->line($x - $len1, $y - 1, $x, $y - 1);
    } elsif (uc($align) eq "C") {
        $self->line($x - $len2, $y - 1, $x + $len2, $y - 1);
    } else {
        $self->line($x, $y - 1, $x + $len1, $y - 1);
    }

    return $len1;
}

=head2 stringl($font, $size, $x, $y $text)

Same as C<string()>.

=cut

sub stringl {
    my ($self, $font, $size, $x, $y, $string) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->uses_font($self, $font);
    $string =~ s|([()])|\\$1|g;
    $self->{'pdf'}->add("BT /F$font $size Tf $x $y Td ($string) Tj ET");
}

=head2 stringr($font, $size, $x, $y, $text)

Same as C<string()> but right aligned (alignment 'r').

=cut

sub stringr {
    my ($self, $font, $size, $x, $y, $string) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->uses_font($self, $font);
    $x -= $size * $self->string_width($font, $string);
    $string =~ s|([()])|\\$1|g;
    $self->{'pdf'}->add(" BT /F$font $size Tf $x $y Td ($string) Tj ET");
}

=head2 stringc($font, $size, $x, $y, $text)

Same as C<string()> but centered (alignment 'c').

=cut

sub stringc {
    my ($self, $font, $size, $x, $y, $string) = @_;

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->uses_font($self, $font);
    $x -= $size * $self->string_width($font, $string) / 2;
    $string =~ s|([()])|\\$1|g;
    $self->{'pdf'}->add(" BT /F$font $size Tf $x $y Td ($string) Tj ET");
}

=head2 string_width($font, $text)

Return the size of the text using the given font in default user space units.This
does not contain the size of the font yet, to get the length you must multiply by
the font size.

=cut

sub string_width {
    my ($self, $font, $string) = @_;

    croak 'No string given' unless defined $string;

    my $fname = $self->{'pdf'}{'fonts'}{$font}{'BaseFont'}[1];
    croak('Unknown font: ' . $fname) unless defined $$font_widths{$fname}[ ord "M" ];

    my $w = 0;
    for my $c ( split '', $string ) {
        $w += $$font_widths{$fname}[ ord $c ] || $DEFAULT_FONT_WIDTH;
    }

    return $w / 1000;
}

=head2 printnl($text, $font, $size, $x, $y)

Similar to  C<string()> but parses the string for newline and prints each part on
a separate line. Lines spacing is the same as the font-size.Returns the number of
lines.

Note the different parameter sequence.The first call should specify all parameters,
font is  the absolute minimum, a warning will be given for the missing y position
and 800  will  be assumed. All subsequent invocations can omit all but the string
parameters.

ATTENTION:There is no provision for changing pages.If you run out of space on the
current page this will draw the string(s) outside the page and it will be invisible.

=cut

sub printnl {
    my ($self, $s, $font, $size, $x, $y) = @_;

    $self->{'current_font'} = $font if defined $font;
    croak 'No font found !' if !defined $self->{'current_font'};

    # set up current_x/y used in stringml
    $self->{'current_y'} = $y if defined $y;
    carp 'No starting position given, using 800' if !defined $self->{'current_y'};
    $self->{'current_y'}    = 800   if !defined $self->{'current_y'};
    $self->{'current_x'}    = $x    if defined $x;
    $self->{'current_x'}    = 20    if !defined $self->{'current_x'};
    $self->{'current_size'} = $size if defined $size;
    $self->{'current_size'} = 12    if !defined $self->{'current_size'};

    # print the line(s)
    my $n = 0;
    for my $line ( split '\n', $s ) {
        $n++;
        $self->string($self->{'current_font'}, $self->{'current_size'}, $self->{'current_x'}, $self->{'current_y'}, $line);
        $self->{'current_y'} = $self->{'current_y'} - $self->{'current_size'};
    }

    return $n;
}

=head2 block_text(\%params)

Add block of text to the page. Parameters are explained as below:

    +------------+--------------------------------------------------------------+
    | Key        | Description                                                  |
    +------------+--------------------------------------------------------------+
    | page       | Object of type PDF::Create::Page                             |
    | font       | Font index to be used.                                       |
    | text       | Text block to be used.                                       |
    | font_size  | Font size for the text.                                      |
    | text_color | Text color as arrayref i.e. [r, g, b]                        |
    | line_width | Line width (in points)                                       |
    | start_y    | First row number (in points) when adding new page.           |
    | end_y      | Last row number (in points) when to add new page.            |
    | x          | x co-ordinate to start the text.                             |
    | y          | y co-ordinate to start the text.                             |
    +------------+--------------------------------------------------------------+

    use strict; use warnings;
    use PDF::Create;

    my $pdf  = PDF::Create->new('filename'=>"$0.pdf", 'Author'=>'MANWAR', 'Title'=>'Create::PDF');
    my $root = $pdf->new_page('MediaBox' => $pdf->get_page_size('A4'));
    my $page = $root->new_page;
    my $font = $pdf->font('BaseFont' => 'Helvetica');

    $page->rectangle(30, 780, 535, 40);
    $page->setrgbcolor(0,1,0);
    $page->fill;

    $page->setrgbcolorstroke(1,0,0);
    $page->line(30, 778, 565, 778);

    $page->setrgbcolor(0,0,1);
    $page->string($font, 15, 102, 792, 'MANWAR - PDF::Create');

    my $text = qq{
Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into ele-It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions
    };

    $page->block_text({
        page       => $page,
        font       => $font,
        text       => $text,
        font_size  => 6,
        text_color => [0,0,1],
        line_width => 535,
        start_y    => 780,
        end_y      => 60,
        'x'        => 30,
        'y'        => 770,
    });

    $pdf->close;

=cut

sub block_text {
    my ($self, $params) = @_;

    croak "ERROR: parameters to method block_text() should be hashref.\n"
        unless (defined $params && (ref($params) eq 'HASH'));

    my $page       = $params->{page};
    my $font       = $params->{font};
    my $text       = $params->{text};
    my $font_size  = $params->{font_size};
    my $text_color = $params->{text_color};
    my $line_width = $params->{line_width};
    my $start_y    = $params->{start_y} || 0;
    my $end_y      = $params->{end_y} || 0;
    my $x          = $params->{x};
    my $y          = $params->{y};
    my $one_space  = $page->string_width($font, ' ') * $font_size;

    my $para_space_factor = 1.5;
    $para_space_factor = $params->{para_space_factor}
        if (exists $params->{para_space_factor}
            && defined $params->{para_space_factor});

    my @lines = ();
    foreach my $block (split /\n/, $text) {
        my @words = split(/ /, $block);
        my $para_last_line = 0;

        while (@words) {
            my $num_words    = 1;
            my $string_width = 0;
            my $space_width  = undef;

            while (1) {
                $string_width = $font_size * $page->string_width(
                $font, _get_text(\@words, $num_words));

                # Shorter, try one more word
                if ($string_width + $one_space < $line_width) {
                    if (scalar(@words) > $num_words) {
                        $num_words++;
                        next;
                    }
                }

                last if ($num_words == 1);

                # Longer, chop a word off, then space accordingly
                $para_last_line = scalar(@words) == $num_words;
                if ($string_width + $one_space > $line_width || $para_last_line) {
                    unless ($para_last_line) {
                        $num_words--;
                    }

                    $string_width = $font_size * $page->string_width(
                        $font, _get_text(\@words, $num_words));

                    $space_width = ($line_width - $string_width) / $num_words;
                    last;
                }
            }

            my %text_param = (
                start => 1,
                Tw    => $space_width,
                F     => $font,
                Tf    => $font_size,
                Td    => "$x $y",
                text  => _get_text(\@words, $num_words),
                end   => 1,
            );

            if ($para_last_line) {
                delete $text_param{Tw};
            }

            $page->text(%text_param);

            if ($y <= $end_y) {
                $y    = $start_y;
                $page = $page->{'Parent'}->new_page();
                $page->setrgbcolor(@$text_color);
            }
            else {
                $y -= int($font_size * $para_space_factor);
                if ($para_last_line) {
                    $y -= int($font_size * $para_space_factor);
                }
            }

            splice(@words, 0, $num_words);
        }
    }
}

=head2 image(%params)

Inserts an image. Parameters can be:

    +----------------+----------------------------------------------------------+
    | Key            | Description                                              |
    +----------------+----------------------------------------------------------+
    |                |                                                          |
    | image          | Image id returned by PDF::image (required).              |
    |                |                                                          |
    | xpos, ypos     | Position of image (required).                            |
    |                |                                                          |
    | xalign, yalign | Alignment of image.0 is left/bottom, 1 is centered and 2 |
    |                | is right, top.                                           |
    |                |                                                          |
    | xscale, yscale | Scaling of image. 1.0 is original size.                  |
    |                |                                                          |
    | rotate         | Rotation of image.0 is no rotation,2*pi is 360° rotation.|
    |                |                                                          |
    | xskew, yskew   | Skew of image.                                           |
    |                |                                                          |
    +----------------+----------------------------------------------------------+

Example jpeg image:

    # include a jpeg image with scaling to 20% size
    my $jpg = $pdf->image("image.jpg");

    $page->image(
        'image'  => $jpg,
        'xscale' => 0.2,
        'yscale' => 0.2,
        'xpos'   => 350,
        'ypos'   => 400
    );

=cut

sub image {
    my ($self, %params) = @_;

    # Switch to the 'C' locale, we need printf floats with a '.', not a ','
    my $savedLocale = setlocale(LC_NUMERIC);
    setlocale(LC_NUMERIC,'C');

    my $img    = $params{'image'} || "1.2";
    my $image  = $img->{num};
    my $xpos   = $params{'xpos'} || 0;
    my $ypos   = $params{'ypos'} || 0;
    my $xalign = $params{'xalign'} || 0;
    my $yalign = $params{'yalign'} || 0;
    my $xscale = $params{'xscale'} || 1;
    my $yscale = $params{'yscale'} || 1;
    my $rotate = $params{'rotate'} || 0;
    my $xskew  = $params{'xskew'} || 0;
    my $yskew  = $params{'yskew'} || 0;

    $xscale *= $img->{width};
    $yscale *= $img->{height};

    if ($xalign == 1) {
        $xpos -= $xscale / 2;
    } elsif ($xalign == 2) {
        $xpos -= $xscale;
    }

    if ($yalign == 1) {
        $ypos -= $yscale / 2;
    } elsif ($yalign == 2) {
        $ypos -= $yscale;
    }

    $self->{'pdf'}->page_stream($self);
    $self->{'pdf'}->uses_xobject( $self, $image );
    $self->{'pdf'}->add("q\n");

    # TODO: image: Merge position with rotate
    $self->{'pdf'}->add("1 0 0 1 $xpos $ypos cm\n")
        if ($xpos || $ypos);

    if ($rotate) {
        my $sinth = sin($rotate);
        my $costh = cos($rotate);
        $self->{'pdf'}->add("$costh $sinth -$sinth $costh 0 0 cm\n");
    }
    if ($xscale || $yscale) {
        $self->{'pdf'}->add("$xscale 0 0 $yscale 0 0 cm\n");
    }
    if ($xskew || $yskew) {
        my $tana = sin($xskew) / cos($xskew);
        my $tanb = sin($yskew) / cos($xskew);
        $self->{'pdf'}->add("1 $tana $tanb 1 0 0 cm\n");
    }
    $self->{'pdf'}->add("/Image$image Do\n");
    $self->{'pdf'}->add("Q\n");

    # Switch to the 'C' locale, we need printf floats with a '.', not a ','
    setlocale(LC_NUMERIC,$savedLocale);
}

# Table with font widths for the supported fonts.
sub init_widths
{
    my $font_widths = {};
    foreach my $name (keys %{$PDF::Font::SUPPORTED_FONTS}) {
        $font_widths->{$name} = PDF::Font->new($name)->char_width;
    }

    return $font_widths;
}

#
#
# PRIVATE METHODS

sub _get_text ($$) {
    my ($words, $num_words) = @_;

    if (scalar @$words < $num_words) { die @_ };

    return join(' ', map { $$words[$_] } (0..($num_words-1)));
}

=head1 AUTHORS

Fabien Tassin

GIF and JPEG-support: Michael Gross (info@mdgrosse.net)

Maintenance since 2007: Markus Baertschi (markus@markus.org)

Currently maintained by Mohammad S Anwar (MANWAR) C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/pdf-create>

=head1 COPYRIGHT

Copyright 1999-2001,Fabien Tassin.All rights reserved.It may be used and modified
freely, but I do  request that this copyright notice remain attached to the file.
You may modify this module as you wish,but if you redistribute a modified version,
please attach a note listing the modifications you have made.

Copyright 2007 Markus Baertschi

Copyright 2010 Gary Lieberman

=head1 LICENSE

This is free software; you can redistribute it and / or modify it under the same
terms as Perl 5.6.0.

=cut

1;
