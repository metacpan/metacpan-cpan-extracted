package SDL2::audio {
    use strict;
    use warnings;
    use experimental 'signatures';
    use SDL2::Utils;
    #
    use SDL2::stdinc;
    use SDL2::error;
    use SDL2::endian;
    use SDL2::mutex;
    use SDL2::thread;
    use SDL2::rwops;
    #
    ffi->type( 'uint16' => 'SDL_AudioFormat' );
    define audio => [
        [ SDL_AUDIO_MASK_BITSIZE   => 0xFF ],        [ SDL_AUDIO_MASK_DATATYPE => ( 1 << 8 ) ],
        [ SDL_AUDIO_MASK_ENDIAN    => ( 1 << 12 ) ], [ SDL_AUDIO_MASK_SIGNED   => ( 1 << 15 ) ],
        [ SDL_AUDIO_BITSIZE        => sub ($x) { $x & SDL2::FFI::SDL_AUDIO_MASK_BITSIZE() } ],
        [ SDL_AUDIO_ISFLOAT        => sub ($x) { $x & SDL2::FFI::SDL_AUDIO_MASK_DATATYPE() } ],
        [ SDL_AUDIO_ISBIGENDIAN    => sub ($x) { $x & SDL2::FFI::SDL_AUDIO_MASK_ENDIAN() } ],
        [ SDL_AUDIO_ISSIGNED       => sub ($x) { $x & SDL2::FFI::SDL_AUDIO_MASK_SIGNED() } ],
        [ SDL_AUDIO_ISINT          => sub ($x) { !SDL2::FFI::DL_AUDIO_ISFLOAT($x) } ],
        [ SDL_AUDIO_ISLITTLEENDIAN => sub ($x) { !SDL2::FFI::SDL_AUDIO_ISBIGENDIAN($x) } ],
        [ SDL_AUDIO_ISUNSIGNED     => sub ($x) { !SDL2::FFI::SDL_AUDIO_ISSIGNED($x) } ],

        # audio format flags
        [ AUDIO_U8     => 0x0008 ], [ AUDIO_S8     => 0x8008 ], [ AUDIO_U16LSB => 0x0010 ],
        [ AUDIO_S16LSB => 0x8010 ], [ AUDIO_U16MSB => 0x1010 ], [ AUDIO_S16MSB => 0x9010 ],
        [ AUDIO_U16    => sub () { SDL2::FFI::AUDIO_U16LSB() } ],
        [ AUDIO_S16    => sub () { SDL2::FFI::AUDIO_S16LSB() } ],

        # int32 support
        [ AUDIO_S32LSB => 0x8020 ], [ AUDIO_S32MSB => 0x9020 ],
        [ AUDIO_S32    => sub () { SDL2::FFI::AUDIO_S32LSB() } ],

        # float32 support
        [ AUDIO_F32LSB => 0x8120 ], [ AUDIO_F32MSB => 0x9120 ],
        [ AUDIO_F32    => sub () { SDL2::FFI::AUDIO_F32LSB() } ],

        # Native audio byte ordering
        (
            SDL2::FFI::SDL_BYTEORDER() == SDL2::FFI::SDL_BIG_ENDIAN() ? (
                [ AUDIO_U16SYS => sub () { SDL2::FFI::AUDIO_U16MSB() } ],
                [ AUDIO_S16SYS => sub () { SDL2::FFI::AUDIO_S16MSB() } ],
                [ AUDIO_S32SYS => sub () { SDL2::FFI::AUDIO_S32MSB() } ],
                [ AUDIO_F32SYS => sub () { SDL2::FFI::AUDIO_F32MSB() } ]
                ) : (
                [ AUDIO_U16SYS => sub () { SDL2::FFI::AUDIO_U16LSB() } ],
                [ AUDIO_S16SYS => sub () { SDL2::FFI::AUDIO_S16LSB() } ],
                [ AUDIO_S32SYS => sub () { SDL2::FFI::AUDIO_S32LSB() } ],
                [ AUDIO_F32SYS => sub () { SDL2::FFI::AUDIO_F32LSB() } ],
                )
        ),

        # Allow change flags
        [ SDL_AUDIO_ALLOW_FREQUENCY_CHANGE => sub () {0x00000001} ],
        [ SDL_AUDIO_ALLOW_FORMAT_CHANGE    => sub () {0x00000002} ],
        [ SDL_AUDIO_ALLOW_CHANNELS_CHANGE  => sub () {0x00000004} ],
        [ SDL_AUDIO_ALLOW_SAMPLES_CHANGE   => sub () {0x00000008} ],
        [   SDL_AUDIO_ALLOW_ANY_CHANGE => sub () {
                ( SDL2::FFI::SDL_AUDIO_ALLOW_FREQUENCY_CHANGE()
                        | SDL2::FFI::SDL_AUDIO_ALLOW_FORMAT_CHANGE()
                        | SDL2::FFI::SDL_AUDIO_ALLOW_CHANNELS_CHANGE()
                        | SDL2::FFI::SDL_AUDIO_ALLOW_SAMPLES_CHANGE() )
            }
        ]
    ];

    # TODO: This is not how you accept a list of ints
    ffi->type( '(opaque,opaque,int)->void' => 'SDL_AudioCallback' );    # void*, uint8*, int -> void

    package SDL2::AudioSpec {
        use strict;
        use warnings;
        use experimental 'signatures';
        use SDL2::Utils;
        has
            freq      => 'int',
            format    => 'SDL_AudioFormat',
            channels  => 'uint8',
            silence   => 'uint8',
            samples   => 'uint16',
            padding   => 'uint16',
            size      => 'uint32',
            _callback => 'opaque',            # 'SDL_AudioCallback',
            userdata  => 'opaque';            # void *

        sub callback ( $s, $cb = () ) {
            if ( defined $cb ) {
                my $closure = ffi->closure($cb);
                ffi->cast( 'opaque', 'SDL_AudioCallback', $s->_callback )->unsticky
                    if defined $s->_callback;
                $closure->sticky;
                return $s->_callback($closure);
            }
            ffi->cast( 'opaque', 'SDL_AudioCallback', $_[0]->_callback );
        }
    };
    #
    define audio => [ [ SDL_AUDIOCVT_MAX_FILTERS => 9 ] ];
    ffi->type( '(opaque,SDL_AudioFormat)->void' => 'SDL_AudioFilter' )
        ;    # struct SDL_AudioCVT * cvt, SDL_AudioFormat format

    package SDL2::AudioCVT {
        use SDL2::Utils;
        has
            needed       => 'int',
            src_format   => 'SDL_AudioFormat',    # SDL_AudioFormat
            dst_format   => 'SDL_AudioFormat',    # SDL_AudioFormat
            rate_incr    => 'double',
            buf          => 'opaque',             # uint8 *
            len          => 'int',
            len_cvt      => 'int',
            len_mult     => 'int',
            len_ratio    => 'double',
            filters      => 'opaque',             #SDL_AudioFilter[SDL_AUDIOCVT_MAX_FILTERS + 1];
            filter_index => 'int';

        # TODO: unwrap these opaque values with casts
    };
    attach audio => {
        SDL_GetNumAudioDrivers    => [ [],         'int' ],
        SDL_GetAudioDriver        => [ ['int'],    'string' ],
        SDL_AudioInit             => [ ['string'], 'int' ],
        SDL_AudioQuit             => [ [] ],
        SDL_GetCurrentAudioDriver => [ [], 'string' ],
        SDL_OpenAudio             => [
            [ 'SDL_AudioSpec', 'SDL_AudioSpec' ],
            'int' => sub ( $inner, $desired, $obtained = () ) {
                deprecate <<'END';
SDL_OpenAudio( ... ) remains for compatibility with SDL 1.2. The new, more
powerful, and preferred way to do this is SDL_OpenAudioDevice( ... );
END
                $inner->( $desired, $obtained );
            }
        ]
    };
    ffi->type( 'uint32' => 'SDL_AudioDeviceID' );
    attach audio => {
        SDL_GetNumAudioDevices => [ ['int'],                           'int' ],
        SDL_GetAudioDeviceName => [ [ 'int', 'int' ],                  'string' ],
        SDL_GetAudioDeviceSpec => [ [ 'int', 'int', 'SDL_AudioSpec' ], 'int' ],
        SDL_OpenAudioDevice    =>
            [ [ 'string', 'int', 'SDL_AudioSpec', 'SDL_AudioSpec', 'int' ], 'SDL_AudioDeviceID' ]
    };
    #
    enum SDL_AudioStatus => [ [ SDL_AUDIO_STOPPED => 0 ], qw[SDL_AUDIO_PLAYING SDL_AUDIO_PAUSED] ];
    attach audio         => {
        SDL_GetAudioStatus       => [ [],                    'SDL_AudioStatus' ],
        SDL_GetAudioDeviceStatus => [ ['SDL_AudioDeviceID'], 'SDL_AudioStatus' ],
        SDL_PauseAudio           => [ ['int'] ],
        SDL_PauseAudioDevice     => [ [ 'SDL_AudioDeviceID', 'int' ] ],
        SDL_LoadWAV_RW           =>
            [ [ 'SDL_RWops', 'int', 'SDL_AudioSpec', 'opaque*', 'uint32*' ], 'SDL_AudioSpec' ]
    };
    define audio => [
        [   SDL_LoadWAV => sub ( $file, $spec, $audio_buf, $audio_len ) {
                SDL2::FFI::SDL_LoadWAV_RW( SDL2::FFI::SDL_RWFromFile( $file, 'rb' ),
                    1, $spec, $audio_buf, $audio_len );
            }
        ]
    ];
    attach audio => {
        SDL_FreeWAV       => [ ['uint8*'] ],
        SDL_BuildAudioCVT => [
            [   'SDL_AudioCVT',    'SDL_AudioFormat', 'uint8', 'int',
                'SDL_AudioFormat', 'uint8',           'int',
            ],
            'int'
        ],
        SDL_ConvertAudio => [ ['SDL_AudioCVT'], 'int' ]
    };

    package SDL2::AudioStream {
        use SDL2::Utils;
        our $TYPE = has();
    };
    attach audio => {
        SDL_NewAudioStream => [
            [ 'SDL_AudioFormat', 'uint8', 'int', 'SDL_AudioFormat', 'uint8', 'int' ],
            'SDL_AudioStream',
        ],
        SDL_AudioStreamPut       => [ [ 'SDL_AudioStream', 'opaque', 'int' ], 'int' ],
        SDL_AudioStreamGet       => [ [ 'SDL_AudioStream', 'opaque', 'int' ], 'int' ],
        SDL_AudioStreamAvailable => [ ['SDL_AudioStream'], 'int' ],
        SDL_AudioStreamFlush     => [ ['SDL_AudioStream'], 'int' ],
        SDL_AudioStreamClear     => [ ['SDL_AudioStream'] ],
        SDL_FreeAudioStream      => [ ['SDL_AudioStream'] ]
    };
    define audio => [ [ SDL_MIX_MAXVOLUME => 128 ] ];
    attach audio => {
        SDL_MixAudio           => [ [ 'uint8*', 'uint8*', 'uint32', 'int' ] ],
        SDL_MixAudioFormat     => [ [ 'uint8*', 'uint8*', 'SDL_AudioFormat', 'uint32', 'int' ] ],
        SDL_QueueAudio         => [ [ 'SDL_AudioDeviceID', 'opaque', 'uint32' ], 'int' ],
        SDL_DequeueAudio       => [ [ 'SDL_AudioDeviceID', 'opaque', 'uint32' ], 'uint32' ],
        SDL_GetQueuedAudioSize => [ ['SDL_AudioDeviceID'], 'uint32' ],
        SDL_ClearQueuedAudio   => [ ['SDL_AudioDeviceID'] ],
        SDL_LockAudio          => [ [] ],
        SDL_LockAudioDevice    => [ ['SDL_AudioDeviceID'] ],
        SDL_UnlockAudio        => [ [] ],
        SDL_UnlockAudioDevice  => [ ['SDL_AudioDeviceID'] ],
        SDL_CloseAudio         => [ [] ],
        SDL_CloseAudioDevice   => [ ['SDL_AudioDeviceID'] ]
    };

=encoding utf-8

=head1 NAME

SDL2::audio - SDL Audio Functions

=head1 SYNOPSIS

    use SDL2::FFI qw[:atomic];
	SDL_assert( 1 == 1 );
	my $test = 'nope';
	SDL_assert(
        sub {
            warn 'testing';
            my $retval = $test eq "blah";
            $test = "blah";
            $retval;
        }
    );

=head1 DESCRIPTION

Audio functions and data types.

=head1 Functions

These functions may be imported by name or with the C<:audio> tag.

=head2 <SDL_GetNumAudioDrivers( )>

Returns the number of built-in audio drivers.

=head2 C<SDL_GetAudioDriver( ... )>

Returns the audio driver at the given index. They are listed in the order they
are normally initialized by default.

	for my $index (0 .. SDL_GetNumAudioDrivers() - 1) {
		printf "[%d] %s\n", $index, SDL_GetAudioDriver($index);
	}

Expected parameters include:

=over

=item C<index> - zero based index

=back

Returns the name as a string.

=head2 C<SDL_AudioInit( ... )>

Initialize a particular audio driver.

	my $ok = SDL_AudioInit( 'disk' );

This function is used internally, and should not be used unless you have a
specific need to specify the audio driver you want to use. You should normally
use C<SDL_Init( ... )> or C<SDL_InitSubSystem( ... )>.

Expected parameters include:

=over

=item C<name> - name of the particular audio driver

=back

Returns C<0> on success. Check C<SDL_GetError( )> for more information.

=head2 C<SDL_AudioQuit( )>

Closes the current audio driver.

	SDL_AudioQuit( );

This function is used internally, and should not be used unless you have a
specific need to specify the audio driver you want to use. You should normally
use C<SDL_Init( ... )> or C<SDL_InitSubSystem( ... )>.

=head2 C<SDL_GetCurrentAudioDriver( )>

Get the name of the current audio driver.

	my $driver = SDL_GetCurrentAudioDriver( );

The returned string points to internal static memory and thus never becomes
invalid, even if you quit the audio subsystem and initialize a new driver
(although such a case would return a different static string from another call
to this function, of course). As such, you should not modify or free the
returned string.

Returns the name of the current audio driver or NULL if no driver has been
initialized.

=head2 C<SDL_OpenAudio( ... )>

This function is a legacy means of opening the audio device.

This function remains for compatibility with SDL 1.2, but also because it's
slightly easier to use than the new functions in SDL 2.0. The new, more
powerful, and preferred way to do this is SDL_OpenAudioDevice().

This function is roughly equivalent to:

	SDL_OpenAudioDevice(undef, 0, $desired, $obtained, SDL_AUDIO_ALLOW_ANY_CHANGE);

With two notable exceptions:

=over

=item If C<obtained> is NULL, we use C<desired> (and allow no changes), which means desired will be modified to have the correct values for silence, etc, and SDL will convert any differences between your app's specific request and the hardware behind the scenes.

=item The return value is always success or failure, and not a device ID, which means you can only have one device open at a time with this function.

=back

Expected parameters include:

=over

=item C<desired> - an L<SDL2::AudioSpec> structure representing the desired output format. Please refer to the C<SDL_OpenAudioDevice( ... )> documentation for details on how to prepare this structure.

=item C<obtained> - an L<SDL2::AudioSpec> structure filled in with the actual parameters, or NULL.

=back

This function opens the audio device with the desired parameters, and returns
C<0> if successful, placing the actual hardware parameters in the structure
pointed to by C<obtained>.

If C<obtained> is NULL, the audio data passed to the callback function will be
guaranteed to be in the requested format, and will be automatically converted
to the actual hardware audio format if necessary. If C<obtained> is NULL,
C<desired> will have fields modified.

This function returns a negative error code on failure to open the audio device
or failure to set up the audio thread; call C<SDL_GetError( )> for more
information.

=head2 C<SDL_GetNumAudioDevices( ... )>

Get the number of built-in audio devices.

	my $num = SDL_GetNumberAudioDevices( );

This function is only valid after successfully initializing the audio
subsystem.

Note that audio capture support is not implemented as of SDL 2.0.4, so the
C<iscapture> parameter is for future expansion and should always be zero for
now.

This function will return C<-1> if an explicit list of devices can't be
determined. Returning C<-1> is not an error. For example, if SDL is set up to
talk to a remote audio server, it can't list every one available on the
Internet, but it will still allow a specific host to be specified in
C<SDL_OpenAudioDevice( ... )>.

In many common cases, when this function returns a value <= 0, it can still
successfully open the default device (NULL for first argument of
C<SDL_OpenAudioDevice( ... )>).

This function may trigger a complete redetect of available hardware. It should
not be called for each iteration of a loop, but rather once at the start of a
loop:

	# Don't do this:
	for (my $i = 0; $i < SDL_GetNumAudioDevices(0); $i++) { ... }

	# do this instead:
	my $count = SDL_GetNumAudioDevices(0);
	for (my $i = 0; $i < $count; ++$i) { do_something_here(); }

Expected parameters include:

=over

=item C<iscapture> - zero to request playback devices, non-zero to request recording devices

=back

Returns the number of available devices exposed by the current driver or C<-1>
if an explicit list of devices can't be determined. A return value of C<-1>
does not necessarily mean an error condition.

=head2 C<SDL_GetAudioDeviceName( ... )>

Get the human-readable name of a specific audio device.

This function is only valid after successfully initializing the audio
subsystem. The values returned by this function reflect the latest call to
C<SDL_GetNumAudioDevices( ... )>; re-call that function to redetect available
hardware.

The string returned by this function is UTF-8 encoded, read-only, and managed
internally. You are not to free it. If you need to keep the string for any
length of time, you should make your own copy of it, as it will be invalid next
time any of several other SDL functions are called.

Expected parameters include:

=over

=item C<index> - the index of the audio device; valid values range from C<0> to C<SDL_GetNumAudioDevices( ) - 1>

=item C<iscapture> - non-zero to query the list of recording devices, zero to query the list of output devices.

=back

Returns the name of the audio device at the requested index, or NULL on error.

=head2 C<SDL_GetAudioDeviceSpec( ... )>

Get the preferred audio format of a specific audio device.

This function is only valid after a successfully initializing the audio
subsystem. The values returned by this function reflect the latest call to
C<SDL_GetNumAudioDevices( )>; re-call that function to redetect available
hardware.

C<spec> will be filled with the sample rate, sample format, and channel count.
All other values in the structure are filled with 0. When the supported struct
members are 0, SDL was unable to get the property from the backend.

Expected parameters include:

=over

=item C<index> - the index of the audio device; valid values range from C<0> to C<SDL_GetNumAudioDevices( ) - 1>

=item C<iscapture> - non-zero to query the list of recording devices, zero to query the list of output devices.

=item C<spec> - The L<SDL2::AudioSpec> to be initialized by this function.

=back

Returns C<0> on success, nonzero on error.

=head2 C<SDL_OpenAudioDevice( ... )>

Open a specific audio device.

C<SDL_OpenAudio( )>, unlike this function, always acts on device ID 1. As such,
this function will never return a 1 so as not to conflict with the legacy
function.

Please note that SDL 2.0 before 2.0.5 did not support recording; as such, this
function would fail if `iscapture` was not zero. Starting with SDL 2.0.5,
recording is implemented and this value can be non-zero.

Passing in a C<device> name of NULL requests the most reasonable default (and
is equivalent to what C<SDL_OpenAudio( )> does to choose a device). The
C<device> name is a UTF-8 string reported by C<SDL_GetAudioDeviceName( )>, but
some drivers allow arbitrary and driver-specific strings, such as a hostname/IP
address for a remote audio server, or a filename in the diskaudio driver.

When filling in the desired audio spec structure:

=over

=item - C<desired-E<gt>freq> should be the frequency in sample-frames-per-second (Hz).

=item - C<desired-E<gt>format> should be the audio format (`AUDIO_S16SYS`, etc).

=item - C<desired-E<gt>samples> is the desired size of the audio buffer, in
B<sample frames> (with stereo output, two samples--left and right--would
make a single sample frame). This number should be a power of two, and
may be adjusted by the audio driver to a value more suitable for the
hardware.  Good values seem to range between 512 and 8096 inclusive,
depending on the application and CPU speed.  Smaller values reduce
latency, but can lead to underflow if the application is doing heavy
processing and cannot fill the audio buffer in time. Note that the
number of sample frames is directly related to time by the following
formula: C<ms = (sampleframes*1000)/freq>

=item - C<desired-E<gt>size> is the size in B<bytes> of the audio buffer, and is calculated by C<SDL_OpenAudioDevice( )>. You don't initialize this.

=item - C<desired-E<gt>silence> is the value used to set the buffer to silence, and is calculated by C<SDL_OpenAudioDevice( )>. You don't initialize this.

=item - C<desired-E<gt>callback> should be set to a function that will be called when the audio device is ready for more data.  It is passed a pointer to the audio buffer, and the length in bytes of the audio buffer. This function usually runs in a separate thread, and so you should protect data structures that it accesses by calling C<SDL_LockAudioDevice( )> and C<SDL_UnlockAudioDevice( )> in your code. Alternately, you may pass a NULL pointer here, and call C<SDL_QueueAudio( )> with some frequency, to queue more audio samples to be played (or for capture devices, call C<SDL_DequeueAudio( )> with some frequency, to obtain audio samples).

=item - C<desired-E<gt>userdata> is passed as the first parameter to your callback function. If you passed a NULL callback, this value is ignored.

=back

C<allowed_changes> can have the following flags OR'd together:

=over

=item - C<SDL_AUDIO_ALLOW_FREQUENCY_CHANGE>

=item - C<SDL_AUDIO_ALLOW_FORMAT_CHANGE>

=item - C<SDL_AUDIO_ALLOW_CHANNELS_CHANGE>

=item - C<SDL_AUDIO_ALLOW_ANY_CHANGE>

=back

These flags specify how SDL should behave when a device cannot offer a specific
feature. If the application requests a feature that the hardware doesn't offer,
SDL will always try to get the closest equivalent.

For example, if you ask for float32 audio format, but the sound card only
supports int16, SDL will set the hardware to int16. If you had set
C<SDL_AUDIO_ALLOW_FORMAT_CHANGE>, SDL will change the format in the C<obtained>
structure. If that flag was B<not> set, SDL will prepare to convert your
callback's float32 audio to int16 before feeding it to the hardware and will
keep the originally requested format in the C<obtained> structure.

If your application can only handle one specific data format, pass a zero for
C<allowed_changes> and let SDL transparently handle any differences.

An opened audio device starts out paused, and should be enabled for playing by
calling C<SDL_PauseAudioDevice($devid, 0)> when you are ready for your audio
callback function to be called. Since the audio driver may modify the requested
size of the audio buffer, you should allocate any local mixing buffers after
you open the audio device.

The audio callback runs in a separate thread in most cases; you can prevent
race conditions between your callback and other threads without fully pausing
playback with C<SDL_LockAudioDevice( )>. For more information about the
callback, see SDL_AudioSpec.

Expected parameters include:

=over

=item C<device> - a UTF-8 string reported by C<SDL_GetAudioDeviceName( ... )> or a driver-specific name as appropriate. NULL requests the most reasonable default device.

=item C<iscapture> - non-zero to specify a device should be opened for recording, not playback

=item C<desired> - an L<SDL2::AudioSpec> structure representing the desired output format; see C<SDL_OpenAudio( )> for more information

=item C<obtained> - an L<SDL2::AudioSpec> structure filled in with the actual output format; see C<SDL_OpenAudio( )> for more information

=item C<allowed_changes> - C<0>, or one or more flags OR'd together

=back

Returns a valid device ID that is > 0 on success or 0 on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetAudioStatus( )>

Get the current audio status.

Returns an L<< C<SDL_AudioStatus>|/C<SDL_AudioStatus> >>.

=head2 C<SDL_GetAudioDeviceStatus( ... )>

Get the current audio status of a particular audio device.

Expected parameters include:

=over

=item C<dev> - C<SDL_AudioDeviceID> of the device to be queried.

=back

Returns an L<< C<SDL_AudioStatus>|/C<SDL_AudioStatus> >>.

=head2 C<SDL_PauseAudio( ... )>

Pause and unpause audio callback processing.

This function should be called with a parameter of C<0> after opening the audio
device to start playing sound. This is so you can safely initialize data for
your callback function after opening the audio device. Silence will be written
to the audio device during the pause.

Expected parameters include:

=over

=item C<pause_on> - true to pause processing

=back

=head2 C<SDL_PauseAudioDevice( ... )>

Pause the audio callback processing of a particular device.

Expected parameters include:

=over

=item C<dev> - C<SDL_AudioDeviceID> of the device to be pause or unpaused.

=item C<pause_on> - true to pause processing

=back

=head2 C<SDL_LoadWAV_RW( ... )>

Load the audio data of a WAVE file into memory.

Loading a WAVE file requires C<src>, C<spec>, C<audio_buf> and C<audio_len> to
be valid pointers. The entire data portion of the file is then loaded into
memory and decoded if necessary.

If C<freesrc> is non-zero, the data source gets automatically closed and freed
before the function returns.

Supported formats are RIFF WAVE files with the formats PCM (8, 16, 24, and 32
bits), IEEE Float (32 bits), Microsoft ADPCM and IMA ADPCM (4 bits), and A-law
and mu-law (8 bits). Other formats are currently unsupported and cause an
error.

If this function succeeds, the pointer returned by it is equal to C<spec> and
the pointer to the audio data allocated by the function is written to
C<audio_buf> and its length in bytes to C<audio_len>. The L<SDL2::AudioSpec>
members C<freq>, C<channels>, and C<format> are set to the values of the audio
data in the buffer. The C<samples> member is set to a sane default and all
others are set to zero.

It's necessary to use C<SDL_FreeWAV( )> to free the audio data returned in
C<audio_buf> when it is no longer used.

Because of the underspecification of the .WAV format, there are many
problematic files in the wild that cause issues with strict decoders. To
provide compatibility with these files, this decoder is lenient in regards to
the truncation of the file, the fact chunk, and the size of the RIFF chunk. The
hints C<SDL_HINT_WAVE_RIFF_CHUNK_SIZE>, C<SDL_HINT_WAVE_TRUNCATION>, and
C<SDL_HINT_WAVE_FACT_CHUNK> can be used to tune the behavior of the loading
process.

Any file that is invalid (due to truncation, corruption, or wrong values in the
headers), too big, or unsupported causes an error. Additionally, any critical
I/O error from the data source will terminate the loading process with an
error. The function returns NULL on error and in all cases (with the exception
of C<src> being NULL), an appropriate error message will be set.

It is required that the data source supports seeking.

Example:

	SDL_LoadWAV_RW( SDL_RWFromFile('sample.wav', 'rb'), 1, $spec, $buf, $len );

Note that C<SDL_LoadWAV( ... )> does this same thing for you, but in a less
messy way:

	SDL_LoadWAV("sample.wav", $spec, $buf, $len);

Expected parameters include:

=over

=item C<src> - The data source for the WAVE data

=item C<freesrc> - If non-zero, SDL will _always_ free the data source

=item C<spec> - An SDL_AudioSpec that will be filled in with the wave file's format details

=item C<audio_buf> - A pointer filled with the audio data, allocated by the function.

=item C<audio_len> - A pointer filled with the length of the audio data buffer in bytes

=back

This function, if successfully called, returns C<spec>, which will be filled
with the audio data format of the wave source data. C<audio_buf> will be filled
with a pointer to an allocated buffer containing the audio data, and
C<audio_len> is filled with the length of that audio buffer in bytes.

This function returns NULL if the .WAV file cannot be opened, uses an unknown
data format, or is corrupt; call C<SDL_GetError( )> for more information.

When the application is done with the data returned in C<audio_buf>, it should
call C<SDL_FreeWAV( )> to dispose of it.

=head2 C<SDL_LoadWAV( ... )>

Loads a .WAV from a file.

	SDL_LoadWAV("sample.wav", $spec, $buf, $len);

Expected parameters include:

=over

=item C<file> - A filename

=item C<spec> - An SDL_AudioSpec that will be filled in with the wave file's format details

=item C<audio_buf> - A pointer filled with the audio data, allocated by the function.

=item C<audio_len> - A pointer filled with the length of the audio data buffer in bytes

=back

This function is a compatibility convenience function that wraps L<<
C<SDL_LoadWAV_RW( ... )>|/C<SDL_LoadWAV_RW( ... )> >>. See that function for
return value information.

=head2 C<SDL_FreeWAV( ... )>

Free data previously allocated with C<SDL_LoadWAV( ... )> or C<SDL_LoadWAV_RW(
... )>.

After a WAVE file has been opened with C<SDL_LoadWAV( ... )> or
C<SDL_LoadWAV_RW( ... )> its data can eventually be freed with C<SDL_FreeWAV(
... )>. It is safe to call this function with a NULL pointer.

Expected parameters include:

=over

=item C<audio_buf> - a pointer to the buffer created by C<SDL_LoadWAV( ... )> or C<SDL_LoadWAV_RW( ... )>

=back

=head2 C<SDL_BuildAudioCVT( ... )>

Initialize an SDL_AudioCVT structure for conversion.

Before an SDL_AudioCVT structure can be used to convert audio data it must be
initialized with source and destination information.

This function will zero out every field of the SDL_AudioCVT, so it must be
called before the application fills in the final buffer information.

Once this function has returned successfully, and reported that a conversion is
necessary, the application fills in the rest of the fields in SDL_AudioCVT, now
that it knows how large a buffer it needs to allocate, and then can call
SDL_ConvertAudio() to complete the conversion.

Expected parameters include:

=over

=item C<cvt> - an SDL_AudioCVT structure filled in with audio conversion information

=item C<src_format> - the source format of the audio data; for more info see SDL_AudioFormat

=item C<src_channels> - the number of channels in the source

=item C<src_rate> - the frequency (sample-frames-per-second) of the source

=item C<dst_format> - the destination format of the audio data; for more info see SDL_AudioFormat

=item C<dst_channels> - the number of channels in the destination

=item C<dst_rate> - the frequency (sample-frames-per-second) of the destination

=back

Returns C<1> if the audio filter is prepared, C<0> if no conversion is needed,
or a negative error code on failure; call C<SDL_GetError( )> for more
information.

=head2 C<SDL_ConvertAudio( ... )>

Convert audio data to a desired audio format.

This function does the actual audio data conversion, after the application has
called C<SDL_BuildAudioCVT( ... )> to prepare the conversion information and
then filled in the buffer details.

Once the application has initialized the C<cvt> structure using
C<SDL_BuildAudioCVT( ... )>, allocated an audio buffer and filled it with audio
data in the source format, this function will convert the buffer, in-place, to
the desired format.

The data conversion may go through several passes; any given pass may possibly
temporarily increase the size of the data. For example, SDL might expand 16-bit
data to 32 bits before resampling to a lower frequency, shrinking the data size
after having grown it briefly. Since the supplied buffer will be both the
source and destination, converting as necessary in-place, the application must
allocate a buffer that will fully contain the data during its largest
conversion pass. After C<SDL_BuildAudioCVT( ... )> returns, the application
should set the C<$cvt-E<gt>len> field to the size, in bytes, of the source
data, and allocate a buffer that is C<cvt-E<gt>len * cvt-E<gt>len_mult> bytes
long for the C<buf> field.

The source data should be copied into this buffer before the call to
C<SDL_ConvertAudio( ... )>. Upon successful return, this buffer will contain
the converted audio, and C<cvt-E<gt>len_cvt> will be the size of the converted
data, in bytes. Any bytes in the buffer past C<cvt-E<gt>len_cvt> are undefined
once this function returns.

Expected parameters include:

=over

=item C<cvt> an L<SDL2::AudioCVT> structure that was previously set up by C<SDL_BuildAudioCVT( ... )>.

=back

Returns C<0> if the conversion was completed successfully or a negative error
code on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_NewAudioStream( ... )>

Create a new audio stream.

Expected parameters include:

=over

=item C<src_format> - The format of the source audio

=item C<src_channels> - The number of channels of the source audio

=item C<src_rate> - The sampling rate of the source audio

=item C<dst_format> - The format of the desired audio output

=item C<dst_channels> - The number of channels of the desired audio output

=item C<dst_rate> - The sampling rate of the desired audio output

=back

Returns a L<SDL2::AudioStream> on success.

=head2 C<SDL_AudioStreamPut( ... )>

Add data to be converted/resampled to the stream.

Expected parameters include:

=over

=item C<stream> - The stream the audio data is being added to

=item C<buf> - A pointer to the audio data to add

=item C<len> - The number of bytes to write to the stream

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_AudioStreamGet( ... )>

Get converted/resampled data from the stream

Expected parameters include:

=over

=item C<stream> - The stream the audio is being requested from

=item C<buf> - A buffer to fill with audio data

=item C<len> - The maximum number of bytes to fill

=back

Returns the number of bytes read from the stream, or C<-1> on error.

=head2 C<SDL_AudioStreamAvailable( ... )>

Get the number of converted/resampled bytes available. The stream may be
buffering data behind the scenes until it has enough to resample correctly, so
this number might be lower than what you expect, or even be zero. Add more data
or flush the stream if you need the data now.

Expected parameters include:

=over

=item C<stream> - The stream the audio is being requested from

=back

=head2 C<SDL_AudioStreamFlush( ... )>

Tell the stream that you're done sending data, and anything being buffered
should be converted/resampled and made available immediately.

It is legal to add more data to a stream after flushing, but there will be
audio gaps in the output. Generally this is intended to signal the end of
input, so the complete output becomes available.

Expected parameters include:

=over

=item C<stream> - The stream the audio is being flushed

=back

=head2 C<SDL_AudioStreamClear( ... )>

Clear any pending data in the stream without converting it.

Expected parameters include:

=over

=item C<stream> - The stream the audio is being cleared

=back

=head2 C<SDL_FreeAudioStream( ... )>

Free an audio stream.

Expected parameters include:

=over

=item C<stream> - The stream the audio is being freed

=back

=head2 C<SDL_MixAudio( ... )>

This function is a legacy means of mixing audio.

This function is equivalent to calling

	SDL_MixAudioFormat( $dst, $src, $format, $len, $volume );

where C<$format> is the obtained format of the audio device from the legacy
C<SDL_OpenAudio( ... )> function.

Expected parameters include:

=over

=item C<dst> - the destination for the mixed audio

=item C<src> - the source audio buffer to be mixed

=item C<len> - the length of the audio buffer in bytes

=item C<volume> - ranges from C<0> - C<128>, and should be set to C<SDL_MIX_MAXVOLUME> for full audio volume

=back

=head2 C<SDL_MixAudioFormat( ... )>

Mix audio data in a specified format.

This takes an audio buffer C<src> of C<len> bytes of C<format> data and mixes
it into C<dst>, performing addition, volume adjustment, and overflow clipping.
The buffer pointed to by C<dst> must also be C<len> bytes of C<format> data.

This is provided for convenience -- you can mix your own audio data.

Do not use this function for mixing together more than two streams of sample
data. The output from repeated application of this function may be distorted by
clipping, because there is no accumulator with greater range than the input
(not to mention this being an inefficient way of doing it).

It is a common misconception that this function is required to write audio data
to an output stream in an audio callback. While you can do that,
C<SDL_MixAudioFormat( ... )> is really only needed when you're mixing a single
audio stream with a volume adjustment.

Expected parameters include:

=over

=item C<dst> - the destination for the mixed audio

=item C<src> - the source audio buffer to be mixed

=item C<format> - the C<SDL_AudioFormat> structure representing the desired audio format

=item C<len> the length of the audio buffer in bytes

=item C<volume> ranges from C<0> - C<128>, and should be set to C<SDL_MIX_MAXVOLUME> for full audio volume

=back

=head2 C<SDL_QueueAudio( ... )>

Queue more audio on non-callback devices.

If you are looking to retrieve queued audio from a non-callback capture device,
you want C<SDL_DequeueAudio( ... )> instead. C<SDL_QueueAudio( ... )> will
return C<-1> to signify an error if you use it with capture devices.

SDL offers two ways to feed audio to the device: you can either supply a
callback that SDL triggers with some frequency to obtain more audio (pull
method), or you can supply no callback, and then SDL will expect you to supply
data at regular intervals (push method) with this function.

There are no limits on the amount of data you can queue, short of exhaustion of
address space. Queued data will drain to the device as necessary without
further intervention from you. If the device needs audio but there is not
enough queued, it will play silence to make up the difference. This means you
will have skips in your audio playback if you aren't routinely queueing
sufficient data.

This function copies the supplied data, so you are safe to free it when the
function returns. This function is thread-safe, but queueing to the same device
from two threads at once does not promise which buffer will be queued first.

You may not queue audio on a device that is using an application-supplied
callback; doing so returns an error. You have to use the audio callback or
queue audio with this function, but not both.

You should not call C<SDL_LockAudio( ... )> on the device before queueing; SDL
handles locking internally for this function.

Expected parameters include:

=over

=item C<dev> - the device ID to which we will queue audio

=item C<data> - the data to queue to the device for later playback

=item C<len> - the number of bytes (not samples!) to which C<data> points

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_DequeueAudio( ... )>

Dequeue more audio on non-callback devices.

If you are looking to queue audio for output on a non-callback playback device,
you want C<SDL_QueueAudio( ... )> instead. C<SDL_DequeueAudio( ... )> will
always return C<0> if you use it with playback devices.

SDL offers two ways to retrieve audio from a capture device: you can either
supply a callback that SDL triggers with some frequency as the device records
more audio data, (push method), or you can supply no callback, and then SDL
will expect you to retrieve data at regular intervals (pull method) with this
function.

There are no limits on the amount of data you can queue, short of exhaustion of
address space. Data from the device will keep queuing as necessary without
further intervention from you. This means you will eventually run out of memory
if you aren't routinely dequeueing data.

Capture devices will not queue data when paused; if you are expecting to not
need captured audio for some length of time, use SDL_PauseAudioDevice() to stop
the capture device from queueing more data. This can be useful during, say,
level loading times. When unpaused, capture devices will start queueing data
from that point, having flushed any capturable data available while paused.

This function is thread-safe, but dequeueing from the same device from two
threads at once does not promise which thread will dequeue data first.

You may not dequeue audio from a device that is using an application-supplied
callback; doing so returns an error. You have to use the audio callback, or
dequeue audio with this function, but not both.

You should not call C<SDL_LockAudio( ... )> on the device before dequeueing;
SDL handles locking internally for this function.

Expected parameters include:

=over

=item C<dev> - the device ID from which we will dequeue audio

=item C<data> - a pointer into where audio data should be copied

=item C<len> - the number of bytes (not samples!) to which (data) points

=back

Returns the number of bytes dequeued, which could be less than requested; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetQueuedAudioSize( ... )>

Get the number of bytes of still-queued audio.

For playback devices: this is the number of bytes that have been queued for
playback with C<SDL_QueueAudio( ... )>, but have not yet been sent to the
hardware.

Once we've sent it to the hardware, this function can not decide the exact byte
boundary of what has been played. It's possible that we just gave the hardware
several kilobytes right before you called this function, but it hasn't played
any of it yet, or maybe half of it, etc.

For capture devices, this is the number of bytes that have been captured by the
device and are waiting for you to dequeue. This number may grow at any time, so
this only informs of the lower-bound of available data.

You may not queue or dequeue audio on a device that is using an
application-supplied callback; calling this function on such a device always
returns 0. You have to use the audio callback or queue audio, but not both.

You should not call C<SDL_LockAudio( ... )> on the device before querying; SDL
handles locking internally for this function.

Expected parameters include:

=over

=item C<dev> - the device ID of which we will query queued audio size

=back

Returns the number of bytes (not samples!) of queued audio.

=head2 C<SDL_ClearQueuedAudio( ... )>

Drop any queued audio data waiting to be sent to the hardware.

Immediately after this call, C<SDL_GetQueuedAudioSize( ... )> will return C<0>.
For output devices, the hardware will start playing silence if more audio isn't
queued. For capture devices, the hardware will start filling the empty queue
with new data if the capture device isn't paused.

This will not prevent playback of queued audio that's already been sent to the
hardware, as we can not undo that, so expect there to be some fraction of a
second of audio that might still be heard. This can be useful if you want to,
say, drop any pending music or any unprocessed microphone input during a level
change in your game.

You may not queue or dequeue audio on a device that is using an
application-supplied callback; calling this function on such a device always
returns C<0>. You have to use the audio callback or queue audio, but not both.

You should not call C<SDL_LockAudio( ... )> on the device before clearing the
queue; SDL handles locking internally for this function.

Expected parameters include:

=over

=item C<dev> - the device ID of which to clear the audio queue

=back

This function always succeeds and thus returns void.

=head2 C<SDL_LockAudio( )>

Protects the callback function.

During a C<SDL_LockAudio( )>/C<SDL_UnlockAudio( )> pair, you can be guaranteed
that the callback function is not running.  Do not call these from the callback
function or you will cause deadlock.

=head2 C<SDL_LockAudioDevice( ... )>

Protects the callback function for a particular audio device.

During a C<SDL_LockAudioDevice( ... )>/C<SDL_UnlockAudioDevice( ... )> pair,
you can be guaranteed that the callback function is not running.  Do not call
these from the callback function or you will cause deadlock.

Expected parameters include:

=over

=item C<dev> - the <SDL_AudioDeviceID>

=back

=head2 C<SDL_UnlockAudio( )>

Protects the callback function.

During a C<SDL_LockAudio( )>/C<SDL_UnlockAudio( )> pair, you can be guaranteed
that the callback function is not running.  Do not call these from the callback
function or you will cause deadlock.

=head2 C<SDL_UnlockAudioDevice( ... )>

Protects the callback function for a particular audio device.

During a C<SDL_LockAudioDevice( ... )>/C<SDL_UnlockAudioDevice( ... )> pair,
you can be guaranteed that the callback function is not running.  Do not call
these from the callback function or you will cause deadlock.

Expected parameters include:

=over

=item C<dev> - the <SDL_AudioDeviceID>

=back

=head2 C<SDL_CloseAudio( )>

This function is a legacy means of closing the audio device.

This function is equivalent to calling

	SDL_CloseAudioDevice( 1 );

and is only useful if you used the legacy C<SDL_OpenAudio( ... )> function.

=head2 C<SDL_CloseAudioDevice( ... )>

This function is a legacy means of closing a particular audio device and is
only useful if you used the legacy C<SDL_OpenAudio( ... )> function.

Expected parameters include:

=over

=item C<dev> - the <SDL_AudioDeviceID>

=back

=head1 Defined Values and Enumumerations

Defines and enumerations listed here may be imported by name or with their
given tags.

=head2 C<SDL_AudioFormat>

These are what the 16 bits in SDL_AudioFormat currently mean... (Unspecified
bits are always zero).

    ++-----------------------sample is signed if set
    ||
    ||       ++-----------sample is bigendian if set
    ||       ||
    ||       ||          ++---sample is float if set
    ||       ||          ||
    ||       ||          || +---sample bit size---+
    ||       ||          || |                     |
    15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00

=head2  Audio flags

These may be imported by name or with the C<:audio> tag.

=over

=item C<SDL_AUDIO_MASK_BITSIZE>

=item C<SDL_AUDIO_MASK_DATATYPE>

=item C<SDL_AUDIO_MASK_ENDIAN>

=item C<SDL_AUDIO_MASK_SIGNED>

=item C<SDL_AUDIO_BITSIZE( ... )>

=item C<SDL_AUDIO_ISFLOAT( ... )>

=item C<SDL_AUDIO_ISBIGENDIAN( ... )>

=item C<SDL_AUDIO_ISSIGNED( ... )>

=item C<SDL_AUDIO_ISINT( ... )>

=item C<SDL_AUDIO_ISLITTLEENDIAN( ... )>

=item C<SDL_AUDIO_ISUNSIGNED( ... )>

=back

=head2 Audio format flags

Defaults to LSB byte order. These may be imported with the C<:audio> tag.

=over

=item C<AUDIO_U8> - Unsigned 8-bit samples

=item C<AUDIO_S8> - Signed 8-bit samples

=item C<AUDIO_U16LSB> - Unsigned 16-bit samples

=item C<AUDIO_S16LSB> - Signed 16-bit samples

=item C<AUDIO_U16MSB> - As above, but big-endian byte order

=item C<AUDIO_S16MSB> - As above, but big-endian byte order

=item C<AUDIO_U16> - C<AUDIO_U16LSB>

=item C<AUDIO_S16> - C<AUDIO_S16LSB>

=back

=head2 C<int32> support

These may be imported with the C<:audio> tag.

=over

=item C<AUDIO_S32LSB> - 32-bit integer samples

=item C<AUDIO_S32MSB> - As above, but big-endian byte order

=item C<AUDIO_S32> - C<AUDIO_S32LSB>

=back

=head2 C<float32> support

These may be imported with the C<:audio> tag.

=over

=item C<AUDIO_F32LSB> - 32-bit floating point samples

=item C<AUDIO_F32MSB> - As above, but big-endian byte order

=item C<AUDIO_F32> - C<AUDIO_F32LSB>

=back

=head2 Native audio byte ordering

Values are based on endianness of system. These may be imported with the
C<:audio> tag.

=over

=item C<AUDIO_U16SYS>

=item C<AUDIO_S16SYS>

=item C<AUDIO_S32SYS>

=item C<AUDIO_F32SYS>

=back

=head2 Allow change flags

Which audio format changes are allowed when opening a device. These may be
imported with the C<:audio> tag.

=over

=item C<SDL_AUDIO_ALLOW_FREQUENCY_CHANGE>

=item C<SDL_AUDIO_ALLOW_FORMAT_CHANGE>

=item C<SDL_AUDIO_ALLOW_CHANNELS_CHANGE>

=item C<SDL_AUDIO_ALLOW_SAMPLES_CHANGE>

=item C<SDL_AUDIO_ALLOW_ANY_CHANGE>

=back

=head2 C<SDL_AudioCallback>

Callback called when the audio device needs more data.

Parameters you should expect:

=over

=item C<userdata> - an application-specific parameter saved in the L<SDL2::AudioSpec> structure

=item C<stream> - a pointer to the audio data buffer.

=item C<len> - the length of that buffer in bytes.

=back

Once the callback returns, the buffer will no longer be valid. Stereo samples
are stored in a LRLRLR ordering.

You can choose to avoid callbacks and use C<SDL_QueueAudio( )> instead, if you
like. Just open your audio device with a NULL callback.

=head2 C<SDL_AudioFilter>

Callback that feeds the audio device.

Parameters you should expect:

=over

=item C<cvt> - L<SDL2::AudioCVT> structure

=item C<format> - L<SDL_AudioFormat> value

=back

=head2 C<SDL_AUDIOCVT_MAX_FILTERS>

The maximum number of C<SDL_AudioFilter> functions in L<SDL2::AudioCVT> is
currently limited to 9. The L<SDL2::AudioCVT>->filters array has 10 pointers,
one of which is the terminating NULL pointer.

=head2 C<SDL_AudioDeviceID>

SDL Audio Device IDs.

A successful call to C<SDL_OpenAudio( ... )> is always device id 1, and legacy
SDL audio APIs assume you want this device ID. C<SDL_OpenAudioDevice( ... )>
calls always returns devices >= 2 on success. The legacy calls are good both
for backwards compatibility and when you don't care about multiple, specific,
or capture devices.

=head2 C<SDL_AudioStatus>

Get the current audio state. This enumeration may be imported with the
C<:audioStatus> tag.

=over

=item C<SDL_AUDIO_STOPPED>

=item C<SDL_AUDIO_PLAYING>

=item C<SDL_AUDIO_PAUSED>

=back

=head2 C<SDL_MIX_MAXVOLUME>

Max audio volume.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

redetect iscapture diskaudio unpause unpaused underflow dequeueing capturable
dequeue dequeueing underspecification dequeued

=end stopwords

=cut

};
1;
