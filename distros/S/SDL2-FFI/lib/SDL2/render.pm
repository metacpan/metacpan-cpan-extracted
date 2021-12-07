package SDL2::render 0.01 {
    use strict;
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    use SDL2::rect;
    use SDL2::video;
    #
    enum SDL_RendererFlags => [
        [ SDL_RENDERER_SOFTWARE      => 0x00000001 ],
        [ SDL_RENDERER_ACCELERATED   => 0x00000002 ],
        [ SDL_RENDERER_PRESENTVSYNC  => 0x00000004 ],
        [ SDL_RENDERER_TARGETTEXTURE => 0x00000008 ]
    ];

    package SDL2::RendererInfo {
        use SDL2::Utils;
        our $TYPE = has
            name                => 'opaque',       # string
            flags               => 'uint32',
            num_texture_formats => 'uint32',
            texture_formats     => 'uint32[16]',
            max_texture_width   => 'int',
            max_texture_height  => 'int';
    };
    enum SDL_ScaleMode => [
        qw[SDL_ScaleModeNearest
            SDL_ScaleModeLinear
            SDL_ScaleModeBest]
        ],
        SDL_TextureAccess => [
        qw[   SDL_TEXTUREACCESS_STATIC
            SDL_TEXTUREACCESS_STREAMING
            SDL_TEXTUREACCESS_TARGET
        ]
        ],
        SDL_TextureModulate => [
        [ SDL_TEXTUREMODULATE_NONE  => 0x00000000 ],
        [ SDL_TEXTUREMODULATE_COLOR => 0x00000001 ],
        [ SDL_TEXTUREMODULATE_ALPHA => 0x00000002 ]
        ],
        SDL_RendererFlip => [
        [ SDL_FLIP_NONE       => 0x00000000 ],
        [ SDL_FLIP_HORIZONTAL => 0x00000001 ],
        [ SDL_FLIP_VERTICAL   => 0x00000002 ]
        ];

    package SDL2::Renderer {
        use SDL2::Utils;
        our $TYPE = has();
    };

    package SDL2::Texture {
        use SDL2::Utils;
        our $TYPE = has();
    };
    attach render => {
        SDL_GetNumRenderDrivers     => [ [],                            'int' ],
        SDL_GetRenderDriverInfo     => [ [ 'int', 'SDL_RendererInfo' ], 'int' ],
        SDL_CreateWindowAndRenderer => [
            [ 'int', 'int', 'uint32', 'opaque*', 'opaque*' ],
            'int' => sub ( $inner, $width, $height, $window_flags, $window = (), $renderer = () ) {

                #$window   //= SDL2::Window->new;
                #$renderer //= SDL2::Renderer->new;
                my $ok = $inner->( $width, $height, $window_flags, \$window, \$renderer );
                $_[4] = ffi->cast( 'opaque' => 'SDL_Window',   $window );
                $_[5] = ffi->cast( 'opaque' => 'SDL_Renderer', $renderer );

                #$ok == 0 ? (
                #    ffi->cast( 'opaque' => 'SDL_Window',   $window ),
                #    ffi->cast( 'opaque' => 'SDL_Renderer', $renderer ),
                #    ) :
                $ok;
            }
        ],
        ,
        SDL_CreateRenderer         => [ [ 'SDL_Window', 'int', 'uint32' ],      'SDL_Renderer' ],
        SDL_CreateSoftwareRenderer => [ ['SDL_Surface'],                        'SDL_Renderer' ],
        SDL_GetRenderer            => [ ['SDL_Window'],                         'SDL_Renderer' ],
        SDL_GetRendererInfo        => [ [ 'SDL_Renderer', 'SDL_RendererInfo' ], 'int' ],
        SDL_GetRendererOutputSize  => [ [ 'SDL_Renderer', 'int*', 'int*' ],     'int' ],
        SDL_CreateTexture => [ [ 'SDL_Renderer', 'uint32', 'int', 'int', 'int' ], 'SDL_Texture' ],
        SDL_CreateTextureFromSurface => [ [ 'SDL_Renderer', 'SDL_Surface' ], 'SDL_Texture' ],
        SDL_QueryTexture        => [ [ 'SDL_Texture', 'uint32*', 'int*', 'int*', 'int*' ], 'int' ],
        SDL_SetTextureColorMod  => [ [ 'SDL_Texture', 'uint8', 'uint8', 'uint8' ],         'int' ],
        SDL_GetTextureColorMod  => [ [ 'SDL_Texture', 'uint8*', 'uint8*', 'uint8*' ],      'int' ],
        SDL_SetTextureAlphaMod  => [ [ 'SDL_Texture', 'uint8' ],                           'int' ],
        SDL_GetTextureAlphaMod  => [ [ 'SDL_Texture', 'uint8*' ],                          'int' ],
        SDL_SetTextureBlendMode => [ [ 'SDL_Texture', 'SDL_BlendMode' ],                   'int' ],
        SDL_GetTextureBlendMode => [ [ 'SDL_Texture', 'int*' ],                            'int' ],
        SDL_UpdateTexture       => [ [ 'SDL_Texture', 'SDL_Rect', 'opaque*', 'int' ],      'int' ],
        SDL_UpdateYUVTexture    => [
            [ 'SDL_Texture', 'SDL_Rect', 'uint8*', 'int', 'uint8*', 'int', 'uint8*', 'int' ], 'int'
        ],
        SDL_UpdateNVTexture =>
            [ [ 'SDL_Texture', 'SDL_Rect', 'uint8*', 'int', 'uint8*', 'int' ], 'int' ],
        SDL_LockTexture           => [ [ 'SDL_Texture', 'SDL_Rect', 'opaque*' ], 'int' ],
        SDL_LockTextureToSurface  => [ [ 'SDL_Texture', 'SDL_Rect', 'SDL_Surface' ], 'int' ],
        SDL_UnlockTexture         => [ ['SDL_Texture'] ],
        SDL_RenderTargetSupported => [ ['SDL_Renderer'],                   'bool' ],
        SDL_SetRenderTarget       => [ [ 'SDL_Renderer', 'SDL_Texture' ],  'int' ],
        SDL_GetRenderTarget       => [ ['SDL_Renderer'],                   'SDL_Texture' ],
        SDL_RenderSetLogicalSize  => [ [ 'SDL_Renderer', 'int', 'int' ],   'int' ],
        SDL_RenderGetLogicalSize  => [ [ 'SDL_Renderer', 'int*', 'int*' ], 'int' ],
        SDL_RenderSetIntegerScale => [ [ 'SDL_Renderer', 'bool' ],         'int' ],
        SDL_RenderGetIntegerScale => [ ['SDL_Renderer'],                   'bool' ],
        SDL_RenderSetViewport     => [ [ 'SDL_Renderer', 'SDL_Rect' ],     'int' ],
        SDL_RenderGetViewport     => [ [ 'SDL_Renderer', 'SDL_Rect' ],     'int' ],
        SDL_RenderSetClipRect     => [ [ 'SDL_Renderer', 'SDL_Rect' ],     'int' ],
        SDL_RenderGetClipRect     => [ [ 'SDL_Renderer', 'SDL_Rect' ] ],
        SDL_RenderIsClipEnabled   => [ ['SDL_Renderer'], 'bool' ],
        SDL_RenderSetScale        => [ [ 'SDL_Renderer', 'float', 'float' ], 'int' ],
        SDL_RenderGetScale     => [ [ 'SDL_Renderer', 'float*', 'float*' ], ],
        SDL_SetRenderDrawColor => [ [ 'SDL_Renderer', 'uint8', 'uint8', 'uint8', 'uint8' ], 'int' ],
        SDL_GetRenderDrawColor =>
            [ [ 'SDL_Renderer', 'uint8*', 'uint8*', 'uint8*', 'uint8*' ], 'int' ],
        SDL_SetRenderDrawBlendMode => [ [ 'SDL_Renderer', 'SDL_BlendMode' ], 'int' ],
        SDL_GetRenderDrawBlendMode => [ [ 'SDL_Renderer', 'int*' ],          'int' ],
        SDL_RenderClear            => [ ['SDL_Renderer'],                    'int' ],
        SDL_RenderDrawPoint        => [ [ 'SDL_Renderer', 'int', 'int' ],    'int' ],
        SDL_RenderDrawPoints       => [
            [ 'SDL_Renderer', 'PointList_t', 'int' ],
            'int' => sub ( $inner, $renderer, @points ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    $SDL2::Point::LIST->create(
                        [ map { ref $_ eq 'HASH' ? $_ : { x => $_->x, y => $_->y } } @points ]
                    ),
                    scalar @points
                );
            }
        ],
        SDL_RenderDrawLine  => [ [ 'SDL_Renderer', 'int', 'int', 'int', 'int' ], 'int' ],
        SDL_RenderDrawLines => [
            [ 'SDL_Renderer', 'PointList_t', 'int' ],
            'int' => sub ( $inner, $renderer, @points ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    $SDL2::Point::LIST->create(
                        [ map { ref $_ eq 'HASH' ? $_ : { x => $_->x, y => $_->y } } @points ]
                    ),
                    scalar @points
                );
            }
        ],
        SDL_RenderDrawRect  => [ [ 'SDL_Renderer', 'SDL_Rect' ], 'int' ],
        SDL_RenderDrawRects => [
            [ 'SDL_Renderer', 'RectList_t', 'int' ],
            'int' => sub ( $inner, $renderer, @rects ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    $SDL2::Rect::LIST->create(
                        [   map {
                                ref $_ eq 'HASH' ? $_ :
                                    { x => $_->x, y => $_->y, w => $_->w, h => $_->h }
                            } @rects
                        ]
                    ),
                    scalar @rects
                );
            }
        ],
        SDL_RenderFillRect  => [ [ 'SDL_Renderer', 'SDL_Rect' ], 'int' ],
        SDL_RenderFillRects => [
            [ 'SDL_Renderer', 'RectList_t', 'int' ],
            'int' => sub ( $inner, $renderer, @rects ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    $SDL2::Rect::LIST->create(
                        [   map {
                                ref $_ eq 'HASH' ? $_ :
                                    { x => $_->x, y => $_->y, w => $_->w, h => $_->h }
                            } @rects
                        ]
                    ),
                    scalar @rects
                );
            }
        ],
        SDL_RenderCopy => [ [ 'SDL_Renderer', 'SDL_Texture', 'SDL_Rect', 'SDL_Rect' ], 'int' ],

        # XXX - I do not have an example for this function in docs
        SDL_RenderCopyEx => [
            [   'SDL_Renderer', 'SDL_Texture', 'SDL_Rect', 'SDL_Rect',
                'double',       'SDL_Point',   'SDL_RendererFlip'
            ],
            'int'
        ],
        SDL_RenderDrawPointF  => [ [ 'SDL_Renderer', 'float', 'float' ], 'int' ],
        SDL_RenderDrawPointsF => [
            [ 'SDL_Renderer', 'FPointList_t', 'int' ],
            'int' => sub ( $inner, $renderer, @points ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    $SDL2::Point::LIST->create(
                        [ map { ref $_ eq 'HASH' ? $_ : { x => $_->x, y => $_->y } } @points ]
                    ),
                    scalar @points
                );
            }
        ],
        SDL_RenderDrawLineF  => [ [ 'SDL_Renderer', 'float', 'float', 'float', 'float' ], 'int' ],
        SDL_RenderDrawLinesF => [
            [ 'SDL_Renderer', 'FPointList_t', 'int' ],
            'int' => sub ( $inner, $renderer, @points ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    $SDL2::FPoint::LIST->create(
                        [ map { ref $_ eq 'HASH' ? $_ : { x => $_->x, y => $_->y } } @points ]
                    ),
                    scalar @points
                );
            }
        ],
        SDL_RenderDrawRectF => [
            [ 'SDL_Renderer', 'FRectList_t', 'int' ],
            'int' => sub ( $inner, $renderer, @rects ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    $SDL2::FRect::LIST->create(
                        [   map {
                                ref $_ eq 'HASH' ? $_ :
                                    { x => $_->x, y => $_->y, w => $_->w, h => $_->h }
                            } @rects
                        ]
                    ),
                    scalar @rects
                );
            }
        ],
        SDL_RenderDrawRectsF => [
            [ 'SDL_Renderer', 'FRectList_t', 'int' ],
            'int' => sub ( $inner, $renderer, @rects ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    $SDL2::FRect::LIST->create(
                        [   map {
                                ref $_ eq 'HASH' ? $_ :
                                    { x => $_->x, y => $_->y, w => $_->w, h => $_->h }
                            } @rects
                        ]
                    ),
                    scalar @rects
                );
            }
        ],
        SDL_RenderFillRectsF => [
            [ 'SDL_Renderer', 'FRectList_t', 'int' ],
            'int' => sub ( $inner, $renderer, @rects ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    $SDL2::FRect::LIST->create(
                        [   map {
                                ref $_ eq 'HASH' ? $_ :
                                    { x => $_->x, y => $_->y, w => $_->w, h => $_->h }
                            } @rects
                        ]
                    ),
                    scalar @rects
                );
            }
        ],

        # XXX - I do not have an example for this function in docs
        SDL_RenderCopyF => [ [ 'SDL_Renderer', 'SDL_Texture', 'SDL_Rect', 'SDL_FRect' ], 'int' ],

        # XXX - I do not have an example for this function in docs
        SDL_RenderCopyExF => [
            [   'SDL_Renderer', 'SDL_Texture', 'SDL_Rect', 'SDL_FRect',
                'double',       'SDL_FPoint',  'SDL_RendererFlip'
            ],
            'int'
        ],
        SDL_RenderReadPixels =>
            [ [ 'SDL_Renderer', 'SDL_Rect', 'uint32', 'opaque', 'int' ], 'int' ],
        SDL_RenderPresent                => [ ['SDL_Renderer'] ],
        SDL_DestroyTexture               => [ ['SDL_Texture'] ],
        SDL_DestroyRenderer              => [ ['SDL_Renderer'] ],
        SDL_RenderFlush                  => [ ['SDL_Renderer'],                      'int' ],
        SDL_GL_BindTexture               => [ [ 'SDL_Texture', 'float*', 'float*' ], 'int' ],
        SDL_GL_UnbindTexture             => [ ['SDL_Texture'],                       'int' ],
        SDL_RenderGetMetalLayer          => [ ['SDL_Renderer'],                      'opaque' ],
        SDL_RenderGetMetalCommandEncoder => [ ['SDL_Renderer'],                      'opaque' ]
    };

