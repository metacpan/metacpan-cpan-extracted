use v5.36;
use Affix qw[Float Pointer sizeof];
use SDL3  qw[:all];

# Isometric scene toy
#
# My goal is a transport tycoon type game but it looks more like a garbage minecraft right now.
#
# Controls:
#  - Click to raise a grid position.
#  - Shift click to lower a grid position
#  - Right click and drag to move/rotate the map
#  - Scroll the mouse wheel to zoom in/out
#  - Hit 'W' to toggle between normal and a (work in progress) wireframe version
#
# Config
my $SCREEN_W       = 1024;
my $SCREEN_H       = 768;
my $MAP_SIZE       = 12;
my $BASE_TILE_SIZE = 50;

# View State
my $zoom      = 1.0;
my $angle     = 0.785;           # Yaw (Rotation)
my $phi       = 0.785;           # Pitch (Elevation)
my $offset_x  = $SCREEN_W / 2;
my $offset_y  = $SCREEN_H / 2;
my $wireframe = 0;

# Drag state
my $is_dragging      = 0;
my $drag_start_angle = 0;
my $drag_base_angle  = 0;
my $drag_start_y     = 0;
my $drag_base_phi    = 0;
#
die SDL_GetError() unless SDL_Init(SDL_INIT_VIDEO);
my $win        = SDL_CreateWindow( 'Just Another Perl Tycoon, ', $SCREEN_W, $SCREEN_H, 0 );
my $ren        = SDL_CreateRenderer( $win, undef );
my $event_ptr  = Affix::malloc(128);
my $quad_verts = Affix::calloc( 6, sizeof(SDL_Vertex) );                                      # Persistent buffer
my $qv_addr    = Affix::address($quad_verts);
my $QV_STRIDE  = sizeof(SDL_Vertex);                                                          # 32 bytes

# Pinned float views for fast direct writes into the vertex buffer
my ( @qv_px, @qv_py, @qv_r, @qv_g, @qv_b, @qv_a );
for my $i ( 0 .. 5 ) {
    my $base = $qv_addr + ( $i * $QV_STRIDE );
    $qv_px[$i] = Affix::cast( $base + 0,  Pointer [Float] );
    $qv_py[$i] = Affix::cast( $base + 4,  Pointer [Float] );
    $qv_r[$i]  = Affix::cast( $base + 8,  Pointer [Float] );
    $qv_g[$i]  = Affix::cast( $base + 12, Pointer [Float] );
    $qv_b[$i]  = Affix::cast( $base + 16, Pointer [Float] );
    $qv_a[$i]  = Affix::cast( $base + 20, Pointer [Float] );
}

# Map data
my @map;
for my $y ( 0 .. $MAP_SIZE - 1 ) {
    for my $x ( 0 .. $MAP_SIZE - 1 ) {
        $map[$y][$x] = 0;
    }
}
$map[5][5] = 1;
$map[6][6] = 2;
$map[5][6] = 1;
$map[6][5] = 3;

# Tile math for iso-like projection
sub project_with_depth ( $gx, $gy, $z ) {
    my $cx    = ( $gx - $MAP_SIZE / 2 );
    my $cy    = ( $gy - $MAP_SIZE / 2 );
    my $scale = $BASE_TILE_SIZE * $zoom;
    my $wx    = $cx * $scale;
    my $wy    = $cy * $scale;
    my $rot_x = $wx * cos($angle) - $wy * sin($angle);
    my $rot_y = $wx * sin($angle) + $wy * cos($angle);
    my $iso_x = $rot_x;
    my $iso_y = $rot_y * sin($phi);
    my $sx    = $iso_x + $offset_x;
    my $sy    = $iso_y + $offset_y - ( $z * $scale * cos($phi) );
    return ( $sx, $sy, $rot_y );
}

