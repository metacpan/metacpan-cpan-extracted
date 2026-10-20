use v5.40;
use SDL3      qw[:all :main];
use SDL3::TTF qw[:all];

# Port of SDL_ttf's examples/showfont (the font-effect half; the upstream
# demo's edit box is omitted here).
#
# Renders a sample string through every font setting that showfont supports,
# and lets you change them while it runs. The styled message is rendered with
# TTF_RenderText_Blended() into a surface, uploaded to a texture, and drawn
# centered -- exactly the way the upstream demo does it -- so you can see bold,
# italic, underline, strikethrough, outline, hinting, kerning, alignment,
# wrapping and size all take effect on real text.
#
#   B  bold            I  italic          U  underline      S  strikethrough
#   O  outline         H  cycle hinting   K  toggle kerning
#   A  cycle alignment (+ SHIFT to go back)
#   W  toggle wrapping +/-  change point size
#   ESC/Q  quit
my ( $window, $renderer, $font, $engine, $texture, $caption );
my $ptsize     = 48.0;
my $align      = 0;                                                                                        # index into @ALIGNMENTS
my $hinting    = 0;                                                                                        # index into @HINTING
my $wrapped    = 1;
my $outline    = 0;
my $MESSAGE    = 'The quick brown fox jumped over the lazy dog';
my @ALIGNMENTS = ( TTF_HORIZONTAL_ALIGN_LEFT, TTF_HORIZONTAL_ALIGN_CENTER, TTF_HORIZONTAL_ALIGN_RIGHT );
my @ALIGN_NAME = qw[left center right];
my @HINTING    = ( TTF_HINTING_NORMAL, TTF_HINTING_LIGHT, TTF_HINTING_MONO, TTF_HINTING_NONE );
my @HINT_NAME  = qw[normal light mono none];

# Pick a font that exists on this platform.
sub system_font {
    my @candidates = (
        $^O eq 'MSWin32' ? 'C:/Windows/Fonts/arial.ttf' : (), $^O eq 'darwin' ? '/System/Library/Fonts/Helvetica.ttc' : (),
        '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',    '/usr/share/fonts/TTF/DejaVuSans.ttf',
    );
    for my $path (@candidates) {
        return $path if -e $path;
    }
    return $candidates[-1];
}

# Apply the current settings to the live font object.
sub apply_settings () {
    TTF_SetFontSize( $font, $ptsize );
    TTF_SetFontOutline( $font, $outline );
    TTF_SetFontHinting( $font, $HINTING[$hinting] );
    TTF_SetFontWrapAlignment( $font, $ALIGNMENTS[$align] );
}