=encoding utf-8

=head1 NAME

SDL2::render - SDL 2D Rendering Functions

=head1 SYNOPSIS

    use SDL2 qw[:render];

=head1 DESCRIPTION

Header file for SDL 2D rendering functions.

This API supports the following features:

=over

=item * single pixel points

=item * single pixel lines

=item * filled rectangles

=item * texture images

=back

The primitives may be drawn in opaque, blended, or additive modes.

The texture images may be drawn in opaque, blended, or additive modes. They can
have an additional color tint or alpha modulation applied to them, and may also
be stretched with linear interpolation.

This API is designed to accelerate simple 2D operations. You may want more
functionality such as polygons and particle effects and in that case you should
use SDL's OpenGL/Direct3D support or one of the many good 3D engines.

These functions must be called from the main thread. See this bug for details:
L<http://bugzilla.libsdl.org/show_bug.cgi?id=1995>

=head1 Functions

These functions may be imported by name or with the C<:render> tag.


=head2 C<SDL_GetNumRenderDrivers( )>

Get the number of 2D rendering drivers available for the current display.

	my $drivers = SDL_GetNumRenderDrivers( );

A render driver is a set of code that handles rendering and texture management
on a particular display. Normally there is only one, but some drivers may have
several available with different capabilities.

There may be none if SDL was compiled without render support.

