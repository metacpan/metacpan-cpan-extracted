package SDL2::video {
    use lib '../../lib';
    use strict;
    use warnings;
    use experimental 'signatures';
    use SDL2::Utils;
    #
    use SDL2::stdinc;
    use SDL2::pixels;
    use SDL2::rect;
    use SDL2::surface;
    #
    package SDL2::DisplayMode {
        use SDL2::Utils;
        our $TYPE = has
            'format'     => 'uint32',
            w            => 'int',
            h            => 'int',
            refresh_rate => 'int',
            driverdata   => 'opaque';
    };

    package SDL2::Window {
        use SDL2::Utils;
        has
            magic                 => 'uint8',
            id                    => 'uint32',
            title                 => 'opaque',            # char *
            icon                  => 'SDL_Surface',
            x                     => 'int',
            y                     => 'int',
            w                     => 'int',
            h                     => 'int',
            min_w                 => 'int',
            min_h                 => 'int',
            max_w                 => 'int',
            max_h                 => 'int',
            flags                 => 'uint32',
            last_fullscreen_flags => 'uint32',
            windowed              => 'SDL_Rect',
            fullscreen_mode       => 'SDL_DisplayMode',
            opacity               => 'float',
            brightness            => 'float',
            gamma                 => 'opaque',            # uint16*
            saved_gamma           => 'opaque',            # uint16*
            surface               => 'SDL_Surface',
            surface_valid         => 'SDL_bool',
            is_hiding             => 'SDL_bool',
            is_destroying         => 'SDL_bool',
            is_dropping           => 'SDL_bool',
            shaper                => 'opaque',            # SDL_WindowShaper
            hit_test              => 'opaque',            # SDL_HitTest
            hit_test_data         => 'opaque',            # void*
            _data                 => 'opaque',            # SDL_WindowUserData*
            driverdata            => 'opaque',            # void*
            _prev                 => 'opaque',            # SDL_Window*
            _next                 => 'opaque'             # SDL_Window*
            ;

        sub data {
            ffi->cast( 'opaque', 'SDL_WindowUserData', $_[0]->_data );
        }

        sub prev {
            ffi->cast( 'opaque', 'SDL_Window', $_[0]->_prev );
        }

        sub next {
            ffi->cast( 'opaque', 'SDL_Window', $_[0]->_next );
        }
    };
    #
    enum SDL_WindowFlags => [
        [ SDL_WINDOW_FULLSCREEN    => 0x00000001 ],
        [ SDL_WINDOW_OPENGL        => 0x00000002 ],
        [ SDL_WINDOW_SHOWN         => 0x00000004 ],
        [ SDL_WINDOW_HIDDEN        => 0x00000008 ],
        [ SDL_WINDOW_BORDERLESS    => 0x00000010 ],
        [ SDL_WINDOW_RESIZABLE     => 0x00000020 ],
        [ SDL_WINDOW_MINIMIZED     => 0x00000040 ],
        [ SDL_WINDOW_MAXIMIZED     => 0x00000080 ],
        [ SDL_WINDOW_MOUSE_GRABBED => 0x00000100 ],
        [ SDL_WINDOW_INPUT_FOCUS   => 0x00000200 ],
        [ SDL_WINDOW_MOUSE_FOCUS   => 0x00000400 ],
        [   SDL_WINDOW_FULLSCREEN_DESKTOP =>
                sub { ( SDL2::FFI::SDL_WINDOW_FULLSCREEN() | 0x00001000 ) }
        ],
        [ SDL_WINDOW_FOREIGN          => 0x00000800 ],
        [ SDL_WINDOW_ALLOW_HIGHDPI    => 0x00002000 ],
        [ SDL_WINDOW_MOUSE_CAPTURE    => 0x00004000 ],
        [ SDL_WINDOW_ALWAYS_ON_TOP    => 0x00008000 ],
        [ SDL_WINDOW_SKIP_TASKBAR     => 0x00010000 ],
        [ SDL_WINDOW_UTILITY          => 0x00020000 ],
        [ SDL_WINDOW_TOOLTIP          => 0x00040000 ],
        [ SDL_WINDOW_POPUP_MENU       => 0x00080000 ],
        [ SDL_WINDOW_KEYBOARD_GRABBED => 0x00100000 ],
        [ SDL_WINDOW_VULKAN           => 0x10000000 ],
        [ SDL_WINDOW_METAL            => 0x20000000 ],
        [ SDL_WINDOW_INPUT_GRABBED    => sub { SDL2::FFI::SDL_WINDOW_MOUSE_GRABBED() } ]
    ];
    define video => [
        [ SDL_WINDOWPOS_UNDEFINED_MASK => 0x1FFF0000 ],
        [   SDL_WINDOWPOS_UNDEFINED_DISPLAY =>
                sub ($X) { ( SDL2::FFI::SDL_WINDOWPOS_UNDEFINED_MASK() | ($X) ) }
        ],
        [ SDL_WINDOWPOS_UNDEFINED => sub () { SDL2::FFI::SDL_WINDOWPOS_UNDEFINED_DISPLAY(0) } ],
        [   SDL_WINDOWPOS_ISUNDEFINED => sub ($X) {
                ( ( ($X) & 0xFFFF0000 ) == SDL2::FFI::SDL_WINDOWPOS_UNDEFINED_MASK() )
            }
        ],
        [ SDL_WINDOWPOS_CENTERED_MASK => sub () {0x2FFF0000} ],
        [   SDL_WINDOWPOS_CENTERED_DISPLAY =>
                sub ($X) { ( SDL2::FFI::SDL_WINDOWPOS_CENTERED_MASK() | ($X) ) }
        ],
        [ SDL_WINDOWPOS_CENTERED => sub() { SDL2::FFI::SDL_WINDOWPOS_CENTERED_DISPLAY(0) } ],
        [   SDL_WINDOWPOS_ISCENTERED => sub ($X) {
                ( ( ($X) & 0xFFFF0000 ) == SDL2::FFI::SDL_WINDOWPOS_CENTERED_MASK() )
            }
        ],
    ];
    enum SDL_WindowEventID => [
        qw[
            SDL_WINDOWEVENT_NONE
            SDL_WINDOWEVENT_SHOWN
            SDL_WINDOWEVENT_HIDDEN
            SDL_WINDOWEVENT_EXPOSED
            SDL_WINDOWEVENT_MOVED
            SDL_WINDOWEVENT_RESIZED
            SDL_WINDOWEVENT_SIZE_CHANGED
            SDL_WINDOWEVENT_MINIMIZED
            SDL_WINDOWEVENT_MAXIMIZED
            SDL_WINDOWEVENT_RESTORED
            SDL_WINDOWEVENT_ENTER
            SDL_WINDOWEVENT_LEAVE
            SDL_WINDOWEVENT_FOCUS_GAINED
            SDL_WINDOWEVENT_FOCUS_LOST
            SDL_WINDOWEVENT_CLOSE
            SDL_WINDOWEVENT_TAKE_FOCUS
            SDL_WINDOWEVENT_HIT_TEST]
        ],
        SDL_DisplayEventID => [
        qw[SDL_DISPLAYEVENT_NONE SDL_DISPLAYEVENT_ORIENTATION
            SDL_DISPLAYEVENT_CONNECTED SDL_DISPLAYEVENT_DISCONNECTED
        ]
        ],
        SDL_DisplayOrientation => [
        qw[SDL_ORIENTATION_UNKNOWN
            SDL_ORIENTATION_LANDSCAPE SDL_ORIENTATION_LANDSCAPE_FLIPPED
            SDL_ORIENTATION_PORTRAIT  SDL_ORIENTATION_PORTRAIT_FLIPPED
        ]
        ],
        SDL_FlashOperation => [qw[SDL_FLASH_CANCEL SDL_FLASH_BRIEFLY SDL_FLASH_UNTIL_FOCUSED]],
        ;

    package SDL2::GLContext 0.01 {
        use SDL2::Utils qw[has];
        our $TYPE = has();    # opaque
    };
    enum SDL_GLattr => [
        qw[
            SDL_GL_RED_SIZE
            SDL_GL_GREEN_SIZE
            SDL_GL_BLUE_SIZE
            SDL_GL_ALPHA_SIZE
            SDL_GL_BUFFER_SIZE
            SDL_GL_DOUBLEBUFFER
            SDL_GL_DEPTH_SIZE
            SDL_GL_STENCIL_SIZE
            SDL_GL_ACCUM_RED_SIZE
            SDL_GL_ACCUM_GREEN_SIZE
            SDL_GL_ACCUM_BLUE_SIZE
            SDL_GL_ACCUM_ALPHA_SIZE
            SDL_GL_STEREO
            SDL_GL_MULTISAMPLEBUFFERS
            SDL_GL_MULTISAMPLESAMPLES
            SDL_GL_ACCELERATED_VISUAL
            SDL_GL_RETAINED_BACKING
            SDL_GL_CONTEXT_MAJOR_VERSION
            SDL_GL_CONTEXT_MINOR_VERSION
            SDL_GL_CONTEXT_EGL
            SDL_GL_CONTEXT_FLAGS
            SDL_GL_CONTEXT_PROFILE_MASK
            SDL_GL_SHARE_WITH_CURRENT_CONTEXT
            SDL_GL_FRAMEBUFFER_SRGB_CAPABLE
            SDL_GL_CONTEXT_RELEASE_BEHAVIOR
            SDL_GL_CONTEXT_RESET_NOTIFICATION
            SDL_GL_CONTEXT_NO_ERROR
        ]
        ],
        SDL_GLprofile => [
        [ SDL_GL_CONTEXT_PROFILE_CORE          => 0x0001 ],
        [ SDL_GL_CONTEXT_PROFILE_COMPATIBILITY => 0x0002 ],
        [ SDL_GL_CONTEXT_PROFILE_ES            => 0x0004 ]
        ],
        SDL_GLcontextFlag => [
        [ SDL_GL_CONTEXT_DEBUG_FLAG              => 0x0001 ],
        [ SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG => 0x0002 ],
        [ SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG      => 0x0004 ],
        [ SDL_GL_CONTEXT_RESET_ISOLATION_FLAG    => 0x0008 ]
        ],
        SDL_GLcontextReleaseFlag => [
        [ SDL_GL_CONTEXT_RELEASE_BEHAVIOR_NONE  => 0x0000 ],
        [ SDL_GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH => 0x0001 ]
        ],
        SDL_GLContextResetNotification => [
        [ SDL_GL_CONTEXT_RESET_NO_NOTIFICATION => 0x0000 ],
        [ SDL_GL_CONTEXT_RESET_LOSE_CONTEXT    => 0x0001 ]
        ];
    attach video => {
        SDL_GetNumVideoDrivers     => [ [],         'int' ],
        SDL_GetVideoDriver         => [ ['int'],    'string' ],
        SDL_VideoInit              => [ ['string'], 'int' ],
        SDL_VideoQuit              => [ [] ],
        SDL_GetCurrentVideoDriver  => [ [],                                      'string' ],
        SDL_GetNumVideoDisplays    => [ [],                                      'int' ],
        SDL_GetDisplayName         => [ ['int'],                                 'string' ],
        SDL_GetDisplayBounds       => [ [ 'int', 'SDL_Rect' ],                   'int' ],
        SDL_GetDisplayUsableBounds => [ [ 'int', 'SDL_Rect' ],                   'int' ],
        SDL_GetDisplayDPI          => [ [ 'int', 'float*', 'float*', 'float*' ], 'int' ],
        SDL_GetDisplayOrientation  => [ ['int'], 'SDL_DisplayOrientation' ],
        SDL_GetNumDisplayModes     => [ ['int'], 'int' ],
        SDL_GetDisplayMode         => [ [ 'int', 'int', 'SDL_DisplayMode' ], 'int' ],
        SDL_GetDesktopDisplayMode  => [ [ 'int', 'SDL_DisplayMode' ],        'int' ],
        SDL_GetCurrentDisplayMode  => [ [ 'int', 'SDL_DisplayMode' ],        'int' ],
        SDL_GetClosestDisplayMode  =>
            [ [ 'int', 'SDL_DisplayMode', 'SDL_DisplayMode' ], 'SDL_DisplayMode' ],
        SDL_GetWindowDisplayIndex => [ ['SDL_Window'],                      'int' ],
        SDL_SetWindowDisplayMode  => [ [ 'SDL_Window', 'SDL_DisplayMode' ], 'int' ],
        SDL_GetWindowDisplayMode  => [ [ 'SDL_Window', 'SDL_DisplayMode' ], 'int' ],
        SDL_GetWindowPixelFormat  => [ ['SDL_Window'],                      'uint32' ],
        SDL_CreateWindow => [ [ 'string', 'int', 'int', 'int', 'int', 'uint32' ] => 'SDL_Window' ],
        SDL_CreateWindowFrom => [ ['opaque']     => 'SDL_Window' ],
        SDL_GetWindowID      => [ ['SDL_Window'] => 'uint32' ],
        SDL_GetWindowFromID  => [ ['uint32']     => 'SDL_Window' ],
        SDL_GetWindowFlags   => [ ['SDL_Window'] => 'uint32' ],
        SDL_SetWindowTitle   => [ [ 'SDL_Window', 'string' ] ],
        SDL_GetWindowTitle   => [ ['SDL_Window'], 'string' ],
        SDL_SetWindowIcon    => [ [ 'SDL_Window', 'SDL_Surface' ] ],

        # These don't work correctly yet. (cast issues)
        SDL_SetWindowData            => [ [ 'SDL_Window', 'string', 'opaque' ], 'opaque' ],
        SDL_GetWindowData            => [ [ 'SDL_Window', 'string' ], 'opaque' ],
        SDL_SetWindowPosition        => [ [ 'SDL_Window', 'int',  'int' ] ],
        SDL_GetWindowPosition        => [ [ 'SDL_Window', 'int*', 'int*' ] ],
        SDL_SetWindowSize            => [ [ 'SDL_Window', 'int',  'int' ] ],
        SDL_GetWindowSize            => [ [ 'SDL_Window', 'int*', 'int*' ] ],
        SDL_GetWindowBordersSize     => [ [ 'SDL_Window', 'int*', 'int*', 'int*', 'int*' ], 'int' ],
        SDL_SetWindowMinimumSize     => [ [ 'SDL_Window', 'int',  'int' ] ],
        SDL_GetWindowMinimumSize     => [ [ 'SDL_Window', 'int*', 'int*' ] ],
        SDL_SetWindowMaximumSize     => [ [ 'SDL_Window', 'int',  'int' ] ],
        SDL_GetWindowMaximumSize     => [ [ 'SDL_Window', 'int*', 'int*' ] ],
        SDL_SetWindowBordered        => [ [ 'SDL_Window', 'SDL_bool' ] ],
        SDL_SetWindowResizable       => [ [ 'SDL_Window', 'SDL_bool' ] ],
        SDL_SetWindowAlwaysOnTop     => [ [ 'SDL_Window', 'SDL_bool' ] ],
        SDL_ShowWindow               => [ ['SDL_Window'] ],
        SDL_HideWindow               => [ ['SDL_Window'] ],
        SDL_RaiseWindow              => [ ['SDL_Window'] ],
        SDL_MaximizeWindow           => [ ['SDL_Window'] ],
        SDL_MinimizeWindow           => [ ['SDL_Window'] ],
        SDL_RestoreWindow            => [ ['SDL_Window'] ],
        SDL_SetWindowFullscreen      => [ [ 'SDL_Window', 'uint32' ],       'int' ],
        SDL_GetWindowSurface         => [ ['SDL_Window'],                   'SDL_Surface' ],
        SDL_UpdateWindowSurface      => [ ['SDL_Window'],                   'int' ],
        SDL_UpdateWindowSurfaceRects => [ [ 'SDL_Window', 'Rects', 'int' ], 'int' ],
        SDL_UpdateWindowSurfaceRects => [
            [ 'SDL_Window', 'RectList_t', 'int' ],
            'int' => sub ( $inner, $window, $_rects, $numrects ) {
                my $rects = $SDL2::rect::List->create(
                    [ map { { x => $_->x, y => $_->y, w => $_->w, h => $_->h } } @$_rects ] );
                $inner->( $window, $rects, $numrects );
            }
        ],
        SDL_SetWindowGrab         => [ [ 'SDL_Window', 'SDL_bool' ] ],
        SDL_SetWindowKeyboardGrab => [ [ 'SDL_Window', 'SDL_bool' ] ],
        SDL_SetWindowMouseGrab    => [ [ 'SDL_Window', 'SDL_bool' ] ],
        SDL_GetWindowGrab         => [ ['SDL_Window'],                 'SDL_bool' ],
        SDL_GetWindowKeyboardGrab => [ ['SDL_Window'],                 'SDL_bool' ],
        SDL_GetWindowMouseGrab    => [ ['SDL_Window'],                 'SDL_bool' ],
        SDL_GetGrabbedWindow      => [ [],                             'SDL_Window' ],
        SDL_SetWindowBrightness   => [ [ 'SDL_Window', 'float' ],      'int' ],
        SDL_GetWindowBrightness   => [ ['SDL_Window'],                 'float' ],
        SDL_SetWindowOpacity      => [ [ 'SDL_Window', 'float' ],      'int' ],
        SDL_GetWindowOpacity      => [ [ 'SDL_Window', 'float*' ],     'int' ],
        SDL_SetWindowModalFor     => [ [ 'SDL_Window', 'SDL_Window' ], 'int' ],
        SDL_SetWindowInputFocus   => [ ['SDL_Window'],                 'int' ],
        SDL_SetWindowGammaRamp    =>
            [ [ 'SDL_Window', 'uint16[256]', 'uint16[256]', 'uint16[256]' ], 'int' ],
        SDL_GetWindowGammaRamp => [
            [ 'SDL_Window', 'uint16[256]', 'uint16[256]', 'uint16[256]' ], 'int'

                #=> sub ( $inner, $window ) {
                #    my @red = my @blue = my @green = map { \0 } 1 .. 256;
                #    my $ok  = $inner->( $window, \@red, \@green, \@blue );
                #    $ok == 0 ? ( \@red, \@green, \@blue ) : $ok;
                #}
        ]
    };
    enum SDL_HitTestResult => [
        qw[SDL_HITTEST_NORMAL
            SDL_HITTEST_DRAGGABLE
            SDL_HITTEST_RESIZE_TOPLEFT
            SDL_HITTEST_RESIZE_TOP
            SDL_HITTEST_RESIZE_TOPRIGHT
            SDL_HITTEST_RESIZE_RIGHT
            SDL_HITTEST_RESIZE_BOTTOMRIGHT
            SDL_HITTEST_RESIZE_BOTTOM
            SDL_HITTEST_RESIZE_BOTTOMLEFT
            SDL_HITTEST_RESIZE_LEFT]
    ];
    #
    ffi->type( '(opaque,opaque,opaque)->opaque' => 'SDL_HitTest' );
    attach video => {
        SDL_SetWindowHitTest => [
            [ 'SDL_Window', 'SDL_HitTest', 'opaque' ],
            'int' => sub ( $xsub, $window, $callback, $callback_data = () ) {    # Fake void pointer
                my $cb = $callback;
                if ( defined $callback ) {
                    $cb = FFI::Platypus::Closure->new(
                        sub ( $win, $area, $data ) {
                            $callback->(
                                ffi->cast( 'opaque' => 'SDL_Window', $win ),
                                ffi->cast( 'opaque' => 'SDL_Point',  $area ),
                                $callback_data
                            );
                        }
                    );
                    $cb->sticky;
                }
                $xsub->( $window, $cb, $callback_data );
                return $cb;
            }
        ],
        SDL_FlashWindow          => [ [ 'SDL_Window', 'SDL_FlashOperation' ], 'int' ],
        SDL_DestroyWindow        => [ ['SDL_Window'] ],
        SDL_IsScreenSaverEnabled => [ [], 'SDL_bool' ],
        SDL_EnableScreenSaver    => [ [] ],
        SDL_DisableScreenSaver   => [ [] ],
        #
        SDL_GL_LoadLibrary        => [ ['string'], 'int' ],
        SDL_GL_GetProcAddress     => [ ['string'], 'opaque' ],
        SDL_GL_UnloadLibrary      => [ [] ],
        SDL_GL_ExtensionSupported => [ ['string'], 'SDL_bool' ],
        SDL_GL_ResetAttributes    => [ [] ],
        SDL_GL_SetAttribute       => [ [ 'SDL_GLattr', 'int' ],           'int' ],
        SDL_GL_GetAttribute       => [ [ 'SDL_GLattr', 'int*' ],          'int' ],
        SDL_GL_CreateContext      => [ ['SDL_Window'],                    'SDL_GLContext' ],
        SDL_GL_MakeCurrent        => [ [ 'SDL_Window', 'SDL_GLContext' ], 'int' ],
        SDL_GL_GetCurrentWindow   => [ [],                                'SDL_Window' ],
        SDL_GL_GetCurrentContext  => [ [],                                'SDL_GLContext' ],
        SDL_GL_GetDrawableSize    => [ [ 'SDL_Window', 'int*', 'int*' ] ],
        SDL_GL_SetSwapInterval    => [ ['int'], 'int' ],
        SDL_GL_GetSwapInterval    => [ [],      'int' ],
        SDL_GL_SwapWindow         => [ ['SDL_Window'] ],
        SDL_GL_DeleteContext      => [ ['SDL_GLContext'] ]
    };

=encoding utf-8

=head1 NAME

SDL2::video - SDL Video Functions

=head1 SYNOPSIS

    use SDL2 qw[:version];
    SDL_GetVersion( my $ver = SDL2::version->new );
    CORE::say sprintf 'SDL version %d.%d.%d', $ver->major, $ver->minor, $ver->patch;

=head1 DESCRIPTION

SDL2::version represents the library's version as three levels: major, minor,
and patch level.

=head1 Functions

These may be imported by name or with the C<:video> tag.

=head2 C<SDL_GetNumVideoDrivers( )>

Get the number of video drivers compiled into SDL.

	my $num = SDL_GetNumVideoDrivers( );

Returns a number >= 1 on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetVideoDriver( ... )>

Get the name of a built in video driver.

	CORE::say SDL_GetVideoDriver($_) for 0 .. SDL_GetNumVideoDrivers( ) - 1;

The video drivers are presented in the order in which they are normally checked
during initialization.

Expected parameters include:

=over

=item C<index> - the index of a video driver

=back

Returns the name of the video driver with the given C<index>.

=head2 C<SDL_VideoInit( ... )>

Initialize the video subsystem, optionally specifying a video driver.

	SDL_VideoInit( 'x11' );

This function initializes the video subsystem, setting up a connection to the
window manager, etc, and determines the available display modes and pixel
formats, but does not initialize a window or graphics mode.

If you use this function and you haven't used the C<SDL_INIT_VIDEO> flag with
either C<SDL_Init( ... )> or C<SDL_InitSubSystem( ... )>, you should call
C<SDL_VideoQuit( )> before calling C<SDL_Quit( )>.

It is safe to call this function multiple times. C<SDL_VideoInit( )> will call
C<SDL_VideoQuit( )> itself if the video subsystem has already been initialized.

You can use C<SDL_GetNumVideoDrivers( )> and C<SDL_GetVideoDriver( )> to find a
specific C<driver_name>.

Expected parameters include:

=over

=item C<driver_name> - the name of a video driver to initialize, or C<undef> for the default driver

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_VideoQuit( )>

Shut down the video subsystem, if initialized with SDL_VideoInit().

	SDL_VideoQuit( );

This function closes all windows, and restores the original video mode.

=head2 C<SDL_GetCurrentVideoDriver( ... )>

Get the name of the currently initialized video driver.

	my $driver = SDL_GetCurrentVideoDriver( );

Returns the name of the current video driver or C<undef> if no driver has been
initialized.

=head2 C<SDL_GetNumVideoDisplays( ... )>

Get the number of available video displays.

	my $screens = SDL_GetNumVideoDisplays( );

Returns a number >= 1 or a negative error code on failure; call C<SDL_GetError(
)> for more information.

=head2 C<SDL_GetDisplayName( ... )>

Get the name of a display in UTF-8 encoding.

	my $screen = SDL_GetDisplayName( 0 );

Expected parameters include:

=over

=item C<displayIndex> the index of display from which the name should be queried

=back

Returns the name of a display or C<undef> for an invalid display index or
failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_GetDisplayBounds( ... )>

Get the desktop area represented by a display.

	SDL_GetDisplayBounds( 0, my $rect );

The primary display (C<displayIndex> zero) is always located at C<0,0>.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=item C<rect> - the L<SDL2::Rect> structure filled in with the display bounds

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetDisplayUsableBounds( ... )>

Get the usable desktop area represented by a display.

	SDL_GetDisplayUsableBounds( 0, my $rect );

The primary display (C<displayIndex> zero) is always located at C<0,0>.

This is the same area as C<SDL_GetDisplayBounds( ... )> reports, but with
portions reserved by the system removed. For example, on Apple's macOS, this
subtracts the area occupied by the menu bar and dock.

Setting a window to be fullscreen generally bypasses these unusable areas, so
these are good guidelines for the maximum space available to a non-fullscreen
window.

The parameter C<rect> is ignored if it is C<undef>.

This function also returns C<-1> if the parameter C<displayIndex> is out of
range.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query the usable bounds from

=item C<rect> - the L<SDL2::Rect> structure filled in with the display bounds

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetDisplayDPI( ... )>

Get the dots/pixels-per-inch for a display.

	SDL_GetDisplayDPI( 0, \my $ddpi, \my $hdpi, \my $vdpi );

Diagonal, horizontal and vertical DPI can all be optionally returned if the
appropriate parameter is non-NULL.

A failure of this function usually means that either no DPI information is
available or the C<displayIndex> is out of range.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display from which DPI information should be queried

=item C<ddpi> - a pointer filled in with the diagonal DPI of the display; may be C<undef>

=item C<hdpi> - a pointer filled in with the horizontal DPI of the display; may be C<undef>

=item C<vdpi> - a pointer filled in with the vertical DPI of the display; may be C<undef>

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetDisplayOrientation( ... )>

Get the orientation of a display.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=back

Returns The SDL_DisplayOrientation enum value of the display, or
C<SDL_ORIENTATION_UNKNOWN> if it isn't available.

=head2 C<SDL_GetNumDisplayModes( ... )>

Get the number of available display modes.

The C<displayIndex> needs to be in the range from 0 to
C<SDL_GetNumVideoDisplays( ) - 1>.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=back

Returns a number >= 1 on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetDisplayMode( ... )>

Get information about a specific display mode.

The display modes are sorted in this priority:

=over

=item - width -> largest to smallest

=item - height -> largest to smallest

=item - bits per pixel -> more colors to fewer colors

=item - packed pixel layout -> largest to smallest

=item - refresh rate -> highest to lowest

=back

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=item C<modeIndex> - the index of the display mode to query

=item C<mode> - an L<SDL2::DisplayMode> structure filled in with the mode at C<modeIndex>

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetDesktopDisplayMode( ... )>

Get information about the desktop's display mode.

There's a difference between this function and L<< C<SDL_GetCurrentDisplayMode(
... )>|/C<SDL_GetCurrentDisplayMode( ... )> >> when SDL runs fullscreen and has
changed the resolution. In that case this function will return the previous
native display mode, and not the current display mode.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=item C<mode> - an L<SDL2::DisplayMode> structure filled in with the current display mode

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetCurrentDisplayMode( ... )>

