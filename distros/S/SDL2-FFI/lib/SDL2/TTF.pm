package SDL2::TTF 0.01 {
    use strict;
    use SDL2::Utils;
    use experimental 'signatures';
    use base 'Exporter::Tiny';
    use SDL2::Utils qw[attach define load_lib];
    use SDL2::FFI;
    #
    our %EXPORT_TAGS;
    #
    sub _ver() {
        CORE::state $version //= TTF_Linked_Version();
        $version;
    }
    #
    load_lib('SDL2_ttf');
    #
    define ttf => [
        [ SDL_TTF_MAJOR_VERSION => sub () { SDL2::TTF::_ver()->major } ],
        [ SDL_TTF_MINOR_VERSION => sub () { SDL2::TTF::_ver()->minor } ],
        [ SDL_TTF_PATCHLEVEL    => sub () { SDL2::TTF::_ver()->patch } ],
        [   SDL_TTF_VERSION => sub ( $version = SDL2::Version->new() ) {
                my $ver = TTF_Linked_Version();
                $version->major( $ver->major );
                $version->minor( $ver->minor );
                $version->patch( $ver->patch );
            }
        ],
        [   SDL_TTF_COMPILEDVERSION => sub () {
                SDL2::FFI::SDL_VERSIONNUM( SDL_TTF_MAJOR_VERSION(), SDL_TTF_MINOR_VERSION(),
                    SDL_TTF_PATCHLEVEL() );
            }
        ],
        [   SDL_TTF_VERSION_ATLEAST => sub ( $X, $Y, $Z ) {
                ( SDL_TTF_COMPILEDVERSION() >= SDL_VERSIONNUM( $X, $Y, $Z ) )
            }
        ]
    ];
    attach ttf => { TTF_Linked_Version => [ [], 'SDL_Version' ] };
    define ttf => [ [ UNICODE_BOM_NATIVE => 0xFEFF ], [ UNICODE_BOM_SWAPPED => 0xFFFE ] ];

    package SDL2::TTF::Font {
        use SDL2::Utils;
        our $TYPE = has();
    };
    attach ttf => {
        TTF_Init    => [ [], 'int' ],
        TTF_WasInit => [ [], 'int' ],
        TTF_Quit    => [ [] ],
        #
        TTF_OpenFont        => [ [ 'string', 'int' ],                   'SDL_TTF_Font' ],
        TTF_OpenFontRW      => [ [ 'SDL_RWops', 'int', 'int' ],         'SDL_TTF_Font' ],
        TTF_OpenFontIndex   => [ [ 'string', 'int', 'long' ],           'SDL_TTF_Font' ],
        TTF_OpenFontIndexRW => [ [ 'SDL_RWops', 'int', 'int', 'long' ], 'SDL_TTF_Font' ],
        TTF_CloseFont       => [ ['SDL_TTF_Font'] ],
        #
        TTF_ByteSwappedUNICODE   => [ ['int'] ],
        TTF_GetFontStyle         => [ ['SDL_TTF_Font'], 'int' ],
        TTF_SetFontStyle         => [ [ 'SDL_TTF_Font', 'int' ] ],
        TTF_GetFontOutline       => [ ['SDL_TTF_Font'], 'int' ],
        TTF_SetFontOutline       => [ [ 'SDL_TTF_Font', 'int' ] ],
        TTF_GetFontHinting       => [ ['SDL_TTF_Font'], 'int' ],
        TTF_SetFontHinting       => [ [ 'SDL_TTF_Font', 'int' ] ],
        TTF_GetFontKerning       => [ ['SDL_TTF_Font'], 'int' ],
        TTF_SetFontKerning       => [ [ 'SDL_TTF_Font', 'int' ] ],
        TTF_FontHeight           => [ ['SDL_TTF_Font'], 'int' ],
        TTF_FontAscent           => [ ['SDL_TTF_Font'], 'int' ],
        TTF_FontDescent          => [ ['SDL_TTF_Font'], 'int' ],
        TTF_FontLineSkip         => [ ['SDL_TTF_Font'], 'int' ],
        TTF_FontFaces            => [ ['SDL_TTF_Font'], 'long' ],
        TTF_FontFaceIsFixedWidth => [ ['SDL_TTF_Font'], 'int' ],
        TTF_FontFaceFamilyName   => [ ['SDL_TTF_Font'], 'string' ],
        TTF_FontFaceStyleName    => [ ['SDL_TTF_Font'], 'string' ],
        TTF_GlyphIsProvided      => [
            [ 'SDL_TTF_Font', 'uint16' ],
            'int' => sub ( $inner, $font, $ch ) {
                $inner->( $font, ord $ch );
            }
        ],
        TTF_GlyphMetrics => [
            [ 'SDL_TTF_Font', 'uint16', 'int*', 'int*', 'int*', 'int*', 'int*' ],
            'int' => sub ( $inner, $font, $ch, $minx, $maxx, $miny, $maxy, $advance ) {
                $inner->( $font, ord $ch, $minx, $maxx, $miny, $maxy, $advance );
            }
        ],
        TTF_SizeText    => [ [ 'SDL_TTF_Font', 'string', 'int*', 'int*' ], 'int' ],
        TTF_SizeUNICODE => [ [ 'SDL_TTF_Font', 'string', 'int*', 'int*' ], 'int' ],
        #
        TTF_RenderText_Solid    => [ [ 'SDL_TTF_Font', 'string', 'SDL_Color' ], 'SDL_Surface' ],
        TTF_RenderUTF8_Solid    => [ [ 'SDL_TTF_Font', 'string', 'SDL_Color' ], 'SDL_Surface' ],
        TTF_RenderUNICODE_Solid => [ [ 'SDL_TTF_Font', 'string', 'SDL_Color' ], 'SDL_Surface' ],
        TTF_RenderGlyph_Solid   => [
            [ 'SDL_TTF_Font', 'uint16', 'SDL_Color' ],
            'SDL_Surface' => sub ( $inner, $font, $ch, $fg ) {
                $inner->( $font, ord $ch, $fg );
            }
        ],
        TTF_RenderText_Shaded =>
            [ [ 'SDL_TTF_Font', 'string', 'SDL_Color', 'SDL_Color' ], 'SDL_Surface' ],
        TTF_RenderUTF8_Shaded =>
            [ [ 'SDL_TTF_Font', 'string', 'SDL_Color', 'SDL_Color' ], 'SDL_Surface' ],
        TTF_RenderUNICODE_Shaded =>
            [ [ 'SDL_TTF_Font', 'string', 'SDL_Color', 'SDL_Color' ], 'SDL_Surface' ],
        TTF_RenderGlyph_Shaded => [
            [ 'SDL_TTF_Font', 'uint16', 'SDL_Color', 'SDL_Color' ],
            'SDL_Surface' => sub ( $inner, $font, $ch, $fg, $bg ) {
                $inner->( $font, ord $ch, $fg, $bg );
            }
        ],
        TTF_RenderText_Blended    => [ [ 'SDL_TTF_Font', 'string', 'SDL_Color' ], 'SDL_Surface' ],
        TTF_RenderUTF8_Blended    => [ [ 'SDL_TTF_Font', 'string', 'SDL_Color' ], 'SDL_Surface' ],
        TTF_RenderUNICODE_Blended => [ [ 'SDL_TTF_Font', 'string', 'SDL_Color' ], 'SDL_Surface' ],
        TTF_RenderGlyph_Blended   => [
            [ 'SDL_TTF_Font', 'uint16', 'SDL_Color' ],
            'SDL_Surface' => sub ( $inner, $font, $ch, $fg ) {
                $inner->( $font, ord $ch, $fg );
            }
        ],
        #
    };
    define ttf => [
        [ TTF_SetError => \&SDL2::FFI::SDL_SetError ],
        [ TTF_GetError => \&SDL2::FFI::SDL_GetError ],
        #
        [ TTF_STYLE_NORMAL    => 0x00 ], [ TTF_STYLE_BOLD => 0x01 ], [ TTF_STYLE_ITALIC => 0x02 ],
        [ TTF_STYLE_UNDERLINE => 0x04 ], [ TTF_STYLE_STRIKETHROUGH => 0x08 ],
        [ TTF_HINTING_NORMAL  => 0 ],    [ TTF_HINTING_LIGHT => 1 ], [ TTF_HINTING_MONO => 2 ],
        [ TTF_HINTING_NONE    => 3 ],    [ TTF_HINTING_LIGHT_SUBPIXEL => 4 ],
    ];

    # Export symbols!
    our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;

    #$EXPORT_TAGS{default} = [];             # Export nothing by default
    $EXPORT_TAGS{all} = \@EXPORT_OK;    # Export everything with :all tag

=encoding utf-8

=head1 NAME

SDL2::TTF - TTF Image Loading Library

=head1 SYNOPSIS

    use SDL2::FFI qw[:all];

=head1 DESCRIPTION

This extension to SDL2 can load fonts from TrueType font files, normally ending
in C<.ttf>, though some C<.fon> files are also valid for use.

=head1 General Functions

These may be imported by name or with the C<:all> tag.

=head2 C<SDL_TTF_VERSION( ... )>

Macro to determine compile-time version of the SDL_ttf library.

    my $compile_version = SDL2::Version->new;
    SDL_TTF_VERSION($compile_version);
    printf "compiled with SDL_ttf version: %d.%d.%d\n", $compile_version->major,
        $compile_version->minor, $compile_version->patch;

Expected parameters include:

=over

=item C<x> - a pointer to a L<SDL2::Version> struct to initialize

=back

=head2 C<SDL_IMAGE_VERSION_ATLEAST( ... )>

Evaluates to true if compiled with SDL at least C<major.minor.patch>.

    if ( SDL_TTF_VERSION_ATLEAST( 2, 0, 5 ) ) {
        # Some feature that requires 2.0.5+
    }

Expected parameters include:

=over

=item C<major>

=item C<minor>

=item C<patch>

=back

=head2 C<TTF_Linked_Version( )>

This function gets the version of the dynamically linked SDL_image library.

    my $link_version = TTF_Linked_Version();
    printf "running with SDL_ttf version: %d.%d.%d\n",
        $link_version->major, $link_version->minor, $link_version->patch;

It should NOT be used to fill a version structure, instead you should use the
L<< C<SDL_TTF_VERSION( ... )>|/C<SDL_TTF_VERSION( ... )> >> macro.

Returns a L<SDL2::Version> object.

=head2 C<TTF_Init( )>

Initialize the truetype font API.

    if ( TTF_Init( ) == -1 ) {
        printf( "could not initialize sdl_ttf: %s\n", TTF_GetError() );
        return !1;
    }

This must be called before using other functions in this library, except L<<
C<TTF_WasInit( )>|/C<TTF_WasInit( )> >>. SDL does not have to be initialized
before this call.

Returns C<0> on success or C<-1> on failure.

=head2 C<TTF_WasInit( )>

Query the initialization status of the truetype font API.

    if ( !TTF_WasInit() && TTF_Init() == -1 ) {
        printf "TTF_Init: %s\n", TTF_GetError();
        exit 1;
    }

You may, of course, use this before TTF_Init to avoid initializing twice in a
row. Or use this to determine if you need to call TTF_Quit.

Returns C<1> if already initialized, C<0> if not initialized.

=head2 C<TTF_Quit( )>

Shutdown and cleanup the truetype font API.

    TTF_Quit( );

After calling this, the C<SDL_ttf> functions should not be used, excepting L<<
C<TTF_WasInit( )>|/C<TTF_WasInit( )> >>. You may, of course, use L<<
C<TTF_Init( )>|/C<TTF_Init( )> >> to use the functionality again.

=head2 C<TTF_SetError( ... )>

This is really a defined macro for C<SDL_SetError( ... )>, which sets the error
string which may be fetched with L<< C<TTF_GetError( )>|/C<TTF_GetError( )> >>
(or C<SDL_GetError( )>).

    sub myfunc ($i) {
        TTF_SetError( 'myfunc is not implemented! %d was passed in.', $i );
        return -1;
    }

=head2 C<TTF_GetError( )>

This is really a defined macro for C<SDL_GetError( )>.

    printf 'Oh My Goodness, an error: %s', TTF_GetError();

Use this to tell the user what happened when an error status has been returned
from an C<SDL_ttf> function call.

Returns the last error set by L<< C<TTF_SetError( ... )>|/C<TTF_SetError( ...
)> >> (or C<SDL_SetError( )>) as a string.

=head1 Management Functions

These functions deal with loading and freeing a C<TTF_Font>.

=head2 C<TTF_OpenFont( ... )>

Load C<file> for use as a font, at C<ptsize> size.

    # load font.ttf at size 16 into font
    my $font = TTF_OpenFont( 'font.ttf', 16 );
    if ( !$font ) {
        printf( "TTF_OpenFont: %s\n", TTF_GetError() );
        # handle error
    }

This is actually C<TTF_OpenFontIndex( $file, $ptsize, 0 )>. This can load TTF
and FON files.

Expected parameters include:

=over

=item C<file> - file name to load font from

=item C<ptsize> - point size (based on 72 DPI) to load font as; this basically translates to pixel height

=back

Returns a new L<SDL2::TTF::Font> structure on success.

=head2 C<TTF_OpenFontRW( ... )>

Load C<src> for use as a font, at C<ptsize> size.

    # load font.ttf at size 16 into font
    my $font = TTF_OpenFontRW( SDL_RWFromFile( 'font.ttf', 'rb' ), 1, 16 );
    if ( !$font ) {
        printf( "TTF_OpenFontRW: %s\n", TTF_GetError() );

        # handle error
    }

This is actually C<TTF_OpenFontIndexRW( $src, $freesrc, $ptsize, 0 )>. This can
load TTF and FON formats.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops>

=item C<freesrc> - a non-zero value means it will automatically close and free the C<src> for you after it finishes using the C<src>, even if a noncritical error occurred

=item C<ptsize> - point size (based on 72 DPI) to load font as; this basically translates to pixel height

=back

Returns a new L<SDL2::TTF::Font> structure on success.

=head2 C<TTF_OpenFontIndex( ... )>

Load C<file>, face C<index>, for use as a font, at C<ptsize> size.

    # load font.ttf at size 16 into font
    my $font = TTF_OpenFontIndex( 'font.ttf', 16, 0 );
    if ( !$font ) {
        printf( "TTF_OpenFontIndex: %s\n", TTF_GetError() );

        # handle error
    }

This is actually C<TTF_OpenFontIndexRW( SDL_RWFromFile($src, 'rb'), $freesrc,
$ptsize, $index )>.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops>

=item C<ptsize> - point size (based on 72 DPI) to load font as; this basically translates to pixel height

=item C<index> - choose a font face from a file containing multiple font faces

=back

Returns a new L<SDL2::TTF::Font> structure on success.

=head2 C<TTF_OpenFontIndexRW( ... )>

Load C<src>, face C<index>, for use as a font, at C<ptsize> size.

    # load font.ttf at size 16 into font
    my $font = TTF_OpenFontIndexRW( SDL_RWFromFile( 'font.ttf', 'rb' ), 1, 16, 0 );
    if ( !$font ) {
        printf( "TTF_OpenFontIndexRW: %s\n", TTF_GetError() );

        # handle error
    }

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops>

=item C<freesrc> - a non-zero value means it will automatically close and free the C<src> for you after it finishes using the C<src>, even if a noncritical error occurred

=item C<ptsize> - point size (based on 72 DPI) to load font as; this basically translates to pixel height

=item C<index> - choose a font face from a file containing multiple font faces

=back

Returns a new L<SDL2::TTF::Font> structure on success.

=head2 C<TTF_CloseFont( ... )>

Free the memory used by C<font>, and free C<font> itself as well. Do not use
C<font> after this without loading a new font to it.

    # free the font
    TTF_CloseFont( $font );
    undef $font; # to be safe...

Expected parameters include:

=over

=item C<font> - pointer to the L<TTF_Font> to free

=back

=head1 Attribute Functions

These functions deal with L<SDL2::TTF::Font> and global attributes.

=head2 C<TTF_ByteSwappedUNICODE( ... )>

This function tells C<SDL_ttf> whether UNICODE (Uint16 per character) text is
generally byteswapped. A B<UNICODE_BOM_NATIVE> or B<UNICODE_BOM_SWAPPED>
character in a string will temporarily override this setting for the remainder
of that string, however this setting will be restored for the next one. The
default mode is non-swapped, native endianness of the CPU.

    # Turn on byte swapping for UNICODE text
    TTF_ByteSwappedUNICODE( 1 );

Expected parameters include:

=over

=item C<swapped>

=over

=item - if non-zero then UNICODE data is byte swapped relative to the CPU's native endianness

=item - if zero, then do not swap UNICODE data, use the CPU's native endianness

=back

=back

=head2 C<TTF_GetFontStyle( ... )>

Get the rendering style of the loaded C<font>.

    # get the loaded font's style
    my $font  = TTF_OpenFontIndex( 'your.ttf', 16, 0 );
    my $style = TTF_GetFontStyle($font);
    print 'The font style is: ' . ( $style == TTF_STYLE_NORMAL ? 'normal' :
            $style & TTF_STYLE_BOLD          ? 'bold' :
            $style & TTF_STYLE_ITALIC        ? 'italic' :
            $style & TTF_STYLE_UNDERLINE     ? 'underline' :
            $style & TTF_STYLE_STRIKETHROUGH ? 'strikethrough' :
            'unknown' );

Expected parameters include:

=over

=item C<font> - the loaded font to get the style of

=back

Returns the style as a bitmask composed of the following masks:

=over

=item C<TTF_STYLE_BOLD>

=item C<TTF_STYLE_ITALIC>

=item C<TTF_STYLE_UNDERLINE>

=item C<TTF_STYLE_STRIKETHROUGH>

=back

If no style is set then C<TTF_STYLE_NORMAL> is returned.

=head2 C<TTF_SetFontStyle( ... )>

Set the rendering style of the loaded C<font>.

    # set the loaded font's style to bold italics
    TTF_SetFontStyle( $font, TTF_STYLE_BOLD | TTF_STYLE_ITALIC );

    # ...render some text in bold italics...

    # set the loaded font's style back to normal
    TTF_SetFontStyle( $font, TTF_STYLE_NORMAL );

Expected parameters include:

=over

=item C<font> - the loaded font to set the style of

=item C<style> - the style as a bitmask composed of the following masks:

=over

=item C<TTF_STYLE_BOLD>

=item C<TTF_STYLE_ITALIC>

=item C<TTF_STYLE_UNDERLINE>

=item C<TTF_STYLE_STRIKETHROUGH>

=back

If no style is desired then use C<TTF_STYLE_NORMAL>, which is the default.

=back

Notes:

=over

=item * Passing an undefined C<font> into this function will cause a segfault.

=item * This will flush the internal cache of previously rendered glyphs, even if there is no change in style, so it may be best to check the current style using TTF_GetFontStyle first.

=item * C<TTF_STYLE_UNDERLINE> may cause surfaces created by C<TTF_RenderGlyph_*> functions to be extended vertically, downward only, to encompass the underline if the original glyph metrics didn't allow for the underline to be drawn below. This does B<not> change the math used to place a glyph using glyph metrics.

On the other hand C<TTF_STYLE_STRIKETHROUGH> doesn't extend the glyph, since
this would invalidate the metrics used to position the glyph when blitting,
because they would likely be extended vertically upward. There is perhaps a
workaround, but it would require programs to be smarter about glyph blitting
math than they are currently designed for.

Still, sometimes the underline or strikethrough may be outside of the generated
surface, and thus not visible when blitted to the screen. In this case, you
should probably turn off these styles and draw your own strikethroughs and
underlines.

=back

=head2 C<TTF_GetFontOutline( ... )>

Get the current outline size of the loaded C<font>.

    # get the loaded font's outline width
    my $outline = TTF_GetFontOutline( $font );
    printf 'The font outline width is %d pixels', $outline;

Expected parameters include:

=over

=item C<font> - the loaded font to get the outline size of

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

Returns the size of the outline currently set on the font, in pixels.

=head2 C<TTF_SetFontOutline( ... )>

Set the outline pixel width of the loaded C<font>.

    # set the loaded font's outline to 1 pixel wide
    TTF_SetFontOutline( $font, 1 );

    # render some outlined text...

    # set the loaded font's outline back to normal
    TTF_SetFontOutline( $font, 0 );

Expected parameters include:

=over

=item C<font> - the loaded font to set the outline size of

=item C<outline> - the size of outline desired, in pixels. Use zero (C<0>) to turn off outlining.

=back

Notes:

=over

=item * Passing an undefined C<font> into this function will cause a segfault.

=item * This will flush the internal cache of previously rendered glyphs, even if there is no change in outline size, so it may be best to check the current outline size using C<TTF_GetFontOutline> first.

=back

=head2 C<TTF_GetFontHinting( ... )>

Get the current hinting setting from the loaded C<font>.

    # get the loaded font's hinting setting
    my $hinting = TTF_GetFontHinting($font);
    printf 'The font hinting is currently set to %s',
        $hinting == TTF_HINTING_NORMAL ? 'Normal' :
        $hinting == TTF_HINTING_LIGHT  ? 'Light' :
        $hinting == TTF_HINTING_MONO   ? 'Mono' :
        $hinting == TTF_HINTING_NONE   ? 'None' :
        'Unknonwn';

Expected parameters include:

=over

=item C<font> - the loaded font to get the hinting setting of

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

Returns the hinting type matching one of the following defined values:

=over

=item C<TTF_HINTING_NORMAL>

=item C<TTF_HINTING_LIGHT>

=item C<TTF_HINTING_MONO>

=item C<TTF_HINTING_NONE>

=back

If no hinting is set then C<TTF_HINTING_NORMAL> is returned.

=head2 C<TTF_SetFontHinting( ... )>

Set the hinting of the loaded C<font>. You should experiment with this setting
if you know which font you are using beforehand, especially when using smaller
sized fonts. If the user is selecting a font, you may wish to let them select
the hinting mode for that font as well.

    # set the loaded font's hinting to optimized for monochrome rendering
    TTF_SetFontHinting( $font, TTF_HINTING_MONO );

    # render some monochrome text...

    # set the loaded font's hinting back to normal
    TTF_SetFontHinting( $font, TTF_HINTING_NORMAL );

Expected parameters include:

=over

=item C<font> - the loaded font to set the hinting of

=item C<hinting> - the hinting setting desired, which is one of:

=over

=item C<TTF_HINTING_NORMAL>

=item C<TTF_HINTING_LIGHT>

=item C<TTF_HINTING_MONO>

=item C<TTF_HINTING_NONE>

=back

The default is C<TTF_HINTING_NORMAL>.

=back

Notes:

=over

=item * Passing an undefined C<font> into this function will cause a segfault.

=item * This will flush the internal cache of previously rendered glyphs, even if there is no change in hinting, so it may be best to check the current hinting by using L<< C<TTF_GetFontHinting( ... )>|/C<TTF_GetFontHinting( ... )> >> first.

=back

=head2 C<TTF_GetFontKerning( ... )>

Get the current kerning setting of the loaded C<font>.

    # get the loaded font's kerning setting
    my $kerning = TTF_GetFontKerning( $font );
    printf 'The font kerning is currently %sabled', $kerning ? 'en' : 'dis';

The default for a newly loaded font is enabled.

Expected parameters include:

=over

=item C<font> - the loaded font to get the kerning setting of

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

Returns zero (C<0>) if kerning is disabled. A non-zero value is returned when
enabled.

=head2 C<TTF_SetFontKerning( ... )>

Set whether to use kerning when rendering the loaded font.

    # turn off kerning on the loaded font
    TTF_SetFontKerning( $font, 0 );

    # render some text string...

    # turn kerning back on for the loaded font
    TTF_SetFontKerning( $font, 1 );

This has no effect on individual glyphs, but rather when rendering whole
strings of characters, at least a word at a time. Perhaps the only time to
disable this is when kerning is not working for a specific font, resulting in
overlapping glyphs or abnormal spacing within words.

Expected parameters include:

=over

=item C<font> - the loaded font to set the kerning value of

=item C<allowed> - C<0> to disable kerning; a non-zero value to enable kerning

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

=head2 C<TTF_FontHeight( ... )>

Get the maximum pixel height of all glyphs of the loaded font.

    printf "The font max height is: %d\n", TTF_FontHeight( $font );

You may use this height for rendering text as close together vertically as
possible, though adding at least one pixel height to it will space it so they
can't touch. Remember that C<SDL_ttf> doesn't handle multiline printing, so you
are responsible for line spacing, see the L<< C<TTF_FontLineSkip( ...
)>|/C<TTF_FontLineSkip( ... )> >> as well.

Expected parameters include:

=over

=item C<font> - the loaded font to query

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

Returns the maximum pixel height of all glyphs in the font.

=head2 C<TTF_FontAscent( ... )>

Get the maximum pixel ascent of all glyphs of the loaded C<font>. This can also
be interpreted as the distance from the top of the font to the baseline.

    printf "The font ascent is: %d\n", TTF_FontAscent( $font );

It could be used when drawing an individual glyph relative to a top point, by
combining it with the glyph's maxy metric to resolve the top of the rectangle
used when blitting the glyph on the screen.

    $rect->y( $top + TTF_FontAscent($font) - $glyph_metric->maxy );

Expected parameters include:

=over

=item C<font> - the loaded font to query

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

Returns the maximum pixel ascent of all glyphs in the font.

=head2 C<TTF_FontDescent( ... )>

Get the maximum pixel descent of all glyphs of the loaded C<font>. This can
also be interpreted as the distance from the baseline to the bottom of the
font.

    printf "The font descent is: %d\n", TTF_FontDescent( $font );

It could be used when drawing an individual glyph relative to a bottom point,
by combining it with the glyph's maxy metric to resolve the top of the
rectangle used when blitting the glyph on the screen.

    $rect->y( $bottom - TTF_FontDescent($font) - $glyph_metric->maxy );

Expected parameters include:

=over

=item C<font> - the loaded font to query

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

Returns the maximum pixel height of all glyphs in the font.

=head2 C<TTF_FontLineSkip( ... )>

Get the recommended pixel height of a rendered line of text of the loaded
C<font>. This is usually larger than the L<< C<TTF_FontHeight( ...
)>|/C<TTF_FontHeight( ... )> >> of the C<font>.

    printf "The font line skip is: %d\n", TTF_FontLineSkip( $font );

Expected parameters include:

=over

=item C<font> - the loaded font to query

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

Returns the recommended pixel height.

=head2 C<TTF_FontFaces( ... )>

Get the number of faces ("sub-fonts") available in the loaded C<font>.

    printf "The number of faces in the font is: %ld\n", TTF_FontFaces($font);

This is a count of the number of specific fonts (based on size and style and
other typographical features perhaps) contained in the font itself. It seems to
be a useless fact to know, since it can't be applied in any other C<SDL_ttf>
functions.

Expected parameters include:

=over

=item C<font> - the loaded font to query

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

Returns the number of faces in the C<font>.

=head2 C<TTF_FontFaceIsFixedWidth( ... )>

Test if the current font face of the loaded font is a fixed width C<font>.

    if(TTF_FontFaceIsFixedWidth($font)) {
        printf "The font is fixed width.\n";
    }
    else {
        print "The font is not fixed width.\n";
    }

Fixed width fonts are monospace, meaning every character that exists in the
font is the same width, thus you can assume that a rendered string's width is
going to be the result of a simple calculation:

    $glyph_width * length( $string )

Expected parameters include:

=over

=item C<font> - the loaded font to query

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

Returns C<0> if the font is B<not> fixed width. Otherwise, a value greater than
zero is returned.

=head2 C<TTF_FontFaceFamilyName( ... )>

Get the current font face family name from the loaded font.

    my $fam = TTF_FontFaceFamilyName( $font );
    print 'The family name of the face in the font is ' . $fam if defined $fam;

Expected parameters include:

=over

=item C<font> - the loaded font to query

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

Returns the current family name of the font face if defined.

=head2 C<TTF_FontFaceStyleName( ... )>

Get the current font face style name from the loaded font.

    my $style = TTF_FontFaceStyleName( $font );
    print 'The style name of the face in the font is ' . $style if defined $style;

Expected parameters include:

=over

=item C<font> - the loaded font to query

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

Returns the current style name of the font face if defined.

=head2 C<TTF_GlyphIsProvided( ... )>

Get the status of the availability of the glyph for ch from the loaded C<font>.

    my $index = TTF_GlyphIsProvided( $font, 'g' );
    printf "There is no 'g' in the loaded font!\n" if !$index;

Expected parameters include:

=over

=item C<font> - the loaded font to query

=item C<ch> - the Unicode character to test glyph availability of

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

Returns the index of the glyph for C<ch> in C<font>, or C<0> for an undefined
character code.

=head2 C<TTF_GlyphMetrics( ... )>

Get desired glyph metrics of the UNICODE char given in C<ch> from the loaded
C<font>.

    # get the glyph metric for the letter 'g' in a loaded font
    my ( $minx, $maxx, $miny, $maxy, $advance );
    if ( TTF_GlyphMetrics( $font, 'g', \$minx, \$maxx, \$miny, \$maxy, \$advance ) == -1 ) {
        printf "%s\n", TTF_GetError();
    }
    else {
        warn;
        printf "minx    : %d\n", $minx;
        printf "maxx    : %d\n", $maxx;
        printf "miny    : %d\n", $miny;
        printf "maxy    : %d\n", $maxy;
        printf "advance : %d\n", $advance;
    }

Expected parameters include:

=over

=item C<font> - the loaded font to query

=item C<ch> - the Unicode character to test glyph metrics of

=item C<minx> - pointer to int to store the returned minimum X offset into, or C<undef> when no return value desired

=item C<maxx> - pointer to int to store the returned maximum X offset into, or C<undef> when no return value desired

=item C<miny> - pointer to int to store the returned minimum Y offset into, or C<undef> when no return value desired

=item C<maxy> - pointer to int to store the returned maximum X offset into, or C<undef> when no return value desired

=item C<advance> - pointer to int to store the returned advance offset into, or C<undef> when no return value desired.

=back

Note: Passing an undefined C<font> into this function will cause a segfault.

Returns C<0> on success, with all defined parameters set to the glyph metric as
appropriate. C<-1> on errors, such as when the glyph named by ch does not exist
in the font.

=head3 Notes

This diagram shows the relationships between the values:

=begin :html

<p><img alt="glyph metrics"
src="https://www.libsdl.org/projects/SDL_ttf/docs/metrics.png" /></p>

=end :html

=begin text

L<https://www.libsdl.org/projects/SDL_ttf/docs/metrics.png>

=end text

Here's how the numbers look:

    TTF_FontHeight        : 53
    TTF_FontAscent        : 38
    TTF_FontDescent       : -14
    TTF_FontLineSkip      : 55
    TTF_GlyphMetrics('g') :
        minx    = 1
        maxx    = 15
        miny    = -7
        maxy    = 15
        advance = 16

We see from the Line Skip that each line of text is 55 pixels high, including
spacing for this font.

The C<Ascent-Descent=52>, so there seems to be 3 pixels worth of space between
lines for this font.

Let's say we want to draw the surface of glyph 'g' (retrieved via L<<
C<TTF_RenderGlyph_Solid( ... )>|/C<TTF_RenderGlyph_Solid( ... )> >> or a
similar function), at coordinates (X,Y) for the top left corner of the desired
location. Here's the math using glyph metrics:

    # $glyph, $screen, $rect
    my ($minx, $maxy, $advance);
    TTF_GlyphMetrics( $font, 'g', \$minx, undef, undef, \$maxy, \$advance );
    $rect->x( $X + $minx );
    $rect->y( $Y + TTF_FontAscent($font) - $maxy );
    SDL_BlitSurface( $glyph, undef, $screen, $rect );
    $X += $advance;

