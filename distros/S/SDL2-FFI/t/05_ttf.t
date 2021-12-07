use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Class qw[isa_ok can_ok];
use lib -d '../t' ? './lib' : 't/lib';
use lib '../lib', 'lib';
#
use SDL2::FFI qw[SDL_RWFromFile];
use SDL2::TTF qw[:all];
$|++;
#
my $hello_world_ttf = ( -d '../t' ? './' : './t/' ) . 'etc/hello-world.ttf';
#
my $compile_version = SDL2::Version->new();
my $link_version    = TTF_Linked_Version();
SDL_TTF_VERSION($compile_version);
diag sprintf 'compiled with SDL_ttf version: %d.%d.%d', $compile_version->major,
    $compile_version->minor, $compile_version->patch;
diag sprintf 'running with SDL_ttf version: %d.%d.%d', $link_version->major, $link_version->minor,
    $link_version->patch;
#
is TTF_WasInit(), 0, 'TTF_WasInit( ) returns 0 before TTF_Init( )';
is TTF_Init(),    0, 'TTF_Init( ) returned 0';
is TTF_WasInit(), 1, 'TTF_WasInit( ) returns 1 after TTF_Init( )';
TTF_Quit();
is TTF_WasInit(), 0, 'TTF_WasInit( ) returns 0 after TTF_Quit( )';
#
TTF_SetError( 'myfunc is not implemented! %d was passed in.', 6 );
is TTF_GetError(), 'myfunc is not implemented! 6 was passed in.',
    'TTF_SetError( ... ) and TTF_GetError( ... ) work';
#
# load font.ttf at size 16 into font
ok !TTF_OpenFont( 'fake.ttf', 16 ),
    'TTF_OpenFont( ... ) with a fake font does not work before TTF_Init( )';
diag 'TTF_GetError is: ' . TTF_GetError();
ok !TTF_OpenFont( ( -d '../t' ? './' : './t/' ) . '/etc/hello-world.ttf', 16 ),
    'TTF_OpenFont( ... ) with a real font does not work before TTF_Init( )';
diag 'TTF_GetError is: ' . TTF_GetError();
diag 'Calling TTF_Init( ) again';
TTF_Init();
ok !TTF_OpenFont( 'fake.ttf', 16 ), 'TTF_OpenFont( ... ) with a fake font still does not work';
diag 'TTF_GetError is: ' . TTF_GetError();
ok my $font = TTF_OpenFont( $hello_world_ttf, 16 ),
    'TTF_OpenFont( ... ) with a real font works now';
ok $font->isa('SDL2::TTF::Font'), 'font returned is an SDL2::TTF::Font object';
ok $font = TTF_OpenFontRW( SDL_RWFromFile( $hello_world_ttf, 'rb' ), 1, 16 ),
    'TTF_OpenFontRW( ... ) with a real font works';
ok $font->isa('SDL2::TTF::Font'), 'font returned is an SDL2::TTF::Font object';
ok $font = TTF_OpenFontIndex( $hello_world_ttf, 16, 0 ),
    'TTF_OpenFontIndex( ... ) with a real font works now';
ok $font->isa('SDL2::TTF::Font'), 'font returned is an SDL2::TTF::Font object';
ok $font = TTF_OpenFontIndexRW( SDL_RWFromFile( $hello_world_ttf, 'rb' ), 1, 16 ),
    'TTF_OpenFontIndexRW( ... ) with a real font works';
ok $font->isa('SDL2::TTF::Font'), 'font returned is an SDL2::TTF::Font object';

# Returns void... Just making sure it doesn't die
TTF_CloseFont($font);
#
# Returns void... Just making sure it doesn't die
TTF_ByteSwappedUNICODE(1);
my $style = TTF_GetFontStyle( TTF_OpenFontIndex( $hello_world_ttf, 16, 0 ) );
is TTF_GetFontStyle( TTF_OpenFontIndex( $hello_world_ttf, 16, 0 ) ), TTF_STYLE_NORMAL,
    'TTF_GetFontStyle( ... ) returns normal on our font';