Get information about the current display mode.

There's a difference between this function and L<< C<SDL_GetDesktopDisplayMode(
... )>|/C<SDL_GetDesktopDisplayMode( ... )> >> when SDL runs fullscreen and has
changed the resolution. In that case this function will return the current
display mode, and not the previous native display mode.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=item C<mode> - an L<SDL2::DisplayMode> structure filled in with the current display mode

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetClosestDisplayMode( ... )>

Get the closest match to the requested display mode.

The available display modes are scanned and C<closest> is filled in with the
closest mode matching the requested mode and returned. The mode format and
refresh rate default to the desktop mode if they are set to C<0>. The modes are
scanned with size being first priority, format being second priority, and
finally checking the refresh rate. If all the available modes are too small,
then C<undef> is returned.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=item C<mode> - an L<SDL2::DisplayMode> structure containing the desired display mode

=item C<closest> - an L<SDL2::DisplayMode> structure filled in with the closest match of the available display modes

=back

Returns the passed in value C<closest> or C<undef> if no matching video mode
was available; call C<SDL_GetError( )> for more information.

=head2 C<SDL_GetWindowDisplayIndex( ... )>

Get the index of the display associated with a window.

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns the index of the display containing the center of the window on success
or a negative error code on failure; call C<SDL_GetError( )> for more
information.

