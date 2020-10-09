package Mojo::PDF;

use Mojo::Base -base;

our $VERSION = '1.005003'; # VERSION

use Carp qw/croak/;
$Carp::Internal{ (__PACKAGE__) }++;
use PDF::Reuse 0.36;
use Number::RGB 1.41;
use Image::Size;
use List::AllUtils qw/sum/;
use Mojo::PDF::Primitive::Table;
use namespace::clean;

$SIG{'__WARN__'} = sub { warn @_ unless caller eq 'PDF::Reuse'; };

has page_size => sub { [612, 792] }; # default US-Letter pages
has [qw/_line_height  _x  _y /] => 0;
has _cur_color => sub { [0, 0, 0] };
has _cur_font  => 'TR';
has _cur_size  => 12;
has _fonts => sub { +{} };
has _rules => sub { +{} };

my %STD_FONTS = (
    'Times-Roman'           => 'Times-Roman',
    'Times-Bold'            => 'Times-Bold',
    'Times-Italic'          => 'Times-Italic',
    'Times-BoldItalic'      => 'Times-BoldItalic',
    'Courier'               => 'Courier',
    'Courier-Bold'          => 'Courier-Bold',
    'Courier-Oblique'       => 'Courier-Oblique',
    'Courier-BoldOblique'   => 'Courier-BoldOblique',
    'Helvetica'             => 'Helvetica',
    'Helvetica-Bold'        => 'Helvetica-Bold',
    'Helvetica-Oblique'     => 'Helvetica-Oblique',
    'Helvetica-BoldOblique' => 'Helvetica-BoldOblique',
    'Symbol'                => 'Symbol',
    'ZapfDingbats'          => 'ZapfDingbats',
    'TR'                    => 'Times-Roman',
    'TB'                    => 'Times-Bold',
    'TI'                    => 'Times-Italic',
    'TBI'                   => 'Times-BoldItalic',
    'C'                     => 'Courier',
    'CB'                    => 'Courier-Bold',
    'CO'                    => 'Courier-Oblique',
    'CBO'                   => 'Courier-BoldOblique',
    'H'                     => 'Helvetica',
    'HB'                    => 'Helvetica-Bold',
    'HO'                    => 'Helvetica-Oblique',
    'HBO'                   => 'Helvetica-BoldOblique',
    'S'                     => 'Symbol',
    'Z'                     => 'ZapfDingbats'
);

sub __hex2rgb {
    my $hex = shift;
    my $c = eval { Number::RGB->new( hex => $hex ) }
        or croak "Could not interpret color '$hex' as hex";

    return map $_/255, @{ $c->rgb };
}

sub __inv_y {
  my $self = shift;
  $_ = $self->page_size->[1] - $_ for @_; @_
}

sub _line {
    my $self = shift;
    my ( $x1, $y1, $x2, $y2 ) = @_;
    $self->__inv_y($y1, $y2);
    prAdd "$x1 $y1 m $x2 $y2 l S";

    $self;
}

sub _str_width {
    my $self = shift;
    my $str = shift;

    return prStrWidth(
        $str,
        $self->_cur_font//'Helvetica',
        $self->_cur_size//12
    ) // 0;
}

sub _stroke {
    my $self = shift;
    my $weight = shift;
    prAdd "$weight w";

    $self;
}

sub add_fonts {
    my $self = shift;
    my %fonts = @_;

    for ( keys %fonts ) {
        $STD_FONTS{$_} and croak "Font name '$_' conflicts with one of the "
            . 'standard font names. Please choose another one';
        $self->_fonts->{$_} = $fonts{ $_ };
    };

    $self;
}

sub color {
    my $self = shift;
    @_ = @{$_[0]} if @_ == 1 and ref $_[0] eq 'ARRAY';

    my ( $r, $g, $b )
        = @_ == 0 ? (0, 0, 0) # default to black
            : @_ == 1
            ? __hex2rgb( $_[0] ) # hex color
                : @_; # rgb tuple

    $self->_cur_color([$r, $g, $b]);
    prAdd "n $r $g $b RG $r $g $b rg\n";

    $self;
}

sub end {
    my $self = shift;
    prEnd;
}

sub font {
    my $self = shift;
    my $name = shift;

    $STD_FONTS{$name} or $self->_fonts->{$name}
        or croak "Unknown font '$name'";

    $STD_FONTS{$name} ? prFont($name) : prTTFont( $self->_fonts->{$name} );
    $self->_cur_font($name);

    $self;
}

