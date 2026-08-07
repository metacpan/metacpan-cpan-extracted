
=pod

=for html <center><img src="https://raw.githubusercontent.com/Perl-SDL3/.github/refs/heads/main/screenshots/particle_waterfall.gif" /></center>

=cut

use v5.36;
use Affix qw[:all];
use SDL3  qw[:all];
$|++;

# This was an idea I had while trying to get bunny_bench.pl running.
#
# We generate particles that can flow from window to window like water. It's a
# lot like the bunnies but less efficient and instead of bouncing around a
# single window, we bounce around more than one window! Moving windows around
# allows the particles to fall into the lower one if they overlap.
#
# Controls
#  - Hit 'R' on the keyboard to reset the particle burst
#  - Hit ESC to exit (we don't react to the OS request to close windows)
#
# Config
my $WIN_COUNT = 5;
my $WIN_W     = 300;
my $WIN_H     = 300;
my $PARTICLES = 1000;
my @cols      = generate_palette($WIN_COUNT);    # Window bgs

# OS Detection & strategy setup
my $Z_STRATEGY = 'fallback';                     # default
my $os_lib     = undef;                          # Handle to user32 or libX11

# We need extra functions for OS integration
my $sdl_lib = Affix::load_library( ( Alien::SDL3->dynamic_libs )[0] );
if ( $^O eq 'MSWin32' ) {
    $os_lib = Affix::load_library('user32.dll');
    if ($os_lib) {
        $Z_STRATEGY = 'win32';
        affix $os_lib, GetTopWindow => [ Pointer [Void] ], Pointer [Void];
        affix $os_lib, GetWindow => [ Pointer [Void], UInt32 ], Pointer [Void];    # uCmd 2 = NEXT
    }
}
elsif ( $^O eq 'linux' || $^O =~ /bsd$/ ) {

    # Check if running Wayland (X11 logic won't work there)
    if ( !$ENV{WAYLAND_DISPLAY} ) {
        $os_lib = Affix::load_library('libX11.so') // Affix::load_library('libX11.so.6');
        if ($os_lib) {
            $Z_STRATEGY = 'x11';
            typedef Display => Pointer [Void];
            typedef _Window => ULong;
            affix $os_lib, XOpenDisplay       => [String] => Display();
            affix $os_lib, XDefaultRootWindow => [ Display() ]->_Window();
            affix $os_lib,
                XQueryTree =>
                [ Display(), _Window(), Pointer [ _Window() ], Pointer [ _Window() ], Pointer [ Pointer [ _Window() ] ], Pointer [UInt] ],
                Int;
            affix $os_lib, XFree => [ Pointer [Void] ], Int;
        }
    }
}
say 'OS Detection: ' . $^O;
say 'Z-Order Strategy: ' . uc($Z_STRATEGY);
#
SDL_Init(SDL_INIT_VIDEO) || die 'Init Failed: ' . SDL_GetError();
my @contexts;
my %os_handle_map;    # Map HWND/XID -> Context
my $ptr_x = Affix::calloc( 1, sizeof(Int) );
my $ptr_y = Affix::calloc( 1, sizeof(Int) );

# X11 Globals
my ( $dpy, $root );
if ( $Z_STRATEGY eq 'x11' ) {
    $dpy  = XOpenDisplay(undef);
    $root = XDefaultRootWindow($dpy);
}
for my $i ( 0 .. $WIN_COUNT - 1 ) {
    my $title = 'Bucket ' . ( $i + 1 );
    my $win   = SDL_CreateWindow( $title, $WIN_W, $WIN_H, SDL_WINDOW_RESIZABLE );
    my $ren   = SDL_CreateRenderer( $win, undef );
    SDL_SetWindowPosition( $win, 200 + ( $i * 100 ), 200 + ( $i * 100 ) );
    my $ctx = {
        win         => $win,
        ren         => $ren,
        id          => $i,
        win_id      => SDL_GetWindowID($win),
        rect        => { x => 0, y => 0, w => $WIN_W, h => $WIN_H },
        last_active => 0                                               # For fallback heuristic
    };

    # Fetch OS Handles
    my $props = SDL_GetWindowProperties($win);
    if ( $Z_STRATEGY eq 'win32' ) {
        my $ptr  = SDL_GetPointerProperty( $props, 'SDL.window.win32.hwnd', undef );
        my $hwnd = Affix::address($ptr);
        $os_handle_map{$hwnd} = $ctx;
    }
    elsif ( $Z_STRATEGY eq 'x11' ) {

        # Try Number first, fallback to Pointer address
        my $xid = SDL_GetNumberProperty( $props, 'SDL.window.x11.window', 0 );
        if ( $xid == 0 ) {
            my $ptr = SDL_GetPointerProperty( $props, 'SDL.window.x11.window', undef );
            $xid = Affix::address($ptr);
        }
        $os_handle_map{$xid} = $ctx;
    }
    push @contexts, $ctx;
}

# Initial Stack (Bottom -> Top)
my @stack = @contexts;

