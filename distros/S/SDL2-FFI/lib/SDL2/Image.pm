package SDL2::Image 0.01 {
    use strict;
    use SDL2::Utils;
    use experimental 'signatures';
    use base 'Exporter::Tiny';
    use SDL2::Utils qw[attach define enum load_lib];
    use SDL2::FFI;
    use SDL2::version;
    #
    our %EXPORT_TAGS;
    #
    sub _ver() {
        CORE::state $version //= IMG_Linked_Version();
        $version;
    }
    #
    load_lib('SDL2_image');
    #
    define image => [
        [ SDL_IMAGE_MAJOR_VERSION => sub () { SDL2::Image::_ver()->major } ],
        [ SDL_IMAGE_MINOR_VERSION => sub () { SDL2::Image::_ver()->minor } ],
        [ SDL_IMAGE_PATCHLEVEL    => sub () { SDL2::Image::_ver()->patch } ],
        [   SDL_IMAGE_VERSION => sub ($version) {
                my $ver = IMG_Linked_Version();
                $version->major( $ver->major );
                $version->minor( $ver->minor );
                $version->patch( $ver->patch );
            }
        ],
        [   SDL_IMAGE_COMPILEDVERSION => sub () {
                SDL2::FFI::SDL_VERSIONNUM( SDL_IMAGE_MAJOR_VERSION(), SDL_IMAGE_MINOR_VERSION(),
                    SDL_IMAGE_PATCHLEVEL() );
            }
        ],
        [   SDL_IMAGE_VERSION_ATLEAST => sub ( $X, $Y, $Z ) {
                ( SDL_IMAGE_COMPILEDVERSION() >= SDL2::FFI::SDL_VERSIONNUM( $X, $Y, $Z ) )
            }
        ]
    ];
    attach image       => { IMG_Linked_Version => [ [], 'SDL_Version' ] };
    enum IMG_InitFlags => [
        [ IMG_INIT_JPG  => 0x00000001 ],
        [ IMG_INIT_PNG  => 0x00000002 ],
        [ IMG_INIT_TIF  => 0x00000004 ],
        [ IMG_INIT_WEBP => 0x00000008 ]
    ];
    attach image => {
        IMG_Init => [ ['int'] => 'int' ],
        IMG_Quit => [ [] ],
        #
        IMG_LoadTyped_RW => [ [ 'SDL_RWops', 'int', 'string' ], 'SDL_Surface' ],
        IMG_Load         => [ ['string'],                       'SDL_Surface' ],
        IMG_Load_RW      => [ [ 'SDL_RWops', 'int' ],           'SDL_Surface' ],
        #
        IMG_LoadTexture         => [ [ 'SDL_Renderer', 'string' ], 'SDL_Texture' ],
        IMG_LoadTexture_RW      => [ [ 'SDL_Renderer', 'SDL_RWops', 'int' ], 'SDL_Texture' ],
        IMG_LoadTextureTyped_RW =>
            [ [ 'SDL_Renderer', 'SDL_RWops', 'int', 'string' ], 'SDL_Texture' ],

        # Functions to detect a file type, given a seekable source
        IMG_isICO  => [ ['SDL_RWops'], 'int' ],
        IMG_isCUR  => [ ['SDL_RWops'], 'int' ],
        IMG_isBMP  => [ ['SDL_RWops'], 'int' ],
        IMG_isGIF  => [ ['SDL_RWops'], 'int' ],
        IMG_isJPG  => [ ['SDL_RWops'], 'int' ],
        IMG_isLBM  => [ ['SDL_RWops'], 'int' ],
        IMG_isPCX  => [ ['SDL_RWops'], 'int' ],
        IMG_isPNG  => [ ['SDL_RWops'], 'int' ],
        IMG_isPNM  => [ ['SDL_RWops'], 'int' ],
        IMG_isSVG  => [ ['SDL_RWops'], 'int' ],
        IMG_isTIF  => [ ['SDL_RWops'], 'int' ],
        IMG_isXCF  => [ ['SDL_RWops'], 'int' ],
        IMG_isXPM  => [ ['SDL_RWops'], 'int' ],
        IMG_isXV   => [ ['SDL_RWops'], 'int' ],
        IMG_isWEBP => [ ['SDL_RWops'], 'int' ],

        # Individual loading functions
        IMG_LoadICO_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadCUR_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadBMP_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadGIF_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadJPG_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadLBM_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadPCX_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadPNG_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadPNM_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadSVG_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadTGA_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadTIF_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadXCF_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadXPM_RW  => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadXV_RW   => [ ['SDL_RWops'], 'SDL_Surface' ],
        IMG_LoadWEBP_RW => [ ['SDL_RWops'], 'SDL_Surface' ],
        #
        IMG_ReadXPMFromArray => [
            ['string_array'],
            'SDL_Surface' => sub ( $inner, @lines ) {
                $inner->( ref $lines[0] eq 'ARRAY' ? @lines : \@lines );
            }
        ],

        # Individual saving functions
        IMG_SavePNG    => [ [ 'SDL_Surface', 'string' ],                  'int' ],
        IMG_SavePNG_RW => [ [ 'SDL_Surface', 'SDL_RWops', 'int' ],        'int' ],
        IMG_SaveJPG    => [ [ 'SDL_Surface', 'string', 'int' ],           'int' ],
        IMG_SaveJPG_RW => [ [ 'SDL_Surface', 'SDL_RWops', 'int', 'int' ], 'int' ]
    };
    if ( SDL_IMAGE_VERSION_ATLEAST( 2, 0, 6 ) ) {

        # Currently on Github but not in a stable dist
        # https://github.com/libsdl-org/SDL_image/issues/182
        package SDL2::Image::Animation {
            use strict;
            use SDL2::Utils;
            use experimental 'signatures';
            #
            our $TYPE = has
                w       => 'int',
                h       => 'int',
                count   => 'int',
                _frames => 'opaque',    # SDL_Surface **
                _delays => 'opaque'     # int *
                ;

            sub frames ($s) {
                [ map { ffi->cast( 'opaque', 'SDL_Surface', $_ ) }
                        @{ ffi->cast( 'opaque', 'opaque[' . $s->count . ']', $s->_frames ) } ];
            }

            sub delays ($s) {
                ffi->cast( 'opaque', 'int[' . $s->count . ']', $s->_delays );
            }
        };
        attach image => {
            IMG_LoadAnimation         => [ ['string'],             'SDL_Image_Animation' ],
            IMG_LoadAnimation_RW      => [ [ 'SDL_RWops', 'int' ], 'SDL_Image_Animation' ],
            IMG_LoadAnimationTyped_RW =>
                [ [ 'SDL_RWops', 'int', 'string' ], 'SDL_Image_Animation' ],
            IMG_FreeAnimation       => [ ['SDL_Image_Animation'] ],
            IMG_LoadGIFAnimation_RW => [ ['SDL_RWops'], 'SDL_Image_Animation' ]
        };
    }
    define image => [
        [ IMG_SetError => sub (@args) { SDL2::FFI::SDL_SetError(@args) } ],
        [ IMG_GetError => sub (@args) { SDL2::FFI::SDL_GetError(@args) } ],
    ];

    # Export symbols!
    our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;

    #$EXPORT_TAGS{default} = [];             # Export nothing by default
    $EXPORT_TAGS{all} = \@EXPORT_OK;    # Export everything with :all tag

=encoding utf-8

=head1 NAME

SDL2::Image - SDL Image Loading Library

=head1 SYNOPSIS

    use SDL2::Image;

=head1 DESCRIPTION

This extension to SDL2 can load images as SDL surfaces and textures. The
following formats are supported:

=over

=item C<TGA> - TrueVision Targa (MUST have C<.tga>)

=item C<BMP> - Windows Bitmap (C<.bmp>)

=item C<PNM> - Portable Anymap (C<.pnm>)

=over

=item C<.pbm> - Portable BitMap (mono)

=item C<.pgm> - Portable GreyMap (256 greys)

=item C<.ppm> - Portable PixMap (full color)

=back

=item C<XPM>

X11 Pixmap (C<.xpm>) can be #included directly in code

This is NOT the same as XBM (X11 Bitmap) format, which is for monocolor images.

=item C<XCF>

GIMP native (.xcf) (XCF = eXperimental Computing Facility?) This format is
always changing, and since there's no library supplied by the GIMP project to
load XCF, the loader may frequently fail to load much of any image from an XCF
file. It's better to load this in GIMP and convert to a better supported image
format.

=item C<PCX> - ZSoft IBM PC Paintbrush (C<.pcx>)

=item C<GIF> - CompuServe Graphics Interchange Format (C<.gif>)

=item C<JPG> - Joint Photographic Experts Group JFIF format (C<.jpg> or C<.jpeg>)

=item C<TIF> - Tagged Image File Format (C<.tif> or C<.tiff>)

=item C<LBM> - Interleaved Bitmap (C<.lbm> or C<.iff>) FORM : ILBM or PBM(packed bitmap)

HAM6, HAM8, and 24bit types are not supported.

=item C<PNG> - Portable Network Graphics (C<.png>)

=back

=head1 Functions

These may be imported by name or with the C<:all> tag.

=head2 C<SDL_IMAGE_VERSION( ... )>

Macro to determine compile-time version of the C<SDL_image> library.

Expected parameters include:

=over

=item C<x> - a pointer to a L<SDL2::Version> struct to initialize

=back

=head2 C<SDL_IMAGE_VERSION_ATLEAST( ... )>

Evaluates to true if compiled with SDL at least C<major.minor.patch>.

	if ( SDL_IMAGE_VERSION_ATLEAST( 2, 0, 5 ) ) {
		# Some feature that requires 2.0.5+
	}

Expected parameters include:

=over

=item C<major>

=item C<minor>

=item C<patch>

=back

=head2 C<IMG_Linked_Version( )>

This function gets the version of the dynamically linked C<SDL_image> library.

    my $link_version = IMG_Linked_Version();
    printf "running with SDL_image version: %d.%d.%d\n",
        $link_version->major, $link_version->minor, $link_version->patch;

It should NOT be used to fill a version structure, instead you should use the
L<< C<SDL_IMAGE_VERSION( ... )>|/C<SDL_IMAGE_VERSION( ... )> >> macro.

Returns a L<SDL2::Version> object.

=head2 C<IMG_Init( ... )>

Loads dynamic libraries and prepares them for use.

    if ( !( IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG ) ) {
        printf( "could not initialize SDL_image: %s\n", IMG_GetError() );
        return !1;
    }

You may call this multiple times, which will actually require you to call
C<IMG_Quit( )> just once to clean up. You may call this function with a
C<flags> of C<0> to retrieve whether support was built-in or not loaded yet.

Expected parameters include:

=over

=item C<flags>

Flags should be one or more flags from L<< C<IMG_InitFlags>|/C<IMG_InitFlags>
>> OR'd together.

=over

=item C<IMG_INIT_JPG>

=item C<IMG_INIT_PNG>

=item C<IMG_INIT_TIF>

=back

=back

Returns the flags successfully initialized, or C<0> on failure.

=head2 C<IMG_Quit( )>

Unloads libraries loaded with L<< C<IMG_Init( ... )>|/C<IMG_Init( ... )> >>.

=head2 C<IMG_LoadTyped_RW( ... )>

Load an image from an SDL data source.

    # load sample.tga into image
    my $image = IMG_LoadTyped_RW( SDL_RWFromFile( 'sample.tga', 'rb' ), 1, 'TGA' );
    if ( !$image ) {
        printf( "IMG_LoadTyped_RW: %s\n", IMG_GetError() );

        # handle error
    }

If the image format supports a transparent pixel, SDL will set the colorkey for
the surface.  You can enable RLE acceleration on the surface afterwards by
calling:

    SDL_SetColorKey( $image, SDL_RLEACCEL, $image->format->colorkey );

Expected parameters include:

=over

=item C<src> - The source L<SDL2::RWops> the image is to be loaded from

=item C<freesrc> - C<SDL_image> will close and free C<src> for you if this is a non-zero value

=item C<type> - a string that indicates which format type to interpret the image as

The list of the currently recognized strings includes (case is not important):

=over

=item C<BMP>

=item C<CUR>

=item C<GIF>

=item C<ICO>

=item C<JPG>

=item C<LBM>

=item C<PCX>

=item C<PNG>

=item C<PNM>

=item C<TGA>

=item C<TIF>

=item C<XCF>

=item C<XPM>

=item C<XV>

=back

=back

Returns a new L<SDL2::Surface> on success.

=head2 C<IMG_Load( ... )>

Loads a file for use as an image in a new surface.

    # load sample.png into image
    my $image = IMG_Load("sample.png");
    if ( !defined $image ) {
        printf( "IMG_Load: %s\n", IMG_GetError() );

        # handle error
    }

This actually calls L<< C<IMG_LoadTyped_RW( ... )>|/C<IMG_LoadTyped_RW( ... )>
>>, with the file extension used as the type string. This can load all
supported image files, including TGA as long as the filename ends with C<.tga>.
It is best to call this outside of event loops, and rather keep the loaded
images around until you are really done with them, as disk speed and image
conversion to a surface is not that speedy. Don't forget to C<SDL_FreeSurface(
... )> the returned surface pointer when you are through with it.

