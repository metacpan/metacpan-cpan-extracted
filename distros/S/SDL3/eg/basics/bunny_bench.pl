use v5.40;
use Carp  qw[croak];
use Affix qw[:all];
use SDL3  qw[:all];
$|++;
#
# This is really a benchmark of Affix's hot path disguised as an SDL demo.
# I get 90 FPS average with 10k bunnies and 48 FPS with 20k on my Windows box.
#
# Controls:
#  - Click/hold the left mouse button to add more bunnies
#  - Hit 'R' on the keyboard to reset the number of bunnies to 100
#
# Config
my $START_BUNNIES = 100;
my $GRAVITY       = 0.5;
my $MAX_X         = 800;
my $MAX_Y         = 600;

# Init
SDL_Init(SDL_INIT_VIDEO) || die SDL_GetError();
#
my $win       = SDL_CreateWindow( 'Affix Bunny Benchmark', $MAX_X, $MAX_Y, 0 );
my $ren       = SDL_CreateRenderer( $win, undef );
my $event_ptr = Affix::malloc(128);

# Create Bunny texture... a 32x32 white circle with ears is good enough
my $tex_w = 32;
my $tex_h = 32;
my $tex   = SDL_CreateTexture( $ren, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, $tex_w, $tex_h );
SDL_SetTextureBlendMode( $tex, SDL_BLENDMODE_BLEND );

# Draw a cute bunny into the texture memory
my @pixels;
for my $y ( 0 .. 31 ) {
    for my $x ( 0 .. 31 ) {

        # Simple distance field for head
        my $dx = $x - 16;
        my $dy = $y - 20;
        my $d  = sqrt( $dx * $dx + $dy * $dy );

        # Ears
        my $ear_l = ( $x - 10 )**2 / 6 + ( $y - 10 )**2 / 30;                                   # Ellipse math
        my $ear_r = ( $x - 22 )**2 / 6 + ( $y - 10 )**2 / 30;
        push @pixels, ( $d < 10 || $ear_l < 1.5 || $ear_r < 1.5 ) ? 0xFFFFFFFF : 0x00000000;    # white or transparent
    }
}
my $raw_bytes = pack( 'L*', @pixels );
SDL_UpdateTexture( $tex, undef, $raw_bytes, $tex_w * 4 );

# Logic
my @bunnies;

sub add_bunnies ($count) {
    for ( 1 .. $count ) {
        push @bunnies, {
            x  => rand($MAX_X),
            y  => rand( $MAX_Y / 2 ),
            vx => rand(8) - 4,
            vy => rand(8) - 4,

            # Random color
            r => rand(255),
            g => rand(255),
            b => rand(255)
        };
    }
    say 'Bunnies: ' . scalar(@bunnies);
}
add_bunnies($START_BUNNIES);

# Optimization: Persistent memory
# Instead of creating a new HV* and then marshalling it to a C struct every draw call,
# we allocate a single memory aligned struct and write to it a bunch of times.
my $dest_rect_raw  = Affix::calloc( 1, sizeof SDL_FRect() );
my $dest_rect_addr = Affix::address($dest_rect_raw);

# Create Views for fast writing
my $p_x = Affix::cast( $dest_rect_addr + 0,  Pointer [Float] );
my $p_y = Affix::cast( $dest_rect_addr + 4,  Pointer [Float] );
my $p_w = Affix::cast( $dest_rect_addr + 8,  Pointer [Float] );
my $p_h = Affix::cast( $dest_rect_addr + 12, Pointer [Float] );

# Set constant size
$$p_w = 32.0;
$$p_h = 32.0;

# Create the pin to pass to SDL
my $dest_rect_pin = Affix::cast( $dest_rect_addr, Pointer [SDL_FRect] );

# Main loop
my $running   = 1;
my $frames    = 0;
my $last_time = SDL_GetTicks();
my $fps_text  = 'FPS: 0';

# Input State
my $ptr_mx = Affix::malloc(4);
my $ptr_my = Affix::malloc(4);
my $pin_mx = Affix::cast( $ptr_mx, Float );
my $pin_my = Affix::cast( $ptr_my, Float );
while ($running) {
    while ( SDL_PollEvent($event_ptr) ) {
        my $h = Affix::cast( $event_ptr, SDL_CommonEvent );
        if    ( $h->{type} == SDL_EVENT_QUIT ) { $running = 0; }
        elsif ( $h->{type} == SDL_EVENT_KEY_DOWN ) {               # Reset
            if ( Affix::cast( $event_ptr, SDL_KeyboardEvent )->{scancode} == SDL_SCANCODE_R ) { @bunnies = (); add_bunnies($START_BUNNIES); }
        }
    }

    # Click to add bunnies (should be in above event poll)
    my $mask = SDL_GetMouseState( $ptr_mx, $ptr_my );
    add_bunnies(100) if $mask & SDL_BUTTON_LMASK;

    # Render
    SDL_SetRenderDrawColor( $ren, 50, 50, 50, 255 );
    SDL_RenderClear($ren);
    for my $b (@bunnies) {

        # Physics (simple gravity)
        $b->{x}  += $b->{vx};
        $b->{y}  += $b->{vy};
        $b->{vy} += $GRAVITY;

        # Wall Bounce
        if ( $b->{x} > $MAX_X - 32 ) { $b->{vx} *= -1; $b->{x} = $MAX_X - 32; }
        if ( $b->{x} < 0 )           { $b->{vx} *= -1; $b->{x} = 0; }
        if ( $b->{y} > $MAX_Y - 32 ) {
            $b->{vy} *= -0.85;    # Bounce with damping
            $b->{y} = $MAX_Y - 32;

            # Randomize x vel slightly on bounce
            if ( rand() > 0.5 ) { $b->{vx} = rand(6) - 3; }
        }
        if ( $b->{y} < 0 ) { $b->{vy} = 0; $b->{y} = 0; }

        # Draw
        # First, set color mod (tint). This is faster with SDL than trying to implement it in pure perl
        SDL_SetTextureColorMod( $tex, $b->{r}, $b->{g}, $b->{b} );

        # We write directly to the aligned memory via our views
        $$p_x = $b->{x};
        $$p_y = $b->{y};

        # Render. Pass the pre-pinned pointer. Zero marshalling overhead.
        SDL_RenderTexture( $ren, $tex, undef, $dest_rect_pin );
    }

    # FPS
    $frames++;
    my $now = SDL_GetTicks();
    if ( $now > $last_time + 1000 ) {
        $fps_text  = sprintf 'FPS: %s | Bunnies: %s', $frames, scalar @bunnies;
        $last_time = $now;
        $frames    = 0;
        say $fps_text;
    }
    SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
    SDL_RenderDebugText( $ren, 10, 10, $fps_text );
    SDL_RenderPresent($ren);
}
SDL_DestroyTexture($tex);
SDL_DestroyRenderer($ren);
SDL_DestroyWindow($win);
SDL_Quit();
