package SDL2::Mixer 0.01 {
    use strict;
    use SDL2::Utils;
    use experimental 'signatures';
    use base 'Exporter::Tiny';
    use SDL2::Utils qw[attach define enum load_lib];
    use SDL2::FFI qw[SDL_RWFromFile];
    use SDL2::stdinc;
    use SDL2::rwops;
    use SDL2::audio;
    use SDL2::endian;
    use SDL2::version;
    #
    our %EXPORT_TAGS;
    #
    #
    sub _ver() {
        CORE::state $version //= Mix_Linked_Version();
        $version;
    }
    #
    #load_lib('SDL2_mixer');
    load_lib('api_wrapper');
    #
    define version => [
        [ SDL_MIXER_MAJOR_VERSION => sub () { SDL2::Mixer::_ver()->major } ],
        [ SDL_MIXER_MINOR_VERSION => sub () { SDL2::Mixer::_ver()->minor } ],
        [ SDL_MIXER_PATCHLEVEL    => sub () { SDL2::Mixer::_ver()->patch } ],
        [   SDL_MIXER_VERSION => sub ($version) {
                my $ver = Mix_Linked_Version();
                $version->major( $ver->major );
                $version->minor( $ver->minor );
                $version->patch( $ver->patch );
            }
        ],
        [   SDL_MIXER_COMPILEDVERSION => sub () {
                SDL2::FFI::SDL_VERSIONNUM( SDL_MIXER_MAJOR_VERSION(), SDL_MIXER_MINOR_VERSION(),
                    SDL_MIXER_PATCHLEVEL() );
            }
        ],
        [   SDL_MIXER_VERSION_ATLEAST => sub ( $X, $Y, $Z ) {
                ( SDL_MIXER_COMPILEDVERSION() >= SDL2::FFI::SDL_VERSIONNUM( $X, $Y, $Z ) )
            }
        ]
    ];
    attach version => { Mix_Linked_Version => [ [], 'SDL_Version' ] };
    enum MIX_InitFlags => [
        [ MIX_INIT_FLAC => 0x00000001 ],
        [ MIX_INIT_MOD  => 0x00000002 ],
        [ MIX_INIT_MP3  => 0x00000008 ],
        [ MIX_INIT_OGG  => 0x00000010 ],
        [ MIX_INIT_MID  => 0x00000020 ],
        [ MIX_INIT_OPUS => 0x00000040 ]
    ];
    attach mixer => { Mix_Init => [ ['int'], 'int' ], Mix_Quit => [ [] ] };
    define default => [
        [ MIX_CHANNELS          => 8 ],
        [ MIX_DEFAULT_FREQUENCY => 44100 ],
        [   MIX_DEFAULT_FORMAT => SDL2::FFI::SDL_BYTEORDER() eq SDL2::FFI::SDL_LIL_ENDIAN() ?
                SDL2::FFI::AUDIO_S16MSB() :
                SDL2::FFI::AUDIO_S16LSB()
        ],
        [ MIX_DEFAULT_CHANNELS => 2 ],
        [ MIX_MAX_VOLUME       => 128 ]    # SDL_MIX_MAXVOLUME
    ];

    package SDL2::Mixer::Chunk {
        use strict;
        use warnings;
        use SDL2::Utils qw[has ffi];
        our $TYPE = has
            allocated => 'int',
            _abuf     => 'opaque',         # uint8*
            alen      => 'uint32',
            volume    => 'uint8';          # Per-sample volume, 0-128

        sub abuf ($s) {
            ffi->cast( 'opaque', 'uint8[' . $s->alen . ']', $s->_abuf );
        }
    };
    enum
        Mix_Fading    => [qw[MIX_NO_FADING MIX_FADING_OUT MIX_FADING_IN]],
        Mix_MusicType => [
        qw[
            MUS_NONE MUS_CMD MUS_WAV MUS_MOD
            MUS_MID MUS_OGG MUS_MP3 MUS_MP3_MAD_UNUSED
            MUS_FLAC MUS_MODPLUG_UNUSED MUS_OPUS]
        ];

    package SDL2::Mixer::Music {
        use warnings;
        use SDL2::Utils qw[has];
        our $TYPE = has(
            interface  => 'opaque',      # Mix_MusicInterface *
            context    => 'opaque',      # void *
            playing    => 'bool',        # SDL_bool
            fading     => 'opaque',      # Mix_Fading
            fade_step  => 'int',
            fade_steps => 'int',
            filename   => 'char[1024]'
        );

# TODO: https://github.com/libsdl-org/SDL_mixer/blob/8d3c364c7d4cbef2c8e004fad703d841d3272a1c/src/music.c#L61
    };
    attach audio => {
        Mix_OpenAudio        => [ [ 'int', 'uint16', 'int', 'int' ],                  'int' ],
        Mix_OpenAudioDevice  => [ [ 'int', 'uint16', 'int', 'int', 'string', 'int' ], 'int' ],
        Mix_AllocateChannels => [ ['int'],                                            'int' ],
        Mix_QuerySpec        => [ [ 'int*', 'int*', 'int*' ],                         'int' ],
        Mix_LoadWAV_RW       => [ [ 'SDL_RWops', 'int' ],                  'SDL_Mixer_Chunk' ],
        Mix_LoadMUS          => [ ['string'],                              'SDL_Mixer_Music' ],
        Mix_LoadMUS_RW       => [ [ 'SDL_RWops', 'int' ],                  'SDL_Mixer_Music' ],
        Mix_LoadMUSType_RW   => [ [ 'SDL_RWops', 'Mix_MusicType', 'int' ], 'SDL_Mixer_Music' ],
        Mix_QuickLoad_WAV    => [ ['string'],                              'SDL_Mixer_Chunk' ],
        Mix_QuickLoad_RAW    => [ [ 'string', 'uint32' ],                  'SDL_Mixer_Chunk' ],
        Mix_FreeChunk        => [ ['SDL_Mixer_Chunk'] ],
        Mix_FreeMusic        => [ ['SDL_Mixer_Music'] ],
        #
        Mix_GetNumChunkDecoders => [ [],      'int' ],
        Mix_GetChunkDecoder     => [ ['int'], 'string' ], (
            SDL_MIXER_VERSION_ATLEAST( 2, 0, 5 ) ?
                ( Mix_HasChunkDecoder => [ ['string'], 'bool' ] ) : ()
        ),
        Mix_GetNumMusicDecoders => [ [],      'int' ],
        Mix_GetMusicDecoder     => [ ['int'], 'string' ], (
            SDL_MIXER_VERSION_ATLEAST( 2, 0, 5 ) ?
                ( Mix_HasMusicDecoder => [ ['string'], 'bool' ] ) : ()
        ),
        #
        Mix_GetMusicType => [ ['SDL_Mixer_Music'], 'int' ],    #'Mix_MusicType'
        (
            SDL_MIXER_VERSION_ATLEAST( 2, 0, 5 ) ?

                # Introduced in 2019 but SDL_mixer hasn't had a stable release since 2017
                (
                Mix_GetMusicTitle        => [ ['SDL_Mixer_Music'], 'string' ],
                Mix_GetMusicTitleTag     => [ ['SDL_Mixer_Music'], 'string' ],
                Mix_GetMusicArtistTag    => [ ['SDL_Mixer_Music'], 'string' ],
                Mix_GetMusicAlbumTag     => [ ['SDL_Mixer_Music'], 'string' ],
                Mix_GetMusicCopyrightTag => [ ['SDL_Mixer_Music'], 'string' ],
                ) :
                ()
        )
    };
    #
    ffi->type( '(opaque,opaque,int)->void' => 'Mix_Func' );
    ffi->type( '()->void'                  => 'music_finished' );
    ffi->type( '(int)->void'               => 'channel_finished' );
    my ( $post_mix, $hook_music, $hook_music_finished, $hook_channel_finished );
    my $hook_music_data;
    attach audio => {
        Bundle_Mix_SetPostMix => [
            [ 'opaque', 'opaque' ] => sub ( $inner, $code, $params = () ) {
                $inner->( $code, \$params );
            }
        ],
        Bundle_Mix_HookMusic => [
            [ 'opaque', 'opaque' ] => sub ( $inner, $code, $params = () ) {
				$hook_music_data = $params;
                $inner->( $code, \$params );
            }
        ],
        Bundle_Mix_HookMusicFinished => [ [ 'opaque' ] ],
        Bundle_Mix_ChannelFinished   => [ [ 'opaque' ] ],
    };
    define audio => [
        [ MIX_CHANNEL_POST => -2 ],
        [ Mix_GetMusicHookData => sub () {$hook_music_data}
        ]    # Do not call lib version of this as we do not pass an SV*
    ];
    ffi->type( '(int,opaque,int,opaque)->void' => 'Mix_EffectFunc' );
    ffi->type( '(int,opaque)->void'            => 'Mix_EffectDone' );
    my %_effects;
    attach effects => {
        Bundle_Mix_RegisterEffect => [
            [ 'int', 'Mix_EffectFunc', 'Mix_EffectDone', 'opaque' ],
            'int',
            sub ( $inner, $chan, $f, $d, $arg = () ) {
                my $cb_f = ffi->closure(
                    sub {
                        my ( $_chan, $_stream, $_len, $args ) = @_;
                        use Data::Dump;
                        ddx \@_;
                        my ($stream) = ffi->cast( 'opaque', 'uint8[' . $_len . ']', $_stream );
                        $f->( $chan, \$stream, $_len, $arg );

                        #set_stream( $stream, $_len );
                    }
                );
                $cb_f->sticky;
                my $cb_d = ffi->closure(
                    sub {
                        warn;
                        my ($chan) = @_;
                        $d->( $chan, $arg );
                    }
                );
                $cb_d->sticky;
                my $id = $inner->( $chan, $cb_f, $cb_d, $arg );
                warn $id;

                #$_effects{$id} = [ $cb_f, $cb_d, $arg];
                $id;
            }
        ],
    };
    attach audio => {
        #
        Mix_PlayChannelTimed => [ [ 'int', 'SDL_Mixer_Chunk', 'int', 'int' ], 'int' ],
        Mix_PlayingMusic     => [ [],                                         'int' ],
        Mix_PlayMusic        => [ [ 'SDL_Mixer_Music', 'int' ],               'int' ],
        Mix_CloseAudio       => [ [] ],
        Mix_Playing          => [ [],      'int' ],
        Mix_HaltChannel      => [ ['int'], 'int' ],
    };
    define audio => [
        [   Mix_LoadWAV => sub ($file) {
                Mix_LoadWAV_RW( SDL_RWFromFile( $file, 'rb' ), 1 );
            }
        ],
        [   Mix_PlayChannel => sub ( $channel, $chunk, $loops ) {
                Mix_PlayChannelTimed( $channel, $chunk, $loops, -1 );
            }
        ]
    ];
    attach todo => {
        Mix_SetReverseStereo => [ [ 'int', 'int' ],             'int' ],
        Mix_SetPanning       => [ [ 'int', 'uint8', 'uint8', ], 'int' ],
        Mix_SetDistance      => [ [ 'int', 'uint8' ],           'int' ],
        Mix_SetPosition      => [ [ 'int', 'sint16', 'uint8' ], 'int' ],
        Mix_GetChunk         => [ ['int'],                      'SDL_Mixer_Chunk' ],
        Mix_VolumeMusic      => [ ['int'],                      'int' ],
        Mix_SetMusicCMD      => [ ['string'],                   'int' ],

        # Requires higher version of lib
        #Mix_GetMusicTitleTag => [['SDL_Mixer_Music'], 'string'],
        #Mix_GetMusicArtistTag => [['SDL_Mixer_Music'], 'string'],
        #Mix_GetMusicTitle => [['SDL_Mixer_Music'], 'string'],
        #Mix_GetMusicAlbumTag => [['SDL_Mixer_Music'], 'string'],
        #Mix_GetMusicCopyrightTag => [['SDL_Mixer_Music'], 'string'],
        #Mix_GetMusicLoopStartTime=>[['SDL_Mixer_Music'], 'double'],
        #Mix_GetMusicPosition => [['SDL_Mixer_Music'], 'double'],
        Mix_FadeInMusic      => [ [ 'SDL_Mixer_Music', 'int', 'int' ], 'int' ],
        Mix_SetMusicPosition => [ ['double'],                          'int' ],
        Mix_PauseMusic       => [ [] ],
        Mix_ResumeMusic      => [ [] ],
        Mix_HaltMusic        => [ [] ],
        Mix_VolumeMusic      => [ ['int'],                      'int' ],
        Mix_PausedMusic      => [ [],                           'int' ],
        Mix_Volume           => [ [ 'int', 'int' ],             'int' ],
        Mix_VolumeChunk      => [ [ 'SDL_Mixer_Chunk', 'int' ], 'int' ],
    };

=pod

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

=cut

    define image => [
        [ Mix_SetError => sub (@args) { SDL2::FFI::SDL_SetError(@args) } ],
        [ Mix_GetError => sub (@args) { SDL2::FFI::SDL_GetError(@args) } ],
    ];

    # Export symbols!
    our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;

    #$EXPORT_TAGS{default} = [];             # Export nothing by default
    $EXPORT_TAGS{all} = \@EXPORT_OK;    # Export everything with :all tag

=encoding utf-8

=head1 NAME

SDL2::Mixer - SDL Audio Library

=head1 SYNOPSIS

    use SDL2::Mixer;

=head1 DESCRIPTION

SDL2::Mixer wraps the C<SDL_mixer> library, a simple multi-channel audio mixer.

It supports 8 channels of 16 bit stereo audio, plus a single channel of music, mixed by the popular MikMod MOD, Timidity MIDI and SMPEG MP3 libraries.

=for :todo See the examples C<eg/playwave.pl> and C<eg/playmus.pl> for documentation on this mixer library.

The mixer can currently load Microsoft WAVE files and Creative Labs VOC files as audio samples, and can load MIDI files via Timidity and the following music formats via MikMod: .MOD .S3M .IT .XM. It can load Ogg Vorbis streams as music if built with the Ogg Vorbis libraries, and finally it can load MP3 music using the SMPEG library.

The process of mixing MIDI files to wave output is very CPU intensive, so if playing regular WAVE files sound great, but playing MIDI files sound choppy, try using 8-bit audio, mono audio, or lower frequencies.

=head2 Conflicts

When using SDL_mixer functions you need to avoid the following functions from SDL:

=over

=item C<SDL_OpenAudio( )>

Use Mix_OpenAudio instead.

=item C<SDL_CloseAudio( )>

Use Mix_CloseAudio instead.

=item C<SDL_PauseAudio( )>

Use C<Mix_Pause( -1 )> and C<Mix_PauseMusic( )> instead, to pause.

Use C<Mix_Resume( -1 )> and C<Mix_ResumeMusic( )> instead, to unpause.

=item C<SDL_LockAudio( )>

This is just not needed since C<SDL_mixer> handles this for you.

Using it may cause problems as well.

=item C<SDL_UnlockAudio( )>

This is just not needed since C<SDL_mixer> handles this for you.

Using it may cause problems as well.

=back

You may call the following functions freely:

=over

=item C<SDL_AudioDriverName( ... )>

This will still work as usual.

=item C<SDL_GetAudioStatus( )>

This will still work, though it will likely return C<SDL_AUDIO_PLAYING> even though C<SDL_mixer> is just playing silence.

=back

It is also a BAD idea to call C<SDL_mixer> and SDL audio functions from a callback. Callbacks include Effects functions and other C<SDL_mixer> audio hooks.

=head1 Functions

These may be imported by name or with the C<:all> tag.

=head2 C<SDL_MIXER_VERSION( ... )>

Macro to determine compile-time version of the C<SDL_mixer> library.

Expected parameters include:

=over

=item C<x> - a pointer to a L<SDL2::Version> struct to initialize

=back

=head2 C<SDL_MIXER_VERSION_ATLEAST( ... )>

Evaluates to true if compiled with C<SDL_mixer> at least C<major.minor.patch>.

	if ( SDL_MIXER_VERSION_ATLEAST( 2, 0, 5 ) ) {
		# Some feature that requires 2.0.5+
	}

Expected parameters include:

=over

=item C<major>

=item C<minor>

=item C<patch>

=back

=head2 C<Mix_Linked_Version( )>

This function gets the version of the dynamically linked C<SDL_mixer> library.

    my $link_version = Mix_Linked_Version();
    printf "running with SDL_mixer version: %d.%d.%d\n",
        $link_version->major, $link_version->minor, $link_version->patch;

It should NOT be used to fill a version structure, instead you should use the
L<< C<SDL_MIXER_VERSION( ... )>|/C<SDL_MIXER_VERSION( ... )> >> macro.

Returns a L<SDL2::Version> object.

=head2 C<Mix_Init( ... )>

Loads dynamic libraries and prepares them for use.

    if ( !( Mix_Init(MIX_INIT_MP3) & MIX_INIT_MP3 ) ) {
        printf( "could not initialize sdl2_image: %s\n", IMG_GetError() );
        return !1;
    }

You may call this multiple times, which will actually require you to call
C<IMG_Quit( )> just once to clean up. You may call this function with a
C<flags> of C<0> to retrieve whether support was built-in or not loaded yet.

Expected parameters include:

=over

=item C<flags>

Flags should be one or more flags from L<< C<MIX_InitFlags>|/C<MIX_InitFlags>
>> OR'd together.

=over

=item C<MIX_INIT_FLAC>

=item C<MIX_INIT_FLAC>

=item C<MIX_INIT_MP3>

=item C<MIX_INIT_OGG>

=item C<MIX_INIT_MID>

=item C<MIX_INIT_OPUS>

=back

=back

Returns the flags successfully initialized, or C<0> on failure.

=head2 C<Mix_Quit( )>

Unloads libraries loaded with L<< C<Mix_Init( ... )>|/C<Mix_Init( ... )> >>.

=head2 C<Mix_OpenAudio( ... )>

Initialize the mixer API.

    # start SDL with audio support
    if ( SDL_Init(SDL_INIT_AUDIO) == -1 ) {
        printf "SDL_Init: %s\n", SDL_GetError();
        exit 1;
    }

    # open 44.1KHz, signed 16bit, system byte order,
    #      stereo audio, using 1024 byte chunks
    if ( Mix_OpenAudio( 44100, MIX_DEFAULT_FORMAT, 2, 1024 ) == -1 ) {
        printf "Mix_OpenAudio: %s\n", Mix_GetError();
        exit 2;
    }

This must be called before using other functions in this library.

SDL must be initialized with C<SDL_INIT_AUDIO> before this call. C<frequency> would be 44100 for 44.1KHz,
which is CD audio rate. Most games use C<22050>, because C<44100> requires too much CPU power on older
computers. chunksize is the size of each mixed sample. The smaller this is the more your hooks will be
called. If make this too small on a slow system, sound may skip. If made to large, sound effects will
lag behind the action more. You want a happy medium for your target computer. You also may make this
C<4096>, or larger, if you are just playing music. C<MIX_CHANNELS( 8 )> mixing channels will be allocated
by default. You may call this function multiple times, however you will have to call L<< C<Mix_CloseAudio( ) >|/C<Mix_CloseAudio( ) > >>
just as many times for the device to actually close. The format will not changed on subsequent calls until fully closed. So you will have to close all the way before trying to open with different format parameters.

Expected parameters include:

=over

=item C<frequency> - output sampling frequency in samples per second (Hz).

You might use C<MIX_DEFAULT_FREQUENCY> (C<22050>) since that is a good value for most games.

=item C<format> - output sample format

This is based on SDL audio support. Here are the values listed in C<SDL_audio.h>:

=over

=item C<AUDIO_U8>

Unsigned 8-bit samples

=item C<AUDIO_S8>

Signed 8-bit samples

=item C<AUDIO_U16LSB>

Unsigned 16-bit samples, in little-endian byte order

=item C<AUDIO_S16LSB>

Signed 16-bit samples, in little-endian byte order

=item C<AUDIO_U16MSB>

Unsigned 16-bit samples, in big-endian byte order

=item C<AUDIO_S16MSB>

Signed 16-bit samples, in big-endian byte order

=item C<AUDIO_U16>

same as C<AUDIO_U16LSB> (for backwards compatibility probably)

=item C<AUDIO_S16>

same as C<AUDIO_S16LSB> (for backwards compatibility probably)

=item C<AUDIO_U16SYS>

Unsigned 16-bit samples, in system byte order

=item C<AUDIO_S16SYS>

Signed 16-bit samples, in system byte order

=back

C<MIX_DEFAULT_FORMAT> is the same as C<AUDIO_S16SYS>.

=item C<channels> - number of sound channels to output

Set to C<2> for stereo, C<1> for mono. This has nothing to do with mixing channels.

=item C<chunksize> - bytes used per output sample

=back

Returns C<0> on success; C<-1> on errors.

=head2 C<Mix_OpenAudioDevice( ... )>

Open the mixer with specific device and certain audio format

Expected parameters include:


=over

=item C<frequency> - output sampling frequency in samples per second (Hz).

You might use C<MIX_DEFAULT_FREQUENCY> (C<22050>) since that is a good value for most games.

=item C<format> - output sample format

=item C<channels> - number of sound channels to output

Set to C<2> for stereo, C<1> for mono. This has nothing to do with mixing channels.

=item C<chunksize> - bytes used per output sample

=item C<device> - name of device to open

=item C<allowed_changes> - C<0> or one or more flags OR'd together

These values include the following:

=over

=item C<SDL_AUDIO_ALLOW_FREQUENCY_CHANGE>

=item C<SDL_AUDIO_ALLOW_FORMAT_CHANGE>

=item C<SDL_AUDIO_ALLOW_CHANNELS_CHANGE>

=item C<SDL_AUDIO_ALLOW_ANY_CHANGE>

=back

=back

Returns a valid device ID that is C<<E<gt>0>> on success or C<0> on failure.

=head2 C<Mix_AllocateChannels( ... )>

Set the number of channels being mixed.

	Mix_AllocateChannels( 16 );

This can be called multiple times, even with sounds playing. If C<numchans> is less than the current number of channels, then the higher channels will be stopped, freed, and therefore not mixed any longer. It's probably not a good idea to change the size 1000 times a second though.

If any channels are deallocated, any callback set by C<Mix_ChannelFinished> will be called when each channel is halted to be freed. Note: passing in zero WILL free all mixing channels, however music will still play.

Expected parameters include:

=over

=item C<numchans> - number of channels to allocate for mixing

A negative number will not do anything. Use this to find out how many channels are currently allocated without modifying the count.

=back

Returns the number of channels allocated. This should never fail but a high number of channels can segfault if you run out of memory.

=head2 C<Mix_QuerySpec( ... )>

Find out what the actual audio device parameters are.

This may or may not match the parameters you passed to L<< C<Mix_OpenAudio( ... )>|/C<Mix_OpenAudio( ... )> >>.

    # get and print the audio format in use
    my $numtimesopened = Mix_QuerySpec( \my ( $frequency, $format, $channels ) );
    if ( !$numtimesopened ) {
        printf( "Mix_QuerySpec: %s\n", Mix_GetError() );
    }
    else {
        my $format_str
            = $format == AUDIO_U8   ? 'U8' :
            $format == AUDIO_S8     ? 'S8' :
            $format == AUDIO_U16LSB ? 'U16LSB' :
            $format == AUDIO_S16LSB ? 'S16LSB' :
            $format == AUDIO_U16MSB ? 'U16MSB' :
            $format == AUDIO_S16MSB ? 'S16MSB' :
            'Unknown';
        printf( "opened=%d times  frequency=%dHz  format=%s  channels=%d",
            $numtimesopened, $frequency, $format_str, $channels );
    }

Expected parameters include:

=over

=item C<frequency> - pointer to an int where the frequency actually used by the opened audio device will be stored

=item C<format> - pointer to a Uint16 where the output format actually being used by the audio device will be stored

=item C<channels> - pointer to an int where the number of audio channels will be stored

C<2> will mean stereo, C<1> will mean mono

=back

Returns C<0> on error. If the device was open, the number of times it was opened will be returned. The values of the arguments variables are not set on an error.

=head2 C<Mix_LoadWAV_RW( ... )>

Load C<src> for use as a sample.

    my $sample = Mix_LoadWAV_RW( SDL_RWFromFile( $wav, 'rb' ), 1 );
    if ( !$sample ) {
        printf( "Mix_LoadWAV_RW: %s\n", Mix_GetError() );
        # handle error
    }

This can load WAVE, AIFF, RIFF, OGG, and VOC formats. Using L<SDL2::RWops> is not covered
here, but they enable you to load from almost any source.

Note: You must call L<< C<SDL_OpenAudio( )>|/C<SDL_OpenAudio( )> >> before this. It must know the output characteristics so it can convert the sample for playback, it does this conversion at load time.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> to load the sample from

=item C<freesrc> - a non-zero value means we will automatically close/free the C<src> for you

=back

Returns a pointer to the sample as a L<SDL2::Mixer::Chunk> object. C<undef> is returned on errors.

=head2 C<Mix_LoadWAV( ... )>

Load C<file> for use as a sample.

	# load sample.wav in to sample
	my $sample = Mix_LoadWAV( 'sample.wav' );
	if( !$sample ) {
		printf( "Mix_LoadWAV: %s\n", Mix_GetError() );
		# handle error
	}

This is actually L<< C<Mix_LoadWAV_RW( SDL_RWFromFile( $file, 'rb' ), 1 )>|/C<Mix_LoadWAV_RW( ... )> >>. This can load WAVE, AIFF, RIFF, OGG, and VOC files.

Note: You must call L<< C<SDL_OpenAudio( )>|/C<SDL_OpenAudio( )> >> before this. It must know the output characteristics so it can convert the sample for playback, it does this conversion at load time.

Returns a pointer to the sample as a L<SDL2::Mixer::Chunk> object. C<undef> is returned on errors.

=head2 C<Mix_LoadMUS( ... )>

Load music file to use.

	# load the MP3 file "music.mp3" to play as music
	my $music = Mix_LoadMUS( 'music.mp3' );
	if( !$music ) {
		printf( "Mix_LoadMUS( 'music.mp3' ): %s\n", Mix_GetError() );
		# this might be a critical error...
	}

This can load WAVE, MOD, MIDI, OGG, MP3, FLAC, and any file that you use a command to play with.
If you are using an external command to play the music, you must call
L<< C<Mix_SetMusicCMD( ... )>|/ C<Mix_SetMusicCMD( ... )> >> before this,
otherwise the internal players will be used. Alternatively, if you have set
an external command up and don't want to use it, you must call
C<Mix_SetMusicCMD( undef )> to use the built-in players again.

Expected parameters include:

=over

=item C<file> - name of music file to use

=back

Returns a pointer to the sample as a L<SDL2::Mixer::Music> object. C<undef> is returned on errors.

=head2 C<Mix_LoadMUS_RW( ... )>

Load a music C<src> from an L<SDL2::RWops> object.

    my $music = Mix_LoadMUS_RW( SDL_RWFromFile( $mp3, 'rb' ), 1 );
    if ( !$music ) {
        printf( "Mix_LoadMUS_RW: %s\n", Mix_GetError() );
        # handle error
    }

This can load WAVE, MOD, MIDI, OGG, MP3, FLAC, and any file that you use a command to play with.
If you are using an external command to play the music, you must call
L<< C<Mix_SetMusicCMD( ... )>|/ C<Mix_SetMusicCMD( ... )> >> before this,
otherwise the internal players will be used. Alternatively, if you have set
an external command up and don't want to use it, you must call
C<Mix_SetMusicCMD( undef )> to use the built-in players again.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> to load the music from

=item C<freesrc> - a non-zero value means we will automatically close/free the C<src> for you

=back

Returns a pointer to the music as a L<SDL2::Mixer::Music> object. C<undef> is returned on errors.

=head2 C<Mix_LoadMUSType_RW( ... )>

Load a music C<src> from an L<SDL2::RWops> object assuming a specific format.

    my $music = Mix_LoadMUSType_RW( SDL_RWFromFile( $mp3, 'rb' ), MUS_MP3, 1 );
    if ( !$music ) {
        printf( "Mix_LoadMUSType_RW: %s\n", Mix_GetError() );
        # handle error
    }

This can load WAVE, MOD, MIDI, OGG, MP3, FLAC, and any file that you use a command to play with.
If you are using an external command to play the music, you must call
L<< C<Mix_SetMusicCMD( ... )>|/ C<Mix_SetMusicCMD( ... )> >> before this,
otherwise the internal players will be used. Alternatively, if you have set
an external command up and don't want to use it, you must call
C<Mix_SetMusicCMD( undef )> to use the built-in players again.

Expected parameters include:

=over

=item C<src> - the source L<SDL2::RWops> to load the music from

=item C<type> - a L<< specific format|/C<Mix_MusicType> >>

=item C<freesrc> - a non-zero value means we will automatically close/free the C<src> for you

=back

Returns a pointer to the music as a L<SDL2::Mixer::Music> object. C<undef> is returned on errors.

=head2 C<Mix_QuickLoad_WAV( ... )>

Load C<mem> as a WAVE/RIFF file into a new sample.

    # quick-load a wave from memory
    my $wave = ...; # I assume you have the wave loaded raw,
					# or compiled in the program...
					# or otherwise generated...
    if ( !( my $wave_chunk = Mix_QuickLoad_WAV($wave) ) ) {
        printf( "Mix_QuickLoad_WAV: %s\n", Mix_GetError() );

        # handle error
    }

The WAVE in C<mem> must be already in the output format. It would be better to use
L<< C<Mix_LoadWAV_RW( ... )>|/C<Mix_LoadWAV_RW( ... )> >> if you aren't sure.

Note: This function does very little checking. If the format mismatches the output format, or if the buffer is not a WAVE, it will not return an error. This is probably a dangerous function to use.

Returns a pointer to the sample as a L<SDL2::Mixer::Chunk> object. C<undef> is returned on errors.

=head2 C<Mix_QuickLoad_RAW( ... )>

Load C<mem> as a raw sample.

    # quick-load a wave from memory
    my $wave = ...; # I assume you have the wave loaded raw,
					# or compiled in the program...
					# or otherwise generated...
    if ( !( my $wave_chunk = Mix_QuickLoad_RAW($wave, length $wave) ) ) {
        printf( "Mix_QuickLoad_RAW: %s\n", Mix_GetError() );

        # handle error
    }

The data in C<mem> must be already in the output format. If you aren't sure what you are doing, this is not a good function for you!

Note: This function does very little checking. If the format mismatches the output format, or if the buffer is not a WAVE, it will not return an error. This is probably a dangerous function to use.

Returns a pointer to the sample as a L<SDL2::Mixer::Chunk> object. C<undef> is returned on errors.

=head2 C<Mix_FreeChunk( ... )>

Free the memory used in C<chunk>, and free C<chunk> itself as well. Do not use C<chunk> after this without loading a new sample to it. Note: It's a bad idea to free a chunk that is still being played...

	# free the sample
	Mix_FreeChunk( $sample );
	$sample = undef; # to be safe..

Expected parameters include:

=over

=item C<chunk> - pointer to the L<SDL2::Mixer::Chunk> to free

=back

=head2 C<Mix_FreeMusic( ... )>

Free the loaded C<music>. If C<music> is playing it will be halted. If C<music> is fading out, then this function will wait (blocking) until the fade out is complete.

	# free music
	Mix_FreeMusic( $music );
	$music = undef; # to be safe..

Expected parameters include:

=over

=item C<music> - pointer to the L<SDL2::Mixer::Music> to free

=back

=head2 C<Mix_GetNumChunkDecoders( )>

Get the number of sample chunk decoders available from the L<< C<Mix_GetChunkDecoder( ... )>|/C<Mix_GetChunkDecoder( ... )> >> function. This number can be different for each run of a program, due to the change in availability of shared libraries that support each format.

	printf("There are %d sample chunk deocoders available\n", Mix_GetNumChunkDecoders());

Returns the number of sample chunk decoders available.

=head2 C<Mix_GetChunkDecoder( ... )>

Get the name of the C<index>ed sample chunk decoder. You need to get the number of sample chunk decoders available using the L<< C<Mix_GetNumChunkDecoders( )>|/C<Mix_GetNumChunkDecoders( )> >> function.

	# print sample chunk decoders available
	for my $i ( 0 .. Mix_GetNumChunkDecoders() - 1 ) {
		printf( "Sample chunk decoder %d is for %s", Mix_GetChunkDecoder($i) );
	}

Appearing in this list doesn't promise your specific audio file will
decode but it's handy to know if you have, say, a functioning Timidity
install.

Expected parameters include:

=over

=item C<index> - the index number of sample chunk decoder to get

In the range from C<0 .. Mix_GetNumChunkDecoders()-1>, inclusive.

=back

Returns the name of the C<index>ed sample chunk decoder. This string is owned by the C<SDL_mixer> library, do not modify or free it. It is valid until you call L<< C<Mix_CloseAudio( )>|/C<Mix_CloseAudio( )> >> the final time.

=head2 C<Mix_HasChunkDecoder( ... )>

Find out if you have a C<name>d chunk decoder.

Expected parameters include:

=over

=item C<name> - decoder name to query

=back

Returns a true value if the given decoder is defined.

=head2 C<Mix_GetNumMusicDecoders( )>

Get the number of music decoders available from the L<< C<Mix_GetMusicDecoder( ... )>|/C<Mix_GetMusicDecoder( ... )> >> function. This number can be different for each run of a program, due to the change in availability of shared libraries that support each format.

	printf("There are %d music deocoders available\n", Mix_GetNumMusicDecoders());

Returns the number of music decoders available.

=head2 C<Mix_GetMusicDecoder( ... )>

Get the name of the C<index>ed sample music decoder. You need to get the number of sample music decoders available using the L<< C<Mix_GetNumMusicDecoders( )>|/C<Mix_GetNumMusicDecoders( )> >> function.

	# print sample music decoders available
	for my $i ( 0 .. Mix_GetNumMusicDecoders() - 1 ) {
		printf( "Music decoder %d is for %s", Mix_GetMusicDecoder($i) );
	}

Appearing in this list doesn't promise your specific audio file will
decode but it's handy to know if you have, say, a functioning Timidity
install.

Expected parameters include:

=over

=item C<index> - the index number of sample music decoder to get

In the range from C<0 .. Mix_GetNumMusicDecoders()-1>, inclusive.

=back

Returns the name of the C<index>ed sample music decoder. This string is owned by the C<SDL_mixer> library, do not modify or free it. It is valid until you call L<< C<Mix_CloseAudio( )>|/C<Mix_CloseAudio( )> >> the final time.

=head2 C<Mix_HasMusicDecoder( ... )>

Find out if you have a C<name>d music decoder.

Expected parameters include:

=over

=item C<name> - decoder name to query

=back

Returns a true value if the given decoder is defined.

=head2 C<Mix_GetMusicTitle( ... )>

Get C<music> title from meta-tag if possible. If title tag is empty, filename will be returned.

	my $title = Mix_GetMusicTitle( $music );

Expected parameters include:

=over

=item C<music> - L<SDL2::Mixer::Music> structure to query

=back

Returns the title as a string.

=head2 C<Mix_GetMusicTitleTag( ... )>

Get C<music> title from meta-tag if possible.

	my $title = Mix_GetMusicTitleTag( $music );

Expected parameters include:

=over

=item C<music> - L<SDL2::Mixer::Music> structure to query

=back

Returns the title as a string.

=head2 C<Mix_GetMusicArtistTag( ... )>

Get C<music> artist from meta-tag if possible.

	my $artist = Mix_GetMusicArtistTag( $music );

Expected parameters include:

=over

=item C<music> - L<SDL2::Mixer::Music> structure to query

=back

Returns the artist as a string.

=head2 C<Mix_GetMusicAlbumTag( ... )>

Get C<music> album from meta-tag if possible.

	my $album = Mix_GetMusicAlbumTag( $music );

Expected parameters include:

=over

=item C<music> - L<SDL2::Mixer::Music> structure to query

=back

Returns the artist as a string.

=head2 C<Mix_GetMusicCopyrightTag( ... )>

Get C<music> copyright from meta-tag if possible.

	my $copyright = Mix_GetMusicCopyrightTag( $music );

Expected parameters include:

=over

=item C<music> - L<SDL2::Mixer::Music> structure to query

=back

Returns the artist as a string.

=head2 C<Mix_SetPostMix( ... )>

Set a function that is called after all mixing is performed.

    Mix_SetPostMix(
        sub { # Add a little background white noise to whatever is playing
            my ( $udata, $stream, $len ) = @_;
            $$stream->[$_] += rand $udata->{amp} for 0 .. $len;
        },
        { amp => 10 }
    );

This can be used to provide real-time visual display of the audio stream
or altering the stream to add an echo or other effects.

Expected parameters include:

=over

=item C<mix_func> - a L<< function pointer|/C<Mix_Func> >> for the postmix processor; C<undef> unregisters the current postmixer

=item C<args> -  a pointer to data to pass into the C<mix_func>'s C<udata> parameter.

It is a good place to keep the state data for the processor, especially if the processor is made to handle multiple channels at the same time.

This may be C<undef>, depending on the processor.

=back

There can only be one postmix function used at a time through this method. Use
L<< C<Mix_RegisterEffect( MIX_CHANNEL_POST, mix_func, undef, arg )>|/C<Mix_RegisterEffect( ... )> >> to use multiple postmix processors.

Note: This postmix processor is run B<after> all the registered postmixers set up by C<Mix_RegisterEffect( ... )>.

=head2 C<Mix_HookMusic( ... )>

Set a custom music player function.

	my @ff = ...; # Some predefined music
    Mix_HookMusic(
        sub {
            my ( $udata, $stream, $len ) = @_;

            # fill buffer with...uh...music...
            $$stream->[$_] = $ff[ $_ + $udata->{pos} ] for 0 .. $len;

            # set udata for next time
            $udata->{pos} += $len;
        },
        { pos => 0 }
    );

This can be used to provide real-time visual display of the audio stream
or altering the stream to add an echo or other effects.

Expected parameters include:

=over

=item C<mix_func> - a L<< function pointer|/C<Mix_Func> >> for the postmix processor; C<undef> unregisters the current postmixer

=item C<args> -  a pointer to data to pass into the C<mix_func>'s C<udata> parameter.

It is a good place to keep the state data for the processor, especially if the processor is made to handle multiple channels at the same time.

This may be C<undef>, depending on the processor.

=back

The function will be called with C<args> passed into the C<udata> parameter when the
L<< mix_func|/C<Mix_Func> >> is called. The C<stream> parameter passes in the audio stream buffer to be
filled with C<len> bytes of music. The music player will then be called automatically when the mixer
needs it. Music playing will start as soon as this is called. All the music playing and stopping
functions have no effect on music after this. Pause and resume will work. Using a custom music
player and the internal music player is not possible, the custom music player takes priority. To
stop the custom music player call C<Mix_HookMusic(undef, undef)>.

=head2 C<Mix_HookMusicFinished( ... )>

Add your own callback for when the music has finished playing or when it is
stopped from a call to L<< C<Mix_HaltMusic( )>|/C<Mix_HaltMusic( )> >>.

    Mix_HookMusicFinished( sub { print "Music stopped.\n" } );

Any time music stops, the C<music_finished> function will be called. Call with C<undef> to remove the callback.

Expected parameters include:

=over

=item C<music_finished> - a function that should not expect any parameters or return anything

=back

=head2 C<Mix_GetMusicHookData( )>

Get the C<arg> passed into L<< C<Mix_HookMusic( ... )>|/C<Mix_HookMusic( ... )> >>.

	my $data = Mix_GetMusicHookData( );

Returns the C<arg> pointer.

=head2 C<Mix_ChannelFinished( ... )>

When C<channel> playback is halted, then the specified L<< C<channel_finished>|/C<channel_finished> >> function is called. The
channel parameter will contain the channel number that has finished.

Expected parameters include:

=over

=item C<channel_finished> - function to call when any channel finishes playback

Pass C<undef> to disable callback.

=back

The callback may be called from the mixer's audio
callback or it could be called as a result of Mix_HaltChannel(), etc.
do not call C<SDL_LockAudio( )> from this callback; you will either be
inside the audio callback, or C<SDL_mixer> will explicitly lock the audio
before calling your callback.

=head1 Effects Functions

These functions are for special effects processing. Not all effects are all that special. All effects are post processing routines that are either built-in to SDL_mixer or created by you. Effects can be applied to individual channels, or to the final mixed stream which contains all the channels including music.

The built-in processors: L<< C<Mix_SetPanning( ... )>|/C<Mix_SetPanning( ... )> >>,
L<< C<Mix_SetPosition( ... )>|/C<Mix_SetPosition( ... )> >>,
L<< C<Mix_SetDistance( ... )>|/C<Mix_SetDistance( ... )> >>, and
L<< C<Mix_SetReverseStereo( ... )>|/C<Mix_SetReverseStereo( ... )> >>, all look for an environment
variable, C<MIX_EFFECTSMAXSPEED> to be defined. If the environment variable is defined these
processors may use more memory or reduce the quality of the effects, all for better speed.

These functions may be imported by name or with the C<:effects> tag.

=head2 C<Mix_RegisterEffect( ... )>



























=head1 Effects

These functions are for special effects processing. Not all effects are all that special. All effects are post processing routines that are either built-in to SDL_mixer or created by you. Effects can be applied to individual channels, or to the final mixed stream which contains all the channels including music.

=head2 C<>

















=head2 C<Mix_SetError( ... )>

Wrapper around C<SDL_SetError( ... )>.

=head2 C<Mix_GetError( )>

Wrapper around C<SDL_GetError( )>.

=head1 Defined values and Enumerations

These might actually be useful and may be imported with the listed tags.

=head2 Version information

=over

=item C<SDL_MIXER_MAJOR_VERSION>

=item C<SDL_MIXER_MINOR_VERSION>

=item C<SDL_MIXER_PATCHLEVEL>

=item C<SDL_MIXER_COMPILEDVERSION> - Version number for the current C<SDL_mixer> version

=back

=head2 C<MIX_InitFlags>

=over

=item C<MIX_INIT_FLAC>

=item C<MIX_INIT_MOD>

=item C<MIX_INIT_MP3>

=item C<MIX_INIT_OGG>

=item C<MIX_INIT_MID>

=item C<MIX_INIT_OPUS>

=back

=head2 C<Mix_Fading>

Enumeration of the different fading types supported by C<SDL_mixer>.

=over

=item C<MIX_NO_FADING>

=item C<MIX_FADING_OUT>

=item C<MIX_FADING_IN>

=back

=head2 C<Mix_MusicType>

Enumeration of types of music files (not libraries used to load them).

=over

=item C<MUS_NONE>

=item C<MUS_CMD>

=item C<MUS_WAV>

=item C<MUS_MOD>

=item C<MUS_MID>

=item C<MUS_OGG>

=item C<MUS_MP3>

=item C<MUS_MP3_MAD_UNUSED>

=item C<MUS_FLAC>

=item C<MUS_MODPLUG_UNUSED>

=item C<MUS_OPUS>

=back

=head2 Good default values

These are good default values for a PC soundcard. They may be imported by name or with the C<:defaults> tag.

=over

=item C<MIX_CHANNELS>

The default mixer has 8 simultaneous mixing channels.

=item C<MIX_DEFAULT_FREQUENCY>

C<44100> is a good default value for a PC soundcard.

=item C<MIX_DEFAULT_FORMAT>

Based on your platform, this is C<AUDIO_S16>.

=item C<MIX_DEFAULT_CHANNELS>

=item C<MIX_MAX_VOLUME>

=back

=head2 C<Mix_Func>

This is a callback which must expect the following parameters:

=over

=item C<udata>

=item C<stream> - pointer to the stream data

=item C<len> - length of the stream

=back

=head2 C<channel_finished>

This is a callback which must expect the following parameters:

=over

=item C<channel> - the channel number that has finished

=back

=head2 C<MIX_CHANNEL_POST>

In some built-in effects, setting C<channel> to C<MIX_CHANNEL_POST> registers the effect as a posteffect where
it will be applied to the final mixed stream before passing it on to the audio device.

=head2 C<Mix_EffectFunc>

This is the format of a special effect callback:

	sub myeffect($chan, $stream, $len, $udata) { ... }

The callback should expect the following parameters:

=over

=item C<chan> - the channel number that your effect is affecting.

=item C<stream> - the buffer of data to work upon

=item C<len> - the size of C<stream>

=item C<udata> - a user-defined bit of data, which you pass as the last arg of C<Mix_RegisterEffect( ... )>, and is passed back unmolested to your callback

=back

Your effect changes the contents of C<stream> based on whatever parameters
are significant, or just leaves it be, if you prefer. You can do whatever
you like to the buffer, though, and it will continue in its changed state
down the mixing pipeline, through any other effect functions, then finally
to be mixed with the rest of the channels and music for the final output
stream.

DO NOT EVER call C<SDL_LockAudio( )> from your callback function!

=head2 C<Mix_EffectDone>

This is a callback that signifies that a channel has finished all its
loops and has completed playback. This gets called if the buffer
plays out normally, or if you call C<Mix_HaltChannel( ... )>, implicitly stop
a channel via C<Mix_AllocateChannels( ... )>, or unregister a callback while
it's still playing.

Your callback should expect the following parameters:

=over

=item C<chan> - the channel number that this effect is effecting now

=item C<udata> - user data pointer that was passed in to C<Mix_RegisterEffect( ... )> when registering this effect processor function

=back

DO NOT EVER call SDL_LockAudio() from your callback function!

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

chunksize little-endian soundcard unregisters postmixer postmixers postmix postmixes
unregister posteffect arg

=end stopwords

=cut

};
1;
