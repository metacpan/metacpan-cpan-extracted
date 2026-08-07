
=pod

=for html <center><img src="https://raw.githubusercontent.com/Perl-SDL3/.github/refs/heads/main/screenshots/tetris.gif" /></center>

=cut

use v5.40;
use SDL3 qw[:all :main];

# Tetris
#
# Classic tetromino stacking with score, next-piece preview and landing shadow
#
# Controls:
#  - Left/Right to move, Down for soft drop
#  - Up to rotate, Space to hard drop
#  - P to pause, R to restart (on game over)
# Game Constants
use constant GRID_W    => 10;
use constant GRID_H    => 20;
use constant CELL      => 24;
use constant SIDEBAR   => 160;
use constant NEXT_CELL => 18;
my ( $window, $renderer );
my @grid;    # [y][x]
my $current_piece;
my $next_idx;
my $last_step = 0;
my $score     = 0;
my $game_over = 0;
my $paused    = 0;

# Tetrominoes: [Shape][Rotation][y][x] with matching colors
my @shapes = (
    [ [ [ 1, 1, 1, 1 ] ], [ [1], [1], [1], [1] ] ],                                                                                        # I
    [ [ [ 1, 1 ], [ 1, 1 ] ] ],                                                                                                            # O
    [ [ [ 0, 1, 0 ], [ 1, 1, 1 ] ], [ [ 1, 0 ], [ 1, 1 ], [ 1, 0 ] ], [ [ 1, 1, 1 ], [ 0, 1, 0 ] ], [ [ 0, 1 ], [ 1, 1 ], [ 0, 1 ] ] ],    # T
    [ [ [ 0, 1, 1 ], [ 1, 1, 0 ] ], [ [ 1, 0 ], [ 1, 1 ], [ 0, 1 ] ] ],                                                                    # S
    [ [ [ 1, 1, 0 ], [ 0, 1, 1 ] ], [ [ 0, 1 ], [ 1, 1 ], [ 1, 0 ] ] ],                                                                    # Z
    [ [ [ 1, 0, 0 ], [ 1, 1, 1 ] ], [ [ 1, 1 ], [ 1, 0 ], [ 1, 0 ] ], [ [ 1, 1, 1 ], [ 0, 0, 1 ] ], [ [ 0, 1 ], [ 0, 1 ], [ 1, 1 ] ] ],    # J
    [ [ [ 0, 0, 1 ], [ 1, 1, 1 ] ], [ [ 1, 0 ], [ 1, 0 ], [ 1, 1 ] ], [ [ 1, 1, 1 ], [ 1, 0, 0 ] ], [ [ 1, 1 ], [ 0, 1 ], [ 0, 1 ] ] ]     # L
);
my @shape_colors = (
    [ 0,   240, 240 ],                                                                                                                     # I
    [ 240, 240, 0 ],                                                                                                                       # O
    [ 160, 0,   240 ],                                                                                                                     # T
    [ 0,   240, 0 ],                                                                                                                       # S
    [ 240, 0,   0 ],                                                                                                                       # Z
    [ 0,   0,   240 ],                                                                                                                     # J
    [ 240, 160, 0 ]                                                                                                                        # L
);

sub spawn_piece {
    $next_idx      = int( rand(@shapes) ) unless defined $next_idx;
    $current_piece = { shape => $shapes[$next_idx], rot => 0, x => int( GRID_W / 2 ) - 1, y => 0, color => $shape_colors[$next_idx] };
    $next_idx      = int( rand(@shapes) );
    $game_over     = 1 if check_collision( $current_piece, 0, 0 );
}

sub check_collision ( $piece, $dx, $dy, $dr = 0 ) {
    my $new_rot = ( $piece->{rot} + $dr ) % scalar( @{ $piece->{shape} } );
    my $matrix  = $piece->{shape}[$new_rot];
    my $new_x   = $piece->{x} + $dx;
    my $new_y   = $piece->{y} + $dy;
    my $h       = scalar(@$matrix);
    my $w       = scalar( @{ $matrix->[0] } );
    for my $y ( 0 .. $h - 1 ) {
        for my $x ( 0 .. $w - 1 ) {
            next unless $matrix->[$y][$x];
            my $gx = $new_x + $x;
            my $gy = $new_y + $y;
            return 1 if $gx < 0 || $gx >= GRID_W || $gy >= GRID_H;
            return 1 if $gy >= 0 && $grid[$gy][$gx];
        }
    }
    return 0;
}

sub drop_distance ($piece) {
    my $dy = 0;
    $dy++ while !check_collision( $piece, 0, $dy + 1 );
    $dy;
}