Let's say we want to draw the same glyph at coordinates (X,Y) for the origin
(on the baseline) of the desired location. Here's the math using glyph metrics:

    my ( $minx, $maxy, $advance );
    TTF_GlyphMetrics( $font, 'g', \$minx, undef, undef, \$maxy, \$advance );
    rect->x( $X + $minx );
    rect->y( $Y - $maxy );
    SDL_BlitSurface( $glyph, undef, $screen, $rect);
    $X += $advance;

Notes:

=over

=item * The only difference between these example is the C<TTF_FontAscent( $font )> used in the top-left corner algorithm.

=item * These examples assume that 'g' is present in the font!

=item * In practice you may want to also subtract C<TTF_GetFontOutline( $font )> from your X and Y coordinates to keep the glyphs in the same place no matter what outline size is set.

=back

See the web page at L<The FreeType2 Documentation
Tutorial|http://freetype.sourceforge.net/freetype2/docs/tutorial/step2.html>
for more.

Any glyph based rendering calculations will not result in accurate kerning
between adjacent glyphs.

=head2 C<TTF_SizeText( ... )>

Calculate the resulting surface size of the LATIN1 encoded C<text> rendered
using C<font>.

    # get the width and height of a string as it would be rendered in a loaded font
    my ($w, $h);
    if( TTF_SizeText( $font, 'Hello World!', \$w, \$h ) ) {
        # perhaps print the current TTF_GetError(), the string can't be rendered...
    }
	else {
        printf( "width=%d height=%d\n", $w, $h );
    }

