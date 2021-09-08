use strictures 2;
use lib '../lib', 'lib';
use experimental 'signatures';
use constant { WND_W => 1280, WND_H => 720 };
use SDL2::FFI qw[:all];
$|++;

package Pong::Ball {
    use Moo;
    use strictures 2;
    use experimental 'signatures';
    use Types::Standard qw[Int Num];
    use SDL2::FFI qw[SDL_SetRenderDrawColor SDL_RenderFillRect];
    has [qw[vx vy speed]] => ( is => 'rw', isa => Num, default => 0, lazy => 1, trigger => \&move );
    has [qw[x y w h]] => ( is => 'rw', isa => Num, default => 20, lazy => 1 );

    sub move ( $s, $new ) {
        $s->x( $s->x + ( $s->vx * $s->speed ) );
        $s->y( $s->y + ( $s->vy * $s->speed ) );
    }

    sub draw ( $s, $renderer ) {
        SDL_SetRenderDrawColor( $renderer, 255, 255, 255, 255 );
        SDL_RenderFillRect( $renderer,
            SDL2::Rect->new( { x => $s->x - $s->w / 2, y => $s->y, w => $s->w, h => $s->h } ) );
    }
};

package Pong::Player {
    use Moo;
    use strictures 2;
    use experimental 'signatures';
    use Types::Standard qw[Int Num InstanceOf];
    use SDL2::FFI qw[SDL_SetRenderDrawColor SDL_RenderFillRect];
    has [qw[score speed x y w h]] => ( is => 'rw', isa => Num, default => 0 );

    sub draw ( $s, $renderer ) {
        SDL_SetRenderDrawColor( $renderer, 200, 200, 200, 255 );
        SDL_RenderFillRect( $renderer,
            SDL2::Rect->new( { x => $s->x, y => $s->y, w => $s->w, h => $s->h } ) );
    }
};
END { SDL_Quit() }
#
die 'Failed to Initialise SDL: ' . SDL_GetError() if SDL_Init(SDL_INIT_EVERYTHING) == -1;
my $win = SDL_CreateWindow( 'Pong?', SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, WND_W, WND_H,
    SDL_WINDOW_SHOWN );
