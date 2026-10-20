use v5.40;
use feature 'class';
no warnings 'experimental::class';
use lib '../../lib';
use SDL3 qw[:all];
$|++;

# SDL3 port of foolish4's OpenGL/GLFW port of tsoding's JAI rope demo
#
# A chain of eight knots trails behind a head; click the red knot and drag it with the mouse and
# the rest of the rope chases after it. The world keeps the original's Cartesian ("simp")
# coordinates where Y grows upward; the mouse is flipped into that space on input and back into
# SDL's top-down coordinates at render time.
#
# Controls: ESC or q to quit. Click the red knot to grab it then drag it around.
#
# See also:
#  - https://github.com/tsoding/rope-jai/blob/master/main.jai
#  - https://github.com/foolish4/perl_pack/blob/main/rope.pl
use constant {
    WINDOW_WIDTH      => 800,
    WINDOW_HEIGHT     => 450,
    CIRCLE_RESOLUTION => 30,
    KNOT_RADIUS       => 30,
    TARGET_DISTANCE   => 100,
    ELASTICITY        => 50,
    TAIL_LENGTH       => 8,
    PI                => 3.14159,
    EPSILON           => 0.000001
};

class Vector2 {
    field $x : param : reader : writer //= 0;
    field $y : param : reader : writer //= 0;
    #
    method length () { sqrt( $x**2 + $y**2 ) }
    method plus   ($other)  { Vector2->new( x => $x + $other->x, y => $y + $other->y ) }
    method minus  ($other)  { Vector2->new( x => $x - $other->x, y => $y - $other->y ) }
    method scaled ($factor) { Vector2->new( x => $x * $factor,   y => $y * $factor ) }

    method move ( $dx, $dy ) {
        $x += $dx;
        $y += $dy;
    }
}

# All geometry is accumulated here each frame as colored vertices and drawn with a single
# SDL_RenderGeometry() call. The current color is the one set by the most recent assignment.
my $current_color = { r => 0.5, g => 0.5, b => 0.5 };
my @verts;

sub simp_immediate_triangle ( $v2a, $v2b, $v2c ) {
    push @verts, map { { position => { x => $_->x, y => WINDOW_HEIGHT - $_->y }, color => $current_color, tex_coord => { x => 0, y => 0 } } } $v2a,
        $v2b, $v2c;
}

sub immediate_thicc_line ( $p0, $p1, $t ) {
    my $v1  = Vector2->new( x => $p1->x - $p0->x, y => $p1->y - $p0->y );
    my $v2  = Vector2->new( x => -$v1->y,         y => $v1->x );
    my $len = $v2->length;
    return if $len <= EPSILON;
    my $offset = $v2->scaled( ( $t / 2 ) / $len );
    simp_immediate_triangle( $p0->plus($offset), $p0->minus($offset), $p1->minus($offset) );
    simp_immediate_triangle( $p0->plus($offset), $p1->minus($offset), $p1->plus($offset) );
}

sub immediate_circle ( $center, $radius ) {
    my $step_angle = 2 * PI / CIRCLE_RESOLUTION;
    for my $i ( 0 .. CIRCLE_RESOLUTION - 1 ) {
        my $p1 = $center->plus( Vector2->new( x => cos( $step_angle * $i ) * $radius,         y => sin( $step_angle * $i ) * $radius ) );
        my $p2 = $center->plus( Vector2->new( x => cos( $step_angle * ( $i + 1 ) ) * $radius, y => sin( $step_angle * ( $i + 1 ) ) * $radius ) );
        simp_immediate_triangle( $center, $p1, $p2 );
    }
}

# The mouse is reported top down by SDL, but the world is Cartesian, so flip it
sub mouse_position ( $x, $y ) { Vector2->new( x => $x, y => WINDOW_HEIGHT - $y ) }