No actual rendering is done, however correct kerning is done to get the actual
width. The height returned in C<h> is the same as you can get using L<<
C<TTF_FontHeight( ... )>|/C<TTF_FontHeight( ... )> >>.

Expected parameters include:

=over

=item C<font> - the loaded font to use to calculate the size of the string with

=item C<text> - The LATIN1 string to size up

=item C<w> - pointer to int in which to fill the text width, or C<undef> for no desired return value

=item C<h> - pointer to int in which to fill the text height, or C<undef> for no desired return value

=back

Notes:

=over

=item * Passing a C<undef> font into this function will cause a segfault

=item * Passing a C<undef> text into this function will result in undefined behavior

=back

Returns C<0> on success with the variables pointed to by C<w> and C<h> set as
appropriate, if they are not C<undef>. C<-1> is returned on errors, such as a
glyph in the string not being found.

=head2 C<TTF_SizeUNICODE( ... )>

Calculate the resulting surface size of the UNICODE encoded C<text> rendered
using C<font>.

    # get the width and height of a string as it would be rendered in a loaded font
    my ($w, $h);
    if( TTF_SizeUNICODE( $font, 'Hello World!', \$w, \$h ) ) {
        # perhaps print the current TTF_GetError(), the string can't be rendered...
    }
	else {
        printf( "width=%d height=%d\n", $w, $h );
    }

