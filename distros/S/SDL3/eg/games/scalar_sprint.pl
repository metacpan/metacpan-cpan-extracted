use v5.36;
use Carp  qw[croak];
use Affix qw[Int UInt32 sizeof];
use SDL3  qw[:all];
$|++;

# Another simple game. This time a quick platformer to demonstrate gamepad support.
# You jump between platforms, pickup powerups, avoid random bottomless pits.
#
# Powerups:
#  - Speed boost (blue)
#  - Jump boost (yellow)
#  - Become magnetic (purple)
#  - Float like a feather (pink)
#  - Strap on a jetpack (orange)
#  - Extra life (red)
#
# Gamepad controls (I'm using an Xbox One controller):
#  - Move left/right with the left joystick
#  - Hit 'A' to jump
#  - Hit 'Start' to pause/resume
#
# Keyboard controls
#  - Move left/right with the arrow keys
#  - Hit 'Space' to jump
#  - Hit 'P' to pause/resume
#  - Hit 'R' to reset the game
#
# TODO: See #2
# Controls:
#  - Keyboard:
#  - Gamepad: Joystick moves left and right. 'A' jumps. Pause the game with the start button.
#
# Config
my $SCREEN_W = 1024;
my $SCREEN_H = 768;

# Physics
my $GRAVITY          = 0.4;      # 0.5 is too floaty
my $JUMP_FORCE       = -13.0;    # -10 and you can't reach any platforms but anything lower than -15 is too bouncy
my $MOVE_SPEED       = 8.0;      # Honestly, 6.0 also works. Maybe we should set this to 7?
my $DEADZONE         = 8000;     # For joystick
my $POWERUP_DURATION = 400;      # This is more than enough time
my $MS_PER_UPDATE    = 16.0;     # This is fine for a platformer

# Level gen
my $GROUND_Y     = 650;
my $PIT_WIDTH    = 160;
my $MIN_GROUND_W = 400;
#
use constant { TYPE_SPEED => 1, TYPE_JUMP => 2, TYPE_MAGNET => 3, TYPE_FEATHER => 4, TYPE_JETPACK => 5, TYPE_LIFE => 6, };
my %PWR_DATA = (
    TYPE_SPEED()   => { name => 'SPEED',   col => [ 0,   100, 255 ] },
    TYPE_JUMP()    => { name => 'JUMP',    col => [ 255, 200, 0 ] },
    TYPE_MAGNET()  => { name => 'MAGNET',  col => [ 200, 0,   255 ] },
    TYPE_FEATHER() => { name => 'FEATHER', col => [ 255, 100, 200 ] },
    TYPE_JETPACK() => { name => 'JETPACK', col => [ 255, 140, 0 ] },
    TYPE_LIFE()    => { name => '1-UP',    col => [ 255, 50,  50 ] },
);
if ( SDL_Init( SDL_INIT_VIDEO | SDL_INIT_GAMEPAD ) == 0 ) { die 'Init Error: ' . SDL_GetError(); }
my $win       = SDL_CreateWindow( 'Scalar Sprint', $SCREEN_W, $SCREEN_H, 0 );
my $ren       = SDL_CreateRenderer( $win, undef );
my $event_ptr = Affix::malloc(128);
SDL_SetRenderDrawBlendMode( $ren, SDL_BLENDMODE_BLEND );

# Gamepad
my $gamepad      = undef;
my $gamepad_id   = -1;
my $gamepad_name = 'Keyboard Only';

sub open_controller ($id) {
    return if $gamepad_id == $id;
    if ($gamepad) { SDL_CloseGamepad($gamepad); }
    $gamepad = SDL_OpenGamepad($id);
    if ($gamepad) {
        $gamepad_id   = SDL_GetGamepadID($gamepad);
        $gamepad_name = SDL_GetGamepadName($gamepad);
        say 'Connected: ' . $gamepad_name;
    }
}
my $count_ptr = Affix::calloc( 1, sizeof(Int) );
my $list_ptr  = SDL_GetGamepads($count_ptr);
if ( Affix::cast( $count_ptr, Int ) > 0 ) {
    open_controller( Affix::cast( $list_ptr, UInt32 ) );
}
SDL_free($list_ptr) if $list_ptr;

