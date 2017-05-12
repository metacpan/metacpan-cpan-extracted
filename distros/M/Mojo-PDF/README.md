# NAME

Mojo::PDF - Generate PDFs with the goodness of Mojo!

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    # Just render text. Be sure to call ->end to save your document
    Mojo::PDF->new('mypdf.pdf')->text('Viva la Mojo!', 306, 396)->end;

    # Let's get fancy pants:
    Mojo::PDF->new('myawesome.pdf')

        ->mixin('_template.pdf')   # add a pre-made PDF page from a template

        # Render text with standard fonts
        ->font('Times-Bold')->size(24)->color(0, 0, .7)
            ->text('Mojo loves PDFs', 612/2, 500, 'center')

        # Render text with custom TTF fonts
        ->add_fonts(
            galaxie    => 'fonts/GalaxiePolaris-Book.ttf',
            galaxie_it => 'fonts/GalaxiePolaris-BookItalic.ttf',
        )
        ->font('galaxie')->size(24)->color('#353C8C')
            ->text( 'Weeee', 20.4, 75 )
            ->text( 'eeee continuing same line!')
            ->text( 'Started a new line!', 20.4 )

        # Render a table
        ->font('galaxie_it')->size(8)->color
        ->table(
            at     => [20.4, 268],
            width  => 571.2,
            border => [.5, '#CFE3EF'],
            data   => [
                [ qw{Product  Description Qty  Price  U/M} ],
                @$data,
            ],
        )

        ->end;

<div>
    </div></div>
</div>

# DESCRIPTION

Mojotastic, no-nonsense PDF generation.

# WARNING

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-warning.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

This module is currently experimental. Things will change.

<div>
    </div></div>
</div>

# METHODS

Unless otherwise indicated, all methods return their invocant.

## `new`

    my $pdf = Mojo::PDF->new('myawesome.pdf');

Creates a new `Mojo::PDF` object. Takes one mandatory argument: the filename
of the PDF you want to generate.

## `end`

    $p->end;

Finish rendering your PDF and save it. Currently, you cannot reuse the same
`Mojo::PDF` object to create more than one PDF.

## `add_fonts`

    $pdf->add_fonts(
        galaxie    => 'fonts/GalaxiePolaris-Book.ttf',
        galaxie_it => 'fonts/GalaxiePolaris-BookItalic.ttf',
    );

Adds TTF fonts to the document. Key/value pairs specify the arbitrary name
of the font (for use with [font](https://metacpan.org/pod/font) and the path to the TTF file.

You cannot use any of the names of the ["DEFAULT FONTS"](#default-fonts) for your fonts.

## `color`

    $pdf->color(.5, .5, .3);
    $pdf->color('#abcdef');
    $pdf->color('#ccc');   # same as #cccccc
    $pdf->color;           # same as #000

Specifies active color. Takes either an RGB tuple or a hex colour. Defaults
to black.

## `font`

    $pdf->font('Times-Bold');

    $pdf->font('galaxie');

Sets active font family. Takes the name of either one of the ["DEFAULT FONTS"](#default-fonts)
or one of the custom fonts included with [add\_fonts](https://metacpan.org/pod/add_fonts)

## `mixin`

    $pdf->mixin('template.pdf');

    $pdf->mixin('template.pdf', 3);

Adds a page from an existing PDF to your currently active page. Takes one
mandatory argument, the filename of the PDF to include. An optional argument
specifies the page number to include (starting from 1), which defaults to
the first page.

## `page`

    $p->page;

Add a new blank page to your document.

## `size`

    $pdf->size(24);

    $pdf->size; # set to 12

Specifies active font size in points. Defaults to 12 points.

## `table`

    $t->table(
        at     => [20.4, 268],
        width  => 571.2,
        border => [.5, '#CFE3EF'],
        data   => [
            [ qw{Product  Description Qty  Price  U/M} ],
            @$data,
        ],

        #Optional:
        row_height => 24,
        str_width_mult => 1.1,
    );

Render a table on the current page. Takes these arguments:

### `at`

    at => [20.4, 268],

An arrayref with X and Y point values of the table's top, left corner.

### `width`

    min_width => 571.2,

Table's minimum width in points. The largest column will be widened
to make the table at least this wide.

### `border`

    border => [.5, '#CFE3EF'],

Takes an arrayref with the width (in points) and colour of the table's borders.
Color allows the same values as [color](https://metacpan.org/pod/color) method.

### `data`

    data   => [
        [ qw{Product  Description Qty  Price  U/M} ],
        @$data,
    ],

An arrayref of rows, each of which is an arrayref of strings representing
table cell values.

### `row_height`

    row_height => 24,

**Optional**. Specifies the height of a row, in points. Defaults to
1.4 times the current font size.

### `str_width_mult`

    str_width_mult => 1.1,

**Optional**. Cell widths will be automatically computed based on the
width of the strings they contain. On some fonts, the detection is a bit
imperfect. For those cases, use `str_width_mult` as a multiplier for the
detected character width.

## `text`

    $p->text($text_string, $x, $y, $alignment, $rotation);

    $p->text('Mojo loves PDFs', 612/2, 500, 'center', 90);
    $p->text('Lorem ipsum dolor sit amet, ', 20 );
    $p->text('consectetur adipiscing elit!');

Render text with the currently active [font](https://metacpan.org/pod/font), [size](https://metacpan.org/pod/size), and [color](https://metacpan.org/pod/color).
`$alignment` specifies how to align the string horizontally on the `$x`
point; valid values are `left` (default), `center`, and `right`.
`$rotation` is the rotation of the text in degrees.

Subsequent calls to [text](https://metacpan.org/pod/text) can omit `$x` and `$y` values with these effects:
omit both to continue rendering where previous [text](https://metacpan.org/pod/text) finished; omit just
`$y`, to render on the next line from previous call to [text](https://metacpan.org/pod/text).

# DEFAULT FONTS

These fonts are available by default:

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

You can use their abbreviate names:

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

# SEE ALSO

[PDF::Reuse](https://metacpan.org/pod/PDF::Reuse), [PDF::Create](https://metacpan.org/pod/PDF::Create), and [PDF::WebKit](https://metacpan.org/pod/PDF::WebKit)

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/Mojo-PDF](https://github.com/zoffixznet/Mojo-PDF)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/Mojo-PDF/issues](https://github.com/zoffixznet/Mojo-PDF/issues)

If you can't access GitHub, you can email your request
to `bug-Mojo-PDF at rt.cpan.org`

<div>
    </div></div>
</div>

# AUTHOR

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