Expected parameters include:

=over

=item C<file> - image file name to load a surface from

=back

Returns a new L<SDL2::Surface> on success.

=head2 C<IMG_Load_RW( ... )>

Load an image C<src> for use as a surface.

    # load sample.png in to image
    my $image = IMG_Load_RW( SDL_RWFromFile( "sample.png", "rb" ), 1 );
    if ( !$image ) {
        printf( "IMG_Load_RW: %s\n", IMG_GetError() );

        # handle error
    }

This can load all supported image formats, B<except TGA>.

Expected parameters include:

=over

=item C<src> - The source L<SDL2::RWops> the image is to be loaded from

=item C<freesrc> - C<SDL_image> will close and free C<src> for you if this is a non-zero value

=back

Returns a new L<SDL2::Surface> on success.

=head2 C<IMG_LoadTexture( ... )>

Load an image C<file> for use as a texture.

    # load sample.png in to texture
    my $texture = IMG_LoadTexture( $renderer, "sample.png" );
    if ( !$texture ) {
        printf( "IMG_LoadTexture: %s\n", IMG_GetError() );

        # handle error
    }

Expected parameters include:

=over

=item C<renderer> - an existing L<SDL2::Renderer> object

=item C<file> - the source filename of the image is to be loaded

=back

Returns a L<SDL2::Texture> object on success.

