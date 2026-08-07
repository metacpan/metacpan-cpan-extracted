use v5.40;
use Carp qw[croak];
use SDL3 qw[:all];
$|++;

# https://en.wikipedia.org/wiki/Boids
# Controls:
#  - Move your mouse around to chase the flocks
#  - Click to appear extra mean
#
# Config
my $SCREEN_W   = 1024;
my $SCREEN_H   = 768;
my $BOID_COUNT = 200;

# Boid Settings
my $MAX_SPEED       = 4.0;
my $NEIGHBOR_DIST   = 50;
my $SEPARATION_DIST = 25;

# Init
die 'Init Error: ' . SDL_GetError() if SDL_Init(SDL_INIT_VIDEO) == 0;
my $win       = SDL_CreateWindow( 'The Swarm', $SCREEN_W, $SCREEN_H, 0 );
my $ren       = SDL_CreateRenderer( $win, undef );
my $event_ptr = Affix::malloc(128);
SDL_HideCursor();

# Boid Data
my @boids;
for ( 1 .. $BOID_COUNT ) {
    push @boids,
        {
        x  => rand($SCREEN_W),
        y  => rand($SCREEN_H),
        vx => ( rand() - 0.5 ) * 4,
        vy => ( rand() - 0.5 ) * 4,
        ax => 0,
        ay => 0,
        r  => int( 100 + rand(155) ),
        g  => int( 100 + rand(155) ),
        b  => 255
        };
}

# Math
sub dist_sq( $b1, $b2 ) {
    my $dx = $b1->{x} - $b2->{x};
    my $dy = $b1->{y} - $b2->{y};
    $dx * $dx + $dy * $dy;
}

sub limit( $vec, $max ) {
    my ( $x, $y ) = @$vec;
    my $mag_sq = $x * $x + $y * $y;
    if ( $mag_sq > $max * $max && $mag_sq > 0 ) {
        my $mag = sqrt($mag_sq);
        return [ $x / $mag * $max, $y / $mag * $max ];
    }
    $vec;
}