No actual rendering is done, however correct kerning is done to get the actual
width. The height returned in C<h> is the same as you can get using L<<
C<TTF_FontHeight( ... )>|/C<TTF_FontHeight( ... )> >>.

Expected parameters include:

=over

=item C<font> - the loaded font to use to calculate the size of the string with

=item C<text> - The UNICODE string to size up

=item C<w> - pointer to int in which to fill the text width, or C<undef> for no desired return value

=item C<h> - pointer to int in which to fill the text height, or C<undef> for no desired return value

=back

Notes:

=over

=item * Passing a C<undef> font into this function will cause a segfault

=item * Passing a C<undef> text into this function will result in undefined behavior

=back

Returns C<0> on success with the variables pointed to by C<w> and C<h> set as
appropriate, if they are not C<undef>. C<-1> is returned on errors, such as a
glyph in the string not being found.

=head1 Render Functions

These functions render text using a L<SDL2::TTF::Font>.

There are three modes of rendering:

=over

=item Solid: Quick and Dirty

Create an 8-bit palletized surface and render the given text at fast quality
with the given font and color. The pixel value of 0 is the colorkey, giving a
transparent background when blitted. Pixel and colormap value 1 is set to the
text foreground color. This allows you to change the color without having to
render the text again. Palette index 0 is of course not drawn when blitted to
another surface, since it is the colorkey, and thus transparent, though its
actual color is 255 minus each of the RGB components of the foreground color.
This is the fastest rendering speed of all the rendering modes. This results in
no box around the text, but the text is not as smooth. The resulting surface
should blit faster than the Blended one. Use this mode for FPS and other fast
changing updating text displays.