=head2 C<IMG_LoadTexture_RW( ... )>

Load an image C<src> for use as a texture.

    # load sample.png in to texture
    my $texture = IMG_LoadTexture_RW( $renderer, SDL_RWFromFile( "sample.png", "rb" ), 1 );
    if ( !$texture ) {
        printf( "IMG_LoadTexture: %s\n", IMG_GetError() );

        # handle error
    }

Expected parameters include:

=over

=item C<renderer> - an existing L<SDL2::Renderer> object

=item C<src> - the source L<SDL2::RWops> the image is to be loaded from

=item C<freesrc> - C<SDL_image> will close and free C<src> for you if this is a non-zero value

=back

Returns a L<SDL2::Texture> object on success.

=head2 C<IMG_LoadTextureTyped_RW( ... )>

Load an image C<src> for use as a texture.

    # load sample.png in to texture
    my $texture
        = IMG_LoadTextureTyped_RW( $renderer, SDL_RWFromFile( 'sample.png', 'rb' ), 1, 'PNG' );
    if ( !$texture ) {
        printf( "IMG_LoadTexture: %s\n", IMG_GetError() );

        # handle error
    }

Expected parameters include:

=over

=item C<renderer> - an existing L<SDL2::Renderer> object

=item C<src> - the source L<SDL2::RWops> the image is to be loaded from

