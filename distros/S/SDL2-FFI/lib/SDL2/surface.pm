package SDL2::surface 0.01 {
    use SDL2::Utils;
    use experimental 'signatures';
    use FFI::C::ArrayDef;
    #
    use SDL2::stdinc;
    use SDL2::pixels;
    use SDL2::rect;
    use SDL2::blendmode;
    use SDL2::rwops;
    #
    package SDL2::Surface {
        use SDL2::Utils;
        our $TYPE = has
            flags     => 'uint32',
            _format   => 'opaque',     # SDL_PixelFormat*
            w         => 'int',
            h         => 'int',
            pitch     => 'int',
            pixels    => 'opaque',     # void*
            userdata  => 'opaque',     # void*
            locked    => 'int',
            lock_data => 'opaque',     # void*
            clip_rect => 'SDL_Rect',
            _map      => 'opaque',     # SDL_BlitMap*
            refcount  => 'int';
        #
        sub format ( $s, $color = () ) {
            defined $_[1] ? $_[0]->_color( ffi->cast( 'SDL_PixelFormat', 'opaque', $_[1] ) ) :
                ffi->cast( 'opaque', 'SDL_PixelFormat', $_[0]->_format );
        }

        sub map ( $s, $color = () ) {
            defined $_[1] ? $_[0]->_map( ffi->cast( 'SDL_BlitMap', 'opaque', $_[1] ) ) :
                ffi->cast( 'opaque', 'SDL_BlitMap', $_[0]->_map );
        }
    };
    #
    enum SDL_YUV_CONVERSION_MODE => [
        qw[SDL_YUV_CONVERSION_JPEG
            SDL_YUV_CONVERSION_BT601
            SDL_YUV_CONVERSION_BT709
            SDL_YUV_CONVERSION_AUTOMATIC]
    ];
    attach surface => {
        SDL_CreateRGBSurface => [
            [ 'uint32', 'int', 'int', 'int', 'uint32', 'uint32', 'uint32', 'uint32' ],
            'SDL_Surface'
        ],
        SDL_CreateRGBSurfaceWithFormat =>
            [ [ 'uint32', 'int', 'int', 'int', 'uint32' ], 'SDL_Surface' ],
        SDL_CreateRGBSurfaceFrom => [    # FIX: uint16 might be large enough for raw data
            [ 'uint16[]', 'int', 'int', 'int', 'int', 'uint32', 'uint32', 'uint32', 'uint32' ],
            'SDL_Surface'
        ],
        SDL_CreateRGBSurfaceWithFormatFrom => [    # FIX: uint16 might be large enough for raw data
            [ 'uint16[]', 'int', 'int', 'int', 'int', 'uint32' ], 'SDL_Surface'
        ],
        SDL_FreeSurface         => [ ['SDL_Surface'] ],
        SDL_SetSurfacePalette   => [ [ 'SDL_Surface', 'SDL_Palette' ], 'int' ],
        SDL_LockSurface         => [ ['SDL_Surface'],                  'int' ],
        SDL_UnlockSurface       => [ ['SDL_Surface'] ],
        SDL_LoadBMP_RW          => [ [ 'SDL_RWops', 'int' ],                       'SDL_Surface' ],
        SDL_SaveBMP_RW          => [ [ 'SDL_Surface', 'SDL_RWops', 'int' ],        'int' ],
        SDL_SetSurfaceRLE       => [ [ 'SDL_Surface', 'int' ],                     'int' ],
        SDL_HasSurfaceRLE       => [ ['SDL_Surface'],                              'SDL_bool' ],
        SDL_SetColorKey         => [ [ 'SDL_Surface', 'int', 'uint32' ],           'int' ],
        SDL_HasColorKey         => [ ['SDL_Surface'],                              'SDL_bool' ],
        SDL_GetColorKey         => [ [ 'SDL_Surface', 'uint32' ],                  'int' ],
        SDL_SetSurfaceColorMod  => [ [ 'SDL_Surface', 'uint8', 'uint8', 'uint8' ], 'int' ],
        SDL_GetSurfaceColorMod  => [ [ 'SDL_Surface', 'uint8*', 'uint8*', 'uint8*' ], 'int' ],
        SDL_SetSurfaceAlphaMod  => [ [ 'SDL_Surface', 'uint8' ],                      'int' ],
        SDL_GetSurfaceAlphaMod  => [ [ 'SDL_Surface', 'uint8*' ],                     'int' ],
        SDL_SetSurfaceBlendMode => [ [ 'SDL_Surface', 'SDL_BlendMode' ],              'int' ],
        SDL_GetSurfaceBlendMode => [ [ 'SDL_Surface', 'SDL_BlendMode' ],              'int' ],
        SDL_SetClipRect         => [ [ 'SDL_Surface', 'SDL_Rect' ],                   'SDL_bool' ],
        SDL_GetClipRect         => [ [ 'SDL_Surface', 'SDL_Rect' ] ],
        SDL_DuplicateSurface    => [ ['SDL_Surface'], 'SDL_Surface' ],
        SDL_ConvertSurface => [ [ 'SDL_Surface', 'SDL_PixelFormat', 'uint32' ], 'SDL_Surface' ],
        SDL_ConvertSurfaceFormat => [ [ 'SDL_Surface', 'uint32', 'uint32' ], 'SDL_Surface' ],
        SDL_ConvertPixels        => [    # FIX: uint16 might be large enough for raw data
            [ 'int', 'int', 'uint32', 'uint16[]', 'int', 'uint32', 'uint16[]', 'int' ], 'int'
        ],
        SDL_FillRect  => [ [ 'SDL_Surface', 'SDL_Rect', 'uint32' ], 'int' ],
        SDL_FillRects => [
            [ 'SDL_Surface', 'RectList_t', 'int', 'uint32' ],
            'int' => sub ( $inner, $dst, $_rects, $count, $color ) {
                my $rects = $SDL2::Rect::LIST->create(
                    [ map { { x => $_->x, y => $_->y, w => $_->w, h => $_->h } } @$_rects ] );
                $inner->( $dst, $rects, $count, $color );
            }
        ],
        SDL_UpperBlit   => [ [ 'SDL_Surface', 'SDL_Rect', 'SDL_Surface', 'SDL_Rect' ], 'int' ],
        SDL_LowerBlit   => [ [ 'SDL_Surface', 'SDL_Rect', 'SDL_Surface', 'SDL_Rect' ], 'int' ],
        SDL_SoftStretch => [ [ 'SDL_Surface', 'SDL_Rect', 'SDL_Surface', 'SDL_Rect' ], 'int' ],
        SDL_SoftStretchLinear =>
            [ [ 'SDL_Surface', 'SDL_Rect', 'SDL_Surface', 'SDL_Rect' ], 'int' ],
        SDL_UpperBlitScaled => [ [ 'SDL_Surface', 'SDL_Rect', 'SDL_Surface', 'SDL_Rect' ], 'int' ],
        SDL_LowerBlitScaled => [ [ 'SDL_Surface', 'SDL_Rect', 'SDL_Surface', 'SDL_Rect' ], 'int' ],
        SDL_SetYUVConversionMode              => [ ['SDL_YUV_CONVERSION_MODE'] ],
        SDL_GetYUVConversionMode              => [ [],               'SDL_YUV_CONVERSION_MODE' ],
        SDL_GetYUVConversionModeForResolution => [ [ 'int', 'int' ], 'SDL_YUV_CONVERSION_MODE' ]
    };
    define surface => [
        [   SDL_LoadBMP => sub ($file) {
                SDL2::FFI::SDL_LoadBMP_RW( SDL2::FFI::SDL_RWFromFile( $file, 'rb' ), 1 );
            }
        ],
        [   SDL_SaveBMP => sub ( $surface, $file ) {
                SDL2::FFI::SDL_SaveBMP_RW( $surface, SDL2::FFI::SDL_RWFromFile( $file, 'wb' ), 1 );
            }
        ],
        [   SDL_BlitSurface => sub ( $src, $srcrect, $dst, $dstrect ) {
                SDL2::FFI::SDL_UpperBlit( $src, $srcrect, $dst, $dstrect );
            }
        ],
        [   SDL_BlitScaled => sub ( $src, $srcrect, $dst, $dstrect ) {
                SDL2::FFI::SDL_UpperBlitScaled( $src, $srcrect, $dst, $dstrect );
            }
        ],
    ];

=encoding utf-8

=head1 NAME

SDL2::surface - SDL2::Surface Management Functions

=head1 SYNOPSIS

    use SDL2 qw[:surface];

=head1 DESCRIPTION

SDL2::surface contains enumerations, functions, and other values used to manage
a SDL2::Surface structure.

=head1 Functions

These may be imported with the C<:surface> tag or individually by name.

=head2 C<SDL_CreateRGBSurface( ... )>

Allocate a new RGB surface.

    my ( $height, $width ) = ( 100, 100 );
    # Create a 32-bit surface with the bytes of each pixel in R,G,B,A order,
    #   as expected by OpenGL for textures
    my ( $rmask, $gmask, $bmask, $amask );
    # SDL interprets each pixel as a 32-bit number, so our masks must depend
    #   on the endianness (byte order) of the machine
    if ( SDL_BYTEORDER() eq SDL_LIL_ENDIAN() ) {
        $rmask = 0xff000000;
        $gmask = 0x00ff0000;
        $bmask = 0x0000ff00;
        $amask = 0x000000ff;
    }
    else {
        $rmask = 0x000000ff;
        $gmask = 0x0000ff00;
        $bmask = 0x00ff0000;
        $amask = 0xff000000;
    }
    my $surface = SDL_CreateRGBSurface( 0, $width, $height, 32, $rmask, $gmask, $bmask, $amask );
    if ( !defined $surface ) {
        SDL_Log( 'SDL_CreateRGBSurface() failed: %s', SDL_GetError() );
        exit 1;
    }
    # or using the default masks for the depth:
    $surface = SDL_CreateRGBSurface( 0, $width, $height, 32, 0, 0, 0, 0 );

If C<depth> is 4 or 8 bits, an empty palette is allocated for the surface. If
C<depth> is greater than 8 bits, the pixel format is set using the [RGBA]mask
parameters.

The [RGBA]mask parameters are the bitmasks used to extract that color from a
pixel. For instance, `Rmask` being 0xFF000000 means the red data is stored in
the most significant byte. Using zeros for the RGB masks sets a default value,
based on the depth. For example:

	SDL_CreateRGBSurface( 0, $w, $h, 32, 0, 0, 0, 0 );

However, using zero for the Amask results in an Amask of 0.

By default surfaces with an alpha mask are set up for blending as with:

	SDL_SetSurfaceBlendMode( $surface, SDL_BLENDMODE_BLEND );

You can change this by calling L<< C<SDL_SetSurfaceBlendMode( ...
)>|/C<SDL_SetSurfaceBlendMode( ... )> >> and selecting a different
C<blendMode>.

Expected parameters include:

=over

=item C<flags> - the flags are unused and should be set to 0

=item C<width> - the width of the surface

=item C<height> - the height of the surface

=item C<depth> - the depth of the surface in bits

=item C<Rmask> - the red mask for the pixels

=item C<Gmask> - the green mask for the pixels

=item C<Bmask> - the blue mask for the pixels

=item C<Amask> - the alpha mask for the pixels

=back

Returns the new L<SDL2::Surface> structure that is created or C<undef> if it
fails; call C<SDL_GetError( )> for more information.

=head2 C<SDL_CreateRGBSurfaceWithFormat( ... )>

Allocate a new RGB surface with a specific pixel format.

    # Create a 32-bit surface with the bytes of each pixel in R,G,B,A order,
    # as expected by OpenGL for textures
    my $surf = SDL_CreateRGBSurfaceWithFormat( 0, 100, 100, 32, SDL_PIXELFORMAT_RGBA32 );
    if ( !defined $surf ) {
        SDL_Log( "SDL_CreateRGBSurfaceWithFormat() failed: %s", SDL_GetError() );
        exit 1;
    }

This function operates mostly like L<< C<SDL_CreateRGBSurface( ...
)>|/C<SDL_CreateRGBSurface( ... )> >>, except instead of providing pixel color
masks, you provide it with a predefined format from C<SDL_PixelFormatEnum>.

Expected parameters include:

=over

=item C<flags> - the flags are unused and should be set to C<0>

=item C<width> - the width of the surface

=item C<height> - the height of the surface

=item C<depth> - the depth of the surface in bits

=item C<format> - the C<SDL_PixelFormatEnum> for the new surface's pixel format.

=back

Returns the new L<SDL2::Surface> structure that is created or C<undef> if it
fails; call C<SDL_GetError( )> for more information.

=head2 C<SDL_CreateRGBSurfaceFrom( ... )>

Allocate a new RGB surface with existing pixel data.

	# Declare an SDL2::Surface to be filled with raw pixel data
    my $pixels = [
        0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff,
        0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff,
        0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff,
        0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff,
        0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0aab,
        0x0789, 0x0bcc, 0x0eee, 0x09aa, 0x099a, 0x0ddd, 0x0fff, 0x0eee, 0x0899, 0x0fff,
        0x0fff, 0x1fff, 0x0dde, 0x0dee, 0x0fff, 0xabbc, 0xf779, 0x8cdd, 0x3fff, 0x9bbc,
        0xaaab, 0x6fff, 0x0fff, 0x3fff, 0xbaab, 0x0fff, 0x0fff, 0x6689, 0x6fff, 0x0dee,
        0xe678, 0xf134, 0x8abb, 0xf235, 0xf678, 0xf013, 0xf568, 0xf001, 0xd889, 0x7abc,
        0xf001, 0x0fff, 0x0fff, 0x0bcc, 0x9124, 0x5fff, 0xf124, 0xf356, 0x3eee, 0x0fff,
        0x7bbc, 0xf124, 0x0789, 0x2fff, 0xf002, 0xd789, 0xf024, 0x0fff, 0x0fff, 0x0002,
        0x0134, 0xd79a, 0x1fff, 0xf023, 0xf000, 0xf124, 0xc99a, 0xf024, 0x0567, 0x0fff,
        0xf002, 0xe678, 0xf013, 0x0fff, 0x0ddd, 0x0fff, 0x0fff, 0xb689, 0x8abb, 0x0fff,
        0x0fff, 0xf001, 0xf235, 0xf013, 0x0fff, 0xd789, 0xf002, 0x9899, 0xf001, 0x0fff,
        0x0fff, 0x0fff, 0x0fff, 0xe789, 0xf023, 0xf000, 0xf001, 0xe456, 0x8bcc, 0xf013,
        0xf002, 0xf012, 0x1767, 0x5aaa, 0xf013, 0xf001, 0xf000, 0x0fff, 0x7fff, 0xf124,
        0x0fff, 0x089a, 0x0578, 0x0fff, 0x089a, 0x0013, 0x0245, 0x0eff, 0x0223, 0x0dde,
        0x0135, 0x0789, 0x0ddd, 0xbbbc, 0xf346, 0x0467, 0x0fff, 0x4eee, 0x3ddd, 0x0edd,
        0x0dee, 0x0fff, 0x0fff, 0x0dee, 0x0def, 0x08ab, 0x0fff, 0x7fff, 0xfabc, 0xf356,
        0x0457, 0x0467, 0x0fff, 0x0bcd, 0x4bde, 0x9bcc, 0x8dee, 0x8eff, 0x8fff, 0x9fff,
        0xadee, 0xeccd, 0xf689, 0xc357, 0x2356, 0x0356, 0x0467, 0x0467, 0x0fff, 0x0ccd,
        0x0bdd, 0x0cdd, 0x0aaa, 0x2234, 0x4135, 0x4346, 0x5356, 0x2246, 0x0346, 0x0356,
        0x0467, 0x0356, 0x0467, 0x0467, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff,
        0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff,
        0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff,
        0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff, 0x0fff
    ];
    my $surface
        = SDL_CreateRGBSurfaceFrom( $pixels, 16, 16, 16, 16 * 2, 0x0f00, 0x00f0, 0x000f, 0xf000 );
	# Set the icon to the window
    SDL_SetWindowIcon( $window, $surface ) if $surface;
	# No longer required
	SDL_FreeSurface( $surface );

This function operates mostly like L<< C<SDL_CreateRGBSurface( ...
)>|/C<SDL_CreateRGBSurface( ... )> >>, except it does not allocate memory for
the pixel data, instead the caller provides an existing buffer of data for the
surface to use.

No copy is made of the pixel data. Pixel data is not managed automatically; you
must free the surface before you free the pixel data.

Expected parameters include:

=over

=item C<pixels> - a pointer to existing pixel data

=item C<width> - the width of the surface

=item C<height> - the height of the surface

=item C<depth> - the depth of the surface in bits

=item C<pitch> - the pitch of the surface in bytes

=item C<Rmask> - the red mask for the pixels

=item C<Gmask> - the green mask for the pixels

=item C<Bmask> - the blue mask for the pixels

=item C<Amask> - the alpha mask for the pixels

=back

Returns the new L<SDL2::Surface> structure that is created or NULL if it fails;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_CreateRGBSurfaceWithFormatFrom( ... )>

Allocate a new RGB surface with with a specific pixel format and existing pixel
data.

This function operates mostly like L<< C<SDL_CreateRGBSurfaceFrom( ...
)>|/C<SDL_CreateRGBSurfaceFrom( ... )> >>, except instead of providing pixel
color masks, you provide it with a predefined format from
C<SDL_PixelFormatEnum>.

No copy is made of the pixel data. Pixel data is not managed automatically; you
must free the surface before you free the pixel data.

Expected parameters include:

=over

=item C<pixels> - a pointer to existing pixel data

=item C<width> - the width of the surface

=item C<height> - the height of the surface

=item C<depth> - the depth of the surface in bits

=item C<pitch> - the pitch of the surface in bytes

=item C<format> - the C<SDL_PixelFormatEnum> for the new surface's pixel format.

=back

Returns the new L<SDL2::Surface> structure that is created or C<undef> if it
fails; call C<SDL_GetError( )> for more information.

=head2 C<SDL_FreeSurface( ... )>

Free an RGB surface.

Expected parameters include:

=over

=item C<surface> - the C<SDL2::Surface> to free

=back

=head2 C<SDL_SetSurfacePalette( ... )>

Set the palette used by a surface.

A single palette can be shared with many surfaces.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to update

=item C<palette> - the L<SDL2::Palette> structure to use

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_LockSurface( ... )>

Set up a surface for directly accessing the pixels.

Between calls to C<SDL_LockSurface( ... )> / L<< C<SDL_UnlockSurface( ...
)>|/C<SDL_UnlockSurface( ... )> >>, you can write to and read from C<<
surface->pixels >>, using the pixel format stored in C<< surface->format >>.
Once you are done accessing the surface, you should use L<<
C<SDL_UnlockSurface( ... )>|/C<SDL_UnlockSurface( ... )> >> to release it.

Not all surfaces require locking. If C<SDL_MUSTLOCK(surface)> evaluates to
C<0>, then you can read and write to the surface at any time, and the pixel
format of the surface will not change.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to be locked

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_UnlockSurface( ... )>

Release a surface after directly accessing the pixels.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to be unlocked

=back

=head2 C<SDL_LoadBMP_RW( ... )>

Load a BMP image from a seekable SDL data stream.

The new surface should be freed with L<< C<SDL_FreeSurface( ...
)>|/C<SDL_FreeSurface( ... )> >>.

Expected parameters include:

=over

=item C<src> - the data stream for the surface

=item C<freesrc> - non-zero to close the stream after being read

=back

Returns a pointer to a new L<SDL2::Surface> structure or C<undef> if there was
an error; call C<SDL_GetError( )> for more information.

=head2 C<SDL_LoadBMP( ... )>

Load a surface from a file.

	my $surface = SDL_LoadBMP( './icons/16x16.bmp' );

Expected parameters include:

=over

=item C<file> - path to a filename to read

=back

Returns a pointer to a new L<SDL2::Surface> structure or C<undef> if there was
an error; call C<SDL_GetError( )> for more information.

=head2 C<SDL_SaveBMP_RW( ... )>

Save a surface to a seekable SDL data stream in BMP format.

Surfaces with a 24-bit, 32-bit and paletted 8-bit format get saved in the BMP
directly. Other RGB formats with 8-bit or higher get converted to a 24-bit
surface or, if they have an alpha mask or a colorkey, to a 32-bit surface
before they are saved. YUV and paletted 1-bit and 4-bit formats are not
supported.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure containing the image to be saved

=item C<dst> - a data stream to save to

=item C<freedst> - non-zero to close the stream after being written

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SaveBMP( ... )>

Save a surface to a file.

	SDL_SaveBMP( $surface, './icons/output.bmp' );

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure containing the image to be saved

=item C<file> - file to save to

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SetSurfaceRLE( ... )>

Set the RLE acceleration hint for a surface.

If RLE is enabled, color key and alpha blending blits are much faster, but the
surface must be locked before directly accessing the pixels.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to optimize

=item C<flag> - C<0> to disable, non-zero to enable RLE acceleration

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HasSurfaceRLE( ... )>

Returns whether the surface is RLE enabled

Expected parameters include:

=over

=item C<surface> the L<SDL2::Surface> structure to query

=back

Returns C<SDL_TRUE> if the surface is RLE enabled, C<SDL_FALSE> otherwise.

=head2 C<SDL_SetColorKey( ... )>

Set the color key (transparent pixel) in a surface.

The color key defines a pixel value that will be treated as transparent in a
blit. It is a pixel of the format used by the surface, as generated by
C<SDL_MapRGB( ... )>.

RLE acceleration can substantially speed up blitting of images with large
horizontal runs of transparent pixels. See L<< C<SDL_SetSurfaceRLE( ...
)>|/C<SDL_SetSurfaceRLE( ... )> >> for details.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to update

=item C<flag> - C<SDL_TRUE> to enable color key, C<SDL_FALSE> to disable color key

=item C<key> - the transparent pixel

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HasColorKey( ... )>

Returns whether the surface has a color key.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to query

=back

Returns C<SDL_TRUE> if the surface has a color key, C<SDL_FALSE> otherwise.

=head2 C<SDL_GetColorKey( ... )>

Get the color key (transparent pixel) for a surface.

The color key is a pixel of the format used by the surface, as generated by
C<SDL_MapRGB( )>.

If the surface doesn't have color key enabled this function returns C<-1>.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to query

=item C<key> a pointer filled in with the transparent pixel

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SetSurfaceColorMod( ... )>

Set an additional color value multiplied into blit operations.

When this surface is blitted, during the blit operation each source color
channel is modulated by the appropriate color value according to the following
formula: C<srcC = srcC * (color / 255)>

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to update

=item C<r> - the red color value multiplied into blit operations

=item C<g> - the green color value multiplied into blit operations

=item C<b> - the blue color value multiplied into blit operations

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetSurfaceColorMod( ... )>

Get the additional color value multiplied into blit operations.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to query

=item C<r> - a pointer filled in with the current red color value

=item C<g> - a pointer filled in with the current green color value

=item C<b> - a pointer filled in with the current blue color value

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SetSurfaceAlphaMod( ... )>

Set an additional alpha value used in blit operations.

When this surface is blitted, during the blit operation the source alpha value
is modulated by this alpha value according to the following formula: C<srcA =
srcA * (alpha / 255)>.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to update

=item C<alpha> - the alpha value multiplied into blit operations

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetSurfaceAlphaMod( ... )>

Get the additional alpha value used in blit operations.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to query

=item C<alpha> - a pointer filled in with the current alpha value

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SetSurfaceBlendMode( ... )>

Set the blend mode used for blit operations.

To copy a surface to another surface (or texture) without blending with the
existing data, the blendmode of the SOURCE surface should be set to
C<SDL_BLENDMODE_NONE>.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to update

=item C<blendMode> - the SDL_BlendMode to use for blit blending

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetSurfaceBlendMode( ... )>

Get the blend mode used for blit operations.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to query

=item C<blendMode> - a pointer filled in with the current SDL_BlendMode

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SetClipRect( ... )>

Set the clipping rectangle for a surface.

When C<surface> is the destination of a blit, only the area within the clip
rectangle is drawn into.

Note that blits are automatically clipped to the edges of the source and
destination surfaces.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure to be clipped

=item C<rect> - the SDL_Rect structure representing the clipping rectangle, or C<undef> to disable clipping

=back

Returns C<SDL_TRUE> if the rectangle intersects the surface, otherwise
C<SDL_FALSE> and blits will be completely clipped.

=head2 C<SDL_GetClipRect( ... )>

Get the clipping rectangle for a surface.

When C<surface> is the destination of a blit, only the area within the clip
rectangle is drawn into.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure representing the surface to be clipped

=item C<rect> - an SDL_Rect structure filled in with the clipping rectangle for the surface

=back

=head2 C<SDL_DuplicateSurface( ... )>

Creates a new surface identical to the existing surface.

The returned surface should be freed with L<< C<SDL_FreeSurface( ...
)>|/C<SDL_FreeSurface( ... )> >>.

Expected parameters include:

=over

=item C<surface> - the surface to duplicate.

=back

Returns a copy of the surface, or C<undef> on failure; call C<SDL_GetError( )>
for more information.

=head2 C<SDL_ConvertSurface( ... )>

Copy an existing surface to a new surface of the specified format.

This function is used to optimize images for faster *repeat* blitting. This is
accomplished by converting the original and storing the result as a new
surface. The new, optimized surface can then be used as the source for future
blits, making them faster.

Expected parameters include:

=over

=item C<src> - the existing SDL_Surface structure to convert

=item C<fmt> - the SDL_PixelFormat structure that the new surface is optimized for

=item C<flags> - the flags are unused and should be set to 0; this is a leftover from SDL 1.2's API

=back

Returns the new L<SDL2::Surface> structure that is created or C<undef> if it
fails; call C<SDL_GetError( )> for more information.

=head2 C<SDL_ConvertSurfaceFormat( ... )>

Copy an existing surface to a new surface of the specified format enum.

This function operates just like L<< C<SDL_ConvertSurface( ...
)>|/C<SDL_ConvertSurface( ... )> >>, but accepts an C<SDL_PixelFormatEnum>
value instead of an SDL_PixelFormat structure. As such, it might be easier to
call but it doesn't have access to palette information for the destination
surface, in case that would be important.

Expected parameters include:

=over

=item C<src> - the existing L<SDL2::Surface> structure to convert

=item C<pixel_format> - the C<SDL_PixelFormatEnum> that the new surface is optimized for

=item C<flags> - the flags are unused and should be set to 0; this is a leftover from SDL 1.2's API

=back

Returns the new L<SDL2::Surface> structure that is created or C<undef> if it
fails; call C<SDL_GetError( )> for more information.

=head2 C<SDL_ConvertPixels( ... )>

Copy a block of pixels of one format to another format.

Expected parameters include:

=over

=item C<width> - the width of the block to copy, in pixels

=item C<height> - the height of the block to copy, in pixels

=item C<src_format> - an C<SDL_PixelFormatEnum> value of the C<src> pixels format

=item C<src> - a pointer to the source pixels

=item C<src_pitch> - the pitch of the block to copy, in bytes

=item C<dst_format> - an C<SDL_PixelFormatEnum> value of the C<dst> pixels format

=item C<dst> - a pointer to be filled in with new pixel data

=item C<dst_pitch> - the pitch of the destination pixels, in bytes

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_FillRect( ... )>

Perform a fast fill of a rectangle with a specific color.

C<color> should be a pixel of the format used by the surface, and can be
generated by C<SDL_MapRGB( ... )> or C<SDL_MapRGBA( ... )>. If the color value
contains an alpha component then the destination is simply filled with that
alpha information, no blending takes place.

If there is a clip rectangle set on the destination (set via C<SDL_SetClipRect(
... )>), then this function will fill based on the intersection of the clip
rectangle and C<rect>.

Expected parameters include:

=over

=item C<dst> - the L<SDL2::Surface> structure that is the drawing target

=item C<rect> - the SDL_Rect structure representing the rectangle to fill, or C<undef> to fill the entire surface

=item C<color> - the color to fill with

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_FillRects( ... )>

Perform a fast fill of a set of rectangles with a specific color.

    my @rects = (
        SDL2::Rect->new( { w => 100, h => 100, x => 0,   y => 0 } ),
        SDL2::Rect->new( { w => 100, h => 100, x => 200, y => 20 } )
    );
    my $surface = SDL_LoadBMP('./imgs/640_426.bmp');
    SDL_FillRects( $surface, \@rects, scalar @rects, 255 ); # blue
    SDL_SaveBMP( $surface, './imgs/new_640_426.bmp' );

C<color> should be a pixel of the format used by the surface, and can be
generated by C<SDL_MapRGB( ... )> or C<SDL_MapRGBA( ... )>. If the color value
contains an alpha component then the destination is simply filled with that
alpha information, no blending takes place.

If there is a clip rectangle set on the destination (set via C<SDL_SetClipRect(
... )>), then this function will fill based on the intersection of the clip
rectangle and C<rect>.

Expected parameters include:

=over

=item C<dst> - the L<SDL2::Surface> structure that is the drawing target

=item C<rects> - an array of C<SDL2::Rects> representing the rectangles to fill.

=item C<count> - the number of rectangles in the array

=item C<color> - the color to fill with

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_BlitSurface( ... )>

Performs a fast blit from the source surface to the destination surface.

Expected parameters include:

=over

=item C<src> - the C<SDL2::Surface> structure to be copied from

=item C<srcrect> - the L<SDL2::Rect> structure representing the rectangle to be copied, or C<undef> to copy the entire surface

=item C<dst> - the L<SDL2::Surface> structure that is the blit target

=item C<dstrect> - the L<SDL2::Rect> structure representing the rectangle that is copied into

=back

This assumes that the source and destination rectangles are the same size. If
either C<srcrect> or C<dstrect> are C<undef>, the entire surface (C<src> or
C<dst>) is copied.  The final blit rectangles are saved in C<srcrect> and
C<dstrect> after all clipping is performed.

If the blit is successful, it returns C<0>, otherwise it returns C<-1>.

The blit function should not be called on a locked surface.

The blit semantics for surfaces with and without blending and colorkey are
defined as follows:

    RGBA->RGB:
      Source surface blend mode set to SDL_BLENDMODE_BLEND:
        alpha-blend (using the source alpha-channel and per-surface alpha)
        SDL_SRCCOLORKEY ignored.
      Source surface blend mode set to SDL_BLENDMODE_NONE:
        copy RGB.
        if SDL_SRCCOLORKEY set, only copy the pixels matching the
        RGB values of the source color key, ignoring alpha in the
        comparison.
    RGB->RGBA:
      Source surface blend mode set to SDL_BLENDMODE_BLEND:
        alpha-blend (using the source per-surface alpha)
      Source surface blend mode set to SDL_BLENDMODE_NONE:
        copy RGB, set destination alpha to source per-surface alpha value.
      both:
        if SDL_SRCCOLORKEY set, only copy the pixels matching the
        source color key.
    RGBA->RGBA:
      Source surface blend mode set to SDL_BLENDMODE_BLEND:
        alpha-blend (using the source alpha-channel and per-surface alpha)
        SDL_SRCCOLORKEY ignored.
      Source surface blend mode set to SDL_BLENDMODE_NONE:
        copy all of RGBA to the destination.
        if SDL_SRCCOLORKEY set, only copy the pixels matching the
        RGB values of the source color key, ignoring alpha in the
        comparison.
    RGB->RGB:
      Source surface blend mode set to SDL_BLENDMODE_BLEND:
        alpha-blend (using the source per-surface alpha)
      Source surface blend mode set to SDL_BLENDMODE_NONE:
        copy RGB.
      both:
        if SDL_SRCCOLORKEY set, only copy the pixels matching the
        source color key.

You should call C<SDL_BlitSurface( ... )> unless you know exactly how SDL
blitting works internally and how to use the other blit functions.

Returns C<0> if the blit is successful or a negative error code on failure;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_UpperBlit( )>

Perform a fast blit from the source surface to the destination surface.

Expected parameters include:

=over

=item C<src> - the C<SDL2::Surface> structure to be copied from

=item C<srcrect> - the L<SDL2::Rect> structure representing the rectangle to be copied, or C<undef> to copy the entire surface

=item C<dst> - the L<SDL2::Surface> structure that is the blit target

=item C<dstrect> - the L<SDL2::Rect> structure representing the rectangle that is copied into

=back

C<SDL_UpperBlit( ... )> has been replaced by L<< C<SDL_BlitSurface( ...
)>|/C<SDL_BlitSurface( ... )> >>, which is merely a wrapper for this function
with a less confusing name.

Returns C<0> if the blit is successful or a negative error code on failure;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_LowerBlit( ... )>

Perform low-level surface blitting only.

This is a semi-private blit function and it performs low-level surface
blitting, assuming the input rectangles have already been clipped.

Unless you know what you're doing, you should be using L<< C<SDL_BlitSurface(
... )>|/C<SDL_BlitSurface( ... )> >> instead.

