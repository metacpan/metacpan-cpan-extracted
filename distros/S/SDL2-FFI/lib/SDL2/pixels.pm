package SDL2::pixels 0.01 {
    use SDL2::Utils;
    use experimental 'signatures';
    #
    #
    use SDL2::stdinc;
    use SDL2::endian;
    #
    define pixels      => [ [ SDL_ALPHA_OPAQUE => 255 ], [ SDL_ALPHA_TRANSPARENT => 0 ] ];
    enum SDL_PixelType => [
        qw[SDL_PIXELTYPE_UNKNOWN
            SDL_PIXELTYPE_INDEX1
            SDL_PIXELTYPE_INDEX4
            SDL_PIXELTYPE_INDEX8
            SDL_PIXELTYPE_PACKED8
            SDL_PIXELTYPE_PACKED16
            SDL_PIXELTYPE_PACKED32
            SDL_PIXELTYPE_ARRAYU8
            SDL_PIXELTYPE_ARRAYU16
            SDL_PIXELTYPE_ARRAYU32
            SDL_PIXELTYPE_ARRAYF16
            SDL_PIXELTYPE_ARRAYF32]
        ],
        SDL_BitmapOrder => [
        qw[
            SDL_BITMAPORDER_NONE
            SDL_BITMAPORDER_4321
            SDL_BITMAPORDER_1234]
        ],
        SDL_PackedOrder => [
        qw[
            SDL_PACKEDORDER_NONE
            SDL_PACKEDORDER_XRGB
            SDL_PACKEDORDER_RGBX
            SDL_PACKEDORDER_ARGB
            SDL_PACKEDORDER_RGBA
            SDL_PACKEDORDER_XBGR
            SDL_PACKEDORDER_BGRX
            SDL_PACKEDORDER_ABGR
            SDL_PACKEDORDER_BGRA
        ]
        ],
        SDL_ArrayOrder => [
        qw[SDL_ARRAYORDER_NONE
            SDL_ARRAYORDER_RGB
            SDL_ARRAYORDER_RGBA
            SDL_ARRAYORDER_ARGB
            SDL_ARRAYORDER_BGR
            SDL_ARRAYORDER_BGRA
            SDL_ARRAYORDER_ABGR]
        ],
        SDL_PackedLayout => [
        qw[SDL_PACKEDLAYOUT_NONE
            SDL_PACKEDLAYOUT_332
            SDL_PACKEDLAYOUT_4444
            SDL_PACKEDLAYOUT_1555
            SDL_PACKEDLAYOUT_5551
            SDL_PACKEDLAYOUT_565
            SDL_PACKEDLAYOUT_8888
            SDL_PACKEDLAYOUT_2101010
            SDL_PACKEDLAYOUT_1010102]
        ];
    define pixels => [
        [   SDL_DEFINE_PIXELFOURCC =>
                sub ( $A, $B, $C, $D ) { SDL2::FFI::SDL_FOURCC( $A, $B, $C, $D ) }
        ],
        [   SDL_DEFINE_PIXELFORMAT => sub ( $type, $order, $layout, $bits, $bytes ) {
                ( ( 1 << 28 ) | ( ($type) << 24 ) | ( ($order) << 20 ) | ( ($layout) << 16 )
                        | ( ($bits) << 8 ) | ( ($bytes) << 0 ) )
            }
        ],
        [ SDL_PIXELFLAG    => sub ($X) { ( ( ($X) >> 28 ) & 0x0F ) } ],
        [ SDL_PIXELTYPE    => sub ($X) { ( ( ($X) >> 24 ) & 0x0F ) } ],
        [ SDL_PIXELORDER   => sub ($X) { ( ( ($X) >> 20 ) & 0x0F ) } ],
        [ SDL_PIXELLAYOUT  => sub ($X) { ( ( ($X) >> 16 ) & 0x0F ) } ],
        [ SDL_BITSPERPIXEL => sub ($X) { ( ( ($X) >> 8 ) & 0xFF ) } ],
        [   SDL_BYTESPERPIXEL => sub ($X) {
                (
                    SDL2::FFI::SDL_ISPIXELFORMAT_FOURCC($X) ? (
                        (
                            ( ($X) == SDL2::FFI::SDL_PIXELFORMAT_YUY2() )     ||
                                ( ($X) == SDL2::FFI::SDL_PIXELFORMAT_UYVY() ) ||
                                ( ($X) == SDL2::FFI::SDL_PIXELFORMAT_YVYU() )
                        ) ? 2 : 1
                        ) :
                        ( ( ($X) >> 0 ) & 0xFF )
                )
            }
        ],
        [   SDL_ISPIXELFORMAT_INDEXED => sub ($format) {
                (
                    !SDL2::FFI::SDL_ISPIXELFORMAT_FOURCC($format) && (
                        ( SDL2::FFI::SDL_PIXELTYPE($format) == SDL2::FFI::SDL_PIXELTYPE_INDEX1() )
                        ||
                        ( SDL2::FFI::SDL_PIXELTYPE($format) == SDL2::FFI::SDL_PIXELTYPE_INDEX4() )
                        ||
                        ( SDL2::FFI::SDL_PIXELTYPE($format) == SDL2::FFI::SDL_PIXELTYPE_INDEX8() )
                    )
                )
            }
        ],
        [   SDL_ISPIXELFORMAT_PACKED => sub ($format) {
                (
                    !SDL2::FFI::SDL_ISPIXELFORMAT_FOURCC($format) && (
                        ( SDL2::FFI::SDL_PIXELTYPE($format) == SDL2::FFI::SDL_PIXELTYPE_PACKED8() )
                        ||
                        ( SDL2::FFI::SDL_PIXELTYPE($format) == SDL2::FFI::SDL_PIXELTYPE_PACKED16() )
                        ||
                        ( SDL2::FFI::SDL_PIXELTYPE($format) == SDL2::FFI::SDL_PIXELTYPE_PACKED32() )
                    )
                )
            }
        ],
        [   SDL_ISPIXELFORMAT_ARRAY => sub ($format) {
                (
                    !SDL2::FFI::SDL_ISPIXELFORMAT_FOURCC($format) && (
                        ( SDL2::FFI::SDL_PIXELTYPE($format) == SDL2::FFI::SDL_PIXELTYPE_ARRAYU8() )
                        ||
                        ( SDL2::FFI::SDL_PIXELTYPE($format) == SDL2::FFI::SDL_PIXELTYPE_ARRAYU16() )
                        ||
                        ( SDL2::FFI::SDL_PIXELTYPE($format) == SDL2::FFI::SDL_PIXELTYPE_ARRAYU32() )
                        ||
                        ( SDL2::FFI::SDL_PIXELTYPE($format) == SDL2::FFI::SDL_PIXELTYPE_ARRAYF16() )
                        ||
                        ( SDL2::FFI::SDL_PIXELTYPE($format) == SDL2::FFI::SDL_PIXELTYPE_ARRAYF32() )
                    )
                )
            }
        ],
        [   SDL_ISPIXELFORMAT_ALPHA => sub ($format) {
                (
                    (
                        SDL2::FFI::SDL_ISPIXELFORMAT_PACKED($format) && (
                            (
                                SDL2::FFI::SDL_PIXELORDER($format)
                                == SDL2::FFI::SDL_PACKEDORDER_ARGB()
                            ) ||
                            ( SDL2::FFI::SDL_PIXELORDER($format)
                                == SDL2::FFI::SDL_PACKEDORDER_RGBA() ) ||
                            ( SDL2::FFI::SDL_PIXELORDER($format)
                                == SDL2::FFI::SDL_PACKEDORDER_ABGR() ) ||
                            ( SDL2::FFI::SDL_PIXELORDER($format)
                                == SDL2::FFI::SDL_PACKEDORDER_BGRA() )
                        )
                    ) ||
                        (
                        SDL2::FFI::SDL_ISPIXELFORMAT_ARRAY($format) &&
                        (
                            (
                                SDL2::FFI::SDL_PIXELORDER($format)
                                == SDL2::FFI::SDL_ARRAYORDER_ARGB()
                            ) ||
                            ( SDL2::FFI::SDL_PIXELORDER($format)
                                == SDL2::FFI::SDL_ARRAYORDER_RGBA() ) ||
                            ( SDL2::FFI::SDL_PIXELORDER($format)
                                == SDL2::FFI::SDL_ARRAYORDER_ABGR() ) ||
                            ( SDL2::FFI::SDL_PIXELORDER($format)
                                == SDL2::FFI::SDL_ARRAYORDER_BGRA() )
                        )
                        )
                )
            }
        ],

        # The flag is set to 1 because 0x1? is not in the printable ASCII range
        [   SDL_ISPIXELFORMAT_FOURCC =>
                sub ($format) { ( ($format) && ( SDL2::FFI::SDL_PIXELFLAG($format) != 1 ) ) }
        ]
    ];
    enum SDL_PixelFormatEnum => [
        'SDL_PIXELFORMAT_UNKNOWN',
        [   SDL_PIXELFORMAT_INDEX1LSB => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_INDEX1(),
                    SDL2::FFI::SDL_BITMAPORDER_4321(),
                    0, 1, 0
                );
            }
        ],
        [   SDL_PIXELFORMAT_INDEX1MSB => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_INDEX1(),
                    SDL2::FFI::SDL_BITMAPORDER_1234(),
                    0, 1, 0
                );
            }
        ],
        [   SDL_PIXELFORMAT_INDEX4LSB => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_INDEX4(),
                    SDL2::FFI::SDL_BITMAPORDER_4321(),
                    0, 4, 0
                );
            }
        ],
        [   SDL_PIXELFORMAT_INDEX4MSB => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_INDEX4(),
                    SDL2::FFI::SDL_BITMAPORDER_1234(),
                    0, 4, 0
                );
            }
        ],
        [   SDL_PIXELFORMAT_INDEX8 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT( SDL2::FFI::SDL_PIXELTYPE_INDEX8(), 0, 0, 8, 1 );
            }
        ],
        [   SDL_PIXELFORMAT_RGB332 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED8(),
                    SDL2::FFI::SDL_PACKEDORDER_XRGB(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_332(),
                    8, 1
                );
            }
        ],
        [   SDL_PIXELFORMAT_XRGB4444 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_XRGB(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_4444(),
                    12, 2
                );
            }
        ],
        [ SDL_PIXELFORMAT_RGB444 => sub () { SDL_PIXELFORMAT_XRGB4444() } ],
        [   SDL_PIXELFORMAT_XBGR4444 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_XBGR(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_4444(),
                    12, 2
                );
            }
        ],
        [ SDL_PIXELFORMAT_BGR444 => sub () { SDL2::FFI::SDL_PIXELFORMAT_XBGR4444() } ],
        [   SDL_PIXELFORMAT_XRGB1555 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_XRGB(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_1555(),
                    15, 2
                );
            }
        ],
        [ SDL_PIXELFORMAT_RGB555 => sub () { SDL2::FFI::SDL_PIXELFORMAT_XRGB1555() } ],
        [   SDL_PIXELFORMAT_XBGR1555 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_XBGR(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_1555(),
                    15, 2
                );
            }
        ],
        [ SDL_PIXELFORMAT_BGR555 => sub () { SDL2::FFI::SDL_PIXELFORMAT_XBGR1555() } ],
        [   SDL_PIXELFORMAT_ARGB4444 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_ARGB(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_4444(),
                    16, 2
                );
            }
        ],
        [   SDL_PIXELFORMAT_RGBA4444 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_RGBA(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_4444(),
                    16, 2
                );
            }
        ],
        [   SDL_PIXELFORMAT_ABGR4444 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_ABGR(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_4444(),
                    16, 2
                );
            }
        ],
        [   SDL_PIXELFORMAT_BGRA4444 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_BGRA(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_4444(),
                    16, 2
                );
            }
        ],
        [   SDL_PIXELFORMAT_ARGB1555 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_ARGB(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_1555(),
                    16, 2
                );
            }
        ],
        [   SDL_PIXELFORMAT_RGBA5551 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_RGBA(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_5551(),
                    16, 2
                );
            }
        ],
        [   SDL_PIXELFORMAT_ABGR1555 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_ABGR(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_1555(),
                    16, 2
                );
            }
        ],
        [   SDL_PIXELFORMAT_BGRA5551 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_BGRA(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_5551(),
                    16, 2
                );
            }
        ],
        [   SDL_PIXELFORMAT_RGB565 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_XRGB(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_565(),
                    16, 2
                );
            }
        ],
        [   SDL_PIXELFORMAT_BGR565 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED16(),
                    SDL2::FFI::SDL_PACKEDORDER_XBGR(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_565(),
                    16, 2
                );
            }
        ],
        [   SDL_PIXELFORMAT_RGB24 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_ARRAYU8(),
                    SDL2::FFI::SDL_ARRAYORDER_RGB(),
                    0, 24, 3
                );
            }
        ],
        [   SDL_PIXELFORMAT_BGR24 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_ARRAYU8(),
                    SDL2::FFI::SDL_ARRAYORDER_BGR(),
                    0, 24, 3
                );
            }
        ],
        [   SDL_PIXELFORMAT_XRGB8888 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED32(),
                    SDL2::FFI::SDL_PACKEDORDER_XRGB(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_8888(),
                    24, 4
                );
            }
        ],
        [ SDL_PIXELFORMAT_RGB888 => sub () { SDL2::FFI::SDL_PIXELFORMAT_XRGB8888() } ],
        [   SDL_PIXELFORMAT_RGBX8888 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED32(),
                    SDL2::FFI::SDL_PACKEDORDER_RGBX(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_8888(),
                    24, 4
                );
            }
        ],
        [   SDL_PIXELFORMAT_XBGR8888 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED32(),
                    SDL2::FFI::SDL_PACKEDORDER_XBGR(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_8888(),
                    24, 4
                );
            }
        ],
        [ SDL_PIXELFORMAT_BGR888 => sub () { SDL2::FFI::SDL_PIXELFORMAT_XBGR8888() } ],
        [   SDL_PIXELFORMAT_BGRX8888 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED32(),
                    SDL2::FFI::SDL_PACKEDORDER_BGRX(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_8888(),
                    24, 4
                );
            }
        ],
        [   SDL_PIXELFORMAT_ARGB8888 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED32(),
                    SDL2::FFI::SDL_PACKEDORDER_ARGB(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_8888(),
                    32, 4
                );
            }
        ],
        [   SDL_PIXELFORMAT_RGBA8888 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED32(),
                    SDL2::FFI::SDL_PACKEDORDER_RGBA(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_8888(),
                    32, 4
                );
            }
        ],
        [   SDL_PIXELFORMAT_ABGR8888 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED32(),
                    SDL2::FFI::SDL_PACKEDORDER_ABGR(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_8888(),
                    32, 4
                );
            }
        ],
        [   SDL_PIXELFORMAT_BGRA8888 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED32(),
                    SDL2::FFI::SDL_PACKEDORDER_BGRA(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_8888(),
                    32, 4
                );
            }
        ],
        [   SDL_PIXELFORMAT_ARGB2101010 => sub () {
                SDL2::FFI::SDL_DEFINE_PIXELFORMAT(
                    SDL2::FFI::SDL_PIXELTYPE_PACKED32(),
                    SDL2::FFI::SDL_PACKEDORDER_ARGB(),
                    SDL2::FFI::SDL_PACKEDLAYOUT_2101010(),
                    32, 4
                );
            }
        ],    # Aliases for RGBA byte arrays of color data, for the current platform
        SDL2::FFI::SDL_BYTEORDER() == SDL2::FFI::SDL_BIG_ENDIAN() ? (
            [ SDL_PIXELFORMAT_RGBA32 => sub() { SDL2::FFI::SDL_PIXELFORMAT_RGBA8888() } ],
            [ SDL_PIXELFORMAT_ARGB32 => sub() { SDL2::FFI::SDL_PIXELFORMAT_ARGB8888() } ],
            [ SDL_PIXELFORMAT_BGRA32 => sub() { SDL2::FFI::SDL_PIXELFORMAT_BGRA8888() } ],
            [ SDL_PIXELFORMAT_ABGR32 => sub() { SDL2::FFI::SDL_PIXELFORMAT_ABGR8888() } ]
            ) : (
            [ SDL_PIXELFORMAT_RGBA32 => sub() { SDL2::FFI::SDL_PIXELFORMAT_ABGR8888() } ],
            [ SDL_PIXELFORMAT_ARGB32 => sub() { SDL2::FFI::SDL_PIXELFORMAT_BGRA8888() } ],
            [ SDL_PIXELFORMAT_BGRA32 => sub() { SDL2::FFI::SDL_PIXELFORMAT_ARGB8888() } ],
            [ SDL_PIXELFORMAT_ABGR32 => sub() { SDL2::FFI::SDL_PIXELFORMAT_RGBA8888() } ],
            ),
        [   SDL_PIXELFORMAT_YV12 =>
                sub () { SDL2::FFI::SDL_DEFINE_PIXELFOURCC( 'Y', 'V', '1', '2' ) }
        ],
        [   SDL_PIXELFORMAT_IYUV =>
                sub () { SDL2::FFI::SDL_DEFINE_PIXELFOURCC( 'I', 'Y', 'U', 'V' ) }
        ],
        [   SDL_PIXELFORMAT_YUY2 =>
                sub () { SDL2::FFI::SDL_DEFINE_PIXELFOURCC( 'Y', 'U', 'Y', '2' ) }
        ],
        [   SDL_PIXELFORMAT_UYVY =>
                sub () { SDL2::FFI::SDL_DEFINE_PIXELFOURCC( 'U', 'Y', 'V', 'Y' ) }
        ],
        [   SDL_PIXELFORMAT_YVYU =>
                sub () { SDL2::FFI::SDL_DEFINE_PIXELFOURCC( 'Y', 'V', 'Y', 'U' ) }
        ],
        [   SDL_PIXELFORMAT_NV12 =>
                sub () { SDL2::FFI::SDL_DEFINE_PIXELFOURCC( 'N', 'V', '1', '2' ) }
        ],
        [   SDL_PIXELFORMAT_NV21 =>
                sub () { SDL2::FFI::SDL_DEFINE_PIXELFOURCC( 'N', 'V', '2', '1' ) }
        ],
        [   SDL_PIXELFORMAT_EXTERNAL_OES =>
                sub () { SDL2::FFI::SDL_DEFINE_PIXELFOURCC( 'O', 'E', 'S', ' ' ) }
        ]
    ];

    package SDL2::Color {
        use SDL2::Utils;
        our $TYPE = has r => 'uint8', g => 'uint8', b => 'uint8', a => 'uint8';
    };

    package SDL2::Palette {
        use SDL2::Utils;
        use experimental 'signatures';
        our $TYPE = has
            ncolors  => 'int',
            _colors  => 'opaque',    #'SDL_Color*',
            version  => 'uint32',
            refcount => 'int';

        sub colors ( $s, $color = () ) {
            defined $_[1] ? $_[0]->_color( ffi->cast( 'SDL_Color', 'opaque', $_[1] ) ) :
                ffi->cast( 'opaque', 'SDL_Color', $_[0]->_color );
        }
    };

    package SDL2::PixelFormat {
        use SDL2::Utils;
        our $TYPE = has
            format        => 'uint32',
            palette       => 'SDL_Palette',
            BitsPerPixel  => 'uint8',
            BytesPerPixel => 'uint8',
            padding       => 'uint8[2]',
            Rmask         => 'uint32',
            Gmask         => 'uint32',
            Bmask         => 'uint32',
            Amask         => 'uint32',
            Rloss         => 'uint8',
            Gloss         => 'uint8',
            Bloss         => 'uint8',
            Aloss         => 'uint8',
            Rshift        => 'uint8',
            Gshift        => 'uint8',
            Bshift        => 'uint8',
            Ashift        => 'uint8',
            refcount      => 'int',
            _next         => 'opaque';        # SDL_PixelFormat *
        ffi->attach_cast( '_cast' => 'opaque' => 'SDL_AssertData' );

        sub next {                            # TODO: Broken.
            my ($self) = @_;
            defined $self->_next ? _cast( $self->_next ) : undef;
        }
    };
    attach pixels => {
        SDL_GetPixelFormatName     => [ ['uint32'], 'string' ],
        SDL_PixelFormatEnumToMasks =>
            [ [ 'uint32', 'int*', 'uint32*', 'uint32*', 'uint32*', 'uint32*' ], 'SDL_bool' ],
        SDL_MasksToPixelFormatEnum =>
            [ [ 'int', 'uint32', 'uint32', 'uint32', 'uint32' ], 'uint32' ],
        SDL_AllocFormat           => [ ['uint32'], 'SDL_PixelFormat' ],
        SDL_FreeFormat            => [ ['SDL_PixelFormat'] ],
        SDL_AllocPalette          => [ ['int'],                              'SDL_Palette' ],
        SDL_SetPixelFormatPalette => [ [ 'SDL_PixelFormat', 'SDL_Palette' ], 'int' ],
        SDL_SetPaletteColors      => [ [ 'SDL_Palette', 'SDL_Color', 'int', 'int' ], 'int' ],
        SDL_FreePalette => [ ['SDL_Palette'] ],
        SDL_MapRGB      => [ [ 'SDL_PixelFormat', 'uint8', 'uint8', 'uint8' ], 'uint32' ],
        SDL_MapRGBA     => [ [ 'SDL_PixelFormat', 'uint8', 'uint8', 'uint8', 'uint8' ], 'uint32' ],
        SDL_GetRGB      => [ [ 'uint32', 'SDL_PixelFormat', 'uint8*', 'uint8*', 'uint8*' ] ],
        SDL_GetRGBA => [ [ 'uint32', 'SDL_PixelFormat', 'uint8*', 'uint8*', 'uint8*', 'uint8*' ] ],
        SDL_CalculateGammaRamp => [ [ 'float', 'uint16[256]' ] ]
    };