sub mixin {
    my $self = shift;
    my ( $doc, $page ) = @_;
    prForm { file => $doc, page => $page//1 };

    $self;
}

sub new {
    my ( $class, $filename ) = ( shift, shift );
    my $self = $class->SUPER::new( @_ );

    prFile $filename;
    prMbox ( 0, 0, $self->page_size->[0], $self->page_size->[1] );
    $self->size;

    $self;
}

sub page {
    my $self = shift;
    prPage;

    $self;
}

sub pic {
    my ($self, $pic, %args) = @_;
    my ($width, $height, $int_name);
    if (ref $pic eq 'SCALAR') { # we have a data string rather than file
        open my $fh, '<', $pic or die "Failed to read image bytes: $!";
        ($width, $height) = Image::Size::imgsize($fh);
        $int_name = prJpeg $$pic, $width, $height, 1;
    }
    else {
        ($width, $height) = Image::Size::imgsize($pic);
        $int_name = prJpeg $pic, $width, $height, 0;
    }

    if ($args{scale}) {
        $width  *= $args{scale};
        $height *= $args{scale};
    }

    my ($x, $y) = map $_||0, @args{qw/x y/};
    $self->__inv_y($y);
    $y -= $height;

    my $str = "q\n";
    $str   .= "$width 0 0 $height $x $y cm\n";
    $str   .= "/$int_name Do\n";
    $str   .= "Q\n";
    prAdd $str;

    $self;
}

sub raw {
    my $self = shift;
    prAdd shift;
    $self;
}

sub rule {
    my ( $self, %new ) = @_;
    my $rules = $self->_rules;

    for ( keys %new ) {
        $rules->{$_} = $new{$_};
        delete $rules->{$_} unless defined $rules->{$_};
    }

    $self;
}

sub size {
    my $self = shift;
    my $size = shift // 12;

    $self->_cur_size( $size );
    prFontSize $size;
    $self->_line_height( $size*1.4 );

    $self;
}

sub table {
    my $self = shift;
    my %conf = @_;

    DRAW: {
        $conf{row_height} ||= $self->_line_height;

        my $t = Mojo::PDF::Primitive::Table->new( pdf => $self, %conf );
        my @overflow = $t->draw
            and $conf{max_height}
            or return $self;

        $conf{data} = $conf{max_height}->[1]->(\@overflow, \%conf, $self);
        @{ $conf{data} || [] }
            and redo DRAW;
    }

    $self;
}

sub text {
    my $self = shift;
    my ( $string, $x, $y, $align, $rotation ) = @_;
    $self->_x( $x //= $self->_x );

    # Don't switch to new line, if neither X nor Y were given;
    $y //= $self->_y + ( @_ > 1 ? $self->_line_height : 0 );
    $self->_y( $y );

    my @lines = split /\n/, $string;
    for ( 0 .. $#lines ) {
        $self->_text(
            $lines[$_],
            $x,
            $self->_y + $self->_line_height * $_,
            $align,
            $rotation,
        );
    }

    $self;
}

sub _text {
    my $self = shift;
    my ( $string, $x, $y, $align, $rotation ) = @_;
    $self->_x( $x );
    $self->_y( $y );

    my @text = ( { text => $string } );
    for my $r ( values %{$self->_rules} ) {
        my @new_text;
        for my $bit ( @text ) {
            if ( $bit->{marked} ) { push @new_text, $bit; next; }

            my $mark = 0;

            for ( split /($r->{re})/, $bit->{text} ) {
                if ( $_ =~ /$r->{re}/ ) { $mark = 1; next; }
                if ( $mark ) {
                    $mark = 0;
                    push @new_text, { marked => 1, text => $_, %$r };
                    next;
                }

                push @new_text, { text => $_ };
            }
        }

        @text = @new_text;
    }

    my ( $orig_font, $orig_size, $orig_color )
        = map $self->$_, qw/_cur_font  _cur_size  _cur_color/;

    for my $bit ( @text ) {
        if ( $bit->{marked} ) {
            if ( $bit->{font} )  { $self->font(  $bit->{font}  ); }
            if ( $bit->{size} )  { $self->size(  $bit->{size}  ); }
            if ( $bit->{color} ) { $self->color( $bit->{color} ); }
            $self->_text($bit->{text}, $self->_x, $self->_y,$align,$rotation );
            if ( $bit->{font} )  { $self->font(  $orig_font  ); }
            if ( $bit->{size} )  { $self->size(  $orig_size  ); }
            if ( $bit->{color} ) { $self->color( $orig_color ); }
            next;
        }
        $self->_render_text_bit(
            $bit->{text},
            $self->_x,
            $self->_y,
            $align,
            $rotation,
        );
    }

    $self;
}

sub _render_text_bit {
    my $self = shift;
    my ( $string, $x, $y, $align, $rotation ) = @_;
    $self->_x( (prText($x, $self->__inv_y($y), $string, $align, $rotation))[1] );

    $self;
}

q|
There are only two hard problems in distributed systems:
2. Exactly-once delivery
1. Guaranteed order of messages 2. Exactly-once delivery
|;

__END__

=encoding utf8

=for stopwords Znet Zoffix Mojotastic PDFs RGB TTF Unicode

=head1 NAME

Mojo::PDF - Generate PDFs with the goodness of Mojo!

=head1 SYNOPSIS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    # Just render text. Be sure to call ->end to save your document
    Mojo::PDF->new('mypdf.pdf')->text('Viva la Mojo!', 306, 396)->end;

    # Let's get fancy pants:
    Mojo::PDF->new('myawesome.pdf', page_size => [612, 792])

        ->mixin('template.pdf')   # add a pre-made PDF page from a template

        # Render text with standard fonts
        ->font('Times-Bold')->size(24)->color(0, 0, .7)
            ->text('Mojo loves PDFs', 612/2, 500, 'center')

        # Render text with custom TTF fonts
        ->add_fonts(
            galaxie    => 'fonts/GalaxiePolaris-Book.ttf',
            galaxie_it => 'fonts/GalaxiePolaris-BookItalic.ttf',
        )
        ->font('galaxie')->size(24)->color('#353C8C')
            ->text('Weeee', 20.4, 75 )
            ->text('eeee continuing same line!')
            ->text('Started a new line!', 20.4 )

        # Render a table
        ->font('galaxie_it')->size(8)->color
        ->table(
            at        => [20.4, 268],
            data      => [
                [ qw{Product  Description Qty  Price  U/M} ],
                @data,
            ],
        )

        ->end;

=for html  </div></div>

=head1 DESCRIPTION

Mojotastic, no-nonsense PDF generation.

=head1 CAVEATS

B<Note:> due to the way L<PDF::Reuse>, which is used under the hood, is
implemented, it's not possible to simultaneously handle multiple
L<Mojo::PDF> objects, as all of the internal L<PDF::Reuse> output
variables are shared. Thus, L<Mojo::PDF> merely provides a more convenient
interface for L<PDF::Reuse>, rather than being a truly object-oriented way
to produce PDFs.

=head1 METHODS

Unless otherwise indicated, all methods return their invocant.

=head2 C<new>

    my $pdf = Mojo::PDF->new('myawesome.pdf');
    my $pdf = Mojo::PDF->new('myawesome.pdf', page_size => [$x, $y]);

Creates a new C<Mojo::PDF> object. Takes one mandatory argument: the filename
of the PDF you want to generate, followed by optional key/value attributes.

If filename is not specified or C<undef>, the PDF will be output to C<STDOUT>.
An L<IO::String> object can be specified to output the PDF into a variable:

    # IO::String
    my $pdf = Mojo::PDF->new(IO::String->new(my $pdf_bytes));
    $pdf->text('Viva la Mojo!', 306, 396)->end;

    # Then use the bytes somewhere:
    open my $fh, '>', 'the.pdf' or die $!;
    print $fh $pdf_bytes;
    close $fh;

=head3 C<page_size>

Array reference containing the XxY page size in pixels. Defaults to [612, 792]
(US-Letter).

=head2 C<end>

    $p->end;

Finish rendering your PDF and save it.

=head2 C<add_fonts>

    $pdf->add_fonts(
        galaxie    => 'fonts/GalaxiePolaris-Book.ttf',
        galaxie_it => 'fonts/GalaxiePolaris-BookItalic.ttf',
    );

Adds TTF fonts to the document. Key/value pairs specify the arbitrary name
of the font (for you to use with L</font>) and the path to the TTF file.

You cannot use any of the names of the L</DEFAULT FONTS> for your custom fonts.

=head2 C<color>

    $pdf->color(.5, .5, .3);
    $pdf->color('#abcdef');
    $pdf->color('#abc');   # same as #aabbcc
    $pdf->color;           # same as #000

Specifies active color. Takes either an RGB tuple or a hex colour. Defaults
to black.

=head2 C<font>

    $pdf->font('Times-Bold');

    $pdf->font('galaxie');

Sets active font family. Takes the name of either one of the L</DEFAULT FONTS>
or one of the custom fonts included with L</add_fonts>. Note that
L</DEFAULT FONTS> do not support Unicode.

=head2 C<mixin>

    $pdf->mixin('template.pdf');

    $pdf->mixin('template.pdf', 3);

Adds a page from an existing PDF to your currently active page, so you
can use it as a template and render additional things on it. Takes one
mandatory argument, the filename of the PDF to include. An optional second
argument specifies the page number to include (starting from 1),
which defaults to the first page.

B<Note:> If you get an error along the lines of I<can't be used as a form. See the documentation under prForm how to concatenate streams>, it likely means the PDF is not compatible with this feature. The details are described in
L<PDF::Reuse::prForm documentation|https://metacpan.org/pod/release/CNIGHS/PDF-Reuse-0.39/lib/PDF/Reuse.pm#prForm-use-a-page-from-an-old-document-as-a-form/background>. I had to convert my InDesign-generated PDFs with
L<Win2PDF "printer"|https://www.win2pdf.com/> to get them to work with this
method.

=head2 C<page>

    $pdf->page;

Add a new blank page to your document and sets it as the currently active page.

=head2 C<pic>

    $pdf->pic(
        'cat.jpg',     # use scalar ref (\$data) to provide raw bytes instead
        x     => 42,   # place at X points from the left of page
        y     => 100,  # place at Y points from the top  of page
        scale => .5    # scale image by this factor
    );

Add a JPEG image to the active page (other formats currently unsupported). Takes the filename (string) or raw image bytes (in a scalar ref) as the first
argument, the rest are key-value pairs: the C<x> for X position, C<y> for Y
position, and C<scale> as the scale factor for the image.

=head2 C<raw>

    $pdf->raw("0 0 m\n10 10 l\nS\nh\n");

Use L<prAdd|PDF::Reuse/"prAdd"> to "add whatever you want to the current content stream".

See, for example, section 4.4.1 on page 196 of the
L<Adobe Acrobat SDK PDF Reference Manual|https://web.archive.org/web/20060212001631/http://partners.adobe.com/public/developer/en/acrobat/sdk/pdf/pdf_creation_apis_and_specs/PDFReference.pdf>.

=head2 C<rule>

    ->rule(
        bold  => { re => qr/\*\*(.?)\*\*/, font => 'galaxie_bold' },
        shiny => {
            re    => qr/!!(.?)!!/,
            font  => 'galaxie_bold',
            color => '#FBBC05',
            size  => 30,
        },
    )
    ->text('Normal **bold text** lalalala !!LOOK SHINY!!')
    ->rule( shiny => undef )
    ->text('!!no longer shiny!!')

Sets rules for bits of text when rendering with
L</text> or L</table>. Available overrides are L</font>, L</color>,
and L</size>. To disable a rule, set its value to C<undef>.

=head2 C<size>

    $pdf->size(24);

    $pdf->size; # set to 12

Specifies active font size in points. Defaults to C<12> points.

=head2 C<table>

    $pdf->table(
        at        => [20.4, 268],
        data      => [
            [ qw{Product  Description Qty  Price  U/M} ],
            @$data,
        ],

        #Optional:
        border         => [.5, '#CFE3EF'],
        header         => 'galaxie_bold',
        max_height     => [ 744, sub {
            my ( $data, $conf, $pdf ) = @_;
            $conf->{at}[1] = 50;
            $pdf->page;
            $data;
        } ],
        min_width      => 571.2,
        padding        => [3, 6],
        row_height     => 24,
        str_width_mult => 1.1,
    );

Render a table on the current page. Takes these arguments:

=head3 C<at>

    at => [20.4, 268],

An arrayref with X and Y point values of the table's top, left corner.

=head3 C<data>

    data => [
        [ qw{Product  Description Qty  Price  U/M} ],
        @$data,
    ],

An arrayref of rows, each of which is an arrayref of strings representing
table cell values. Setting L</header> will render first row as a table header.
Cells that are C<undef>/empty string will not be rendered. Text
in cells is rendered using L</text>.

=head3 C<border>

    border => [.5, '#CFE3EF'],

B<Optional>. Takes an arrayref with the width (in points) and colour of
the table's borders. Color allows the same values as L</color> method.
B<Defaults to:> C<[.5, '#ccc']>

=head3 C<header>

    header => 'galaxie_bold',

B<Optional>. Takes the same value as L</font>. If set, the first row
of C</data> will be used as table header, rendered centered using
C<header> font. B<Not set by default.>

=head3 C<max_height>

    $pdf->table(
        at         => [20.4, 300],
        data       => $data,
        max_height => [ 744, sub {
            my ( $data, $conf, $pdf ) = @_;
            $conf->{at}[1] = 50; # start table higher on subsequent pages
            $pdf->page;          # start a new page
            $data;               # render remaining rows
        },
    );

B<Optional>. Takes an arrayref with two arguments: the maximum height
(in points) the table should reach and the callback to use when not
all rows could fit. The B<return value> of the callback will be used as
the new collection of rows to render.
The C<@_> will contain remaining rows to render,
hashref of the options you've passed to C<table> method, and the
C<Mojo::PDF> object.

=head3 C<min_width>

    min_width => 571.2,

B<Optional>. Table's minimum width in points (zero by default).
The largest column will be widened to make the table at least this wide.

=head3 C<padding>

    padding => [3],          # all sides 3
    padding => [3, 6],       # top/bottom 3, left/right 6
    padding => [3, 6, 4],    # top 3, left/right 6, bottom 4
    padding => [3, 6, 4, 5], # top 3, right 6, bottom 4, left 5

B<Optional>. Specifies cell padding (in points). Takes an arrayref of 1 to 4
numbers, following the same convention as
the L<CSS property|http://www.w3.org/wiki/CSS/Properties/padding>.

=head3 C<row_height>

    row_height => 24,

B<Optional>. Specifies the height of a row, in points. Defaults to
1.4 times the current L<font size|/size>.

=head3 C<str_width_mult>

    str_width_mult => 1.1,
    str_width_mult => { 10 => 1.1, 20 => 1.3, inf => 1.5 },

B<Optional>. Cell widths will be automatically computed based on the
width of the strings they contain. Currently, that computation
works reliably only for the C<Times>, C<Courier>, and C<Helvetica>
L</font> families. All other fonts will be computed as if they were sized
same as C<Helvetica>. For those cases, use C<str_width_mult> as a multiplier
for the detected character width.

You can use a hashref to specify different multipliers for strings of
different lengths. The values are multipliers and keys specify the
maximum length this multiplier applies to. You can use
positive infinity (C<inf>) too:

    str_width_mult => { 10 => 1.1, 20 => 1.3, inf => 1.5 },
    # mult is 1.1 for strings 0-10 chars
    # mult is 1.3 for strings 11-20 chars
    # mult is 1.5 for strings 20+ chars

=head2 C<text>

    $p->text($text_string, $x, $y, $alignment, $rotation);

    $p->text('Mojo loves PDFs', 612/2, 500, 'center', 90);
    $p->text('Lorem ipsum dolor sit amet, ', 20 );
    $p->text('consectetur adipiscing elit!');

    use Text::Fold qw/fold_text/;
    $p->text( fold_text $giant_amount_of_text, 42 ); # new lines work!

Render text with the currently active L</font>, L</size>, and L</color>.
C<$alignment> specifies how to align the string horizontally on the C<$x>
point; valid values are C<left> (default), C<center>, and C<right>.
C<$rotation> is the rotation of the text in degrees. You can use new
line characters (C<\n>) to render text on multiple lines.

Subsequent calls to C<text> can omit C<$x> and C<$y> values with
these effects: omit both to continue rendering where previous C<text>
finished; omit just C<$y>, to render on the next line from previous call
to C<text>. B<Note:> determination of the C<$x> reliably works only for the
C<Times>, C<Courier>, and C<Helvetica> L</font> families. All other fonts
will be computed as if they were sized same as C<Helvetica>.

=head1 DEFAULT FONTS

These fonts are available by default. Note that they don't support Unicode.

    Times-Roman
    Times-Bold
    Times-Italic
    Times-BoldItalic

    Courier
    Courier-Bold
    Courier-Oblique
    Courier-BoldOblique

    Helvetica
    Helvetica-Bold
    Helvetica-Oblique
    Helvetica-BoldOblique

    Symbol
    ZapfDingbats

You can use their abbreviated names:

    TR
    TB
    TI
    TBI

    C
    CB
    CO
    CBO

    H
    HB
    HO
    HBO

    S
    Z

=head1 SEE ALSO

L<PDF::Reuse>, L<PDF::Create>, and L<PDF::WebKit>

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/Mojo-PDF>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/Mojo-PDF/issues>

If you can't access GitHub, you can email your request
to C<bug-Mojo-PDF at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for html  </div></div>

=head1 CONTRIBUTORS

L<Stefan Adams|https://github.com/s1037989>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