$win // die 'Failed to create SDL Window: ' . SDL_GetError();
my $ren = SDL_CreateRenderer( $win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC );
$ren // die 'Failed to create SDL Renderer: ' . SDL_GetError();
#
my $l     = Pong::Player->new( x => 100,         y => ( WND_H / 2 ) - 75, w => 20, h => 150 );
my $r     = Pong::Player->new( x => WND_W - 120, y => ( WND_H / 2 ) - 75, w => 20, h => 150 );
my $ball  = Pong::Ball->new( x => 100, y => 40, vx => 1, vy => 1, speed => 5 );
my @angle = ( -1, -.75, -.5, -.25, 0, 0, .25, .5, .75, 1 );
#
my $tid = SDL_AddTimer( 1000, sub { warn 'ping'; shift } );
while (1) {
    SDL_Yield();
    while ( SDL_PollEvent( my $e = SDL2::Event->new ) ) {
        exit if $e->type == SDL_QUIT;
        if ( $e->type eq SDL_KEYDOWN ) {
            exit                                 if $e->key->keysym->sym == SDLK_ESCAPE;
            $l->y( $l->y() - int( WND_H / 20 ) ) if $e->key->keysym->sym == SDLK_UP && $l->y > 0;
            $l->y( $l->y() + int( WND_H / 20 ) )
                if $e->key->keysym->sym == SDLK_DOWN && $l->y < WND_H - $l->h;
        }
        elsif ( $e->type == SDL_MOUSEWHEEL ) {
            $r->y( $r->y() - int( WND_H / 20 ) ) if $e->wheel->y > 0 && $r->y > 0;
            $r->y( $r->y() + int( WND_H / 20 ) ) if $e->wheel->y < 0 && $r->y < ( WND_H - $r->h );
        }
    }
    $r->score( $r->score + 1 ) if $ball->x <= 0;
    $l->score( $l->score + 1 ) if $ball->x >= ( WND_W - $r->w );
    if ( ( $ball->x + $ball->w ) >= $r->x &&
        $ball->vx == 1 &&
        ( $ball->y >= $r->y && $ball->y <= ( $r->y + $r->h ) ) ) {
        $ball->vy( $angle[ ( ( $ball->y - $r->y ) / ( $r->h / +@angle ) ) ] // $ball->vy );
        $ball->vx(-1);
    }
    elsif ( $ball->x <= ( $l->x + $l->w ) &&
        $ball->vx == -1 &&
        ( $ball->y >= $l->y && $ball->y <= ( $l->y + $l->h ) ) ) {
        $ball->vy( $angle[ ( ( $ball->y - $l->y ) / ( $l->h / +@angle ) ) ] // $ball->vy );
        $ball->vx(1);
    }
    else {
        $ball->vx( $ball->x >= WND_W - $ball->w ? -1 : $ball->x <= 0 ? 1 : $ball->vx );
        $ball->vy( $ball->y >= WND_H - $ball->h ? -1 : $ball->y <= 0 ? 1 : $ball->vy );
    }
    SDL_SetRenderDrawColor( $ren, 33, 34, 35, 255 );
    SDL_RenderClear($ren);
    SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
    $_ % 5 && SDL_RenderDrawPoint( $ren, WND_W / 2, $_ ) for 0 .. WND_H;
    $_->draw($ren) for $l, $r, $ball;
    SDL_RenderPresent($ren);
}
__END__
use strictures 2;
use lib '../lib', 'lib';
use experimental 'signatures';
use constant { WND_W => 1280, WND_H => 720 };
use SDL2::FFI qw[:all];
$|++;

=cut
#use FFI::Platypus::Internal;
#warn FFI::Platypus::Internal::FFI_PL_TYPE_SINT32();
#die;
package Pong::Ball {
    use Moo;
    use experimental 'signatures';
    use Types::Standard qw[Ref Int Num];
    use SDL2::FFI qw[SDL_SetRenderDrawColor SDL_RenderFillRect];
    has [qw[vx vy speed]] => ( is => 'rw', isa => Num, default => 1, lazy => 1 );
    has rect => ( is => 'ro', isa => Ref, handles => [qw[w h x y]] );

    sub move ($s) {
        $s->x( $s->x + ( $s->vx * $s->speed ) );
        $s->y( $s->y + ( $s->vy * $s->speed ) );
    }

    sub draw ( $s, $renderer ) {
        SDL_SetRenderDrawColor( $renderer, 255, 255, 255, 255 );
        SDL_RenderFillRect( $renderer, $s->rect );
    }
};

package Pong::Player {
    use Moo;
    use experimental 'signatures';
    use Types::Standard qw[Int Num Ref];
    use SDL2::FFI qw[SDL_SetRenderDrawColor SDL_RenderFillRect];
    has [qw[score speed]] => ( is => 'rw', isa => Num, default => 0 );
    has rect              => ( is => 'ro', isa => Ref, handles => [qw[w h x y]] );
    sub move ($s) {1}

    sub draw ( $s, $renderer ) {
        SDL_SetRenderDrawColor( $renderer, 200, 200, 200, 255 );
        SDL_RenderFillRect( $renderer, $s->rect );
    }
};
END {SDL_Quit}
die SDL_GetError if SDL_Init(SDL_INIT_EVERYTHING) == -1;

#SDL_Delay( 5 * 1000 );
die SDL_GetError
    if SDL_CreateWindowAndRenderer( WND_W, WND_H,
    SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC,
    my $win, my $ren ) == -1;
my $l = Pong::Player->new(
    rect => SDL2::Rect->new( { x => 100, y => ( WND_H / 2 ) - 75, w => 20, h => 150 } ) );
my $r = Pong::Player->new(
    rect => SDL2::Rect->new( { x => WND_W - 120, y => ( WND_H / 2 ) - 75, w => 20, h => 150 } ) );
my $ball = Pong::Ball->new(
    speed => 1,
    rect  => SDL2::Rect->new( { x => ( WND_W / 2 ), y => ( WND_H / 2 ), w => 20, h => 20 } )
);
my @angle = ( -1, -.75, -.5, -.25, 0, 0, .25, .5, .75, 1 );

sub draw {
    SDL_SetRenderDrawColor( $ren, 33, 34, 35, 255 );
    SDL_RenderClear($ren);
    SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
    $_ % 5 && SDL_RenderDrawPoint( $ren, WND_W / 2, $_ ) for 0 .. WND_H;
    for my $o ( $l, $r, $ball ) { $o->move; $o->draw($ren) }
    SDL_RenderPresent($ren) if $ren;
}

#warn $person->init;
#warn FFI::Platypus::FFI_PL_TYPE_STRING();
#exit;
#my $tid = SDL_AddTimer(1000, sub { use Data::Dump; ddx \@_; warn 'hi'; 1000}, 'test' );
=cut

my %_timers;
SDL2::FFI::ffi->type( '(int)->int' => 'closure_t' );
SDL2::FFI::ffi->type( 'opaque'     => 'pointer' );
SDL2::FFI::ffi->type( opaque       => 'SDL_WindowX' );
SDL2::FFI::attach(
    event => {
        init_timer => [
            [ 'int', 'closure_t', 'opaque' ],
            'int' => sub {
                my ( $inner, $time, $code, $args ) = @_;
                my $cb = SDL2::FFI::ffi->closure(
                    $code

                        #sub {
                        #    my ( $delay, $etc ) = @_;
                        #	warn 'Inside callback!';
                        #	my $retval = $code->( $delay, $args );
                        #    $retval;
                        #}
                );

                #$cb->sticky;
                my $id = $inner->( $time, $cb, $args );
                $_timers{$id} = $cb;    #Timer->new(cb => $cb, id => $id );
                return $id;
            }
        ],
        SDLTest_PrintEvent => [ ['SDL_Event'] ],
        mainloop           => [ [ 'SDL_Window', 'SDL_Surface' ], 'int' ],
        loop               => [ ['SDL_Event'],              'int' ],
        make_window        => [ [],                         'SDL_Window' ],
        get_surface        => [ ['SDL_Window'],             'SDL_Surface' ],
        get_event          => [ [],                         'SDL_Event' ],
        window_to_window   => [ ['SDL_Window'] ],
    }
);
my $ptr = SDL2::FFI::ffi->function( SDL_GetWindowSurface => ['SDL_Window'], 'SDL_Surface' );
SDL2::FFI::ffi->attach(
    [ SDL_GetWindowSurface => 'My_GetWindowSurface' ] => ['SDL_Window'],
    'SDL_Surface'
);
if ( SDL_Init(SDL_INIT_VIDEO) < 0 ) {
    die 'could not initialize sdl2: ' . SDL_GetError();
}END { SDL_Quit(); }

SDL2::FFI::SDL_AddTimer(
    1000,
    sub {
        use Data::Dump;
        ddx \@_;
        $_[0] * 2;
    },
    100
);
sub SCREEN_WIDTH ()  {640}
sub SCREEN_HEIGHT () {480}
if ( SDL_Init(SDL_INIT_VIDEO) < 0 ) {
    printf( "could not initialize sdl2: %s\n", SDL_GetError() );
    exit 1;
}
my $window   = SDL2::FFI::make_window();
my $window_x = SDL2::Window->new();

#SDL2::FFI::window_to_window($window, $window_x);
#die;
#warn $window->magic;
#SDL_Surface * screenSurface = NULL;
my $screenSurface =
SDL2::FFI::get_surface($window);

SDL_GetWindowSurface($window);
#$screenSurface = My_GetWindowSurface($window);
#$screenSurface = $ptr->call($window);
die SDL_GetError() if !$screenSurface;
SDL_FillRect( $screenSurface, undef, SDL_MapRGB( $screenSurface->format, 0xFF, 0xFF, 0xFF ) );
SDL_UpdateWindowSurface($window);
my $e = SDL2::Event->new();

#my $e = SDL2::FFI::get_event();
warn $e;
while (1) {
    my $quit = SDL2::FFI::mainloop( $window, $e );
    warn $quit;
    exit if $quit;
}
__END__
my $quit = 0;

while (!$quit) {
	draw;
	$quit = SDL2::FFI::mainloop($e);
}

SDL_Quit();

exit;
while (1) {
    while (
        #SDL_PollEventX( $e )
        SDL_PollEvent($e)
		#SDL2::FFI::loop($e)

        #$e = SDL2::FFI::fakeloop()
    ) {
        #SDL2::FFI::loop( $e );
		warn $e->type;
        die 'FINALLY' if $e->type == SDL_USEREVENT;
        exit          if $e->type == SDL_QUIT;
        if ( $e->type eq SDL_KEYDOWN ) {
            exit                               if $e->key->keysym->sym == SDLK_ESCAPE;
            $l->y( $l->y - int( WND_H / 20 ) ) if $e->key->keysym->sym == SDLK_UP && $l->y > 0;
            $l->y( $l->y + int( WND_H / 20 ) )
                if $e->key->keysym->sym == SDLK_DOWN && $l->y < WND_H - $l->h;
        }
        elsif ( $e->type == SDL_MOUSEWHEEL ) {
            $r->y( $r->y - int( WND_H / 20 ) ) if $e->wheel->y == 1  && $r->y > 0;
            $r->y( $r->y + int( WND_H / 20 ) ) if $e->wheel->y == -1 && $r->y < WND_H - $r->h;
        }
    }
    if    ( $ball->x <= 0 ) { $r->score( $r->score + 1 ); $ball->y( $r->y + $r->h / 2 ) }
    elsif ( $ball->x >= ( WND_W - $ball->w ) ) {
        $l->score( $l->score + 1 );
        $ball->y( $l->y + $l->h / 2 );
    }
    elsif ( SDL_HasIntersection( $ball->rect, $r->rect ) ) {

        #warn ( ($r->y - $ball->y) / +@angle);
        #		- $ball->h;
        # $ball->vy( $angle[ int ( ( ($r->y - $ball->y) / +@angle)) ] );
        $ball->vx(-1);
    }
    elsif ( SDL_HasIntersection( $ball->rect, $l->rect ) ) {

        #$ball->vy( $angle[   $l->h ] );
        $ball->vx(1);
    }
    $ball->vx( $ball->x >= ( WND_W - $ball->w ) ? -1 : $ball->x <= 0 ? 1 : $ball->vx );
    $ball->vy( $ball->y >= ( WND_H - $ball->h ) ? -1 : $ball->y <= 0 ? 1 : $ball->vy );
    draw;
}

# TODO:
# - display score
