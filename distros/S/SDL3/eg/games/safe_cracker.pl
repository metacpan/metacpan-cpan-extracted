use v5.38;
use Affix qw[:all];
use SDL3  qw[:all];
#
# Safe cracker. Use haptics to guide you to the correct 3 position combination.
#
# This uses the SDL_RumbleGamepad API to demonstrate using both the low and high frequency haptics.
#
# Controls:
#  - Rotate the joystick until you hone in on the sweet spot. Haptics should lead you to it.
#  - Hold position until the safe locks that value in.
#
# Config
my $SCREEN_W    = 800;
my $SCREEN_H    = 600;
my $DIAL_RADIUS = 200;
my $DEADZONE    = 5000;

# Init
if ( SDL_Init( SDL_INIT_VIDEO | SDL_INIT_GAMEPAD ) == 0 ) { die SDL_GetError(); }
my $win       = SDL_CreateWindow( 'Safe Cracker', $SCREEN_W, $SCREEN_H, 0 );
my $ren       = SDL_CreateRenderer( $win, undef );
my $event_ptr = Affix::malloc(128);
SDL_SetRenderDrawBlendMode( $ren, SDL_BLENDMODE_BLEND );

# Gamepad setup
my $gamepad   = undef;
my $count_ptr = Affix::calloc( 1, sizeof(Int) );
my $list_ptr  = SDL_GetGamepads($count_ptr);
if ( Affix::cast( $count_ptr, Int ) > 0 ) {
    my $id = Affix::cast( $list_ptr, UInt32 );
    $gamepad = SDL_OpenGamepad($id);
    say "Controller Connected: " . SDL_GetGamepadName($gamepad);
}
SDL_free($list_ptr) if $list_ptr;
die 'This demo requires a Gamepad with Rumble support!' unless $gamepad;

# Game state
# Generate a combo (3 numbers between 0-99)
my @combo              = ( int( rand(100) ), int( rand(100) ), int( rand(100) ) );
my $current_target_idx = 0;
my $is_unlocked        = 0;

# Dial state
my $current_angle = 0;    # Radians
my $current_val   = 0;    # 0-99
my $last_val      = 0;    # For detecting ticks
my $lock_timer    = 0;    # For holding the number

# Helpers
sub draw_circle ( $cx, $cy, $r, $steps ) {
    my @points;
    for my $i ( 0 .. $steps ) {
        my $a = ( $i / $steps ) * 6.283185;
        push @points, { x => $cx + cos($a) * $r, y => $cy + sin($a) * $r };
    }

    # Draw lines
    for my $i ( 0 .. $steps - 1 ) {
        SDL_RenderLine( $ren, $points[$i]{x}, $points[$i]{y}, $points[ $i + 1 ]{x}, $points[ $i + 1 ]{y} );
    }
}