sub unproject ( $sx, $sy ) {
    my $iso_x = $sx - $offset_x;
    my $iso_y = $sy - $offset_y;
    my $rot_x = $iso_x;
    my $rot_y = $iso_y / ( sin($phi) || 0.001 );
    my $wx    = $rot_x * cos( -$angle ) - $rot_y * sin( -$angle );
    my $wy    = $rot_x * sin( -$angle ) + $rot_y * cos( -$angle );
    my $scale = $BASE_TILE_SIZE * $zoom;
    my $cx    = $wx / $scale;
    my $cy    = $wy / $scale;
    return ( int( $cx + $MAP_SIZE / 2 + 0.5 ), int( $cy + $MAP_SIZE / 2 + 0.5 ) );
}

# Calculate angle of mouse relative to screen center
sub get_mouse_angle ( $mx, $my ) {
    atan2 $my - $offset_y, $mx - $offset_x;
}

# Rendering
sub draw_quad_fill ( $c, $p1, $p2, $p3, $p4 ) {
    my ( $r, $g, $b ) = @$c;
    my @pos = ( $p1, $p2, $p3, $p1, $p3, $p4 );
    for my $i ( 0 .. 5 ) {
        my $pinx = $qv_px[$i];
        my $piny = $qv_py[$i];
        my $pinr = $qv_r[$i];
        my $ping = $qv_g[$i];
        my $pinb = $qv_b[$i];
        my $pina = $qv_a[$i];
        $$pinx = $pos[$i][0];
        $$piny = $pos[$i][1];
        $$pinr = $r / 255.0;
        $$ping = $g / 255.0;
        $$pinb = $b / 255.0;
        $$pina = 1.0;
    }
    SDL_RenderGeometry( $ren, undef, $quad_verts, 6, undef, 0 );
}