=item C<freesrc> - C<SDL_image> will close and free C<src> for you if this is a non-zero value

=item C<type> - a string that indicates which format type to interpret the image as

=back

Returns a L<SDL2::Texture> object on success.

=head2 C<IMG_isICO( ... )>

If the BMP format is supported, then the image data is tested to see if it is
readable as an ICO, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is an ICO and the BMP format support is compiled into
C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isCUR( ... )>

If the BMP format is supported, then the image data is tested to see if it is
readable as a CUR, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a CUR and the BMP format support is compiled into
C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isBMP( ... )>

If the BMP format is supported, then the image data is tested to see if it is
readable as a BMP, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a BMP and the BMP format support is compiled into
C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isGIF( ... )>

If the GIF format is supported, then the image data is tested to see if it is
readable as a GIF, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a GIF and the GIF format support is compiled into
C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isJPG( ... )>

If the JPG format is supported, then the image data is tested to see if it is
readable as a JPG, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a JPG and the JPG format support is compiled into
C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isLBM( ... )>

If the LBM format is supported, then the image data is tested to see if it is
readable as a LBM, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a LBM and the LBM format support is compiled into
C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isPCX( ... )>

If the PCX format is supported, then the image data is tested to see if it is
readable as a PCX, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a PCX and the PCX format support is compiled into
C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isPNG( ... )>

If the PNG format is supported, then the image data is tested to see if it is
readable as a PNG, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a PNG and the PNG format support is compiled into
C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isPNM( ... )>

