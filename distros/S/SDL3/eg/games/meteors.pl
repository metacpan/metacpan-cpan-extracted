use v5.36;
use SDL3 qw[:all];
$|++;

# Simple game to get started. Meteors drop from the top of the screen and you dodge them.
# They all drop at their own rate and the whole game speeds up as you play.
#
# Controls:
#  - Play with the left and right arrows on the keyboard
#  - Space restarts on game over
#  - Escape exits at any time
#
say 'Controls: Left/Right arrows to move. ESC to quit.';

# Configuration
my $SCREEN_W        = 800;
my $SCREEN_H        = 600;
my $PLAYER_SPEED    = 8.0;
my $METEOR_SPEED    = 5.0;
my $METEOR_VARIANCE = 3.0;    # speed + random variance

# Init SDL
SDL_Init(SDL_INIT_VIDEO) || die SDL_GetError;
my $win       = SDL_CreateWindow( 'Meteor Dodge', $SCREEN_W, $SCREEN_H, 0 );
my $ren       = SDL_CreateRenderer( $win, undef );
my $event_ptr = Affix::malloc(128);

# Game State
my $running   = 1;
my $game_over = 0;
my $score     = 0;
my $frames    = 0;

# Player Object
my $player  = { x => 375, y => 540, w => 50, h => 30 };
my @meteors = ();
my %keys    = ( left => 0, right => 0 );

# Check AABB Collision
sub check_collision ( $r1, $r2 ) {
    return !( $r1->{x} + $r1->{w} < $r2->{x} || $r1->{x} > $r2->{x} + $r2->{w} || $r1->{y} + $r1->{h} < $r2->{y} || $r1->{y} > $r2->{y} + $r2->{h} );
}

sub reset_game {
    @meteors      = ();
    $player->{x}  = 375;
    $score        = 0;
    $game_over    = 0;
    $METEOR_SPEED = 5.0;
    %keys         = ( left => 0, right => 0 );
}
while ($running) {
    my $start_tick = SDL_GetTicks();

    # Event Polling
    while ( SDL_PollEvent($event_ptr) ) {
        my $header = Affix::cast( $event_ptr, SDL_CommonEvent );
        if ( $header->{type} == SDL_EVENT_QUIT ) {
            $running = 0;
        }
        elsif ( $header->{type} == SDL_EVENT_KEY_DOWN || $header->{type} == SDL_EVENT_KEY_UP ) {
            my $key_evt = Affix::cast( $event_ptr, SDL_KeyboardEvent );
            my $is_down = ( $header->{type} == SDL_EVENT_KEY_DOWN ) ? 1 : 0;
            my $code    = $key_evt->{scancode};
            if    ( $code == SDL_SCANCODE_LEFT )   { $keys{left}  = $is_down; }
            elsif ( $code == SDL_SCANCODE_RIGHT )  { $keys{right} = $is_down; }
            elsif ( $code == SDL_SCANCODE_ESCAPE ) { $running     = 0; }

            # Restart by hitting space
            reset_game if $code == SDL_SCANCODE_SPACE && $is_down && $game_over;
        }
    }

    # Update positions on screen
    unless ($game_over) {
        $player->{x} -= $PLAYER_SPEED if $keys{left}  && $player->{x} > 0;
        $player->{x} += $PLAYER_SPEED if $keys{right} && $player->{x} < $SCREEN_W - $player->{w};

        # Spawn new meteor
        push @meteors, { x => int( rand( $SCREEN_W - 40 ) ), y => -40, w => 40, h => 40, speed => $METEOR_SPEED + rand $METEOR_VARIANCE }
            if $frames % 15 == 0;

        # Update Meteors
        for my $i ( reverse 0 .. $#meteors ) {
            my $m = $meteors[$i];
            $m->{y} += $m->{speed};
            if ( $m->{y} > $SCREEN_H ) {
                splice @meteors, $i, 1;    # Bump it once it's off screen
                $score++;
                $METEOR_SPEED += 0.5 if $score % 10 == 0;    # Speed up
                next;
            }
            $game_over = check_collision( $player, $m );
        }
        $frames++;
    }

    # Render
    SDL_SetRenderDrawColor( $ren, 20, 20, 40, 255 );
    SDL_RenderClear($ren);
    if ($game_over) {
        SDL_SetRenderDrawColor( $ren, 255, 50, 50, 255 );
        my $y = ( $SCREEN_H / 2 ) - 60;

        # The SDL debug font is usually 8x8
        my $char_w = 8;
        for my $line ( 'GAME OVER', 'Press SPACE to Restart', sprintf 'Score: %d', $score ) {
            my $text_w = length($line) * $char_w;
            my $x      = ( $SCREEN_W - $text_w ) / 2;
            SDL_RenderDebugText( $ren, int($x), $y += 20, $line );
        }
    }
    else {
        # Player (Yellow)
        SDL_SetRenderDrawColor( $ren, 255, 255, 0, 255 );
        SDL_RenderFillRect( $ren, $player );

        # Meteors (Red)
        SDL_SetRenderDrawColor( $ren, 255, 50, 50, 255 );

        # Shallow copy because Affix would pass it as an aggregate to SDL and the speed value will evaporate
        SDL_RenderFillRect( $ren, {%$_} ) for @meteors;

        # UI
        SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
        SDL_RenderDebugText( $ren, 10, 10, 'Score: ' . $score );
    }
    SDL_RenderPresent($ren);

    # Cap FPS
    my $elapsed = SDL_GetTicks() - $start_tick;
    if ( $elapsed < 16 ) { SDL_Delay( 16 - $elapsed ); }
}
SDL_DestroyRenderer($ren);
SDL_DestroyWindow($win);
SDL_Quit();
