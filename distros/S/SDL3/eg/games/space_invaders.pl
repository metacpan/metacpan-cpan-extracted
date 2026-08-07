use v5.36;
use Affix qw[Pointer Int UInt32 UInt64 Float sizeof];
use SDL3  qw[:all];
$|++;

# Space Invaders
#
# Demonstrates runtime generation of assets
#
# Controls:
#  - Left/Right to move
#  - Space to shoot
# Config
my $SCREEN_W    = 800;
my $SCREEN_H    = 600;
my $SPRITE_SIZE = 32;

# Init
if ( SDL_Init(SDL_INIT_VIDEO) == 0 ) { die "Init Error: " . SDL_GetError(); }
my $win       = SDL_CreateWindow( "Affix Invaders", $SCREEN_W, $SCREEN_H, 0 );
my $ren       = SDL_CreateRenderer( $win, undef );
my $event_ptr = Affix::malloc(128);

# 1. Procedural Assets (Invaders + Player + Bullet)
# 0-1: Type A, 2-3: Type B, 4-5: Type C, 6: Player, 7: Bullet
my $total_sprites = 8;
my $surf_w        = $total_sprites * $SPRITE_SIZE;
my $surf_h        = $SPRITE_SIZE;
my $surf          = SDL_CreateSurface( $surf_w, $surf_h, 376840196 );    # RGBA32
SDL_LockSurface($surf);
my $surf_addr   = Affix::address($surf);
my $pixels_addr = ${ Affix::cast( $surf_addr + 24, Pointer [UInt64] ) };
my $pitch       = ${ Affix::cast( $surf_addr + 16, Pointer [Int] ) };

for my $i ( 0 .. $total_sprites - 1 ) {
    my $off_x = $i * $SPRITE_SIZE;
    my $color = 0xFFFFFFFF;                       # White by default
    if    ( $i < 2 )  { $color = 0xFF00FF00; }    # Green (Low)
    elsif ( $i < 4 )  { $color = 0xFFFF0000; }    # Blue (Mid)
    elsif ( $i < 6 )  { $color = 0xFF0000FF; }    # Red (High)
    elsif ( $i == 6 ) { $color = 0xFF00FFFF; }    # Yellow (Player)
    elsif ( $i == 7 ) { $color = 0xFFFFFFFF; }    # White (Bullet)
    my $is_frame_2 = ( $i % 2 != 0 );

    for my $y ( 0 .. 31 ) {
        for my $x ( 0 .. 31 ) {
            my $sx         = abs( $x - 16 );
            my $pixel_addr = $pixels_addr + ( $y * $pitch ) + ( ( $off_x + $x ) * 4 );
            my $pixel_ptr  = Affix::cast( $pixel_addr, Pointer [UInt32] );
            my $draw       = 0;

            # Logic based on sprite index
            if ( $i < 6 ) {

                # INVADERS
                if ( $sx < 11 && $y > 5 && $y < 24 ) {
                    if ( ( ( $sx ^ $y ) & 4 ) == 0 ) { $draw = 1; }
                }
                if ( $y == 10 && ( $sx == 4 ) ) { $draw = 0; }    # Eyes

                # Legs animation
                if ($is_frame_2) {
                    if ( $y >= 24 && $y < 28 && ( $sx == 10 || $sx == 9 ) ) { $draw = 1; }
                }
                else {
                    if ( $y >= 24 && $y < 28 && ( $sx == 4 || $sx == 5 ) ) { $draw = 1; }
                }
            }
            elsif ( $i == 6 ) {

                # PLAYER (space ship)
                if ( $y > 20 && $sx < 14 ) { $draw = 1; }    # Body
                if ( $y > 14 && $sx < 4 )  { $draw = 1; }    # Turret
                if ( $y > 8  && $sx < 2 )  { $draw = 1; }    # Tip
            }
            elsif ( $i == 7 ) {

                # BULLET
                if ( $sx < 2 && $y > 8 && $y < 24 ) { $draw = 1; }
            }
            $$pixel_ptr = $draw ? $color : 0;
        }
    }
}
SDL_UnlockSurface($surf);
my $tex = SDL_CreateTextureFromSurface( $ren, $surf );
SDL_DestroySurface($surf);