=encoding utf-8

=head1 NAME

SDL2::pixels - Enumerated Pixel Format Definitions

=head1 SYNOPSIS

    use SDL2 qw[:pixels];

=head1 DESCRIPTION

SDL2::pixels defines pixel format values and related functions.

=head1 Functions

=head2 C<SDL_GetPixelFormatName( ... )>

Get the human readable name of a pixel format.

	SDL_GetPixelFormatName(370546692);

Expected parameters include:

=over

=item C<format> - the pixel format to query

=back

Returns the human readable name of the specified pixel format or
C<SDL_PIXELFORMAT_UNKNOWN> if the format isn't recognized.

=head2 C<SDL_PixelFormatEnumToMasks( ... )>

Convert one of the enumerated pixel formats to a C<bpp> value and RGBA masks.

	SDL_PixelFormatEnumToMasks(
		SDL_PIXELFORMAT_ABGR8888,
		\my $bpp,
		\my $rmask, \my $bmask, \my $gmask, \my $amask
	) || return SDL_SetError('Unknown format');

Expected parameters include:

=over

=item C<format> - one of the SDL_PixelFormatEnum values

=item C<bpp> - a bits per pixel value; usually 15, 16, or 32

=item C<Rmask> - a pointer filled in with the red mask for the format

=item C<Gmask> - a pointer filled in with the green mask for the format