=head2 C<SDL_SetWindowDisplayMode( ... )>

Set the display mode to use when a window is visible at fullscreen.

This only affects the display mode used when the window is fullscreen. To
change the window size when the window is not fullscreen, use
SDL_SetWindowSize().

Expected parameters include:

=over

=item C<window> - the window to affect

=item C<mode> - the L<SDL2::DisplayMode> structure representing the mode to use, or C<undef> to use the window's dimensions and the desktop's format and refresh rate

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetWindowDisplayMode( ... )>

Query the display mode to use when a window is visible at fullscreen.

Expected parameters include:

=over

=item C<window> - the window to query

=item C<mode> - an L<SDL2::DisplayMode> structure filled in with the fullscreen display mode

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetWindowPixelFormat( ... )>

Get the pixel format associated with the window.

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns the pixel format of the window on success or C<SDL_PIXELFORMAT_UNKNOWN>
on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_CreateWindow( ... )>

Create a window with the specified position, dimensions, and flags.

	my $window = SDL_CreateWindow( 'Example',
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        1280, 720,
      	SDL_WINDOW_SHOWN
    );

C<flags> may be any of the following OR'd together:

=over

=item C<SDL_WINDOW_FULLSCREEN> - fullscreen window

=item C<SDL_WINDOW_FULLSCREEN_DESKTOP> - fullscreen window at desktop resolution

