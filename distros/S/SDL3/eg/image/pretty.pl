use lib '../../lib';
use v5.40;
use SDL3        qw[:all :main];
use SDL3::Image qw[:all];
my ( $window, $renderer, $texture );

# Generate an uncompressed 24-bit BMP in memory
sub make_procedural_bmp ( $w = 64, $h = 64 ) {

    # BMP rows must be padded to 4-byte boundaries
    my $row_bytes = ( $w * 3 + 3 ) & ~3;
    my $pad       = $row_bytes - ( $w * 3 );
    my $img_size  = $row_bytes * $h;
    my $file_size = 54 + $img_size;

    # 14-byte File Header + 40-byte DIB Header (BITMAPINFOHEADER)
    my $header = pack(
        'a2 V v v V V V V v v V V V V V V', 'BM',    # Magic number
        $file_size,                                  # Total file size
        0, 0,                                        # Reserved
        54,                                          # Pixel data offset
        40,                                          # Header size
        $w, $h,                                      # Width, Height (positive = bottom-to-top)
        1,                                           # Color planes
        24,                                          # Bits per pixel
        0,                                           # Compression (0 = BI_RGB, uncompressed)
        $img_size,                                   # Size of raw pixel data
        2835, 2835,                                  # Resolution (~72 DPI)
        0,    0                                      # Color palette entries
    );

    # Randomize personality parameters for this generation
    my ( $phase_r, $phase_g, $phase_b ) = map { rand(6.283) } 1 .. 3;
    my $freq_ring    = 2.5 + rand(4.5);
    my $freq_plasma  = 4.0 + rand(8.0);
    my $lobes        = int( 2 + rand(6) );           # 2 to 7 energy tentacles/ripples
    my $lobe_depth   = 1.0 + rand(3.5);
    my $radius       = $w * ( 0.36 + rand(0.08) );
    my $falloff_rate = 1.6 + rand(1.4);

    # Randomize specular center (gives the sphere a lit 3D angle)
    my $core_ox = ( rand() - 0.5 ) * ( $w * 0.3 );
    my $core_oy = ( rand() - 0.5 ) * ( $h * 0.3 );
    my $pixels  = '';
    for my $y ( 0 .. $h - 1 ) {
        for my $x ( 0 .. $w - 1 ) {
            my $cx = $x - $w / 2;
            my $cy = $y - $h / 2;
            my $d  = sqrt( $cx * $cx + $cy * $cy );
            my $a  = atan2( $cy, $cx );

            # Angular harmonic wobble
            my $wobble = $lobe_depth * sin( $a * $lobes + $phase_r );
            my $eff_d  = $d + $wobble;

            # Core specular distance
            my $core_d = sqrt( ( $cx - $core_ox )**2 + ( $cy - $core_oy )**2 );

            # Multichannel trigonometric plasma
            my $r = int( 128 + 127 * sin( $eff_d / $freq_ring + $phase_r ) );
            my $g = int( 128 + 127 * cos( $core_d / $freq_plasma + $phase_g ) );
            my $b = int( 128 + 127 * sin( ( $x + $y ) / 8.0 + $phase_b ) );

            # Subtle star-dust film grain
            my $grain = int( ( rand() - 0.5 ) * 24 );
            $r += $grain;
            $g += $grain;
            $b += $grain;

            # Corona/atmosphere falloff outside the radius
            if ( $eff_d > $radius ) {
                my $fade = exp( -( $eff_d - $radius ) / $falloff_rate );
                $r = int( $r * $fade );
                $g = int( $g * $fade );
                $b = int( $b * $fade );
            }

            # Clamp to [0, 255]
            $r = $r < 0 ? 0 : ( $r > 255 ? 255 : $r );
            $g = $g < 0 ? 0 : ( $g > 255 ? 255 : $g );
            $b = $b < 0 ? 0 : ( $b > 255 ? 255 : $b );

            # BMP stores as BGR
            $pixels .= pack( 'C3', $b, $g, $r );
        }
        $pixels .= "\0" x $pad;
    }
    return $header . $pixels;
}

# Helper to generate a new image and recreate the GPU texture
sub reload_orb () {
    SDL_DestroyTexture($texture) if $texture;
    my $bmp    = make_procedural_bmp( 128, 128 );
    my $stream = SDL_IOFromConstMem( \$bmp, length($bmp) );
    $texture = IMG_LoadTexture_IO( $renderer, $stream, 1 );
    return $texture ? 1 : 0;
}

sub SDL_AppInit ( $appstate, $argc, $argv ) {
    if ( !SDL_CreateWindowAndRenderer( 'Procedural Random Orb (Press SPACE to reroll)', 640, 640, 0, $window, $renderer ) ) {
        SDL_Log( "Couldn't create window and renderer: %s\n", SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    return reload_orb() ? SDL_APP_CONTINUE : SDL_APP_FAILURE;
}

sub SDL_AppEvent ( $appstate, $event ) {
    return SDL_APP_SUCCESS if $event->{type} == SDL_EVENT_QUIT;
    if ( $event->{type} == SDL_EVENT_KEY_DOWN ) {
        my $key = $event->{key}{key};
        if ( $key == SDLK_SPACE() ) {    # Press SPACE to re-roll a new random orb!
            reload_orb();
        }
        elsif ( $key == SDLK_ESCAPE() ) {    # Press ESC to exit
            return SDL_APP_SUCCESS;
        }
    }
    return SDL_APP_CONTINUE;
}

sub SDL_AppIterate ($appstate) {
    my ( $w,  $h )  = ( 0, 0 );
    my ( $tw, $th ) = ( 0, 0 );
    my $scale = 5.0;
    SDL_GetRenderOutputSize( $renderer, \$w, \$h );
    SDL_SetRenderScale( $renderer, $scale, $scale );
    SDL_GetTextureSize( $texture, \$tw, \$th );
    my $dst = { w => $tw, h => $th, x => ( ( $w / $scale ) - $tw ) / 2, y => ( ( $h / $scale ) - $th ) / 2 };
    SDL_SetRenderDrawColor( $renderer, 15, 15, 20, 255 );
    SDL_RenderClear($renderer);
    SDL_RenderTexture( $renderer, $texture, undef, $dst );
    SDL_RenderPresent($renderer);
    return SDL_APP_CONTINUE;
}

sub SDL_AppQuit ( $appstate, $result ) {
    SDL_DestroyTexture($texture) if $texture;
}