# Returns void... Just making sure it doesn't die
TTF_SetFontStyle( $font, TTF_STYLE_BOLD | TTF_STYLE_ITALIC );

# set the loaded font's style back to normal
TTF_SetFontStyle( $font, TTF_STYLE_NORMAL );
is TTF_GetFontOutline($font), 0, 'TTF_GetFontOutline( $font ) is zero by default';
TTF_SetFontOutline( $font, 5 );
is TTF_GetFontOutline($font), 5, 'TTF_GetFontOutline( $font ) is now 5';
is TTF_GetFontHinting($font), TTF_HINTING_NORMAL,
    'TTF_GetFontHinting( $font ) is TTF_HINTING_NORMAL by default';
TTF_SetFontHinting( $font, TTF_HINTING_MONO );
is TTF_GetFontHinting($font), TTF_HINTING_MONO,
    'TTF_GetFontHinting( $font ) is now TTF_HINTING_MONO';
#
is TTF_GetFontKerning($font), 1, 'Kerning is enabled by default';
TTF_SetFontKerning( $font, 0 );
is TTF_GetFontKerning($font), 0, 'Kerning is now disabled';
#
is TTF_FontHeight($font),           16,             'Font height is 16';
is TTF_FontAscent($font),           26,             'Font max ascent is 26';
is TTF_FontDescent($font),          0,              'Font max descent is 0';
is TTF_FontLineSkip($font),         16,             'Recommended height is 16';
is TTF_FontFaces($font),            1,              'I only created one font face...';
is TTF_FontFaceIsFixedWidth($font), 0,              '...which is not monospaced';
is TTF_FontFaceFamilyName($font),   'hello, world', '...and is named "hello, world"';
is TTF_FontFaceStyleName($font),    'Regular',      '...and is "Regular" styled';
is TTF_GlyphIsProvided( $font, 'H' ), 2, '...and provides an "H"';
is TTF_GlyphIsProvided( $font, 'I' ), 3, '...and provides an "I"';
is TTF_GlyphIsProvided( $font, 'h' ), 0, '...but not an "h"';
is TTF_GlyphIsProvided( $font, 'i' ), 0, '...and not an "i"';
is TTF_GlyphIsProvided( $font, 'A' ), 0, '...not even an "A"';
is TTF_GlyphIsProvided( $font, 'a' ), 0, '...or even an "a"';
{
    # get the glyph metric for the letter 'g' in a loaded font
    my ( $minx, $maxx, $miny, $maxy, $advance );
    is TTF_GlyphMetrics( $font, 'H', \$minx, \$maxx, \$miny, \$maxy, \$advance ), 0,
        'TTF_GlyphMetrics( $font, "H", ... ) == 0';
    is $minx,    0,  '   $minx == 0';
    is $maxx,    23, '   $maxx == 23';
    is $miny,    0,  '   $miny == 0';
    is $maxy,    26, '   $maxy == 26';
    is $advance, 13, '   $advance == 13';
}
{
    my ( $w, $h );
    is TTF_SizeText( $font, 'H', \$w, \$h ), 0, 'TTF_SizeText( ..., "H", ... ) == 0';
    is $w, 23, '   $w == 23';
    is $h, 26, '   $h == 26';
    is TTF_SizeText( $font, 'HI', \$w, \$h ), 0, 'TTF_SizeText( ..., "HI", ... ) == 0';
    is $w, 39, '   $w == 39';
    is $h, 26, '   $h == 26';
    #
    is TTF_SizeText( $font, 'HIHI', \$w, \$h ), 0, 'TTF_SizeText( ..., "HIHI", ... ) == 0';
    is $w, 68, '   $w == 68';
    is $h, 26, '   $h == 26';
}
{
    my ( $w, $h );

    #my $win = $^O eq 'MSWin32';
    is TTF_SizeUNICODE( $font, 'H', \$w, \$h ), 0, 'TTF_SizeUNICODE( ..., "H", ... ) == 0';

    #$win ? is $w, 59, '   $w == 59' : is $w, 47, '   $w == 47';
    is $h, 26, '   $h == 26';
    is TTF_SizeUNICODE( $font, 'HI', \$w, \$h ), 0, 'TTF_SizeUNICODE( ..., "HI", ... ) == 0';

    #$win ? is $w, 59, '   $w == 59' : is $w, 47, '   $w == 47';
    is $h, 26, '   $h == 26';
    #
    is TTF_SizeUNICODE( $font, 'HIHI', \$w, \$h ), 0, 'TTF_SizeUNICODE( ..., "HIHI", ... ) == 0';

    #$win ? is $w, 71, '   $w == 71' : is $w, 47, '   $w == 47';
    is $h, 26, '   $h == 26';
}
#
{
    my $red  = SDL2::Color->new( { r => 0, g => 0, b => 0 } );
    my $blue = SDL2::Color->new( { r => 0, g => 0, b => 0xff } );
    isa_ok TTF_RenderText_Solid( $font, 'Testing!', $red ), ['SDL2::Surface'],
        'TTF_RenderText_Solid( ... ) returns an SDL2::Surface';
    isa_ok TTF_RenderUTF8_Solid( $font, 'Testing!', $red ), ['SDL2::Surface'],
        'TTF_RenderUTF8_Solid( ... ) returns an SDL2::Surface';
    isa_ok TTF_RenderUNICODE_Solid( $font, 'Testing!', $red ), ['SDL2::Surface'],
        'TTF_RenderUNICODE_Solid( ... ) returns an SDL2::Surface';
    isa_ok TTF_RenderGlyph_Solid( $font, 'H', $red ), ['SDL2::Surface'],
        'TTF_RenderGlyph_Solid( ... ) returns an SDL2::Surface';
    #
    isa_ok TTF_RenderText_Shaded( $font, 'Testing!', $red, $blue ), ['SDL2::Surface'],
        'TTF_RenderText_Shaded( ... ) returns an SDL2::Surface';
    isa_ok TTF_RenderUTF8_Shaded( $font, 'Testing!', $red, $blue ), ['SDL2::Surface'],
        'TTF_RenderUTF8_Shaded( ... ) returns an SDL2::Surface';
    isa_ok TTF_RenderUNICODE_Shaded( $font, 'Testing!', $red, $blue ), ['SDL2::Surface'],
        'TTF_RenderUNICODE_Shaded( ... ) returns an SDL2::Surface';
    isa_ok TTF_RenderGlyph_Shaded( $font, 'H', $red, $blue ), ['SDL2::Surface'],
        'TTF_RenderGlyph_Shaded( ... ) returns an SDL2::Surface';
    #
    isa_ok TTF_RenderText_Blended( $font, 'Testing!', $red ), ['SDL2::Surface'],
        'TTF_RenderText_Blended( ... ) returns an SDL2::Surface';
    isa_ok TTF_RenderUTF8_Blended( $font, 'Testing!', $red ), ['SDL2::Surface'],
        'TTF_RenderUTF8_Blended( ... ) returns an SDL2::Surface';
    isa_ok TTF_RenderUNICODE_Blended( $font, 'Testing!', $red ), ['SDL2::Surface'],
        'TTF_RenderUNICODE_Blended( ... ) returns an SDL2::Surface';
    isa_ok TTF_RenderGlyph_Blended( $font, 'H', $red ), ['SDL2::Surface'],
        'TTF_RenderGlyph_Blended( ... ) returns an SDL2::Surface';
}
#
can_ok $_ for qw[
    SDL_TTF_MAJOR_VERSION
    SDL_TTF_MINOR_VERSION
    SDL_TTF_PATCHLEVEL
    UNICODE_BOM_NATIVE
    UNICODE_BOM_SWAPPED
    TTF_STYLE_NORMAL
    TTF_STYLE_BOLD
    TTF_STYLE_ITALIC
    TTF_STYLE_UNDERLINE
    TTF_STYLE_STRIKETHROUGH
    TTF_HINTING_NORMAL
    TTF_HINTING_LIGHT
    TTF_HINTING_MONO
    TTF_HINTING_NONE
    TTF_HINTING_LIGHT_SUBPIXEL];
#
done_testing;