Returns a number >= 0 on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetRenderDriverInfo( ... )>

Get info about a specific 2D rendering driver for the current display.

	my $info = !SDL_GetRendererDriverInfo( );

Expected parameters include:

=over

=item C<index> - the index of the driver to query information about

=back

Returns an L<SDL2::RendererInfo> structure on success or a negative error code
on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_CreateWindowAndRenderer( ... )>

Create a window and default renderer.

	my ($window, $renderer) = SDL_CreateWindowAndRenderer(640, 480, 0);

Expected parameters include:

=over

=item C<width> - the width of the window

=item C<height> - the height of the window

=item C<window_flags> - the flags used to create the window (see C<SDL_CreateWindow( ... )>)

=back

Returns a L<SDL2::Window> and L<SDL2::Renderer> objects on success, or C<-1> on
error; call C<SDL_GetError( )> for more information.

=head2 C<SDL_CreateRenderer( ... )>

Create a 2D rendering context for a window.

	my $renderer = SDL_CreateRenderer( $window, -1, 0);

Expected parameters include:

=over

=item C<window> - the window where rendering is displayed

=item C<index> - the index of the rendering driver to initialize, or C<-1> to initialize the first one supporting the requested flags

=item C<flags> - C<0>, or one or more C<SDL_RendererFlags> OR'd together

=back

Returns a valid rendering context or undefined if there was an error; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_CreateSoftwareRenderer( ... )>

Create a 2D software rendering context for a surface.

	my $renderer = SDL_CreateSoftwareRenderer( $surface );

Two other API which can be used to create SDL_Renderer:

L<< C<SDL_CreateRenderer( ... )>|/C<SDL_CreateRenderer( ... )> >> and L<<
C<SDL_CreateWindowAndRenderer( ... )>|/C<SDL_CreateWindowAndRenderer( ... )>
>>. These can B<also> create a software renderer, but they are intended to be
used with an L<SDL2::Window> as the final destination and not an
L<SDL2::Surface>.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure representing the surface where rendering is done

=back

Returns a valid rendering context or undef if there was an error; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetRenderer( ... )>

Get the renderer associated with a window.

	my $renderer = SDL_GetRenderer( $window );

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns the rendering context on success or undef on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetRendererInfo( ... )>

Get information about a rendering context.

	my $info = !SDL_GetRendererInfo( $renderer );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns an L<SDL2::RendererInfo> structure on success or a negative error code
on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_GetRendererOutputSize( ... )>

Get the output size in pixels of a rendering context.

	my ($w, $h) = SDL_GetRendererOutputSize( $renderer );

Due to high-dpi displays, you might end up with a rendering context that has
more pixels than the window that contains it, so use this instead of
C<SDL_GetWindowSize( ... )> to decide how much drawing area you have.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns the width and height on success or a negative error code on failure;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_CreateTexture( ... )>

Create a texture for a rendering context.

    my $texture = SDL_CreateTexture( $renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, 1024, 768);

=for TODO: https://gist.github.com/malja/2193bd656fe50c203f264ce554919976

You can set the texture scaling method by setting
C<SDL_HINT_RENDER_SCALE_QUALITY> before creating the texture.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<format> - one of the enumerated values in C<:pixelFormatEnum>

=item C<access> - one of the enumerated values in C<:textureAccess>

=item C<w> - the width of the texture in pixels

=item C<h> - the height of the texture in pixels

=back

Returns a pointer to the created texture or undefined if no rendering context
was active, the format was unsupported, or the width or height were out of
range; call C<SDL_GetError( )> for more information.

=head2 C<SDL_CreateTextureFromSurface( ... )>

Create a texture from an existing surface.

	use Config;
	my ($rmask, $gmask, $bmask, $amask) =
	$Config{byteorder} == 4321 ? (0xff000000,0x00ff0000,0x0000ff00,0x000000ff) :
    							 (0x000000ff,0x0000ff00,0x00ff0000,0xff000000);
	my $surface = SDL_CreateRGBSurface( 0, 640, 480, 32, $rmask, $gmask, $bmask, $amask );
	my $texture = SDL_CreateTextureFromSurface( $renderer, $surface );

The surface is not modified or freed by this function.

The SDL_TextureAccess hint for the created texture is
C<SDL_TEXTUREACCESS_STATIC>.

The pixel format of the created texture may be different from the pixel format
of the surface. Use L<< C<SDL_QueryTexture( ... )>|/C<SDL_QueryTexture( ... )>
>> to query the pixel format of the texture.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<surface> - the L<SDL2::Surface> structure containing pixel data used to fill the texture

=back

Returns the created texture or undef on failure; call C<SDL_GetError( )> for
more information.

=head2 C<SDL_QueryTexture( ... )>

Query the attributes of a texture.

	my ( $format, $access, $w, $h ) = SDL_QueryTexture( $texture );

Expected parameters include:

=over

=item C<texture> - the texture to query

=back

Returns the following on success...

=over

=item C<format> - a pointer filled in with the raw format of the texture; the actual format may differ, but pixel transfers will use this format (one of the C<SDL_PixelFormatEnum> values)

=item C<access> - a pointer filled in with the actual access to the texture (one of the L<< C<SDL_TextureAccess>|/C<SDL_TextureAccess> >> values)

=item C<w> - a pointer filled in with the width of the texture in pixels

=item C<h> - a pointer filled in with the height of the texture in pixels

=back

...or a negative error code on failure; call C<SDL_GetError( )> for more
information.

=head2 C<SDL_SetTextureColorMod( ... )>