If the PNM format is supported, then the image data is tested to see if it is
readable as a PNM, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a PNM and the PNM format support is compiled into
C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isSVG( ... )>

If the SVG format is supported, then the image data is tested to see if it is
readable as a SVG, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a SVG and the SVG format support is compiled into
C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isTIF( ... )>

If the TIF format is supported, then the image data is tested to see if it is
readable as a TIF, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a TIF and the TIF format support is compiled into
C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isXCF( ... )>

If the XCF format is supported, then the image data is tested to see if it is
readable as a XCF, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a XCF and the XCF format support is compiled into
C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isXPM( ... )>

If the XPM format is supported, then the image data is tested to see if it is
readable as a XPM, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a XPM and the XPM format support is compiled into
C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isXV( ... )>

If the XV format is supported, then the image data is tested to see if it is
readable as a XV thumbnail, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a XV thumbnail and the XV format support is
compiled into C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_isWEBP( ... )>

If the WebP format is supported, then the image data is tested to see if it is
readable as a WebP, otherwise it returns false (zero).

Expected parameters include:

=over

=item C<src> - the source C<SDL2::RWops> the image is to be loaded from

=back

Returns C<1> if the image is a WebP and the WebP image format support is
compiled into C<SDL_image>. C<0> is returned otherwise.

=head2 C<IMG_LoadICO_RW( ... )>

Load C<src> as a ICO image for use as a surface, if ICO support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadCUR_RW( ... )>

Load C<src> as a CUR image for use as a surface, if CUR support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadBMP_RW( ... )>

Load C<src> as a BMP image for use as a surface, if BMP support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadGIF_RW( ... )>

Load C<src> as a GIF image for use as a surface, if GIF support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadJPG_RW( ... )>

Load C<src> as a JPG image for use as a surface, if JPG support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadLBM_RW( ... )>

Load C<src> as a LBM image for use as a surface, if LBM support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadPCX_RW( ... )>

Load C<src> as a PCX image for use as a surface, if PCX support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadPNG_RW( ... )>

Load C<src> as a PNG image for use as a surface, if PNG support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadPNM_RW( ... )>

Load C<src> as a PNM image for use as a surface, if PNM support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadSVG_RW( ... )>

Load C<src> as a SVG image for use as a surface, if SVG support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadTGA_RW( ... )>

Load C<src> as a TGA image for use as a surface, if TGA support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadTIF_RW( ... )>

Load C<src> as a TIF image for use as a surface, if TIF support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadXCF_RW( ... )>

Load C<src> as a XCF image for use as a surface, if XCF support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadXPM_RW( ... )>

Load C<src> as a XPM image for use as a surface, if XPM support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadXV_RW( ... )>

Load C<src> as a XV image for use as a surface, if XV support is compiled into
the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_LoadWEBP_RW( ... )>

Load C<src> as a WEBP image for use as a surface, if WEBP support is compiled
into the C<SDL_image> library.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> object

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_ReadXPMFromArray( ... )>

Load C<xpm> as a XPM image for use as a surface, if XPM support is compiled
into the C<SDL_image> library.

	my $image = IMG_ReadXPMFromArray( @sample_xpm );
	if( !$image ) {
		printf "IMG_ReadXPMFromArray: %s\n", IMG_GetError();
		# handle error
	}

XPM files may be embedded in source code. See C<eg/xpm.pl> for an example.

Expected parameters include:

=over

=item <xpm> - the source xpm data

The XPM image is loaded from this list of strings.

=back

Returns a new L<SDL2::Surface> structure on success.

=head2 C<IMG_SavePNG( ... )>

Saves the contents of an L<SDL2::Surface> to a PNG file.

This should work regardless of whether PNG support was successfully initialized
with C<IMG_Init( ... )>, but the full set of PNG features may not be available.

Expected parameters include:

=over

=item C<surface> - an L<SDL2::Surface> object containing the image to be saved

=item <file> - UTF-8 encoded string containing the path to save the PNG to

=back

Returns C<0> on success or a negative error code on failure.

=head2 C<IMG_SavePNG_RW( ... )>

Sends the contents of an L<SDL2::Surface> to a L<SDL2::RWops> as a PNG file.

This should work regardless of whether PNG support was successfully initialized
with C<IMG_Init( ... )>, but the full set of PNG features may not be available.

Expected parameters include:

=over

=item C<surface> - an L<SDL2::Surface> object containing the image to be saved