Expected parameters include:

=over

=item C<src> - the L<SDL2::Surface> structure to be copied from

=item C<srcrect> - the L<SDL2::Rect> structure representing the rectangle to be copied, or C<undef> to copy the entire surface

=item C<dst> - the L<SDL2::Surface> structure that is the blit target

=item C<dstrect> - the L<SDL2::Rect> structure representing the rectangle that is copied into

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SoftStretch( ... )>

Perform a fast, low quality, stretch blit between two surfaces of the same
format.

Expected parameters include:

=over

=item C<src> - the L<SDL2::Surface> structure to be copied from

=item C<srcrect> - the L<SDL2::Rect> structure representing the rectangle to be copied, or C<undef> to copy the entire surface

=item C<dst> - the L<SDL2::Surface> structure that is the blit target

=item C<dstrect> - the L<SDL2::Rect> structure representing the rectangle that is copied into

=back

B<Warning>: This function uses a static buffer, and is not thread-safe.

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

Please use L<< C<SDL_BlitScaled( ... )>|/C<SDL_BlitScaled( ... )> >> instead.

=head2 C<SDL_SoftStretchLinear( ... )>

Perform bilinear scaling between two surfaces of the same format, 32BPP.

Expected parameters include:

=over

=item C<src> - the L<SDL2::Surface> structure to be copied from