# Game state
my $player = { x => $SCREEN_W / 2 - 16, y => $SCREEN_H - 50, w => 32, h => 32, cooldown => 0 };
my @bullets;
my @enemies;

sub reset_game {
    @bullets     = ();
    @enemies     = ();
    $player->{x} = $SCREEN_W / 2 - 16;

    # Spawn baddie grid (5 rows, 8 columns)
    for my $row ( 0 .. 4 ) {
        for my $col ( 0 .. 7 ) {
            my $type = 0;                         # Type A
            if    ( $row == 0 ) { $type = 2; }    # Type C (Top)
            elsif ( $row < 3 )  { $type = 1; }    # Type B (Mid)
            push @enemies, { x => 100 + ( $col * 50 ), y => 50 + ( $row * 40 ), w => 32, h => 32, type => $type, alive => 1 };
        }
    }
}
reset_game();

# Marching state
my $march_dir   = 1;      # 1 = Right, -1 = Left
my $march_timer = 0;
my $march_delay = 500;    # ms
my $move_step   = 10;

# Standard util
sub check_aabb ( $a, $b ) {
    return !( $a->{x} + $a->{w} < $b->{x} || $a->{x} > $b->{x} + $b->{w} || $a->{y} + $a->{h} < $b->{y} || $a->{y} > $b->{y} + $b->{h} );
}
#
my $running   = 1;
my $game_over = 0;
my $win_state = 0;

# Persistent rects
my $src_rect = Affix::calloc( 1, sizeof(SDL_FRect) );
my $dst_rect = Affix::calloc( 1, sizeof(SDL_FRect) );

# Pinned float views for direct writes into the rects
my @sr = map { Affix::cast( Affix::address($src_rect) + $_ * 4, Pointer [Float] ) } 0 .. 3;
my @dr = map { Affix::cast( Affix::address($dst_rect) + $_ * 4, Pointer [Float] ) } 0 .. 3;

sub set_rect {
    my ( $pins, $x, $y, $w, $h ) = @_;
    my $p0 = $pins->[0];
    my $p1 = $pins->[1];
    my $p2 = $pins->[2];
    my $p3 = $pins->[3];
    $$p0 = $x;
    $$p1 = $y;
    $$p2 = $w;
    $$p3 = $h;
}