=item <dst> - a C<SDL2::RWops> object to save the PNG to

=item C<freedst> - if non-zero, the destination file object will be closed once the PNG has been written

=back

Returns C<0> on success or a negative error code on failure.

=head2 C<IMG_SaveJPG( ... )>

Saves the contents of an L<SDL2::Surface> to a JPEG file.

JPEG support must be already initialized using C<IMG_Init( ... )> before this
function can be used, otherwise this function will fail without an explicit
error that can be retrieved with C<IMG_GetError( )>.

Expected parameters include:

=over

=item C<surface> - an L<SDL2::Surface> object containing the image to be saved

=item <file> - UTF-8 encoded string containing the path to save the JPEG to

=item C<quality> - the quality at which to compress the JPEG, from C<0> to C<100> inclusive

=back

Returns C<0> on success or a negative error code on failure.

=head2 C<IMG_SaveJPG_RW( ... )>

Sends the contents of an L<SDL2::Surface> to a L<SDL2::RWops> as a JPEG file.

JPEG support must be already initialized using C<IMG_Init( ... )> before this
function can be used, otherwise this function will fail without an explicit
error that can be retrieved with C<IMG_GetError( )>.

Expected parameters include:

=over

=item C<surface> - an L<SDL2::Surface> object containing the image to be saved

=item <dst> - a C<SDL2::RWops> object to save the JPEG to

=item C<freedst> - if non-zero, the destination file object will be closed once the JPEG has been written

=item C<quality> - the quality at which to compress the JPEG, from C<0> to C<100> inclusive

=back

Returns C<0> on success or a negative error code on failure.

=head2 C<IMG_LoadAnimation( ... )>

Load an animated image from an existing file.

Note that this function is only defined on C<SDL_image> 2.0.6+.

Expected parameters include:

=over

=item C<file> - image file name to load an animated image from

=back

Returns a new L<SDL2::Image::Animation> object on success.

=head2 C<IMG_LoadAnimation_RW( ... )>

Load an animated image from an SDL data source.

Note that this function is only defined on C<SDL_image> 2.0.6+.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> the animated GIF is to be loaded from

=item C<freesrc> - C<SDL_image> will close and free C<src> for you if this is a non-zero value

=back

Returns a new L<SDL2::Image::Animation> object on success.

=head2 C<IMG_LoadAnimationTyped_RW( ... )>

Load an animated image from an SDL data source.

Note that this function is only defined on C<SDL_image> 2.0.6+.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> the animated GIF is to be loaded from

=item C<freesrc> - C<SDL_image> will close and free C<src> for you if this is a non-zero value

=item C<type> - a string that indicates which format type to interpret the image as

Currently, the following types are understood:

=over

=item C<GIF>

=back

=back

Returns a new L<SDL2::Image::Animation> object on success.

=head2 C<IMG_FreeAnimation( ... )>

Frees an initialized L<SDL2::Image::Animation> structure from memory.

Note that this function is only defined on C<SDL_image> 2.0.6+.

Expected parameters include:

=over

=item C<anim> - the L<SDL2::Image::Animation> to release from memory

=back

=head2 C<IMG_LoadGIFAnimation_RW( ... )>

Loads an animated GIF image from an L<SDL2::RWops> object.

Note that this function is only defined on C<SDL_image> 2.0.6+.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> the animated GIF is to be loaded from

=back

Returns a L<SDL2::Image::Animation> on success.

=head2 C<IMG_SetError( ... )>

Wrapper around C<SDL_SetError( ... )>.

=head2 C<IMG_GetError( )>

Wrapper around C<SDL_GetError( )>.

=head1 Defined values and Enumerations

These might actually be useful and may be imported with the listed tags.

=head2 Version information

=over

=item C<SDL_IMAGE_MAJOR_VERSION>

=item C<SDL_IMAGE_MINOR_VERSION>

=item C<SDL_IMAGE_PATCHLEVEL>

=item C<SDL_IMAGE_COMPILEDVERSION> - Version number for the current C<SDL_image> version

=back

=head2 C<IMG_InitFlags>

=over

=item C<IMG_INIT_JPG>

=item C<IMG_INIT_PNG>

=item C<IMG_INIT_TIF>

=item C<IMG_INIT_WEBP>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

monocolor eXperimental WebP bitmap ZSoft .xcf dst xpm (.xcf)

=end stopwords

=cut

};
1;