sub lock_piece {
    my $matrix = $current_piece->{shape}[ $current_piece->{rot} ];
    for my $y ( 0 .. scalar(@$matrix) - 1 ) {
        for my $x ( 0 .. scalar( @{ $matrix->[0] } ) - 1 ) {
            next unless $matrix->[$y][$x];
            $grid[ $current_piece->{y} + $y ][ $current_piece->{x} + $x ] = $current_piece->{color};
        }
    }

    # Clear lines
    my $cleared = 0;
    for ( my $y = GRID_H - 1; $y >= 0; $y-- ) {
        if ( scalar( grep {$_} @{ $grid[$y] } ) == GRID_W ) {
            splice @grid, $y, 1;
            unshift @grid, [ (undef) x GRID_W ];
            $cleared++;
            $y++;    # Check same index again
        }
    }
    my @points = ( 0, 100, 300, 500, 800 );
    $score += $points[ $cleared <= 4 ? $cleared : 4 ];
    spawn_piece();
}

sub restart {
    @grid      = map { [ (undef) x GRID_W ] } ( 1 .. GRID_H );
    $score     = 0;
    $game_over = 0;
    $paused    = 0;
    $next_idx  = int( rand(@shapes) );
    spawn_piece();
}

sub draw_cells ( $mx, $my, $size ) {
    my $matrix = $current_piece->{shape}[ $current_piece->{rot} ];
    for my $y ( 0 .. scalar(@$matrix) - 1 ) {
        for my $x ( 0 .. scalar( @{ $matrix->[0] } ) - 1 ) {
            next unless $matrix->[$y][$x];
            SDL_RenderFillRect( $renderer, { x => ( $mx + $x ) * $size, y => ( $my + $y ) * $size, w => $size - 1, h => $size - 1 } );
        }
    }
}

sub SDL_AppInit ( $appstate, $argc, $argv ) {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_CreateWindowAndRenderer( 'SDL3 Tetris', GRID_W * CELL + SIDEBAR, GRID_H * CELL, 0, \$window, \$renderer );
    @grid = map { [ (undef) x GRID_W ] } ( 1 .. GRID_H );
    spawn_piece();
    return SDL_APP_CONTINUE;
}

