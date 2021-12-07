use strictures 2;
use lib '../lib';
use SDL2::FFI qw[:all];
use SDL2::Utils qw[enum];
use Object::Pad;
use experimental 'signatures';
use Data::Dump;
$|++;
#
@ARGV = ( '/home/sanko/Projects/SDL2.pm/eg/KohSantepheap-Regular.ttf', 'test' );
#
sub DEFAULT_PTSIZE () {18}
sub DEFAULT_TEXT ()   {'The quick brown fox jumped over the lazy dog'}
sub WIDTH ()          {640}
sub HEIGHT ()         {480}

sub TTF_SHOWFONT_USAGE () {
    "Usage: %s [-solid] [-shaded] [-blended] [-utf8|-unicode] [-b] [-i] [-u] [-s] [-outline size] [-hintlight|-hintmono|-hintnone] [-nokerning] [-fgcol r,g,b,a] [-bgcol r,g,b,a] <font>.ttf [ptsize] [text]\n";
}
enum TextRenderMethod => [ 'TextRenderSolid', 'TextRenderShaded', 'TextRenderBlended' ];
class Scene {
    has $caption     : reader : writer = SDL2::Texture->new;    # SDL_Texture
    has $captionRect : reader = SDL2::Rect->new;                # SDL_Rect
    has $message     : reader : writer = SDL2::Texture->new;    # SDL_Texture
    has $messageRect : reader = SDL2::Rect->new;                # SDL_Rect
};

sub draw_scene ( $renderer, $scene ) {

    # Clear the background to background color
    SDL_SetRenderDrawColor( $renderer, 0xFF, 0xFF, 0xFF, 0xFF );
    SDL_RenderClear($renderer);
    SDL_RenderCopy( $renderer, $scene->caption, undef, $scene->captionRect );
    warn $scene->caption;
    SDL_RenderCopy( $renderer, $scene->message, undef, $scene->messageRect );
    warn $scene->message;
    SDL_RenderPresent($renderer);
}

sub cleanup ($exitcode) {
    TTF_Quit();
    SDL_Quit();
    exit $exitcode;
}

#__END__
#char *argv0 = argv[0];
#SDL_Window *window;
#SDL_Renderer *renderer;
#TTF_Font *font;
#SDL_Surface *text = NULL;
#int ptsize;
#int i, done;
my $white = SDL2::Color->new( { r => 0xFF, g => 0xFF, b => 0xFF, a => 0xFF } );
my $black = SDL2::Color->new( { r => 0x00, g => 0x00, b => 0x00, a => 0x00 } );

#SDL_Color *forecol;
#SDL_Color *backcol;
my $event = SDL2::Event->new();

#TextRenderMethod rendermethod;
my ( $renderstyle, $outline, $hinting, $kerning, $dump );
enum rendertype => [ 'RENDER_LATIN1', 'RENDER_UTF8', 'RENDER_UNICODE' ];
my ( $message, $string );

# Look for special execution mode
$dump = 0;

# Look for special rendering types
my $rendermethod = SDL2::FFI::TextRenderSolid();
$renderstyle = TTF_STYLE_NORMAL;
my $rendertype = SDL2::FFI::RENDER_LATIN1();
$outline = 0;
$hinting = TTF_HINTING_NORMAL;
$kerning = 0;