# Z-Order Update Functions
sub update_z_win32 {
    my @new_stack;
    my $found = 0;

    # Walk Windows list from Top to Bottom
    my $curr = GetTopWindow(undef);
    while ( $curr && $found < $WIN_COUNT ) {
        my $addr = Affix::address($curr);
        if ( exists $os_handle_map{$addr} ) {
            push @new_stack, $os_handle_map{$addr};
            $found++;
        }
        $curr = GetWindow( $curr, 2 );    # GW_HWNDNEXT
    }

    # Windows gives Top->Bottom. We need Bottom->Top for rendering loop.
    if ( $found == $WIN_COUNT ) {
        @stack = reverse @new_stack;
    }
}

# Helpers for XQueryTree
my ( $root_ret, $parent_ret, $children_ptr, $nchildren ) = (
    Affix::calloc( 1, sizeof(ULong) ),
    Affix::calloc( 1, sizeof(ULong) ),
    Affix::calloc( 1, sizeof( Pointer [Void] ) ),
    Affix::calloc( 1, sizeof(UInt) )
);

sub update_z_x11 {
    if ( XQueryTree( $dpy, $root, $root_ret, $parent_ret, $children_ptr, $nchildren ) ) {
        my $count = ${ Affix::cast( $nchildren, UInt ) };
        if ( $count > 0 ) {
            my @new_stack;
            my $list        = ${ Affix::cast( $children_ptr, Pointer [ULong] ) };
            my $sizeof_long = Affix::sizeof(ULong);                                 # 4 or 8

            # X11 returns Bottom -> Top (Correct for us)
            for my $k ( 0 .. $count - 1 ) {
                my $addr = $list + ( $k * $sizeof_long );
                my $xid  = ${ Affix::cast( $addr, ULong ) };
                if ( exists $os_handle_map{$xid} ) {
                    push @new_stack, $os_handle_map{$xid};
                }
            }
            XFree($list);
            if ( @new_stack == $WIN_COUNT ) { @stack = @new_stack; }
        }
    }
}

# Particles
my $event_ptr = Affix::malloc(128);
my @particles;
for ( 1 .. $PARTICLES ) {
    push @particles,
        {
        ctx => $contexts[0],
        x   => rand($WIN_W),
        y   => rand( $WIN_H / 2 ),
        vx  => rand(8) - 4,
        vy  => rand(5),
        r   => 100 + rand(155),
        g   => 100 + rand(155),
        b   => 255
        };
}
say 'Simulation Started.';