=item C<srcrect> - the L<SDL2::Rect> structure representing the rectangle to be copied, or C<undef> to copy the entire surface

=item C<dst> - the L<SDL2::Surface> structure that is the blit target

=item C<dstrect> - the L<SDL2::Rect> structure representing the rectangle that is copied into

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

Please use L<< C<SDL_BlitScaled( ... )>|/C<SDL_BlitScaled( ... )> >> instead.

=head2 C<SDL_BlitScaled( ... )>

Perform a scaled surface copy to a destination surface.

Expected parameters include:

=over

=item C<src> - the L<SDL2::Surface> structure to be copied from

=item C<srcrect> - the L<SDL2::Rect> structure representing the rectangle to be copied, or C<undef> to copy the entire surface

=item C<dst> - the L<SDL2::Surface> structure that is the blit target

=item C<dstrect> - the L<SDL2::Rect> structure representing the rectangle that is copied into

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_UpperBlitScaled( ... )>

Perform a scaled surface copy to a destination surface.

Expected parameters include:

=over

=item C<src> - the L<SDL2::Surface> structure to be copied from

=item C<srcrect> - the L<SDL2::Rect> structure representing the rectangle to be copied, or C<undef> to copy the entire surface

=item C<dst> - the L<SDL2::Surface> structure that is the blit target