=item C<Bmask> - a pointer filled in with the blue mask for the format

=item C<Amask> - a pointer filled in with the alpha mask for the format

=back

Returns C<SDL_TRUE> on success or C<SDL_FALSE> if the conversion wasn't
possible; call C<SDL_GetError( )> for more information.

=head2 C<SDL_MasksToPixelFormatEnum( ... )>

Convert a bpp value and RGBA masks to an enumerated pixel format.

    # ARGB8888
    my $amask = 0xff000000;
    my $rmask = 0x00ff0000;
    my $gmask = 0x0000ff00;
    my $bmask = 0x000000ff;
    SDL_MasksToPixelFormatEnum( 32, $rmask, $gmask, $bmask, $amask );

This will return C<SDL_PIXELFORMAT_UNKNOWN> if the conversion wasn't possible.

Expected parameters include:

=over

=item C<bpp> - a bits per pixel value; usually 15, 16, or 32

=item C<Rmask> - the red mask for the format

=item C<Gmask> - the green mask for the format

=item C<Bmask> - the blue mask for the format

=item C<Amask> - the alpha mask for the format

=back

Returns one of the C<SDL_PixelFormatEnum> values.

=head2 C<SDL_AllocFormat( ... )>

Create an L<SDL2::PixelFormat> structure corresponding to a pixel format.

    # ARGB8888
    my $amask = 0xff000000;
    my $rmask = 0x00ff0000;
    my $gmask = 0x0000ff00;
    my $bmask = 0x000000ff;
    my $format
        = SDL_AllocFormat( SDL_MasksToPixelFormatEnum( 32, $rmask, $gmask, $bmask, $amask ) );