# Main loop
my $running = 1;
my $ptr_mx  = Affix::malloc(4);
my $ptr_my  = Affix::malloc(4);
while ($running) {

    # Sync z-order
    if    ( $Z_STRATEGY eq 'win32' ) { update_z_win32(); }
    elsif ( $Z_STRATEGY eq 'x11' )   { update_z_x11(); }

    # Sync Geometry
    for my $c (@contexts) {
        SDL_GetWindowPosition( $c->{win}, $ptr_x, $ptr_y );
        $c->{rect}{x} = Affix::cast( $ptr_x, Int );
        $c->{rect}{y} = Affix::cast( $ptr_y, Int );
        SDL_GetWindowSize( $c->{win}, $ptr_x, $ptr_y );
        $c->{rect}{w} = Affix::cast( $ptr_x, Int );
        $c->{rect}{h} = Affix::cast( $ptr_y, Int );
    }

    # Events & fallback heuristic
    while ( SDL_PollEvent($event_ptr) ) {
        my $h = Affix::cast( $event_ptr, SDL_CommonEvent );
        if    ( $h->{type} == SDL_EVENT_QUIT ) { $running = 0; }
        elsif ( $h->{type} == SDL_EVENT_KEY_DOWN ) {
            my $k = Affix::cast( $event_ptr, SDL_KeyboardEvent );
            if ( $k->{scancode} == SDL_SCANCODE_ESCAPE ) { $running = 0; }
            if ( $k->{scancode} == SDL_SCANCODE_R ) {
                my $top = $stack[-1];
                for my $p (@particles) {
                    $p->{ctx} = $top;
                    $p->{x}   = $WIN_W / 2;
                    $p->{y}   = 50;
                }
            }
        }

        # Fallback logic: sort based on last activity
        if ( $Z_STRATEGY eq 'fallback' ) {
            if ( $h->{type} == SDL_EVENT_WINDOW_FOCUS_GAINED || $h->{type} == SDL_EVENT_MOUSE_MOTION || $h->{type} == SDL_EVENT_MOUSE_BUTTON_DOWN ) {
                my $wid = 0;
                if ( $h->{type} == SDL_EVENT_WINDOW_FOCUS_GAINED ) {
                    $wid = ( Affix::cast( $event_ptr, SDL_WindowEvent ) )->{windowID};
                }
                else {
                    $wid = ( Affix::cast( $event_ptr, SDL_MouseMotionEvent ) )->{windowID};
                }

                # Bubble Up
                for my $ctx (@contexts) {
                    if ( $ctx->{win_id} == $wid ) {
                        $ctx->{last_active} = SDL_GetTicks();
                        @stack = sort { $a->{last_active} <=> $b->{last_active} } @contexts;
                        last;
                    }
                }
            }
        }
    }

    # Physics (w/ view-rect continuity check)
    for my $p (@particles) {
        $p->{x}  += $p->{vx};
        $p->{y}  += $p->{vy};
        $p->{vy} += 0.3;
        my $cur_rect = $p->{ctx}->{rect};
        my $gx       = $cur_rect->{x} + $p->{x};
        my $gy       = $cur_rect->{y} + $p->{y};
        my $found    = 0;

        # Scan Stack Top -> Bottom
        for ( my $i = $#stack; $i >= 0; $i-- ) {
            my $target = $stack[$i];
            my $r      = $target->{rect};
            if ( $gx >= $r->{x} && $gx < $r->{x} + $r->{w} && $gy >= $r->{y} && $gy < $r->{y} + $r->{h} ) {
                if ( $p->{ctx} != $target ) {
                    $p->{ctx} = $target;
                    $p->{x}   = $gx - $r->{x};
                    $p->{y}   = $gy - $r->{y};
                }
                $found = 1;
                last;
            }
        }
        unless ($found) {
            if ( $p->{x} > $cur_rect->{w} ) { $p->{x} = $cur_rect->{w}; $p->{vx} *= -0.8; }
            if ( $p->{x} < 0 )              { $p->{x} = 0;              $p->{vx} *= -0.8; }
            if ( $p->{y} > $cur_rect->{h} ) { $p->{y} = $cur_rect->{h}; $p->{vy} *= -0.6; }
            if ( $p->{y} < 0 )              { $p->{y} = 0;              $p->{vy} *= -0.5; }
        }
    }

    # Render
    for my $ctx (@stack) {
        my $ren = $ctx->{ren};
        my $id  = $ctx->{id};
        SDL_SetRenderDrawColor( $ren, @{ $cols[$id] }, 255 );
        SDL_RenderClear($ren);
        for my $p (@particles) {
            if ( $p->{ctx} == $ctx ) {
                SDL_SetRenderDrawColor( $ren, $p->{r}, $p->{g}, $p->{b}, 255 );

                # Make them slightly thicker so they are visible
                my $px = $p->{x};
                my $py = $p->{y};
                SDL_RenderFillRect( $ren, { x => $px - 2, y => $py - 2, w => 4, h => 4 } );
            }
        }
        SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
        SDL_RenderDebugText( $ren, 10, 10, 'Bucket ' . ( $id + 1 ) );
        my $z_idx = 0;
        for my $k ( 0 .. $#stack ) {
            if ( $stack[$k] == $ctx ) { $z_idx = $k; last; }
        }

        #~ my $status = ( $z_idx == $#stack ) ? '[FRONT]' : "[$z_idx]";
        #~ SDL_RenderDebugText( $ren, 10, 30, '$status (' . uc($Z_STRATEGY) . ')' );
        SDL_RenderPresent($ren);
    }
    SDL_Delay(16);
}

sub generate_palette ($n) {
    return () if $n <= 0;
    my $step = 360.0 / $n;    # Space colors evenly

    # Create a deterministic starting offset based on $n. We multiply $n by a
    # primeish number to ensure the wheel starts at a different rotation for
    # different values of $n.
    my $start_offset = ( $n * 137.508 ) % 360;

    # Saturation: 0.7 (Colorful but not eye-bleeding)
    # Value:      0.95 (Bright)
    map { [ hsv_to_rgb( ( ( $start_offset + ( $_ * $step ) ) % 360 ), 0.70, 0.95 ) ] } 0 .. $n - 1;
}

sub hsv_to_rgb ( $h, $s, $v ) {    # H [0-360], S [0-1], V [0-1] -> (0-255, 0-255, 0-255)
    my $c = $v * $s;
    my $x = $c * ( 1 - abs( ( ( $h / 60.0 ) % 2 ) - 1 ) );
    my $m = $v - $c;
    my ( $r, $g, $b );
    if    ( $h < 60 )  { ( $r, $g, $b ) = ( $c, $x, 0 ) }
    elsif ( $h < 120 ) { ( $r, $g, $b ) = ( $x, $c, 0 ) }
    elsif ( $h < 180 ) { ( $r, $g, $b ) = ( 0, $c, $x ) }
    elsif ( $h < 240 ) { ( $r, $g, $b ) = ( 0, $x, $c ) }
    elsif ( $h < 300 ) { ( $r, $g, $b ) = ( $x, 0, $c ) }
    else               { ( $r, $g, $b ) = ( $c, 0, $x ) }
    int( ( $r + $m ) * 255 ), int( ( $g + $m ) * 255 ), int( ( $b + $m ) * 255 );
}
for my $ctx (@contexts) { SDL_DestroyRenderer( $ctx->{ren} ); SDL_DestroyWindow( $ctx->{win} ); }
SDL_Quit();
