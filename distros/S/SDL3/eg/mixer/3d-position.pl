use v5.40;
use SDL3        qw[:all :main];
use SDL3::Mixer qw[:all];

# Demonstrates MIX_SetTrack3DPosition( ... ): a looping tone is placed in 3D
# space around the listener. SDL_mixer applies distance attenuation and stereo
# spatialization automatically, so the tone gets quieter as it moves away from
# the origin (the listener) and pans left/right as it moves along x.
#
# The position is under your control. Move it with the arrow keys:
#
#   LEFT / RIGHT     move the source along X (pans the sound)
#   UP / DOWN        move the source along Y (closer to / further from the listener)
#   PAGE UP / DOWN   move the source along Z (raises it above / lowers it below the listener)
#   A                toggle the automatic orbit on and off
#   SPACE            pause/unpause whatever motion is active
#   ESC              quit
#
# The dot on screen is the source; the square in the middle is the listener.
# The readout shows the position SDL_mixer actually stored, straight from
# MIX_GetTrack3DPosition().
my ( $window, $renderer, $mixer, $track );
my $angle       = 0.0;                           # current position on the orbit, in radians
my $radius      = 3.0;                           # how far from the listener the orbit travels
my $paused      = 0;                             # whether all motion is frozen
my $orbiting    = 1;                             # automatic orbit on by default
my $last_pos    = { x => 0, y => 0, z => 2 };    # last position we asked for
my $verified    = { x => 0, y => 0, z => 0 };    # position read back via MIX_GetTrack3DPosition
my $last_ns     = 0;                             # timestamp of the previous frame (nanoseconds)
my $STEP        = 0.25;                          # how far one arrow/page key press moves the source
my $ORBIT_SPEED = 1.8;                           # radians per second the automatic orbit advances
my $Z_LIMIT     = 10.0;                          # how far above/below the listener Z may be moved
my $XY_LIMIT    = 8.0;                           # how far the source may be moved along X/Y by hand

# Clamp the source to a sensible working range around the listener.
sub _clamp ( $v, $lo, $hi ) { $v < $lo ? $lo : $v > $hi ? $hi : $v }

# Hand the current position to SDL_mixer and read it back to prove it took.
sub _apply_position () {
    MIX_SetTrack3DPosition( $track, $last_pos );
    my $actual = {};
    MIX_GetTrack3DPosition( $track, $actual ) and $verified = $actual;
}

