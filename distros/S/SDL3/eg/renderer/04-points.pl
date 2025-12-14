use v5.40;
use lib '../../lib';
use SDL3 qw[:all :main];

# This demo creates an SDL window and renderer and draws some points to it every frame. It's based
# on a public domain example.
use constant {
    WINDOW_WIDTH          => 640,
    WINDOW_HEIGHT         => 480,
    NUM_POINTS            => 500,
    MIN_PIXELS_PER_SECOND => 30,    # move at least this many pixels per second.
    MAX_PIXELS_PER_SECOND => 60     # move this many pixels per second at most.
};

# We will use this renderer to draw into this window every frame.
my ( $window, $renderer );
my $last_time = 0;

# (track everything as parallel arrays... so we can pass the coordinates
# to the renderer in a single function call.)
# Points are plotted as a set of X and Y coordinates.
# (0, 0) is the top left of the window, and larger numbers go down
# and to the right. This isn't how geometry works, but this is pretty
# standard in 2D graphics.
my @points       = map { {} } 1 .. NUM_POINTS;
my @point_speeds = (0) x NUM_POINTS;

# This function runs once at startup.
sub SDL_AppInit( $appstate, $argc, $argv ) {
    SDL_SetAppMetadata( "Example Renderer Points", "1.0", "com.example.renderer-points" );
    if ( !SDL_Init(SDL_INIT_VIDEO) ) {
        SDL_Log( "Couldn't initialize SDL: " . SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !SDL_CreateWindowAndRenderer( 'examples/renderer/points', WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_RESIZABLE, \$window, \$renderer ) ) {
        SDL_Log( "Couldn't create window/renderer: " . SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    SDL_SetRenderLogicalPresentation( $renderer, WINDOW_WIDTH, WINDOW_HEIGHT, SDL_LOGICAL_PRESENTATION_LETTERBOX );

    # set up the data for a bunch of points.
    for my $i ( 0 .. $#points ) {
        $points[$i]->{x}  = rand(WINDOW_WIDTH);
        $points[$i]->{y}  = rand(WINDOW_HEIGHT);
        $point_speeds[$i] = MIN_PIXELS_PER_SECOND + ( rand( MAX_PIXELS_PER_SECOND - MIN_PIXELS_PER_SECOND ) );
    }
    $last_time = SDL_GetTicks();
    return SDL_APP_CONTINUE;    # carry on with the program!
}

# This function runs when a new event (mouse input, keypresses, etc) occurs.
sub SDL_AppEvent( $appstate, $event ) {
    if ( $event->{type} == SDL_EVENT_QUIT ) {
        return SDL_APP_SUCCESS;    # end the program, reporting success to the OS.
    }
    return SDL_APP_CONTINUE;       # carry on with the program!
}

# This function runs once per frame, and is the heart of the program.
sub SDL_AppIterate($appstate) {
    my $now     = SDL_GetTicks();
    my $elapsed = ( $now - $last_time ) / 1000.0;    # seconds since last iteration

    # let's move all our points a little for a new frame.
    for my $i ( 0 .. $#points ) {
        my $distance = $elapsed * $point_speeds[$i];
        $points[$i]->{x} += $distance;
        $points[$i]->{y} += $distance;
        if ( ( $points[$i]->{x} >= WINDOW_WIDTH ) || ( $points[$i]->{y} >= WINDOW_HEIGHT ) ) {

            # off the screen; restart it elsewhere!
            if ( int( rand(2) ) ) {
                $points[$i]->{x} = rand(WINDOW_WIDTH);
                $points[$i]->{y} = 0.0;
            }
            else {
                $points[$i]->{x} = 0.0;
                $points[$i]->{y} = rand(WINDOW_HEIGHT);
            }
            $point_speeds[$i] = MIN_PIXELS_PER_SECOND + ( rand( MAX_PIXELS_PER_SECOND - MIN_PIXELS_PER_SECOND ) );
        }
    }
    $last_time = $now;

    # as you can see from this, rendering draws over whatever was drawn before it.
    SDL_SetRenderDrawColor( $renderer, 0, 0, 0, SDL_ALPHA_OPAQUE );          # black, full alpha
    SDL_RenderClear($renderer);                                              # start with a blank canvas.
    SDL_SetRenderDrawColor( $renderer, 255, 255, 255, SDL_ALPHA_OPAQUE );    # white, full alpha
    SDL_RenderPoints( $renderer, \@points, scalar @points );                 # draw all the points!

    # You can also draw single points with SDL_RenderPoint(), but it's
    # cheaper (sometimes significantly so) to do them all at once.
    SDL_RenderPresent($renderer);    # put it all on the screen!
    return SDL_APP_CONTINUE;         # carry on with the program!
}

# This function runs once at shutdown.
sub SDL_AppQuit( $appstate, $result ) {

    # SDL will clean up the window/renderer for us.
}

=pod

=head1 NAME

eg/renderer/04-points.pl - An SDL3 example demonstrating efficient point rendering and logical updates in Perl

=head1 SYNOPSIS

    perl 04-points.pl
    # Look at the pretty pixels

=head1 DESCRIPTION

This script is a direct port of the SDL3 C example C<examples/renderer/04-points/points.c>.

It creates a window and a renderer, then initializes a cloud of 500 points. The, every frame, it...

=over

=item 1. Calculates the elapsed time since the last frame

=item 2. Updates the X and Y coordinates of every point based on its individual speed

=item 3. Resets points that drift off-screen to the top or left edges

=item 4. Clears the screen and redraws all points simultaneously

=back

The visual effect is a stream of white pixels moving diagonally from the top-left toward the bottom-right. Snow, in a pinch.

=head1 LICENSE

This software is Copyright (c) 2025 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

See the F<LICENSE> file for full text.

=head1 AUTHOR

Perl port written by Sanko Robinson <sanko@cpan.org>

Original C is in the public domain. See L<https://github.com/libsdl-org/SDL/tree/main/examples/renderer/04-points>.

=cut
