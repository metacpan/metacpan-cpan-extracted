use v5.36;
use Carp  qw[croak];
use Affix qw[Int UInt32];
use SDL3  qw[:all];
use Data::Dump;
$|++;

# The 'Hello, World' of graphics programs. Draws a colorful, spinning triangle to the screen.
#
# We just describe the vertices in a list of hashes and Affix handles packing them
# into an array of C structs for the GPU.
#
# No controls. You just watch it a few seconds and close the window.
#
# Config
my $SCREEN_W = 800;
my $SCREEN_H = 600;

# Init SDL
SDL_Init(SDL_INIT_VIDEO) || die 'Init Error: ' . SDL_GetError();
my $win       = SDL_CreateWindow( 'Affix + SDL3 = ▲', $SCREEN_W, $SCREEN_H, 0 );
my $ren       = SDL_CreateRenderer( $win, undef );
my $event_ptr = Affix::malloc(128);

# Main loop
my $running = 1;
while ($running) {

    # Events
    while ( SDL_PollEvent($event_ptr) ) {
        my $h = Affix::cast( $event_ptr, SDL_CommonEvent );
        if    ( $h->{type} == SDL_EVENT_QUIT ) { $running = 0 }
        elsif ( $h->{type} == SDL_EVENT_KEY_DOWN ) {
            my $k = Affix::cast( $event_ptr, SDL_KeyboardEvent );
            if ( $k->{scancode} == SDL_SCANCODE_ESCAPE ) { $running = 0 }
        }
    }

    # Update Animation
    my $time = SDL_GetTicks() / 1000.0;

    # Calculate Center
    my $cx     = $SCREEN_W / 2;
    my $cy     = $SCREEN_H / 2;
    my $radius = 250;

    # Calculate 3 vertices of an equilateral triangle
    # We add $time to the angle to make it spin
    my @points;
    for my $i ( 0 .. 2 ) {

        # 0, 120, 240 degrees offset
        my $angle = $time + ( $i * ( 2 * 3.14159 ) / 3 );
        push @points, { x => $cx + cos($angle) * $radius, y => $cy + sin($angle) * $radius };
    }

    # Build Vertex List
    # SDL_Vertex = { position, color, tex_coord }
    # Colors are Floats (0.0 to 1.0)
    # Affix automatically packs these nested hashes into C structs
    my $vertices = [
        {   position  => $points[0],
            color     => { r => 1.0, g => 0.0, b => 0.0, a => 1.0 },    # Red
            tex_coord => { x => 0.0, y => 0.0 }
        },
        {   position  => $points[1],
            color     => { r => 0.0, g => 1.0, b => 0.0, a => 1.0 },    # Green
            tex_coord => { x => 0.0, y => 0.0 }
        },
        {   position  => $points[2],
            color     => { r => 0.0, g => 0.0, b => 1.0, a => 1.0 },    # Blue
            tex_coord => { x => 0.0, y => 0.0 }
        }
    ];

    # Render
    SDL_SetRenderDrawColor( $ren, 20, 20, 20, 255 );    # Dark grey background
    SDL_RenderClear($ren);

    # The Magic Function: Draws arbitrary triangles with interpolated colors
    SDL_RenderGeometry( $ren, undef, $vertices, 3, undef, 0 );
    SDL_RenderPresent($ren);

    # Simple frame limiter
    SDL_Delay(16);
}
SDL_DestroyRenderer($ren);
SDL_DestroyWindow($win);
SDL_Quit();