# This function runs once at startup.
sub SDL_AppInit ( $appstate, $argc, $argv ) {
    SDL_SetAppMetadata( 'Example 3D Position', '1.0', 'com.example.3d-position' );

    # This doesn't have to run very much, so give up tons of CPU time between iterations. Optional!
    SDL_SetHint( SDL_HINT_MAIN_CALLBACK_RATE, '60' );
    if ( !SDL_Init(SDL_INIT_VIDEO) ) {
        SDL_Log( q[Couldn't initialize SDL: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !SDL_CreateWindowAndRenderer( 'examples/3d-position', 640, 480, SDL_WINDOW_RESIZABLE, $window, $renderer ) ) {
        SDL_Log( q[Couldn't create window/renderer: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !MIX_Init() ) {
        SDL_Log( q[Couldn't init SDL_mixer library: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }

    # Create a mixer on the default audio device. Don't care about the specific audio format.
    $mixer = MIX_CreateMixerDevice( SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, undef );
    if ( !$mixer ) {
        SDL_Log( q[Couldn't create mixer on default device: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }

    # A looping sound effect to move around. A sinewave makes a steady tone that
    # is easy to hear pan and fade without needing an external audio file.
    my $audio = MIX_CreateSineWaveAudio( $mixer, 440, 0.25, -1 );
    if ( !$audio ) {
        SDL_Log( q[Couldn't generate sinewave: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }

    # One track, looping forever, positioned in 3D every frame.
    $track = MIX_CreateTrack($mixer);
    if ( !$track ) {
        SDL_Log( q[Couldn't create a mixer track: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    MIX_SetTrackAudio( $track, $audio );
    my $options = SDL_CreateProperties();
    SDL_SetNumberProperty( $options, MIX_PROP_PLAY_LOOPS_NUMBER, -1 );    # loop forever.
    MIX_PlayTrack( $track, $options );
    SDL_DestroyProperties($options);

    # Place it somewhere sensible before the first frame.
    _apply_position();
    return SDL_APP_CONTINUE;
}

# This function runs when a new event (mouse input, keypresses, etc) occurs.
sub SDL_AppEvent ( $appstate, $event ) {
    my $type = $event->{type};
    return SDL_APP_SUCCESS  if $type == SDL_EVENT_QUIT;
    return SDL_APP_CONTINUE if $type != SDL_EVENT_KEY_DOWN;
    my $key = $event->{key}{key};
    return SDL_APP_SUCCESS if $key == SDLK_ESCAPE;
    if ( $key == SDLK_SPACE ) {
        $paused = !$paused;
    }
    elsif ( $key == SDLK_A ) {
        $orbiting = !$orbiting;
    }
    elsif ( $key == SDLK_LEFT ) {

        # Moving by hand takes over from the orbit, so the change is visible.
        $orbiting = 0;
        $last_pos->{x} = _clamp( $last_pos->{x} - $STEP, -$XY_LIMIT, $XY_LIMIT );
    }
    elsif ( $key == SDLK_RIGHT ) {
        $orbiting = 0;
        $last_pos->{x} = _clamp( $last_pos->{x} + $STEP, -$XY_LIMIT, $XY_LIMIT );
    }
    elsif ( $key == SDLK_UP ) {
        $orbiting = 0;
        $last_pos->{y} = _clamp( $last_pos->{y} + $STEP, -$XY_LIMIT, $XY_LIMIT );
    }
    elsif ( $key == SDLK_DOWN ) {
        $orbiting = 0;
        $last_pos->{y} = _clamp( $last_pos->{y} - $STEP, -$XY_LIMIT, $XY_LIMIT );
    }
    elsif ( $key == SDLK_PAGEUP ) {

        # Z is independent of the orbit -- you can raise/lower the source while
        # it circles the listener.
        $last_pos->{z} = _clamp( $last_pos->{z} + $STEP, -$Z_LIMIT, $Z_LIMIT );
    }
    elsif ( $key == SDLK_PAGEDOWN ) {
        $last_pos->{z} = _clamp( $last_pos->{z} - $STEP, -$Z_LIMIT, $Z_LIMIT );
    }
    return SDL_APP_CONTINUE;
}

# This function runs once per frame, and is the heart of the program.
sub SDL_AppIterate ($appstate) {

    # Advance the orbit by real elapsed time, not by frames, so it turns at the
    # same rate no matter what the callback rate is.
    my $now = SDL_GetTicksNS();
    my $dt  = $last_ns ? ( $now - $last_ns ) / 1_000_000_000.0 : 0.0;
    $last_ns = $now;
    if ( $orbiting && !$paused ) {
        $angle += $ORBIT_SPEED * $dt;
        $angle -= 6.283185307179586 if $angle >= 6.283185307179586;
        $last_pos->{x} = $radius * cos($angle);
        $last_pos->{y} = $radius * sin($angle);
    }
    _apply_position();

    # Draw the scene: an ellipse for the orbit, the listener, and the source dot.
    my ( $w, $h ) = ( 0, 0 );
    SDL_GetCurrentRenderOutputSize( $renderer, \$w, \$h );
    SDL_SetRenderDrawColor( $renderer, 16, 16, 24, 255 );
    SDL_RenderClear($renderer);
    my ( $cx, $cy, $scale ) = ( $w / 2, $h / 2, 80.0 );

    # The orbit, seen as an ellipse.
    SDL_SetRenderDrawColor( $renderer, 60, 60, 80, 255 );
    my $prev;
    for my $i ( 0 .. 120 ) {
        my $a = $i / 120 * 6.283185307179586;
        my $p = { x => $cx + $radius * cos($a) * $scale, y => $cy + $radius * sin($a) * $scale * 0.35 };
        SDL_RenderLine( $renderer, $prev->{x}, $prev->{y}, $p->{x}, $p->{y} ) if $prev;
        $prev = $p;
    }

    # The listener at the origin.
    SDL_SetRenderDrawColor( $renderer, 90, 90, 120, 255 );
    SDL_RenderFillRect( $renderer, { x => $cx - 4, y => $cy - 4, w => 8, h => 8 } );

    # The moving source (brighter when closer to the listener). The dot is
    # nudged up on screen as Z rises, so you can see height as well as x/y.
    my $dist = sqrt( $last_pos->{x}**2 + $last_pos->{y}**2 + $last_pos->{z}**2 );
    my $near = 1.0 / ( 1.0 + $dist );
    my $sx   = $cx + $last_pos->{x} * $scale;
    my $sy   = $cy - $last_pos->{y} * $scale * 0.35 - $last_pos->{z} * 8.0;
    SDL_SetRenderDrawColor( $renderer, int( 255 * $near ), 200, int( 255 * ( 1 - $near ) ), 255 );
    SDL_RenderFillRect( $renderer, { x => $sx - 6, y => $sy - 6, w => 12, h => 12 } );

    # Show the position SDL_mixer actually reports for the track.
    SDL_SetRenderDrawColor( $renderer, 220, 220, 220, 255 );
    SDL_RenderDebugText( $renderer, 12, 12, sprintf 'track 3D position  x=%.2f  y=%.2f  z=%.2f', @{$verified}{qw[x y z]} );
    SDL_RenderDebugText( $renderer, 12, 32, sprintf '%s%s', ( $orbiting ? 'orbit' : 'manual' ), ( $paused ? ' (paused)' : '' ) );
    SDL_RenderDebugText( $renderer, 12, 52, 'arrows move X/Y   PGUP/PGDN move Z   A orbit   SPACE pause   ESC quit' );
    SDL_RenderPresent($renderer);
    return SDL_APP_CONTINUE;
}

# This function runs once at shutdown.
sub SDL_AppQuit ( $appstate, $result ) {

    # SDL will clean up the window/renderer for us, MIX_Quit() destroys any mixer objects we made.
    MIX_Quit();
}