=item Shaded: Slow and Nice, but with a Solid Box

Create an 8-bit palletized surface and render the given text at high quality
with the given font and colors. The 0 pixel value is background, while other
pixels have varying degrees of the foreground color from the background color.
This results in a box of the background color around the text in the foreground
color. The text is antialiased. This will render slower than Solid, but in
about the same time as Blended mode. The resulting surface should blit as fast
as Solid, once it is made. Use this when you need nice text, and can live with
a box.

=item Blended: Slow Slow Slow, but Ultra Nice over another image

Create a 32-bit ARGB surface and render the given text at high quality, using
alpha blending to dither the font with the given color. This results in a
surface with alpha transparency, so you don't have a solid colored box around
the text. The text is antialiased. This will render slower than Solid, but in
about the same time as Shaded mode. The resulting surface will blit slower than
if you had used Solid or Shaded. Use this when you want high quality, and the
text isn't changing too fast.

=back

=head2 C<TTF_RenderText_Solid( ... )>

Render the LATIN1 encoded C<text> using C<font> with C<fg> color onto a new
surface, using the B<Solid> mode. The caller (you!) is responsible for freeing
any returned surface.

    # Render some text in solid black to a new surface
    # then blit to the upper left of the screen
    # then free the text surface
    my $color = SDL2::Color->new({r => 0, g => 0, b => 0});
	if(!(my $text_surface = TTF_RenderText_Solid( $font,"Hello World!", $color))) {
		# handle error here, perhaps print TTF_GetError at least
	}
	else {
		SDL_BlitSurface( $text_surface, undef, $screen, undef );
		# perhaps we can reuse it, but I assume not for simplicity.
		SDL_FreeSurface( $text_surface );
	}