# Default is black and white
my $forecol = $black;
my $backcol = $white;
for ( my $i = 1; $ARGV[$i] && substr( $ARGV[$i], 0, 1 ) eq '-'; ++$i ) {
    if ( $ARGV[$i] eq '-solid' ) {
        $rendermethod = SDL2::FFI::TextRenderSolid();
    }
    elsif ( $ARGV[$i] eq '-shaded' ) {
        $rendermethod = SDL2::FFI::TextRenderShaded();
    }
    elsif ( $ARGV[$i] eq '-blended' ) {
        $rendermethod = SDL2::FFI::TextRenderBlended();
    }
    elsif ( $ARGV[$i] eq '-utf8' ) {
        $rendertype = RENDER_UTF8();
    }
    elsif ( $ARGV[$i] eq '-unicode' ) {
        $rendertype = RENDER_UNICODE();
    }
    elsif ( $ARGV[$i] eq '-b' ) {
        $renderstyle |= TTF_STYLE_BOLD;
    }
    elsif ( $ARGV[$i] eq '-i' ) {
        $renderstyle |= TTF_STYLE_ITALIC;
    }
    elsif ( $ARGV[$i] eq '-u' ) {
        $renderstyle |= TTF_STYLE_UNDERLINE;
    }
    elsif ( $ARGV[$i] eq '-s' ) {
        $renderstyle |= TTF_STYLE_STRIKETHROUGH;
    }

    #elsif ($ARGV[$i] eq '-outline') {
    #    if (sscanf (argv[++i], "%d", &outline) != 1) {
    #        printf TTF_SHOWFONT_USAGE, __FILE__;
    #        exit 1;
    #    }
    #}
    elsif ( $ARGV[$i] eq '-hintlight' ) {
        $hinting = TTF_HINTING_LIGHT;
    }
    elsif ( $ARGV[$i] eq '-hintmono' ) {
        $hinting = TTF_HINTING_MONO;
    }

    #else
    #if ($ARGV[$i] eq "-hintnone") == 0) {
    #    hinting = TTF_HINTING_NONE;
    #} else
    #if ($ARGV[$i] eq "-nokerning") == 0) {
    #    kerning = 0;
    #}
    elsif ( $ARGV[$i] eq '-dump' ) {
        $dump = 1;
    }

    #else
    #if ($ARGV[$i] eq "-fgcol") == 0) {
    #    int r, g, b, a = 0xFF;
    #    if (sscanf (argv[++i], "%d,%d,%d,%d", &r, &g, &b, &a) < 3) {
    #        fprintf(stderr, TTF_SHOWFONT_USAGE, argv0);
    #        return(1);
    #    }
    #    forecol->r = (Uint8)r;
    #    forecol->g = (Uint8)g;
    #    forecol->b = (Uint8)b;
    #    forecol->a = (Uint8)a;
    #} else
    #if ($ARGV[$i] eq "-bgcol") == 0) {
    #    int r, g, b, a = 0xFF;
    #    if (sscanf (argv[++i], "%d,%d,%d,%d", &r, &g, &b, &a) < 3) {
    #        fprintf(stderr, TTF_SHOWFONT_USAGE, argv0);
    #        return(1);
    #    }
    #    backcol->r = (Uint8)r;
    #    backcol->g = (Uint8)g;
    #    backcol->b = (Uint8)b;
    #    backcol->a = (Uint8)a;
    #}
    else {
        die sprintf TTF_SHOWFONT_USAGE, __FILE__;
    }
}

#$argv += i;
#$argc -= i;
# Check usage
#if (!@ARGV) {
#    die sprintf TTF_SHOWFONT_USAGE, __FILE__;
#}
# Initialize the TTF library
if ( TTF_Init() < 0 ) {
    printf "Couldn't initialize TTF: %s\n", SDL_GetError();
    SDL_Quit();
    die 2;
}

# Open the font file with the requested point size
my $ptsize = 0;
my $i;

#if ( @ARGV > 1 ) {
#    $ptsize = $ARGV[1];
#}
#if ( $ptsize == 0 ) {
$i      = 2;
$ptsize = DEFAULT_PTSIZE;

#}
#else {
#    $i = 3;
#}
my $font = TTF_OpenFont( $ARGV[0], $ptsize );
if ( !defined $font ) {
    printf( "Couldn't load %d pt font from %s: %s\n", $ptsize, __FILE__, SDL_GetError() );
    cleanup(2);
}
TTF_SetFontStyle( $font, $renderstyle );
TTF_SetFontOutline( $font, $outline );
TTF_SetFontKerning( $font, $kerning );
TTF_SetFontHinting( $font, $hinting );
if ($dump) {
    for ( my $i = 48; $i < 123; $i++ ) {
        my $glyph = TTF_RenderGlyph_Shaded( $font, $i, $forecol, $backcol );
        if ($glyph) {

            #char outname[64];
            my $outname = sprintf 'glyph-%d.bmp', $i;
            SDL_SaveBMP( $glyph, $outname );
        }
    }
    cleanup(0);
}

# Create a window
my ( $window, $renderer );
if ( SDL_CreateWindowAndRenderer( WIDTH, HEIGHT, 0, $window, $renderer ) < 0 ) {
    printf "SDL_CreateWindowAndRenderer() failed: %s\n", SDL_GetError();
    cleanup(2);
}

