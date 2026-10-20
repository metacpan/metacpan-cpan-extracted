use v5.40;
use SDL3        qw[:all :main];
use SDL3::Image qw[:all];

# Port of SDL_image's examples/showimage.
#
# Displays a list of image files. Press LEFT/RIGHT to move between images,
# SPACE/TAB to skip to the next one, and ESC/Q to quit. A checkerboard is
# drawn behind the image so transparency is visible. Any EXIF orientation
# baked into the file is honored: IMG_Load records it in the surface's
# "SDL.surface.rotation" / "SDL.surface.flip" properties, which we read back
# and hand to SDL_RenderTextureRotated.
#
# The images we ship in eg/image/assets.
my @IMAGES = qw[
    sample.png  sample.jpg
    rgbrgb.png  rgbrgb.gif
    sample.webp sample.bmp
    sample.qoi  sample.avif];
my ( $window, $renderer, $texture );
my $index    = 0;
my $rotation = 0.0;
my $flip     = SDL_FLIP_NONE();

# Locate a bundled asset next to this script.
sub asset ($name) {
    my $dir = __FILE__ =~ s{[^/\\]+$}{}r;
    return $dir . 'assets/' . $name;
}

# Draw a Gimpish checkerboard so transparency is visible.
sub draw_background ($renderer) {
    my @col = ( [ 0x66, 0x66, 0x66, 0xFF ], [ 0x99, 0x99, 0x99, 0xFF ] );
    my $dx  = 8;
    my $dy  = 8;
    my ( $w, $h ) = ( 0, 0 );
    SDL_GetCurrentRenderOutputSize( $renderer, \$w, \$h );
    for ( my $y = 0; $y < $h; $y += $dy ) {
        for ( my $x = 0; $x < $w; $x += $dx ) {
            my $i = ( ( $x ^ $y ) >> 3 ) & 1;
            SDL_SetRenderDrawColor( $renderer, @{ $col[$i] } );
            SDL_RenderFillRect( $renderer, { x => $x, y => $y, w => $dx, h => $dy } );
        }
    }
}

# Load an image into a texture, picking up any EXIF rotation/flip.
sub load_image ( $renderer, $file ) {
    my $surface = IMG_Load( asset($file) );
    if ( !$surface ) {
        SDL_Log( q[Couldn't load %s: %s], $file, SDL_GetError() );
        return undef;
    }
    my $props = SDL_GetSurfaceProperties($surface);

    # These surface properties aren't always bound as constants; use the
    # documented string names. Flip defaults to SDL_FLIP_NONE, rotation to 0.
    $flip     = SDL_GetNumberProperty( $props, 'SDL.surface.flip', SDL_FLIP_NONE() );
    $rotation = SDL_GetFloatProperty( $props, 'SDL.surface.rotation', 0.0 );
    my $texture = SDL_CreateTextureFromSurface( $renderer, $surface );
    SDL_DestroySurface($surface);
    return $texture;
}

# Load a specific image and resize the window to fit it.
sub show_image ($i) {
    SDL_DestroyTexture($texture) if $texture;
    $texture = load_image( $renderer, $IMAGES[$i] );
    return 0 unless $texture;
    my ( $tw, $th ) = ( 0, 0 );
    SDL_GetTextureSize( $texture, \$tw, \$th );
    SDL_SetWindowTitle( $window, $IMAGES[$i] );
    if ( $rotation == 90.0 || $rotation == 270.0 ) {
        SDL_SetWindowSize( $window, $th, $tw );
    }
    else {
        SDL_SetWindowSize( $window, $tw, $th );
    }
    return 1;
}

# This function runs once at startup.
sub SDL_AppInit ( $appstate, $argc, $argv ) {
    SDL_SetAppMetadata( 'Example Show Image', '1.0', 'com.example.show-image' );
    if ( !SDL_CreateWindowAndRenderer( 'showimage', 640, 480, SDL_WINDOW_RESIZABLE, $window, $renderer ) ) {
        SDL_Log( q[SDL_CreateWindowAndRenderer() failed: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    return show_image($index) ? SDL_APP_CONTINUE : SDL_APP_FAILURE;
}

# This function runs when a new event (mouse input, keypresses, etc) occurs.
sub SDL_AppEvent ( $appstate, $event ) {
    my $type = $event->{type};
    return SDL_APP_SUCCESS if $type == SDL_EVENT_QUIT;
    if ( $type == SDL_EVENT_KEY_DOWN ) {
        my $key = $event->{key}{key};
        return SDL_APP_SUCCESS if $key == SDLK_ESCAPE || $key == SDLK_Q;
        if ( $key == SDLK_LEFT ) {
            $index = ( $index - 1 ) % @IMAGES;
            $index += @IMAGES if $index < 0;
            show_image($index);
        }
        elsif ( $key == SDLK_RIGHT || $key == SDLK_SPACE || $key == SDLK_TAB ) {
            $index = ( $index + 1 ) % @IMAGES;
            show_image($index);
        }
    }
    return SDL_APP_CONTINUE;
}

# This function runs once per frame, and is the heart of the program.
sub SDL_AppIterate ($appstate) {
    my ( $tw, $th ) = ( 0, 0 );
    SDL_GetTextureSize( $texture, \$tw, \$th );
    my %dst;
    if ( $rotation == 90.0 || $rotation == 270.0 ) {

        # Use a pre-rotated destination rectangle.
        $dst{x} = ( $th - $tw ) / 2.0;
        $dst{y} = ( $tw - $th ) / 2.0;
        $dst{w} = $tw;
        $dst{h} = $th;
    }
    else {
        $dst{x} = 0.0;
        $dst{y} = 0.0;
        $dst{w} = $tw;
        $dst{h} = $th;
    }
    draw_background($renderer);
    SDL_RenderTextureRotated( $renderer, $texture, undef, \%dst, $rotation, undef, $flip );
    SDL_RenderPresent($renderer);
    return SDL_APP_CONTINUE;
}

# This function runs once at shutdown.
sub SDL_AppQuit ( $appstate, $result ) {
    SDL_DestroyTexture($texture) if $texture;
}