=item C<SDL_WINDOW_OPENGL> - window usable with an OpenGL context

=item C<SDL_WINDOW_VULKAN> - window usable with a Vulkan instance

=item C<SDL_WINDOW_METAL> - window usable with a Metal instance

=item C<SDL_WINDOW_HIDDEN> - window is not visible

=item C<SDL_WINDOW_BORDERLESS> - no window decoration

=item C<SDL_WINDOW_RESIZABLE> - window can be resized

=item C<SDL_WINDOW_MINIMIZED> - window is minimized

=item C<SDL_WINDOW_MAXIMIZED> - window is maximized

=item C<SDL_WINDOW_INPUT_GRABBED> - window has grabbed input focus

=item C<SDL_WINDOW_ALLOW_HIGHDPI> - window should be created in high-DPI mode if supported (>= SDL 2.0.1)

=back

C<SDL_WINDOW_SHOWN> is ignored by C<SDL_CreateWindow( )>. The SDL_Window is
implicitly shown if C<SDL_WINDOW_HIDDEN> is not set. C<SDL_WINDOW_SHOWN> may be
queried later using L<< C<SDL_GetWindowFlags( ... )>|/C<SDL_GetWindowFlags( ...
)> >>.

On Apple's macOS, you B<must> set the NSHighResolutionCapable Info.plist
property to YES, otherwise you will not receive a High-DPI OpenGL canvas.

If the window is created with the C<SDL_WINDOW_ALLOW_HIGHDPI> flag, its size in
pixels may differ from its size in screen coordinates on platforms with
high-DPI support (e.g. iOS and macOS). Use L<< C<SDL_GetWindowSize( ...
)>|/C<SDL_GetWindowSize( ... )> >> to query the client area's size in screen
coordinates, and L<< C<SDL_GL_GetDrawableSize( ...
)>|/C<SDL_GL_GetDrawableSize( ... )> >> or C<SDL_GetRendererOutputSize( ... )>
to query the drawable size in pixels.

If the window is set fullscreen, the width and height parameters C<w> and C<h>
will not be used. However, invalid size parameters (e.g. too large) may still
fail. Window size is actually limited to 16384 x 16384 for all platforms at
window creation.

If the window is created with any of the SDL_WINDOW_OPENGL or
C<SDL_WINDOW_VULKAN> flags, then the corresponding LoadLibrary function (L<<
C<SDL_GL_LoadLibrary( ... )>|/C<SDL_GL_LoadLibrary( ... )> >> or
C<SDL_Vulkan_LoadLibrary( ... )>) is called and the corresponding
C<UnloadLibrary> function is called by L<< C<SDL_DestroyWindow( ...
)>|/C<SDL_DestroyWindow( ... )> >>.

If C<SDL_WINDOW_VULKAN> is specified and there isn't a working Vulkan driver,
C<SDL_CreateWindow( ... )> will fail because C<SDL_Vulkan_LoadLibrary( ... )>
will fail.

If C<SDL_WINDOW_METAL> is specified on an OS that does not support Metal,
C<SDL_CreateWindow( ... )> will fail.

On non-Apple devices, SDL requires you to either not link to the Vulkan loader
or link to a dynamic library version. This limitation may be removed in a
future version of SDL.

Expected parameters include:

=over

=item C<title> - the title of the window, in UTF-8 encoding

=item C<x> - the x position of the window, C<SDL_WINDOWPOS_CENTERED>, or C<SDL_WINDOWPOS_UNDEFINED>

=item C<y> - the y position of the window, C<SDL_WINDOWPOS_CENTERED>, or C<SDL_WINDOWPOS_UNDEFINED>

=item C<w> - the width of the window, in screen coordinates

=item C<h> - the height of the window, in screen coordinates

=item C<flags> - C<0>, or one or more C<SDL_WindowFlags> OR'd together

=back

Returns the window that was created or NULL on failure; call C<SDL_GetError( )>
for more information.

=head2 C<SDL_CreateWindowFrom( ... )>

Create an SDL window from an existing native window.

In some cases (e.g. OpenGL) and on some platforms (e.g. Microsoft Windows) the
hint C<SDL_HINT_VIDEO_WINDOW_SHARE_PIXEL_FORMAT> needs to be configured before
using L<< C<SDL_CreateWindowFrom( ... )>|/C<SDL_CreateWindowFrom( ... )> >>.

Expected parameters include:

=over

=item C<data> - a pointer to driver-dependent window creation data, typically your native window cast to a void*

=back

Returns the window that was created or NULL on failure; call C<SDL_GetError( )>
for more information.

=head2 C<SDL_GetWindowID( ... )>

Get the numeric ID of a window.

The numeric ID is what L<SDL2::WindowEvent> references, and is necessary to map
these events to specific L<SDL2::Window> objects.

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns the ID of the window on success or C<0> on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetWindowFromID( ... )>

Get a window from a stored ID.

The numeric ID is what L<SDL2::WindowEvent> references, and is necessary to map
these events to specific L<SDL2::Window> objects.

Expected parameters include:

=over

=item C<id> - the ID of the window

=back

Returns the window associated with C<id> or C<undef> if it doesn't exist; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetWindowFlags( ... )>

Get the window flags.

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns a mask of the C<SDL_WindowFlags> associated with C<window>.

=head2 C<SDL_SetWindowTitle( ... )>

Set the title of a window.

This string is expected to be in UTF-8 encoding.

Expected parameters include:

=over

=item C<window> - the window to change

=item C<title> - the desired window title in UTF-8 format

=back

=head2 C<SDL_GetWindowTitle( ... )>

Get the title of a window.

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns the title of the window in UTF-8 format or C<""> if there is no title.

=head2 C<SDL_SetWindowIcon( ... )>

Set the icon for a window.

Expected parameters include:

=over

=item C<window> - the window to change

=item C<icon> - an L<SDL2::Surface> structure containing the icon for the window

=back

=head2 C<SDL_SetWindowData( ... )>

Associate an arbitrary named pointer with a window.

C<name> is case-sensitive.

Expected parameters include:

=over

=item C<window> - the window to associate with the pointer

=item C<name> - the name of the pointer

=item C<userdata> - the associated pointer

=back

Returns the previous value associated with C<name>.

=head2 C<SDL_GetWindowData( ... )>

Retrieve the data pointer associated with a window.

Expected parameters include:

=over

=item C<window> - the window to query

=item C<name> - the name of the pointer

=back

Returns the value associated with C<name>.

=head2 C<SDL_SetWindowPosition( ... )>

Set the position of a window.

The window coordinate origin is the upper left of the display.

Expected parameters include:

=over

=item C<window> - the window to reposition

=item C<x> - the x coordinate of the window in screen coordinates, or C<SDL_WINDOWPOS_CENTERED> or C<SDL_WINDOWPOS_UNDEFINED>

=item C<y> - the y coordinate of the window in screen coordinates, or C<SDL_WINDOWPOS_CENTERED> or C<SDL_WINDOWPOS_UNDEFINED>