# Show which font file we're looking at
$string = 'Font file: ' . $ARGV[0];
my $text;
if ( $rendermethod == SDL2::FFI::TextRenderSolid() ) {
    $text = TTF_RenderText_Solid( $font, $string, $forecol );
}
elsif ( $rendermethod == SDL2::FFI::TextRenderShaded() ) {
    $text = TTF_RenderText_Shaded( $font, $string, $forecol, $backcol );
}
elsif ( $rendermethod == SDL2::FFI::TextRenderBlended() ) {
    $text = TTF_RenderText_Blended( $font, $string, $forecol );
}
my $scene = Scene->new();
if ( !defined $text ) {
    $scene->captionRect->x(4);
    $scene->captionRect->y(4);
    $scene->captionRect->w( $text->w );
    $scene->captionRect->h( $text->h );
    $scene->set_caption( SDL_CreateTextureFromSurface( $renderer, $text ) );
    SDL_FreeSurface($text);
}

# Render and center the message
if ( @ARGV > 2 ) {
    $message = $ARGV[2];
}
else {
    $message = DEFAULT_TEXT;
}
#
if ( $rendertype == SDL2::FFI::RENDER_LATIN1() ) {
    if ( $rendermethod == SDL2::FFI::TextRenderSolid() ) {
        $text = TTF_RenderText_Solid( $font, $message, $forecol );
    }
    elsif ( $rendermethod == SDL2::FFI::TextRenderShaded() ) {
        $text = TTF_RenderText_Shaded( $font, $message, $forecol, $backcol );
    }
    elsif ( $rendermethod == SDL2::FFI::TextRenderBlended() ) {
        $text = TTF_RenderText_Blended( $font, $message, $forecol );
    }
}
elsif ( $rendertype == SDL2::FFI::RENDER_UTF8() ) {
    if ( $rendermethod == SDL2::FFI::TextRenderSolid() ) {
        $text = TTF_RenderUTF8_Solid( $font, $message, $forecol );
    }
    elsif ( $rendermethod == SDL2::FFI::TextRenderShaded() ) {
        $text = TTF_RenderUTF8_Shaded( $font, $message, $forecol, $backcol );
    }
    elsif ( $rendermethod == SDL2::FFI::TextRenderBlended() ) {
        $text = TTF_RenderUTF8_Blended( $font, $message, $forecol );
    }
}
elsif ( $rendertype == SDL2::FFI::RENDER_UNICODE() ) {
    my $unicode_text = SDL_iconv_utf8_ucs2($message);
    if ( $rendermethod == SDL2::FFI::TextRenderSolid() ) {
        $text = TTF_RenderUNICODE_Solid( $font, $unicode_text, $forecol );
    }
    elsif ( $rendermethod == SDL2::FFI::TextRenderShaded() ) {
        $text = TTF_RenderUNICODE_Shaded( $font, $unicode_text, $forecol, $backcol );
    }
    elsif ( $rendermethod == SDL2::FFI::TextRenderBlended() ) {
        $text = TTF_RenderUTF8_Blended( $font, $unicode_text, $forecol );
    }
    SDL_free($unicode_text);
}
if ( !defined $text ) {
    printf "Couldn't render text: %s\n", SDL_GetError();
    TTF_CloseFont($font);
    cleanup(2);
}
$scene->messageRect->x( ( WIDTH() - $text->w ) / 2 );
$scene->messageRect->y( ( HEIGHT() - $text->h ) / 2 );
$scene->messageRect->w( $text->w );
$scene->messageRect->h( $text->h );
$scene->set_message( SDL_CreateTextureFromSurface( $renderer, $text ) );
printf( "Font is generally %d big, and string is %d big\n", TTF_FontHeight($font), $text->h );
#
draw_scene( $renderer, $scene );