Set an additional color value multiplied into render copy operations.

	my $ok = !SDL_SetTextureColorMod( $texture, 64, 64, 64 );

When this texture is rendered, during the copy operation each source color
channel is modulated by the appropriate color value according to the following
formula:

	srcC = srcC * (color / 255)

Color modulation is not always supported by the renderer; it will return C<-1>
if color modulation is not supported.

Expected parameters include:

=over

=item C<texture> - the texture to update

=item C<r> - the red color value multiplied into copy operations

=item C<g> - the green color value multiplied into copy operations

=item C<b> - the blue color value multiplied into copy operations

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetTextureColorMod( ... )>

Get the additional color value multiplied into render copy operations.

	my ( $r, $g, $b ) = SDL_GetTextureColorMod( $texture );

Expected parameters include:

=over

=item C<texture> - the texture to query

=back

Returns the current red, green, and blue color values on success or a negative
error code on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_SetTextureAlphaMod( ... )>

Set an additional alpha value multiplied into render copy operations.

	SDL_SetTextureAlphaMod( $texture, 100 );

When this texture is rendered, during the copy operation the source alpha

value is modulated by this alpha value according to the following formula:

	srcA = srcA * (alpha / 255)

Alpha modulation is not always supported by the renderer; it will return C<-1>
if alpha modulation is not supported.

Expected parameters include:

=over

=item C<texture> - the texture to update

=item C<alpha> - the source alpha value multiplied into copy operations

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetTextureAlphaMod( ... )>

Get the additional alpha value multiplied into render copy operations.

	my $alpha = SDL_GetTextureAlphaMod( $texture );

Expected parameters include:

=over

=item C<texture> - the texture to query

=back

Returns the current alpha value on success or a negative error code on failure;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_SetTextureBlendMode( ... )>

Set the blend mode for a texture, used by L<< C<SDL_RenderCopy( ...
)>|/C<SDL_RenderCopy( ... )> >>.

If the blend mode is not supported, the closest supported mode is chosen and
this function returns C<-1>.

Expected parameters include:

=over

=item C<texture> - the texture to update

=item C<blendMode> - the C<SDL_BlendMode> to use for texture blending

=back

Returns 0 on success or a negative error code on failure; call C<SDL_GetError(
)> for more information.

=head2 C<SDL_GetTextureBlendMode( ... )>

Get the blend mode used for texture copy operations.

	SDL_GetTextureBlendMode( $texture, SDL_BLENDMODE_ADD );

Expected parameters include:

=over

=item C<texture> - the texture to query

=back

Returns the current C<:blendMode> on success or a negative error code on
failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_SetTextureScaleMode( ... )>

Set the scale mode used for texture scale operations.

	SDL_SetTextureScaleMode( $texture, $scaleMode );

If the scale mode is not supported, the closest supported mode is chosen.

Expected parameters include:

=over

=item C<texture> - The texture to update.

=item C<scaleMode> - the SDL_ScaleMode to use for texture scaling.

=back

Returns C<0> on success, or C<-1> if the texture is not valid.

=head2 C<SDL_GetTextureScaleMode( ... )>

Get the scale mode used for texture scale operations.

	my $ok = SDL_GetTextureScaleMode( $texture );

Expected parameters include:

=over

=item C<texture> - the texture to query.

=back

Returns the current scale mode on success, or C<-1> if the texture is not
valid.

=head2 C<SDL_UpdateTexture( ... )>

Update the given texture rectangle with new pixel data.

	my $rect = SDL2::Rect->new( { x => 0, y => ..., w => $surface->w, h => $surface->h } );
	SDL_UpdateTexture( $texture, $rect, $surface->pixels, $surface->pitch );

The pixel data must be in the pixel format of the texture. Use L<<
C<SDL_QueryTexture( ... )>|/C<SDL_QueryTexture( ... )> >> to query the pixel
format of the texture.

This is a fairly slow function, intended for use with static textures that do
not change often.

If the texture is intended to be updated often, it is preferred to create the
texture as streaming and use the locking functions referenced below. While this
function will work with streaming textures, for optimization reasons you may
not get the pixels back if you lock the texture afterward.

Expected parameters include:

=over

=item C<texture> - the texture to update

=item C<rect> - an L<SDL2::Rect> structure representing the area to update, or undef to update the entire texture

=item C<pixels> - the raw pixel data in the format of the texture

=item C<pitch> - the number of bytes in a row of pixel data, including padding between lines

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_UpdateYUVTexture( ... )>

Update a rectangle within a planar YV12 or IYUV texture with new pixel data.

	SDL_UpdateYUVTexture( $texture, $rect, $yPlane, $yPitch, $uPlane, $uPitch, $vPlane, $vPitch );

You can use L<< C<SDL_UpdateTexture( ... )>|/C<SDL_UpdateTexture( ... )> >> as
long as your pixel data is a contiguous block of Y and U/V planes in the proper
order, but this function is available if your pixel data is not contiguous.

Expected parameters include:

=over

=item C<texture> - the texture to update

=item C<rect> - a pointer to the rectangle of pixels to update, or undef to update the entire texture

=item C<Yplane> - the raw pixel data for the Y plane

=item C<Ypitch> - the number of bytes between rows of pixel data for the Y plane

=item C<Uplane> - the raw pixel data for the U plane

=item C<Upitch> - the number of bytes between rows of pixel data for the U plane

=item C<Vplane> - the raw pixel data for the V plane

=item C<Vpitch> - the number of bytes between rows of pixel data for the V plane

=back

Returns C<0> on success or -1 if the texture is not valid; call C<SDL_GetError(
)> for more information.

=head2 C<SDL_UpdateNVTexture( ... )>

Update a rectangle within a planar NV12 or NV21 texture with new pixels.

	SDL_UpdateNVTexture( $texture, $rect, $yPlane, $yPitch, $uPlane, $uPitch );

You can use L<< C<SDL_UpdateTexture( ... )>|/C<SDL_UpdateTexture( ... )> >> as
long as your pixel data is a contiguous block of NV12/21 planes in the proper
order, but this function is available if your pixel data is not contiguous.

Expected parameters include:

=over

=item C<texture> - the texture to update

=item C<rect> - a pointer to the rectangle of pixels to update, or undef to update the entire texture.

=item C<Yplane> - the raw pixel data for the Y plane.

=item C<Ypitch> - the number of bytes between rows of pixel data for the Y plane.

=item C<UVplane> - the raw pixel data for the UV plane.

=item C<UVpitch> - the number of bytes between rows of pixel data for the UV plane.

=back

Returns C<0> on success, or C<-1> if the texture is not valid.

=head2 C<SDL_LockTexture( ... )>

Lock a portion of the texture for B<write-only> pixel access.

	SDL_LockTexture( $texture, $rect, $pixels, $pitch );

As an optimization, the pixels made available for editing don't necessarily
contain the old texture data. This is a write-only operation, and if you need
to keep a copy of the texture data you should do that at the application level.

You must use L<< C<SDL_UpdateTexture( ... )>|/C<SDL_UpdateTexture( ... )> >> to
unlock the pixels and apply any changes.

Expected parameters include:

=over

=item C<texture> - the texture to lock for access, which was created with C<SDL_TEXTUREACCESS_STREAMING>