sub draw_block ( $gx, $gy, $z, $color ) {
    my ( $r, $g, $b ) = @$color;
    my ( $p1x, $p1y ) = project_with_depth( $gx - 0.5, $gy - 0.5, $z );
    my ( $p2x, $p2y ) = project_with_depth( $gx + 0.5, $gy - 0.5, $z );
    my ( $p3x, $p3y ) = project_with_depth( $gx + 0.5, $gy + 0.5, $z );
    my ( $p4x, $p4y ) = project_with_depth( $gx - 0.5, $gy + 0.5, $z );
    if ($wireframe) {
        SDL_SetRenderDrawColor( $ren, $r, $g, $b, 255 );
        SDL_RenderLine( $ren, $p1x, $p1y, $p2x, $p2y );
        SDL_RenderLine( $ren, $p2x, $p2y, $p3x, $p3y );
        SDL_RenderLine( $ren, $p3x, $p3y, $p4x, $p4y );
        SDL_RenderLine( $ren, $p4x, $p4y, $p1x, $p1y );
        if ( $z > 0 ) {
            my ( $b2x, $b2y ) = project_with_depth( $gx + 0.5, $gy - 0.5, 0 );
            my ( $b3x, $b3y ) = project_with_depth( $gx + 0.5, $gy + 0.5, 0 );
            my ( $b4x, $b4y ) = project_with_depth( $gx - 0.5, $gy + 0.5, 0 );
            SDL_RenderLine( $ren, $p2x, $p2y, $b2x, $b2y );
            SDL_RenderLine( $ren, $p3x, $p3y, $b3x, $b3y );
            SDL_RenderLine( $ren, $p4x, $p4y, $b4x, $b4y );
        }
    }
    else {
        draw_quad_fill( $color, [ $p1x, $p1y ], [ $p2x, $p2y ], [ $p3x, $p3y ], [ $p4x, $p4y ] );
        if ( $z > 0 ) {

            # Face Culling
            my ( undef, undef, $d1 ) = project_with_depth( $gx - 0.5, $gy - 0.5, 0 );
            my ( undef, undef, $d2 ) = project_with_depth( $gx + 0.5, $gy - 0.5, 0 );
            my ( undef, undef, $d3 ) = project_with_depth( $gx + 0.5, $gy + 0.5, 0 );
            my ( undef, undef, $d4 ) = project_with_depth( $gx - 0.5, $gy + 0.5, 0 );
            my ( $b1x, $b1y )        = project_with_depth( $gx - 0.5, $gy - 0.5, 0 );
            my ( $b2x, $b2y )        = project_with_depth( $gx + 0.5, $gy - 0.5, 0 );
            my ( $b3x, $b3y )        = project_with_depth( $gx + 0.5, $gy + 0.5, 0 );
            my ( $b4x, $b4y )        = project_with_depth( $gx - 0.5, $gy + 0.5, 0 );
            my $c_dark   = [ int( $r * 0.7 ), int( $g * 0.7 ), int( $b * 0.7 ) ];
            my $c_shadow = [ int( $r * 0.5 ), int( $g * 0.5 ), int( $b * 0.5 ) ];
            my $max_d    = $d1;
            my $corner   = 1;
            if ( $d2 > $max_d ) { $max_d = $d2; $corner = 2; }
            if ( $d3 > $max_d ) { $max_d = $d3; $corner = 3; }
            if ( $d4 > $max_d ) { $max_d = $d4; $corner = 4; }

            if ( $corner == 1 ) {
                draw_quad_fill( $c_shadow, [ $p1x, $p1y ], [ $p2x, $p2y ], [ $b2x, $b2y ], [ $b1x, $b1y ] );
                draw_quad_fill( $c_dark,   [ $p4x, $p4y ], [ $p1x, $p1y ], [ $b1x, $b1y ], [ $b4x, $b4y ] );
            }
            elsif ( $corner == 2 ) {
                draw_quad_fill( $c_shadow, [ $p1x, $p1y ], [ $p2x, $p2y ], [ $b2x, $b2y ], [ $b1x, $b1y ] );
                draw_quad_fill( $c_dark,   [ $p2x, $p2y ], [ $p3x, $p3y ], [ $b3x, $b3y ], [ $b2x, $b2y ] );
            }
            elsif ( $corner == 3 ) {
                draw_quad_fill( $c_shadow, [ $p4x, $p4y ], [ $p3x, $p3y ], [ $b3x, $b3y ], [ $b4x, $b4y ] );
                draw_quad_fill( $c_dark,   [ $p2x, $p2y ], [ $p3x, $p3y ], [ $b3x, $b3y ], [ $b2x, $b2y ] );
            }
            elsif ( $corner == 4 ) {
                draw_quad_fill( $c_shadow, [ $p4x, $p4y ], [ $p3x, $p3y ], [ $b3x, $b3y ], [ $b4x, $b4y ] );
                draw_quad_fill( $c_dark,   [ $p4x, $p4y ], [ $p1x, $p1y ], [ $b1x, $b1y ], [ $b4x, $b4y ] );
            }
        }
    }
}