sub SDL_AppIterate ($appstate) {
    my $now = SDL_GetTicks();
    if ( !$game_over && !$paused && $now - $last_step > 500 ) {
        if ( check_collision( $current_piece, 0, 1 ) ) {
            lock_piece();
        }
        else {
            $current_piece->{y}++;
        }
        $last_step = $now;
    }
    SDL_SetRenderDrawColor( $renderer, 20, 20, 20, 255 );
    SDL_RenderClear($renderer);

    # Draw Grid
    for my $y ( 0 .. GRID_H - 1 ) {
        for my $x ( 0 .. GRID_W - 1 ) {
            if ( $grid[$y][$x] ) {
                SDL_SetRenderDrawColor( $renderer, @{ $grid[$y][$x] }, 255 );
                SDL_RenderFillRect( $renderer, { x => $x * CELL, y => $y * CELL, w => CELL - 1, h => CELL - 1 } );
            }
        }
    }

    # Thin grid lines for alignment
    SDL_SetRenderDrawColor( $renderer, 45, 45, 45, 255 );
    for my $i ( 0 .. GRID_W ) {
        SDL_RenderLine( $renderer, $i * CELL, 0, $i * CELL, GRID_H * CELL );
    }
    for my $j ( 0 .. GRID_H ) {
        SDL_RenderLine( $renderer, 0, $j * CELL, GRID_W * CELL, $j * CELL );
    }

    # Draw Shadow (ghost of where the current piece will land)
    if ( !$game_over ) {
        my $drop = drop_distance($current_piece);
        SDL_SetRenderDrawBlendMode( $renderer, SDL_BLENDMODE_BLEND );
        SDL_SetRenderDrawColor( $renderer, @{ $current_piece->{color} }, 40 );
        draw_cells( $current_piece->{x}, $current_piece->{y} + $drop, CELL );
        SDL_SetRenderDrawBlendMode( $renderer, SDL_BLENDMODE_NONE );
    }

    # Draw Current Piece
    SDL_SetRenderDrawColor( $renderer, @{ $current_piece->{color} }, 255 );
    draw_cells( $current_piece->{x}, $current_piece->{y}, CELL );

    # Draw Sidebar
    my $sx = GRID_W * CELL;
    SDL_SetRenderDrawColor( $renderer, 28, 28, 28, 255 );
    SDL_RenderFillRect( $renderer, { x => $sx, y => 0, w => SIDEBAR, h => GRID_H * CELL } );
    SDL_SetRenderDrawColor( $renderer, 60, 60, 60, 255 );
    SDL_RenderRect( $renderer, { x => $sx, y => 0, w => 1, h => GRID_H * CELL } );
    SDL_SetRenderDrawColor( $renderer, 230, 230, 230, 255 );
    SDL_RenderDebugText( $renderer, $sx + 16, 12, 'NEXT' );

    # Next Piece Preview
    SDL_SetRenderDrawColor( $renderer, 60, 60, 60, 255 );
    SDL_RenderRect( $renderer, { x => $sx + 16, y => 36, w => 128, h => 96 } );
    my $matrix = $shapes[$next_idx][0];
    my $mw     = scalar( @{ $matrix->[0] } );
    my $mh     = scalar(@$matrix);
    my $off_x  = int( ( 128 - $mw * NEXT_CELL ) / 2 );
    my $off_y  = int( ( 96 - $mh * NEXT_CELL ) / 2 );
    SDL_SetRenderDrawColor( $renderer, @{ $shape_colors[$next_idx] }, 255 );

    for my $y ( 0 .. $mh - 1 ) {
        for my $x ( 0 .. $mw - 1 ) {
            next unless $matrix->[$y][$x];
            SDL_RenderFillRect( $renderer,
                { x => $sx + 16 + $off_x + $x * NEXT_CELL, y => 36 + $off_y + $y * NEXT_CELL, w => NEXT_CELL - 1, h => NEXT_CELL - 1 } );
        }
    }

    # Score
    SDL_SetRenderDrawColor( $renderer, 230, 230, 230, 255 );
    SDL_RenderDebugText( $renderer, $sx + 16, 160, 'SCORE' );
    SDL_RenderDebugText( $renderer, $sx + 16, 182, "$score" );
    if ($paused) {
        SDL_SetRenderDrawColor( $renderer, 230, 230, 230, 255 );
        SDL_RenderDebugText( $renderer, 60, 200, 'PAUSED' );
        SDL_RenderDebugText( $renderer, 60, 222, 'Press P to resume' );
    }
    if ($game_over) {
        SDL_SetRenderDrawColor( $renderer, 230, 60, 60, 255 );
        SDL_RenderDebugText( $renderer, 60, 200, 'GAME OVER' );
        SDL_SetRenderDrawColor( $renderer, 230, 230, 230, 255 );
        SDL_RenderDebugText( $renderer, 60, 222, "Score: $score" );
        SDL_RenderDebugText( $renderer, 60, 244, 'Press R to restart' );
    }
    SDL_RenderPresent($renderer);
    return SDL_APP_CONTINUE;
}

sub SDL_AppEvent ( $appstate, $event ) {
    return SDL_APP_SUCCESS if $event->{type} == SDL_EVENT_QUIT;
    if ( $event->{type} == SDL_EVENT_KEY_DOWN ) {
        my $key = $event->{key}{scancode};
        if ( $key == SDL_SCANCODE_P ) {
            $paused = !$paused;
        }
        elsif ( $key == SDL_SCANCODE_R && $game_over ) {
            restart();
        }
        elsif ( !$game_over && !$paused ) {
            if ( $key == SDL_SCANCODE_LEFT && !check_collision( $current_piece, -1, 0 ) ) {
                $current_piece->{x}--;
            }
            elsif ( $key == SDL_SCANCODE_RIGHT && !check_collision( $current_piece, 1, 0 ) ) {
                $current_piece->{x}++;
            }
            elsif ( $key == SDL_SCANCODE_DOWN && !check_collision( $current_piece, 0, 1 ) ) {
                $current_piece->{y}++;
                $score += 1;    # Soft drop bonus
            }
            elsif ( $key == SDL_SCANCODE_UP ) {
                $current_piece->{rot} = ( $current_piece->{rot} + 1 ) % scalar( @{ $current_piece->{shape} } );
                $current_piece->{rot}-- if check_collision( $current_piece, 0, 0 );
            }
            elsif ( $key == SDL_SCANCODE_SPACE ) {
                $current_piece->{y} += drop_distance($current_piece);
                lock_piece();
                $last_step = SDL_GetTicks();
            }
        }
    }
    return SDL_APP_CONTINUE;
}

sub SDL_AppQuit ( $appstate, $result ) {
    SDL_DestroyRenderer($renderer);
    SDL_DestroyWindow($window);
    SDL_Quit();
}