=item C<rect> - an L<SDL2::Rect> structure representing the area to lock for access; undef to lock the entire texture

=item C<pixels> - this is filled in with a pointer to the locked pixels, appropriately offset by the locked area

=item C<pitch> - this is filled in with the pitch of the locked pixels; the pitch is the length of one row in bytes

=back

Returns 0 on success or a negative error code if the texture is not valid or
was not created with C<SDL_TEXTUREACCESS_STREAMING>; call C<SDL_GetError( )>
for more information.

=head2 C<SDL_LockTextureToSurface( ... )>

Lock a portion of the texture for B<write-only> pixel access, and expose it as
a SDL surface.

	my $surface = SDL_LockTextureSurface( $texture, $rect );

Besides providing an L<SDL2::Surface> instead of raw pixel data, this function
operates like L<SDL2::LockTexture>.

As an optimization, the pixels made available for editing don't necessarily
contain the old texture data. This is a write-only operation, and if you need
to keep a copy of the texture data you should do that at the application level.

You must use L<< C<SDL_UnlockTexture( ... )>|/C<SDL_UnlockTexture( ... )> >> to
unlock the pixels and apply any changes.

The returned surface is freed internally after calling L<< C<SDL_UnlockTexture(
... )>|/C<SDL_UnlockTexture( ... )> >> or L<< C<SDL_DestroyTexture( ...
)>|/C<SDL_DestroyTexture( ... )> >>. The caller should not free it.

Expected parameters include:

=over

=item C<texture> - the texture to lock for access, which was created with C<SDL_TEXTUREACCESS_STREAMING>

=item C<rect> - a pointer to the rectangle to lock for access. If the rect is undef, the entire texture will be locked

=back

Returns the L<SDL2::Surface> structure on success, or C<-1> if the texture is
not valid or was not created with C<SDL_TEXTUREACCESS_STREAMING>.

=head2 C<SDL_UnlockTexture( ... )>

Unlock a texture, uploading the changes to video memory, if needed.

	SDL_UnlockTexture( $texture );

B<Warning>: Please note that L<< C<SDL_LockTexture( ... )>|/C<SDL_LockTexture(
... )> >> is intended to be write-only; it will not guarantee the previous
contents of the texture will be provided. You must fully initialize any area of
a texture that you lock before unlocking it, as the pixels might otherwise be
uninitialized memory.

Which is to say: locking and immediately unlocking a texture can result in
corrupted textures, depending on the renderer in use.

Expected parameters include:

=over

=item C<texture> - a texture locked by L<< C<SDL_LockTexture( ... )>|/C<SDL_LockTexture( ... )> >>

=back

=head2 C<SDL_RenderTargetSupported( ... )>

Determine whether a renderer supports the use of render targets.

	my $bool = SDL_RenderTargetSupported( $renderer );

Expected parameters include:

=over

=item C<renderer> - the renderer that will be checked

=back

Returns true if supported or false if not.

=head2 C<SDL_SetRenderTarget( ... )>

Set a texture as the current rendering target.

	SDL_SetRenderTarget( $renderer, $texture );

Before using this function, you should check the C<SDL_RENDERER_TARGETTEXTURE>
bit in the flags of L<SDL2::RendererInfo> to see if render targets are
supported.

The default render target is the window for which the renderer was created. To
stop rendering to a texture and render to the window again, call this function
with a undefined C<texture>.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<texture> - the targeted texture, which must be created with the C<SDL_TEXTUREACCESS_TARGET> flag, or undef to render to the window instead of a texture.

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetRenderTarget( ... )>

Get the current render target.

	my $texture = SDL_GetRenderTarget( $renderer );

The default render target is the window for which the renderer was created, and
is reported an undefined value here.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns the current render target or undef for the default render target.

=head2 C<SDL_RenderSetLogicalSize( ... )>

Set a device independent resolution for rendering.

	SDL_RenderSetLogicalSize( $renderer, 100, 100 );

This function uses the viewport and scaling functionality to allow a fixed
logical resolution for rendering, regardless of the actual output resolution.
If the actual output resolution doesn't have the same aspect ratio the output
rendering will be centered within the output display.

If the output display is a window, mouse and touch events in the window will be
filtered and scaled so they seem to arrive within the logical resolution.

If this function results in scaling or subpixel drawing by the rendering
backend, it will be handled using the appropriate quality hints.

Expected parameters include:

=over

=item C<renderer> - the renderer for which resolution should be set

=item C<w> - the width of the logical resolution

=item C<h> - the height of the logical resolution

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderGetLogicalSize( ... )>

Get device independent resolution for rendering.

	my ($w, $h) = SDL_RenderGetLogicalSize( $renderer );

This may return C<0> for C<w> and C<h> if the L<SDL2::Renderer> has never had
its logical size set by L<< C<SDL_RenderSetLogicalSize( ...
)>|/C<SDL_RenderSetLogicalSize( ... )> >> and never had a render target set.

Expected parameters include:

=over

=item C<renderer> - a rendering context

=back

Returns the width and height.

=head2 C<SDL_RenderSetIntegerScale( ... )>

Set whether to force integer scales for resolution-independent rendering.

	SDL_RenderSetIntegerScale( $renderer, 1 );

This function restricts the logical viewport to integer values - that is, when
a resolution is between two multiples of a logical size, the viewport size is
rounded down to the lower multiple.

Expected parameters include:

=over

=item C<renderer> - the renderer for which integer scaling should be set

=item C<enable> - enable or disable the integer scaling for rendering

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderGetIntegerScale( ... )>

Get whether integer scales are forced for resolution-independent rendering.

	SDL_RenderGetIntegerScale( $renderer );

Expected parameters include:

=over

=item C<renderer> - the renderer from which integer scaling should be queried

=back

Returns true if integer scales are forced or false if not and on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderSetViewport( ... )>

Set the drawing area for rendering on the current target.

	SDL_RenderSetViewport( $renderer, $rect );

When the window is resized, the viewport is reset to fill the entire new window
size.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<rect> - the L<SDL2::Rect> structure representing the drawing area, or undef to set the viewport to the entire target

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderGetViewport( ... )>

Get the drawing area for the current target.

	my $rect = SDL_RenderGetViewport( $renderer );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns an L<SDL2::Rect> structure filled in with the current drawing area.

=head2 C<SDL_RenderSetClipRect( ... )>

Set the clip rectangle for rendering on the specified target.

	SDL_RenderSetClipRect( $renderer, $rect );

Expected parameters include:

=over

=item C<renderer> - the rendering context for which clip rectangle should be set

=item C<rect> - an L<SDL2::Rect> structure representing the clip area, relative to the viewport, or undef to disable clipping

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderGetClipRect( ... )>

Get the clip rectangle for the current target.

	my $rect = SDL_RenderGetClipRect( $renderer );

Expected parameters include:

=over

=item C<renderer> - the rendering context from which clip rectangle should be queried

=back

Returns an L<SDL2::Rect> structure filled in with the current clipping area or
an empty rectangle if clipping is disabled.

=head2 C<SDL_RenderIsClipEnabled( ... )>