=back

=head2 C<SDL_GetWindowPosition( ... )>

Get the position of a window.

If you do not need the value for one of the positions a C<undef> may be passed
in the C<x> or C<y> parameter.

Expected parameters include:

=over

=item C<window> - the window to query

=item C<x> - a pointer filled in with the x position of the window, in screen coordinates, may be C<undef>

=item C<y> - a pointer filled in with the y position of the window, in screen coordinates, may be C<undef>

=back

=head2 C<SDL_SetWindowSize( ... )>

Set the size of a window's client area.

The window size in screen coordinates may differ from the size in pixels, if
the window was created with C<SDL_WINDOW_ALLOW_HIGHDPI> on a platform with
high-dpi support (e.g. iOS or macOS). Use L<< C<SDL_GL_GetDrawableSize( ...
)>|/C<SDL_GL_GetDrawableSize( ... )> >> or C<SDL_GetRendererOutputSize( ... )>
to get the real client area size in pixels.

Fullscreen windows automatically match the size of the display mode, and you
should use L<< C<SDL_SetWindowDisplayMode( ... )>|/C<SDL_SetWindowDisplayMode(
... )> >> to change their size.

Expected parameters include:

=over

=item C<window> - the window to change

=item C<w> - the width of the window in pixels, in screen coordinates, must be > 0

=item C<h> - the height of the window in pixels, in screen coordinates, must be > 0

=back

=head2 C<SDL_GetWindowSize( ... )>

Get the size of a window's client area.

C<undef> can safely be passed as the C<w> or C<h> parameter if the width or
height value is not desired.

The window size in screen coordinates may differ from the size in pixels, if
the window was created with C<SDL_WINDOW_ALLOW_HIGHDPI> on a platform with
high-dpi support (e.g. iOS or macOS). Use SDL_GL_GetDrawableSize(),
C<SDL_Vulkan_GetDrawableSize( ... )>, or C<SDL_GetRendererOutputSize( ... )> to
get the real client area size in pixels.

Expected parameters include:

=over

=item C<window> - the window to query the width and height from

=item C<w> - a pointer filled in with the width of the window, in screen coordinates, may be C<undef>

=item C<h> - a pointer filled in with the height of the window, in screen coordinates, may be C<undef>

=back

=head2 C<SDL_GetWindowBordersSize( ... )>

Get the size of a window's borders (decorations) around the client area.

Note: If this function fails (returns C<-1>), the size values will be
initialized to C<0, 0, 0, 0> (if a non-NULL pointer is provided), as if the
window in question was borderless.

Note: This function may fail on systems where the window has not yet been
decorated by the display server (for example, immediately after calling L<<
C<SDL_CreateWindow( ... )>|/C<SDL_CreateWindow( ... )> >>). It is recommended
that you wait at least until the window has been presented and composited, so
that the window system has a chance to decorate the window and provide the
border dimensions to SDL.

This function also returns C<-1> if getting the information is not supported.

Expected parameters include:

=over

=item C<window> - the window to query the size values of the border (decorations) from

=item C<top> - pointer to variable for storing the size of the top border; C<undef> is permitted

=item C<left> - pointer to variable for storing the size of the left border; C<undef> is permitted

=item C<bottom> - pointer to variable for storing the size of the bottom border; C<undef> is permitted

=item C<right> - pointer to variable for storing the size of the right border; C<undef> is permitted

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SetWindowMinimumSize( ... )>

Set the minimum size of a window's client area.

Expected parameters include:

=over

=item C<window> - the window to change

=item C<min_w> - the minimum width of the window in pixels

=item C<min_h> - the minimum height of the window in pixels

=back

=head2 C<SDL_GetWindowMinimumSize( ... )>

Get the minimum size of a window's client area.

Expected parameters include:

=over

=item C<window> - the window to query

=item C<w> - a pointer filled in with the minimum width of the window, may be C<undef>

=item C<h> - a pointer filled in with the minimum height of the window, may be C<undef>

=back

=head2 C<SDL_SetWindowMaximumSize( ... )>

Set the maximum size of a window's client area.

Expected parameters include:

=over

=item C<window> - the window to change

=item C<max_w> - the maximum width of the window in pixels

=item C<max_h> - the maximum height of the window in pixels

=back

=head2 C<SDL_GetWindowMaximumSize( ... )>

Get the maximum size of a window's client area.

Expected parameters include:

=over

=item C<window> - the window to query

=item C<w> - a pointer filled in with the maximum width of the window, may be C<undef>

=item C<h> - a pointer filled in with the maximum height of the window, may be C<undef>

=back

=head2 C<SDL_SetWindowBordered( ... )>

Set the border state of a window.

This will add or remove the window's C<SDL_WINDOW_BORDERLESS> flag and add or
remove the border from the actual window. This is a no-op if the window's
border already matches the requested state.

You can't change the border state of a fullscreen window.

Expected parameters include:

=over

=item C<window> - the window of which to change the border state

=item C<bordered> - C<SDL_FALSE> to remove border, C<SDL_TRUE> to add border

=back

=head2 C<SDL_SetWindowResizable( ... )>

Set the user-resizable state of a window.

This will add or remove the window's `SDL_WINDOW_RESIZABLE` flag and
allow/disallow user resizing of the window. This is a no-op if the window's
resizable state already matches the requested state.

You can't change the resizable state of a fullscreen window.

Expected parameters include:

=over

=item C<window> - the window of which to change the resizable state

=item C<resizable> - C<SDL_TRUE> to allow resizing, C<SDL_FALSE> to disallow

=back

=head2 C<SDL_SetWindowAlwaysOnTop( ... )>

Set the window to always be above the others.

This will add or remove the window's C<SDL_WINDOW_ALWAYS_ON_TOP> flag. This
will bring the window to the front and keep the window above the rest.

Expected parameters include:

=over

=item C<window> - window of which to change the always on top state

=item C<on_top> - C<SDL_TRUE> to set the window always on top, C<SDL_FALSE> to disable

=back

=head2 C<SDL_ShowWindow( ... )>

Show a window.

Expected parameters include:

=over

=item C<window> - the window to show

=back

=head2 C<SDL_HideWindow( ... )>

Hide a window.

Expected parameters include:

=over

=item C<window> - the window to hide

=back

=head2 C<SDL_RaiseWindow( ... )>

Raise a window above other windows and set the input focus.

Expected parameters include:

=over

=item C<window> - the window to raise

=back

=head2 C<SDL_MaximizeWindow( ... )>

Make a window as large as possible.

Expected parameters include:

=over

=item C<window> - the window to maximize

=back

=head2 C<SDL_MinimizeWindow( ... )>

Minimize a window to an iconic representation.

Expected parameters include:

=over

=item C<window> - the window to minimize

=back

=head2 C<SDL_RestoreWindow( ... )>

Restore the size and position of a minimized or maximized window.

Expected parameters include:

=over

=item C<window> - the window to restore

=back

=head2 C<SDL_SetWindowFullscreen( ... )>

Set a window's fullscreen state.

C<flags> may be C<SDL_WINDOW_FULLSCREEN>, for "real" fullscreen with a
videomode change; C<SDL_WINDOW_FULLSCREEN_DESKTOP> for "fake" fullscreen that
takes the size of the desktop; and 0 for windowed mode.

Expected parameters include:

=over

=item C<window> - the window to change

=item C<flags> - C<SDL_WINDOW_FULLSCREEN>, C<SDL_WINDOW_FULLSCREEN_DESKTOP> or C<0>

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetWindowSurface( ... )>

Get the SDL surface associated with the window.

A new surface will be created with the optimal format for the window, if
necessary. This surface will be freed when the window is destroyed. Do not free
this surface.

This surface will be invalidated if the window is resized. After resizing a
window this function must be called again to return a valid surface.

You may not combine this with 3D or the rendering API on this window.

This function is affected by C<SDL_HINT_FRAMEBUFFER_ACCELERATION>.


Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns the surface associated with the window, or NULL on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_UpdateWindowSurface( ... )>

Copy the window surface to the screen.

This is the function you use to reflect any changes to the surface on the
screen.

Expected parameters include:

=over

=item C<window> - the window to update

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_UpdateWindowSurfaceRects( ... )>

Copy areas of the window surface to the screen.

This is the function you use to reflect changes to portions of the surface on
the screen.

Expected parameters include:

=over

=item C<window> - the window to update

=item C<rects> - an array of L<SDL2::Rect> structures representing areas of the surface to copy

=item C<numrects> - the number of rectangles

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SetWindowGrab( ... )>

Set a window's input grab mode.

When input is grabbed the mouse is confined to the window.

If the caller enables a grab while another window is currently grabbed, the
other window loses its grab in favor of the caller's window.

Expected parameters include:

=over

=item C<window> - the window for which the input grab mode should be set

=item C<grabbed> - C<SDL_TRUE> to grab input or C<SDL_FALSE> to release input

=back

=head2 C<SDL_SetWindowKeyboardGrab( ... )>

Set a window's keyboard grab mode.

If the caller enables a grab while another window is currently grabbed, the
other window loses its grab in favor of the caller's window.

Expected parameters include:

=over

=item C<window> - window for which the keyboard grab mode should be set

=item C<grabbed> - C<SDL_TRUE> to grab keyboard, C<SDL_FALSE> to release

=back

=head2 C<SDL_SetWindowMouseGrab( ... )>