# Game State
my $camera_x    = 0;
my $camera_zoom = 1.0;
my $score       = 0;
my $high_score  = 0;
my $lives       = 3;
my $game_over   = 0;
my $paused      = 0;
my $player      = { x => 100, y => 300, w => 40, h => 40, vx => 0, vy => 0, grounded => 0 };
my %effects;
my @platforms;
my @pickups;
my %keys = ( left => 0, right => 0, jump => 0, start => 0 );

# Generation State
my $last_ground_x   = 0;
my $last_plat_x     = 0;
my $last_plat_y     = 0;
my $high_plat_count = 0;    # Track how long we've been stuck in the sky

# Logic
sub lerp ( $start, $end, $t ) { return $start + ( $end - $start ) * $t; }

sub to_screen_rect ( $world_x, $world_y, $w, $h ) {
    my $sw               = $w * $camera_zoom;
    my $sh               = $h * $camera_zoom;
    my $sx               = ( $world_x - $camera_x ) * $camera_zoom;
    my $dist_from_bottom = $SCREEN_H - $world_y;
    my $sy               = $SCREEN_H - ( $dist_from_bottom * $camera_zoom );
    return { x => $sx, y => $sy, w => $sw, h => $sh };
}

sub draw_centered_text ( $y, $text ) {
    my $x = ( $SCREEN_W - ( length($text) * 8 ) ) / 2;
    SDL_RenderDebugText( $ren, $x, $y, $text );
}

sub respawn_player {
    $player->{x}  = $camera_x + 100;
    $player->{y}  = 0;
    $player->{vx} = 0;
    $player->{vy} = 0;
    %effects      = ();
}

sub reset_game {
    $lives           = 3;
    $score           = 0;
    $camera_x        = 0;
    $camera_zoom     = 1.0;
    $game_over       = 0;
    $paused          = 0;
    @platforms       = ();
    @pickups         = ();
    $last_ground_x   = -200;
    $last_plat_x     = 400;
    $last_plat_y     = 450;
    $high_plat_count = 0;

    # Start Runway
    push @platforms, { x => $last_ground_x, y => $GROUND_Y, w => 1200, h => 300 };
    $last_ground_x += 1200;
    respawn_player();
}
reset_game();

sub spawn_powerup ( $x, $y ) {
    if ( rand() > 0.65 ) {
        my $r    = rand();
        my $type = TYPE_SPEED;
        if    ( $r > 0.85 ) { $type = TYPE_LIFE; }
        elsif ( $r > 0.70 ) { $type = TYPE_JETPACK; }
        elsif ( $r > 0.55 ) { $type = TYPE_MAGNET; }
        elsif ( $r > 0.40 ) { $type = TYPE_FEATHER; }
        elsif ( $r > 0.20 ) { $type = TYPE_JUMP; }
        push @pickups, { x => $x, y => $y, w => 30, h => 30, type => $type };
    }
}