# Wait for a keystroke, and blit text on mouse press
my $done = 0;
while ( !$done ) {
    if ( SDL_WaitEvent($event) < 0 ) {
        printf( "SDL_PullEvent() error: %s\n", SDL_GetError() );
        $done = 1;
        next;
    }
    if ( $event->type == SDL_MOUSEBUTTONDOWN() ) {
        $scene->messageRect->x( $event->button->x - $text->w / 2 );
        $scene->messageRect->y( $event->button->y - $text->h / 2 );
        $scene->messageRect->w( $text->w );
        $scene->messageRect->h( $text->h );
        draw_scene( $renderer, $scene );
    }
    elsif ( $event->type == SDL_KEYDOWN() || $event->type == SDL_QUIT() ) {
        $done = 1;
    }
}
SDL_FreeSurface($text);
TTF_CloseFont($font);
SDL_DestroyTexture( $scene->caption );
SDL_DestroyTexture( $scene->message );
cleanup(0);
__END__
{
#
# Pointers to our window, renderer, texture, and font
my ( $window, $texture, $renderer, $font );

#SDL_Window* window;
#SDL_Renderer* renderer;
#SDL_Texture *texture, *text;
#TTF_Font* font;
#string input;
my $input = '';
my $text;    # SDL2::Texture
my $fg = SDL2::Color->new( {r => 255, g => 0, b => 0, a=> 255 });
my $bg = SDL2::Color->new( {r => 0, g => 0, b => 255, a=> 100 });


END {
    SDL_StopTextInput();
    #
    TTF_CloseFont($font);
    SDL_DestroyTexture($texture);
    undef $texture;
    #
    SDL_DestroyRenderer($renderer);
    SDL_DestroyWindow($window);
    undef $window;
    undef $renderer;
    #
    TTF_Quit();
    IMG_Quit();
    SDL_Quit();
}
     my $e    = SDL2::Event->new;
    my $dest = SDL2::Rect->new;
	my $keys = SDL_GetKeyboardState();

sub loop() {


    # Clear the window to white
    #SDL_SetRenderDrawColor( $renderer, 255, 255, 255, 255 );
    SDL_RenderClear($renderer);

    # Event loop
    while ( SDL_PollEvent($e) != 0 ) {
        if ( $e->type == SDL_QUIT ) {
            return !1;
        }
        elsif ( $e->type == SDL_TEXTINPUT ) {
            $input .= $e->text->text;
        }
        elsif ( $e->type == SDL_KEYDOWN ) {
            if ( $e->key->keysym->sym == SDLK_BACKSPACE && length $input ) {
                chop $input;
            }
        }
    }

    # Render texture
    SDL_RenderCopy( $renderer, $texture, undef, undef );
    if ( length $input ) {
        my $text_surf = TTF_RenderText_Shaded( $font, $input, $fg, $bg );
		warn join '|',
		$fg->r,
		$fg->g,
		$fg->b,
		$fg->a;
        $text = SDL_CreateTextureFromSurface( $renderer, $text_surf );

        $dest->x( 320 - ( $text_surf->w / 2.0 ) );
		warn $dest->x;
        $dest->y(240);
        $dest->w( $text_surf->w );
        $dest->h( $text_surf->h );
        SDL_RenderCopy( $renderer, $text, undef, $dest );
        SDL_DestroyTexture($text);
        SDL_FreeSurface($text_surf);
    }

    # Update window
    SDL_RenderPresent($renderer);
    return 1;
}

sub init() {
    if ( SDL_Init(SDL_INIT_EVERYTHING) < 0 ) {
        die 'Error initializing SDL: ' . SDL_GetError();
    }
    if ( IMG_Init(IMG_INIT_PNG) < 0 ) {
        die 'Error initializing SDL_image: ' . IMG_GetError();
    }

    # Initialize SDL_ttf
    if ( TTF_Init() < 0 ) {
        die 'Error intializing SDL_ttf: ' . TTF_GetError();
    }
    $window
        = SDL_CreateWindow( "Example", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480,
        SDL_WINDOW_SHOWN );
    if ( !$window ) {
        die 'Error creating window: ' . SDL_GetError();
    }
    $renderer = SDL_CreateRenderer( $window, -1, SDL_RENDERER_ACCELERATED );
    if ( !$renderer ) {
        die 'Error creating renderer: ' . SDL_GetError();
    }
    my $buffer = IMG_Load("sample.png");
    if ( !$buffer ) {
        die 'Error loading image sample.png: ' . SDL_GetError();
    }
    $texture = SDL_CreateTextureFromSurface( $renderer, $buffer );
    SDL_FreeSurface($buffer);
    undef $buffer;
    if ( !$texture ) {
        die 'Error creating texture: ' . SDL_GetError();
    }

    # Load font
    $font = TTF_OpenFont( "KohSantepheap-Regular.ttf", 72 );
    if ( !$font ) {
        die 'Error loading font: ' . TTF_GetError();
    }


    # Start sending SDL_TextInput events
    SDL_StartTextInput();
    return 1;
}
die SDL_GetError() if !init();
while ( loop() ) {

    # wait before processing the next frame
    SDL_Delay(10);
}

}