Expected parameters include:

=over

=item C<font> - font to render the text with

=item C<text> - the LATIN1 string to render

=item C<fg> - the color to render the text in; this becomes colormap index 1

=back

Notes:

=over

=item * Passing a C<undef> font into this function will cause a segfault

=item * Passing a C<undef> text into this function will result in undefined behavior

=back

Returns a new L<SDL2::Surface> on success.

=head2 C<TTF_RenderUTF8_Solid( ... )>

Render the UTF8 encoded C<text> using C<font> with C<fg> color onto a new
surface, using the B<Solid> mode. The caller (you!) is responsible for freeing
any returned surface.

    # Render some text in solid black to a new surface
    # then blit to the upper left of the screen
    # then free the text surface
    my $color = SDL2::Color->new({r => 0, g => 0, b => 0});
	if(!(my $text_surface = TTF_RenderUTF8_Solid( $font,"Hello World!", $color))) {
		# handle error here, perhaps print TTF_GetError at least
	}
	else {
		SDL_BlitSurface( $text_surface, undef, $screen, undef );
		# perhaps we can reuse it, but I assume not for simplicity.
		SDL_FreeSurface( $text_surface );
	}

Expected parameters include:

=over

=item C<font> - font to render the text with

=item C<text> - the UTF8 string to render

=item C<fg> - the color to render the text in; this becomes colormap index 1

=back

Notes:

=over

=item * Passing a C<undef> font into this function will cause a segfault

=item * Passing a C<undef> text into this function will result in undefined behavior

=back

Returns a new L<SDL2::Surface> on success.

=head2 C<TTF_RenderUNICODE_Solid( ... )>

Render the UNICODE encoded C<text> using C<font> with C<fg> color onto a new
surface, using the B<Solid> mode. The caller (you!) is responsible for freeing
any returned surface.

    # Render some text in solid black to a new surface
    # then blit to the upper left of the screen
    # then free the text surface
    my $color = SDL2::Color->new({r => 0, g => 0, b => 0});
	if(!(my $text_surface = TTF_RenderUNICODE_Solid( $font,"Hello World!", $color))) {
		# handle error here, perhaps print TTF_GetError at least
	}
	else {
		SDL_BlitSurface( $text_surface, undef, $screen, undef );
		# perhaps we can reuse it, but I assume not for simplicity.
		SDL_FreeSurface( $text_surface );
	}

Expected parameters include:

