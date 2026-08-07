use v5.38;
use Carp  qw[croak];
use Affix qw[:all];
use SDL3  qw[:all];
#
# The Matrix. You know, kinda like the movie from like 30 years ago.
#
# This is essentially a Tilemap Renderer.
#
# I include a procedural generator for the font texture so we don't need an external file. It draws
# a simple 8x8 grid of exotic looking glyphs. You can swap the procedural texture for a real font
# file (like vga8x8.bmp) or a spritesheet of terrain tiles to build a dungeon crawler.
#
# Config
my $FONT_W   = 8;
my $FONT_H   = 8;
my $COLS     = 100;
my $ROWS     = 60;
my $SCALE    = 1;                          # Size of text
my $SCREEN_W = $COLS * $FONT_W * $SCALE;
my $SCREEN_H = $ROWS * $FONT_H * $SCALE;

# Init
die SDL_GetError() if SDL_Init(SDL_INIT_VIDEO) == 0;
my $win       = SDL_CreateWindow( 'Just Another Perl Matrix,', $SCREEN_W, $SCREEN_H, 0 );
my $ren       = SDL_CreateRenderer( $win, undef );
my $event_ptr = Affix::malloc(128);
SDL_SetRenderDrawBlendMode( $ren, SDL_BLENDMODE_BLEND );

# Generate font texture. We create a 128x64 texture holding 128 chars (16 cols x 8 rows of 8x8 glyphs)
my $atlas_w = 128;
my $atlas_h = 64;
my $tex     = SDL_CreateTexture( $ren, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, $atlas_w, $atlas_h );
SDL_SetTextureScaleMode( $tex, SDL_SCALEMODE_NEAREST );    # Crisp pixels
SDL_SetTextureBlendMode( $tex, SDL_BLENDMODE_ADD );        # Glowing effect
my @pixels;
for my $y ( 0 .. $atlas_h - 1 ) {
    for my $x ( 0 .. $atlas_w - 1 ) {

        # Determine which char this is
        my $char_x  = int( $x / 8 );
        my $char_y  = int( $y / 8 );
        my $local_x = $x % 8;
        my $local_y = $y % 8;

        # Procedural glyphs make exotic looking text without loading a font file
        my $seed = ( $char_x + ( $char_y * 16 ) ) * 12345;
        my $hash = ( ( $local_x ^ $local_y ) + $seed ) % 9;
        my $on   = 0;
        if ( $hash > 6 )                      { $on = 1; }
        if ( $local_x == 0 || $local_x == 7 ) { $on = 0; }    # Spacing
        push @pixels, $on ? 0xFFFFFFFF : 0x00000000;
    }
}
my $raw = pack( 'L*', @pixels );
SDL_UpdateTexture( $tex, undef, $raw, $atlas_w * 4 );

# Rain Simulation
my @drops;

# One drop per column
for my $x ( 0 .. $COLS - 1 ) {
    push @drops, {
        x           => $x,
        y           => rand($ROWS) * -1,      # Start off screen
        speed       => 0.2 + rand(0.5),
        len         => 5 + int( rand(15) ),
        char_offset => int( rand(128) )
    };
}
#
# Persistent, directly-writable FRects (one per column avoids garbage marshalling)
my $src_rect = Affix::calloc( 1, sizeof SDL_FRect() );
my $dst_rect = Affix::calloc( 1, sizeof SDL_FRect() );

# Views for fast direct writes into the C structs
my $src_x = Affix::cast( Affix::address($src_rect) + 0,  Pointer [Float] );
my $src_y = Affix::cast( Affix::address($src_rect) + 4,  Pointer [Float] );
my $src_w = Affix::cast( Affix::address($src_rect) + 8,  Pointer [Float] );
my $src_h = Affix::cast( Affix::address($src_rect) + 12, Pointer [Float] );
my $dst_x = Affix::cast( Affix::address($dst_rect) + 0,  Pointer [Float] );
my $dst_y = Affix::cast( Affix::address($dst_rect) + 4,  Pointer [Float] );
my $dst_w = Affix::cast( Affix::address($dst_rect) + 8,  Pointer [Float] );
my $dst_h = Affix::cast( Affix::address($dst_rect) + 12, Pointer [Float] );

# Constant sizes
$$src_w = 8;
$$src_h = 8;
$$dst_w = $FONT_W * $SCALE;
$$dst_h = $FONT_H * $SCALE;
my $running = 1;
my $frame   = 0;
while ($running) {
    while ( SDL_PollEvent($event_ptr) ) {
        if ( Affix::cast( $event_ptr, SDL_CommonEvent )->{type} == SDL_EVENT_QUIT ) { $running = 0; }
    }
    SDL_SetRenderDrawColor( $ren, 0, 0, 0, 255 );
    SDL_RenderClear($ren);
    $frame++;
    #
    for my $d (@drops) {

        # Move
        $d->{y} += $d->{speed};
        if ( $d->{y} - $d->{len} > $ROWS ) {
            $d->{y}     = rand(10) * -1;     # Reset to top
            $d->{speed} = 0.2 + rand(0.5);
        }

        # Draw trail
        my $head_y = int( $d->{y} );
        for my $i ( 0 .. $d->{len} ) {
            my $y_pos = $head_y - $i;
            next if $y_pos < 0 || $y_pos >= $ROWS;

            # Color logic
            my $alpha = 255;
            my $r     = 0;
            my $g     = 255;
            my $b     = 0;
            if ( $i == 0 ) {

                # Head is bright white
                $r = 200;
                $g = 255;
                $b = 200;
            }
            elsif ( $i > $d->{len} - 4 ) {

                # Tail fades out
                $alpha = 255 * ( 1 - ( $i / $d->{len} ) );
            }

            # Flicker chars
            # Change char every few frames based on position
            my $char_idx = ( $d->{char_offset} + $y_pos + int( $frame / 5 ) ) % 128;

            # Source Rect
            my $cx = ( $char_idx % 16 ) * 8;
            my $cy = int( $char_idx / 16 ) * 8;
            $$src_x = $cx;
            $$src_y = $cy;

            # Dest rect (full screen)
            $$dst_x = $d->{x} * $FONT_W * $SCALE;
            $$dst_y = $y_pos * $FONT_H * $SCALE;
            SDL_SetTextureColorMod( $tex, $r, $g, $b );
            SDL_SetTextureAlphaMod( $tex, int($alpha) );
            SDL_RenderTexture( $ren, $tex, $src_rect, $dst_rect );
        }
    }
    SDL_RenderPresent($ren);
    SDL_Delay(16);
}
SDL_Quit();