# Input State
my %keys = ( left => 0, right => 0, fire => 0 );
while ($running) {
    my $now = SDL_GetTicks();
    while ( SDL_PollEvent($event_ptr) ) {
        my $h = Affix::cast( $event_ptr, SDL_CommonEvent );
        if ( $h->{type} == SDL_EVENT_QUIT ) { $running = 0; }
        if ( $h->{type} == SDL_EVENT_KEY_DOWN || $h->{type} == SDL_EVENT_KEY_UP ) {
            my $k    = Affix::cast( $event_ptr, SDL_KeyboardEvent );
            my $down = ( $h->{type} == SDL_EVENT_KEY_DOWN );
            my $c    = $k->{scancode};
            if ( $c == SDL_SCANCODE_LEFT )  { $keys{left}  = $down; }
            if ( $c == SDL_SCANCODE_RIGHT ) { $keys{right} = $down; }
            if ( $c == SDL_SCANCODE_SPACE ) { $keys{fire}  = $down; }
            if ( $c == SDL_SCANCODE_R && $down ) {
                reset_game();
                $game_over = 0;
                $win_state = 0;
            }
            if ( $c == SDL_SCANCODE_ESCAPE ) { $running = 0; }
        }
    }
    unless ( $game_over || $win_state ) {

        # Player
        if ( $keys{left} )  { $player->{x} -= 5; }
        if ( $keys{right} ) { $player->{x} += 5; }

        # Clamp player position
        if ( $player->{x} < 0 )              { $player->{x} = 0; }
        if ( $player->{x} > $SCREEN_W - 32 ) { $player->{x} = $SCREEN_W - 32; }

        # Shoot
        if ( $player->{cooldown} > 0 ) { $player->{cooldown}--; }
        if ( $keys{fire} && $player->{cooldown} <= 0 ) {
            push @bullets, { x => $player->{x} + 12, y => $player->{y}, w => 8, h => 16, active => 1 };
            $player->{cooldown} = 30;    # Rate limit
        }

        # 2. Bullets
        for my $b (@bullets) {
            next unless $b->{active};
            $b->{y} -= 10;
            if ( $b->{y} < -20 ) { $b->{active} = 0; }

            # Collision
            for my $e (@enemies) {
                next unless $e->{alive};
                if ( check_aabb( $b, $e ) ) {
                    $e->{alive}  = 0;
                    $b->{active} = 0;

                    # Speed up slightly on kill
                    if ( $march_delay > 50 ) { $march_delay -= 5; }
                }
            }
        }

        # Enemies march left/right and then down
        if ( $now > $march_timer + $march_delay ) {
            $march_timer = $now;
            my $edge_hit     = 0;
            my $living_count = 0;

            # Check bounds
            for my $e (@enemies) {
                next unless $e->{alive};
                $living_count++;
                if ( ( $march_dir == 1 && $e->{x} > $SCREEN_W - 40 ) || ( $march_dir == -1 && $e->{x} < 10 ) ) {
                    $edge_hit = 1;
                }
            }
            if ( $living_count == 0 ) { $win_state = 1; }
            if ($edge_hit) {
                $march_dir *= -1;
                for my $e (@enemies) { $e->{y} += 20; }    # Drop down
            }
            else {
                for my $e (@enemies) { $e->{x} += ( $move_step * $march_dir ); }
            }

            # Check 'Game Over' state (baddies have reached screen bottom)
            for my $e (@enemies) {
                if ( $e->{alive} && $e->{y} > $player->{y} - 20 ) {
                    $game_over = 1;
                }
            }
        }
    }

    # Render
    SDL_SetRenderDrawColor( $ren, 10, 10, 20, 255 );
    SDL_RenderClear($ren);

    # Draw baddies
    # Animation frame based on time
    my $frame = int( $now / 500 ) % 2;
    for my $e (@enemies) {
        next unless $e->{alive};
        my $idx = ( $e->{type} * 2 ) + $frame;
        set_rect( \@sr, $idx * 32, 0,       32, 32 );
        set_rect( \@dr, $e->{x},   $e->{y}, 32, 32 );
        SDL_RenderTexture( $ren, $tex, $src_rect, $dst_rect );
    }

    # Draw player (index 6)
    set_rect( \@sr, 6 * 32,       0,            32, 32 );
    set_rect( \@dr, $player->{x}, $player->{y}, 32, 32 );
    SDL_RenderTexture( $ren, $tex, $src_rect, $dst_rect );

    # Draw bullets (index 7)
    for my $b (@bullets) {
        next unless $b->{active};
        set_rect( \@sr, 7 * 32,       0,       32, 32 );
        set_rect( \@dr, $b->{x} - 12, $b->{y}, 32, 32 );    # Center the 32px sprite
        SDL_RenderTexture( $ren, $tex, $src_rect, $dst_rect );
    }

    # UI
    if ($game_over) {
        SDL_SetRenderDrawColor( $ren, 255, 0, 0, 255 );
        SDL_RenderDebugText( $ren, 350, 280, "GAME OVER" );
        SDL_RenderDebugText( $ren, 330, 300, "Press R to Restart" );
    }
    elsif ($win_state) {
        SDL_SetRenderDrawColor( $ren, 0, 255, 0, 255 );
        SDL_RenderDebugText( $ren, 350, 280, "VICTORY!" );
        SDL_RenderDebugText( $ren, 330, 300, "Press R to Restart" );
    }
    SDL_RenderPresent($ren);
    SDL_Delay(16);
}
SDL_DestroyTexture($tex);
SDL_DestroyRenderer($ren);
SDL_DestroyWindow($win);
SDL_Quit();