Returned structure may come from a shared global cache (i.e. not newly
allocated), and hence should not be modified, especially the palette. Weird
errors such as C<Blit combination not supported> may occur.

Expected parameters include:

=over

=item C<pixel_format> - one of the SDL_PixelFormatEnum values

=back

Returns the new L<SDL2::PixelFormat> structure or undef on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_FreeFormat( ... )>

Free an SDL_PixelFormat structure allocated by L<< C<SDL_AllocFormat( ...
)>|/C<SDL_AllocFormat( ... )> >>.

Expected parameters include:

=over

=item C<format> the C<SDL2::PixelFormat> structure to free

=back

=head2 C<SDL_AllocPalette( ... )>

Create a palette structure with the specified number of color entries.

	my $palette = SDL_AllocPalette(256);

The palette entries are initialized to white.

Expected parameters include:

=over

=item C<ncolors> - represents the number of color entries in the color palette

=back

Returns a new L<SDL2::Palette> structure on success or undef on failure (e.g.
if there wasn't enough memory); call C<SDL_GetError( )> for more information.

=head2 C<SDL_SetPixelFormatPalette( ... )>

Set the palette for a pixel format structure.

Expected parameters include:

=over

=item C<format> - the L<SDL2::PixelFormat> structure that will use the palette

=item C<palette> - the L<SDL2::Palette> structure that will be used

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SetPaletteColors( ... )>

Set a range of colors in a palette.

Expected parameters include:

=over

=item C<palette> - the SDL_Palette structure to modify

=item C<colors> - an array of SDL_Color structures to copy into the palette

=item C<firstcolor> - the index of the first palette entry to modify

=item C<ncolors> - the number of entries to modify

=back

Returns C<0> on success or a negative error code if not all of the colors could
be set; call C<SDL_GetError( )> for more information.

=head2 C<SDL_FreePalette( ... )>

Free a palette created with L<< C<SDL_AllocPalette( ... )>|/C<SDL_AllocPalette(
... )> >>.

Expected parameters include:

=over

=item C<palette> - the L<SDL2::Palette> structure to be freed

=back

=head2 C<SDL_MapRGB( ... )>

Map an RGB triple to an opaque pixel value for a given pixel format.

This function maps the RGB color value to the specified pixel format and
returns the pixel value best approximating the given RGB color value for the
given pixel format.

If the format has a palette (8-bit) the index of the closest matching color in
the palette will be returned.

If the specified pixel format has an alpha component it will be returned as all
1 bits (fully opaque).

If the pixel format bpp (color depth) is less than 32-bpp then the unused upper
bits of the return value can safely be ignored (e.g., with a 16-bpp format the
return value can be assigned to a Uint16, and similarly a Uint8 for an 8-bpp
format).

Expected parameters include:

=over

=item C<format> - an L<SDL2::PixelFormat> structure describing the pixel format

=item C<r> - the red component of the pixel in the range 0-255

=item C<g> - the green component of the pixel in the range 0-255

=item C<b> - the blue component of the pixel in the range 0-255

=back

Returns a pixel value.

=head2 C<SDL_MapRGBA( ... )>

Map an RGBA quadruple to a pixel value for a given pixel format.

This function maps the RGBA color value to the specified pixel format and
returns the pixel value best approximating the given RGBA color value for the
given pixel format.

If the specified pixel format has no alpha component the alpha value will be
ignored (as it will be in formats with a palette).

If the format has a palette (8-bit) the index of the closest matching color in
the palette will be returned.

If the pixel format bpp (color depth) is less than 32-bpp then the unused upper
bits of the return value can safely be ignored (e.g., with a 16-bpp format the
return value can be assigned to a Uint16, and similarly a Uint8 for an 8-bpp
format).

Expected parameters include:

=over

=item C<format> - an L<SDL2::PixelFormat> structure describing the format of the pixel

=item C<r> - the red component of the pixel in the range 0-255

=item C<g> - the green component of the pixel in the range 0-255

=item C<b> - the blue component of the pixel in the range 0-255

=item C<a> - the alpha component of the pixel in the range 0-255

=back

Returns a pixel value.

=head2 C<SDL_GetRGB( ... )>

Get RGB values from a pixel in the specified format.

This function uses the entire 8-bit [0..255] range when converting color
components from pixel formats with less than 8-bits per RGB component (e.g., a
completely white pixel in 16-bit RGB565 format would return C<[0xff, 0xff,
0xff]> not C<[0xf8, 0xfc, 0xf8]>).

Expected parameters include:

=over

=item C<pixel> a pixel value

=item C<format> an L<SDL2::PixelFormat> structure describing the format of the pixel

=item C<r> - a pointer filled in with the red component

=item C<g> - a pointer filled in with the green component

=item C<b> - a pointer filled in with the blue component

=back

=head2 C<SDL_GetRGBA( ... )>

Get RGBA values from a pixel in the specified format.

This function uses the entire 8-bit [0..255] range when converting color
components from pixel formats with less than 8-bits per RGB component (e.g., a
completely white pixel in 16-bit RGB565 format would return C<[0xff, 0xff,
0xff]> not C<[0xf8, 0xfc, 0xf8]>).

If the surface has no alpha component, the alpha will be returned as 0xff (100%
opaque).

Expected parameters include:

=over

=item C<pixel> - a pixel value

=item C<format> - an L<SDL2::PixelFormat> structure describing the format of the pixel

=item C<r> - a pointer filled in with the red component

=item C<g> - a pointer filled in with the green component

=item C<b> - a pointer filled in with the blue component

=item C<a> - a pointer filled in with the alpha component

=back

=head2 C<SDL_CalculateGammaRamp( ... )>

Calculate a 256 entry gamma ramp for a gamma value.

    my @ramp = (0) x 256; # preallocate to avoid spurious warnings
    SDL_CalculateGammaRamp( .925, \@ramp ); # \@ramp will be filled

Expected parameters include:

=over

=item C<gamma> - a gamma value where C<0.0> is black and C<1.0> is identity

=item C<ramp> - an array of 256 values filled in with the gamma ramp

=back

=head2 Transparency definitions

These define alpha as the opacity of a surface.

=over

=item C<SDL_ALPHA_OPAQUE>

=item C<SDL_ALPHA_TRANSPARENT>

=back

=head1 SDL_PixelType

These may be imported with the tag C<:pixelType>

=over

=item C<SDL_PIXELTYPE_UNKNOWN>

=item C<SDL_PIXELTYPE_INDEX1>

=item C<SDL_PIXELTYPE_INDEX4>

=item C<SDL_PIXELTYPE_INDEX8>

=item C<SDL_PIXELTYPE_PACKED8>

=item C<SDL_PIXELTYPE_PACKED16>

=item C<SDL_PIXELTYPE_PACKED32>

=item C<SDL_PIXELTYPE_ARRAYU8>

=item C<SDL_PIXELTYPE_ARRAYU16>

=item C<SDL_PIXELTYPE_ARRAYU32>

=item C<SDL_PIXELTYPE_ARRAYF16>

=item C<SDL_PIXELTYPE_ARRAYF32>

=back

=head1 SDL_BitmapOrder

Bitmap pixel order, high bit -> low bit. These maybe imported with the
C<:bitmapOrder> tag.

=over

=item C<SDL_BITMAPORDER_NONE>

=item C<SDL_BITMAPORDER_4321>

=item C<SDL_BITMAPORDER_1234>

=back

=head1 SDL_PackedOrder

Packed component order, high bit -> low bit. These may be imported with the
C<:packedOrder> tag.

=over

=item C<SDL_PACKEDORDER_NONE>

=item C<SDL_PACKEDORDER_XRGB>

=item C<SDL_PACKEDORDER_RGBX>

=item C<SDL_PACKEDORDER_ARGB>

=item C<SDL_PACKEDORDER_RGBA>

=item C<SDL_PACKEDORDER_XBGR>

=item C<SDL_PACKEDORDER_BGRX>

=item C<SDL_PACKEDORDER_ABGR>

=item C<SDL_PACKEDORDER_BGRA>

=back

=head1 SDL_ArrayOrder

Array component order, low byte -> high byte. These may be imported with the
C<:arrayOrder> tag.

=over

=item C<SDL_ARRAYORDER_NONE>

=item C<SDL_ARRAYORDER_RGB>

=item C<SDL_ARRAYORDER_RGBA>

=item C<SDL_ARRAYORDER_ARGB>

=item C<SDL_ARRAYORDER_BGR>

=item C<SDL_ARRAYORDER_BGRA>

=item C<SDL_ARRAYORDER_ABGR>

=back

=head1 SDL_PackedLayout

Packed component layout. These values may be imported with the C<:packedLayout>
tag.

=over

=item C<SDL_PACKEDLAYOUT_NONE>

=item C<SDL_PACKEDLAYOUT_332>

=item C<SDL_PACKEDLAYOUT_4444>

=item C<SDL_PACKEDLAYOUT_1555>

=item C<SDL_PACKEDLAYOUT_5551>

=item C<SDL_PACKEDLAYOUT_565>

=item C<SDL_PACKEDLAYOUT_8888>

=item C<SDL_PACKEDLAYOUT_2101010>

=item C<SDL_PACKEDLAYOUT_1010102>

=back

=head1 C<:pixels>

These utility functions may be imported with the C<:pixels> tag.

=over

=item C<SDL_DEFINE_PIXELFOURCC( ... )>

=item C<SDL_DEFINE_PIXELFORMAT( ... )>

=item C<SDL_PIXELFLAG( ... )>

=item C<SDL_PIXELTYPE( ... )>

=item C<SDL_PIXELORDER( ... )>

=item C<SDL_PIXELLAYOUT( ... )>

=item C<SDL_BITSPERPIXEL( ... )>

=item C<SDL_BYTESPERPIXEL( ... )>

=item C<SDL_ISPIXELFORMAT_INDEXED( ... )>

=item C<SDL_ISPIXELFORMAT_PACKED( ... )>

=item C<SDL_ISPIXELFORMAT_ARRAY( ... )>

=item C<SDL_ISPIXELFORMAT_ALPHA( ... )>

=item C<SDL_ISPIXELFORMAT_FOURCC( ... )>

=back

=head1 SDL_PixelFormatEnum

These values may be imported with the C<:pixelFormatEnum> tag.

=over

=item C<SDL_PIXELFORMAT_UNKNOWN>

=item C<SDL_PIXELFORMAT_INDEX1LSB>

=item C<SDL_PIXELFORMAT_INDEX1MSB>

=item C<SDL_PIXELFORMAT_INDEX4LSB>

=item C<SDL_PIXELFORMAT_INDEX4MSB>

=item C<SDL_PIXELFORMAT_INDEX8>

=item C<SDL_PIXELFORMAT_RGB332>

=item C<SDL_PIXELFORMAT_XRGB4444>

=item C<SDL_PIXELFORMAT_RGB444>

=item C<SDL_PIXELFORMAT_XBGR4444>

=item C<SDL_PIXELFORMAT_BGR444>

=item C<SDL_PIXELFORMAT_XRGB1555>

=item C<SDL_PIXELFORMAT_RGB555>

=item C<SDL_PIXELFORMAT_XBGR1555>

=item C<SDL_PIXELFORMAT_BGR555>

=item C<SDL_PIXELFORMAT_ARGB4444>

=item C<SDL_PIXELFORMAT_RGBA4444>

=item C<SDL_PIXELFORMAT_ABGR4444>

=item C<SDL_PIXELFORMAT_BGRA4444>

=item C<SDL_PIXELFORMAT_ARGB1555>

=item C<SDL_PIXELFORMAT_RGBA5551>

=item C<SDL_PIXELFORMAT_ABGR1555>

=item C<SDL_PIXELFORMAT_BGRA5551>

=item C<SDL_PIXELFORMAT_RGB565>

=item C<SDL_PIXELFORMAT_BGR565>

=item C<SDL_PIXELFORMAT_RGB24>

=item C<SDL_PIXELFORMAT_BGR24>

=item C<SDL_PIXELFORMAT_XRGB8888>

=item C<SDL_PIXELFORMAT_RGB888>

=item C<SDL_PIXELFORMAT_RGBX8888>

=item C<SDL_PIXELFORMAT_XBGR8888>

=item C<SDL_PIXELFORMAT_BGR888>

=item C<SDL_PIXELFORMAT_BGRX8888>

=item C<SDL_PIXELFORMAT_ARGB8888>

=item C<SDL_PIXELFORMAT_RGBA8888>

=item C<SDL_PIXELFORMAT_ABGR8888>

=item C<SDL_PIXELFORMAT_BGRA8888>

=item C<SDL_PIXELFORMAT_ARGB2101010>

=item C<SDL_PIXELFORMAT_RGBA32>

=item C<SDL_PIXELFORMAT_ARGB32>

=item C<SDL_PIXELFORMAT_BGRA32>

=item C<SDL_PIXELFORMAT_ABGR32>

=item C<SDL_PIXELFORMAT_YV12> - Planar mode: Y + V + U  (3 planes)

=item C<SDL_PIXELFORMAT_IYUV> - Planar mode: Y + U + V  (3 planes)

=item C<SDL_PIXELFORMAT_YUY2> - Packed mode: Y0+U0+Y1+V0 (1 plane)

=item C<SDL_PIXELFORMAT_UYVY> - Packed mode: U0+Y0+V0+Y1 (1 plane)

=item C<SDL_PIXELFORMAT_YVYU> - Packed mode: Y0+V0+Y1+U0 (1 plane)

=item C<SDL_PIXELFORMAT_NV12> - Planar mode: Y + U/V interleaved  (2 planes)

=item C<SDL_PIXELFORMAT_NV21> - Planar mode: Y + V/U interleaved  (2 planes)

=item C<SDL_PIXELFORMAT_EXTERNAL_OES> - Android video texture format

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

bpp 8-bpp 16-bpp 32-bpp 0xff

=end stopwords

=cut

};
1;