=item C<dstrect> - the L<SDL2::Rect> structure representing the rectangle that is copied into

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

C<SDL_UpperBlitScaled( ... )> has been replaced by L<< C<SDL_BlitScaled( ...
)>|/C<SDL_BlitScaled( ... )> >>, which is merely a wrapper for this function
with a less confusing name.

=head2 C<SDL_LowerBlitScaled( ... )>

Perform low-level surface scaled blitting only.

Expected parameters include:

=over

=item C<src> - the L<SDL2::Surface> structure to be copied from

=item C<srcrect> - the L<SDL2::Rect> structure representing the rectangle to be copied, or C<undef> to copy the entire surface

=item C<dst> - the L<SDL2::Surface> structure that is the blit target

=item C<dstrect> - the L<SDL2::Rect> structure representing the rectangle that is copied into

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

This is a semi-private function and it performs low-level surface blitting,
assuming the input rectangles have already been clipped.

=head2 C<SDL_SetYUVConversionMode( ... )>

Set the YUV conversion mode.

Expected parameters include;

=over

=item C<mode> - a C<SDL_YUV_CONVERSION_MODE>

=back

=head2 C<SDL_GetYUVConversionMode( )>

Get the YUV conversion mode.

Returns a C<SDL_GetYUVConversionMode> value.

=head2 C<SDL_GetYUVConversionModeForResolution( ... )>

Get the YUV conversion mode, returning the correct mode for the resolution when
the current conversion mode is C<SDL_YUV_CONVERSION_AUTOMATIC>.

Expected parameters include:

=over

=item C<width>

=item C<height>

=back

Returns a C<SDL_YUV_CONVERSION_MODE> value.

=head1 Defined Values and Enumerations

These may be imported with the given tag or individually by name.

=head2 C<SDL_YUV_CONVERSION_MODE>

The formula used for converting between YUV and RGB. These values may be
imported with the C<:YUV_CONVERSION_MODE> tag.

=over

=item C<SDL_YUV_CONVERSION_JPEG> - Full range JPEG

=item C<SDL_YUV_CONVERSION_BT601> - BT.601 (the default)

=item C<SDL_YUV_CONVERSION_BT709> - BT.709

=item C<SDL_YUV_CONVERSION_AUTOMATIC> - BT.601 for SD content, BT.709 for HD content

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

colorkey paletted bitmasks blit blits blitted blitting blendmode rect enum
0xFF000000

=end stopwords

=cut

};
1;