# Re-render the styled message into a texture. Called at startup and whenever a
# setting changes, mirroring showfont's render-and-center step.
sub render_message () {
    my $white = { r => 0xFF, g => 0xFF, b => 0xFF, a => 0xFF };

    # Outline needs a contrasting color or it is invisible on the background.
    $white = { r => 0xFF, g => 0xD0, b => 0x00, a => 0xFF } if $outline;
    my $surface = $wrapped ? TTF_RenderText_Blended_Wrapped( $font, $MESSAGE, 0, $white, 640 ) : TTF_RenderText_Blended( $font, $MESSAGE, 0, $white );
    if ( !$surface ) {
        SDL_Log( q[Couldn't render text: %s], SDL_GetError() );
        return;
    }
    SDL_DestroyTexture($texture) if $texture;
    $texture = SDL_CreateTextureFromSurface( $renderer, $surface );
    SDL_DestroySurface($surface);
}

# This function runs once at startup.
sub SDL_AppInit ( $appstate, $argc, $argv ) {
    my $font_path = system_font();
    if ( !SDL_CreateWindowAndRenderer( 'font styles', 800, 600, SDL_WINDOW_RESIZABLE, $window, $renderer ) ) {
        SDL_Log( q[Couldn't create window and renderer: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !TTF_Init() ) {
        SDL_Log( q[Couldn't initialize SDL_ttf: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    $font = TTF_OpenFont( $font_path, $ptsize );
    if ( !$font ) {
        SDL_Log( q[Couldn't open font %s: %s], $font_path, SDL_GetError() );
        return SDL_APP_FAILURE;
    }

    # A caption at the top, like showfont's "Font file: ..." line.
    $engine = TTF_CreateRendererTextEngine($renderer);

    #~ $caption = TTF_CreateText( $engine, $font, sprintf( 'Font file: %s', $font_path ), 0 );
    #~ TTF_SetTextColor( $caption, 0xD0, 0xD0, 0xD0, SDL_ALPHA_OPAQUE );
    apply_settings();
    render_message();
    return SDL_APP_CONTINUE;
}

# This function runs when a new event (mouse input, keypresses, etc) occurs.
sub SDL_AppEvent ( $appstate, $event ) {
    my $type = $event->{type};
    return SDL_APP_SUCCESS  if $type == SDL_EVENT_QUIT;
    return SDL_APP_CONTINUE if $type != SDL_EVENT_KEY_DOWN;
    my $key   = $event->{key}{key};
    my $style = TTF_GetFontStyle($font);
    return SDL_APP_SUCCESS if $key == SDLK_ESCAPE || $key == SDLK_Q;
    if ( $key == SDLK_B ) {
        TTF_SetFontStyle( $font, $style ^ TTF_STYLE_BOLD );
        render_message();
    }
    elsif ( $key == SDLK_I ) {
        TTF_SetFontStyle( $font, $style ^ TTF_STYLE_ITALIC );
        render_message();
    }
    elsif ( $key == SDLK_U ) {
        TTF_SetFontStyle( $font, $style ^ TTF_STYLE_UNDERLINE );
        render_message();
    }
    elsif ( $key == SDLK_S ) {
        TTF_SetFontStyle( $font, $style ^ TTF_STYLE_STRIKETHROUGH );
        render_message();
    }
    elsif ( $key == SDLK_O ) {
        $outline = $outline ? 0 : 1;
        apply_settings();
        render_message();
    }
    elsif ( $key == SDLK_H ) {
        $hinting = ( $hinting + 1 ) % @HINTING;
        apply_settings();
        render_message();
    }
    elsif ( $key == SDLK_K ) {
        TTF_SetFontKerning( $font, TTF_GetFontKerning($font) ? 0 : 1 );
        render_message();
    }
    elsif ( $key == SDLK_W ) {
        $wrapped = !$wrapped;
        apply_settings();
        render_message();
    }
    elsif ( $key == SDLK_A ) {
        my $step = ( $event->{key}{mod} & SDL_KMOD_SHIFT ) ? -1 : 1;
        $align = ( $align + $step ) % @ALIGNMENTS;
        apply_settings();
        render_message();
    }
    elsif ( $key == SDLK_PLUS || $key == SDLK_EQUALS ) {
        $ptsize += 4;
        apply_settings();
        render_message();
    }
    elsif ( $key == SDLK_MINUS ) {
        $ptsize = $ptsize > 8 ? $ptsize - 4 : 8;
        apply_settings();
        render_message();
    }
    return SDL_APP_CONTINUE;
}

# This function runs once per frame, and is the heart of the program.
sub SDL_AppIterate ($appstate) {
    SDL_SetRenderDrawColor( $renderer, 20, 20, 28, 255 );
    SDL_RenderClear($renderer);

    # The caption, rendered through the text engine.
    TTF_DrawRendererText( $caption, 8, 8 );

    # The styled message, centered.
    if ($texture) {
        my ( $w,  $h )  = ( 0, 0 );
        my ( $tw, $th ) = ( 0, 0 );
        SDL_GetRenderOutputSize( $renderer, \$w, \$h );
        SDL_GetTextureSize( $texture, \$tw, \$th );
        my %dst = ( x => ( $w - $tw ) / 2.0, y => ( $h - $th ) / 2.0, w => $tw, h => $th );
        SDL_RenderTexture( $renderer, $texture, undef, \%dst );
    }

    # A status line describing the current settings.
    SDL_SetRenderDrawColor( $renderer, 180, 200, 220, 255 );
    SDL_RenderDebugText( $renderer, 8, 40, sprintf 'size %.0f  hinting %s  align %s  wrapping %s  outline %d',
        $ptsize, $HINT_NAME[$hinting], $ALIGN_NAME[$align], ( $wrapped ? 'on' : 'off' ), $outline );
    SDL_RenderDebugText( $renderer, 8, 58, 'B bold  I italic  U underline  S strike  O outline  H hint  K kerning  A align  W wrap  +/- size' );
    SDL_RenderPresent($renderer);
    return SDL_APP_CONTINUE;
}

# This function runs once at shutdown.
sub SDL_AppQuit ( $appstate, $result ) {
    SDL_DestroyTexture($texture)           if $texture;
    TTF_DestroyText($caption)              if $caption;
    TTF_DestroyRendererTextEngine($engine) if $engine;
    TTF_CloseFont($font)                   if $font;
    TTF_Quit();
}