sub update_world_gen {
    my $look_ahead = ( $SCREEN_W / $camera_zoom ) + 200;

    # Generate floor
    if ( $last_ground_x < $camera_x + $look_ahead ) {
        if ( rand() > 0.85 ) {
            $last_ground_x += $PIT_WIDTH;
        }
        else {
            my $w     = $MIN_GROUND_W + int( rand(600) );
            my $h_var = int( rand(40) ) - 20;
            push @platforms, { x => $last_ground_x, y => $GROUND_Y + $h_var, w => $w, h => 400 };
            $last_ground_x += $w;
        }
    }

    # Generate platforms
    if ( $last_plat_x < $camera_x + $look_ahead ) {
        my $gap = 150 + int( rand(200) );
        my $w   = 150 + int( rand(200) );
        my $h   = 40;
        my $y;

        # Anti-frustration logic:
        # If the last 3 platforms have been 'High' (Y < 480), force a 'Low' one.
        # Max Jump is ~200px. Ground is 650.
        # Anything < 450 is unreachable from the floor without a double jump/powerup.
        if ( $high_plat_count >= 3 ) {

            # FORCE LOW PLATFORM (Accessible from Ground)
            # 500 is easily reachable from 650.
            $y               = 500 + int rand 50;
            $high_plat_count = 0;                   # Reset counter
        }
        else {
            # Standard random generation
            my $delta_y = int( rand 200 ) - 100;    # -100 (Up) to +100 (Down)
            $y = $last_plat_y + $delta_y;

            # Clamp logic
            if ( $y < 200 ) { $y = 200; }
            if ( $y > 550 ) { $y = 550; }           # Don't go too low or it merges with floor

            # Track if this is a 'High' platform
            if ( $y < 450 ) {
                $high_plat_count++;
            }
            else {
                $high_plat_count = 0;
            }
        }
        my $new_x = $last_plat_x + $gap;
        push @platforms, { x => $new_x, y => $y, w => $w, h => $h };
        spawn_powerup( $new_x + $w / 2 - 15, $y - 60 );
        $last_plat_x = $new_x + $w;
        $last_plat_y = $y;
    }
    if ( $platforms[0]->{x} + $platforms[0]->{w} < $camera_x - 500 ) { shift @platforms; }
}

sub check_aabb ( $a, $b ) {
    return !( $a->{x} + $a->{w} < $b->{x} || $a->{x} > $b->{x} + $b->{w} || $a->{y} + $a->{h} < $b->{y} || $a->{y} > $b->{y} + $b->{h} );
}