sub compute_tail_velocity ( $head, $tail ) {
    my $delta = Vector2->new( x => $tail->x - $head->x, y => $tail->y - $head->y );
    my $len   = $delta->length || 1;
    return Vector2->new(
        x => ( $head->x + ( $delta->x / $len ) * TARGET_DISTANCE - $tail->x ) * ELASTICITY,
        y => ( $head->y + ( $delta->y / $len ) * TARGET_DISTANCE - $tail->y ) * ELASTICITY
    );
}
#
my $head = Vector2->new( x => WINDOW_WIDTH / 2, y => WINDOW_HEIGHT / 2 );
my @tail = map { Vector2->new( x => rand() * WINDOW_WIDTH, y => rand() * WINDOW_HEIGHT ) } 0 .. TAIL_LENGTH - 1;
my ( $win, $ren, $event_ptr );
my $drag      = 0;
my $prev_left = 0;

sub update ($dt) {
    my @tail_velocity = ( compute_tail_velocity( $head, $tail[0] ), map { compute_tail_velocity( $tail[ $_ - 1 ], $tail[$_] ) } 1 .. $#tail );
    $tail[$_]->move( $tail_velocity[$_]->x * $dt, $tail_velocity[$_]->y * $dt ) for 0 .. $#tail;
}

sub render {
    @verts         = ();                                 # clear?
    $current_color = { r => 0.5, g => 0.5, b => 0.5 };
    immediate_thicc_line( $head,           $tail[0],  30 );
    immediate_thicc_line( $tail[ $_ - 1 ], $tail[$_], KNOT_RADIUS ) for 1 .. $#tail;
    $current_color = { r => 1, g => 0, b => 0 };
    immediate_circle( $head, KNOT_RADIUS );
    $current_color = { r => 0, g => 1, b => 0 };
    immediate_circle( $tail[$_], KNOT_RADIUS ) for 0 .. $#tail;
    SDL_RenderGeometry( $ren, undef, \@verts, scalar(@verts), undef, 0 );
}
#
SDL_Init(SDL_INIT_VIDEO) || die 'Init Error: ' . SDL_GetError();
$win       = SDL_CreateWindow( q[Here's Rope in SDL3?], WINDOW_WIDTH, WINDOW_HEIGHT, 0 );
$ren       = SDL_CreateRenderer( $win, undef );
$event_ptr = Affix::malloc(128);
#
my $running   = 1;
my $last_time = SDL_GetTicks();
while ($running) {
    my $now = SDL_GetTicks();
    my $dt  = ( $now - $last_time ) / 1000.0;
    $last_time = $now;
    while ( SDL_PollEvent($event_ptr) ) {
        my $h = Affix::cast( $event_ptr, SDL_CommonEvent );
        if    ( $h->{type} == SDL_EVENT_QUIT ) { $running = 0 }
        elsif ( $h->{type} == SDL_EVENT_KEY_DOWN ) {
            my $k = Affix::cast( $event_ptr, SDL_KeyboardEvent );
            if ( $k->{scancode} == SDL_SCANCODE_ESCAPE || $k->{scancode} == SDL_SCANCODE_Q ) {
                $running = 0;
                say 'goodbye!';
            }
        }
    }
    my $mouse_mask = SDL_GetMouseState( my ( $mouse_x, $mouse_y ) );
    my $left_down  = $mouse_mask & SDL_BUTTON_LMASK;
    if ( $left_down && !$prev_left ) {
        my $pass  = mouse_position( $mouse_x, $mouse_y );
        my $delta = Vector2->new( x => $pass->x - $head->x, y => $pass->y - $head->y );
        $drag = $delta->length <= KNOT_RADIUS;
    }
    elsif ( !$left_down && $prev_left ) { $drag = 0 }
    $prev_left = $left_down;
    $head      = mouse_position( $mouse_x, $mouse_y ) if $drag;
    update($dt);
    SDL_SetRenderDrawColor( $ren, 26, 26, 26, 255 );
    SDL_RenderClear($ren);
    render();
    SDL_RenderPresent($ren);
}
SDL_DestroyRenderer($ren);
SDL_DestroyWindow($win);
SDL_Quit();