=over

=item C<font> - font to render the text with

=item C<text> - the UNICODE string to render

=item C<fg> - the color to render the text in; this becomes colormap index 1

=back

Notes:

=over

=item * Passing a C<undef> font into this function will cause a segfault

=item * Passing a C<undef> text into this function will result in undefined behavior

=back

Returns a new L<SDL2::Surface> on success.

=head2 C<TTF_RenderGlyph_Solid( ... )>

Render the glyph for the UNICODE C<ch> using C<font> with C<fg> color onto a
new surface, using the B<Solid> mode. The caller (you!) is responsible for
freeing any returned surface.

    # Render and cache all printable ASCII characters in solid black
    my @glyph_cache;
    for my $ord ( 0 .. 127 ) {
        push @glyph_cache, TTF_RenderGlyph_Solid( $font, chr $ord, $color );
    }

Expected parameters include:

=over

=item C<font> - font to render the text with

=item C<ch> - the glyph to render

=item C<fg> - the color to render the glyph in; this becomes colormap index 1

=back

Note: Passing a C<undef> font into this function will cause a segfault.

Returns a new L<SDL2::Surface> on success. C<undef> is returned on errors, such
as when the glyph is not available in the font.

Combined with a cache of the glyph metrics (minx, miny, and advance), you might
make a fast text rendering routine that prints directly to the screen, but with
inaccurate kerning.

=head2 C<TTF_RenderText_Shaded( ... )>

Render the LATIN1 encoded C<text> using C<font> with C<fg> color onto a new
surface filled with the C<bg> color, using the B<Shaded> mode. The caller
(you!) is responsible for freeing any returned surface.

    # Render some text in shaded black on white to a new surface
    # then blit to the upper left of the screen
    # then free the text surface
    my $color   = SDL2::Color->new({r => 0, g => 0, b => 0});
    my $bgcolor = SDL2::Color->new({r => 0xff, g => 0xff, b => 0xff});
	if(!(my $text_surface = TTF_RenderText_Shaded( $font,"Hello World!", $color, $bgcolor))) {
		# handle error here, perhaps print TTF_GetError at least
	}
	else {
		SDL_BlitSurface( $text_surface, undef, $screen, undef );
		# perhaps we can reuse it, but I assume not for simplicity.
		SDL_FreeSurface( $text_surface );
	}

Expected parameters include:

=over

=item C<font> - font to render the text with

=item C<text> - the LATIN1 string to render

=item C<fg> - the color to render the text in; this becomes colormap index 1

=item C<bg> - the color to render the background box in; this becomes colormap index 0

=back

Notes:

=over

=item * Passing a C<undef> font into this function will cause a segfault

=item * Passing a C<undef> text into this function will result in undefined behavior

=back

Returns a new L<SDL2::Surface> on success.

=head2 C<TTF_RenderUTF8_Shaded( ... )>

Render the UTF8 encoded C<text> using C<font> with C<fg> color onto a new
surface filled with the C<bg> color, using the B<Shaded> mode. The caller
(you!) is responsible for freeing any returned surface.

    # Render some text in shaded black on white to a new surface
    # then blit to the upper left of the screen
    # then free the text surface
    my $color   = SDL2::Color->new({r => 0, g => 0, b => 0});
    my $bgcolor = SDL2::Color->new({r => 0xff, g => 0xff, b => 0xff});
	if(!(my $text_surface = TTF_RenderUTF8_Shaded( $font,"Hello World!", $color, $bgcolor))) {
		# handle error here, perhaps print TTF_GetError at least
	}
	else {
		SDL_BlitSurface( $text_surface, undef, $screen, undef );
		# perhaps we can reuse it, but I assume not for simplicity.
		SDL_FreeSurface( $text_surface );
	}

Expected parameters include:

=over

=item C<font> - font to render the text with

=item C<text> - the UTF8 string to render

=item C<fg> - the color to render the text in; this becomes colormap index 1

=item C<bg> - the color to render the background box in; this becomes colormap index 0

=back

Notes:

=over

=item * Passing a C<undef> font into this function will cause a segfault

=item * Passing a C<undef> text into this function will result in undefined behavior

=back

Returns a new L<SDL2::Surface> on success.

=head2 C<TTF_RenderUNICODE_Shaded( ... )>

Render the UNICODE encoded C<text> using C<font> with C<fg> color onto a new
surface filled with the C<bg> color, using the B<Shaded> mode. The caller
(you!) is responsible for freeing any returned surface.

    # Render some text in shaded black on white to a new surface
    # then blit to the upper left of the screen
    # then free the text surface
    my $color   = SDL2::Color->new({r => 0, g => 0, b => 0});
    my $bgcolor = SDL2::Color->new({r => 0xff, g => 0xff, b => 0xff});
	if(!(my $text_surface = TTF_RenderUNICODE_Shaded( $font,"Hello World!", $color, $bgcolor))) {
		# handle error here, perhaps print TTF_GetError at least
	}
	else {
		SDL_BlitSurface( $text_surface, undef, $screen, undef );
		# perhaps we can reuse it, but I assume not for simplicity.
		SDL_FreeSurface( $text_surface );
	}

Expected parameters include:

=over

=item C<font> - font to render the text with

=item C<text> - the UNICODE string to render

=item C<fg> - the color to render the text in; this becomes colormap index 1

=item C<bg> - the color to render the background box in; this becomes colormap index 0

=back

Notes:

=over

=item * Passing a C<undef> font into this function will cause a segfault

=item * Passing a C<undef> text into this function will result in undefined behavior

=back

Returns a new L<SDL2::Surface> on success.

=head2 C<TTF_RenderGlyph_Shaded( ... )>

Render the glyph for the UNICODE C<ch> using C<font> with C<fg> color onto a
new surface, using the B<Shaded> mode. The caller (you!) is responsible for
freeing any returned surface.

    # Render and cache all printable ASCII characters in solid black
    my @glyph_cache;
    for my $ord ( 0 .. 127 ) {
        push @glyph_cache, TTF_RenderGlyph_Shaded( $font, chr $ord, $color, $bgcolor );
    }

Expected parameters include:

=over

=item C<font> - font to render the text with

=item C<ch> - the glyph to render

=item C<fg> - the color to render the glyph in; this becomes colormap index 1

=back

Note: Passing a C<undef> font into this function will cause a segfault.

Returns a new L<SDL2::Surface> on success. C<undef> is returned on errors, such
as when the glyph is not available in the font.

Combined with a cache of the glyph metrics (minx, miny, and advance), you might
make a fast text rendering routine that prints directly to the screen, but with
inaccurate kerning.

=head2 C<TTF_RenderText_Blended( ... )>