Set a window's mouse grab mode.

Expected parameters include:

=over

=item C<window> - the window for which the mouse grab mode should be set.

=back

=head2 C<SDL_GetWindowGrab( ... )>

Get a window's input grab mode.

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns C<SDL_TRUE> if input is grabbed, C<SDL_FALSE> otherwise.

=head2 C<SDL_GetWindowKeyboardGrab( ... )>

Get a window's keyboard grab mode.

Expected parameters include:

=over

=item C<param> - window the window to query

=back

Returns C<SDL_TRUE> if keyboard is grabbed, and C<SDL_FALSE> otherwise.

=head2 C<SDL_GetWindowMouseGrab( ... )>

Get a window's mouse grab mode.

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns C<SDL_TRUE> if mouse is grabbed, and C<SDL_FALSE> otherwise.

=head2 C<SDL_GetGrabbedWindow( )>

Get the window that currently has an input grab enabled.

Returns the window if input is grabbed or C<undef> otherwise.

=head2 C<SDL_SetWindowBrightness( ... )>

Set the brightness (gamma multiplier) for a given window's display.

Despite the name and signature, this method sets the brightness of the entire
display, not an individual window. A window is considered to be owned by the
display that contains the window's center pixel. (The index of this display can
be retrieved using SDL_GetWindowDisplayIndex().) The brightness set will not
follow the window if it is moved to another display.

Many platforms will refuse to set the display brightness in modern times. You
are better off using a shader to adjust gamma during rendering, or something
similar.

Expected parameters include:

=over

=item C<window> - the window used to select the display whose brightness will be changed

=item C<brightness> - the brightness (gamma multiplier) value to set where C<0.0> is completely dark and C<1.0> is normal brightness

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetWindowBrightness( ... )>

Get the brightness (gamma multiplier) for a given window's display.

Despite the name and signature, this method retrieves the brightness of the
entire display, not an individual window. A window is considered to be owned by
the display that contains the window's center pixel. (The index of this display
can be retrieved using L<< C<SDL_GetWindowDisplayIndex( ...
)>|/C<SDL_GetWindowDisplayIndex( ... )> >>.)

Expected parameters include:

=over

=item C<window> - the window used to select the display whose brightness will be queried

=back

Returns the brightness for the display where C<0.0> is completely dark and
C<1.0> is normal brightness.

=head2 C<SDL_SetWindowOpacity( ... )>

Set the opacity for a window.

The parameter C<opacity> will be clamped internally between C<0.0>
(transparent) and C<1.0> (opaque).

This function also returns C<-1> if setting the opacity isn't supported.

Expected parameters include:

=over

=item C<window> - the window which will be made transparent or opaque

=item C<opacity> - the opacity value (C<0.0> - transparent, C<1.0> - opaque)

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetWindowOpacity( ... )>

Get the opacity of a window.

If transparency isn't supported on this platform, opacity will be reported as
C<1.0> without error.

The parameter C<opacity> is ignored if it is C<undef>.

This function also returns -1 if an invalid window was provided.

Expected parameters include:

=over

=item C<window> - the window to get the current opacity value from

=item C<out_opacity> - the float filled in (0.0f - transparent, 1.0f - opaque)

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SetWindowModalFor( ... )>

Set the window as a modal for another window.

Expected parameters include:

=over

=item C<modal_window> - the window that should be set modal

=item C<parent_window> - the parent window for the modal window

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SetWindowInputFocus( ... )>

Explicitly set input focus to the window.

You almost certainly want L<< C<SDL_RaiseWindow( ... )>|/C<SDL_RaiseWindow( ...
)> >> instead of this function. Use this with caution, as you might give focus
to a window that is completely obscured by other windows.

Expected parameters include:

=over

=item C<window> - the window that should get the input focus

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SetWindowGammaRamp( ... )>

Set the gamma ramp for the display that owns a given window.

Set the gamma translation table for the red, green, and blue channels of the
video hardware. Each table is an array of 256 16-bit quantities, representing a
mapping between the input and output for that channel. The input is the index
into the array, and the output is the 16-bit gamma value at that index, scaled
to the output color precision.

Despite the name and signature, this method sets the gamma ramp of the entire
display, not an individual window. A window is considered to be owned by the
display that contains the window's center pixel. (The index of this display can
be retrieved using L<< C<SDL_GetWindowDisplayIndex( ...
)>|/C<SDL_GetWindowDisplayIndex( ... )> >>.) The gamma ramp set will not follow
the window if it is moved to another display.

Expected parameters include:

=over

=item C<window> - the window used to select the display whose gamma ramp will be changed

=item C<red> - a 256 element array of 16-bit quantities representing the translation table for the red channel, or C<undef>

=item C<green> - a 256 element array of 16-bit quantities representing the translation table for the green channel, or C<undef>

=item C<blue> - a 256 element array of 16-bit quantities representing the translation table for the blue channel, or C<undef>

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetWindowGammaRamp( ... )>

Get the gamma ramp for a given window's display.

Despite the name and signature, this method retrieves the gamma ramp of the
entire display, not an individual window. A window is considered to be owned by
the display that contains the window's center pixel. (The index of this display
can be retrieved using L<< C<SDL_GetWindowDisplayIndex( ...
)>|/C<SDL_GetWindowDisplayIndex( ... )> >>.)


Expected parameters include:

=over

=item C<window> - the window used to select the display whose gamma ramp will be queried

=item C<red> - a 256 element array of 16-bit quantities filled in with the translation table for the red channel, or C<undef>

=item C<green> - a 256 element array of 16-bit quantities filled in with the translation table for the green channel, or C<undef>

=item C<blue> - a 256 element array of 16-bit quantities filled in with the translation table for the blue channel, or C<undef>

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SetWindowHitTest( ... )>

Provide a callback that decides if a window region has special properties.

Normally windows are dragged and resized by decorations provided by the system
window manager (a title bar, borders, etc), but for some apps, it makes sense
to drag them from somewhere else inside the window itself; for example, one
might have a borderless window that wants to be draggable from any part, or
simulate its own title bar, etc.

This function lets the app provide a callback that designates pieces of a given
window as special. This callback is run during event processing if we need to
tell the OS to treat a region of the window specially; the use of this callback
is known as "hit testing."

Mouse input may not be delivered to your application if it is within a special
area; the OS will often apply that input to moving the window or resizing the
window and not deliver it to the application.

Specifying C<undef> for a callback disables hit-testing. Hit-testing is
disabled by default.

Platforms that don't support this functionality will return C<-1>
unconditionally, even if you're attempting to disable hit-testing.

