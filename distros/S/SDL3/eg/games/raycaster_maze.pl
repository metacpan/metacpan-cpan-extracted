use v5.36;
use SDL3 qw[:all];
$|++;

# Cheap Raycaster Maze
#
# I was thinking a Duke Nukem type game but got better ideas before implementing jumps
#
# Controls:
#  - Move with the arrows (up, down, left, right) or with WASD
#
# Configuration
my $SCREEN_W = 640;
my $SCREEN_H = 480;
my $MAP_W    = 24;
my $MAP_H    = 24;

# Movement Settings
my $MOVE_SPEED = 0.009;    # Walk speed
my $ROT_SPEED  = 0.003;    # Turn speed

# Init SDL
SDL_Init(SDL_INIT_VIDEO);
my $win       = SDL_CreateWindow( 'Raycaster maze', $SCREEN_W, $SCREEN_H, 0 );
my $ren       = SDL_CreateRenderer( $win, undef );
my $event_ptr = Affix::malloc(128);

# World Map
# 1 = White Wall, 2 = Red Wall, 3 = Green Wall, 4 = Blue Wall, 0 = Empty
my @world_map = (
    [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
    [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 3, 0, 3, 0, 3, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 3, 0, 0, 0, 3, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 2, 2, 0, 2, 2, 0, 0, 0, 0, 3, 0, 3, 0, 3, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 4, 0, 4, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 4, 0, 0, 0, 0, 5, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 4, 0, 4, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 4, 0, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ]
);

# Player state
my $pos_x   = 22.0;
my $pos_y   = 12.0;
my $dir_x   = -1.0;
my $dir_y   = 0.0;
my $plane_x = 0.0;
my $plane_y = 0.66;                                            # The 2D Raycaster version of FOV
my $running = 1;
my %keys    = ( up => 0, down => 0, left => 0, right => 0 );

# FPS
my $last_time = SDL_GetTicks();
while ($running) {

    # Input
    while ( SDL_PollEvent($event_ptr) ) {
        my $h = Affix::cast( $event_ptr, SDL_CommonEvent );
        if    ( $h->{type} == SDL_EVENT_QUIT ) { $running = 0; }
        elsif ( $h->{type} == SDL_EVENT_KEY_DOWN || $h->{type} == SDL_EVENT_KEY_UP ) {
            my $k       = Affix::cast( $event_ptr, SDL_KeyboardEvent );
            my $is_down = ( $h->{type} == SDL_EVENT_KEY_DOWN ) ? 1 : 0;
            my $code    = $k->{scancode};
            if    ( $code == SDL_SCANCODE_LEFT || $code == SDL_SCANCODE_A )  { $keys{left}  = $is_down; }
            elsif ( $code == SDL_SCANCODE_RIGHT || $code == SDL_SCANCODE_D ) { $keys{right} = $is_down; }
            elsif ( $code == SDL_SCANCODE_W || $code == SDL_SCANCODE_UP )    { $keys{up}    = $is_down; }    # W or UP
            elsif ( $code == SDL_SCANCODE_S || $code == SDL_SCANCODE_DOWN )  { $keys{down}  = $is_down; }    # S or DOWN
            elsif ( $code == SDL_SCANCODE_ESCAPE )                           { $running     = 0; }
        }
    }

    # Move forward
    if ( $keys{up} ) {

        # Check X and Y independently to allow sliding along walls
        if ( $world_map[ int( $pos_x + $dir_x * $MOVE_SPEED ) ][ int($pos_y) ] == 0 ) {
            $pos_x += $dir_x * $MOVE_SPEED;
        }
        if ( $world_map[ int($pos_x) ][ int( $pos_y + $dir_y * $MOVE_SPEED ) ] == 0 ) {
            $pos_y += $dir_y * $MOVE_SPEED;
        }
    }

    # Move backward
    if ( $keys{down} ) {
        if ( $world_map[ int( $pos_x - $dir_x * $MOVE_SPEED ) ][ int($pos_y) ] == 0 ) {
            $pos_x -= $dir_x * $MOVE_SPEED;
        }
        if ( $world_map[ int($pos_x) ][ int( $pos_y - $dir_y * $MOVE_SPEED ) ] == 0 ) {
            $pos_y -= $dir_y * $MOVE_SPEED;
        }
    }

    # Rotate right
    if ( $keys{right} ) {
        my $old_dir_x = $dir_x;
        $dir_x = $dir_x * cos( -$ROT_SPEED ) - $dir_y * sin( -$ROT_SPEED );
        $dir_y = $old_dir_x * sin( -$ROT_SPEED ) + $dir_y * cos( -$ROT_SPEED );
        my $old_plane_x = $plane_x;
        $plane_x = $plane_x * cos( -$ROT_SPEED ) - $plane_y * sin( -$ROT_SPEED );
        $plane_y = $old_plane_x * sin( -$ROT_SPEED ) + $plane_y * cos( -$ROT_SPEED );
    }

    # Rotate left
    if ( $keys{left} ) {
        my $old_dir_x = $dir_x;
        $dir_x = $dir_x * cos($ROT_SPEED) - $dir_y * sin($ROT_SPEED);
        $dir_y = $old_dir_x * sin($ROT_SPEED) + $dir_y * cos($ROT_SPEED);
        my $old_plane_x = $plane_x;
        $plane_x = $plane_x * cos($ROT_SPEED) - $plane_y * sin($ROT_SPEED);
        $plane_y = $old_plane_x * sin($ROT_SPEED) + $plane_y * cos($ROT_SPEED);
    }

    # Render
    # Clear ceiling (dark grey) and floor (black)
    SDL_SetRenderDrawColor( $ren, 25, 25, 25, 255 );
    SDL_RenderClear($ren);

    # Raycasting loop
    for my $x ( 0 .. $SCREEN_W - 1 ) {

        # Calculate ray position and direction
        my $camera_x  = 2 * $x / $SCREEN_W - 1;          # x-coordinate in camera space
        my $ray_dir_x = $dir_x + $plane_x * $camera_x;
        my $ray_dir_y = $dir_y + $plane_y * $camera_x;

        # Which box of the map we're in
        my $map_x = int($pos_x);
        my $map_y = int($pos_y);

        # Length of ray from current position to next x or y-side
        my ( $side_dist_x, $side_dist_y );

        # Length of ray from one x or y-side to next x or y-side
        # Avoid div by zero
        my $delta_dist_x = ( $ray_dir_x == 0 ) ? 1e30 : abs( 1 / $ray_dir_x );
        my $delta_dist_y = ( $ray_dir_y == 0 ) ? 1e30 : abs( 1 / $ray_dir_y );
        my $perp_wall_dist;

        # Direction to step in x or y direction (either +1 or -1)
        my ( $step_x, $step_y );
        my $hit = 0;
        my $side;    # was a NS or a EW wall hit?

        # Calculate step and initial sideDist
        if ( $ray_dir_x < 0 ) {
            $step_x      = -1;
            $side_dist_x = ( $pos_x - $map_x ) * $delta_dist_x;
        }
        else {
            $step_x      = 1;
            $side_dist_x = ( $map_x + 1.0 - $pos_x ) * $delta_dist_x;
        }
        if ( $ray_dir_y < 0 ) {
            $step_y      = -1;
            $side_dist_y = ( $pos_y - $map_y ) * $delta_dist_y;
        }
        else {
            $step_y      = 1;
            $side_dist_y = ( $map_y + 1.0 - $pos_y ) * $delta_dist_y;
        }

        # Perform DDA
        while ( $hit == 0 ) {

            # jump to next map square, OR in x-direction, OR in y-direction
            if ( $side_dist_x < $side_dist_y ) {
                $side_dist_x += $delta_dist_x;
                $map_x       += $step_x;
                $side = 0;
            }
            else {
                $side_dist_y += $delta_dist_y;
                $map_y       += $step_y;
                $side = 1;
            }

            # Check if ray has hit a wall
            if ( $world_map[$map_x][$map_y] > 0 ) {
                $hit = 1;
            }
        }

        # Calculate distance projected on camera direction
        # (Euclidean distance will give fisheye effect!)
        if ( $side == 0 ) {
            $perp_wall_dist = ( $side_dist_x - $delta_dist_x );
        }
        else {
            $perp_wall_dist = ( $side_dist_y - $delta_dist_y );
        }

        # Calculate height of line to draw on screen
        my $line_height = int( $SCREEN_H / $perp_wall_dist );

        # Calculate lowest and highest pixel to fill in current stripe
        my $draw_start = -$line_height / 2 + $SCREEN_H / 2;
        if ( $draw_start < 0 ) { $draw_start = 0; }
        my $draw_end = $line_height / 2 + $SCREEN_H / 2;
        if ( $draw_end >= $SCREEN_H ) { $draw_end = $SCREEN_H - 1; }

        # Choose wall color based on map value
        my $wall_type = $world_map[$map_x][$map_y];
        my ( $r, $g, $b ) = ( 255, 255, 255 );                               # Default white
        if    ( $wall_type == 2 ) { ( $r, $g, $b ) = ( 200, 0,   0 ); }      # Red
        elsif ( $wall_type == 3 ) { ( $r, $g, $b ) = ( 0,   200, 0 ); }      # Green
        elsif ( $wall_type == 4 ) { ( $r, $g, $b ) = ( 0,   0,   200 ); }    # Blue
        elsif ( $wall_type == 5 ) { ( $r, $g, $b ) = ( 200, 0,   200 ); }    # Magenta (Secret box!)

        # Give x and y sides different brightness for pseudo-lighting
        if ( $side == 1 ) {
            $r /= 2;
            $g /= 2;
            $b /= 2;
        }

        # Draw the pixels of the stripe as a vertical line
        SDL_SetRenderDrawColor( $ren, int($r), int($g), int($b), 255 );
        SDL_RenderLine( $ren, $x, $draw_start, $x, $draw_end );
    }

    # Frame Timing
    my $curr_time = SDL_GetTicks();
    my $delta     = $curr_time - $last_time;
    $last_time = $curr_time;
    my $fps = int( 1000 / ( $delta || 1 ) );
    SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
    SDL_RenderDebugText( $ren, 10, 10, 'FPS: ' . $fps );
    SDL_RenderPresent($ren);
}
SDL_DestroyRenderer($ren);
SDL_DestroyWindow($win);
SDL_Quit();