Render the LATIN1 encoded C<text> using C<font> with C<fg> color onto a new
surface, using the B<Blended> mode. The caller (you!) is responsible for
freeing any returned surface.

    # Render some text in blended black to a new surface
    # then blit to the upper left of the screen
    # then free the text surface
    my $color   = SDL2::Color->new({r => 0, g => 0, b => 0});
	if(!(my $text_surface = TTF_RenderText_Blended( $font,"Hello World!", $color ))) {
		# handle error here, perhaps print TTF_GetError at least
	}
	else {
		SDL_BlitSurface( $text_surface, undef, $screen, undef );
		# perhaps we can reuse it, but I assume not for simplicity.
		SDL_FreeSurface( $text_surface );
	}

Expected parameters include:

=over

=item C<font> - font to render the text with

=item C<text> - the LATIN1 string to render

=item C<fg> - the color to render the text in; pixels are blended between transparent and this color to draw the antialiased glyphs

=back

Notes:

=over

=item * Passing a C<undef> font into this function will cause a segfault

=item * Passing a C<undef> text into this function will result in undefined behavior

=back

Returns a new L<SDL2::Surface> on success.

=head2 C<TTF_RenderUTF8_Blended( ... )>

Render the UTF8 encoded C<text> using C<font> with C<fg> color onto a new
surface, using the B<Blended> mode. The caller (you!) is responsible for
freeing any returned surface.

    # Render some text in blended black to a new surface
    # then blit to the upper left of the screen
    # then free the text surface
    my $color   = SDL2::Color->new({r => 0, g => 0, b => 0});
	if(!(my $text_surface = TTF_RenderUTF8_Blended( $font,"Hello World!", $color ))) {
		# handle error here, perhaps print TTF_GetError at least
	}
	else {
		SDL_BlitSurface( $text_surface, undef, $screen, undef );
		# perhaps we can reuse it, but I assume not for simplicity.
		SDL_FreeSurface( $text_surface );
	}

Expected parameters include:

=over

=item C<font> - font to render the text with

=item C<text> - the UTF8 string to render

=item C<fg> - the color to render the text in; pixels are blended between transparent and this color to draw the antialiased glyphs

=back

Notes:

=over

=item * Passing a C<undef> font into this function will cause a segfault

=item * Passing a C<undef> text into this function will result in undefined behavior

=back

Returns a new L<SDL2::Surface> on success.

=head2 C<TTF_RenderUNICODE_Blended( ... )>

Render the UNICODE encoded C<text> using C<font> with C<fg> color onto a new
surface, using the B<Blended> mode. The caller (you!) is responsible for
freeing any returned surface.

    # Render some text in blended black to a new surface
    # then blit to the upper left of the screen
    # then free the text surface
    my $color   = SDL2::Color->new({r => 0, g => 0, b => 0});
	if(!(my $text_surface = TTF_RenderUNICODE_Blended( $font,"Hello World!", $color ))) {
		# handle error here, perhaps print TTF_GetError at least
	}
	else {
		SDL_BlitSurface( $text_surface, undef, $screen, undef );
		# perhaps we can reuse it, but I assume not for simplicity.
		SDL_FreeSurface( $text_surface );
	}

Expected parameters include:

=over

=item C<font> - font to render the text with

=item C<text> - the UNICODE string to render

=item C<fg> - the color to render the text in; pixels are blended between transparent and this color to draw the antialiased glyphs

=back

Notes:

=over

=item * Passing a C<undef> font into this function will cause a segfault

=item * Passing a C<undef> text into this function will result in undefined behavior

=back

Returns a new L<SDL2::Surface> on success.

=head2 C<TTF_RenderGlyph_Blended( ... )>

Render the glyph for the UNICODE C<ch> using C<font> with C<fg> color onto a
new surface, using the B<Blended> mode. The caller (you!) is responsible for
freeing any returned surface.

    # Render and cache all printable ASCII characters in blended black
    my @glyph_cache;
    for my $ord ( 0 .. 127 ) {
        push @glyph_cache, TTF_RenderGlyph_Blended( $font, chr $ord, $color );
    }

Expected parameters include:

=over

=item C<font> - font to render the text with

=item C<ch> - the glyph to render

=item C<fg> - the color to render the glyph in; pixels are blended between transparent and this color to draw the antialiased glyph

=back

Note: Passing a C<undef> font into this function will cause a segfault.

Returns a new L<SDL2::Surface> on success. C<undef> is returned on errors, such
as when the glyph is not available in the font.

Combined with a cache of the glyph metrics (minx, miny, and advance), you might
make a fast text rendering routine that prints directly to the screen, but with
inaccurate kerning.

=head2 Defined Values

These may be imported by name or with the C<:all> tag.

=over

=item C<TTF_MAJOR_VERSION>

SDL_ttf library major number at compilation time.

=item C<TTF_MINOR_VERSION>

SDL_ttf library minor number at compilation time.

=item C<TTF_PATCHLEVEL>

SDL_ttf library patch level at compilation time.

=item C<UNICODE_BOM_NATIVE>

This allows you to switch byte-order of UNICODE text data to native order,
meaning the mode of your CPU. This is meant to be used in a UNICODE string that
you are using with the SDL_ttf API.

=item C<UNICODE_BOM_SWAPPED>

This allows you to switch byte-order of UNICODE text data to swapped order,
meaning the reversed mode of your CPU. So if your CPU is LSB, then the data
will be interpreted as MSB. This is meant to be used in a UNICODE string that
you are using with the SDL_ttf API.

=item C<TTF_STYLE_NORMAL>

Used to indicate regular, normal, plain rendering style.

=item C<TTF_STYLE_BOLD>

Used to indicate bold rendering style. This is used in a bitmask along with
other styles.

=item C<TTF_STYLE_ITALIC>

Used to indicate italicized rendering style. This is used in a bitmask along
with other styles.

=item C<TTF_STYLE_UNDERLINE>

Used to indicate underlined rendering style. This is used in a bitmask along
with other styles.

=item C<TTF_STYLE_STRIKETHROUGH>

Used to indicate strikethrough rendering style. This is used in a bitmask along
with other styles.

=item C<TTF_HINTING_NORMAL>

This corresponds to the default hinting algorithm, optimized for standard
gray-level rendering

=item C<TTF_HINTING_LIGHT>

A lighter hinting algorithm for non-monochrome modes. Many generated glyphs are
more fuzzy but better resemble its original shape. A bit like rendering on Mac
OS X.

=item C<TTF_HINTING_MONO>

Strong hinting algorithm that should only be used for monochrome output. The
result is probably unpleasant if the glyph is rendered in non-monochrome modes.

=item C<TTF_HINTING_NONE>

No hinting is used so the font may become very blurry or messy at smaller
sizes.

=item C<TTF_HINTING_LIGHT_SUBPIXEL>

A grayscale subpixel hinting algorithm.

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

truetype byteswapped segfault workaround bitmask strikethrough strikethroughs
maxy ch monospace colormap miny grayscale antialiased

=end stopwords


=cut

};
1;