Get whether clipping is enabled on the given renderer.

	my $tf = SDL_RenderIsClipEnabled( $renderer );

Expected parameters include:

=over

=item C<renderer> - the renderer from which clip state should be queried

=back

Returns true if clipping is enabled or false if not; call C<SDL_GetError( )>
for more information.

=head2 C<SDL_RenderSetScale( ... )>

Set the drawing scale for rendering on the current target.

	SDL_RenderSetScale( $renderer, .5, 1 );

The drawing coordinates are scaled by the x/y scaling factors before they are
used by the renderer. This allows resolution independent drawing with a single
coordinate system.

If this results in scaling or subpixel drawing by the rendering backend, it
will be handled using the appropriate quality hints. For best results use
integer scaling factors.

Expected parameters include:

=over

=item C<renderer> - a rendering context

=item C<scaleX> - the horizontal scaling factor

=item C<scaleY> - the vertical scaling factor

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderGetScale( ... )>

Get the drawing scale for the current target.

	my ($scaleX, $scaleY) = SDL_RenderGetScale( $renderer );

Expected parameters include:

=over

=item C<renderer> - the renderer from which drawing scale should be queried

=back

Returns the horizonal and vertical scaling factors.

=head2 C<SDL_SetRenderDrawColor( ... )>

Set the color used for drawing operations (Rect, Line and Clear).

	SDL_SetRenderDrawColor( $renderer, 0, 0, 128, SDL_ALPHA_OPAQUE );

Set the color for drawing or filling rectangles, lines, and points, and for L<<
C<SDL_RenderClear( ... )>|/C<SDL_RenderClear( ... )> >>.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<r> - the red value used to draw on the rendering target

=item C<g> - the green value used to draw on the rendering target

=item C<b> - the blue value used to draw on the rendering target

=item C<a> - the alpha value used to draw on the rendering target; usually C<SDL_ALPHA_OPAQUE> (255). Use C<SDL_SetRenderDrawBlendMode> to specify how the alpha channel is used

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetRenderDrawColor( ... )>

Get the color used for drawing operations (Rect, Line and Clear).

	my ($r, $g, $b, $a) = SDL_GetRenderDrawColor( $renderer );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns red, green, blue, and alpha values on success or a negative error code
on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_SetRenderDrawBlendMode( ... )>

Set the blend mode used for drawing operations (Fill and Line).

	SDL_SetRenderDrawBlendMode( $renderer, SDL_BLENDMODE_BLEND );

If the blend mode is not supported, the closest supported mode is chosen.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<blendMode> - the C<SDL_BlendMode> to use for blending

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetRenderDrawBlendMode( ... )>

Get the blend mode used for drawing operations.

	my $blendMode = SDL_GetRenderDrawBlendMode( $rendering );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns the current C<:blendMode> on success or a negative error code on
failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderClear( ... )>

Clear the current rendering target with the drawing color.

	SDL_RenderClear( $renderer );

This function clears the entire rendering target, ignoring the viewport and the
clip rectangle.

=over

=item C<renderer> - the rendering context

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderDrawPoint( ... )>

Draw a point on the current rendering target.

	SDL_RenderDrawPoint( $renderer, 100, 100 );

C<SDL_RenderDrawPoint( ... )> draws a single point. If you want to draw
multiple, use L<< C<SDL_RenderDrawPoints( ... )>|/C<SDL_RenderDrawPoints( ...
)> >> instead.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<x> - the x coordinate of the point

=item C<y> - the y coordinate of the point

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderDrawPoints( ... )>

Draw multiple points on the current rendering target.

	my @points = map { SDL2::Point->new( {x => int rand, y => int rand } ) } 1..1024;
	SDL_RenderDrawPoints( $renderer, @points );

=over

=item C<renderer> - the rendering context

=item C<points> - an array of L<SDL2::Point> structures that represent the points to draw

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderDrawLine( ... )>

Draw a line on the current rendering target.

	SDL_RenderDrawLine( $renderer, 300, 240, 340, 240 );

C<SDL_RenderDrawLine( ... )> draws the line to include both end points. If you
want to draw multiple, connecting lines use L<< C<SDL_RenderDrawLines( ...
)>|/C<SDL_RenderDrawLines( ... )> >> instead.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<x1> - the x coordinate of the start point

=item C<y1> - the y coordinate of the start point

=item C<x2> - the x coordinate of the end point

=item C<y2> - the y coordinate of the end point

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderDrawLines( ... )>

Draw a series of connected lines on the current rendering target.

	SDL_RenderDrawLines( $renderer, @points);

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<points> - an array of L<SDL2::Point> structures representing points along the lines

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderDrawRect( ... )>

Draw a rectangle on the current rendering target.

	SDL_RenderDrawRect( $renderer, SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ) );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<rect> - an L<SDL2::Rect> structure representing the rectangle to draw

=for TODO - or undef to outline the entire rendering target

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderDrawRects( ... )>

Draw some number of rectangles on the current rendering target.

	SDL_RenderDrawRects( $renderer,
		SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<rects> - an array of L<SDL2::Rect> structures representing the rectangles to be drawn

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderFillRect( ... )>

Fill a rectangle on the current rendering target with the drawing color.

	SDL_RenderFillRect( $renderer, SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ) );

The current drawing color is set by L<< C<SDL_SetRenderDrawColor( ...
)>|/C<SDL_SetRenderDrawColor( ... )> >>, and the color's alpha value is ignored
unless blending is enabled with the appropriate call to L<<
C<SDL_SetRenderDrawBlendMode( ... )>|/C<SDL_SetRenderDrawBlendMode( ... )> >>.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<rect> - the L<SDL2::Rect> structure representing the rectangle to fill

=for TODO - or undef for the entire rendering target

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderFillRects( ... )>