# Main loop
my $running = 1;
while ($running) {
    while ( SDL_PollEvent($event_ptr) ) {
        my $h = Affix::cast( $event_ptr, SDL_CommonEvent );
        if    ( $h->{type} == SDL_EVENT_QUIT ) { $running = 0; }
        elsif ( $h->{type} == SDL_EVENT_KEY_DOWN ) {
            if ( Affix::cast( $event_ptr, SDL_KeyboardEvent )->{scancode} == SDL_SCANCODE_ESCAPE ) {
                $running = 0;
            }
        }
    }
    my $dt = 16;    # ms

    # Read Input from analog stick
    if ( $gamepad && !$is_unlocked ) {
        my $x = SDL_GetGamepadAxis( $gamepad, SDL_GAMEPAD_AXIS_LEFTX );
        my $y = SDL_GetGamepadAxis( $gamepad, SDL_GAMEPAD_AXIS_LEFTY );
        if ( sqrt( $x * $x + $y * $y ) > $DEADZONE ) {

            # Calculate Angle (-PI to PI)
            $current_angle = atan2( $y, $x );

            # Convert to 0-100 Scale
            # atan2 returns 0 at 3 o'clock. We want 0 at 12 o'clock.
            # shift by PI/2
            my $adjusted = $current_angle + 1.5708;
            if ( $adjusted < 0 ) { $adjusted += 6.283185; }

            # Map 0..2PI -> 0..100
            $current_val = int( ( $adjusted / 6.283185 ) * 100 ) % 100;

            # Haptics logic
            my $target = $combo[$current_target_idx];

            # Tick feedback (passing any number)
            if ( $current_val != $last_val ) {

                # If we hit the target number exactly, Heavy Rumble
                if ( $current_val == $target ) {

                    # (Low freq, High freq, Duration)
                    # Heavy Thud
                    SDL_RumbleGamepad( $gamepad, 40000, 0, 150 );
                }
                else {
                    # Light Click
                    SDL_RumbleGamepad( $gamepad, 0, 10000, 20 );
                }
                $last_val   = $current_val;
                $lock_timer = 0;              # Reset hold timer if we moved
            }

            # B. Solving Logic (Hold Steady)
            if ( $current_val == $target ) {
                $lock_timer += $dt;

                # If held for 1 second
                if ( $lock_timer > 1000 ) {

                    # Success Rumble!
                    SDL_RumbleGamepad( $gamepad, 60000, 60000, 300 );
                    $current_target_idx++;
                    $lock_timer = 0;
                    if ( $current_target_idx >= 3 ) {
                        $is_unlocked = 1;
                    }
                    else {
                        # Small pause/feedback to show progress
                        SDL_Delay(500);
                    }
                }
            }
            else {
                $lock_timer = 0;
            }
        }
    }

    # Render
    SDL_SetRenderDrawColor( $ren, 20, 20, 20, 255 );
    SDL_RenderClear($ren);
    my $cx = $SCREEN_W / 2;
    my $cy = $SCREEN_H / 2;

    # Draw status lights
    for my $i ( 0 .. 2 ) {
        if ( $i < $current_target_idx ) {
            SDL_SetRenderDrawColor( $ren, 0, 255, 0, 255 );    # Solved (Green)
        }
        elsif ( $i == $current_target_idx ) {
            SDL_SetRenderDrawColor( $ren, 255, 200, 0, 255 );    # Active (Yellow)
        }
        else {
            SDL_SetRenderDrawColor( $ren, 50, 50, 50, 255 );     # Locked (Grey)
        }
        my $lx = $cx - 60 + ( $i * 60 );
        SDL_RenderFillRect( $ren, { x => $lx - 10, y => $cy - 250, w => 20, h => 20 } );
    }

    # Draw dial
    if ($is_unlocked) {
        SDL_SetRenderDrawColor( $ren, 0, 255, 0, 255 );
        SDL_RenderDebugText( $ren, $cx - 30, $cy, "SAFE OPEN!" );
        draw_circle( $cx, $cy, $DIAL_RADIUS, 64 );
    }
    else {
        SDL_SetRenderDrawColor( $ren, 200, 200, 200, 255 );
        draw_circle( $cx, $cy, $DIAL_RADIUS, 64 );

        # Draw ticks
        for my $i ( 0 .. 11 ) {    # 12 hour marks
            my $a  = ( $i / 12 ) * 6.283185;
            my $x1 = $cx + cos($a) * ( $DIAL_RADIUS - 20 );
            my $y1 = $cy + sin($a) * ( $DIAL_RADIUS - 20 );
            my $x2 = $cx + cos($a) * $DIAL_RADIUS;
            my $y2 = $cy + sin($a) * $DIAL_RADIUS;
            SDL_RenderLine( $ren, $x1, $y1, $x2, $y2 );
        }

        # Draw needle
        my $nx = $cx + cos($current_angle) * ( $DIAL_RADIUS - 10 );
        my $ny = $cy + sin($current_angle) * ( $DIAL_RADIUS - 10 );

        # Change color if hovering over target
        if ( $current_val == $combo[$current_target_idx] ) {
            SDL_SetRenderDrawColor( $ren, 255, 50, 50, 255 );    # Red Hot
        }
        else {
            SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
        }
        SDL_RenderLine( $ren, $cx, $cy, $nx, $ny );

        # Progress Bar (Holding)
        if ( $lock_timer > 0 ) {
            my $pct = $lock_timer / 1000.0;
            SDL_SetRenderDrawColor( $ren, 0, 255, 0, 255 );
            SDL_RenderFillRect( $ren, { x => $cx - 50, y => $cy + 50, w => 100 * $pct, h => 10 } );
        }

        # Debug Text
        SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
        SDL_RenderDebugText( $ren, 10, 10, "Current: $current_val" );

        # Cheat code for testing (Show target)
        # SDL_RenderDebugText($ren, 10, 30, "Target: " . $combo[$current_target_idx]);
    }
    SDL_RenderPresent($ren);
    SDL_Delay(16);
}
SDL_CloseGamepad($gamepad) if $gamepad;
SDL_DestroyRenderer($ren);
SDL_DestroyWindow($win);
SDL_Quit();