# Main loop
my $running = 1;
my $ptr_mx  = Affix::malloc(4);
my $ptr_my  = Affix::malloc(4);
while ($running) {
    while ( SDL_PollEvent($event_ptr) ) {
        my $hdr = Affix::cast( $event_ptr, SDL_CommonEvent );
        if    ( $hdr->{type} == SDL_EVENT_QUIT ) { $running = 0; }
        elsif ( $hdr->{type} == SDL_EVENT_KEY_DOWN ) {
            my $k = Affix::cast( $event_ptr, SDL_KeyboardEvent );
            if ( $k->{scancode} == SDL_SCANCODE_W ) { $wireframe = !$wireframe; }
        }
        elsif ( $hdr->{type} == SDL_EVENT_MOUSE_WHEEL ) {
            my $w = Affix::cast( $event_ptr, SDL_MouseWheelEvent );
            $zoom += ( $w->{y} * 0.1 );
            if ( $zoom < 0.2 ) { $zoom = 0.2; }
            if ( $zoom > 3.0 ) { $zoom = 3.0; }
        }
        elsif ( $hdr->{type} == SDL_EVENT_MOUSE_BUTTON_DOWN ) {
            my $b = Affix::cast( $event_ptr, SDL_MouseButtonEvent );
            if ( $b->{button} == SDL_BUTTON_RIGHT ) {
                $is_dragging = 1;

                # Capture start state for drag
                $drag_start_angle = get_mouse_angle( $b->{x}, $b->{y} );
                $drag_base_angle  = $angle;
                $drag_start_y     = $b->{y};
                $drag_base_phi    = $phi;
            }
        }
        elsif ( $hdr->{type} == SDL_EVENT_MOUSE_BUTTON_UP ) {
            my $b = Affix::cast( $event_ptr, SDL_MouseButtonEvent );
            if ( $b->{button} == SDL_BUTTON_RIGHT ) { $is_dragging = 0; }
        }
        elsif ( $hdr->{type} == SDL_EVENT_MOUSE_MOTION ) {
            my $m = Affix::cast( $event_ptr, SDL_MouseMotionEvent );
            if ($is_dragging) {

                # Update rotation (yaw)
                # New angle = base + (current mouse angle - start mouse angle)
                my $cur_mouse_angle = get_mouse_angle( $m->{x}, $m->{y} );
                $angle = $drag_base_angle + ( $cur_mouse_angle - $drag_start_angle );

                # Update pitch
                # Linear drag based on Y distance from start click
                # Dragging DOWN (positive Y) increases pitch (top-down view)
                my $dy = $m->{y} - $drag_start_y;
                $phi = $drag_base_phi + ( $dy * 0.005 );

                # Clamp pitch so we don't end up in the upside-down
                if ( $phi < 0.1 ) { $phi = 0.1; }
                if ( $phi > 1.5 ) { $phi = 1.5; }
            }
        }
    }

    # Logic
    SDL_GetMouseState( $ptr_mx, $ptr_my );
    my $mx  = Affix::cast( $ptr_mx, Float );
    my $my  = Affix::cast( $ptr_my, Float );
    my $mod = SDL_GetModState();
    my ( $hx, $hy ) = unproject( $mx, $my );
    if ( $hx >= 0 && $hx < $MAP_SIZE && $hy >= 0 && $hy < $MAP_SIZE ) {
        my $mask = SDL_GetMouseState( $ptr_mx, $ptr_my );
        if ( $mask & SDL_BUTTON_LMASK ) {
            if ( $mod & SDL_KMOD_SHIFT ) {
                if ( $map[$hy][$hx] > 0 ) { $map[$hy][$hx] -= 0.1; }
            }
            else {
                $map[$hy][$hx] += 0.1;
            }
        }
    }

    # Render
    SDL_SetRenderDrawColor( $ren, 20, 20, 30, 255 );
    SDL_RenderClear($ren);
    my @render_list;
    for my $y ( 0 .. $MAP_SIZE - 1 ) {
        for my $x ( 0 .. $MAP_SIZE - 1 ) {
            my ( undef, undef, $depth ) = project_with_depth( $x, $y, 0 );
            push @render_list, { x => $x, y => $y, h => $map[$y][$x], depth => $depth };
        }
    }
    @render_list = sort { $a->{depth} <=> $b->{depth} } @render_list;
    foreach my $block (@render_list) {
        my $x   = $block->{x};
        my $y   = $block->{y};
        my $col = [ 100, 200, 100 ];
        if ( $x == $hx && $y == $hy ) { $col = [ 255, 255, 0 ]; }
        draw_block( $x, $y, $block->{h}, $col );
    }
    SDL_RenderPresent($ren);
    SDL_Delay(16);
}
SDL_DestroyRenderer($ren);
SDL_DestroyWindow($win);
SDL_Quit();