sub update_physics {

    # Input
    my $input_x   = 0.0;
    my $jump_held = 0;
    if ($gamepad) {
        my $axis = SDL_GetGamepadAxis( $gamepad, SDL_GAMEPAD_AXIS_LEFTX );
        if ( abs($axis) > $DEADZONE )                                     { $input_x   = $axis / 32767.0; }
        if ( SDL_GetGamepadButton( $gamepad, SDL_GAMEPAD_BUTTON_SOUTH ) ) { $jump_held = 1; }
    }
    if ( $keys{left} )     { $input_x -= 1.0; }
    if ( $keys{right} )    { $input_x += 1.0; }
    if ( $keys{jump} )     { $jump_held = 1; }
    if ( $input_x < -1.0 ) { $input_x   = -1.0; }
    if ( $input_x > 1.0 )  { $input_x   = 1.0; }

    # Physics
    my $speed_mult = ( ( $effects{ TYPE_SPEED() } // 0 ) > 0 ) ? 1.8 : 1.0;
    $player->{vx} = $input_x * $MOVE_SPEED * $speed_mult;
    if ( $jump_held && ( $effects{ TYPE_JETPACK() } // 0 ) > 0 ) {
        $player->{vy} -= 1.2;
        if ( $player->{vy} < -8.0 ) { $player->{vy} = -8.0; }
        $player->{grounded} = 0;
    }
    elsif ( $jump_held && $player->{grounded} ) {
        my $jump_mult = ( ( $effects{ TYPE_JUMP() } // 0 ) > 0 ) ? 1.5 : 1.0;
        $player->{vy}       = $JUMP_FORCE * $jump_mult;
        $player->{grounded} = 0;
    }
    my $current_gravity = ( ( $effects{ TYPE_FEATHER() } // 0 ) > 0 ) ? ( $GRAVITY * 0.4 ) : $GRAVITY;
    $player->{vy} += $current_gravity;
    $player->{x}  += $player->{vx};
    $player->{y}  += $player->{vy};
    $player->{grounded} = 0;

    # Collision
    for my $plat (@platforms) {
        if ( check_aabb( $player, $plat ) ) {
            my $feet    = $player->{y} + $player->{h};
            my $surface = $plat->{y};

            # Step Up Logic
            if ( $feet >= $surface && $feet <= $surface + 30 ) {
                if ( $player->{vy} >= 0 ) {
                    $player->{y}        = $plat->{y} - $player->{h};
                    $player->{vy}       = 0;
                    $player->{grounded} = 1;
                }
            }
        }
    }

    # Pickups
    for my $i ( reverse 0 .. $#pickups ) {
        my $p = $pickups[$i];
        if ( ( $effects{ TYPE_MAGNET() } // 0 ) > 0 ) {
            my $dx = ( $player->{x} + $player->{w} / 2 ) - ( $p->{x} + $p->{w} / 2 );
            my $dy = ( $player->{y} + $player->{h} / 2 ) - ( $p->{y} + $p->{h} / 2 );
            if ( $dx * $dx + $dy * $dy < 160000 ) {
                $p->{x} += $dx * 0.15;
                $p->{y} += $dy * 0.15;
            }
        }
        if ( check_aabb( $player, $p ) ) {
            my $type = $p->{type};
            if ( $type == TYPE_LIFE ) {
                $lives++;
            }
            else {
                $effects{$type} = $POWERUP_DURATION;
            }
            splice( @pickups, $i, 1 );
        }
    }

    # Timers
    for my $k ( keys %effects ) {
        if ( defined $effects{$k} && $effects{$k} > 0 ) {
            $effects{$k}--;
            if ( $effects{$k} <= 0 ) { delete $effects{$k}; }
        }
    }

    # World Update
    if ( $player->{x} > $score ) { $score = int( $player->{x} ); }
    my $target_cam = $player->{x} - 200;
    if ( $camera_x < $target_cam ) { $camera_x = $target_cam; }

    # Zoom Logic
    my $target_zoom = 1.0;
    if ( $player->{y} < 100 ) {
        $target_zoom = 1.0 - ( abs( 100 - $player->{y} ) / 700 );
        if ( $target_zoom < 0.5 ) { $target_zoom = 0.5; }
    }
    $camera_zoom = lerp( $camera_zoom, $target_zoom, 0.1 );
    update_world_gen();
    if ( $player->{y} > $SCREEN_H + ( $SCREEN_H * ( 1 - $camera_zoom ) ) ) {
        $lives--;
        if ( $lives <= 0 ) {
            $game_over = 1;
            if ( $score > $high_score ) { $high_score = $score; }
        }
        else {
            respawn_player();
        }
    }
}

# Loop
my $running          = 1;
my $previous_time    = SDL_GetTicks();
my $lag              = 0.0;
my $last_start_state = 0;
while ($running) {
    my $current_time = SDL_GetTicks();
    my $elapsed      = $current_time - $previous_time;
    $previous_time = $current_time;
    $lag += $elapsed;
    if ( $gamepad && SDL_GamepadConnected($gamepad) == 0 ) {
        SDL_CloseGamepad($gamepad);
        $gamepad      = undef;
        $gamepad_name = 'Keyboard Only';
    }
    while ( SDL_PollEvent($event_ptr) ) {
        my $h = Affix::cast( $event_ptr, SDL_CommonEvent );
        if    ( $h->{type} == SDL_EVENT_QUIT ) { $running = 0; }
        elsif ( $h->{type} == SDL_EVENT_GAMEPAD_ADDED ) {
            my $g = Affix::cast( $event_ptr, SDL_GamepadDeviceEvent );
            open_controller( $g->{which} );
        }
        elsif ( $h->{type} == SDL_EVENT_KEY_DOWN || $h->{type} == SDL_EVENT_KEY_UP ) {
            my $k       = Affix::cast( $event_ptr, SDL_KeyboardEvent );
            my $is_down = ( $h->{type} == SDL_EVENT_KEY_DOWN ) ? 1 : 0;
            my $code    = $k->{scancode};
            if    ( $code == SDL_SCANCODE_LEFT )          { $keys{left}  = $is_down; }
            elsif ( $code == SDL_SCANCODE_RIGHT )         { $keys{right} = $is_down; }
            elsif ( $code == SDL_SCANCODE_SPACE )         { $keys{jump}  = $is_down; }
            elsif ( $code == SDL_SCANCODE_RETURN )        { $keys{start} = $is_down; }
            elsif ( $code == SDL_SCANCODE_P && $is_down ) { $paused      = !$paused; }
            elsif ( $code == SDL_SCANCODE_R && $is_down && $game_over ) { reset_game(); }
        }
    }
    my $start_pressed = 0;
    if ($gamepad) {
        my $start_down = SDL_GetGamepadButton( $gamepad, SDL_GAMEPAD_BUTTON_START );
        if ( $start_down && !$last_start_state ) { $start_pressed = 1; }
        $last_start_state = $start_down;
    }
    state $last_enter = 0;
    if ( $keys{start} && !$last_enter ) { $start_pressed = 1; }
    $last_enter = $keys{start};
    if ($start_pressed) {
        if   ($game_over) { reset_game(); }
        else              { $paused = !$paused; }
    }
    if ( !$paused && !$game_over ) {
        while ( $lag >= $MS_PER_UPDATE ) {
            update_physics();
            $lag -= $MS_PER_UPDATE;
        }
    }
    else {
        $lag = 0;
    }

    # Render
    SDL_SetRenderDrawColor( $ren, 30, 30, 40, 255 );
    SDL_RenderClear($ren);

    # Background
    SDL_SetRenderDrawColor( $ren, 50, 50, 60, 255 );
    my $camera_x = $player->{x} * .4;
    my $shift    = int( $camera_x * 0.1 ) % 1024;
    $shift += 1024 if $shift < 0;

    # Draw 2 copies (Offset by -$shift)
    for my $offset ( -$shift, -$shift + 1024 ) {
        my @pts = (
            $offset,
            $SCREEN_H,
            $offset + 200,
            $SCREEN_H - 300,
            $offset + 500,
            $SCREEN_H - 100,
            $offset + 800,
            $SCREEN_H - 400,
            $offset + 1024,
            $SCREEN_H
        );
        for ( my $i = 0; $i < @pts - 2; $i += 2 ) {
            my ( $ax, $ay, $bx, $by ) = @pts[ $i .. $i + 3 ];
            next if $bx < 0 || $ax > $SCREEN_W;    # Skip lines completely off-screen
            if ( $ax < 0 ) {                       # Clip line start to 0 if it goes off-screen left
                $ay += ( $by - $ay ) * ( 0 - $ax ) / ( $bx - $ax );
                $ax = 0;
            }
            SDL_RenderLine( $ren, $ax, $ay, $bx, $by );
        }
    }

    # Platforms
    SDL_SetRenderDrawColor( $ren, 100, 100, 120, 255 );
    for my $p (@platforms) {
        SDL_RenderFillRect( $ren, to_screen_rect( $p->{x}, $p->{y}, $p->{w}, $p->{h} ) );
    }

    # Pickups
    for my $p (@pickups) {
        my $conf = $PWR_DATA{ $p->{type} };
        my $c    = $conf->{col};
        SDL_SetRenderDrawColor( $ren, $c->[0], $c->[1], $c->[2], 255 );
        SDL_RenderFillRect( $ren, to_screen_rect( $p->{x}, $p->{y}, $p->{w}, $p->{h} ) );
    }

    # Player (Blended)
    my ( $sum_r, $sum_g, $sum_b ) = ( 0, 0, 0 );
    my $total_weight = 0;
    for my $id ( keys %effects ) {
        next unless ( $effects{$id} // 0 ) > 0;
        my $conf = $PWR_DATA{$id};
        my $w    = $effects{$id} / $POWERUP_DURATION;
        $sum_r        += $conf->{col}[0] * $w;
        $sum_g        += $conf->{col}[1] * $w;
        $sum_b        += $conf->{col}[2] * $w;
        $total_weight += $w;
    }
    my ( $pr, $pg, $pb );
    if ( $total_weight > 0 ) {
        my $avg_r = $sum_r / $total_weight;
        my $avg_g = $sum_g / $total_weight;
        my $avg_b = $sum_b / $total_weight;
        my $blend = ( $total_weight > 1.0 ) ? 1.0 : $total_weight;
        $pr = 255 + ( $avg_r - 255 ) * $blend;
        $pg = 255 + ( $avg_g - 255 ) * $blend;
        $pb = 255 + ( $avg_b - 255 ) * $blend;
    }
    else {
        ( $pr, $pg, $pb ) = ( 255, 255, 255 );
    }
    SDL_SetRenderDrawColor( $ren, int($pr), int($pg), int($pb), 255 );
    SDL_RenderFillRect( $ren, to_screen_rect( $player->{x}, $player->{y}, $player->{w}, $player->{h} ) );

    # UI
    SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
    SDL_RenderDebugText( $ren, 10, 10, 'Score: ' . $score );
    SDL_RenderDebugText( $ren, 10, 30, 'Lives: ' . $lives );

    # Instructions
    SDL_SetRenderDrawColor( $ren, 0, 0, 0, 150 );
    SDL_RenderFillRect( $ren, { x => $SCREEN_W - 160, y => 10, w => 150, h => 160 } );
    my $iy = 20;
    SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
    SDL_RenderDebugText( $ren, $SCREEN_W - 150, $iy, 'POWERUPS' );
    $iy += 20;
    for my $id ( TYPE_SPEED, TYPE_JUMP, TYPE_MAGNET, TYPE_FEATHER, TYPE_JETPACK, TYPE_LIFE ) {
        my $conf = $PWR_DATA{$id};
        my $c    = $conf->{col};
        SDL_SetRenderDrawColor( $ren, $c->[0], $c->[1], $c->[2], 255 );
        SDL_RenderFillRect( $ren, { x => $SCREEN_W - 150, y => $iy, w => 10, h => 10 } );
        SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
        SDL_RenderDebugText( $ren, $SCREEN_W - 135, $iy, $conf->{name} );
        $iy += 20;
    }
    my $ui_y = $SCREEN_H - 20;
    for my $id ( keys %effects ) {
        if ( $effects{$id} > 0 ) {
            my $conf = $PWR_DATA{$id};
            my $c    = $conf->{col};
            my $w    = ( $effects{$id} / $POWERUP_DURATION ) * 200;
            SDL_SetRenderDrawColor( $ren, $c->[0], $c->[1], $c->[2], 200 );
            SDL_RenderFillRect( $ren, { x => 10, y => $ui_y, w => $w, h => 10 } );
            SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
            SDL_RenderDebugText( $ren, 15, $ui_y - 10, $conf->{name} );
            $ui_y -= 30;
        }
    }
    if ($paused) {
        SDL_SetRenderDrawColor( $ren, 0, 0, 0, 100 );
        SDL_RenderFillRect( $ren, { x => 0, y => 0, w => $SCREEN_W, h => $SCREEN_H } );
        SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
        draw_centered_text( $SCREEN_H / 2, 'PAUSED' );
    }
    elsif ($game_over) {
        SDL_SetRenderDrawColor( $ren, 50, 0, 0, 200 );
        SDL_RenderFillRect( $ren, { x => 0, y => 0, w => $SCREEN_W, h => $SCREEN_H } );
        SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
        draw_centered_text( $SCREEN_H / 2 - 20, 'GAME OVER' );
        draw_centered_text( $SCREEN_H / 2 + 10, 'Final Score: ' . $score );
        draw_centered_text( $SCREEN_H / 2 + 30, 'Press Start or Enter to Restart' );
    }
    SDL_RenderPresent($ren);
    SDL_Delay(1);
}
SDL_CloseGamepad($gamepad) if $gamepad;
SDL_DestroyRenderer($ren);
SDL_DestroyWindow($win);
SDL_Quit();