# Main Loop
my $running = 1;
while ($running) {
    while ( SDL_PollEvent($event_ptr) ) {
        my $h = Affix::cast( $event_ptr, SDL_CommonEvent );
        if    ( $h->{type} == SDL_EVENT_QUIT ) { $running = 0; }
        elsif ( $h->{type} == SDL_EVENT_KEY_DOWN ) {
            my $k = Affix::cast( $event_ptr, SDL_KeyboardEvent );
            if ( $k->{scancode} == SDL_SCANCODE_ESCAPE ) { $running = 0; }
        }
    }

    # Update Mouse Logic
    # We pass the raw pointers to SDL to fill
    my $mouse_mask = SDL_GetMouseState( my ( $predator_x, $predator_y ) );

    # Update Boids
    for my $i ( 0 .. $#boids ) {
        my $b = $boids[$i];
        my ( $sep_x, $sep_y, $ali_x, $ali_y, $coh_x, $coh_y, $count ) = ( 0, 0, 0, 0, 0, 0, 0 );

        # Flock Logic
        for my $j ( 0 .. $#boids ) {
            next if $i == $j;
            my $other = $boids[$j];
            my $d_sq  = dist_sq( $b, $other );
            if ( $d_sq > 0 && $d_sq < $NEIGHBOR_DIST**2 ) {
                $ali_x += $other->{vx};
                $ali_y += $other->{vy};
                $coh_x += $other->{x};
                $coh_y += $other->{y};
                if ( $d_sq < $SEPARATION_DIST**2 ) {
                    my $diff_x = $b->{x} - $other->{x};
                    my $diff_y = $b->{y} - $other->{y};
                    my $d      = sqrt($d_sq);
                    $sep_x += $diff_x / $d;
                    $sep_y += $diff_y / $d;
                }
                $count++;
            }
        }
        if ( $count > 0 ) {
            $ali_x /= $count;
            $ali_y /= $count;
            $coh_x /= $count;
            $coh_y /= $count;
            my $dir_x = $coh_x - $b->{x};
            my $dir_y = $coh_y - $b->{y};
            ( $coh_x, $coh_y ) = @{ limit( [ $dir_x, $dir_y ], $MAX_SPEED ) };
            ( $ali_x, $ali_y ) = @{ limit( [ $ali_x, $ali_y ], $MAX_SPEED ) };
        }

        # Predator Logic
        my $p_dx      = $b->{x} - $predator_x;
        my $p_dy      = $b->{y} - $predator_y;
        my $p_dist_sq = $p_dx * $p_dx + $p_dy * $p_dy;
        my ( $flee_x, $flee_y ) = ( 0, 0 );
        my $scare_range = ( $mouse_mask & SDL_BUTTON_LMASK ) ? 300 : 150;
        if ( $p_dist_sq < $scare_range**2 ) {
            my $strength = ( $scare_range**2 / ( $p_dist_sq + 1 ) ) * 2.0;
            $flee_x = ( $p_dx / sqrt($p_dist_sq) ) * $strength;
            $flee_y = ( $p_dy / sqrt($p_dist_sq) ) * $strength;
        }
        $b->{ax} += ( $sep_x * 1.5 ) + ( $ali_x * 1.0 ) + ( $coh_x * 1.0 ) + ( $flee_x * 5.0 );
        $b->{ay} += ( $sep_y * 1.5 ) + ( $ali_y * 1.0 ) + ( $coh_y * 1.0 ) + ( $flee_y * 5.0 );
        $b->{vx} += $b->{ax};
        $b->{vy} += $b->{ay};
        ( $b->{vx}, $b->{vy} ) = @{ limit( [ $b->{vx}, $b->{vy} ], $MAX_SPEED ) };
        $b->{x} += $b->{vx};
        $b->{y} += $b->{vy};
        $b->{ax} = 0;
        $b->{ay} = 0;
        if ( $b->{x} < 0 )         { $b->{x} = $SCREEN_W; }
        if ( $b->{x} > $SCREEN_W ) { $b->{x} = 0; }
        if ( $b->{y} < 0 )         { $b->{y} = $SCREEN_H; }
        if ( $b->{y} > $SCREEN_H ) { $b->{y} = 0; }
    }

    # Render
    SDL_SetRenderDrawColor( $ren, 10, 10, 20, 255 );
    SDL_RenderClear($ren);
    my @vert_data;
    for my $b (@boids) {
        my $ang = atan2( $b->{vy}, $b->{vx} );
        my $c   = cos($ang);
        my $s   = sin($ang);

        # Rotated Triangle
        my $x1  = $b->{x} + ( 10 * $c );
        my $y1  = $b->{y} + ( 10 * $s );
        my $x2  = $b->{x} + ( -5 * $c - 5 * $s );
        my $y2  = $b->{y} + ( -5 * $s + 5 * $c );
        my $x3  = $b->{x} + ( -5 * $c + 5 * $s );
        my $y3  = $b->{y} + ( -5 * $s - 5 * $c );
        my $col = { r => $b->{r} / 255.0, g => $b->{g} / 255.0, b => $b->{b} / 255.0, a => 1.0 };
        my $uv  = { x => 0, y => 0 };

        # Flatten structure into list of Vertex structs
        push @vert_data, { position => { x => $x1, y => $y1 }, color => $col, tex_coord => $uv },
            { position => { x => $x2, y => $y2 }, color => $col, tex_coord => $uv },
            { position => { x => $x3, y => $y3 }, color => $col, tex_coord => $uv };
    }
    SDL_RenderGeometry( $ren, undef, \@vert_data, scalar(@vert_data), undef, 0 );

    # Draw Predator
    SDL_SetRenderDrawColor( $ren, 255, 50, 50, 255 );
    my $rad = ( $mouse_mask & SDL_BUTTON_LMASK ) ? 20 : 8;

    # Diamond shape for cursor
    SDL_RenderLine( $ren, $predator_x,        $predator_y - $rad, $predator_x + $rad, $predator_y );
    SDL_RenderLine( $ren, $predator_x + $rad, $predator_y,        $predator_x,        $predator_y + $rad );
    SDL_RenderLine( $ren, $predator_x,        $predator_y + $rad, $predator_x - $rad, $predator_y );
    SDL_RenderLine( $ren, $predator_x - $rad, $predator_y,        $predator_x,        $predator_y - $rad );
    SDL_RenderPresent($ren);
    SDL_Delay(16);
}
SDL_DestroyRenderer($ren);
SDL_DestroyWindow($win);
SDL_Quit();