Fill some number of rectangles on the current rendering target with the drawing
color.

	SDL_RenderFillRects( $renderer,
		SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<rects> - an array of L<SDL2::Rect> structures representing the rectangles to be filled

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderCopy( ... )>

Copy a portion of the texture to the current rendering target.

	SDL_RenderCopy( $renderer, $blueShapes, $srcR, $destR );

The texture is blended with the destination based on its blend mode set with
L<< C<SDL_SetTextureBlendMode( ... )>|/C<SDL_SetTextureBlendMode( ... )> >>.

The texture color is affected based on its color modulation set by L<<
C<SDL_SetTextureColorMod( ... )>|/C<SDL_SetTextureColorMod( ... )> >>.

The texture alpha is affected based on its alpha modulation set by L<<
C<SDL_SetTextureAlphaMod( ... )>|/C<SDL_SetTextureAlphaMod( ... )> >>.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<texture> - the source texture

=item C<srcrect> - the source L<SDL2::Rect> structure

=for TODO: or NULL for the entire texture

=item C<dstrect> - the destination L<SDL2::Rect> structure; the texture will be stretched to fill the given rectangle

=for TODO or NULL for the entire rendering target;

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderCopyEx( ... )>

Copy a portion of the texture to the current rendering, with optional rotation
and flipping.

=for TODO: I need an example for this... it's complex

Copy a portion of the texture to the current rendering target, optionally
rotating it by angle around the given center and also flipping it top-bottom
and/or left-right.

The texture is blended with the destination based on its blend mode set with
L<< C<SDL_SetTextureBlendMode( ... )>|/C<SDL_SetTextureBlendMode( ... )> >>.

The texture color is affected based on its color modulation set by L<<
C<SDL_SetTextureColorMod( ... )>|/C<SDL_SetTextureColorMod( ... )> >>.

The texture alpha is affected based on its alpha modulation set by L<<
C<SDL_SetTextureAlphaMod( ... )>|/C<SDL_SetTextureAlphaMod( ... )> >>.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<texture> - the source texture

=item C<srcrect> - the source L<SDL2::Rect> structure

=for TODO: or NULL for the entire texture

=item C<dstrect> - the destination SDL_Rect structure

=for TODO: or NULL for the entire rendering target

=item C<angle> - an angle in degrees that indicates the rotation that will be applied to dstrect, rotating it in a clockwise direction

=item C<center> - a pointer to a point indicating the point around which dstrect will be rotated (if NULL, rotation will be done around C<dstrect.w / 2>, C<dstrect.h / 2>)

=item C<flip> - a L<:rendererFlip> value stating which flipping actions should be performed on the texture

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderDrawPointF( ... )>

Draw a point on the current rendering target at subpixel precision.

	SDL_RenderDrawPointF( $renderer, 25.5, 100.25 );

Expected parameters include:

=over

=item C<renderer> - The renderer which should draw a point.

=item C<x> - The x coordinate of the point.

=item C<y> - The y coordinate of the point.

=back

Returns C<0> on success, or C<-1> on error

=head2 C<SDL_RenderDrawPointsF( ... )>

Draw multiple points on the current rendering target at subpixel precision.

	my @points = map { SDL2::Point->new( {x => int rand, y => int rand } ) } 1..1024;
	SDL_RenderDrawPointsF( $renderer, @points );

Expected parameters include:

=over

=item C<renderer> - The renderer which should draw multiple points

=item C<points> - The points to draw

=back

Returns C<0> on success, or C<-1> on error; call C<SDL_GetError( )> for more
information.

=head2 C<SDL_RenderDrawLineF( ... )>

Draw a line on the current rendering target at subpixel precision.

	SDL_RenderDrawLineF( $renderer, 100, 100, 250, 100);

Expected parameters include:

=over

=item C<renderer> - The renderer which should draw a line.

=item C<x1> - The x coordinate of the start point.

=item C<y1> - The y coordinate of the start point.

=item C<x2> - The x coordinate of the end point.

=item C<y2> - The y coordinate of the end point.

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_RenderDrawLinesF( ... )>

Draw a series of connected lines on the current rendering target at subpixel
precision.

	SDL_RenderDrawLines( $renderer, @points);

Expected parameters include:

=over

=item C<renderer> - The renderer which should draw multiple lines.

=item C<points> - The points along the lines

=back

Return C<0> on success, or C<-1> on error.

=head2 C<SDL_RenderDrawRectF( ... )>

Draw a rectangle on the current rendering target at subpixel precision.

	SDL_RenderDrawRectF( $renderer, $point);

Expected parameters include:

=over

=item C<renderer> - The renderer which should draw a rectangle.

=item C<rect> - A pointer to the destination rectangle

=for TODO: or NULL to outline the entire rendering target.

=back

Returns C<0> on success, or C<-1> on error

=head2 C<SDL_RenderDrawRectsF( ... )>

Draw some number of rectangles on the current rendering target at subpixel
precision.

	SDL_RenderDrawRectsF( $renderer,
		SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

=over

=item C<renderer> - The renderer which should draw multiple rectangles.

=item C<rects> - A pointer to an array of destination rectangles.

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_RenderFillRectF( ... )>

Fill a rectangle on the current rendering target with the drawing color at
subpixel precision.

	SDL_RenderFillRectF( $renderer,
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

=over

=item C<renderer> - The renderer which should fill a rectangle.

=item C<rect> - A pointer to the destination rectangle

=for TODO: or NULL for the entire rendering target.

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_RenderFillRectsF( ... )>

Fill some number of rectangles on the current rendering target with the drawing
color at subpixel precision.

	SDL_RenderFillRectsF( $renderer,
		SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

=over

=item C<renderer> - The renderer which should fill multiple rectangles.

=item C<rects> - A pointer to an array of destination rectangles.

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_RenderCopyF( ... )>

Copy a portion of the texture to the current rendering target at subpixel
precision.

=for TODO: I need to come up with an example for this as well

Expected parameters include:

=over

=item C<renderer> - The renderer which should copy parts of a texture

=item C<texture> - The source texture

=item C<srcrect> - A pointer to the source rectangle

=for TODO: or NULL for the entiretexture.

=item C<dstrect> - A pointer to the destination rectangle

=for TODO: or NULL for the entire rendering target

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_RenderCopyExF( ... )>

Copy a portion of the source texture to the current rendering target, with
rotation and flipping, at subpixel precision.

=for TODO: I need to come up with an example for this as well

=over

=item C<renderer> - The renderer which should copy parts of a texture

=item C<texture> - The source texture

=item C<srcrect> - A pointer to the source rectangle

=for TODO: or NULL for the entire texture

=item C<dstrect> - A pointer to the destination rectangle

=for TODO: or NULL for the entire rendering target.

=item C<angle> - An angle in degrees that indicates the rotation that will be applied to dstrect, rotating it in a clockwise direction

=item C<center> - A pointer to a point indicating the point around which dstrect will be rotated (if NULL, rotation will be done around C<dstrect.w/2>, C<dstrect.h/2>)

=item C<flip> - A C<:rendererFlip> value stating which flipping actions should be performed on the texture

=back

Returns C<0> on success, or C<-1> on error

=head2 C<SDL_RenderReadPixels( ... )>

Read pixels from the current rendering target to an array of pixels.

	SDL_RenderReadPixels(
        $renderer,
        SDL2::Rect->new( { x => 0, y => 0, w => 640, h => 480 } ),
        SDL_PIXELFORMAT_RGB888,
        $surface->pixels, $surface->pitch
    );

B<WARNING>: This is a very slow operation, and should not be used frequently.

C<pitch> specifies the number of bytes between rows in the destination
C<pixels> data. This allows you to write to a subrectangle or have padded rows
in the destination. Generally, C<pitch> should equal the number of pixels per
row in the `pixels` data times the number of bytes per pixel, but it might
contain additional padding (for example, 24bit RGB Windows Bitmap data pads all
rows to multiples of 4 bytes).

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<rect> - an L<SDL2::Rect> structure representing the area to read

=for TODO: or NULL for the entire render target

=item C<format> - an C<:pixelFormatEnum> value of the desired format of the pixel data, or C<0> to use the format of the rendering target

=item C<pixels> - pointer to the pixel data to copy into

=item C<pitch> - the pitch of the C<pixels> parameter

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderPresent( ... )>

Update the screen with any rendering performed since the previous call.

	SDL_RenderPresent( $renderer );

SDL's rendering functions operate on a backbuffer; that is, calling a rendering
function such as L<< C<SDL_RenderDrawLine( ... )>|/C<SDL_RenderDrawLine( ... )>
>> does not directly put a line on the screen, but rather updates the
backbuffer. As such, you compose your entire scene and *present* the composed
backbuffer to the screen as a complete picture.

Therefore, when using SDL's rendering API, one does all drawing intended for
the frame, and then calls this function once per frame to present the final
drawing to the user.

The backbuffer should be considered invalidated after each present; do not
assume that previous contents will exist between frames. You are strongly
encouraged to call L<< C<SDL_RenderClear( ... )>|/C<SDL_RenderClear( ... )> >>
to initialize the backbuffer before starting each new frame's drawing, even if
you plan to overwrite every pixel.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

=head2 C<SDL_DestroyTexture( ... )>

Destroy the specified texture.

	SDL_DestroyTexture( $texture );

Passing undef or an otherwise invalid texture will set the SDL error message to
"Invalid texture".

Expected parameters include:

=over

=item C<texture> - the texture to destroy

=back


=head2 C<SDL_DestroyRenderer( ... )>

Destroy the rendering context for a window and free associated textures.

	SDL_DestroyRenderer( $renderer );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

=head2 C<SDL_RenderFlush( ... )>

Force the rendering context to flush any pending commands to the underlying
rendering API.

	SDL_RenderFlush( $renderer );

You do not need to (and in fact, shouldn't) call this function unless you are
planning to call into OpenGL/Direct3D/Metal/whatever directly in addition to
using an SDL_Renderer.

This is for a very-specific case: if you are using SDL's render API, you asked
for a specific renderer backend (OpenGL, Direct3D, etc), you set
C<SDL_HINT_RENDER_BATCHING> to "C<1>", and you plan to make OpenGL/D3D/whatever
calls in addition to SDL render API calls. If all of this applies, you should
call L<< C<SDL_RenderFlush( ... )>|/C<SDL_RenderFlush( ... )> >> between calls
to SDL's render API and the low-level API you're using in cooperation.

In all other cases, you can ignore this function. This is only here to get
maximum performance out of a specific situation. In all other cases, SDL will
do the right thing, perhaps at a performance loss.

This function is first available in SDL 2.0.10, and is not needed in 2.0.9 and
earlier, as earlier versions did not queue rendering commands at all, instead
flushing them to the OS immediately.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.


=head2 C<SDL_GL_BindTexture( ... )>

Bind an OpenGL/ES/ES2 texture to the current context.

	my ($texw, $texh) = SDL_GL_BindTexture( $texture );

This is for use with OpenGL instructions when rendering OpenGL primitives
directly.

If not NULL, the returned width and height values suitable for the provided
texture. In most cases, both will be C<1.0>, however, on systems that support
the GL_ARB_texture_rectangle extension, these values will actually be the pixel
width and height used to create the texture, so this factor needs to be taken
into account when providing texture coordinates to OpenGL.

You need a renderer to create an L<SDL2::Texture>, therefore you can only use
this function with an implicit OpenGL context from L<< C<SDL_CreateRenderer(
... )>|/C<SDL_CreateRenderer( ... )> >>, not with your own OpenGL context. If
you need control over your OpenGL context, you need to write your own
texture-loading methods.

Also note that SDL may upload RGB textures as BGR (or vice-versa), and re-order
the color channels in the shaders phase, so the uploaded texture may have
swapped color channels.

Expected parameters include:

=over

=item C<texture> - the texture to bind to the current OpenGL/ES/ES2 context

=back

Returns the texture's with and height on success, or -1 if the operation is not
supported; call C<SDL_GetError( )> for more information.

=head2 C<SDL_GL_UnbindTexture( ... )>

Unbind an OpenGL/ES/ES2 texture from the current context.

	SDL_GL_UnbindTexture( $texture );

See L<< C<SDL_GL_BindTexture( ... )>|/C<SDL_GL_BindTexture( ... )> >> for
examples on how to use these functions.

Expected parameters include:

=over

=item C<texture> - the texture to unbind from the current OpenGL/ES/ES2 context

=back

Returns C<0> on success, or C<-1> if the operation is not supported.

=head2 C<SDL_RenderGetMetalLayer( ... )>

Get the CAMetalLayer associated with the given Metal renderer.

	my $opaque = SDL_RenderGetMetalLayer( $renderer );

This function returns C<void *>, so SDL doesn't have to include Metal's
headers, but it can be safely cast to a C<CAMetalLayer *>.

Expected parameters include:

=over

=item C<renderer> - the renderer to query

=back

Returns C<CAMetalLayer*> on success, or undef if the renderer isn't a Metal
renderer.

=head2 C<SDL_RenderGetMetalCommandEncoder( ... )>

Get the Metal command encoder for the current frame

	$opaque = SDL_RenderGetMetalCommandEncoder( $renderer );

This function returns C<void *>, so SDL doesn't have to include Metal's
headers, but it can be safely cast to an
C<idE<lt>MTLRenderCommandEncoderE<gt>>.

Expected parameters include:

=over

=item C<renderer> - the renderer to query

=back

Returns C<idE<lt>MTLRenderCommandEncoderE<gt>> on success, or undef if the
renderer isn't a Metal renderer.

=head1 Defined Variables and Enumerations

Variables may be imported by name or with the C<:render> tag. Enumerations may
be imported with their given tags.

=head2 C<SDL_RendererFlags>

Flags used when creating a rendering context.

=over

=item C<SDL_RENDERER_SOFTWARE> - The renderer is a software fallback

=item C<SDL_RENDERER_ACCELERATED> - The renderer uses hardware acceleration

=item C<SDL_RENDERER_PRESENTVSYNC> - Present is synchronized with the refresh rate

=item C<SDL_RENDERER_TARGETTEXTURE> - The renderer supports rendering to texture

=back

=head2 C<SDL_ScaleMode>

The scaling mode for a texture.

=over

=item C<SDL_ScaleModeNearest> - nearest pixel sampling

=item C<SDL_ScaleModeLinear> - linear filtering

=item C<SDL_ScaleModeBest> - anisotropic filtering

=back

=head2 C<SDL_TextureAccess>

The access pattern allowed for a texture.

=over

=item C<SDL_TEXTUREACCESS_STATIC> - Changes rarely, not lockable

=item C<SDL_TEXTUREACCESS_STREAMING> - Changes frequently, lockable

=item C<SDL_TEXTUREACCESS_TARGET> - Texture can be used as a render target

=back

=head2 C<SDL_TextureModulate>

The texture channel modulation used in C<SDL_RenderCopy( )>.

=over

=item C<SDL_TEXTUREMODULATE_NONE> - No modulation

=item C<SDL_TEXTUREMODULATE_COLOR> - C<srcC = srcC * color>

=item C<SDL_TEXTUREMODULATE_ALPHA> - C<srcA = srcA * alpha>

=back

=head2 C<SDL_RendererFlip>

Flip constants for SDL_RenderCopyEx

=over

=item C<SDL_FLIP_NONE> - Do not flip

=item C<SDL_FLIP_HORIZONTAL> - flip horizontally

=item C<SDL_FLIP_VERTICAL> - flip vertically

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

high-dpi rect viewport subpixel dstrect subrectangle backbuffer OpenGL
vice-versa CAMetalLayer

=end stopwords

=cut

};
1;