Your callback may fire at any time, and its firing does not indicate any
specific behavior (for example, on Windows, this certainly might fire when the
OS is deciding whether to drag your window, but it fires for lots of other
reasons, too, some unrelated to anything you probably care about _and when the
mouse isn't actually at the location it is testing_). Since this can fire at
any time, you should try to keep your callback efficient, devoid of
allocations, etc.

Expected parameters include:

=over

=item C<window> - the window to set hit-testing on

=item C<callback> - the function to call when doing a hit-test

=item C<callback_data> - an app-defined void pointer passed to C<callback>

=back

Returns C<0> on success or C<-1> on error (including unsupported); call
C<SDL_GetError( )> for more information.

=head2 C<SDL_FlashWindow( ... )>

Request a window to demand attention from the user.

Expected parameters include:

=over

=item C<window> - the window to be flashed

=item C<operation> - the flash operation

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_DestroyWindow( ... )>

Destroy a window.

If C<window> is C<undef>, this function will return immediately after setting
the SDL error message to "Invalid window". See C<SDL_GetError( )>.

Expected parameters include:

=over

=item C<window> - the window to destroy

=back

=head2 C<SDL_IsScreenSaverEnabled( )>

Check whether the screensaver is currently enabled.

The screensaver is disabled by default since SDL 2.0.2. Before SDL 2.0.2 the
screensaver was enabled by default.

The default can also be changed using `SDL_HINT_VIDEO_ALLOW_SCREENSAVER`.

Returns C<SDL_TRUE> if the screensaver is enabled, C<SDL_FALSE> if it is
disabled.

=head2 C<SDL_EnableScreenSaver( )>

Allow the screen to be blanked by a screen saver.

	SDL_EnableScreenSaver( );

=head2 C<SDL_DisableScreenSaver( )>

Prevent the screen from being blanked by a screen saver.

	SDL_DisableScreenSaver( );

If you disable the screensaver, it is automatically re-enabled when SDL quits.

=head2 C<SDL_GL_LoadLibrary( ... )>

Dynamically load an OpenGL library.

This should be done after initializing the video driver, but before creating
any OpenGL windows. If no OpenGL library is loaded, the default library will be
loaded upon creation of the first OpenGL window.

If you do this, you need to retrieve all of the GL functions used in your
program from the dynamic library using C<SDL_GL_GetProcAddress( ... )>.

Expected parameters include:

=over

=item C<path> - the platform dependent OpenGL library name, or C<undef> to open the default OpenGL library

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GL_GetProcAddress( ... )>

Get an OpenGL function by name.

If the GL library is loaded at runtime with L<< C<SDL_GL_LoadLibrary( ...
)>|/C<SDL_GL_LoadLibrary( ... )> >>, then all GL functions must be retrieved
this way. Usually this is used to retrieve function pointers to OpenGL
extensions.

There are some quirks to looking up OpenGL functions that require some extra
care from the application. If you code carefully, you can handle these quirks
without any platform-specific code, though:

=over

=item

On Windows, function pointers are specific to the current GL context; this
means you need to have created a GL context and made it current before calling
SDL_GL_GetProcAddress(). If you recreate your context or create a second
context, you should assume that any existing function pointers aren't valid to
use with it. This is (currently) a Windows-specific limitation, and in practice
lots of drivers don't suffer this limitation, but it is still the way the wgl
API is documented to work and you should expect crashes if you don't respect
it. Store a copy of the function pointers that comes and goes with context
lifespan.

=item

On X11, function pointers returned by this function are valid for any context,
and can even be looked up before a context is created at all. This means that,
for at least some common OpenGL implementations, if you look up a function that
doesn't exist, you'll get a non-NULL result that is _NOT_ safe to call. You
must always make sure the function is actually available for a given GL context
before calling it, by checking for the existence of the appropriate extension
with SDL_GL_ExtensionSupported(), or verifying that the version of OpenGL
you're using offers the function as core functionality.

=item

Some OpenGL drivers, on all platforms, *will* return NULL if a function isn't
supported, but you can't count on this behavior. Check for extensions you use,
and if you get a NULL anyway, act as if that extension wasn't available. This
is probably a bug in the driver, but you can code defensively for this scenario
anyhow.

=item

Just because you're on Linux/Unix, don't assume you'll be using X11. Next-gen
display servers are waiting to replace it, and may or may not make the same
promises about function pointers.

=item

OpenGL function pointers must be declared `APIENTRY` as in the example code.
This will ensure the proper calling convention is followed on platforms where
this matters (Win32) thereby avoiding stack corruption.

=back

Expected parameters include:

=over

=item C<proc> - the name of an OpenGL function

=back

Returns a pointer to the named OpenGL function. The returned pointer should be
cast to the appropriate function signature.

=head2 C<SDL_GL_UnloadLibrary( )>

Unload the OpenGL library previously loaded by L<< C<SDL_GL_LoadLibrary( ...
)>|/C<SDL_GL_LoadLibrary( ... )> >>.

=head2 C<SDL_GL_ExtensionSupported( ... )>

Check if an OpenGL extension is supported for the current context.

This function operates on the current GL context; you must have created a
context and it must be current before calling this function. Do not assume that
all contexts you create will have the same set of extensions available, or that
recreating an existing context will offer the same extensions again.

While it's probably not a massive overhead, this function is not an O(1)
operation. Check the extensions you care about after creating the GL context
and save that information somewhere instead of calling the function every time
you need to know.

Expected parameters include:

=over

=item C<extension> - the name of the extension to check

=back

Returns C<SDL_TRUE> if the extension is supported, C<SDL_FALSE> otherwise.

=head2 C<SDL_GL_ResetAttributes( )>

Reset all previously set OpenGL context attributes to their default values.

=head2 <SDL_GL_SetAttribute( ... )>

Set an OpenGL window attribute before window creation.

This function sets the OpenGL attribute C<attr> to C<value>. The requested
attributes should be set before creating an OpenGL window. You should use L<<
C<SDL_GL_GetAttribute( ... )>| C<SDL_GL_GetAttribute( ... )> >> to check the
values after creating the OpenGL context, since the values obtained can differ
from the requested ones.

Expected parameters include;

=over

=item C<attr> - an C<SDL_GLattr> enum value specifying the OpenGL attribute to set

=item C<value> - the desired value for the attribute

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GL_GetAttribute( ... )>

Get the actual value for an attribute from the current context.

Expected parameters include:

=over

=item C<attr> - an SDL_GLattr enum value specifying the OpenGL attribute to get

=item C<value> - a pointer filled in with the current value of C<attr>

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GL_CreateContext( ... )>

Create an OpenGL context for an OpenGL window, and make it current.

Windows users new to OpenGL should note that, for historical reasons, GL
functions added after OpenGL version 1.1 are not available by default. Those
functions must be loaded at run-time, either with an OpenGL extension-handling
library or with L<< C<SDL_GL_GetProcAddress( ... )>|/C<SDL_GL_GetProcAddress(
... )> >> and its related functions.

C<SDL_GLContext> is an alias for C<void *>. It's opaque to the application.

Expected parameters include:

=over

=item C<window> - the window to associate with the context

=back

Returns the OpenGL context associated with C<window> or NULL on error; call
C<SDL_GetError( )> for more details.

=head2 C<SDL_GL_MakeCurrent( ... )>

Set up an OpenGL context for rendering into an OpenGL window.

The context must have been created with a compatible window.

Expected parameters include:

=over

=item C<window> - the window to associate with the context

=item C<context> - the OpenGL context to associate with the window

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GL_GetCurrentWindow( )>

Get the currently active OpenGL window.

Returns the currently active OpenGL window on success or C<undef> on failure;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_GL_GetCurrentContext( )>

Get the currently active OpenGL context.

Returns the currently active OpenGL context or C<undef> on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GL_GetDrawableSize( ... )>

Get the size of a window's underlying drawable in pixels.

This returns info useful for calling C<glViewport( )>.

This may differ from L<< C<SDL_GetWindowSize( ... )>|/C<SDL_GetWindowSize( ...
)> >> if we're rendering to a high-DPI drawable, i.e. the window was created
with C<SDL_WINDOW_ALLOW_HIGHDPI> on a platform with high-DPI support (Apple
calls this "Retina"), and not disabled by the
C<SDL_HINT_VIDEO_HIGHDPI_DISABLED> hint.

Expected parameters include:

=over

=item C<window> - the window from which the drawable size should be queried

=item C<w> - a pointer to variable for storing the width in pixels, may be C<undef>

=item C<h> - a pointer to variable for storing the height in pixels, may be C<undef>

=back

=head2 C<SDL_GL_SetSwapInterval( ... )>

Set the swap interval for the current OpenGL context.

Some systems allow specifying C<-1> for the interval, to enable adaptive vsync.
Adaptive vsync works the same as vsync, but if you've already missed the
vertical retrace for a given frame, it swaps buffers immediately, which might
be less jarring for the user during occasional framerate drops. If an
application requests adaptive vsync and the system does not support it, this
function will fail and return C<-1>. In such a case, you should probably retry
the call with 1 for the interval.

Adaptive vsync is implemented for some glX drivers with
GLX_EXT_swap_control_tear:
L<https://www.opengl.org/registry/specs/EXT/glx_swap_control_tear.txt> and for
some Windows drivers with WGL_EXT_swap_control_tear:
L<https://www.opengl.org/registry/specs/EXT/wgl_swap_control_tear.txt>

Read more on the Khronos wiki:
L<https://www.khronos.org/opengl/wiki/Swap_Interval#Adaptive_Vsync>

Expected parameters include:

=over

=item C<interval> - C<0> for immediate updates, C<1> for updates synchronized with the vertical retrace, C<-1> for adaptive vsync

=back

Returns C<0> on success or C<-1> if setting the swap interval is not supported;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_GL_GetSwapInterval( )>

Get the swap interval for the current OpenGL context.

If the system can't determine the swap interval, or there isn't a valid current
context, this function will return 0 as a safe default.

Returns C<0> if there is no vertical retrace synchronization, C<1> if the
buffer swap is synchronized with the vertical retrace, and C<-1> if late swaps
happen immediately instead of waiting for the next retrace; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GL_SwapWindow( ... )>

Update a window with OpenGL rendering.

This is used with double-buffered OpenGL contexts, which are the default.

On macOS, make sure you bind 0 to the draw framebuffer before swapping the
window, otherwise nothing will happen. If you aren't using C<glBindFramebuffer(
)>, this is the default and you won't have to do anything extra.

Expected parameters include:

=over

=item C<window> - the window to change

=back

=head2 C<SDL_GL_DeleteContext( ... )>

Delete an OpenGL context.

Expected parameters include:

=over

=item C<context> - the OpenGL context to be deleted

=back

=head1 Defined values and enumerations

These may be imported with their given tags.

=head2 Window position flags

=over

=item C<SDL_WINDOWPOS_UNDEFINED>

Used to indicate that you don't care what the window position is.

=item C<SDL_WINDOWPOS_CENTERED>

Used to indicate that the window position should be centered.

=back

=head2 C<SDL_WindowFlags>

The flags on a window. These may be imported with the C<:windowflags> tag.

=over

=item C<SDL_WINDOW_FULLSCREEN> - Fullscreen window

=item C<SDL_WINDOW_OPENGL> - Window usable with OpenGL context

=item C<SDL_WINDOW_SHOWN> - Window is visible

=item C<SDL_WINDOW_HIDDEN> - Window is not visible

=item C<SDL_WINDOW_BORDERLESS> - No window decoration

=item C<SDL_WINDOW_RESIZABLE> - Window can be resized

=item C<SDL_WINDOW_MINIMIZED> - Window is minimized

=item C<SDL_WINDOW_MAXIMIZED> - Window is maximized

=item C<SDL_WINDOW_MOUSE_GRABBED> - Window has grabbed mouse input

=item C<SDL_WINDOW_INPUT_FOCUS> - Window has input focus

=item C<SDL_WINDOW_MOUSE_FOCUS> - Window has mouse focus

=item C<SDL_WINDOW_FULLSCREEN_DESKTOP> - Fullscreen window without frame

=item C<SDL_WINDOW_FOREIGN> - Window not created by SDL

=item C<SDL_WINDOW_ALLOW_HIGHDPI> - Window should be created in high-DPI mode if supported.

On macOS NSHighResolutionCapable must be set true in the application's
Info.plist for this to have any effect.

=item C<SDL_WINDOW_MOUSE_CAPTURE> - Window has mouse captured (unrelated to C<MOUSE_GRABBED>)

=item C<SDL_WINDOW_ALWAYS_ON_TOP> - Window should always be above others

=item C<SDL_WINDOW_SKIP_TASKBAR> - Window should not be added to the taskbar

=item C<SDL_WINDOW_UTILITY> - Window should be treated as a utility window

=item C<SDL_WINDOW_TOOLTIP> - Window should be treated as a tooltip

=item C<SDL_WINDOW_POPUP_MENU> - Window should be treated as a popup menu

=item C<SDL_WINDOW_KEYBOARD_GRABBED> - Window has grabbed keyboard input

=item C<SDL_WINDOW_VULKAN> - Window usable for Vulkan surface

=item C<SDL_WINDOW_METAL> - Window usable for Metal view

=item C<SDL_WINDOW_INPUT_GRABBED> - Equivalent to C<SDL_WINDOW_MOUSE_GRABBED> for compatibility

=back

=head2 C<SDL_WindowEventID>

Event subtype for window events. These may be imported with the
C<:windowEventID> tag.

=over

=item C<SDL_WINDOWEVENT_NONE> - Never used

=item C<SDL_WINDOWEVENT_SHOWN> - Window has been shown

=item C<SDL_WINDOWEVENT_HIDDEN> - Window has been hidden

=item C<SDL_WINDOWEVENT_EXPOSED> - Window has been exposed and should be redrawn

=item C<SDL_WINDOWEVENT_MOVED> - Window has been moved to C<data1, data2>

=item C<SDL_WINDOWEVENT_RESIZED> - Window has been resized to C<data1 x data2>

=item C<SDL_WINDOWEVENT_SIZE_CHANGED> - The window size has changed, either as a result of an API call or through the system or user changing the window size.

=item C<SDL_WINDOWEVENT_MINIMIZED> - Window has been minimized

=item C<SDL_WINDOWEVENT_MAXIMIZED> - Window has been maximized

=item C<SDL_WINDOWEVENT_RESTORED> - Window has been restored to normal size and position

=item C<SDL_WINDOWEVENT_ENTER> - Window has gained mouse focus

=item C<SDL_WINDOWEVENT_LEAVE> - Window has lost mouse focus

=item C<SDL_WINDOWEVENT_FOCUS_GAINED> - Window has gained keyboard focus

=item C<SDL_WINDOWEVENT_FOCUS_LOST> - Window has lost keyboard focus

=item C<SDL_WINDOWEVENT_CLOSE> - The window manager requests that the window be closed

=item C<SDL_WINDOWEVENT_TAKE_FOCUS> - Window is being offered a focus (should C<SetWindowInputFocus( )> on itself or a subwindow, or ignore)

=item C<SDL_WINDOWEVENT_HIT_TEST> - Window had a hit test that wasn't C<SDL_HITTEST_NORMAL>.

=back

=head2 C<SDL_DisplayEventID>

Event subtype for display events. These may be imported with the
C<:displayEventID> tag.

=over

=item C<SDL_DISPLAYEVENT_NONE> - Never used

=item C<SDL_DISPLAYEVENT_ORIENTATION> - Display orientation has changed to data1

=item C<SDL_DISPLAYEVENT_CONNECTED> - Display has been added to the system

=item C<SDL_DISPLAYEVENT_DISCONNECTED> - Display has been removed from the system

=back

=head2 C<SDL_DisplayOrientation>

These may be imported with the C<:displayOrientation> tag.

=over

=item C<SDL_ORIENTATION_UNKNOWN> - The display orientation can't be determined

=item C<SDL_ORIENTATION_LANDSCAPE> - The display is in landscape mode, with the right side up, relative to portrait mode

=item C<SDL_ORIENTATION_LANDSCAPE_FLIPPED> - The display is in landscape mode, with the left side up, relative to portrait mode

=item C<SDL_ORIENTATION_PORTRAIT> - The display is in portrait mode

=item C<SDL_ORIENTATION_PORTRAIT_FLIPPED> - The display is in portrait mode, upside down

=back

=head2 C<SDL_FlashOperation>

Window flash operation. These may be imported with the C<:flashOperation> tag.

=over

=item C<SDL_FLASH_CANCEL> - Cancel any window flash state

=item C<SDL_FLASH_BRIEFLY> - Flash the window briefly to get attention

=item C<SDL_FLASH_UNTIL_FOCUSED> - Flash the window until it gets focus

=back

=head2 C<SDL_GLattr>

OpenGL configuration attributes. These may be imported with the C<:glAttr> tag.

=over

=item C<SDL_GL_RED_SIZE>

=item C<SDL_GL_GREEN_SIZE>

=item C<SDL_GL_BLUE_SIZE>

=item C<SDL_GL_ALPHA_SIZE>

=item C<SDL_GL_BUFFER_SIZE>

=item C<SDL_GL_DOUBLEBUFFER>

=item C<SDL_GL_DEPTH_SIZE>

=item C<SDL_GL_STENCIL_SIZE>

=item C<SDL_GL_ACCUM_RED_SIZE>

=item C<SDL_GL_ACCUM_GREEN_SIZE>

=item C<SDL_GL_ACCUM_BLUE_SIZE>

=item C<SDL_GL_ACCUM_ALPHA_SIZE>

=item C<SDL_GL_STEREO>

=item C<SDL_GL_MULTISAMPLEBUFFERS>

=item C<SDL_GL_MULTISAMPLESAMPLES>

=item C<SDL_GL_ACCELERATED_VISUAL>

=item C<SDL_GL_RETAINED_BACKING>

=item C<SDL_GL_CONTEXT_MAJOR_VERSION>

=item C<SDL_GL_CONTEXT_MINOR_VERSION>

=item C<SDL_GL_CONTEXT_EGL>

=item C<SDL_GL_CONTEXT_FLAGS>

=item C<SDL_GL_CONTEXT_PROFILE_MASK>

=item C<SDL_GL_SHARE_WITH_CURRENT_CONTEXT>

=item C<SDL_GL_FRAMEBUFFER_SRGB_CAPABLE>

=item C<SDL_GL_CONTEXT_RELEASE_BEHAVIOR>

=item C<SDL_GL_CONTEXT_RESET_NOTIFICATION>

=item C<SDL_GL_CONTEXT_NO_ERROR>

=back

=head2 C<SDL_GLprofile>

These may be imported with the C<:glProfile> tag.

=over

=item C<SDL_GL_CONTEXT_PROFILE_CORE>

=item C<SDL_GL_CONTEXT_PROFILE_COMPATIBILITY>

=item C<SDL_GL_CONTEXT_PROFILE_ES>

=back

=head2 C<SDL_GLcontextFlag>

These may be imported with the C<:glContextFlag> tag.

=over

=item C<SDL_GL_CONTEXT_DEBUG_FLAG>

=item C<SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG>

=item C<SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG>

=item C<SDL_GL_CONTEXT_RESET_ISOLATION_FLAG>

=back

=head2 C<SDL_GLcontextReleaseFlag>

These may be imported with the C<:glContextReleaseFlag> tag.

=over

=item C<SDL_GL_CONTEXT_RELEASE_BEHAVIOR_NONE>

=item C<SDL_GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH>

=back

=head2 C<SDL_GLContextResetNotification>

These may be imported with the C<:glContextResetNotification> tag.

=over

=item C<SDL_GL_CONTEXT_RESET_NO_NOTIFICATION>

=item C<SDL_GL_CONTEXT_RESET_LOSE_CONTEXT>

=back

=head2 C<SDL_HitTest>

Callback used for hit-testing.

Parameters to expect include:

=over

=item C<win> - the L<SDL2::Window> where hit-testing was set on

=item C<area> - an L<SDL2::Point> which should be hit-tested

=item C<data> - what was passed as C<callback_data> to L<< C<SDL_SetWindowHitTest( ... )>|/C<SDL_SetWindowHitTest( ... )> >>

=back

Your callback should return an C<SDL_HitTestResult> value.

=head2 C<SDL_HitTestResult>

Possible return values from the L<SDL_HitTest> callback.

=over

=item C<SDL_HITTEST_NORMAL> - Region is normal. No special properties

=item C<SDL_HITTEST_DRAGGABLE> - Region can drag entire window

=item C<SDL_HITTEST_RESIZE_TOPLEFT>

=item C<SDL_HITTEST_RESIZE_TOP>

=item C<SDL_HITTEST_RESIZE_TOPRIGHT>

=item C<SDL_HITTEST_RESIZE_RIGHT>

=item C<SDL_HITTEST_RESIZE_BOTTOMRIGHT>

=item C<SDL_HITTEST_RESIZE_BOTTOM>

=item C<SDL_HITTEST_RESIZE_BOTTOMLEFT>

=item C<SDL_HITTEST_RESIZE_LEFT>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

fullscreen non-fullscreen high-dpi borderless resizable draggable taskbar
tooltip popup subwindow macOS iOS NSHighResolutionCapable videomode screensaver
wgl lifespan vsync glX framebuffer framerate

=end stopwords

=cut

};
1;
