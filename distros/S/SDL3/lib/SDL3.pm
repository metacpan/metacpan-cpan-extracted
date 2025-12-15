package SDL3 v0.0.3 {
    use v5.40;
    use base 'Exporter';
    use Affix qw[:all];
    use Alien::SDL3;
    use Carp   qw[croak cluck confess];
    use Config qw[%Config];

=encoding utf-8

=head1 NAME

SDL3 - Perl Wrapper for the Simple DirectMedia Layer 3.0

=head1 SYNOPSIS

    use v5.40;
    use SDL3 qw[:all :main];
    my ( $x, $y, $dx, $dy, $ren ) = ( 300, 200, 5, 5 );

    sub SDL_AppInit( $app, $ac, $av ) {
        state $win;
        SDL_Init(SDL_INIT_VIDEO);
        SDL_CreateWindowAndRenderer( 'Bouncing Box', 640, 480, 0, \$win, \$ren );
        SDL_SetRenderVSync( $ren, 1 );
        SDL_APP_CONTINUE;
    }

    sub SDL_AppEvent( $app, $ev ) {
        $ev->{type} == SDL_EVENT_QUIT ? SDL_APP_SUCCESS : SDL_APP_CONTINUE;
    }

    sub SDL_AppIterate($app) {
        $dx *= -1 if $x <= 0 || $x >= 620;    # Bounce X (Window 640 - Rect 20)
        $dy *= -1 if $y <= 0 || $y >= 460;    # Bounce Y (Window 480 - Rect 20)
        $x  += $dx;
        $y  += $dy;
        SDL_SetRenderDrawColor( $ren, 20, 20, 30, 255 );
        SDL_RenderClear($ren);
        SDL_SetRenderDrawColor( $ren, int($x) % 255, int($y) % 255, 200, 255 );
        SDL_RenderFillRect( $ren, { x => $x, y => $y, w => 20, h => 20 } );
        SDL_RenderPresent($ren);
        SDL_APP_CONTINUE;
    }
    sub SDL_AppQuit { }

=head1 DESCRIPTION

This module provides a Perl wrapper for SDL3, a cross-platform development library designed to provide low level access
to audio, keyboard, mouse, joystick, and graphics hardware.

This is very much still under construction. There are a few examples in this distribution's C<eg/> directory but a few
games and other demos I've written may be found on github: L<https://github.com/sanko/SDL3.pm-demos>.

=head2 Features

Each feature listed below is a tag you may use.

=cut

    my ( $lib, @etc ) = Alien::SDL3->dynamic_libs;
    croak "Could not find library" unless $lib;
    Affix::load_library($_) or die "Could not find $_" for $lib, @etc;
    our ( %EXPORT_TAGS, @EXPORT_OK );
    my $main_hook;

    sub import ( $pkg, @wants ) {
        {
            no strict 'refs';
            (s[^:][_]r)->() for @wants;
        }
        $main_hook //= caller if grep { $_ eq ':main' } @wants;
        #
        require List::Util;
        @EXPORT_OK = sort map {@$_} values %EXPORT_TAGS;
        $EXPORT_TAGS{all} = [@EXPORT_OK];
        SDL3->export_to_level( 1, $pkg, @wants );
    }
    #
    sub _affix_and_export( $name, $args, $ret ) {
        my ( $n, $r ) = ref $name ? @$name : ( $name, $name );
        confess 'Failed to affix ' . $name . ': ' . $n unless affix $lib, $name, $args, $ret;
        push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $n;
    }

    sub _const_and_export( $name, $value ) {
        no strict 'refs';
        *{$name} = sub() {$value};
        push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $name;
    }
    sub _export( $name, @tags ) { push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $name }

    sub _func_and_export( $name, $sub ) {
        no strict 'refs';
        my ( undef, undef, undef, $tag ) = caller;
        *{$name} = $sub;
        push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $name;
    }

    sub _typedef_and_export( $name, $type //= () ) {
        no strict 'refs';
        my ( undef, undef, undef, $tag ) = caller;
        if ( defined $type ) {
            typedef $name, $type;
        }
        else {
            typedef $name;
        }
        push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $name;
    }

    sub _enum_and_export( $name, $values ) {
        no strict 'refs';
        my ( undef, undef, undef, $tag ) = caller;
        typedef $name, Enum [@$values];
        push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $name;

        #~ my $value = 0;
        for my $enum (@$values) {
            push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, ref $enum ? $enum->[0] : $enum;
        }
    }

=head3 C<:all>

This binds all functions, defines all types, and imports them into your package.

See L<the SDL3 Wiki|https://wiki.libsdl.org/SDL3/FrontPage> for documentation of the hundreds of types and functions
you'll have access to with this import tag.

=cut

    sub _all() {
        state $done++ && return;
        _stdinc();
        _assert();
        _asyncio();
        _atomic();
        _audio();
        _bits();
        _blendmode();
        _camera();
        _clipboard();
        _cpuinfo();
        _dialog();
        _error();
        _events();
        _filesystem();
        _gamepad();
        _gpu();
        _guid();
        _haptic();
        _hidapi();
        _hints();
        _init();
        _iostream();
        _joystick();
        _keyboard();
        _keycode();
        _loadso();
        _locale();
        _log();
        _messagebox();
        _metal();
        _misc();
        _mouse();
        _mutex();
        _pen();
        _pixels();
        _platform();
        _power();
        _process();
        _properties();
        _rect();
        _render();
        _scancode();
        _sensor();
        _storage();
        _surface();
        _system();
        _thread();
        _time();
        _timer();
        _tray();
        _touch();
        _version();
        _video();
        #
    }

    # No docs because this is a no-op.
    sub _assert () {
        state $done++ && return;
        _error();
    }

=head3 C<:asyncio> - Async I/O

SDL offers a way to perform I/O asynchronously. This allows an app to read or write files without waiting for data to
actually transfer; the functions that request I/O never block while the request is fulfilled.

See L<SDL3: CategoryAsyncIO|https://wiki.libsdl.org/SDL3/CategoryAsyncIO>

=cut

    sub _asyncio() {
        state $done++ && return;
        #
        _stdinc();
        #
        _typedef_and_export SDL_AsyncIO => Void;
        _enum_and_export SDL_AsyncIOTaskType => [ 'SDL_ASYNCIO_TASK_READ', 'SDL_ASYNCIO_TASK_WRITE', 'SDL_ASYNCIO_TASK_CLOSE' ];
        _enum_and_export SDL_AsyncIOResult   => [ 'SDL_ASYNCIO_COMPLETE',  'SDL_ASYNCIO_FAILURE',    'SDL_ASYNCIO_CANCELED' ];
        _typedef_and_export SDL_AsyncIOOutcome => Struct [
            asyncio           => Pointer [ SDL_AsyncIO() ],
            type              => SDL_AsyncIOTaskType(),
            result            => SDL_AsyncIOResult(),
            buffer            => Pointer [Void],
            offset            => UInt64,
            bytes_requested   => UInt64,
            bytes_transferred => UInt64,
            userdata          => Pointer [Void]
        ];
        _typedef_and_export SDL_AsyncIOQueue => Void;
        _affix_and_export SDL_AsyncIOFromFile => [ String, String ], Pointer [ SDL_AsyncIO() ];
        _affix_and_export SDL_GetAsyncIOSize => [ Pointer [ SDL_AsyncIO() ] ], SInt64;
        _affix_and_export
            SDL_ReadAsyncIO => [ Pointer [ SDL_AsyncIO() ], Pointer [Void], UInt64, UInt64, Pointer [ SDL_AsyncIOQueue() ], Pointer [Void] ],
            Bool;
        _affix_and_export
            SDL_WriteAsyncIO => [ Pointer [ SDL_AsyncIO() ], Pointer [Void], UInt64, UInt64, Pointer [ SDL_AsyncIOQueue() ], Pointer [Void] ],
            Bool;
        _affix_and_export
            SDL_CloseAsyncIO => [ Pointer [ SDL_AsyncIO() ], Bool, Pointer [ SDL_AsyncIOQueue() ], Pointer [Void] ],
            Bool;
        _affix_and_export SDL_CreateAsyncIOQueue  => [], Pointer [ SDL_AsyncIOQueue() ];
        _affix_and_export SDL_DestroyAsyncIOQueue => [ Pointer [ SDL_AsyncIOQueue() ] ], Void;
        _affix_and_export SDL_GetAsyncIOResult    => [ Pointer [ SDL_AsyncIOQueue() ], Pointer [ SDL_AsyncIOOutcome() ] ], Bool;
        _affix_and_export
            SDL_WaitAsyncIOResult => [ Pointer [ SDL_AsyncIOQueue() ], Pointer [ SDL_AsyncIOOutcome() ], SInt32 ],
            Bool;
        _affix_and_export SDL_SignalAsyncIOQueue => [ Pointer [ SDL_AsyncIOQueue() ] ], Void;
        _affix_and_export SDL_LoadFileAsync => [ String, Pointer [ SDL_AsyncIOQueue() ], Pointer [Void] ], Bool;
    }

=head3 C<:atomic> - Atomic Operations

Atomic operations.

IMPORTANT: If you are not an expert in concurrent lockless programming, you should not be using any functions in this
file. You should be protecting your data structures with full mutexes instead.

See L<SDL3: CategoryAtomic|https://wiki.libsdl.org/SDL3/CategoryAtomic>

=cut

    sub _atomic () {
        state $done++ && return;
        #
        _platform_defines();
        _stdinc();
        #
        _typedef_and_export SDL_SpinLock => Int;
        _affix_and_export SDL_TryLockSpinlock              => [ Pointer [ SDL_SpinLock() ] ], Bool;
        _affix_and_export SDL_LockSpinlock                 => [ Pointer [ SDL_SpinLock() ] ], Void;
        _affix_and_export SDL_UnlockSpinlock               => [ Pointer [ SDL_SpinLock() ] ], Void;
        _affix_and_export SDL_MemoryBarrierReleaseFunction => [], Void;
        _affix_and_export SDL_MemoryBarrierAcquireFunction => [], Void;
        _typedef_and_export SDL_AtomicInt => Struct [ value => Int ];
        _affix_and_export SDL_CompareAndSwapAtomicInt => [ Pointer [ SDL_AtomicInt() ], Int, Int ], Bool;
        _affix_and_export SDL_SetAtomicInt            => [ Pointer [ SDL_AtomicInt() ], Int ], Int;
        _affix_and_export SDL_GetAtomicInt            => [ Pointer [ SDL_AtomicInt() ] ], Int;
        _affix_and_export SDL_AddAtomicInt            => [ Pointer [ SDL_AtomicInt() ], Int ], Int;
        _typedef_and_export SDL_AtomicU32 => Struct [ value => UInt32 ];
        _affix_and_export SDL_CompareAndSwapAtomicU32 => [ Pointer [ SDL_AtomicU32() ], UInt32, UInt32 ], Bool;
        _affix_and_export SDL_SetAtomicU32            => [ Pointer [ SDL_AtomicU32() ], UInt32 ], UInt32;
        _affix_and_export SDL_GetAtomicU32            => [ Pointer [ SDL_AtomicU32() ] ], UInt32;

        #~ _affix_and_export SDL_AddAtomicU32                => [ Pointer [ SDL_AtomicU32() ], Int ], UInt32;
        _affix_and_export SDL_CompareAndSwapAtomicPointer => [ Pointer [ Pointer [Void] ], Pointer [Void], Pointer [Void] ], Bool;
        _affix_and_export SDL_SetAtomicPointer            => [ Pointer [ Pointer [Void] ], Pointer [Void] ], Pointer [Void];
        _affix_and_export SDL_GetAtomicPointer            => [ Pointer [ Pointer [Void] ] ], Pointer [Void];
    }

=head3 C<:audio> - Audio Playback, Recording, and Mixing

Audio functionality for the SDL library.

All audio in SDL3 revolves around C<SDL_AudioStream>. Whether you want to play or record audio, convert it, stream it,
buffer it, or mix it, you're going to be passing it through an audio stream.

See L<SDL3: CategoryAudio|https://wiki.libsdl.org/SDL3/CategoryAudio>

=cut

    sub _audio() {
        state $done++ && return;
        _error();
        _iostream();
        _mutex();
        _properties();
        _stdinc();
        #
        _const_and_export SDL_AUDIO_MASK_BITSIZE    => (0xFF);
        _const_and_export SDL_AUDIO_MASK_FLOAT      => ( 1 << 8 );
        _const_and_export SDL_AUDIO_MASK_BIG_ENDIAN => ( 1 << 12 );
        _const_and_export SDL_AUDIO_MASK_SIGNED     => ( 1 << 15 );
        _func_and_export(
            SDL_DEFINE_AUDIO_FORMAT => sub ( $signed, $bigendian, $flt, $size ) {
                ( ( ($signed) << 15 ) | ( ($bigendian) << 12 ) | ( ($flt) << 8 ) | ( ($size) & SDL_AUDIO_MASK_BITSIZE() ) )
            }
        );
        _enum_and_export SDL_AudioFormat => [
            [ SDL_AUDIO_UNKNOWN => 0x0000 ], [ SDL_AUDIO_U8    => 0x0008 ], [ SDL_AUDIO_S8    => 0x8008 ], [ SDL_AUDIO_S16LE => 0x8010 ],
            [ SDL_AUDIO_S16BE   => 0x9010 ], [ SDL_AUDIO_S32LE => 0x8020 ], [ SDL_AUDIO_S32BE => 0x9020 ], [ SDL_AUDIO_F32LE => 0x8120 ],
            [ SDL_AUDIO_F32BE   => 0x9120 ], [ SDL_AUDIO_S16   => 0x8010 ],    # Little Endian default?
            [ SDL_AUDIO_S32     => 0x8020 ], [ SDL_AUDIO_F32   => 0x8120 ]
        ];
        _func_and_export( SDL_AUDIO_BITSIZE        => sub ($x) { ( ($x) & SDL_AUDIO_MASK_BITSIZE() ) } );
        _func_and_export( SDL_AUDIO_BYTESIZE       => sub ($x) { ( SDL_AUDIO_BITSIZE($x) / 8 ) } );
        _func_and_export( SDL_AUDIO_ISFLOAT        => sub ($x) { ( ($x) & SDL_AUDIO_MASK_FLOAT() ) } );
        _func_and_export( SDL_AUDIO_ISBIGENDIAN    => sub ($x) { ( ($x) & SDL_AUDIO_MASK_BIG_ENDIAN() ) } );
        _func_and_export( SDL_AUDIO_ISLITTLEENDIAN => sub ($x) { ( !SDL_AUDIO_ISBIGENDIAN($x) ) } );
        _func_and_export( SDL_AUDIO_ISSIGNED       => sub ($x) { ( ($x) & SDL_AUDIO_MASK_SIGNED() ) } );
        _func_and_export( SDL_AUDIO_ISINT          => sub ($x) { ( !SDL_AUDIO_ISFLOAT($x) ) } );
        _func_and_export( SDL_AUDIO_ISUNSIGNED     => sub ($x) { ( !SDL_AUDIO_ISSIGNED($x) ) } );
        _typedef_and_export SDL_AudioDeviceID => UInt32;
        _const_and_export SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK  => 0xFFFFFFFF;
        _const_and_export SDL_AUDIO_DEVICE_DEFAULT_RECORDING => 0xFFFFFFFE;
        _func_and_export( SDL_AUDIO_FRAMESIZE => sub ($x) { ( SDL_AUDIO_BYTESIZE( $x->{format} ) * $x->{channels} ) } );
        _typedef_and_export SDL_AudioSpec   => Struct [ format => SDL_AudioFormat(), channels => Int, freq => Int ];
        _typedef_and_export SDL_AudioStream => Void;
        _affix_and_export SDL_GetNumAudioDrivers       => [], Int;
        _affix_and_export SDL_GetAudioDriver           => [Int], String;
        _affix_and_export SDL_GetCurrentAudioDriver    => [], String;
        _affix_and_export SDL_GetAudioPlaybackDevices  => [ Pointer [Int] ], Pointer [ SDL_AudioDeviceID() ];
        _affix_and_export SDL_GetAudioRecordingDevices => [ Pointer [Int] ], Pointer [ SDL_AudioDeviceID() ];
        _affix_and_export SDL_GetAudioDeviceName       => [ SDL_AudioDeviceID() ], String;
        _affix_and_export SDL_GetAudioDeviceFormat     => [ SDL_AudioDeviceID(), Pointer [ SDL_AudioSpec() ], Pointer [Int] ], Bool;
        _affix_and_export SDL_GetAudioDeviceChannelMap => [ SDL_AudioDeviceID(), Pointer [Int] ], Pointer [Int];
        _affix_and_export SDL_OpenAudioDevice          => [ SDL_AudioDeviceID(), Pointer [ SDL_AudioSpec() ] ], SDL_AudioDeviceID();
        _affix_and_export SDL_IsAudioDevicePhysical    => [ SDL_AudioDeviceID() ], Bool;
        _affix_and_export SDL_IsAudioDevicePlayback    => [ SDL_AudioDeviceID() ], Bool;
        _affix_and_export SDL_PauseAudioDevice         => [ SDL_AudioDeviceID() ], Bool;
        _affix_and_export SDL_ResumeAudioDevice        => [ SDL_AudioDeviceID() ], Bool;
        _affix_and_export SDL_AudioDevicePaused        => [ SDL_AudioDeviceID() ], Bool;
        _affix_and_export SDL_GetAudioDeviceGain       => [ SDL_AudioDeviceID() ], Float;
        _affix_and_export SDL_SetAudioDeviceGain       => [ SDL_AudioDeviceID(), Float ], Bool;
        _affix_and_export SDL_CloseAudioDevice         => [ SDL_AudioDeviceID() ], Void;
        _affix_and_export SDL_BindAudioStreams         => [ SDL_AudioDeviceID(), Pointer [ Pointer [ SDL_AudioStream() ] ], Int ], Bool;
        _affix_and_export SDL_BindAudioStream          => [ SDL_AudioDeviceID(), Pointer [ SDL_AudioStream() ] ], Bool;
        _affix_and_export SDL_UnbindAudioStreams       => [ Pointer [ Pointer [ SDL_AudioStream() ] ], Int ], Void;
        _affix_and_export SDL_UnbindAudioStream        => [ Pointer [ SDL_AudioStream() ] ], Void;
        _affix_and_export SDL_GetAudioStreamDevice     => [ Pointer [ SDL_AudioStream() ] ], SDL_AudioDeviceID();
        _affix_and_export
            SDL_CreateAudioStream => [ Pointer [ SDL_AudioSpec() ], Pointer [ SDL_AudioSpec() ] ],
            Pointer [ SDL_AudioStream() ];
        _affix_and_export SDL_GetAudioStreamProperties => [ Pointer [ SDL_AudioStream() ] ], SDL_PropertiesID();
        _const_and_export SDL_PROP_AUDIOSTREAM_AUTO_CLEANUP_BOOLEAN => 'SDL.audiostream.auto_cleanup';
        _affix_and_export
            SDL_GetAudioStreamFormat => [ Pointer [ SDL_AudioStream() ], Pointer [ SDL_AudioSpec() ], Pointer [ SDL_AudioSpec() ] ],
            Bool;
        _affix_and_export
            SDL_SetAudioStreamFormat => [ Pointer [ SDL_AudioStream() ], Pointer [ SDL_AudioSpec() ], Pointer [ SDL_AudioSpec() ] ],
            Bool;
        _affix_and_export SDL_GetAudioStreamFrequencyRatio   => [ Pointer [ SDL_AudioStream() ] ], Float;
        _affix_and_export SDL_SetAudioStreamFrequencyRatio   => [ Pointer [ SDL_AudioStream() ], Float ], Bool;
        _affix_and_export SDL_GetAudioStreamGain             => [ Pointer [ SDL_AudioStream() ] ], Float;
        _affix_and_export SDL_SetAudioStreamGain             => [ Pointer [ SDL_AudioStream() ], Float ], Bool;
        _affix_and_export SDL_GetAudioStreamInputChannelMap  => [ Pointer [ SDL_AudioStream() ], Pointer [Int] ], Pointer [Int];
        _affix_and_export SDL_GetAudioStreamOutputChannelMap => [ Pointer [ SDL_AudioStream() ], Pointer [Int] ], Pointer [Int];
        _affix_and_export SDL_SetAudioStreamInputChannelMap  => [ Pointer [ SDL_AudioStream() ], Pointer [Int], Int ],  Bool;
        _affix_and_export SDL_SetAudioStreamOutputChannelMap => [ Pointer [ SDL_AudioStream() ], Pointer [Int], Int ],  Bool;
        _affix_and_export SDL_PutAudioStreamData             => [ Pointer [ SDL_AudioStream() ], Pointer [Void], Int ], Bool;
        _typedef_and_export SDL_AudioStreamDataCompleteCallback => Callback [ [ Pointer [Void], Pointer [Void], Int ] => Void ];

        #~ _affix_and_export
        #~ SDL_PutAudioStreamDataNoCopy =>
        #~ [ Pointer [ SDL_AudioStream() ], Pointer [Void], Int, SDL_AudioStreamDataCompleteCallback(), Pointer [Void] ],
        #~ Bool;
        #~ _affix_and_export
        #~ SDL_PutAudioStreamPlanarData => [ Pointer [ SDL_AudioStream() ], Pointer [ Pointer [Void] ], Int, Int ],
        #~ Bool;
        _affix_and_export SDL_GetAudioStreamData      => [ Pointer [ SDL_AudioStream() ], Pointer [Void], Int ], Int;
        _affix_and_export SDL_GetAudioStreamAvailable => [ Pointer [ SDL_AudioStream() ] ], Int;
        _affix_and_export SDL_GetAudioStreamQueued    => [ Pointer [ SDL_AudioStream() ] ], Int;
        _affix_and_export SDL_FlushAudioStream        => [ Pointer [ SDL_AudioStream() ] ], Bool;
        _affix_and_export SDL_ClearAudioStream        => [ Pointer [ SDL_AudioStream() ] ], Bool;
        _affix_and_export SDL_PauseAudioStreamDevice  => [ Pointer [ SDL_AudioStream() ] ], Bool;
        _affix_and_export SDL_ResumeAudioStreamDevice => [ Pointer [ SDL_AudioStream() ] ], Bool;
        _affix_and_export SDL_AudioStreamDevicePaused => [ Pointer [ SDL_AudioStream() ] ], Bool;
        _affix_and_export SDL_LockAudioStream         => [ Pointer [ SDL_AudioStream() ] ], Bool;
        _affix_and_export SDL_UnlockAudioStream       => [ Pointer [ SDL_AudioStream() ] ], Bool;
        _typedef_and_export SDL_AudioStreamCallback => Callback [ [ Pointer [Void], Pointer [ SDL_AudioStream() ], Int, Int ] => Void ];
        _affix_and_export
            SDL_SetAudioStreamGetCallback => [ Pointer [ SDL_AudioStream() ], SDL_AudioStreamCallback(), Pointer [Void] ],
            Bool;
        _affix_and_export
            SDL_SetAudioStreamPutCallback => [ Pointer [ SDL_AudioStream() ], SDL_AudioStreamCallback(), Pointer [Void] ],
            Bool;
        _affix_and_export SDL_DestroyAudioStream => [ Pointer [ SDL_AudioStream() ] ], Void;
        _affix_and_export
            SDL_OpenAudioDeviceStream => [ SDL_AudioDeviceID(), Pointer [ SDL_AudioSpec() ], SDL_AudioStreamCallback(), Pointer [Void] ],
            Pointer [ SDL_AudioStream() ];
        _typedef_and_export SDL_AudioPostmixCallback => Callback [ [ Pointer [Void], Pointer [ SDL_AudioSpec() ], Pointer [Float], Int ] => Void ];
        _affix_and_export
            SDL_SetAudioPostmixCallback => [ SDL_AudioDeviceID(), SDL_AudioPostmixCallback(), Pointer [Void] ],
            Bool;
        _affix_and_export
            SDL_LoadWAV_IO => [ Pointer [ SDL_IOStream() ], Bool, Pointer [ SDL_AudioSpec() ], Pointer [ Pointer [UInt8] ], Pointer [UInt32] ],
            Bool;
        _affix_and_export
            SDL_LoadWAV => [ String, Pointer [ SDL_AudioSpec() ], Pointer [ Pointer [UInt8] ], Pointer [UInt32] ],
            Bool;
        _affix_and_export SDL_MixAudio => [ Pointer [UInt8], Pointer [UInt8], SDL_AudioFormat(), UInt32, Float ], Bool;
        _affix_and_export
            SDL_ConvertAudioSamples =>
            [ Pointer [ SDL_AudioSpec() ], Pointer [UInt8], Int, Pointer [ SDL_AudioSpec() ], Pointer [ Pointer [UInt8] ], Pointer [Int] ],
            Bool;
        _affix_and_export SDL_GetAudioFormatName       => [ SDL_AudioFormat() ], String;
        _affix_and_export SDL_GetSilenceValueForFormat => [ SDL_AudioFormat() ], Int;
    }

=head3 C<:bits> - CategoryBlendmode

Functions for fiddling with bits and bitmasks.

See L<SDL3: CategoryBits|https://wiki.libsdl.org/SDL3/CategoryBits>

=cut

    sub _bits() {
        state $done++ && return;

        # We don't need this... do we?
    }

=head3 C<:blendmode> - Blend modes

Blend modes decide how two colors will mix together. There are both standard modes for basic needs and a means to
create custom modes, dictating what sort of math to do on what color components.

See L<SDL3: CategoryBlendmode|https://wiki.libsdl.org/SDL3/CategoryBlendmode>

=cut

    sub _blendmode() {    # Based on sdl-main/include/sdl3/sdl_blendmode.h
        state $done++ && return;
        #
        _stdinc();
        #
        _typedef_and_export SDL_BlendMode => UInt32;
        _const_and_export SDL_BLENDMODE_NONE                => 0x00000000;
        _const_and_export SDL_BLENDMODE_BLEND               => 0x00000001;
        _const_and_export SDL_BLENDMODE_BLEND_PREMULTIPLIED => 0x00000010;
        _const_and_export SDL_BLENDMODE_ADD                 => 0x00000002;
        _const_and_export SDL_BLENDMODE_ADD_PREMULTIPLIED   => 0x00000020;
        _const_and_export SDL_BLENDMODE_MOD                 => 0x00000004;
        _const_and_export SDL_BLENDMODE_MUL                 => 0x00000008;
        _const_and_export SDL_BLENDMODE_INVALID             => 0x7FFFFFFF;
        _enum_and_export SDL_BlendOperation => [
            [ SDL_BLENDOPERATION_ADD          => 0x1 ],
            [ SDL_BLENDOPERATION_SUBTRACT     => 0x2 ],
            [ SDL_BLENDOPERATION_REV_SUBTRACT => 0x3 ],
            [ SDL_BLENDOPERATION_MINIMUM      => 0x4 ],
            [ SDL_BLENDOPERATION_MAXIMUM      => 0x5 ]
        ];
        _enum_and_export SDL_BlendFactor => [
            [ SDL_BLENDFACTOR_ZERO                => 0x1 ],
            [ SDL_BLENDFACTOR_ONE                 => 0x2 ],
            [ SDL_BLENDFACTOR_SRC_COLOR           => 0x3 ],
            [ SDL_BLENDFACTOR_ONE_MINUS_SRC_COLOR => 0x4 ],
            [ SDL_BLENDFACTOR_SRC_ALPHA           => 0x5 ],
            [ SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA => 0x6 ],
            [ SDL_BLENDFACTOR_DST_COLOR           => 0x7 ],
            [ SDL_BLENDFACTOR_ONE_MINUS_DST_COLOR => 0x8 ],
            [ SDL_BLENDFACTOR_DST_ALPHA           => 0x9 ],
            [ SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA => 0xA ]
        ];
        _affix_and_export
            SDL_ComposeCustomBlendMode =>
            [ SDL_BlendFactor(), SDL_BlendFactor(), SDL_BlendOperation(), SDL_BlendFactor(), SDL_BlendFactor(), SDL_BlendOperation() ],
            SDL_BlendMode();
    }

=head3 C<:camera> - Camera Support

Video capture for the SDL library.

See L<SDL3: CategoryCamera|https://wiki.libsdl.org/SDL3/CategoryCamera>

=cut

    sub _camera() {
        state $done++ && return;
        #
        _error();
        _pixels();
        _properties();
        _surface();
        #
        _typedef_and_export SDL_CameraID => UInt32;
        _typedef_and_export SDL_Camera   => Void;
        _typedef_and_export SDL_CameraSpec => Struct [
            format                => SDL_PixelFormat(),
            colorspace            => SDL_Colorspace(),
            width                 => Int,
            height                => Int,
            framerate_numerator   => Int,
            framerate_denominator => Int
        ];
        _enum_and_export SDL_CameraPosition =>
            [ 'SDL_CAMERA_POSITION_UNKNOWN', 'SDL_CAMERA_POSITION_FRONT_FACING', 'SDL_CAMERA_POSITION_BACK_FACING' ];
        _enum_and_export SDL_CameraPermissionState =>
            [ [ SDL_CAMERA_PERMISSION_STATE_DENIED => -1 ], 'SDL_CAMERA_PERMISSION_STATE_PENDING', 'SDL_CAMERA_PERMISSION_STATE_APPROVED' ];
        _affix_and_export SDL_GetNumCameraDrivers       => [], Int;
        _affix_and_export SDL_GetCameraDriver           => [Int], String;
        _affix_and_export SDL_GetCurrentCameraDriver    => [], String;
        _affix_and_export SDL_GetCameras                => [ Pointer [Int] ], Pointer [ SDL_CameraID() ];
        _affix_and_export SDL_GetCameraSupportedFormats => [ SDL_CameraID(), Pointer [Int] ], Pointer [ Pointer [ SDL_CameraSpec() ] ];
        _affix_and_export SDL_GetCameraName             => [ SDL_CameraID() ], String;
        _affix_and_export SDL_GetCameraPosition         => [ SDL_CameraID() ], SDL_CameraPosition();
        _affix_and_export SDL_OpenCamera                => [ SDL_CameraID(), Pointer [ SDL_CameraSpec() ] ], Pointer [ SDL_Camera() ];
        _affix_and_export SDL_GetCameraPermissionState  => [ Pointer [ SDL_Camera() ] ], SDL_CameraPermissionState();
        _affix_and_export SDL_GetCameraID               => [ Pointer [ SDL_Camera() ] ], SDL_CameraID();
        _affix_and_export SDL_GetCameraProperties       => [ Pointer [ SDL_Camera() ] ], SDL_PropertiesID();
        _affix_and_export SDL_GetCameraFormat           => [ Pointer [ SDL_Camera() ], Pointer [ SDL_CameraSpec() ] ], Bool;
        _affix_and_export SDL_AcquireCameraFrame        => [ Pointer [ SDL_Camera() ], Pointer [UInt64] ], Pointer [ SDL_Surface() ];
        _affix_and_export SDL_ReleaseCameraFrame        => [ Pointer [ SDL_Camera() ], Pointer [ SDL_Surface() ] ], Void;
        _affix_and_export SDL_CloseCamera               => [ Pointer [ SDL_Camera() ] ], Void;
    }

=head3 C<:clipboard> - Clipboard Handling

SDL provides access to the system clipboard, both for reading information from other processes and publishing
information of its own.

This is not just text! SDL apps can access and publish data by mimetype.

See L<SDL3: CategoryClipboard|https://wiki.libsdl.org/SDL3/CategoryClipboard>

=cut

    sub _clipboard() {
        state $done++ && return;
        #
        _error();
        _stdinc();
        #
        _affix_and_export SDL_SetClipboardText        => [String], Bool;
        _affix_and_export SDL_GetClipboardText        => [], String;
        _affix_and_export SDL_HasClipboardText        => [], Bool;
        _affix_and_export SDL_SetPrimarySelectionText => [String], Bool;
        _affix_and_export SDL_GetPrimarySelectionText => [], String;
        _affix_and_export SDL_HasPrimarySelectionText => [], Bool;
        _typedef_and_export SDL_ClipboardDataCallback    => Callback [ [ Pointer [Void], String, Pointer [Size_t] ] => Pointer [Void] ];
        _typedef_and_export SDL_ClipboardCleanupCallback => Callback [ [ Pointer [Void] ]                           => Void ];
        _affix_and_export
            SDL_SetClipboardData => [ SDL_ClipboardDataCallback(), SDL_ClipboardCleanupCallback(), Pointer [Void], Pointer [String], Size_t ],
            Bool;
        _affix_and_export SDL_ClearClipboardData    => [], Bool;
        _affix_and_export SDL_GetClipboardData      => [ String, Pointer [Size_t] ], Pointer [Void];
        _affix_and_export SDL_HasClipboardData      => [String], Bool;
        _affix_and_export SDL_GetClipboardMimeTypes => [ Pointer [Size_t] ], Pointer [String];
    }

=head3 C<:cpuinfo> - CPU Feature Detection

CPU feature detection for SDL.

These functions are largely concerned with reporting if the system has access to various SIMD instruction sets, but
also has other important info to share, such as system RAM size and number of logical CPU cores.

See L<SDL3: CategoryCPUInfo|https://wiki.libsdl.org/SDL3/CategoryCPUInfo>

=cut

    sub _cpuinfo() {
        state $done++ && return;
        #
        _stdinc();
        #
        _const_and_export SDL_CACHELINE_SIZE => 128;
        _affix_and_export SDL_GetNumLogicalCPUCores => [], Int;
        _affix_and_export SDL_GetCPUCacheLineSize   => [], Int;
        _affix_and_export SDL_HasAltiVec            => [], Bool;
        _affix_and_export SDL_HasMMX                => [], Bool;
        _affix_and_export SDL_HasSSE                => [], Bool;
        _affix_and_export SDL_HasSSE2               => [], Bool;
        _affix_and_export SDL_HasSSE3               => [], Bool;
        _affix_and_export SDL_HasSSE41              => [], Bool;
        _affix_and_export SDL_HasSSE42              => [], Bool;
        _affix_and_export SDL_HasAVX                => [], Bool;
        _affix_and_export SDL_HasAVX2               => [], Bool;
        _affix_and_export SDL_HasAVX512F            => [], Bool;
        _affix_and_export SDL_HasARMSIMD            => [], Bool;
        _affix_and_export SDL_HasNEON               => [], Bool;
        _affix_and_export SDL_HasLSX                => [], Bool;
        _affix_and_export SDL_HasLASX               => [], Bool;
        _affix_and_export SDL_GetSystemRAM          => [], Int;
        _affix_and_export SDL_GetSIMDAlignment      => [], Size_t;

        #~ _affix_and_export SDL_GetSystemPageSize     => [], Int;
    }

=head3 C<:dialog> - File Dialogs

File dialog support.

SDL offers file dialogs, to let users select files with native GUI interfaces. There are "open" dialogs, "save"
dialogs, and folder selection dialogs. The app can control some details, such as filtering to specific files, or
whether multiple files can be selected by the user.

Note that launching a file dialog is a non-blocking operation; control returns to the app immediately, and a callback
is called later (possibly in another thread) when the user makes a choice.

See L<SDL3: CategoryDialog|https://wiki.libsdl.org/SDL3/CategoryDialog>

=cut

    sub _dialog() {
        state $done++ && return;
        #
        _error();
        _properties();
        _video();
        #
        _typedef_and_export SDL_DialogFileFilter   => Struct [ name => String, pattern => String ];
        _typedef_and_export SDL_DialogFileCallback => Callback [ [ Pointer [Void], Pointer [String], Int ] => Void ];
        _affix_and_export
            SDL_ShowOpenFileDialog =>
            [ SDL_DialogFileCallback(), Pointer [Void], Pointer [ SDL_Window() ], Pointer [ SDL_DialogFileFilter() ], Int, String, Bool ],
            Void;
        _affix_and_export
            SDL_ShowSaveFileDialog =>
            [ SDL_DialogFileCallback(), Pointer [Void], Pointer [ SDL_Window() ], Pointer [ SDL_DialogFileFilter() ], Int, String ],
            Void;
        _affix_and_export
            SDL_ShowOpenFolderDialog => [ SDL_DialogFileCallback(), Pointer [Void], Pointer [ SDL_Window() ], String, Bool ],
            Void;
        _enum_and_export SDL_FileDialogType => [ 'SDL_FILEDIALOG_OPENFILE', 'SDL_FILEDIALOG_SAVEFILE', 'SDL_FILEDIALOG_OPENFOLDER' ];
        _affix_and_export
            SDL_ShowFileDialogWithProperties => [ SDL_FileDialogType(), SDL_DialogFileCallback(), Pointer [Void], SDL_PropertiesID() ],
            Void;
        _const_and_export SDL_PROP_FILE_DIALOG_FILTERS_POINTER => 'SDL.filedialog.filters';
        _const_and_export SDL_PROP_FILE_DIALOG_NFILTERS_NUMBER => 'SDL.filedialog.nfilters';
        _const_and_export SDL_PROP_FILE_DIALOG_WINDOW_POINTER  => 'SDL.filedialog.window';
        _const_and_export SDL_PROP_FILE_DIALOG_LOCATION_STRING => 'SDL.filedialog.location';
        _const_and_export SDL_PROP_FILE_DIALOG_MANY_BOOLEAN    => 'SDL.filedialog.many';
        _const_and_export SDL_PROP_FILE_DIALOG_TITLE_STRING    => 'SDL.filedialog.title';
        _const_and_export SDL_PROP_FILE_DIALOG_ACCEPT_STRING   => 'SDL.filedialog.accept';
        _const_and_export SDL_PROP_FILE_DIALOG_CANCEL_STRING   => 'SDL.filedialog.cancel';
    }

=head3 C<:error> - Error Handling

Simple error message routines for SDL.

Most apps will interface with these APIs in exactly one function: when almost any SDL function call reports failure,
you can get a human-readable string of the problem from L<SDL_GetError()|https://wiki.libsdl.org/SDL3/SDL_GetError>.

See L<SDL3: CategoryError|https://wiki.libsdl.org/SDL3/CategoryError>

=cut

    sub _error() {
        state $done++ && return;
        #
        _affix_and_export 'SDL_SetError',    [String] => Bool;
        _affix_and_export 'SDL_OutOfMemory', []       => Bool;
        _affix_and_export 'SDL_GetError',    []       => String;
        _affix_and_export 'SDL_ClearError',  []       => Bool;
        #
        _func_and_export( SDL_Unsupported       => sub () { SDL_SetError('That operation is not supported') } );
        _func_and_export( SDL_InvalidParamError => sub ($param) { SDL_SetError( sprintf q[Parameter '%s' is invalid], $param ) } );
    }

=head3 C<:events> - Event Handling

Event queue management.

See L<SDL3: CategoryEvents|https://wiki.libsdl.org/SDL3/CategoryEvents>

=cut

    sub _events() {
        state $done++ && return;
        _audio();
        _camera();
        _error();
        _gamepad();
        _joystick();
        _keyboard();
        _keycode();
        _mouse();
        _pen();
        _power();
        _scancode();
        _sensor();
        _stdinc();
        _touch();
        _video();
        #
        _enum_and_export SDL_EventType => [
            [ SDL_EVENT_FIRST => 0 ],          [ SDL_EVENT_QUIT => 0x100 ],      'SDL_EVENT_TERMINATING',           'SDL_EVENT_LOW_MEMORY',
            'SDL_EVENT_WILL_ENTER_BACKGROUND', 'SDL_EVENT_DID_ENTER_BACKGROUND', 'SDL_EVENT_WILL_ENTER_FOREGROUND', 'SDL_EVENT_DID_ENTER_FOREGROUND',
            'SDL_EVENT_LOCALE_CHANGED',        'SDL_EVENT_SYSTEM_THEME_CHANGED',

            # Display events
            # 0x150 was SDL_DISPLAYEVENT, reserve the number for sdl2-compat
            [ SDL_EVENT_DISPLAY_ORIENTATION => 0x151 ], 'SDL_EVENT_DISPLAY_ADDED', 'SDL_EVENT_DISPLAY_REMOVED', 'SDL_EVENT_DISPLAY_MOVED',
            'SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED',   'SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED', 'SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED',
            'SDL_EVENT_DISPLAY_USABLE_BOUNDS_CHANGED',  [ SDL_EVENT_DISPLAY_FIRST => 'SDL_EVENT_DISPLAY_ORIENTATION' ],
            [ SDL_EVENT_DISPLAY_LAST => 'SDL_EVENT_DISPLAY_USABLE_BOUNDS_CHANGED' ],

            # Window events
            # 0x200 was SDL_WINDOWEVENT, reserve the number for sdl2-compat
            # 0x201 was SDL_SYSWMEVENT, reserve the number for sdl2-compat
            [ SDL_EVENT_WINDOW_SHOWN => 0x202 ], 'SDL_EVENT_WINDOW_HIDDEN',      'SDL_EVENT_WINDOW_EXPOSED',            'SDL_EVENT_WINDOW_MOVED',
            'SDL_EVENT_WINDOW_RESIZED', 'SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED',   'SDL_EVENT_WINDOW_METAL_VIEW_RESIZED', 'SDL_EVENT_WINDOW_MINIMIZED',
            'SDL_EVENT_WINDOW_MAXIMIZED',         'SDL_EVENT_WINDOW_RESTORED',   'SDL_EVENT_WINDOW_MOUSE_ENTER',     'SDL_EVENT_WINDOW_MOUSE_LEAVE',
            'SDL_EVENT_WINDOW_FOCUS_GAINED',      'SDL_EVENT_WINDOW_FOCUS_LOST', 'SDL_EVENT_WINDOW_CLOSE_REQUESTED', 'SDL_EVENT_WINDOW_HIT_TEST',
            'SDL_EVENT_WINDOW_ICCPROF_CHANGED',   'SDL_EVENT_WINDOW_DISPLAY_CHANGED', 'SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED',
            'SDL_EVENT_WINDOW_SAFE_AREA_CHANGED', 'SDL_EVENT_WINDOW_OCCLUDED',        'SDL_EVENT_WINDOW_ENTER_FULLSCREEN',
            'SDL_EVENT_WINDOW_LEAVE_FULLSCREEN',  'SDL_EVENT_WINDOW_DESTROYED',       'SDL_EVENT_WINDOW_HDR_STATE_CHANGED',
            [ SDL_EVENT_WINDOW_FIRST => 'SDL_EVENT_WINDOW_SHOWN' ], [ SDL_EVENT_WINDOW_LAST => 'SDL_EVENT_WINDOW_HDR_STATE_CHANGED' ],

            # Keyboard events
            [ SDL_EVENT_KEY_DOWN => 0x300 ], 'SDL_EVENT_KEY_UP', 'SDL_EVENT_TEXT_EDITING', 'SDL_EVENT_TEXT_INPUT', 'SDL_EVENT_KEYMAP_CHANGED',
            'SDL_EVENT_KEYBOARD_ADDED',      'SDL_EVENT_KEYBOARD_REMOVED', 'SDL_EVENT_TEXT_EDITING_CANDIDATES', 'SDL_EVENT_SCREEN_KEYBOARD_SHOWN',
            'SDL_EVENT_SCREEN_KEYBOARD_HIDDEN',

            # Mouse events
            [ SDL_EVENT_MOUSE_MOTION => 0x400 ], 'SDL_EVENT_MOUSE_BUTTON_DOWN', 'SDL_EVENT_MOUSE_BUTTON_UP', 'SDL_EVENT_MOUSE_WHEEL',
            'SDL_EVENT_MOUSE_ADDED',             'SDL_EVENT_MOUSE_REMOVED',

            # Joystick events
            [ SDL_EVENT_JOYSTICK_AXIS_MOTION => 0x600 ], 'SDL_EVENT_JOYSTICK_BALL_MOTION', 'SDL_EVENT_JOYSTICK_HAT_MOTION',
            'SDL_EVENT_JOYSTICK_BUTTON_DOWN',            'SDL_EVENT_JOYSTICK_BUTTON_UP',   'SDL_EVENT_JOYSTICK_ADDED', 'SDL_EVENT_JOYSTICK_REMOVED',
            'SDL_EVENT_JOYSTICK_BATTERY_UPDATED',        'SDL_EVENT_JOYSTICK_UPDATE_COMPLETE',

            # Gamepad events
            [ SDL_EVENT_GAMEPAD_AXIS_MOTION => 0x650 ], 'SDL_EVENT_GAMEPAD_BUTTON_DOWN', 'SDL_EVENT_GAMEPAD_BUTTON_UP', 'SDL_EVENT_GAMEPAD_ADDED',
            'SDL_EVENT_GAMEPAD_REMOVED',     'SDL_EVENT_GAMEPAD_REMAPPED', 'SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN', 'SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION',
            'SDL_EVENT_GAMEPAD_TOUCHPAD_UP', 'SDL_EVENT_GAMEPAD_SENSOR_UPDATE', 'SDL_EVENT_GAMEPAD_UPDATE_COMPLETE',
            'SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED',

            # Touch events
            [ SDL_EVENT_FINGER_DOWN => 0x700 ], 'SDL_EVENT_FINGER_UP', 'SDL_EVENT_FINGER_MOTION', 'SDL_EVENT_FINGER_CANCELED',

            # Pinch events
            [ SDL_EVENT_PINCH_BEGIN => 0x710 ], 'SDL_EVENT_PINCH_UPDATE', 'SDL_EVENT_PINCH_END',

            # 0x800, 0x801, and 0x802 were the Gesture events from SDL2. Do not reuse these values! sdl2-compat needs them!
            # Clipboard events
            [ SDL_EVENT_CLIPBOARD_UPDATE => 0x900 ],

            # Drag and drop events
            [ SDL_EVENT_DROP_FILE => 0x1000 ], 'SDL_EVENT_DROP_TEXT', 'SDL_EVENT_DROP_BEGIN', 'SDL_EVENT_DROP_COMPLETE', 'SDL_EVENT_DROP_POSITION',

            # Audio hotplug events
            [ SDL_EVENT_AUDIO_DEVICE_ADDED => 0x1100 ], 'SDL_EVENT_AUDIO_DEVICE_REMOVED', 'SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED',

            # Sensor events
            [ SDL_EVENT_SENSOR_UPDATE => 0x1200 ],

            # Pressure-sensitive pen events
            [ SDL_EVENT_PEN_PROXIMITY_IN => 0x1300 ], 'SDL_EVENT_PEN_PROXIMITY_OUT', 'SDL_EVENT_PEN_DOWN',   'SDL_EVENT_PEN_UP',
            'SDL_EVENT_PEN_BUTTON_DOWN',              'SDL_EVENT_PEN_BUTTON_UP',     'SDL_EVENT_PEN_MOTION', 'SDL_EVENT_PEN_AXIS',

            # Camera hotplug events
            [ SDL_EVENT_CAMERA_DEVICE_ADDED => 0x1400 ], 'SDL_EVENT_CAMERA_DEVICE_REMOVED', 'SDL_EVENT_CAMERA_DEVICE_APPROVED',
            'SDL_EVENT_CAMERA_DEVICE_DENIED',

            # Render events
            [ SDL_EVENT_RENDER_TARGETS_RESET => 0x2000 ], 'SDL_EVENT_RENDER_DEVICE_RESET', 'SDL_EVENT_RENDER_DEVICE_LOST',

            # Reserved events for private platforms
            [ SDL_EVENT_PRIVATE0 => 0x4000 ], 'SDL_EVENT_PRIVATE1', 'SDL_EVENT_PRIVATE2', 'SDL_EVENT_PRIVATE3',

            # Internal events
            [ SDL_EVENT_POLL_SENTINEL => 0x7F00 ],

            # Events SDL_EVENT_USER through SDL_EVENT_LAST are for your use,
            # and should be allocated with SDL_RegisterEvents()
            [ SDL_EVENT_USER => 0x8000 ],

            # This last event is only for bounding internal arrays
            [ SDL_EVENT_LAST => 0xFFFF ],

            # This just makes sure the enum is the size of Uint32
            [ SDL_EVENT_ENUM_PADDING => 0x7FFFFFFF ]
        ];
        _typedef_and_export SDL_CommonEvent => Struct [ type => UInt32, reserved => UInt32, timestamp => UInt64 ];
        _typedef_and_export SDL_DisplayEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            displayID => SDL_DisplayID(),
            data1     => SInt32,
            data2     => SInt32
        ];
        _typedef_and_export SDL_WindowEvent =>
            Struct [ type => SDL_EventType(), reserved => UInt32, timestamp => UInt64, windowID => SDL_WindowID(), data1 => SInt32, data2 => SInt32 ];
        _typedef_and_export SDL_KeyboardDeviceEvent =>
            Struct [ type => SDL_EventType(), reserved => UInt32, timestamp => UInt64, which => SDL_KeyboardID() ];
        _typedef_and_export SDL_KeyboardEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            windowID  => SDL_WindowID(),
            which     => SDL_KeyboardID(),
            scancode  => SDL_Scancode(),
            key       => SDL_Keycode(),
            mod       => SDL_Keymod(),
            raw       => UInt16,
            down      => Bool,
            repeat    => Bool
        ];
        _typedef_and_export SDL_TextEditingEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            windowID  => SDL_WindowID(),
            text      => String,
            start     => SInt32,
            length    => SInt32
        ];
        _typedef_and_export SDL_TextEditingCandidatesEvent => Struct [
            type               => SDL_EventType(),
            reserved           => UInt32,
            timestamp          => UInt64,
            windowID           => SDL_WindowID(),
            candidates         => Pointer [String],
            num_candidates     => SInt32,
            selected_candidate => SInt32,
            horizontal         => Bool,
            padding1           => UInt8,
            padding2           => UInt8,
            padding3           => UInt8
        ];
        _typedef_and_export SDL_TextInputEvent =>
            Struct [ type => SDL_EventType(), reserved => UInt32, timestamp => UInt64, windowID => SDL_WindowID(), text => String ];
        _typedef_and_export SDL_MouseDeviceEvent =>
            Struct [ type => SDL_EventType(), reserved => UInt32, timestamp => UInt64, which => SDL_MouseID() ];
        _typedef_and_export SDL_MouseMotionEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            windowID  => SDL_WindowID(),
            which     => SDL_MouseID(),
            state     => SDL_MouseButtonFlags(),
            x         => Float,
            y         => Float,
            xrel      => Float,
            yrel      => Float
        ];
        _typedef_and_export SDL_MouseButtonEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            windowID  => SDL_WindowID(),
            which     => SDL_MouseID(),
            button    => UInt8,
            down      => Bool,
            clicks    => UInt8,
            padding   => UInt8,
            x         => Float,
            y         => Float
        ];
        _typedef_and_export SDL_MouseWheelEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            windowID  => SDL_WindowID(),
            which     => SDL_MouseID(),
            x         => Float,
            y         => Float,
            direction => SDL_MouseWheelDirection(),
            mouse_x   => Float,
            mouse_y   => Float,
            integer_x => SInt32,
            integer_y => SInt32
        ];
        _typedef_and_export SDL_JoyAxisEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            which     => SDL_JoystickID(),
            axis      => UInt8,
            padding1  => UInt8,
            padding2  => UInt8,
            padding3  => UInt8,
            value     => SInt16,
            padding4  => UInt16
        ];
        _typedef_and_export SDL_JoyBallEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            which     => SDL_JoystickID(),
            ball      => UInt8,
            padding1  => UInt8,
            padding2  => UInt8,
            padding3  => UInt8,
            xrel      => SInt16,
            yrel      => SInt16
        ];
        _typedef_and_export SDL_JoyHatEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            which     => SDL_JoystickID(),
            hat       => UInt8,
            value     => UInt8,
            padding1  => UInt8,
            padding2  => UInt8
        ];
        _typedef_and_export SDL_JoyButtonEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            which     => SDL_JoystickID(),
            button    => UInt8,
            down      => Bool,
            padding1  => UInt8,
            padding2  => UInt8
        ];
        _typedef_and_export SDL_JoyDeviceEvent =>
            Struct [ type => SDL_EventType(), reserved => UInt32, timestamp => UInt64, which => SDL_JoystickID() ];
        _typedef_and_export SDL_JoyBatteryEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            which     => SDL_JoystickID(),
            state     => SDL_PowerState(),
            percent   => Int
        ];
        _typedef_and_export SDL_GamepadAxisEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            which     => SDL_JoystickID(),
            axis      => UInt8,
            padding1  => UInt8,
            padding2  => UInt8,
            padding3  => UInt8,
            value     => SInt16,
            padding4  => UInt16
        ];
        _typedef_and_export SDL_GamepadButtonEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            which     => SDL_JoystickID(),
            button    => UInt8,
            down      => Bool,
            padding1  => UInt8,
            padding2  => UInt8
        ];
        _typedef_and_export SDL_GamepadDeviceEvent =>
            Struct [ type => SDL_EventType(), reserved => UInt32, timestamp => UInt64, which => SDL_JoystickID() ];
        _typedef_and_export SDL_GamepadTouchpadEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            which     => SDL_JoystickID(),
            touchpad  => SInt32,
            finger    => SInt32,
            x         => Float,
            y         => Float,
            pressure  => Float
        ];
        _typedef_and_export SDL_GamepadSensorEvent => Struct [
            type             => SDL_EventType(),
            reserved         => UInt32,
            timestamp        => UInt64,
            which            => SDL_JoystickID(),
            sensor           => SInt32,
            data             => Array [ Float, 3 ],
            sensor_timestamp => UInt64
        ];
        _typedef_and_export SDL_AudioDeviceEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            which     => SDL_AudioDeviceID(),
            recording => Bool,
            padding1  => UInt8,
            padding2  => UInt8,
            padding3  => UInt8
        ];
        _typedef_and_export SDL_CameraDeviceEvent =>
            Struct [ type => SDL_EventType(), reserved => UInt32, timestamp => UInt64, which => SDL_CameraID() ];
        _typedef_and_export SDL_RenderEvent =>
            Struct [ type => SDL_EventType(), reserved => UInt32, timestamp => UInt64, windowID => SDL_WindowID() ];
        _typedef_and_export SDL_TouchFingerEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            touchID   => SDL_TouchID(),
            fingerID  => SDL_FingerID(),
            x         => Float,
            y         => Float,
            dx        => Float,
            dy        => Float,
            pressure  => Float,
            windowID  => SDL_WindowID()
        ];
        _typedef_and_export SDL_PinchFingerEvent =>
            Struct [ type => SDL_EventType(), reserved => UInt32, timestamp => UInt64, scale => Float, windowID => SDL_WindowID() ];
        _typedef_and_export SDL_PenProximityEvent =>
            Struct [ type => SDL_EventType(), reserved => UInt32, timestamp => UInt64, windowID => SDL_WindowID(), which => SDL_PenID() ];
        _typedef_and_export SDL_PenMotionEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            windowID  => SDL_WindowID(),
            which     => SDL_PenID(),
            pen_state => SDL_PenInputFlags(),
            x         => Float,
            y         => Float
        ];
        _typedef_and_export SDL_PenTouchEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            windowID  => SDL_WindowID(),
            which     => SDL_PenID(),
            pen_state => SDL_PenInputFlags(),
            x         => Float,
            y         => Float,
            eraser    => Bool,
            down      => Bool
        ];
        _typedef_and_export SDL_PenButtonEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            windowID  => SDL_WindowID(),
            which     => SDL_PenID(),
            pen_state => SDL_PenInputFlags(),
            x         => Float,
            y         => Float,
            button    => UInt8,
            down      => Bool
        ];
        _typedef_and_export SDL_PenAxisEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            windowID  => SDL_WindowID(),
            which     => SDL_PenID(),
            pen_state => SDL_PenInputFlags(),
            x         => Float,
            y         => Float,
            axis      => SDL_PenAxis(),
            value     => Float
        ];
        _typedef_and_export SDL_DropEvent => Struct [
            type      => SDL_EventType(),
            reserved  => UInt32,
            timestamp => UInt64,
            windowID  => SDL_WindowID(),
            x         => Float,
            y         => Float,
            source    => String,
            data      => String
        ];
        _typedef_and_export SDL_ClipboardEvent => Struct [
            type           => SDL_EventType(),
            reserved       => UInt32,
            timestamp      => UInt64,
            owner          => Bool,
            num_mime_types => SInt32,
            mime_types     => Pointer [String]
        ];
        _typedef_and_export SDL_SensorEvent => Struct [
            type             => SDL_EventType(),
            reserved         => UInt32,
            timestamp        => UInt64,
            which            => SDL_SensorID(),
            data             => Array [ Float, 6 ],
            sensor_timestamp => UInt64
        ];
        _typedef_and_export SDL_QuitEvent => Struct [ type => SDL_EventType(), reserved => UInt32, timestamp => UInt64 ];
        _typedef_and_export SDL_UserEvent => Struct [
            type      => UInt32,
            reserved  => UInt32,
            timestamp => UInt64,
            windowID  => SDL_WindowID(),
            code      => SInt32,
            data1     => Pointer [Void],
            data2     => Pointer [Void]
        ];
        _typedef_and_export SDL_Event => Union [
            type            => UInt32,
            common          => SDL_CommonEvent(),
            display         => SDL_DisplayEvent(),
            window          => SDL_WindowEvent(),
            kdevice         => SDL_KeyboardDeviceEvent(),
            key             => SDL_KeyboardEvent(),
            edit            => SDL_TextEditingEvent(),
            edit_candidates => SDL_TextEditingCandidatesEvent(),
            text            => SDL_TextInputEvent(),
            mdevice         => SDL_MouseDeviceEvent(),
            motion          => SDL_MouseMotionEvent(),
            button          => SDL_MouseButtonEvent(),
            wheel           => SDL_MouseWheelEvent(),
            jdevice         => SDL_JoyDeviceEvent(),
            jaxis           => SDL_JoyAxisEvent(),
            jball           => SDL_JoyBallEvent(),
            jhat            => SDL_JoyHatEvent(),
            jbutton         => SDL_JoyButtonEvent(),
            jbattery        => SDL_JoyBatteryEvent(),
            gdevice         => SDL_GamepadDeviceEvent(),
            gaxis           => SDL_GamepadAxisEvent(),
            gbutton         => SDL_GamepadButtonEvent(),
            gtouchpad       => SDL_GamepadTouchpadEvent(),
            gsensor         => SDL_GamepadSensorEvent(),
            adevice         => SDL_AudioDeviceEvent(),
            cdevice         => SDL_CameraDeviceEvent(),
            sensor          => SDL_SensorEvent(),
            quit            => SDL_QuitEvent(),
            user            => SDL_UserEvent(),
            tfinger         => SDL_TouchFingerEvent(),
            pinch           => SDL_PinchFingerEvent(),
            pproximity      => SDL_PenProximityEvent(),
            ptouch          => SDL_PenTouchEvent(),
            pmotion         => SDL_PenMotionEvent(),
            pbutton         => SDL_PenButtonEvent(),
            paxis           => SDL_PenAxisEvent(),
            render          => SDL_RenderEvent(),
            drop            => SDL_DropEvent(),
            clipboard       => SDL_ClipboardEvent(),
            padding         => Array [ UInt8, 128 ]
        ];
        _affix_and_export SDL_PumpEvents => [], Void;
        _enum_and_export SDL_EventAction => [ 'SDL_ADDEVENT', 'SDL_PEEKEVENT', 'SDL_GETEVENT' ];
        _affix_and_export SDL_PeepEvents       => [ Pointer [ SDL_Event() ], Int, SDL_EventAction(), UInt32, UInt32 ], Int;
        _affix_and_export SDL_HasEvent         => [UInt32], Bool;
        _affix_and_export SDL_HasEvents        => [ UInt32, UInt32 ], Bool;
        _affix_and_export SDL_FlushEvent       => [UInt32], Void;
        _affix_and_export SDL_FlushEvents      => [ UInt32, UInt32 ], Void;
        _affix_and_export SDL_PollEvent        => [ Pointer [ SDL_Event() ] ], Bool;
        _affix_and_export SDL_WaitEvent        => [ Pointer [ SDL_Event() ] ], Bool;
        _affix_and_export SDL_WaitEventTimeout => [ Pointer [ SDL_Event() ], SInt32 ], Bool;
        _affix_and_export SDL_PushEvent        => [ Pointer [ SDL_Event() ] ], Bool;
        _typedef_and_export SDL_EventFilter => Callback [ [ Pointer [Void], Pointer [ SDL_Event() ] ] => Bool ];
        _affix_and_export SDL_SetEventFilter     => [ SDL_EventFilter(), Pointer [Void] ], Void;
        _affix_and_export SDL_GetEventFilter     => [ Pointer [ SDL_EventFilter() ], Pointer [ Pointer [Void] ] ], Bool;
        _affix_and_export SDL_AddEventWatch      => [ SDL_EventFilter(), Pointer [Void] ], Bool;
        _affix_and_export SDL_RemoveEventWatch   => [ SDL_EventFilter(), Pointer [Void] ], Void;
        _affix_and_export SDL_FilterEvents       => [ SDL_EventFilter(), Pointer [Void] ], Void;
        _affix_and_export SDL_SetEventEnabled    => [ UInt32, Bool ], Void;
        _affix_and_export SDL_EventEnabled       => [UInt32], Bool;
        _affix_and_export SDL_RegisterEvents     => [Int],    UInt32;
        _affix_and_export SDL_GetWindowFromEvent => [ Pointer [ SDL_Event() ] ], Pointer [ SDL_Window() ];

        #~ _affix_and_export SDL_GetEventDescription => [ Pointer [ SDL_Event() ], String, Int ], Int;
    }

=head3 C<:filesystem> - Filesystem Access

SDL offers an API for examining and manipulating the system's filesystem. This covers most things one would need to do
with directories, except for actual file I/O.

See L<SDL3: CategoryFilesystem|https://wiki.libsdl.org/SDL3/CategoryFilesystem>

=cut

    sub _filesystem() {
        state $done++ && return;
        #
        _error();
        _stdinc();
        #
        _affix_and_export SDL_GetBasePath => [], String;
        _affix_and_export SDL_GetPrefPath => [ String, String ], String;
        _enum_and_export SDL_Folder => [
            'SDL_FOLDER_HOME',        'SDL_FOLDER_DESKTOP',   'SDL_FOLDER_DOCUMENTS',   'SDL_FOLDER_DOWNLOADS',
            'SDL_FOLDER_MUSIC',       'SDL_FOLDER_PICTURES',  'SDL_FOLDER_PUBLICSHARE', 'SDL_FOLDER_SAVEDGAMES',
            'SDL_FOLDER_SCREENSHOTS', 'SDL_FOLDER_TEMPLATES', 'SDL_FOLDER_VIDEOS',      'SDL_FOLDER_COUNT'
        ];
        _affix_and_export SDL_GetUserFolder => [ SDL_Folder() ], String;
        _enum_and_export SDL_PathType => [ 'SDL_PATHTYPE_NONE', 'SDL_PATHTYPE_FILE', 'SDL_PATHTYPE_DIRECTORY', 'SDL_PATHTYPE_OTHER' ];
        _typedef_and_export SDL_PathInfo => Struct [
            type        => SDL_PathType(),
            size        => UInt64,
            create_time => SInt64,           # SDL_Time
            modify_time => SInt64,
            access_time => SInt64
        ];
        _typedef_and_export SDL_GlobFlags => UInt32;
        _const_and_export SDL_GLOB_CASEINSENSITIVE => ( 1 << 0 );
        _affix_and_export SDL_CreateDirectory => [String], Bool;
        _enum_and_export SDL_EnumerationResult => [ 'SDL_ENUM_CONTINUE', 'SDL_ENUM_SUCCESS', 'SDL_ENUM_FAILURE' ];
        _typedef_and_export SDL_EnumerateDirectoryCallback => Callback [ [ Pointer [Void], String, String ] => SDL_EnumerationResult() ];
        _affix_and_export
            SDL_EnumerateDirectory => [ String, SDL_EnumerateDirectoryCallback(), Pointer [Void] ],
            Bool;
        _affix_and_export SDL_RemovePath  => [String], Bool;
        _affix_and_export SDL_RenamePath  => [ String, String ], Bool;
        _affix_and_export SDL_CopyFile    => [ String, String ], Bool;
        _affix_and_export SDL_GetPathInfo => [ String, Pointer [ SDL_PathInfo() ] ], Bool;
        _affix_and_export
            SDL_GlobDirectory => [ String, String, SDL_GlobFlags(), Pointer [Int] ],
            Pointer [String];
        _affix_and_export SDL_GetCurrentDirectory => [], String;
    }

=head3 C<:gamepad> - Gamepad Support

SDL provides a low-level joystick API, which just treats joysticks as an arbitrary pile of buttons, axes, and hat
switches. If you're planning to write your own control configuration screen, this can give you a lot of flexibility,
but that's a lot of work, and most things that we consider "joysticks" now are actually console-style gamepads. So SDL
provides the gamepad API on top of the lower-level joystick functionality.

See L<SDL3: CategoryGamepad|https://wiki.libsdl.org/SDL3/CategoryGamepad>

=cut

    sub _gamepad() {
        state $done++ && return;
        #
        _error();
        _guid();
        _iostream();
        _joystick();
        _power();
        _properties();
        _sensor();
        _stdinc();
        #
        _typedef_and_export SDL_Gamepad => Void;
        _enum_and_export SDL_GamepadType => [
            'SDL_GAMEPAD_TYPE_UNKNOWN',                     'SDL_GAMEPAD_TYPE_STANDARD',
            'SDL_GAMEPAD_TYPE_XBOX360',                     'SDL_GAMEPAD_TYPE_XBOXONE',
            'SDL_GAMEPAD_TYPE_PS3',                         'SDL_GAMEPAD_TYPE_PS4',
            'SDL_GAMEPAD_TYPE_PS5',                         'SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_PRO',
            'SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_JOYCON_LEFT', 'SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_JOYCON_RIGHT',
            'SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_JOYCON_PAIR', 'SDL_GAMEPAD_TYPE_GAMECUBE',
            'SDL_GAMEPAD_TYPE_COUNT'
        ];
        _enum_and_export SDL_GamepadButton => [
            [ SDL_GAMEPAD_BUTTON_INVALID => -1 ], 'SDL_GAMEPAD_BUTTON_SOUTH',
            'SDL_GAMEPAD_BUTTON_EAST',            'SDL_GAMEPAD_BUTTON_WEST',
            'SDL_GAMEPAD_BUTTON_NORTH',           'SDL_GAMEPAD_BUTTON_BACK',
            'SDL_GAMEPAD_BUTTON_GUIDE',           'SDL_GAMEPAD_BUTTON_START',
            'SDL_GAMEPAD_BUTTON_LEFT_STICK',      'SDL_GAMEPAD_BUTTON_RIGHT_STICK',
            'SDL_GAMEPAD_BUTTON_LEFT_SHOULDER',   'SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER',
            'SDL_GAMEPAD_BUTTON_DPAD_UP',         'SDL_GAMEPAD_BUTTON_DPAD_DOWN',
            'SDL_GAMEPAD_BUTTON_DPAD_LEFT',       'SDL_GAMEPAD_BUTTON_DPAD_RIGHT',
            'SDL_GAMEPAD_BUTTON_MISC1',           'SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1',
            'SDL_GAMEPAD_BUTTON_LEFT_PADDLE1',    'SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2',
            'SDL_GAMEPAD_BUTTON_LEFT_PADDLE2',    'SDL_GAMEPAD_BUTTON_TOUCHPAD',
            'SDL_GAMEPAD_BUTTON_MISC2',           'SDL_GAMEPAD_BUTTON_MISC3',
            'SDL_GAMEPAD_BUTTON_MISC4',           'SDL_GAMEPAD_BUTTON_MISC5',
            'SDL_GAMEPAD_BUTTON_MISC6',           'SDL_GAMEPAD_BUTTON_COUNT'
        ];
        _enum_and_export SDL_GamepadButtonLabel => [
            'SDL_GAMEPAD_BUTTON_LABEL_UNKNOWN', 'SDL_GAMEPAD_BUTTON_LABEL_A',
            'SDL_GAMEPAD_BUTTON_LABEL_B',       'SDL_GAMEPAD_BUTTON_LABEL_X',
            'SDL_GAMEPAD_BUTTON_LABEL_Y',       'SDL_GAMEPAD_BUTTON_LABEL_CROSS',
            'SDL_GAMEPAD_BUTTON_LABEL_CIRCLE',  'SDL_GAMEPAD_BUTTON_LABEL_SQUARE',
            'SDL_GAMEPAD_BUTTON_LABEL_TRIANGLE'
        ];
        _enum_and_export SDL_GamepadAxis => [
            [ SDL_GAMEPAD_AXIS_INVALID => -1 ], 'SDL_GAMEPAD_AXIS_LEFTX',
            'SDL_GAMEPAD_AXIS_LEFTY',           'SDL_GAMEPAD_AXIS_RIGHTX',
            'SDL_GAMEPAD_AXIS_RIGHTY',          'SDL_GAMEPAD_AXIS_LEFT_TRIGGER',
            'SDL_GAMEPAD_AXIS_RIGHT_TRIGGER',   'SDL_GAMEPAD_AXIS_COUNT'
        ];
        _enum_and_export SDL_GamepadBindingType =>
            [ 'SDL_GAMEPAD_BINDTYPE_NONE', 'SDL_GAMEPAD_BINDTYPE_BUTTON', 'SDL_GAMEPAD_BINDTYPE_AXIS', 'SDL_GAMEPAD_BINDTYPE_HAT' ];
        _typedef_and_export SDL_GamepadBinding => Struct [
            input_type => SDL_GamepadBindingType(),
            input      => Union [
                button => Int,
                axis   => Struct [ axis => Int, axis_min => Int, axis_max => Int ],
                hat    => Struct [ hat  => Int, hat_mask => Int ]
            ],
            output_type => SDL_GamepadBindingType(),
            output      => Union [ button => SDL_GamepadButton(), axis => Struct [ axis => SDL_GamepadAxis(), axis_min => Int, axis_max => Int ] ]
        ];
        _affix_and_export SDL_AddGamepadMapping             => [String], Int;
        _affix_and_export SDL_AddGamepadMappingsFromIO      => [ Pointer [ SDL_IOStream() ], Bool ], Int;
        _affix_and_export SDL_AddGamepadMappingsFromFile    => [String], Int;
        _affix_and_export SDL_ReloadGamepadMappings         => [], Bool;
        _affix_and_export SDL_GetGamepadMappings            => [ Pointer [Int] ], Pointer [String];
        _affix_and_export SDL_GetGamepadMappingForGUID      => [ SDL_GUID() ], String;
        _affix_and_export SDL_GetGamepadMapping             => [ Pointer [ SDL_Gamepad() ] ], String;
        _affix_and_export SDL_SetGamepadMapping             => [ SDL_JoystickID(), String ], Bool;
        _affix_and_export SDL_HasGamepad                    => [], Bool;
        _affix_and_export SDL_GetGamepads                   => [ Pointer [Int] ], Pointer [ SDL_JoystickID() ];
        _affix_and_export SDL_IsGamepad                     => [ SDL_JoystickID() ], Bool;
        _affix_and_export SDL_GetGamepadNameForID           => [ SDL_JoystickID() ], String;
        _affix_and_export SDL_GetGamepadPathForID           => [ SDL_JoystickID() ], String;
        _affix_and_export SDL_GetGamepadPlayerIndexForID    => [ SDL_JoystickID() ], Int;
        _affix_and_export SDL_GetGamepadGUIDForID           => [ SDL_JoystickID() ], SDL_GUID();
        _affix_and_export SDL_GetGamepadVendorForID         => [ SDL_JoystickID() ], UInt16;
        _affix_and_export SDL_GetGamepadProductForID        => [ SDL_JoystickID() ], UInt16;
        _affix_and_export SDL_GetGamepadProductVersionForID => [ SDL_JoystickID() ], UInt16;
        _affix_and_export SDL_GetGamepadTypeForID           => [ SDL_JoystickID() ], SDL_GamepadType();
        _affix_and_export SDL_GetRealGamepadTypeForID       => [ SDL_JoystickID() ], SDL_GamepadType();
        _affix_and_export SDL_GetGamepadMappingForID        => [ SDL_JoystickID() ], String;
        _affix_and_export SDL_OpenGamepad                   => [ SDL_JoystickID() ], Pointer [ SDL_Gamepad() ];
        _affix_and_export SDL_GetGamepadFromID              => [ SDL_JoystickID() ], Pointer [ SDL_Gamepad() ];
        _affix_and_export SDL_GetGamepadFromPlayerIndex     => [Int], Pointer [ SDL_Gamepad() ];
        _affix_and_export SDL_GetGamepadProperties          => [ Pointer [ SDL_Gamepad() ] ], SDL_PropertiesID();
        _const_and_export SDL_PROP_GAMEPAD_CAP_MONO_LED_BOOLEAN       => 'SDL.joystick.cap.mono_led';
        _const_and_export SDL_PROP_GAMEPAD_CAP_RGB_LED_BOOLEAN        => 'SDL.joystick.cap.rgb_led';
        _const_and_export SDL_PROP_GAMEPAD_CAP_PLAYER_LED_BOOLEAN     => 'SDL.joystick.cap.player_led';
        _const_and_export SDL_PROP_GAMEPAD_CAP_RUMBLE_BOOLEAN         => 'SDL.joystick.cap.rumble';
        _const_and_export SDL_PROP_GAMEPAD_CAP_TRIGGER_RUMBLE_BOOLEAN => 'SDL.joystick.cap.trigger_rumble';
        _affix_and_export SDL_GetGamepadID              => [ Pointer [ SDL_Gamepad() ] ], SDL_JoystickID();
        _affix_and_export SDL_GetGamepadName            => [ Pointer [ SDL_Gamepad() ] ], String;
        _affix_and_export SDL_GetGamepadPath            => [ Pointer [ SDL_Gamepad() ] ], String;
        _affix_and_export SDL_GetGamepadType            => [ Pointer [ SDL_Gamepad() ] ], SDL_GamepadType();
        _affix_and_export SDL_GetRealGamepadType        => [ Pointer [ SDL_Gamepad() ] ], SDL_GamepadType();
        _affix_and_export SDL_GetGamepadPlayerIndex     => [ Pointer [ SDL_Gamepad() ] ], Int;
        _affix_and_export SDL_SetGamepadPlayerIndex     => [ Pointer [ SDL_Gamepad() ], Int ], Bool;
        _affix_and_export SDL_GetGamepadVendor          => [ Pointer [ SDL_Gamepad() ] ], UInt16;
        _affix_and_export SDL_GetGamepadProduct         => [ Pointer [ SDL_Gamepad() ] ], UInt16;
        _affix_and_export SDL_GetGamepadProductVersion  => [ Pointer [ SDL_Gamepad() ] ], UInt16;
        _affix_and_export SDL_GetGamepadFirmwareVersion => [ Pointer [ SDL_Gamepad() ] ], UInt16;
        _affix_and_export SDL_GetGamepadSerial          => [ Pointer [ SDL_Gamepad() ] ], String;
        _affix_and_export SDL_GetGamepadSteamHandle     => [ Pointer [ SDL_Gamepad() ] ], UInt64;
        _affix_and_export SDL_GetGamepadConnectionState => [ Pointer [ SDL_Gamepad() ] ], SDL_JoystickConnectionState();
        _affix_and_export SDL_GetGamepadPowerInfo       => [ Pointer [ SDL_Gamepad() ], Pointer [Int] ], SDL_PowerState();
        _affix_and_export SDL_GamepadConnected          => [ Pointer [ SDL_Gamepad() ] ], Bool;
        _affix_and_export SDL_GetGamepadJoystick        => [ Pointer [ SDL_Gamepad() ] ], Pointer [ SDL_Joystick() ];
        _affix_and_export SDL_SetGamepadEventsEnabled   => [Bool], Void;
        _affix_and_export SDL_GamepadEventsEnabled      => [], Bool;
        _affix_and_export
            SDL_GetGamepadBindings => [ Pointer [ SDL_Gamepad() ], Pointer [Int] ],
            Pointer [ Pointer [ SDL_GamepadBinding() ] ];
        _affix_and_export SDL_UpdateGamepads               => [], Void;
        _affix_and_export SDL_GetGamepadTypeFromString     => [String], SDL_GamepadType();
        _affix_and_export SDL_GetGamepadStringForType      => [ SDL_GamepadType() ], String;
        _affix_and_export SDL_GetGamepadAxisFromString     => [String], SDL_GamepadAxis();
        _affix_and_export SDL_GetGamepadStringForAxis      => [ SDL_GamepadAxis() ], String;
        _affix_and_export SDL_GamepadHasAxis               => [ Pointer [ SDL_Gamepad() ], SDL_GamepadAxis() ], Bool;
        _affix_and_export SDL_GetGamepadAxis               => [ Pointer [ SDL_Gamepad() ], SDL_GamepadAxis() ], SInt16;
        _affix_and_export SDL_GetGamepadButtonFromString   => [String], SDL_GamepadButton();
        _affix_and_export SDL_GetGamepadStringForButton    => [ SDL_GamepadButton() ], String;
        _affix_and_export SDL_GamepadHasButton             => [ Pointer [ SDL_Gamepad() ], SDL_GamepadButton() ], Bool;
        _affix_and_export SDL_GetGamepadButton             => [ Pointer [ SDL_Gamepad() ], SDL_GamepadButton() ], Bool;
        _affix_and_export SDL_GetGamepadButtonLabelForType => [ SDL_GamepadType(), SDL_GamepadButton() ], SDL_GamepadButtonLabel();
        _affix_and_export SDL_GetGamepadButtonLabel        => [ Pointer [ SDL_Gamepad() ], SDL_GamepadButton() ], SDL_GamepadButtonLabel();
        _affix_and_export SDL_GetNumGamepadTouchpads       => [ Pointer [ SDL_Gamepad() ] ], Int;
        _affix_and_export SDL_GetNumGamepadTouchpadFingers => [ Pointer [ SDL_Gamepad() ], Int ], Int;
        _affix_and_export
            SDL_GetGamepadTouchpadFinger =>
            [ Pointer [ SDL_Gamepad() ], Int, Int, Pointer [Bool], Pointer [Float], Pointer [Float], Pointer [Float] ],
            Bool;
        _affix_and_export SDL_GamepadHasSensor                      => [ Pointer [ SDL_Gamepad() ], SDL_SensorType() ], Bool;
        _affix_and_export SDL_SetGamepadSensorEnabled               => [ Pointer [ SDL_Gamepad() ], SDL_SensorType(), Bool ], Bool;
        _affix_and_export SDL_GamepadSensorEnabled                  => [ Pointer [ SDL_Gamepad() ], SDL_SensorType() ], Bool;
        _affix_and_export SDL_GetGamepadSensorDataRate              => [ Pointer [ SDL_Gamepad() ], SDL_SensorType() ], Float;
        _affix_and_export SDL_GetGamepadSensorData                  => [ Pointer [ SDL_Gamepad() ], SDL_SensorType(), Pointer [Float], Int ], Bool;
        _affix_and_export SDL_RumbleGamepad                         => [ Pointer [ SDL_Gamepad() ], UInt16, UInt16, UInt32 ], Bool;
        _affix_and_export SDL_RumbleGamepadTriggers                 => [ Pointer [ SDL_Gamepad() ], UInt16, UInt16, UInt32 ], Bool;
        _affix_and_export SDL_SetGamepadLED                         => [ Pointer [ SDL_Gamepad() ], UInt8, UInt8, UInt8 ],    Bool;
        _affix_and_export SDL_SendGamepadEffect                     => [ Pointer [ SDL_Gamepad() ], Pointer [Void], Int ], Bool;
        _affix_and_export SDL_CloseGamepad                          => [ Pointer [ SDL_Gamepad() ] ], Void;
        _affix_and_export SDL_GetGamepadAppleSFSymbolsNameForButton => [ Pointer [ SDL_Gamepad() ], SDL_GamepadButton() ], String;
        _affix_and_export SDL_GetGamepadAppleSFSymbolsNameForAxis   => [ Pointer [ SDL_Gamepad() ], SDL_GamepadAxis() ],   String;
    }

=head3 C<:gpu> - 3D Rendering and GPU Compute

The GPU API offers a cross-platform way for apps to talk to modern graphics hardware. It offers both 3D graphics and
compute support, in the style of Metal, Vulkan, and Direct3D 12.

See L<SDL3: CategoryGPU|https://wiki.libsdl.org/SDL3/CategoryGPU>

=cut

    sub _gpu() {
        state $done++ && return;
        #
        _pixels();
        _properties();
        _rect();
        _stdinc();
        _surface();
        _video();
        #
        _typedef_and_export SDL_GPUDevice           => Void;
        _typedef_and_export SDL_GPUBuffer           => Void;
        _typedef_and_export SDL_GPUTransferBuffer   => Void;
        _typedef_and_export SDL_GPUTexture          => Void;
        _typedef_and_export SDL_GPUSampler          => Void;
        _typedef_and_export SDL_GPUShader           => Void;
        _typedef_and_export SDL_GPUComputePipeline  => Void;
        _typedef_and_export SDL_GPUGraphicsPipeline => Void;
        _typedef_and_export SDL_GPUCommandBuffer    => Void;
        _typedef_and_export SDL_GPURenderPass       => Void;
        _typedef_and_export SDL_GPUComputePass      => Void;
        _typedef_and_export SDL_GPUCopyPass         => Void;
        _typedef_and_export SDL_GPUFence            => Void;
        _enum_and_export SDL_GPUPrimitiveType => [
            'SDL_GPU_PRIMITIVETYPE_TRIANGLELIST', 'SDL_GPU_PRIMITIVETYPE_TRIANGLESTRIP',
            'SDL_GPU_PRIMITIVETYPE_LINELIST',     'SDL_GPU_PRIMITIVETYPE_LINESTRIP',
            'SDL_GPU_PRIMITIVETYPE_POINTLIST'
        ];
        _enum_and_export SDL_GPULoadOp => [ 'SDL_GPU_LOADOP_LOAD', 'SDL_GPU_LOADOP_CLEAR', 'SDL_GPU_LOADOP_DONT_CARE' ];
        _enum_and_export SDL_GPUStoreOp =>
            [ 'SDL_GPU_STOREOP_STORE', 'SDL_GPU_STOREOP_DONT_CARE', 'SDL_GPU_STOREOP_RESOLVE', 'SDL_GPU_STOREOP_RESOLVE_AND_STORE' ];
        _enum_and_export SDL_GPUIndexElementSize => [ 'SDL_GPU_INDEXELEMENTSIZE_16BIT', 'SDL_GPU_INDEXELEMENTSIZE_32BIT' ];
        _enum_and_export SDL_GPUTextureFormat => [
            'SDL_GPU_TEXTUREFORMAT_INVALID',               'SDL_GPU_TEXTUREFORMAT_A8_UNORM',
            'SDL_GPU_TEXTUREFORMAT_R8_UNORM',              'SDL_GPU_TEXTUREFORMAT_R8G8_UNORM',
            'SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM',        'SDL_GPU_TEXTUREFORMAT_R16_UNORM',
            'SDL_GPU_TEXTUREFORMAT_R16G16_UNORM',          'SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UNORM',
            'SDL_GPU_TEXTUREFORMAT_R10G10B10A2_UNORM',     'SDL_GPU_TEXTUREFORMAT_B5G6R5_UNORM',
            'SDL_GPU_TEXTUREFORMAT_B5G5R5A1_UNORM',        'SDL_GPU_TEXTUREFORMAT_B4G4R4A4_UNORM',
            'SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM',        'SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM',
            'SDL_GPU_TEXTUREFORMAT_BC2_RGBA_UNORM',        'SDL_GPU_TEXTUREFORMAT_BC3_RGBA_UNORM',
            'SDL_GPU_TEXTUREFORMAT_BC4_R_UNORM',           'SDL_GPU_TEXTUREFORMAT_BC5_RG_UNORM',
            'SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM',        'SDL_GPU_TEXTUREFORMAT_BC6H_RGB_FLOAT',
            'SDL_GPU_TEXTUREFORMAT_BC6H_RGB_UFLOAT',       'SDL_GPU_TEXTUREFORMAT_R8_SNORM',
            'SDL_GPU_TEXTUREFORMAT_R8G8_SNORM',            'SDL_GPU_TEXTUREFORMAT_R8G8B8A8_SNORM',
            'SDL_GPU_TEXTUREFORMAT_R16_SNORM',             'SDL_GPU_TEXTUREFORMAT_R16G16_SNORM',
            'SDL_GPU_TEXTUREFORMAT_R16G16B16A16_SNORM',    'SDL_GPU_TEXTUREFORMAT_R16_FLOAT',
            'SDL_GPU_TEXTUREFORMAT_R16G16_FLOAT',          'SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT',
            'SDL_GPU_TEXTUREFORMAT_R32_FLOAT',             'SDL_GPU_TEXTUREFORMAT_R32G32_FLOAT',
            'SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT',    'SDL_GPU_TEXTUREFORMAT_R11G11B10_UFLOAT',
            'SDL_GPU_TEXTUREFORMAT_R8_UINT',               'SDL_GPU_TEXTUREFORMAT_R8G8_UINT',
            'SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UINT',         'SDL_GPU_TEXTUREFORMAT_R16_UINT',
            'SDL_GPU_TEXTUREFORMAT_R16G16_UINT',           'SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UINT',
            'SDL_GPU_TEXTUREFORMAT_R32_UINT',              'SDL_GPU_TEXTUREFORMAT_R32G32_UINT',
            'SDL_GPU_TEXTUREFORMAT_R32G32B32A32_UINT',     'SDL_GPU_TEXTUREFORMAT_R8_INT',
            'SDL_GPU_TEXTUREFORMAT_R8G8_INT',              'SDL_GPU_TEXTUREFORMAT_R8G8B8A8_INT',
            'SDL_GPU_TEXTUREFORMAT_R16_INT',               'SDL_GPU_TEXTUREFORMAT_R16G16_INT',
            'SDL_GPU_TEXTUREFORMAT_R16G16B16A16_INT',      'SDL_GPU_TEXTUREFORMAT_R32_INT',
            'SDL_GPU_TEXTUREFORMAT_R32G32_INT',            'SDL_GPU_TEXTUREFORMAT_R32G32B32A32_INT',
            'SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB',   'SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB',
            'SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM_SRGB',   'SDL_GPU_TEXTUREFORMAT_BC2_RGBA_UNORM_SRGB',
            'SDL_GPU_TEXTUREFORMAT_BC3_RGBA_UNORM_SRGB',   'SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM_SRGB',
            'SDL_GPU_TEXTUREFORMAT_D16_UNORM',             'SDL_GPU_TEXTUREFORMAT_D24_UNORM',
            'SDL_GPU_TEXTUREFORMAT_D32_FLOAT',             'SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT',
            'SDL_GPU_TEXTUREFORMAT_D32_FLOAT_S8_UINT',     'SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM',
            'SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM',        'SDL_GPU_TEXTUREFORMAT_ASTC_5x5_UNORM',
            'SDL_GPU_TEXTUREFORMAT_ASTC_6x5_UNORM',        'SDL_GPU_TEXTUREFORMAT_ASTC_6x6_UNORM',
            'SDL_GPU_TEXTUREFORMAT_ASTC_8x5_UNORM',        'SDL_GPU_TEXTUREFORMAT_ASTC_8x6_UNORM',
            'SDL_GPU_TEXTUREFORMAT_ASTC_8x8_UNORM',        'SDL_GPU_TEXTUREFORMAT_ASTC_10x5_UNORM',
            'SDL_GPU_TEXTUREFORMAT_ASTC_10x6_UNORM',       'SDL_GPU_TEXTUREFORMAT_ASTC_10x8_UNORM',
            'SDL_GPU_TEXTUREFORMAT_ASTC_10x10_UNORM',      'SDL_GPU_TEXTUREFORMAT_ASTC_12x10_UNORM',
            'SDL_GPU_TEXTUREFORMAT_ASTC_12x12_UNORM',      'SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM_SRGB',
            'SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM_SRGB',   'SDL_GPU_TEXTUREFORMAT_ASTC_5x5_UNORM_SRGB',
            'SDL_GPU_TEXTUREFORMAT_ASTC_6x5_UNORM_SRGB',   'SDL_GPU_TEXTUREFORMAT_ASTC_6x6_UNORM_SRGB',
            'SDL_GPU_TEXTUREFORMAT_ASTC_8x5_UNORM_SRGB',   'SDL_GPU_TEXTUREFORMAT_ASTC_8x6_UNORM_SRGB',
            'SDL_GPU_TEXTUREFORMAT_ASTC_8x8_UNORM_SRGB',   'SDL_GPU_TEXTUREFORMAT_ASTC_10x5_UNORM_SRGB',
            'SDL_GPU_TEXTUREFORMAT_ASTC_10x6_UNORM_SRGB',  'SDL_GPU_TEXTUREFORMAT_ASTC_10x8_UNORM_SRGB',
            'SDL_GPU_TEXTUREFORMAT_ASTC_10x10_UNORM_SRGB', 'SDL_GPU_TEXTUREFORMAT_ASTC_12x10_UNORM_SRGB',
            'SDL_GPU_TEXTUREFORMAT_ASTC_12x12_UNORM_SRGB', 'SDL_GPU_TEXTUREFORMAT_ASTC_4x4_FLOAT',
            'SDL_GPU_TEXTUREFORMAT_ASTC_5x4_FLOAT',        'SDL_GPU_TEXTUREFORMAT_ASTC_5x5_FLOAT',
            'SDL_GPU_TEXTUREFORMAT_ASTC_6x5_FLOAT',        'SDL_GPU_TEXTUREFORMAT_ASTC_6x6_FLOAT',
            'SDL_GPU_TEXTUREFORMAT_ASTC_8x5_FLOAT',        'SDL_GPU_TEXTUREFORMAT_ASTC_8x6_FLOAT',
            'SDL_GPU_TEXTUREFORMAT_ASTC_8x8_FLOAT',        'SDL_GPU_TEXTUREFORMAT_ASTC_10x5_FLOAT',
            'SDL_GPU_TEXTUREFORMAT_ASTC_10x6_FLOAT',       'SDL_GPU_TEXTUREFORMAT_ASTC_10x8_FLOAT',
            'SDL_GPU_TEXTUREFORMAT_ASTC_10x10_FLOAT',      'SDL_GPU_TEXTUREFORMAT_ASTC_12x10_FLOAT',
            'SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT'
        ];
        _typedef_and_export SDL_GPUTextureUsageFlags => UInt32;
        _const_and_export SDL_GPU_TEXTUREUSAGE_SAMPLER                                 => ( 1 << 0 );
        _const_and_export SDL_GPU_TEXTUREUSAGE_COLOR_TARGET                            => ( 1 << 1 );
        _const_and_export SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET                    => ( 1 << 2 );
        _const_and_export SDL_GPU_TEXTUREUSAGE_GRAPHICS_STORAGE_READ                   => ( 1 << 3 );
        _const_and_export SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ                    => ( 1 << 4 );
        _const_and_export SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE                   => ( 1 << 5 );
        _const_and_export SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE => ( 1 << 6 );
        _enum_and_export SDL_GPUTextureType => [
            'SDL_GPU_TEXTURETYPE_2D', 'SDL_GPU_TEXTURETYPE_2D_ARRAY', 'SDL_GPU_TEXTURETYPE_3D', 'SDL_GPU_TEXTURETYPE_CUBE',
            'SDL_GPU_TEXTURETYPE_CUBE_ARRAY'
        ];
        _enum_and_export SDL_GPUSampleCount => [ 'SDL_GPU_SAMPLECOUNT_1', 'SDL_GPU_SAMPLECOUNT_2', 'SDL_GPU_SAMPLECOUNT_4', 'SDL_GPU_SAMPLECOUNT_8' ];
        _enum_and_export SDL_GPUCubeMapFace => [
            'SDL_GPU_CUBEMAPFACE_POSITIVEX', 'SDL_GPU_CUBEMAPFACE_NEGATIVEX', 'SDL_GPU_CUBEMAPFACE_POSITIVEY', 'SDL_GPU_CUBEMAPFACE_NEGATIVEY',
            'SDL_GPU_CUBEMAPFACE_POSITIVEZ', 'SDL_GPU_CUBEMAPFACE_NEGATIVEZ'
        ];
        _typedef_and_export SDL_GPUBufferUsageFlags => UInt32;
        _const_and_export SDL_GPU_BUFFERUSAGE_VERTEX                => ( 1 << 0 );
        _const_and_export SDL_GPU_BUFFERUSAGE_INDEX                 => ( 1 << 1 );
        _const_and_export SDL_GPU_BUFFERUSAGE_INDIRECT              => ( 1 << 2 );
        _const_and_export SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ => ( 1 << 3 );
        _const_and_export SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ  => ( 1 << 4 );
        _const_and_export SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE => ( 1 << 5 );
        _enum_and_export SDL_GPUTransferBufferUsage => [ 'SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD', 'SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD' ];
        _enum_and_export SDL_GPUShaderStage         => [ 'SDL_GPU_SHADERSTAGE_VERTEX',         'SDL_GPU_SHADERSTAGE_FRAGMENT' ];
        _typedef_and_export SDL_GPUShaderFormat => UInt32;
        _const_and_export SDL_GPU_SHADERFORMAT_INVALID  => 0;
        _const_and_export SDL_GPU_SHADERFORMAT_PRIVATE  => ( 1 << 0 );
        _const_and_export SDL_GPU_SHADERFORMAT_SPIRV    => ( 1 << 1 );
        _const_and_export SDL_GPU_SHADERFORMAT_DXBC     => ( 1 << 2 );
        _const_and_export SDL_GPU_SHADERFORMAT_DXIL     => ( 1 << 3 );
        _const_and_export SDL_GPU_SHADERFORMAT_MSL      => ( 1 << 4 );
        _const_and_export SDL_GPU_SHADERFORMAT_METALLIB => ( 1 << 5 );
        _enum_and_export SDL_GPUVertexElementFormat => [
            'SDL_GPU_VERTEXELEMENTFORMAT_INVALID',      'SDL_GPU_VERTEXELEMENTFORMAT_INT',
            'SDL_GPU_VERTEXELEMENTFORMAT_INT2',         'SDL_GPU_VERTEXELEMENTFORMAT_INT3',
            'SDL_GPU_VERTEXELEMENTFORMAT_INT4',         'SDL_GPU_VERTEXELEMENTFORMAT_UINT',
            'SDL_GPU_VERTEXELEMENTFORMAT_UINT2',        'SDL_GPU_VERTEXELEMENTFORMAT_UINT3',
            'SDL_GPU_VERTEXELEMENTFORMAT_UINT4',        'SDL_GPU_VERTEXELEMENTFORMAT_FLOAT',
            'SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2',       'SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3',
            'SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4',       'SDL_GPU_VERTEXELEMENTFORMAT_BYTE2',
            'SDL_GPU_VERTEXELEMENTFORMAT_BYTE4',        'SDL_GPU_VERTEXELEMENTFORMAT_UBYTE2',
            'SDL_GPU_VERTEXELEMENTFORMAT_UBYTE4',       'SDL_GPU_VERTEXELEMENTFORMAT_BYTE2_NORM',
            'SDL_GPU_VERTEXELEMENTFORMAT_BYTE4_NORM',   'SDL_GPU_VERTEXELEMENTFORMAT_UBYTE2_NORM',
            'SDL_GPU_VERTEXELEMENTFORMAT_UBYTE4_NORM',  'SDL_GPU_VERTEXELEMENTFORMAT_SHORT2',
            'SDL_GPU_VERTEXELEMENTFORMAT_SHORT4',       'SDL_GPU_VERTEXELEMENTFORMAT_USHORT2',
            'SDL_GPU_VERTEXELEMENTFORMAT_USHORT4',      'SDL_GPU_VERTEXELEMENTFORMAT_SHORT2_NORM',
            'SDL_GPU_VERTEXELEMENTFORMAT_SHORT4_NORM',  'SDL_GPU_VERTEXELEMENTFORMAT_USHORT2_NORM',
            'SDL_GPU_VERTEXELEMENTFORMAT_USHORT4_NORM', 'SDL_GPU_VERTEXELEMENTFORMAT_HALF2',
            'SDL_GPU_VERTEXELEMENTFORMAT_HALF4'
        ];
        _enum_and_export SDL_GPUVertexInputRate => [ 'SDL_GPU_VERTEXINPUTRATE_VERTEX',      'SDL_GPU_VERTEXINPUTRATE_INSTANCE' ];
        _enum_and_export SDL_GPUFillMode        => [ 'SDL_GPU_FILLMODE_FILL',               'SDL_GPU_FILLMODE_LINE' ];
        _enum_and_export SDL_GPUCullMode        => [ 'SDL_GPU_CULLMODE_NONE',               'SDL_GPU_CULLMODE_FRONT', 'SDL_GPU_CULLMODE_BACK' ];
        _enum_and_export SDL_GPUFrontFace       => [ 'SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE', 'SDL_GPU_FRONTFACE_CLOCKWISE' ];
        _enum_and_export SDL_GPUCompareOp => [
            'SDL_GPU_COMPAREOP_INVALID',       'SDL_GPU_COMPAREOP_NEVER',
            'SDL_GPU_COMPAREOP_LESS',          'SDL_GPU_COMPAREOP_EQUAL',
            'SDL_GPU_COMPAREOP_LESS_OR_EQUAL', 'SDL_GPU_COMPAREOP_GREATER',
            'SDL_GPU_COMPAREOP_NOT_EQUAL',     'SDL_GPU_COMPAREOP_GREATER_OR_EQUAL',
            'SDL_GPU_COMPAREOP_ALWAYS'
        ];
        _enum_and_export SDL_GPUStencilOp => [
            'SDL_GPU_STENCILOP_INVALID',             'SDL_GPU_STENCILOP_KEEP',
            'SDL_GPU_STENCILOP_ZERO',                'SDL_GPU_STENCILOP_REPLACE',
            'SDL_GPU_STENCILOP_INCREMENT_AND_CLAMP', 'SDL_GPU_STENCILOP_DECREMENT_AND_CLAMP',
            'SDL_GPU_STENCILOP_INVERT',              'SDL_GPU_STENCILOP_INCREMENT_AND_WRAP',
            'SDL_GPU_STENCILOP_DECREMENT_AND_WRAP'
        ];
        _enum_and_export SDL_GPUBlendOp => [
            'SDL_GPU_BLENDOP_INVALID', 'SDL_GPU_BLENDOP_ADD', 'SDL_GPU_BLENDOP_SUBTRACT', 'SDL_GPU_BLENDOP_REVERSE_SUBTRACT',
            'SDL_GPU_BLENDOP_MIN',     'SDL_GPU_BLENDOP_MAX'
        ];
        _enum_and_export SDL_GPUBlendFactor => [
            'SDL_GPU_BLENDFACTOR_INVALID',                  'SDL_GPU_BLENDFACTOR_ZERO',
            'SDL_GPU_BLENDFACTOR_ONE',                      'SDL_GPU_BLENDFACTOR_SRC_COLOR',
            'SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_COLOR',      'SDL_GPU_BLENDFACTOR_DST_COLOR',
            'SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_COLOR',      'SDL_GPU_BLENDFACTOR_SRC_ALPHA',
            'SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA',      'SDL_GPU_BLENDFACTOR_DST_ALPHA',
            'SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_ALPHA',      'SDL_GPU_BLENDFACTOR_CONSTANT_COLOR',
            'SDL_GPU_BLENDFACTOR_ONE_MINUS_CONSTANT_COLOR', 'SDL_GPU_BLENDFACTOR_SRC_ALPHA_SATURATE'
        ];
        _typedef_and_export SDL_GPUColorComponentFlags => UInt8;
        _const_and_export SDL_GPU_COLORCOMPONENT_R => ( 1 << 0 );
        _const_and_export SDL_GPU_COLORCOMPONENT_G => ( 1 << 1 );
        _const_and_export SDL_GPU_COLORCOMPONENT_B => ( 1 << 2 );
        _const_and_export SDL_GPU_COLORCOMPONENT_A => ( 1 << 3 );
        _enum_and_export SDL_GPUFilter            => [ 'SDL_GPU_FILTER_NEAREST',            'SDL_GPU_FILTER_LINEAR' ];
        _enum_and_export SDL_GPUSamplerMipmapMode => [ 'SDL_GPU_SAMPLERMIPMAPMODE_NEAREST', 'SDL_GPU_SAMPLERMIPMAPMODE_LINEAR' ];
        _enum_and_export SDL_GPUSamplerAddressMode =>
            [ 'SDL_GPU_SAMPLERADDRESSMODE_REPEAT', 'SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT', 'SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE' ];
        _enum_and_export SDL_GPUPresentMode => [ 'SDL_GPU_PRESENTMODE_VSYNC', 'SDL_GPU_PRESENTMODE_IMMEDIATE', 'SDL_GPU_PRESENTMODE_MAILBOX' ];
        _enum_and_export SDL_GPUSwapchainComposition => [
            'SDL_GPU_SWAPCHAINCOMPOSITION_SDR',                 'SDL_GPU_SWAPCHAINCOMPOSITION_SDR_LINEAR',
            'SDL_GPU_SWAPCHAINCOMPOSITION_HDR_EXTENDED_LINEAR', 'SDL_GPU_SWAPCHAINCOMPOSITION_HDR10_ST2084'
        ];
        _typedef_and_export SDL_GPUViewport => Struct [ x => Float, y => Float, w => Float, h => Float, min_depth => Float, max_depth => Float ];
        _typedef_and_export SDL_GPUTextureTransferInfo =>
            Struct [ transfer_buffer => Pointer [ SDL_GPUTransferBuffer() ], offset => UInt32, pixels_per_row => UInt32, rows_per_layer => UInt32 ];
        _typedef_and_export SDL_GPUTransferBufferLocation => Struct [ transfer_buffer => Pointer [ SDL_GPUTransferBuffer() ], offset => UInt32 ];
        _typedef_and_export SDL_GPUTextureLocation =>
            Struct [ texture => Pointer [ SDL_GPUTexture() ], mip_level => UInt32, layer => UInt32, x => UInt32, y => UInt32, z => UInt32 ];
        _typedef_and_export SDL_GPUTextureRegion => Struct [
            texture   => Pointer [ SDL_GPUTexture() ],
            mip_level => UInt32,
            layer     => UInt32,
            x         => UInt32,
            y         => UInt32,
            z         => UInt32,
            w         => UInt32,
            h         => UInt32,
            d         => UInt32
        ];
        _typedef_and_export SDL_GPUBlitRegion => Struct [
            texture              => Pointer [ SDL_GPUTexture() ],
            mip_level            => UInt32,
            layer_or_depth_plane => UInt32,
            x                    => UInt32,
            y                    => UInt32,
            w                    => UInt32,
            h                    => UInt32
        ];
        _typedef_and_export SDL_GPUBufferLocation => Struct [ buffer => Pointer [ SDL_GPUBuffer() ], offset => UInt32 ];
        _typedef_and_export SDL_GPUBufferRegion => Struct [ buffer => Pointer [ SDL_GPUBuffer() ], offset => UInt32, size => UInt32 ];
        _typedef_and_export SDL_GPUIndirectDrawCommand =>
            Struct [ num_vertices => UInt32, num_instances => UInt32, first_vertex => UInt32, first_instance => UInt32 ];
        _typedef_and_export SDL_GPUIndexedIndirectDrawCommand =>
            Struct [ num_indices => UInt32, num_instances => UInt32, first_index => UInt32, vertex_offset => SInt32, first_instance => UInt32 ];
        _typedef_and_export SDL_GPUIndirectDispatchCommand => Struct [ groupcount_x => UInt32, groupcount_y => UInt32, groupcount_z => UInt32 ];
        _typedef_and_export SDL_GPUSamplerCreateInfo => Struct [
            min_filter        => SDL_GPUFilter(),
            mag_filter        => SDL_GPUFilter(),
            mipmap_mode       => SDL_GPUSamplerMipmapMode(),
            address_mode_u    => SDL_GPUSamplerAddressMode(),
            address_mode_v    => SDL_GPUSamplerAddressMode(),
            address_mode_w    => SDL_GPUSamplerAddressMode(),
            mip_lod_bias      => Float,
            max_anisotropy    => Float,
            compare_op        => SDL_GPUCompareOp(),
            min_lod           => Float,
            max_lod           => Float,
            enable_anisotropy => Bool,
            enable_compare    => Bool,
            padding1          => UInt8,
            padding2          => UInt8,
            props             => SDL_PropertiesID()
        ];
        _typedef_and_export SDL_GPUVertexBufferDescription =>
            Struct [ slot => UInt32, pitch => UInt32, input_rate => SDL_GPUVertexInputRate(), instance_step_rate => UInt32 ];
        _typedef_and_export SDL_GPUVertexAttribute =>
            Struct [ location => UInt32, buffer_slot => UInt32, format => SDL_GPUVertexElementFormat(), offset => UInt32 ];
        _typedef_and_export SDL_GPUVertexInputState => Struct [
            vertex_buffer_descriptions => Pointer [ SDL_GPUVertexBufferDescription() ],
            num_vertex_buffers         => UInt32,
            vertex_attributes          => Pointer [ SDL_GPUVertexAttribute() ],
            num_vertex_attributes      => UInt32
        ];
        _typedef_and_export SDL_GPUStencilOpState => Struct [
            fail_op       => SDL_GPUStencilOp(),
            pass_op       => SDL_GPUStencilOp(),
            depth_fail_op => SDL_GPUStencilOp(),
            compare_op    => SDL_GPUCompareOp()
        ];
        _typedef_and_export SDL_GPUColorTargetBlendState => Struct [
            src_color_blendfactor   => SDL_GPUBlendFactor(),
            dst_color_blendfactor   => SDL_GPUBlendFactor(),
            color_blend_op          => SDL_GPUBlendOp(),
            src_alpha_blendfactor   => SDL_GPUBlendFactor(),
            dst_alpha_blendfactor   => SDL_GPUBlendFactor(),
            alpha_blend_op          => SDL_GPUBlendOp(),
            color_write_mask        => SDL_GPUColorComponentFlags(),
            enable_blend            => Bool,
            enable_color_write_mask => Bool,
            padding1                => UInt8,
            padding2                => UInt8
        ];
        _typedef_and_export SDL_GPUShaderCreateInfo => Struct [
            code_size            => Size_t,
            code                 => Pointer [UInt8],
            entrypoint           => String,
            format               => SDL_GPUShaderFormat(),
            stage                => SDL_GPUShaderStage(),
            num_samplers         => UInt32,
            num_storage_textures => UInt32,
            num_storage_buffers  => UInt32,
            num_uniform_buffers  => UInt32,
            props                => SDL_PropertiesID()
        ];
        _typedef_and_export SDL_GPUTextureCreateInfo => Struct [
            type                 => SDL_GPUTextureType(),
            format               => SDL_GPUTextureFormat(),
            usage                => SDL_GPUTextureUsageFlags(),
            width                => UInt32,
            height               => UInt32,
            layer_count_or_depth => UInt32,
            num_levels           => UInt32,
            sample_count         => SDL_GPUSampleCount(),
            props                => SDL_PropertiesID()
        ];
        _typedef_and_export SDL_GPUBufferCreateInfo => Struct [ usage => SDL_GPUBufferUsageFlags(), size => UInt32, props => SDL_PropertiesID() ];
        _typedef_and_export SDL_GPUTransferBufferCreateInfo =>
            Struct [ usage => SDL_GPUTransferBufferUsage(), size => UInt32, props => SDL_PropertiesID() ];
        _typedef_and_export SDL_GPURasterizerState => Struct [
            fill_mode                  => SDL_GPUFillMode(),
            cull_mode                  => SDL_GPUCullMode(),
            front_face                 => SDL_GPUFrontFace(),
            depth_bias_constant_factor => Float,
            depth_bias_clamp           => Float,
            depth_bias_slope_factor    => Float,
            enable_depth_bias          => Bool,
            enable_depth_clip          => Bool,
            padding1                   => UInt8,
            padding2                   => UInt8
        ];
        _typedef_and_export SDL_GPUMultisampleState => Struct [
            sample_count             => SDL_GPUSampleCount(),
            sample_mask              => UInt32,
            enable_mask              => Bool,
            enable_alpha_to_coverage => Bool,
            padding2                 => UInt8,
            padding3                 => UInt8
        ];
        _typedef_and_export SDL_GPUDepthStencilState => Struct [
            compare_op          => SDL_GPUCompareOp(),
            back_stencil_state  => SDL_GPUStencilOpState(),
            front_stencil_state => SDL_GPUStencilOpState(),
            compare_mask        => UInt8,
            write_mask          => UInt8,
            enable_depth_test   => Bool,
            enable_depth_write  => Bool,
            enable_stencil_test => Bool,
            padding1            => UInt8,
            padding2            => UInt8,
            padding3            => UInt8
        ];
        _typedef_and_export SDL_GPUColorTargetDescription =>
            Struct [ format => SDL_GPUTextureFormat(), blend_state => SDL_GPUColorTargetBlendState() ];
        _typedef_and_export SDL_GPUGraphicsPipelineTargetInfo => Struct [
            color_target_descriptions => Pointer [ SDL_GPUColorTargetDescription() ],
            num_color_targets         => UInt32,
            depth_stencil_format      => SDL_GPUTextureFormat(),
            has_depth_stencil_target  => Bool,
            padding1                  => UInt8,
            padding2                  => UInt8,
            padding3                  => UInt8
        ];
        _typedef_and_export SDL_GPUGraphicsPipelineCreateInfo => Struct [
            vertex_shader       => Pointer [ SDL_GPUShader() ],
            fragment_shader     => Pointer [ SDL_GPUShader() ],
            vertex_input_state  => SDL_GPUVertexInputState(),
            primitive_type      => SDL_GPUPrimitiveType(),
            rasterizer_state    => SDL_GPURasterizerState(),
            multisample_state   => SDL_GPUMultisampleState(),
            depth_stencil_state => SDL_GPUDepthStencilState(),
            target_info         => SDL_GPUGraphicsPipelineTargetInfo(),
            props               => SDL_PropertiesID()
        ];
        _typedef_and_export SDL_GPUComputePipelineCreateInfo => Struct [
            code_size                      => Size_t,
            code                           => Pointer [UInt8],
            entrypoint                     => String,
            format                         => SDL_GPUShaderFormat(),
            num_samplers                   => UInt32,
            num_readonly_storage_textures  => UInt32,
            num_readonly_storage_buffers   => UInt32,
            num_readwrite_storage_textures => UInt32,
            num_readwrite_storage_buffers  => UInt32,
            num_uniform_buffers            => UInt32,
            threadcount_x                  => UInt32,
            threadcount_y                  => UInt32,
            threadcount_z                  => UInt32,
            props                          => SDL_PropertiesID()
        ];
        _typedef_and_export SDL_GPUColorTargetInfo => Struct [
            texture               => Pointer [ SDL_GPUTexture() ],
            mip_level             => UInt32,
            layer_or_depth_plane  => UInt32,
            clear_color           => SDL_FColor(),
            load_op               => SDL_GPULoadOp(),
            store_op              => SDL_GPUStoreOp(),
            resolve_texture       => Pointer [ SDL_GPUTexture() ],
            resolve_mip_level     => UInt32,
            resolve_layer         => UInt32,
            cycle                 => Bool,
            cycle_resolve_texture => Bool,
            padding1              => UInt8,
            padding2              => UInt8
        ];
        _typedef_and_export SDL_GPUDepthStencilTargetInfo => Struct [
            texture          => Pointer [ SDL_GPUTexture() ],
            clear_depth      => Float,
            load_op          => SDL_GPULoadOp(),
            store_op         => SDL_GPUStoreOp(),
            stencil_load_op  => SDL_GPULoadOp(),
            stencil_store_op => SDL_GPUStoreOp(),
            cycle            => Bool,
            clear_stencil    => UInt8,
            mip_level        => UInt8,
            layer            => UInt8
        ];
        _typedef_and_export SDL_GPUBlitInfo => Struct [
            source      => SDL_GPUBlitRegion(),
            destination => SDL_GPUBlitRegion(),
            load_op     => SDL_GPULoadOp(),
            clear_color => SDL_FColor(),
            flip_mode   => SDL_FlipMode(),
            filter      => SDL_GPUFilter(),
            cycle       => Bool,
            padding1    => UInt8,
            padding2    => UInt8,
            padding3    => UInt8
        ];
        _typedef_and_export SDL_GPUBufferBinding => Struct [ buffer => Pointer [ SDL_GPUBuffer() ], offset => UInt32 ];
        _typedef_and_export SDL_GPUTextureSamplerBinding =>
            Struct [ texture => Pointer [ SDL_GPUTexture() ], sampler => Pointer [ SDL_GPUSampler() ] ];
        _typedef_and_export SDL_GPUStorageBufferReadWriteBinding =>
            Struct [ buffer => Pointer [ SDL_GPUBuffer() ], cycle => Bool, padding1 => UInt8, padding2 => UInt8, padding3 => UInt8 ];
        _typedef_and_export SDL_GPUStorageTextureReadWriteBinding => Struct [
            texture   => Pointer [ SDL_GPUTexture() ],
            mip_level => UInt32,
            layer     => UInt32,
            cycle     => Bool,
            padding1  => UInt8,
            padding2  => UInt8,
            padding3  => UInt8
        ];
        _affix_and_export SDL_GPUSupportsShaderFormats      => [ SDL_GPUShaderFormat(), String ], Bool;
        _affix_and_export SDL_GPUSupportsProperties         => [ SDL_PropertiesID() ], Bool;
        _affix_and_export SDL_CreateGPUDevice               => [ SDL_GPUShaderFormat(), Bool, String ], Pointer [ SDL_GPUDevice() ];
        _affix_and_export SDL_CreateGPUDeviceWithProperties => [ SDL_PropertiesID() ], Pointer [ SDL_GPUDevice() ];
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_DEBUGMODE_BOOLEAN              => 'SDL.gpu.device.create.debugmode';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_PREFERLOWPOWER_BOOLEAN         => 'SDL.gpu.device.create.preferlowpower';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_VERBOSE_BOOLEAN                => 'SDL.gpu.device.create.verbose';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_NAME_STRING                    => 'SDL.gpu.device.create.name';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_FEATURE_CLIP_DISTANCE_BOOLEAN  => 'SDL.gpu.device.create.feature.clip_distance';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_FEATURE_DEPTH_CLAMPING_BOOLEAN => 'SDL.gpu.device.create.feature.depth_clamping';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_FEATURE_INDIRECT_DRAW_FIRST_INSTANCE_BOOLEAN =>
            'SDL.gpu.device.create.feature.indirect_draw_first_instance';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_FEATURE_ANISOTROPY_BOOLEAN => 'SDL.gpu.device.create.feature.anisotropy';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_SHADERS_PRIVATE_BOOLEAN    => 'SDL.gpu.device.create.shaders.private';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_SHADERS_SPIRV_BOOLEAN      => 'SDL.gpu.device.create.shaders.spirv';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_SHADERS_DXBC_BOOLEAN       => 'SDL.gpu.device.create.shaders.dxbc';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_SHADERS_DXIL_BOOLEAN       => 'SDL.gpu.device.create.shaders.dxil';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_SHADERS_MSL_BOOLEAN        => 'SDL.gpu.device.create.shaders.msl';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_SHADERS_METALLIB_BOOLEAN   => 'SDL.gpu.device.create.shaders.metallib';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_D3D12_ALLOW_FEWER_RESOURCE_SLOTS_BOOLEAN =>
            'SDL.gpu.device.create.d3d12.allowtier1resourcebinding';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_D3D12_SEMANTIC_NAME_STRING => 'SDL.gpu.device.create.d3d12.semantic';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_VULKAN_REQUIRE_HARDWARE_ACCELERATION_BOOLEAN =>
            'SDL.gpu.device.create.vulkan.requirehardwareacceleration';
        _const_and_export SDL_PROP_GPU_DEVICE_CREATE_VULKAN_OPTIONS_POINTER => 'SDL.gpu.device.create.vulkan.options';
        _typedef_and_export SDL_GPUVulkanOptions => Struct [
            vulkan_api_version                 => UInt32,
            feature_list                       => Pointer [Void],
            vulkan_10_physical_device_features => Pointer [Void],
            device_extension_count             => UInt32,
            device_extension_names             => Pointer [String],
            instance_extension_count           => UInt32,
            instance_extension_names           => Pointer [String]
        ];
        _affix_and_export SDL_DestroyGPUDevice    => [ Pointer [ SDL_GPUDevice() ] ], Void;
        _affix_and_export SDL_GetNumGPUDrivers    => [], Int;
        _affix_and_export SDL_GetGPUDriver        => [Int], String;
        _affix_and_export SDL_GetGPUDeviceDriver  => [ Pointer [ SDL_GPUDevice() ] ], String;
        _affix_and_export SDL_GetGPUShaderFormats => [ Pointer [ SDL_GPUDevice() ] ], SDL_GPUShaderFormat();

        #~ _affix_and_export SDL_GetGPUDeviceProperties => [ Pointer [ SDL_GPUDevice() ] ], SDL_PropertiesID();
        _const_and_export SDL_PROP_GPU_DEVICE_NAME_STRING           => 'SDL.gpu.device.name';
        _const_and_export SDL_PROP_GPU_DEVICE_DRIVER_NAME_STRING    => 'SDL.gpu.device.driver_name';
        _const_and_export SDL_PROP_GPU_DEVICE_DRIVER_VERSION_STRING => 'SDL.gpu.device.driver_version';
        _const_and_export SDL_PROP_GPU_DEVICE_DRIVER_INFO_STRING    => 'SDL.gpu.device.driver_info';
        _affix_and_export
            SDL_CreateGPUComputePipeline => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUComputePipelineCreateInfo() ] ],
            Pointer [ SDL_GPUComputePipeline() ];
        _const_and_export SDL_PROP_GPU_COMPUTEPIPELINE_CREATE_NAME_STRING => 'SDL.gpu.computepipeline.create.name';
        _affix_and_export
            SDL_CreateGPUGraphicsPipeline => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUGraphicsPipelineCreateInfo() ] ],
            Pointer [ SDL_GPUGraphicsPipeline() ];
        _const_and_export SDL_PROP_GPU_GRAPHICSPIPELINE_CREATE_NAME_STRING => 'SDL.gpu.graphicspipeline.create.name';
        _affix_and_export
            SDL_CreateGPUSampler => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUSamplerCreateInfo() ] ],
            Pointer [ SDL_GPUSampler() ];
        _const_and_export SDL_PROP_GPU_SAMPLER_CREATE_NAME_STRING => 'SDL.gpu.sampler.create.name';
        _affix_and_export SDL_CreateGPUShader => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUShaderCreateInfo() ] ], Pointer [ SDL_GPUShader() ];
        _const_and_export SDL_PROP_GPU_SHADER_CREATE_NAME_STRING => 'SDL.gpu.shader.create.name';
        _affix_and_export
            SDL_CreateGPUTexture => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUTextureCreateInfo() ] ],
            Pointer [ SDL_GPUTexture() ];
        _const_and_export SDL_PROP_GPU_TEXTURE_CREATE_D3D12_CLEAR_R_FLOAT        => 'SDL.gpu.texture.create.d3d12.clear.r';
        _const_and_export SDL_PROP_GPU_TEXTURE_CREATE_D3D12_CLEAR_G_FLOAT        => 'SDL.gpu.texture.create.d3d12.clear.g';
        _const_and_export SDL_PROP_GPU_TEXTURE_CREATE_D3D12_CLEAR_B_FLOAT        => 'SDL.gpu.texture.create.d3d12.clear.b';
        _const_and_export SDL_PROP_GPU_TEXTURE_CREATE_D3D12_CLEAR_A_FLOAT        => 'SDL.gpu.texture.create.d3d12.clear.a';
        _const_and_export SDL_PROP_GPU_TEXTURE_CREATE_D3D12_CLEAR_DEPTH_FLOAT    => 'SDL.gpu.texture.create.d3d12.clear.depth';
        _const_and_export SDL_PROP_GPU_TEXTURE_CREATE_D3D12_CLEAR_STENCIL_NUMBER => 'SDL.gpu.texture.create.d3d12.clear.stencil';
        _const_and_export SDL_PROP_GPU_TEXTURE_CREATE_NAME_STRING                => 'SDL.gpu.texture.create.name';
        _affix_and_export SDL_CreateGPUBuffer => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUBufferCreateInfo() ] ], Pointer [ SDL_GPUBuffer() ];
        _const_and_export SDL_PROP_GPU_BUFFER_CREATE_NAME_STRING => 'SDL.gpu.buffer.create.name';
        _affix_and_export
            SDL_CreateGPUTransferBuffer => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUTransferBufferCreateInfo() ] ],
            Pointer [ SDL_GPUTransferBuffer() ];
        _const_and_export SDL_PROP_GPU_TRANSFERBUFFER_CREATE_NAME_STRING => 'SDL.gpu.transferbuffer.create.name';
        _affix_and_export SDL_SetGPUBufferName    => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUBuffer() ], String ],  Void;
        _affix_and_export SDL_SetGPUTextureName   => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUTexture() ], String ], Void;
        _affix_and_export SDL_InsertGPUDebugLabel => [ Pointer [ SDL_GPUCommandBuffer() ], String ], Void;
        _affix_and_export SDL_PushGPUDebugGroup   => [ Pointer [ SDL_GPUCommandBuffer() ], String ], Void;
        _affix_and_export SDL_PopGPUDebugGroup    => [ Pointer [ SDL_GPUCommandBuffer() ] ], Void;
        _affix_and_export SDL_ReleaseGPUTexture   => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUTexture() ] ], Void;
        _affix_and_export SDL_ReleaseGPUSampler   => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUSampler() ] ], Void;
        _affix_and_export SDL_ReleaseGPUBuffer    => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUBuffer() ] ],  Void;
        _affix_and_export
            SDL_ReleaseGPUTransferBuffer => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUTransferBuffer() ] ],
            Void;
        _affix_and_export
            SDL_ReleaseGPUComputePipeline => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUComputePipeline() ] ],
            Void;
        _affix_and_export SDL_ReleaseGPUShader => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUShader() ] ], Void;
        _affix_and_export
            SDL_ReleaseGPUGraphicsPipeline => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUGraphicsPipeline() ] ],
            Void;
        _affix_and_export SDL_AcquireGPUCommandBuffer => [ Pointer [ SDL_GPUDevice() ] ], Pointer [ SDL_GPUCommandBuffer() ];
        _affix_and_export
            SDL_PushGPUVertexUniformData => [ Pointer [ SDL_GPUCommandBuffer() ], UInt32, Pointer [Void], UInt32 ],
            Void;
        _affix_and_export
            SDL_PushGPUFragmentUniformData => [ Pointer [ SDL_GPUCommandBuffer() ], UInt32, Pointer [Void], UInt32 ],
            Void;
        _affix_and_export
            SDL_PushGPUComputeUniformData => [ Pointer [ SDL_GPUCommandBuffer() ], UInt32, Pointer [Void], UInt32 ],
            Void;
        _affix_and_export
            SDL_BeginGPURenderPass =>
            [ Pointer [ SDL_GPUCommandBuffer() ], Pointer [ SDL_GPUColorTargetInfo() ], UInt32, Pointer [ SDL_GPUDepthStencilTargetInfo() ] ],
            Pointer [ SDL_GPURenderPass() ];
        _affix_and_export
            SDL_BindGPUGraphicsPipeline => [ Pointer [ SDL_GPURenderPass() ], Pointer [ SDL_GPUGraphicsPipeline() ] ],
            Void;
        _affix_and_export SDL_SetGPUViewport         => [ Pointer [ SDL_GPURenderPass() ], Pointer [ SDL_GPUViewport() ] ], Void;
        _affix_and_export SDL_SetGPUScissor          => [ Pointer [ SDL_GPURenderPass() ], Pointer [ SDL_Rect() ] ],        Void;
        _affix_and_export SDL_SetGPUBlendConstants   => [ Pointer [ SDL_GPURenderPass() ], SDL_FColor() ], Void;
        _affix_and_export SDL_SetGPUStencilReference => [ Pointer [ SDL_GPURenderPass() ], UInt8 ], Void;
        _affix_and_export
            SDL_BindGPUVertexBuffers => [ Pointer [ SDL_GPURenderPass() ], UInt32, Pointer [ SDL_GPUBufferBinding() ], UInt32 ],
            Void;
        _affix_and_export
            SDL_BindGPUIndexBuffer => [ Pointer [ SDL_GPURenderPass() ], Pointer [ SDL_GPUBufferBinding() ], SDL_GPUIndexElementSize() ],
            Void;
        _affix_and_export
            SDL_BindGPUVertexSamplers => [ Pointer [ SDL_GPURenderPass() ], UInt32, Pointer [ SDL_GPUTextureSamplerBinding() ], UInt32 ],
            Void;
        _affix_and_export
            SDL_BindGPUVertexStorageTextures => [ Pointer [ SDL_GPURenderPass() ], UInt32, Pointer [ Pointer [ SDL_GPUTexture() ] ], UInt32 ],
            Void;
        _affix_and_export
            SDL_BindGPUVertexStorageBuffers => [ Pointer [ SDL_GPURenderPass() ], UInt32, Pointer [ Pointer [ SDL_GPUBuffer() ] ], UInt32 ],
            Void;
        _affix_and_export
            SDL_BindGPUFragmentSamplers => [ Pointer [ SDL_GPURenderPass() ], UInt32, Pointer [ SDL_GPUTextureSamplerBinding() ], UInt32 ],
            Void;
        _affix_and_export
            SDL_BindGPUFragmentStorageTextures => [ Pointer [ SDL_GPURenderPass() ], UInt32, Pointer [ Pointer [ SDL_GPUTexture() ] ], UInt32 ],
            Void;
        _affix_and_export
            SDL_BindGPUFragmentStorageBuffers => [ Pointer [ SDL_GPURenderPass() ], UInt32, Pointer [ Pointer [ SDL_GPUBuffer() ] ], UInt32 ],
            Void;
        _affix_and_export
            SDL_DrawGPUIndexedPrimitives => [ Pointer [ SDL_GPURenderPass() ], UInt32, UInt32, UInt32, SInt32, UInt32 ],
            Void;
        _affix_and_export
            SDL_DrawGPUPrimitives => [ Pointer [ SDL_GPURenderPass() ], UInt32, UInt32, UInt32, UInt32 ],
            Void;
        _affix_and_export
            SDL_DrawGPUPrimitivesIndirect => [ Pointer [ SDL_GPURenderPass() ], Pointer [ SDL_GPUBuffer() ], UInt32, UInt32 ],
            Void;
        _affix_and_export
            SDL_DrawGPUIndexedPrimitivesIndirect => [ Pointer [ SDL_GPURenderPass() ], Pointer [ SDL_GPUBuffer() ], UInt32, UInt32 ],
            Void;
        _affix_and_export SDL_EndGPURenderPass => [ Pointer [ SDL_GPURenderPass() ] ], Void;
        _affix_and_export
            SDL_BeginGPUComputePass => [
            Pointer [ SDL_GPUCommandBuffer() ],
            Pointer [ SDL_GPUStorageTextureReadWriteBinding() ],
            UInt32, Pointer [ SDL_GPUStorageBufferReadWriteBinding() ], UInt32
            ],
            Pointer [ SDL_GPUComputePass() ];
        _affix_and_export
            SDL_BindGPUComputePipeline => [ Pointer [ SDL_GPUComputePass() ], Pointer [ SDL_GPUComputePipeline() ] ],
            Void;
        _affix_and_export
            SDL_BindGPUComputeSamplers => [ Pointer [ SDL_GPUComputePass() ], UInt32, Pointer [ SDL_GPUTextureSamplerBinding() ], UInt32 ],
            Void;
        _affix_and_export
            SDL_BindGPUComputeStorageTextures => [ Pointer [ SDL_GPUComputePass() ], UInt32, Pointer [ Pointer [ SDL_GPUTexture() ] ], UInt32 ],
            Void;
        _affix_and_export
            SDL_BindGPUComputeStorageBuffers => [ Pointer [ SDL_GPUComputePass() ], UInt32, Pointer [ Pointer [ SDL_GPUBuffer() ] ], UInt32 ],
            Void;
        _affix_and_export SDL_DispatchGPUCompute => [ Pointer [ SDL_GPUComputePass() ], UInt32, UInt32, UInt32 ], Void;
        _affix_and_export
            SDL_DispatchGPUComputeIndirect => [ Pointer [ SDL_GPUComputePass() ], Pointer [ SDL_GPUBuffer() ], UInt32 ],
            Void;
        _affix_and_export SDL_EndGPUComputePass => [ Pointer [ SDL_GPUComputePass() ] ], Void;
        _affix_and_export
            SDL_MapGPUTransferBuffer => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUTransferBuffer() ], Bool ],
            Pointer [Void];
        _affix_and_export SDL_UnmapGPUTransferBuffer => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUTransferBuffer() ] ], Void;
        _affix_and_export SDL_BeginGPUCopyPass => [ Pointer [ SDL_GPUCommandBuffer() ] ], Pointer [ SDL_GPUCopyPass() ];
        _affix_and_export
            SDL_UploadToGPUTexture =>
            [ Pointer [ SDL_GPUCopyPass() ], Pointer [ SDL_GPUTextureTransferInfo() ], Pointer [ SDL_GPUTextureRegion() ], Bool ],
            Void;
        _affix_and_export
            SDL_UploadToGPUBuffer =>
            [ Pointer [ SDL_GPUCopyPass() ], Pointer [ SDL_GPUTransferBufferLocation() ], Pointer [ SDL_GPUBufferRegion() ], Bool ],
            Void;
        _affix_and_export
            SDL_CopyGPUTextureToTexture => [
            Pointer [ SDL_GPUCopyPass() ],
            Pointer [ SDL_GPUTextureLocation() ],
            Pointer [ SDL_GPUTextureLocation() ],
            UInt32, UInt32, UInt32, Bool
            ],
            Void;
        _affix_and_export
            SDL_CopyGPUBufferToBuffer =>
            [ Pointer [ SDL_GPUCopyPass() ], Pointer [ SDL_GPUBufferLocation() ], Pointer [ SDL_GPUBufferLocation() ], UInt32, Bool ],
            Void;
        _affix_and_export
            SDL_DownloadFromGPUTexture =>
            [ Pointer [ SDL_GPUCopyPass() ], Pointer [ SDL_GPUTextureRegion() ], Pointer [ SDL_GPUTextureTransferInfo() ] ],
            Void;
        _affix_and_export
            SDL_DownloadFromGPUBuffer =>
            [ Pointer [ SDL_GPUCopyPass() ], Pointer [ SDL_GPUBufferRegion() ], Pointer [ SDL_GPUTransferBufferLocation() ] ],
            Void;
        _affix_and_export SDL_EndGPUCopyPass => [ Pointer [ SDL_GPUCopyPass() ] ], Void;
        _affix_and_export
            SDL_GenerateMipmapsForGPUTexture => [ Pointer [ SDL_GPUCommandBuffer() ], Pointer [ SDL_GPUTexture() ] ],
            Void;
        _affix_and_export SDL_BlitGPUTexture => [ Pointer [ SDL_GPUCommandBuffer() ], Pointer [ SDL_GPUBlitInfo() ] ], Void;
        _affix_and_export
            SDL_WindowSupportsGPUSwapchainComposition => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_Window() ], SDL_GPUSwapchainComposition() ],
            Bool;
        _affix_and_export
            SDL_WindowSupportsGPUPresentMode => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_Window() ], SDL_GPUPresentMode() ],
            Bool;
        _affix_and_export SDL_ClaimWindowForGPUDevice    => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_ReleaseWindowFromGPUDevice => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_Window() ] ], Void;
        _affix_and_export
            SDL_SetGPUSwapchainParameters =>
            [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_Window() ], SDL_GPUSwapchainComposition(), SDL_GPUPresentMode() ],
            Bool;
        _affix_and_export SDL_SetGPUAllowedFramesInFlight => [ Pointer [ SDL_GPUDevice() ], UInt32 ], Bool;
        _affix_and_export
            SDL_GetGPUSwapchainTextureFormat => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_Window() ] ],
            SDL_GPUTextureFormat();
        _affix_and_export
            SDL_AcquireGPUSwapchainTexture => [
            Pointer [ SDL_GPUCommandBuffer() ],
            Pointer [ SDL_Window() ],
            Pointer [ Pointer [ SDL_GPUTexture() ] ],
            Pointer [UInt32],
            Pointer [UInt32]
            ],
            Bool;
        _affix_and_export SDL_WaitForGPUSwapchain => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export
            SDL_WaitAndAcquireGPUSwapchainTexture => [
            Pointer [ SDL_GPUCommandBuffer() ],
            Pointer [ SDL_Window() ],
            Pointer [ Pointer [ SDL_GPUTexture() ] ],
            Pointer [UInt32],
            Pointer [UInt32]
            ],
            Bool;
        _affix_and_export SDL_SubmitGPUCommandBuffer                => [ Pointer [ SDL_GPUCommandBuffer() ] ], Bool;
        _affix_and_export SDL_SubmitGPUCommandBufferAndAcquireFence => [ Pointer [ SDL_GPUCommandBuffer() ] ], Pointer [ SDL_GPUFence() ];
        _affix_and_export SDL_CancelGPUCommandBuffer                => [ Pointer [ SDL_GPUCommandBuffer() ] ], Bool;
        _affix_and_export SDL_WaitForGPUIdle                        => [ Pointer [ SDL_GPUDevice() ] ],        Bool;
        _affix_and_export
            SDL_WaitForGPUFences => [ Pointer [ SDL_GPUDevice() ], Bool, Pointer [ Pointer [ SDL_GPUFence() ] ], UInt32 ],
            Bool;
        _affix_and_export SDL_QueryGPUFence                  => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUFence() ] ], Bool;
        _affix_and_export SDL_ReleaseGPUFence                => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_GPUFence() ] ], Void;
        _affix_and_export SDL_GPUTextureFormatTexelBlockSize => [ SDL_GPUTextureFormat() ], UInt32;
        _affix_and_export
            SDL_GPUTextureSupportsFormat => [ Pointer [ SDL_GPUDevice() ], SDL_GPUTextureFormat(), SDL_GPUTextureType(), SDL_GPUTextureUsageFlags() ],
            Bool;
        _affix_and_export
            SDL_GPUTextureSupportsSampleCount => [ Pointer [ SDL_GPUDevice() ], SDL_GPUTextureFormat(), SDL_GPUSampleCount() ],
            Bool;
        _affix_and_export
            SDL_CalculateGPUTextureFormatSize => [ SDL_GPUTextureFormat(), UInt32, UInt32, UInt32 ],
            UInt32;

        #~ _affix_and_export SDL_GetPixelFormatFromGPUTextureFormat => [ SDL_GPUTextureFormat() ], SDL_PixelFormat();
        #~ _affix_and_export SDL_GetGPUTextureFormatFromPixelFormat => [ SDL_PixelFormat() ],      SDL_GPUTextureFormat();
    }

=head3 C<:guid> - GUIDs

A GUID is a 128-bit value that represents something that is uniquely identifiable by this value: "globally unique."

SDL provides functions to convert a GUID to/from a string.

See L<SDL3: CategoryGUID|https://wiki.libsdl.org/SDL3/CategoryGUID>

=cut

    sub _guid() {
        state $done++ && return;
        #
        _stdinc();
        #
        _typedef_and_export SDL_GUID => Struct [ data => Array [ UInt8, 16 ] ];
        #
        _affix_and_export SDL_GUIDToString => [ SDL_GUID(), String, Int ], Void;
        _affix_and_export SDL_StringToGUID => [String], SDL_GUID();
    }

=head3 C<:haptic> - Force Feedback Support

The SDL haptic subsystem manages haptic (force feedback) devices.

See L<SDL3: CategoryHaptic|https://wiki.libsdl.org/SDL3/CategoryHaptic>

=cut

    sub _haptic() {
        state $done++ && return;
        #
        _error();
        _joystick();
        _stdinc();
        #
        _typedef_and_export SDL_Haptic   => Void;
        _typedef_and_export SDL_HapticID => UInt32;
        _const_and_export SDL_HAPTIC_INFINITY => 4294967295;
        _typedef_and_export SDL_HapticEffectType => UInt16;
        _const_and_export SDL_HAPTIC_CONSTANT     => ( 1 << 0 );
        _const_and_export SDL_HAPTIC_SINE         => ( 1 << 1 );
        _const_and_export SDL_HAPTIC_SQUARE       => ( 1 << 2 );
        _const_and_export SDL_HAPTIC_TRIANGLE     => ( 1 << 3 );
        _const_and_export SDL_HAPTIC_SAWTOOTHUP   => ( 1 << 4 );
        _const_and_export SDL_HAPTIC_SAWTOOTHDOWN => ( 1 << 5 );
        _const_and_export SDL_HAPTIC_RAMP         => ( 1 << 6 );
        _const_and_export SDL_HAPTIC_SPRING       => ( 1 << 7 );
        _const_and_export SDL_HAPTIC_DAMPER       => ( 1 << 8 );
        _const_and_export SDL_HAPTIC_INERTIA      => ( 1 << 9 );
        _const_and_export SDL_HAPTIC_FRICTION     => ( 1 << 10 );
        _const_and_export SDL_HAPTIC_LEFTRIGHT    => ( 1 << 11 );
        _const_and_export SDL_HAPTIC_RESERVED1    => ( 1 << 12 );
        _const_and_export SDL_HAPTIC_RESERVED2    => ( 1 << 13 );
        _const_and_export SDL_HAPTIC_RESERVED3    => ( 1 << 14 );
        _const_and_export SDL_HAPTIC_CUSTOM       => ( 1 << 15 );
        _const_and_export SDL_HAPTIC_GAIN         => ( 1 << 16 );
        _const_and_export SDL_HAPTIC_AUTOCENTER   => ( 1 << 17 );
        _const_and_export SDL_HAPTIC_STATUS       => ( 1 << 18 );
        _const_and_export SDL_HAPTIC_PAUSE        => ( 1 << 19 );
        _typedef_and_export SDL_HapticDirectionType => UInt8;
        _const_and_export SDL_HAPTIC_POLAR         => 0;
        _const_and_export SDL_HAPTIC_CARTESIAN     => 1;
        _const_and_export SDL_HAPTIC_SPHERICAL     => 2;
        _const_and_export SDL_HAPTIC_STEERING_AXIS => 3;
        _typedef_and_export SDL_HapticEffectID  => Int;
        _typedef_and_export SDL_HapticDirection => Struct [ type => SDL_HapticDirectionType(), dir => Array [ SInt32, 3 ] ];
        _typedef_and_export SDL_HapticConstant => Struct [
            type          => SDL_HapticEffectType(),
            direction     => SDL_HapticDirection(),
            length        => UInt32,
            delay         => UInt16,
            button        => UInt16,
            interval      => UInt16,
            level         => SInt16,
            attack_length => UInt16,
            attack_level  => UInt16,
            fade_length   => UInt16,
            fade_level    => UInt16
        ];
        _typedef_and_export SDL_HapticPeriodic => Struct [
            type          => SDL_HapticEffectType(),
            direction     => SDL_HapticDirection(),
            length        => UInt32,
            delay         => UInt16,
            button        => UInt16,
            interval      => UInt16,
            period        => UInt16,
            magnitude     => SInt16,
            offset        => SInt16,
            phase         => UInt16,
            attack_length => UInt16,
            attack_level  => UInt16,
            fade_length   => UInt16,
            fade_level    => UInt16
        ];
        _typedef_and_export SDL_HapticCondition => Struct [
            type        => SDL_HapticEffectType(),
            direction   => SDL_HapticDirection(),
            length      => UInt32,
            delay       => UInt16,
            button      => UInt16,
            interval    => UInt16,
            right_sat   => Array [ UInt16, 3 ],
            left_sat    => Array [ UInt16, 3 ],
            right_coeff => Array [ SInt16, 3 ],
            left_coeff  => Array [ SInt16, 3 ],
            deadband    => Array [ UInt16, 3 ],
            center      => Array [ SInt16, 3 ]
        ];
        _typedef_and_export SDL_HapticRamp => Struct [
            type          => SDL_HapticEffectType(),
            direction     => SDL_HapticDirection(),
            length        => UInt32,
            delay         => UInt16,
            button        => UInt16,
            interval      => UInt16,
            start         => SInt16,
            end           => SInt16,
            attack_length => UInt16,
            attack_level  => UInt16,
            fade_length   => UInt16,
            fade_level    => UInt16
        ];
        _typedef_and_export SDL_HapticLeftRight =>
            Struct [ type => SDL_HapticEffectType(), length => UInt32, large_magnitude => UInt16, small_magnitude => UInt16 ];
        _typedef_and_export SDL_HapticCustom => Struct [
            type          => SDL_HapticEffectType(),
            direction     => SDL_HapticDirection(),
            length        => UInt32,
            delay         => UInt16,
            button        => UInt16,
            interval      => UInt16,
            channels      => UInt8,
            period        => UInt16,
            samples       => UInt16,
            data          => Pointer [UInt16],
            attack_length => UInt16,
            attack_level  => UInt16,
            fade_length   => UInt16,
            fade_level    => UInt16
        ];
        _typedef_and_export SDL_HapticEffect => Union [
            type      => SDL_HapticEffectType(),
            constant  => SDL_HapticConstant(),
            periodic  => SDL_HapticPeriodic(),
            condition => SDL_HapticCondition(),
            ramp      => SDL_HapticRamp(),
            leftright => SDL_HapticLeftRight(),
            custom    => SDL_HapticCustom()
        ];
        _affix_and_export SDL_GetHaptics                 => [ Pointer [Int] ], Pointer [ SDL_HapticID() ];
        _affix_and_export SDL_GetHapticNameForID         => [ SDL_HapticID() ], String;
        _affix_and_export SDL_OpenHaptic                 => [ SDL_HapticID() ], Pointer [ SDL_Haptic() ];
        _affix_and_export SDL_GetHapticFromID            => [ SDL_HapticID() ], Pointer [ SDL_Haptic() ];
        _affix_and_export SDL_GetHapticID                => [ Pointer [ SDL_Haptic() ] ], SDL_HapticID();
        _affix_and_export SDL_GetHapticName              => [ Pointer [ SDL_Haptic() ] ], String;
        _affix_and_export SDL_IsMouseHaptic              => [], Bool;
        _affix_and_export SDL_OpenHapticFromMouse        => [], Pointer [ SDL_Haptic() ];
        _affix_and_export SDL_IsJoystickHaptic           => [ Pointer [ SDL_Joystick() ] ], Bool;
        _affix_and_export SDL_OpenHapticFromJoystick     => [ Pointer [ SDL_Joystick() ] ], Pointer [ SDL_Haptic() ];
        _affix_and_export SDL_CloseHaptic                => [ Pointer [ SDL_Haptic() ] ],   Void;
        _affix_and_export SDL_GetMaxHapticEffects        => [ Pointer [ SDL_Haptic() ] ],   Int;
        _affix_and_export SDL_GetMaxHapticEffectsPlaying => [ Pointer [ SDL_Haptic() ] ],   Int;
        _affix_and_export SDL_GetHapticFeatures          => [ Pointer [ SDL_Haptic() ] ],   UInt32;
        _affix_and_export SDL_GetNumHapticAxes           => [ Pointer [ SDL_Haptic() ] ],   Int;
        _affix_and_export SDL_HapticEffectSupported      => [ Pointer [ SDL_Haptic() ], Pointer [ SDL_HapticEffect() ] ], Bool;
        _affix_and_export SDL_CreateHapticEffect         => [ Pointer [ SDL_Haptic() ], Pointer [ SDL_HapticEffect() ] ], SDL_HapticEffectID();
        _affix_and_export
            SDL_UpdateHapticEffect => [ Pointer [ SDL_Haptic() ], SDL_HapticEffectID(), Pointer [ SDL_HapticEffect() ] ],
            Bool;
        _affix_and_export SDL_RunHapticEffect       => [ Pointer [ SDL_Haptic() ], SDL_HapticEffectID(), UInt32 ], Bool;
        _affix_and_export SDL_StopHapticEffect      => [ Pointer [ SDL_Haptic() ], SDL_HapticEffectID() ], Bool;
        _affix_and_export SDL_DestroyHapticEffect   => [ Pointer [ SDL_Haptic() ], SDL_HapticEffectID() ], Void;
        _affix_and_export SDL_GetHapticEffectStatus => [ Pointer [ SDL_Haptic() ], SDL_HapticEffectID() ], Bool;
        _affix_and_export SDL_SetHapticGain         => [ Pointer [ SDL_Haptic() ], Int ], Bool;
        _affix_and_export SDL_SetHapticAutocenter   => [ Pointer [ SDL_Haptic() ], Int ], Bool;
        _affix_and_export SDL_PauseHaptic           => [ Pointer [ SDL_Haptic() ] ], Bool;
        _affix_and_export SDL_ResumeHaptic          => [ Pointer [ SDL_Haptic() ] ], Bool;
        _affix_and_export SDL_StopHapticEffects     => [ Pointer [ SDL_Haptic() ] ], Bool;
        _affix_and_export SDL_HapticRumbleSupported => [ Pointer [ SDL_Haptic() ] ], Bool;
        _affix_and_export SDL_InitHapticRumble      => [ Pointer [ SDL_Haptic() ] ], Bool;
        _affix_and_export SDL_PlayHapticRumble      => [ Pointer [ SDL_Haptic() ], Float, UInt32 ], Bool;
        _affix_and_export SDL_StopHapticRumble      => [ Pointer [ SDL_Haptic() ] ], Bool;
    }

=head3 C<:hidapi> - HIDAPI

HID devices.

See L<SDL3: CategoryHIDAPI|https://wiki.libsdl.org/SDL3/CategoryHIDAPI>

=cut

    sub _hidapi() {
        state $done++ && return;
        #
        _error();
        _properties();
        _stdinc();
        #
        _typedef_and_export SDL_hid_device => Void;
        _enum_and_export SDL_hid_bus_type => [
            [ SDL_HID_API_BUS_UNKNOWN   => 0x00 ],
            [ SDL_HID_API_BUS_USB       => 0x01 ],
            [ SDL_HID_API_BUS_BLUETOOTH => 0x02 ],
            [ SDL_HID_API_BUS_I2C       => 0x03 ],
            [ SDL_HID_API_BUS_SPI       => 0x04 ]
        ];
        typedef 'SDL_hid_device_info';
        _typedef_and_export SDL_hid_device_info => Struct [
            path                => String,
            vendor_id           => UShort,
            product_id          => UShort,
            serial_number       => WString,
            release_number      => UShort,
            manufacturer_string => WString,
            product_string      => WString,
            usage_page          => UShort,
            usage               => UShort,
            interface_number    => Int,
            interface_class     => Int,
            interface_subclass  => Int,
            interface_protocol  => Int,
            bus_type            => SDL_hid_bus_type(),
            next                => Pointer [ SDL_hid_device_info() ]
        ];
        _affix_and_export SDL_hid_init                => [], Int;
        _affix_and_export SDL_hid_exit                => [], Int;
        _affix_and_export SDL_hid_device_change_count => [], UInt32;
        _affix_and_export SDL_hid_enumerate           => [ UShort, UShort ], Pointer [ SDL_hid_device_info() ];
        _affix_and_export SDL_hid_free_enumeration    => [ Pointer [ SDL_hid_device_info() ] ], Void;
        _affix_and_export SDL_hid_open                => [ UShort, UShort, WString ], Pointer [ SDL_hid_device() ];
        _affix_and_export SDL_hid_open_path           => [String], Pointer [ SDL_hid_device() ];

        #~ _affix_and_export SDL_hid_get_properties      => [ Pointer [ SDL_hid_device() ] ], SDL_PropertiesID();
        _const_and_export SDL_PROP_HIDAPI_LIBUSB_DEVICE_HANDLE_POINTER => 'SDL.hidapi.libusb.device.handle';
        _affix_and_export SDL_hid_write                    => [ Pointer [ SDL_hid_device() ], Pointer [UChar], Size_t ], Int;
        _affix_and_export SDL_hid_read_timeout             => [ Pointer [ SDL_hid_device() ], Pointer [UChar], Size_t, Int ], Int;
        _affix_and_export SDL_hid_read                     => [ Pointer [ SDL_hid_device() ], Pointer [UChar], Size_t ], Int;
        _affix_and_export SDL_hid_set_nonblocking          => [ Pointer [ SDL_hid_device() ], Int ], Int;
        _affix_and_export SDL_hid_send_feature_report      => [ Pointer [ SDL_hid_device() ], Pointer [UChar], Size_t ], Int;
        _affix_and_export SDL_hid_get_feature_report       => [ Pointer [ SDL_hid_device() ], Pointer [UChar], Size_t ], Int;
        _affix_and_export SDL_hid_get_input_report         => [ Pointer [ SDL_hid_device() ], Pointer [UChar], Size_t ], Int;
        _affix_and_export SDL_hid_close                    => [ Pointer [ SDL_hid_device() ] ], Int;
        _affix_and_export SDL_hid_get_manufacturer_string  => [ Pointer [ SDL_hid_device() ], WString, Size_t ], Int;
        _affix_and_export SDL_hid_get_product_string       => [ Pointer [ SDL_hid_device() ], WString, Size_t ], Int;
        _affix_and_export SDL_hid_get_serial_number_string => [ Pointer [ SDL_hid_device() ], WString, Size_t ], Int;
        _affix_and_export SDL_hid_get_indexed_string       => [ Pointer [ SDL_hid_device() ], Int, WString, Size_t ], Int;
        _affix_and_export SDL_hid_get_device_info          => [ Pointer [ SDL_hid_device() ] ], Pointer [ SDL_hid_device_info() ];
        _affix_and_export SDL_hid_get_report_descriptor    => [ Pointer [ SDL_hid_device() ], Pointer [UChar], Size_t ], Int;
        _affix_and_export SDL_hid_ble_scan                 => [Bool], Void;
    }

=head3 C<:hints> - Configuration Variables

Functions to set and get configuration hints, as well as listing each of them alphabetically.

See L<SDL3: CategoryHints|https://wiki.libsdl.org/SDL3/CategoryHints>

=cut

    sub _hints() {
        state $done++ && return;
        #
        _error();
        _stdinc();
        #
        _const_and_export SDL_HINT_ALLOW_ALT_TAB_WHILE_GRABBED             => 'SDL_ALLOW_ALT_TAB_WHILE_GRABBED';
        _const_and_export SDL_HINT_ANDROID_ALLOW_RECREATE_ACTIVITY         => 'SDL_ANDROID_ALLOW_RECREATE_ACTIVITY';
        _const_and_export SDL_HINT_ANDROID_BLOCK_ON_PAUSE                  => 'SDL_ANDROID_BLOCK_ON_PAUSE';
        _const_and_export SDL_HINT_ANDROID_LOW_LATENCY_AUDIO               => 'SDL_ANDROID_LOW_LATENCY_AUDIO';
        _const_and_export SDL_HINT_ANDROID_TRAP_BACK_BUTTON                => 'SDL_ANDROID_TRAP_BACK_BUTTON';
        _const_and_export SDL_HINT_APP_ID                                  => 'SDL_APP_ID';
        _const_and_export SDL_HINT_APP_NAME                                => 'SDL_APP_NAME';
        _const_and_export SDL_HINT_APPLE_TV_CONTROLLER_UI_EVENTS           => 'SDL_APPLE_TV_CONTROLLER_UI_EVENTS';
        _const_and_export SDL_HINT_APPLE_TV_REMOTE_ALLOW_ROTATION          => 'SDL_APPLE_TV_REMOTE_ALLOW_ROTATION';
        _const_and_export SDL_HINT_AUDIO_ALSA_DEFAULT_DEVICE               => 'SDL_AUDIO_ALSA_DEFAULT_DEVICE';
        _const_and_export SDL_HINT_AUDIO_ALSA_DEFAULT_PLAYBACK_DEVICE      => 'SDL_AUDIO_ALSA_DEFAULT_PLAYBACK_DEVICE';
        _const_and_export SDL_HINT_AUDIO_ALSA_DEFAULT_RECORDING_DEVICE     => 'SDL_AUDIO_ALSA_DEFAULT_RECORDING_DEVICE';
        _const_and_export SDL_HINT_AUDIO_CATEGORY                          => 'SDL_AUDIO_CATEGORY';
        _const_and_export SDL_HINT_AUDIO_CHANNELS                          => 'SDL_AUDIO_CHANNELS';
        _const_and_export SDL_HINT_AUDIO_DEVICE_APP_ICON_NAME              => 'SDL_AUDIO_DEVICE_APP_ICON_NAME';
        _const_and_export SDL_HINT_AUDIO_DEVICE_SAMPLE_FRAMES              => 'SDL_AUDIO_DEVICE_SAMPLE_FRAMES';
        _const_and_export SDL_HINT_AUDIO_DEVICE_STREAM_NAME                => 'SDL_AUDIO_DEVICE_STREAM_NAME';
        _const_and_export SDL_HINT_AUDIO_DEVICE_STREAM_ROLE                => 'SDL_AUDIO_DEVICE_STREAM_ROLE';
        _const_and_export SDL_HINT_AUDIO_DEVICE_RAW_STREAM                 => 'SDL_AUDIO_DEVICE_RAW_STREAM';
        _const_and_export SDL_HINT_AUDIO_DISK_INPUT_FILE                   => 'SDL_AUDIO_DISK_INPUT_FILE';
        _const_and_export SDL_HINT_AUDIO_DISK_OUTPUT_FILE                  => 'SDL_AUDIO_DISK_OUTPUT_FILE';
        _const_and_export SDL_HINT_AUDIO_DISK_TIMESCALE                    => 'SDL_AUDIO_DISK_TIMESCALE';
        _const_and_export SDL_HINT_AUDIO_DRIVER                            => 'SDL_AUDIO_DRIVER';
        _const_and_export SDL_HINT_AUDIO_DUMMY_TIMESCALE                   => 'SDL_AUDIO_DUMMY_TIMESCALE';
        _const_and_export SDL_HINT_AUDIO_FORMAT                            => 'SDL_AUDIO_FORMAT';
        _const_and_export SDL_HINT_AUDIO_FREQUENCY                         => 'SDL_AUDIO_FREQUENCY';
        _const_and_export SDL_HINT_AUDIO_INCLUDE_MONITORS                  => 'SDL_AUDIO_INCLUDE_MONITORS';
        _const_and_export SDL_HINT_AUTO_UPDATE_JOYSTICKS                   => 'SDL_AUTO_UPDATE_JOYSTICKS';
        _const_and_export SDL_HINT_AUTO_UPDATE_SENSORS                     => 'SDL_AUTO_UPDATE_SENSORS';
        _const_and_export SDL_HINT_BMP_SAVE_LEGACY_FORMAT                  => 'SDL_BMP_SAVE_LEGACY_FORMAT';
        _const_and_export SDL_HINT_CAMERA_DRIVER                           => 'SDL_CAMERA_DRIVER';
        _const_and_export SDL_HINT_CPU_FEATURE_MASK                        => 'SDL_CPU_FEATURE_MASK';
        _const_and_export SDL_HINT_JOYSTICK_DIRECTINPUT                    => 'SDL_JOYSTICK_DIRECTINPUT';
        _const_and_export SDL_HINT_FILE_DIALOG_DRIVER                      => 'SDL_FILE_DIALOG_DRIVER';
        _const_and_export SDL_HINT_DISPLAY_USABLE_BOUNDS                   => 'SDL_DISPLAY_USABLE_BOUNDS';
        _const_and_export SDL_HINT_INVALID_PARAM_CHECKS                    => 'SDL_INVALID_PARAM_CHECKS';
        _const_and_export SDL_HINT_EMSCRIPTEN_ASYNCIFY                     => 'SDL_EMSCRIPTEN_ASYNCIFY';
        _const_and_export SDL_HINT_EMSCRIPTEN_CANVAS_SELECTOR              => 'SDL_EMSCRIPTEN_CANVAS_SELECTOR';
        _const_and_export SDL_HINT_EMSCRIPTEN_KEYBOARD_ELEMENT             => 'SDL_EMSCRIPTEN_KEYBOARD_ELEMENT';
        _const_and_export SDL_HINT_EMSCRIPTEN_FILL_DOCUMENT                => 'SDL_EMSCRIPTEN_FILL_DOCUMENT';
        _const_and_export SDL_HINT_ENABLE_SCREEN_KEYBOARD                  => 'SDL_ENABLE_SCREEN_KEYBOARD';
        _const_and_export SDL_HINT_EVDEV_DEVICES                           => 'SDL_EVDEV_DEVICES';
        _const_and_export SDL_HINT_EVENT_LOGGING                           => 'SDL_EVENT_LOGGING';
        _const_and_export SDL_HINT_FORCE_RAISEWINDOW                       => 'SDL_FORCE_RAISEWINDOW';
        _const_and_export SDL_HINT_FRAMEBUFFER_ACCELERATION                => 'SDL_FRAMEBUFFER_ACCELERATION';
        _const_and_export SDL_HINT_GAMECONTROLLERCONFIG                    => 'SDL_GAMECONTROLLERCONFIG';
        _const_and_export SDL_HINT_GAMECONTROLLERCONFIG_FILE               => 'SDL_GAMECONTROLLERCONFIG_FILE';
        _const_and_export SDL_HINT_GAMECONTROLLERTYPE                      => 'SDL_GAMECONTROLLERTYPE';
        _const_and_export SDL_HINT_GAMECONTROLLER_IGNORE_DEVICES           => 'SDL_GAMECONTROLLER_IGNORE_DEVICES';
        _const_and_export SDL_HINT_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT    => 'SDL_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT';
        _const_and_export SDL_HINT_GAMECONTROLLER_SENSOR_FUSION            => 'SDL_GAMECONTROLLER_SENSOR_FUSION';
        _const_and_export SDL_HINT_GDK_TEXTINPUT_DEFAULT_TEXT              => 'SDL_GDK_TEXTINPUT_DEFAULT_TEXT';
        _const_and_export SDL_HINT_GDK_TEXTINPUT_DESCRIPTION               => 'SDL_GDK_TEXTINPUT_DESCRIPTION';
        _const_and_export SDL_HINT_GDK_TEXTINPUT_MAX_LENGTH                => 'SDL_GDK_TEXTINPUT_MAX_LENGTH';
        _const_and_export SDL_HINT_GDK_TEXTINPUT_SCOPE                     => 'SDL_GDK_TEXTINPUT_SCOPE';
        _const_and_export SDL_HINT_GDK_TEXTINPUT_TITLE                     => 'SDL_GDK_TEXTINPUT_TITLE';
        _const_and_export SDL_HINT_HIDAPI_LIBUSB                           => 'SDL_HIDAPI_LIBUSB';
        _const_and_export SDL_HINT_HIDAPI_LIBUSB_WHITELIST                 => 'SDL_HIDAPI_LIBUSB_WHITELIST';
        _const_and_export SDL_HINT_HIDAPI_UDEV                             => 'SDL_HIDAPI_UDEV';
        _const_and_export SDL_HINT_GPU_DRIVER                              => 'SDL_GPU_DRIVER';
        _const_and_export SDL_HINT_HIDAPI_ENUMERATE_ONLY_CONTROLLERS       => 'SDL_HIDAPI_ENUMERATE_ONLY_CONTROLLERS';
        _const_and_export SDL_HINT_HIDAPI_IGNORE_DEVICES                   => 'SDL_HIDAPI_IGNORE_DEVICES';
        _const_and_export SDL_HINT_IME_IMPLEMENTED_UI                      => 'SDL_IME_IMPLEMENTED_UI';
        _const_and_export SDL_HINT_IOS_HIDE_HOME_INDICATOR                 => 'SDL_IOS_HIDE_HOME_INDICATOR';
        _const_and_export SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS        => 'SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS';
        _const_and_export SDL_HINT_JOYSTICK_ARCADESTICK_DEVICES            => 'SDL_JOYSTICK_ARCADESTICK_DEVICES';
        _const_and_export SDL_HINT_JOYSTICK_ARCADESTICK_DEVICES_EXCLUDED   => 'SDL_JOYSTICK_ARCADESTICK_DEVICES_EXCLUDED';
        _const_and_export SDL_HINT_JOYSTICK_BLACKLIST_DEVICES              => 'SDL_JOYSTICK_BLACKLIST_DEVICES';
        _const_and_export SDL_HINT_JOYSTICK_BLACKLIST_DEVICES_EXCLUDED     => 'SDL_JOYSTICK_BLACKLIST_DEVICES_EXCLUDED';
        _const_and_export SDL_HINT_JOYSTICK_DEVICE                         => 'SDL_JOYSTICK_DEVICE';
        _const_and_export SDL_HINT_JOYSTICK_ENHANCED_REPORTS               => 'SDL_JOYSTICK_ENHANCED_REPORTS';
        _const_and_export SDL_HINT_JOYSTICK_FLIGHTSTICK_DEVICES            => 'SDL_JOYSTICK_FLIGHTSTICK_DEVICES';
        _const_and_export SDL_HINT_JOYSTICK_FLIGHTSTICK_DEVICES_EXCLUDED   => 'SDL_JOYSTICK_FLIGHTSTICK_DEVICES_EXCLUDED';
        _const_and_export SDL_HINT_JOYSTICK_GAMEINPUT                      => 'SDL_JOYSTICK_GAMEINPUT';
        _const_and_export SDL_HINT_JOYSTICK_GAMECUBE_DEVICES               => 'SDL_JOYSTICK_GAMECUBE_DEVICES';
        _const_and_export SDL_HINT_JOYSTICK_GAMECUBE_DEVICES_EXCLUDED      => 'SDL_JOYSTICK_GAMECUBE_DEVICES_EXCLUDED';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI                         => 'SDL_JOYSTICK_HIDAPI';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_COMBINE_JOY_CONS        => 'SDL_JOYSTICK_HIDAPI_COMBINE_JOY_CONS';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_GAMECUBE                => 'SDL_JOYSTICK_HIDAPI_GAMECUBE';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_GAMECUBE_RUMBLE_BRAKE   => 'SDL_JOYSTICK_HIDAPI_GAMECUBE_RUMBLE_BRAKE';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_JOY_CONS                => 'SDL_JOYSTICK_HIDAPI_JOY_CONS';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_JOYCON_HOME_LED         => 'SDL_JOYSTICK_HIDAPI_JOYCON_HOME_LED';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_LUNA                    => 'SDL_JOYSTICK_HIDAPI_LUNA';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_NINTENDO_CLASSIC        => 'SDL_JOYSTICK_HIDAPI_NINTENDO_CLASSIC';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_PS3                     => 'SDL_JOYSTICK_HIDAPI_PS3';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_PS3_SIXAXIS_DRIVER      => 'SDL_JOYSTICK_HIDAPI_PS3_SIXAXIS_DRIVER';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_PS4                     => 'SDL_JOYSTICK_HIDAPI_PS4';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_PS4_REPORT_INTERVAL     => 'SDL_JOYSTICK_HIDAPI_PS4_REPORT_INTERVAL';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_PS5                     => 'SDL_JOYSTICK_HIDAPI_PS5';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_PS5_PLAYER_LED          => 'SDL_JOYSTICK_HIDAPI_PS5_PLAYER_LED';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_SHIELD                  => 'SDL_JOYSTICK_HIDAPI_SHIELD';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_STADIA                  => 'SDL_JOYSTICK_HIDAPI_STADIA';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_STEAM                   => 'SDL_JOYSTICK_HIDAPI_STEAM';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_STEAM_HOME_LED          => 'SDL_JOYSTICK_HIDAPI_STEAM_HOME_LED';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_STEAMDECK               => 'SDL_JOYSTICK_HIDAPI_STEAMDECK';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_STEAM_HORI              => 'SDL_JOYSTICK_HIDAPI_STEAM_HORI';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_LG4FF                   => 'SDL_JOYSTICK_HIDAPI_LG4FF';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_8BITDO                  => 'SDL_JOYSTICK_HIDAPI_8BITDO';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_SINPUT                  => 'SDL_JOYSTICK_HIDAPI_SINPUT';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_ZUIKI                   => 'SDL_JOYSTICK_HIDAPI_ZUIKI';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_FLYDIGI                 => 'SDL_JOYSTICK_HIDAPI_FLYDIGI';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_SWITCH                  => 'SDL_JOYSTICK_HIDAPI_SWITCH';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_SWITCH_HOME_LED         => 'SDL_JOYSTICK_HIDAPI_SWITCH_HOME_LED';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_SWITCH_PLAYER_LED       => 'SDL_JOYSTICK_HIDAPI_SWITCH_PLAYER_LED';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_SWITCH2                 => 'SDL_JOYSTICK_HIDAPI_SWITCH2';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_VERTICAL_JOY_CONS       => 'SDL_JOYSTICK_HIDAPI_VERTICAL_JOY_CONS';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_WII                     => 'SDL_JOYSTICK_HIDAPI_WII';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_WII_PLAYER_LED          => 'SDL_JOYSTICK_HIDAPI_WII_PLAYER_LED';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_XBOX                    => 'SDL_JOYSTICK_HIDAPI_XBOX';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_XBOX_360                => 'SDL_JOYSTICK_HIDAPI_XBOX_360';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_XBOX_360_PLAYER_LED     => 'SDL_JOYSTICK_HIDAPI_XBOX_360_PLAYER_LED';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_XBOX_360_WIRELESS       => 'SDL_JOYSTICK_HIDAPI_XBOX_360_WIRELESS';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_XBOX_ONE                => 'SDL_JOYSTICK_HIDAPI_XBOX_ONE';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_XBOX_ONE_HOME_LED       => 'SDL_JOYSTICK_HIDAPI_XBOX_ONE_HOME_LED';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_GIP                     => 'SDL_JOYSTICK_HIDAPI_GIP';
        _const_and_export SDL_HINT_JOYSTICK_HIDAPI_GIP_RESET_FOR_METADATA  => 'SDL_JOYSTICK_HIDAPI_GIP_RESET_FOR_METADATA';
        _const_and_export SDL_HINT_JOYSTICK_IOKIT                          => 'SDL_JOYSTICK_IOKIT';
        _const_and_export SDL_HINT_JOYSTICK_LINUX_CLASSIC                  => 'SDL_JOYSTICK_LINUX_CLASSIC';
        _const_and_export SDL_HINT_JOYSTICK_LINUX_DEADZONES                => 'SDL_JOYSTICK_LINUX_DEADZONES';
        _const_and_export SDL_HINT_JOYSTICK_LINUX_DIGITAL_HATS             => 'SDL_JOYSTICK_LINUX_DIGITAL_HATS';
        _const_and_export SDL_HINT_JOYSTICK_LINUX_HAT_DEADZONES            => 'SDL_JOYSTICK_LINUX_HAT_DEADZONES';
        _const_and_export SDL_HINT_JOYSTICK_MFI                            => 'SDL_JOYSTICK_MFI';
        _const_and_export SDL_HINT_JOYSTICK_RAWINPUT                       => 'SDL_JOYSTICK_RAWINPUT';
        _const_and_export SDL_HINT_JOYSTICK_RAWINPUT_CORRELATE_XINPUT      => 'SDL_JOYSTICK_RAWINPUT_CORRELATE_XINPUT';
        _const_and_export SDL_HINT_JOYSTICK_ROG_CHAKRAM                    => 'SDL_JOYSTICK_ROG_CHAKRAM';
        _const_and_export SDL_HINT_JOYSTICK_THREAD                         => 'SDL_JOYSTICK_THREAD';
        _const_and_export SDL_HINT_JOYSTICK_THROTTLE_DEVICES               => 'SDL_JOYSTICK_THROTTLE_DEVICES';
        _const_and_export SDL_HINT_JOYSTICK_THROTTLE_DEVICES_EXCLUDED      => 'SDL_JOYSTICK_THROTTLE_DEVICES_EXCLUDED';
        _const_and_export SDL_HINT_JOYSTICK_WGI                            => 'SDL_JOYSTICK_WGI';
        _const_and_export SDL_HINT_JOYSTICK_WHEEL_DEVICES                  => 'SDL_JOYSTICK_WHEEL_DEVICES';
        _const_and_export SDL_HINT_JOYSTICK_WHEEL_DEVICES_EXCLUDED         => 'SDL_JOYSTICK_WHEEL_DEVICES_EXCLUDED';
        _const_and_export SDL_HINT_JOYSTICK_ZERO_CENTERED_DEVICES          => 'SDL_JOYSTICK_ZERO_CENTERED_DEVICES';
        _const_and_export SDL_HINT_JOYSTICK_HAPTIC_AXES                    => 'SDL_JOYSTICK_HAPTIC_AXES';
        _const_and_export SDL_HINT_KEYCODE_OPTIONS                         => 'SDL_KEYCODE_OPTIONS';
        _const_and_export SDL_HINT_KMSDRM_DEVICE_INDEX                     => 'SDL_KMSDRM_DEVICE_INDEX';
        _const_and_export SDL_HINT_KMSDRM_REQUIRE_DRM_MASTER               => 'SDL_KMSDRM_REQUIRE_DRM_MASTER';
        _const_and_export SDL_HINT_KMSDRM_ATOMIC                           => 'SDL_KMSDRM_ATOMIC';
        _const_and_export SDL_HINT_LOGGING                                 => 'SDL_LOGGING';
        _const_and_export SDL_HINT_MAC_BACKGROUND_APP                      => 'SDL_MAC_BACKGROUND_APP';
        _const_and_export SDL_HINT_MAC_CTRL_CLICK_EMULATE_RIGHT_CLICK      => 'SDL_MAC_CTRL_CLICK_EMULATE_RIGHT_CLICK';
        _const_and_export SDL_HINT_MAC_OPENGL_ASYNC_DISPATCH               => 'SDL_MAC_OPENGL_ASYNC_DISPATCH';
        _const_and_export SDL_HINT_MAC_OPTION_AS_ALT                       => 'SDL_MAC_OPTION_AS_ALT';
        _const_and_export SDL_HINT_MAC_SCROLL_MOMENTUM                     => 'SDL_MAC_SCROLL_MOMENTUM';
        _const_and_export SDL_HINT_MAIN_CALLBACK_RATE                      => 'SDL_MAIN_CALLBACK_RATE';
        _const_and_export SDL_HINT_MOUSE_AUTO_CAPTURE                      => 'SDL_MOUSE_AUTO_CAPTURE';
        _const_and_export SDL_HINT_MOUSE_DOUBLE_CLICK_RADIUS               => 'SDL_MOUSE_DOUBLE_CLICK_RADIUS';
        _const_and_export SDL_HINT_MOUSE_DOUBLE_CLICK_TIME                 => 'SDL_MOUSE_DOUBLE_CLICK_TIME';
        _const_and_export SDL_HINT_MOUSE_DEFAULT_SYSTEM_CURSOR             => 'SDL_MOUSE_DEFAULT_SYSTEM_CURSOR';
        _const_and_export SDL_HINT_MOUSE_EMULATE_WARP_WITH_RELATIVE        => 'SDL_MOUSE_EMULATE_WARP_WITH_RELATIVE';
        _const_and_export SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH                => 'SDL_MOUSE_FOCUS_CLICKTHROUGH';
        _const_and_export SDL_HINT_MOUSE_NORMAL_SPEED_SCALE                => 'SDL_MOUSE_NORMAL_SPEED_SCALE';
        _const_and_export SDL_HINT_MOUSE_RELATIVE_MODE_CENTER              => 'SDL_MOUSE_RELATIVE_MODE_CENTER';
        _const_and_export SDL_HINT_MOUSE_RELATIVE_SPEED_SCALE              => 'SDL_MOUSE_RELATIVE_SPEED_SCALE';
        _const_and_export SDL_HINT_MOUSE_RELATIVE_SYSTEM_SCALE             => 'SDL_MOUSE_RELATIVE_SYSTEM_SCALE';
        _const_and_export SDL_HINT_MOUSE_RELATIVE_WARP_MOTION              => 'SDL_MOUSE_RELATIVE_WARP_MOTION';
        _const_and_export SDL_HINT_MOUSE_RELATIVE_CURSOR_VISIBLE           => 'SDL_MOUSE_RELATIVE_CURSOR_VISIBLE';
        _const_and_export SDL_HINT_MOUSE_TOUCH_EVENTS                      => 'SDL_MOUSE_TOUCH_EVENTS';
        _const_and_export SDL_HINT_MUTE_CONSOLE_KEYBOARD                   => 'SDL_MUTE_CONSOLE_KEYBOARD';
        _const_and_export SDL_HINT_NO_SIGNAL_HANDLERS                      => 'SDL_NO_SIGNAL_HANDLERS';
        _const_and_export SDL_HINT_OPENGL_LIBRARY                          => 'SDL_OPENGL_LIBRARY';
        _const_and_export SDL_HINT_EGL_LIBRARY                             => 'SDL_EGL_LIBRARY';
        _const_and_export SDL_HINT_OPENGL_ES_DRIVER                        => 'SDL_OPENGL_ES_DRIVER';
        _const_and_export SDL_HINT_OPENVR_LIBRARY                          => 'SDL_OPENVR_LIBRARY';
        _const_and_export SDL_HINT_ORIENTATIONS                            => 'SDL_ORIENTATIONS';
        _const_and_export SDL_HINT_POLL_SENTINEL                           => 'SDL_POLL_SENTINEL';
        _const_and_export SDL_HINT_PREFERRED_LOCALES                       => 'SDL_PREFERRED_LOCALES';
        _const_and_export SDL_HINT_QUIT_ON_LAST_WINDOW_CLOSE               => 'SDL_QUIT_ON_LAST_WINDOW_CLOSE';
        _const_and_export SDL_HINT_RENDER_DIRECT3D_THREADSAFE              => 'SDL_RENDER_DIRECT3D_THREADSAFE';
        _const_and_export SDL_HINT_RENDER_DIRECT3D11_DEBUG                 => 'SDL_RENDER_DIRECT3D11_DEBUG';
        _const_and_export SDL_HINT_RENDER_DIRECT3D11_WARP                  => 'SDL_RENDER_DIRECT3D11_WARP';
        _const_and_export SDL_HINT_RENDER_VULKAN_DEBUG                     => 'SDL_RENDER_VULKAN_DEBUG';
        _const_and_export SDL_HINT_RENDER_GPU_DEBUG                        => 'SDL_RENDER_GPU_DEBUG';
        _const_and_export SDL_HINT_RENDER_GPU_LOW_POWER                    => 'SDL_RENDER_GPU_LOW_POWER';
        _const_and_export SDL_HINT_RENDER_DRIVER                           => 'SDL_RENDER_DRIVER';
        _const_and_export SDL_HINT_RENDER_LINE_METHOD                      => 'SDL_RENDER_LINE_METHOD';
        _const_and_export SDL_HINT_RENDER_METAL_PREFER_LOW_POWER_DEVICE    => 'SDL_RENDER_METAL_PREFER_LOW_POWER_DEVICE';
        _const_and_export SDL_HINT_RENDER_VSYNC                            => 'SDL_RENDER_VSYNC';
        _const_and_export SDL_HINT_RETURN_KEY_HIDES_IME                    => 'SDL_RETURN_KEY_HIDES_IME';
        _const_and_export SDL_HINT_ROG_GAMEPAD_MICE                        => 'SDL_ROG_GAMEPAD_MICE';
        _const_and_export SDL_HINT_ROG_GAMEPAD_MICE_EXCLUDED               => 'SDL_ROG_GAMEPAD_MICE_EXCLUDED';
        _const_and_export SDL_HINT_PS2_GS_WIDTH                            => 'SDL_PS2_GS_WIDTH';
        _const_and_export SDL_HINT_PS2_GS_HEIGHT                           => 'SDL_PS2_GS_HEIGHT';
        _const_and_export SDL_HINT_PS2_GS_PROGRESSIVE                      => 'SDL_PS2_GS_PROGRESSIVE';
        _const_and_export SDL_HINT_PS2_GS_MODE                             => 'SDL_PS2_GS_MODE';
        _const_and_export SDL_HINT_RPI_VIDEO_LAYER                         => 'SDL_RPI_VIDEO_LAYER';
        _const_and_export SDL_HINT_SCREENSAVER_INHIBIT_ACTIVITY_NAME       => 'SDL_SCREENSAVER_INHIBIT_ACTIVITY_NAME';
        _const_and_export SDL_HINT_SHUTDOWN_DBUS_ON_QUIT                   => 'SDL_SHUTDOWN_DBUS_ON_QUIT';
        _const_and_export SDL_HINT_STORAGE_TITLE_DRIVER                    => 'SDL_STORAGE_TITLE_DRIVER';
        _const_and_export SDL_HINT_STORAGE_USER_DRIVER                     => 'SDL_STORAGE_USER_DRIVER';
        _const_and_export SDL_HINT_THREAD_FORCE_REALTIME_TIME_CRITICAL     => 'SDL_THREAD_FORCE_REALTIME_TIME_CRITICAL';
        _const_and_export SDL_HINT_THREAD_PRIORITY_POLICY                  => 'SDL_THREAD_PRIORITY_POLICY';
        _const_and_export SDL_HINT_TIMER_RESOLUTION                        => 'SDL_TIMER_RESOLUTION';
        _const_and_export SDL_HINT_TOUCH_MOUSE_EVENTS                      => 'SDL_TOUCH_MOUSE_EVENTS';
        _const_and_export SDL_HINT_TRACKPAD_IS_TOUCH_ONLY                  => 'SDL_TRACKPAD_IS_TOUCH_ONLY';
        _const_and_export SDL_HINT_TV_REMOTE_AS_JOYSTICK                   => 'SDL_TV_REMOTE_AS_JOYSTICK';
        _const_and_export SDL_HINT_VIDEO_ALLOW_SCREENSAVER                 => 'SDL_VIDEO_ALLOW_SCREENSAVER';
        _const_and_export SDL_HINT_VIDEO_DISPLAY_PRIORITY                  => 'SDL_VIDEO_DISPLAY_PRIORITY';
        _const_and_export SDL_HINT_VIDEO_DOUBLE_BUFFER                     => 'SDL_VIDEO_DOUBLE_BUFFER';
        _const_and_export SDL_HINT_VIDEO_DRIVER                            => 'SDL_VIDEO_DRIVER';
        _const_and_export SDL_HINT_VIDEO_DUMMY_SAVE_FRAMES                 => 'SDL_VIDEO_DUMMY_SAVE_FRAMES';
        _const_and_export SDL_HINT_VIDEO_EGL_ALLOW_GETDISPLAY_FALLBACK     => 'SDL_VIDEO_EGL_ALLOW_GETDISPLAY_FALLBACK';
        _const_and_export SDL_HINT_VIDEO_FORCE_EGL                         => 'SDL_VIDEO_FORCE_EGL';
        _const_and_export SDL_HINT_VIDEO_MAC_FULLSCREEN_SPACES             => 'SDL_VIDEO_MAC_FULLSCREEN_SPACES';
        _const_and_export SDL_HINT_VIDEO_MAC_FULLSCREEN_MENU_VISIBILITY    => 'SDL_VIDEO_MAC_FULLSCREEN_MENU_VISIBILITY';
        _const_and_export SDL_HINT_VIDEO_METAL_AUTO_RESIZE_DRAWABLE        => 'SDL_VIDEO_METAL_AUTO_RESIZE_DRAWABLE';
        _const_and_export SDL_HINT_VIDEO_MATCH_EXCLUSIVE_MODE_ON_MOVE      => 'SDL_VIDEO_MATCH_EXCLUSIVE_MODE_ON_MOVE';
        _const_and_export SDL_HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS            => 'SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS';
        _const_and_export SDL_HINT_VIDEO_OFFSCREEN_SAVE_FRAMES             => 'SDL_VIDEO_OFFSCREEN_SAVE_FRAMES';
        _const_and_export SDL_HINT_VIDEO_SYNC_WINDOW_OPERATIONS            => 'SDL_VIDEO_SYNC_WINDOW_OPERATIONS';
        _const_and_export SDL_HINT_VIDEO_WAYLAND_ALLOW_LIBDECOR            => 'SDL_VIDEO_WAYLAND_ALLOW_LIBDECOR';
        _const_and_export SDL_HINT_VIDEO_WAYLAND_MODE_EMULATION            => 'SDL_VIDEO_WAYLAND_MODE_EMULATION';
        _const_and_export SDL_HINT_VIDEO_WAYLAND_MODE_SCALING              => 'SDL_VIDEO_WAYLAND_MODE_SCALING';
        _const_and_export SDL_HINT_VIDEO_WAYLAND_PREFER_LIBDECOR           => 'SDL_VIDEO_WAYLAND_PREFER_LIBDECOR';
        _const_and_export SDL_HINT_VIDEO_WAYLAND_SCALE_TO_DISPLAY          => 'SDL_VIDEO_WAYLAND_SCALE_TO_DISPLAY';
        _const_and_export SDL_HINT_VIDEO_WIN_D3DCOMPILER                   => 'SDL_VIDEO_WIN_D3DCOMPILER';
        _const_and_export SDL_HINT_VIDEO_X11_EXTERNAL_WINDOW_INPUT         => 'SDL_VIDEO_X11_EXTERNAL_WINDOW_INPUT';
        _const_and_export SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR      => 'SDL_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR';
        _const_and_export SDL_HINT_VIDEO_X11_NET_WM_PING                   => 'SDL_VIDEO_X11_NET_WM_PING';
        _const_and_export SDL_HINT_VIDEO_X11_NODIRECTCOLOR                 => 'SDL_VIDEO_X11_NODIRECTCOLOR';
        _const_and_export SDL_HINT_VIDEO_X11_SCALING_FACTOR                => 'SDL_VIDEO_X11_SCALING_FACTOR';
        _const_and_export SDL_HINT_VIDEO_X11_VISUALID                      => 'SDL_VIDEO_X11_VISUALID';
        _const_and_export SDL_HINT_VIDEO_X11_WINDOW_VISUALID               => 'SDL_VIDEO_X11_WINDOW_VISUALID';
        _const_and_export SDL_HINT_VIDEO_X11_XRANDR                        => 'SDL_VIDEO_X11_XRANDR';
        _const_and_export SDL_HINT_VITA_ENABLE_BACK_TOUCH                  => 'SDL_VITA_ENABLE_BACK_TOUCH';
        _const_and_export SDL_HINT_VITA_ENABLE_FRONT_TOUCH                 => 'SDL_VITA_ENABLE_FRONT_TOUCH';
        _const_and_export SDL_HINT_VITA_MODULE_PATH                        => 'SDL_VITA_MODULE_PATH';
        _const_and_export SDL_HINT_VITA_PVR_INIT                           => 'SDL_VITA_PVR_INIT';
        _const_and_export SDL_HINT_VITA_RESOLUTION                         => 'SDL_VITA_RESOLUTION';
        _const_and_export SDL_HINT_VITA_PVR_OPENGL                         => 'SDL_VITA_PVR_OPENGL';
        _const_and_export SDL_HINT_VITA_TOUCH_MOUSE_DEVICE                 => 'SDL_VITA_TOUCH_MOUSE_DEVICE';
        _const_and_export SDL_HINT_VULKAN_DISPLAY                          => 'SDL_VULKAN_DISPLAY';
        _const_and_export SDL_HINT_VULKAN_LIBRARY                          => 'SDL_VULKAN_LIBRARY';
        _const_and_export SDL_HINT_WAVE_FACT_CHUNK                         => 'SDL_WAVE_FACT_CHUNK';
        _const_and_export SDL_HINT_WAVE_CHUNK_LIMIT                        => 'SDL_WAVE_CHUNK_LIMIT';
        _const_and_export SDL_HINT_WAVE_RIFF_CHUNK_SIZE                    => 'SDL_WAVE_RIFF_CHUNK_SIZE';
        _const_and_export SDL_HINT_WAVE_TRUNCATION                         => 'SDL_WAVE_TRUNCATION';
        _const_and_export SDL_HINT_WINDOW_ACTIVATE_WHEN_RAISED             => 'SDL_WINDOW_ACTIVATE_WHEN_RAISED';
        _const_and_export SDL_HINT_WINDOW_ACTIVATE_WHEN_SHOWN              => 'SDL_WINDOW_ACTIVATE_WHEN_SHOWN';
        _const_and_export SDL_HINT_WINDOW_ALLOW_TOPMOST                    => 'SDL_WINDOW_ALLOW_TOPMOST';
        _const_and_export SDL_HINT_WINDOW_FRAME_USABLE_WHILE_CURSOR_HIDDEN => 'SDL_WINDOW_FRAME_USABLE_WHILE_CURSOR_HIDDEN';
        _const_and_export SDL_HINT_WINDOWS_CLOSE_ON_ALT_F4                 => 'SDL_WINDOWS_CLOSE_ON_ALT_F4';
        _const_and_export SDL_HINT_WINDOWS_ENABLE_MENU_MNEMONICS           => 'SDL_WINDOWS_ENABLE_MENU_MNEMONICS';
        _const_and_export SDL_HINT_WINDOWS_ENABLE_MESSAGELOOP              => 'SDL_WINDOWS_ENABLE_MESSAGELOOP';
        _const_and_export SDL_HINT_WINDOWS_GAMEINPUT                       => 'SDL_WINDOWS_GAMEINPUT';
        _const_and_export SDL_HINT_WINDOWS_RAW_KEYBOARD                    => 'SDL_WINDOWS_RAW_KEYBOARD';
        _const_and_export SDL_HINT_WINDOWS_RAW_KEYBOARD_EXCLUDE_HOTKEYS    => 'SDL_WINDOWS_RAW_KEYBOARD_EXCLUDE_HOTKEYS';
        _const_and_export SDL_HINT_WINDOWS_FORCE_SEMAPHORE_KERNEL          => 'SDL_WINDOWS_FORCE_SEMAPHORE_KERNEL';
        _const_and_export SDL_HINT_WINDOWS_INTRESOURCE_ICON                => 'SDL_WINDOWS_INTRESOURCE_ICON';
        _const_and_export SDL_HINT_WINDOWS_INTRESOURCE_ICON_SMALL          => 'SDL_WINDOWS_INTRESOURCE_ICON_SMALL';
        _const_and_export SDL_HINT_WINDOWS_USE_D3D9EX                      => 'SDL_WINDOWS_USE_D3D9EX';
        _const_and_export SDL_HINT_WINDOWS_ERASE_BACKGROUND_MODE           => 'SDL_WINDOWS_ERASE_BACKGROUND_MODE';
        _const_and_export SDL_HINT_X11_FORCE_OVERRIDE_REDIRECT             => 'SDL_X11_FORCE_OVERRIDE_REDIRECT';
        _const_and_export SDL_HINT_X11_WINDOW_TYPE                         => 'SDL_X11_WINDOW_TYPE';
        _const_and_export SDL_HINT_X11_XCB_LIBRARY                         => 'SDL_X11_XCB_LIBRARY';
        _const_and_export SDL_HINT_XINPUT_ENABLED                          => 'SDL_XINPUT_ENABLED';
        _const_and_export SDL_HINT_ASSERT                                  => 'SDL_ASSERT';
        _const_and_export SDL_HINT_PEN_MOUSE_EVENTS                        => 'SDL_PEN_MOUSE_EVENTS';
        _const_and_export SDL_HINT_PEN_TOUCH_EVENTS                        => 'SDL_PEN_TOUCH_EVENTS';
        _enum_and_export SDL_HintPriority => [ 'SDL_HINT_DEFAULT', 'SDL_HINT_NORMAL', 'SDL_HINT_OVERRIDE' ];
        _affix_and_export SDL_SetHintWithPriority => [ String, String, SDL_HintPriority() ], Bool;
        _affix_and_export SDL_SetHint             => [ String, String ], Bool;
        _affix_and_export SDL_ResetHint           => [String], Bool;
        _affix_and_export SDL_ResetHints          => [], Void;
        _affix_and_export SDL_GetHint             => [String], String;
        _affix_and_export SDL_GetHintBoolean      => [ String, Bool ], Bool;
        _typedef_and_export SDL_HintCallback => Callback [ [ Pointer [Void], String, String, String ] => Void ];
        _affix_and_export SDL_AddHintCallback    => [ String, SDL_HintCallback(), Pointer [Void] ], Bool;
        _affix_and_export SDL_RemoveHintCallback => [ String, SDL_HintCallback(), Pointer [Void] ], Void;
    }

=head3 C<:init> - Initialization and Shutdown

All SDL programs need to initialize the library before starting to work with it.

See L<SDL3: CategoryInit|https://wiki.libsdl.org/SDL3/CategoryInit>

=cut

    sub _init() {    # Based on sdl-main/include/sdl3/sdl_init.h
        state $done++ && return;
        _stdinc();
        _error();
        _events();
        #
        _typedef_and_export SDL_InitFlags => UInt32;
        _const_and_export SDL_INIT_AUDIO    => 0x00000010;
        _const_and_export SDL_INIT_VIDEO    => 0x00000020;
        _const_and_export SDL_INIT_JOYSTICK => 0x00000200;
        _const_and_export SDL_INIT_HAPTIC   => 0x00001000;
        _const_and_export SDL_INIT_GAMEPAD  => 0x00002000;
        _const_and_export SDL_INIT_EVENTS   => 0x00004000;
        _const_and_export SDL_INIT_SENSOR   => 0x00008000;
        _const_and_export SDL_INIT_CAMERA   => 0x00010000;
        _enum_and_export SDL_AppResult => [ [ SDL_APP_CONTINUE => 0 ], [ SDL_APP_SUCCESS => 1 ], [ SDL_APP_FAILURE => 2 ] ];
        _typedef_and_export SDL_AppInit_func    => Callback [ [ Pointer [ Pointer [Void] ], Int, Pointer [String] ] => SDL_AppResult() ];
        _typedef_and_export SDL_AppIterate_func => Callback [ [ Pointer [Void] ]                                    => SDL_AppResult() ];
        _typedef_and_export SDL_AppEvent_func   => Callback [ [ Pointer [Void], SDL_Event() ]                       => SDL_AppResult() ];
        _typedef_and_export SDL_AppQuit_func    => Callback [ [ Pointer [Void], SDL_AppResult() ]                   => Void ];
        _affix_and_export SDL_Init          => [ SDL_InitFlags() ], Bool;
        _affix_and_export SDL_InitSubSystem => [ SDL_InitFlags() ], Bool;
        _affix_and_export SDL_QuitSubSystem => [ SDL_InitFlags() ], Void;
        _affix_and_export SDL_WasInit       => [ SDL_InitFlags() ], SDL_InitFlags();
        _affix_and_export SDL_Quit          => [], Void;
        _affix_and_export SDL_IsMainThread  => [], Bool;
        _typedef_and_export SDL_MainThreadCallback => Callback [ [ Pointer [Void] ] => Void ];
        _affix_and_export SDL_RunOnMainThread        => [ SDL_MainThreadCallback(), Pointer [Void], Bool ], Bool;
        _affix_and_export SDL_SetAppMetadata         => [ String, String, String ], Bool;
        _affix_and_export SDL_SetAppMetadataProperty => [ String, String ], Bool;
        _const_and_export SDL_PROP_APP_METADATA_NAME_STRING       => 'SDL.app.metadata.name';
        _const_and_export SDL_PROP_APP_METADATA_VERSION_STRING    => 'SDL.app.metadata.version';
        _const_and_export SDL_PROP_APP_METADATA_IDENTIFIER_STRING => 'SDL.app.metadata.identifier';
        _const_and_export SDL_PROP_APP_METADATA_CREATOR_STRING    => 'SDL.app.metadata.creator';
        _const_and_export SDL_PROP_APP_METADATA_COPYRIGHT_STRING  => 'SDL.app.metadata.copyright';
        _const_and_export SDL_PROP_APP_METADATA_URL_STRING        => 'SDL.app.metadata.url';
        _const_and_export SDL_PROP_APP_METADATA_TYPE_STRING       => 'SDL.app.metadata.type';
        _affix_and_export SDL_GetAppMetadataProperty => [String], String;
    }

=head3 C<:iostream> - I/O Streams

SDL provides an abstract interface for reading and writing data streams. It offers implementations for files, memory,
etc, and the app can provide their own implementations, too.

SDL_IOStream is not related to the standard C++ iostream class, other than both are abstract interfaces to read/write
data.

See L<SDL3: CategoryIOStream|https://wiki.libsdl.org/SDL3/CategoryIOStream>

=cut

    sub _iostream() {
        state $done++ && return;
        _error();
        _properties();
        _stdinc();
        #
        _enum_and_export SDL_IOStatus => [
            'SDL_IO_STATUS_READY',    'SDL_IO_STATUS_ERROR', 'SDL_IO_STATUS_EOF', 'SDL_IO_STATUS_NOT_READY',
            'SDL_IO_STATUS_READONLY', 'SDL_IO_STATUS_WRITEONLY'
        ];
        _enum_and_export SDL_IOWhence => [ 'SDL_IO_SEEK_SET', 'SDL_IO_SEEK_CUR', 'SDL_IO_SEEK_END' ];
        _typedef_and_export SDL_IOStreamInterface => Struct [
            version => UInt32,
            size    => Callback [ [ Pointer [Void] ]                                                     => SInt64 ],
            seek    => Callback [ [ Pointer [Void], SInt64, SDL_IOWhence() ]                             => SInt64 ],
            read    => Callback [ [ Pointer [Void], Pointer [Void], Size_t, Pointer [ SDL_IOStatus() ] ] => Size_t ],
            write   => Callback [ [ Pointer [Void], Pointer [Void], Size_t, Pointer [ SDL_IOStatus() ] ] => Size_t ],
            flush   => Callback [ [ Pointer [Void], Pointer [ SDL_IOStatus() ] ]                         => Bool ],
            close   => Callback [ [ Pointer [Void] ]                                                     => Bool ]
        ];
        _typedef_and_export SDL_IOStream => Void;
        _affix_and_export SDL_IOFromFile => [ String, String ], Pointer [ SDL_IOStream() ];
        _const_and_export SDL_PROP_IOSTREAM_WINDOWS_HANDLE_POINTER => 'SDL.iostream.windows.handle';
        _const_and_export SDL_PROP_IOSTREAM_STDIO_FILE_POINTER     => 'SDL.iostream.stdio.file';
        _const_and_export SDL_PROP_IOSTREAM_FILE_DESCRIPTOR_NUMBER => 'SDL.iostream.file_descriptor';
        _const_and_export SDL_PROP_IOSTREAM_ANDROID_AASSET_POINTER => 'SDL.iostream.android.aasset';
        _affix_and_export SDL_IOFromMem => [ Pointer [Void], Size_t ], Pointer [ SDL_IOStream() ];
        _const_and_export SDL_PROP_IOSTREAM_MEMORY_POINTER           => 'SDL.iostream.memory.base';
        _const_and_export SDL_PROP_IOSTREAM_MEMORY_SIZE_NUMBER       => 'SDL.iostream.memory.size';
        _const_and_export SDL_PROP_IOSTREAM_MEMORY_FREE_FUNC_POINTER => 'SDL.iostream.memory.free';
        _affix_and_export SDL_IOFromConstMem => [ Pointer [Void], Size_t ], Pointer [ SDL_IOStream() ];
        _affix_and_export SDL_IOFromDynamicMem => [], Pointer [ SDL_IOStream() ];
        _const_and_export SDL_PROP_IOSTREAM_DYNAMIC_MEMORY_POINTER   => 'SDL.iostream.dynamic.memory';
        _const_and_export SDL_PROP_IOSTREAM_DYNAMIC_CHUNKSIZE_NUMBER => 'SDL.iostream.dynamic.chunksize';
        _affix_and_export
            SDL_OpenIO => [ Pointer [ SDL_IOStreamInterface() ], Pointer [Void] ],
            Pointer [ SDL_IOStream() ];
        _affix_and_export SDL_CloseIO         => [ Pointer [ SDL_IOStream() ] ], Bool;
        _affix_and_export SDL_GetIOProperties => [ Pointer [ SDL_IOStream() ] ], SDL_PropertiesID();
        _affix_and_export SDL_GetIOStatus     => [ Pointer [ SDL_IOStream() ] ], SDL_IOStatus();
        _affix_and_export SDL_GetIOSize       => [ Pointer [ SDL_IOStream() ] ], SInt64;
        _affix_and_export SDL_SeekIO          => [ Pointer [ SDL_IOStream() ], SInt64, SDL_IOWhence() ], SInt64;
        _affix_and_export SDL_TellIO          => [ Pointer [ SDL_IOStream() ] ], SInt64;
        _affix_and_export SDL_ReadIO          => [ Pointer [ SDL_IOStream() ], Pointer [Void], Size_t ], Size_t;
        _affix_and_export SDL_WriteIO         => [ Pointer [ SDL_IOStream() ], Pointer [Void], Size_t ], Size_t;

        #~ _affix_and_export SDL_IOprintf        => [ Pointer [ SDL_IOStream() ], String, VarArgs ], Size_t;
        #~ _affix_and_export SDL_IOvprintf => [ Pointer [ SDL_IOStream() ], String, Pointer [Void] ], Size_t;
        _affix_and_export SDL_FlushIO     => [ Pointer [ SDL_IOStream() ] ], Bool;
        _affix_and_export SDL_LoadFile_IO => [ Pointer [ SDL_IOStream() ], Pointer [Size_t], Bool ], Pointer [Void];
        _affix_and_export SDL_LoadFile    => [ String, Pointer [Size_t] ], Pointer [Void];
        _affix_and_export SDL_SaveFile_IO => [ Pointer [ SDL_IOStream() ], Pointer [Void], Size_t, Bool ], Bool;
        _affix_and_export SDL_SaveFile    => [ String, Pointer [Void], Size_t ], Bool;
        _affix_and_export SDL_ReadU8      => [ Pointer [ SDL_IOStream() ], Pointer [UInt8] ],  Bool;
        _affix_and_export SDL_ReadS8      => [ Pointer [ SDL_IOStream() ], Pointer [SInt8] ],  Bool;
        _affix_and_export SDL_ReadU16LE   => [ Pointer [ SDL_IOStream() ], Pointer [UInt16] ], Bool;
        _affix_and_export SDL_ReadS16LE   => [ Pointer [ SDL_IOStream() ], Pointer [SInt16] ], Bool;
        _affix_and_export SDL_ReadU16BE   => [ Pointer [ SDL_IOStream() ], Pointer [UInt16] ], Bool;
        _affix_and_export SDL_ReadS16BE   => [ Pointer [ SDL_IOStream() ], Pointer [SInt16] ], Bool;
        _affix_and_export SDL_ReadU32LE   => [ Pointer [ SDL_IOStream() ], Pointer [UInt32] ], Bool;
        _affix_and_export SDL_ReadS32LE   => [ Pointer [ SDL_IOStream() ], Pointer [SInt32] ], Bool;
        _affix_and_export SDL_ReadU32BE   => [ Pointer [ SDL_IOStream() ], Pointer [UInt32] ], Bool;
        _affix_and_export SDL_ReadS32BE   => [ Pointer [ SDL_IOStream() ], Pointer [SInt32] ], Bool;
        _affix_and_export SDL_ReadU64LE   => [ Pointer [ SDL_IOStream() ], Pointer [UInt64] ], Bool;
        _affix_and_export SDL_ReadS64LE   => [ Pointer [ SDL_IOStream() ], Pointer [SInt64] ], Bool;
        _affix_and_export SDL_ReadU64BE   => [ Pointer [ SDL_IOStream() ], Pointer [UInt64] ], Bool;
        _affix_and_export SDL_ReadS64BE   => [ Pointer [ SDL_IOStream() ], Pointer [SInt64] ], Bool;
        _affix_and_export SDL_WriteU8     => [ Pointer [ SDL_IOStream() ], UInt8 ],  Bool;
        _affix_and_export SDL_WriteS8     => [ Pointer [ SDL_IOStream() ], SInt8 ],  Bool;
        _affix_and_export SDL_WriteU16LE  => [ Pointer [ SDL_IOStream() ], UInt16 ], Bool;
        _affix_and_export SDL_WriteS16LE  => [ Pointer [ SDL_IOStream() ], SInt16 ], Bool;
        _affix_and_export SDL_WriteU16BE  => [ Pointer [ SDL_IOStream() ], UInt16 ], Bool;
        _affix_and_export SDL_WriteS16BE  => [ Pointer [ SDL_IOStream() ], SInt16 ], Bool;
        _affix_and_export SDL_WriteU32LE  => [ Pointer [ SDL_IOStream() ], UInt32 ], Bool;
        _affix_and_export SDL_WriteS32LE  => [ Pointer [ SDL_IOStream() ], SInt32 ], Bool;
        _affix_and_export SDL_WriteU32BE  => [ Pointer [ SDL_IOStream() ], UInt32 ], Bool;
        _affix_and_export SDL_WriteS32BE  => [ Pointer [ SDL_IOStream() ], SInt32 ], Bool;
        _affix_and_export SDL_WriteU64LE  => [ Pointer [ SDL_IOStream() ], UInt64 ], Bool;
        _affix_and_export SDL_WriteS64LE  => [ Pointer [ SDL_IOStream() ], SInt64 ], Bool;
        _affix_and_export SDL_WriteU64BE  => [ Pointer [ SDL_IOStream() ], UInt64 ], Bool;
        _affix_and_export SDL_WriteS64BE  => [ Pointer [ SDL_IOStream() ], SInt64 ], Bool;
    }

=head3 C<:joystick> - Joystick Support

SDL joystick support.

This is the lower-level joystick handling. If you want the simpler option, where what each button does is well-defined,
you should use the gamepad API instead.

See L<SDL3: CategoryJoystick|https://wiki.libsdl.org/SDL3/CategoryJoystick>

=cut

    sub _joystick() {
        state $done++ && return;
        _error();
        _guid();
        _mutex();
        _power();
        _properties();
        _sensor();
        _stdinc();
        #
        _typedef_and_export SDL_Joystick   => Void;
        _typedef_and_export SDL_JoystickID => UInt32;
        _enum_and_export SDL_JoystickType => [
            'SDL_JOYSTICK_TYPE_UNKNOWN',      'SDL_JOYSTICK_TYPE_GAMEPAD',   'SDL_JOYSTICK_TYPE_WHEEL',  'SDL_JOYSTICK_TYPE_ARCADE_STICK',
            'SDL_JOYSTICK_TYPE_FLIGHT_STICK', 'SDL_JOYSTICK_TYPE_DANCE_PAD', 'SDL_JOYSTICK_TYPE_GUITAR', 'SDL_JOYSTICK_TYPE_DRUM_KIT',
            'SDL_JOYSTICK_TYPE_ARCADE_PAD',   'SDL_JOYSTICK_TYPE_THROTTLE',  'SDL_JOYSTICK_TYPE_COUNT'
        ];
        _enum_and_export SDL_JoystickConnectionState => [
            [ SDL_JOYSTICK_CONNECTION_INVALID => -1 ], 'SDL_JOYSTICK_CONNECTION_UNKNOWN',
            'SDL_JOYSTICK_CONNECTION_WIRED',           'SDL_JOYSTICK_CONNECTION_WIRELESS'
        ];
        _const_and_export SDL_JOYSTICK_AXIS_MAX => 32767;
        _const_and_export SDL_JOYSTICK_AXIS_MIN => -32768;
        _affix_and_export SDL_LockJoysticks                  => [], Void;
        _affix_and_export SDL_UnlockJoysticks                => [], Void;
        _affix_and_export SDL_HasJoystick                    => [], Bool;
        _affix_and_export SDL_GetJoysticks                   => [ Pointer [Int] ], Pointer [ SDL_JoystickID() ];
        _affix_and_export SDL_GetJoystickNameForID           => [ SDL_JoystickID() ], String;
        _affix_and_export SDL_GetJoystickPathForID           => [ SDL_JoystickID() ], String;
        _affix_and_export SDL_GetJoystickPlayerIndexForID    => [ SDL_JoystickID() ], Int;
        _affix_and_export SDL_GetJoystickGUIDForID           => [ SDL_JoystickID() ], SDL_GUID();
        _affix_and_export SDL_GetJoystickVendorForID         => [ SDL_JoystickID() ], UInt16;
        _affix_and_export SDL_GetJoystickProductForID        => [ SDL_JoystickID() ], UInt16;
        _affix_and_export SDL_GetJoystickProductVersionForID => [ SDL_JoystickID() ], UInt16;
        _affix_and_export SDL_GetJoystickTypeForID           => [ SDL_JoystickID() ], SDL_JoystickType();
        _affix_and_export SDL_OpenJoystick                   => [ SDL_JoystickID() ], Pointer [ SDL_Joystick() ];
        _affix_and_export SDL_GetJoystickFromID              => [ SDL_JoystickID() ], Pointer [ SDL_Joystick() ];
        _affix_and_export SDL_GetJoystickFromPlayerIndex     => [Int], Pointer [ SDL_Joystick() ];
        _typedef_and_export SDL_VirtualJoystickTouchpadDesc => Struct [ nfingers => UInt16, padding => Array [ UInt16, 3 ] ];
        _typedef_and_export SDL_VirtualJoystickSensorDesc => Struct [ type => SDL_SensorType(), rate => Float ];
        _typedef_and_export SDL_VirtualJoystickDesc => Struct [
            version           => UInt32,
            type              => UInt16,
            padding           => UInt16,
            vendor_id         => UInt16,
            product_id        => UInt16,
            naxes             => UInt16,
            nbuttons          => UInt16,
            nballs            => UInt16,
            nhats             => UInt16,
            ntouchpads        => UInt16,
            nsensors          => UInt16,
            padding2          => Array [ UInt16, 2 ],
            button_mask       => UInt32,
            axis_mask         => UInt32,
            name              => String,
            touchpads         => Pointer [ SDL_VirtualJoystickTouchpadDesc() ],
            sensors           => Pointer [ SDL_VirtualJoystickSensorDesc() ],
            userdata          => Pointer [Void],
            Update            => Callback [ [ Pointer [Void] ]                      => Void ],
            SetPlayerIndex    => Callback [ [ Pointer [Void], Int ]                 => Void ],
            Rumble            => Callback [ [ Pointer [Void], UInt16, UInt16 ]      => Bool ],
            RumbleTriggers    => Callback [ [ Pointer [Void], UInt16, UInt16 ]      => Bool ],
            SetLED            => Callback [ [ Pointer [Void], UInt8, UInt8, UInt8 ] => Bool ],
            SendEffect        => Callback [ [ Pointer [Void], Pointer [Void], Int ] => Bool ],
            SetSensorsEnabled => Callback [ [ Pointer [Void], Bool ]                => Bool ],
            Cleanup           => Callback [ [ Pointer [Void] ]                      => Void ]
        ];
        _affix_and_export SDL_AttachVirtualJoystick      => [ Pointer [ SDL_VirtualJoystickDesc() ] ], SDL_JoystickID();
        _affix_and_export SDL_DetachVirtualJoystick      => [ SDL_JoystickID() ], Bool;
        _affix_and_export SDL_IsJoystickVirtual          => [ SDL_JoystickID() ], Bool;
        _affix_and_export SDL_SetJoystickVirtualAxis     => [ Pointer [ SDL_Joystick() ], Int, SInt16 ], Bool;
        _affix_and_export SDL_SetJoystickVirtualBall     => [ Pointer [ SDL_Joystick() ], Int, SInt16, SInt16 ], Bool;
        _affix_and_export SDL_SetJoystickVirtualButton   => [ Pointer [ SDL_Joystick() ], Int, Bool ],  Bool;
        _affix_and_export SDL_SetJoystickVirtualHat      => [ Pointer [ SDL_Joystick() ], Int, UInt8 ], Bool;
        _affix_and_export SDL_SetJoystickVirtualTouchpad => [ Pointer [ SDL_Joystick() ], Int, Int, Bool, Float, Float, Float ], Bool;
        _affix_and_export
            SDL_SendJoystickVirtualSensorData => [ Pointer [ SDL_Joystick() ], SDL_SensorType(), UInt64, Pointer [Float], Int ],
            Bool;
        _affix_and_export SDL_GetJoystickProperties => [ Pointer [ SDL_Joystick() ] ], SDL_PropertiesID();
        _const_and_export SDL_PROP_JOYSTICK_CAP_MONO_LED_BOOLEAN       => 'SDL.joystick.cap.mono_led';
        _const_and_export SDL_PROP_JOYSTICK_CAP_RGB_LED_BOOLEAN        => 'SDL.joystick.cap.rgb_led';
        _const_and_export SDL_PROP_JOYSTICK_CAP_PLAYER_LED_BOOLEAN     => 'SDL.joystick.cap.player_led';
        _const_and_export SDL_PROP_JOYSTICK_CAP_RUMBLE_BOOLEAN         => 'SDL.joystick.cap.rumble';
        _const_and_export SDL_PROP_JOYSTICK_CAP_TRIGGER_RUMBLE_BOOLEAN => 'SDL.joystick.cap.trigger_rumble';
        _affix_and_export SDL_GetJoystickName            => [ Pointer [ SDL_Joystick() ] ], String;
        _affix_and_export SDL_GetJoystickPath            => [ Pointer [ SDL_Joystick() ] ], String;
        _affix_and_export SDL_GetJoystickPlayerIndex     => [ Pointer [ SDL_Joystick() ] ], Int;
        _affix_and_export SDL_SetJoystickPlayerIndex     => [ Pointer [ SDL_Joystick() ], Int ], Bool;
        _affix_and_export SDL_GetJoystickGUID            => [ Pointer [ SDL_Joystick() ] ], SDL_GUID();
        _affix_and_export SDL_GetJoystickVendor          => [ Pointer [ SDL_Joystick() ] ], UInt16;
        _affix_and_export SDL_GetJoystickProduct         => [ Pointer [ SDL_Joystick() ] ], UInt16;
        _affix_and_export SDL_GetJoystickProductVersion  => [ Pointer [ SDL_Joystick() ] ], UInt16;
        _affix_and_export SDL_GetJoystickFirmwareVersion => [ Pointer [ SDL_Joystick() ] ], UInt16;
        _affix_and_export SDL_GetJoystickSerial          => [ Pointer [ SDL_Joystick() ] ], String;
        _affix_and_export SDL_GetJoystickType            => [ Pointer [ SDL_Joystick() ] ], SDL_JoystickType();
        _affix_and_export
            SDL_GetJoystickGUIDInfo => [ SDL_GUID(), Pointer [UInt16], Pointer [UInt16], Pointer [UInt16], Pointer [UInt16] ],
            Void;
        _affix_and_export SDL_JoystickConnected           => [ Pointer [ SDL_Joystick() ] ], Bool;
        _affix_and_export SDL_GetJoystickID               => [ Pointer [ SDL_Joystick() ] ], SDL_JoystickID();
        _affix_and_export SDL_GetNumJoystickAxes          => [ Pointer [ SDL_Joystick() ] ], Int;
        _affix_and_export SDL_GetNumJoystickBalls         => [ Pointer [ SDL_Joystick() ] ], Int;
        _affix_and_export SDL_GetNumJoystickHats          => [ Pointer [ SDL_Joystick() ] ], Int;
        _affix_and_export SDL_GetNumJoystickButtons       => [ Pointer [ SDL_Joystick() ] ], Int;
        _affix_and_export SDL_SetJoystickEventsEnabled    => [Bool], Void;
        _affix_and_export SDL_JoystickEventsEnabled       => [], Bool;
        _affix_and_export SDL_UpdateJoysticks             => [], Void;
        _affix_and_export SDL_GetJoystickAxis             => [ Pointer [ SDL_Joystick() ], Int ], SInt16;
        _affix_and_export SDL_GetJoystickAxisInitialState => [ Pointer [ SDL_Joystick() ], Int, Pointer [SInt16] ], Bool;
        _affix_and_export SDL_GetJoystickBall             => [ Pointer [ SDL_Joystick() ], Int, Pointer [Int], Pointer [Int] ], Bool;
        _affix_and_export SDL_GetJoystickHat              => [ Pointer [ SDL_Joystick() ], Int ], UInt8;
        _const_and_export SDL_HAT_CENTERED  => 0x00;
        _const_and_export SDL_HAT_UP        => 0x01;
        _const_and_export SDL_HAT_RIGHT     => 0x02;
        _const_and_export SDL_HAT_DOWN      => 0x04;
        _const_and_export SDL_HAT_LEFT      => 0x08;
        _const_and_export SDL_HAT_RIGHTUP   => 0x03;
        _const_and_export SDL_HAT_RIGHTDOWN => 0x06;
        _const_and_export SDL_HAT_LEFTUP    => 0x09;
        _const_and_export SDL_HAT_LEFTDOWN  => 0x0C;
        _affix_and_export SDL_GetJoystickButton          => [ Pointer [ SDL_Joystick() ], Int ], Bool;
        _affix_and_export SDL_RumbleJoystick             => [ Pointer [ SDL_Joystick() ], UInt16, UInt16, UInt32 ], Bool;
        _affix_and_export SDL_RumbleJoystickTriggers     => [ Pointer [ SDL_Joystick() ], UInt16, UInt16, UInt32 ], Bool;
        _affix_and_export SDL_SetJoystickLED             => [ Pointer [ SDL_Joystick() ], UInt8, UInt8, UInt8 ],    Bool;
        _affix_and_export SDL_SendJoystickEffect         => [ Pointer [ SDL_Joystick() ], Pointer [Void], Int ], Bool;
        _affix_and_export SDL_CloseJoystick              => [ Pointer [ SDL_Joystick() ] ], Void;
        _affix_and_export SDL_GetJoystickConnectionState => [ Pointer [ SDL_Joystick() ] ], SDL_JoystickConnectionState();
        _affix_and_export SDL_GetJoystickPowerInfo       => [ Pointer [ SDL_Joystick() ], Pointer [Int] ], SDL_PowerState();
    }

=head3 C<:keyboard> - Keyboard Support

SDL keyboard management.

See L<SDL3: CategoryKeyboard|https://wiki.libsdl.org/SDL3/CategoryKeyboard>

=cut

    sub _keyboard() {
        state $done++ && return;
        _error();
        _keycode();
        _properties();
        _rect();
        _scancode();
        _stdinc();
        _video();
        #
        _typedef_and_export SDL_KeyboardID => UInt32;
        _affix_and_export SDL_HasKeyboard          => [], Bool;
        _affix_and_export SDL_GetKeyboards         => [ Pointer [Int] ], Pointer [ SDL_KeyboardID() ];
        _affix_and_export SDL_GetKeyboardNameForID => [ SDL_KeyboardID() ], String;
        _affix_and_export SDL_GetKeyboardFocus     => [], Pointer [ SDL_Window() ];
        _affix_and_export SDL_GetKeyboardState     => [ Pointer [Int] ], Pointer [Bool];
        _affix_and_export SDL_ResetKeyboard        => [], Void;
        _affix_and_export SDL_GetModState          => [], SDL_Keymod();
        _affix_and_export SDL_SetModState          => [ SDL_Keymod() ], Void;
        _affix_and_export SDL_GetKeyFromScancode   => [ SDL_Scancode(), SDL_Keymod(), Bool ], SDL_Keycode();
        _affix_and_export SDL_GetScancodeFromKey   => [ SDL_Keycode(), Pointer [ SDL_Keymod() ] ], SDL_Scancode();
        _affix_and_export SDL_SetScancodeName      => [ SDL_Scancode(), String ], Bool;
        _affix_and_export SDL_GetScancodeName      => [ SDL_Scancode() ], String;
        _affix_and_export SDL_GetScancodeFromName  => [String], SDL_Scancode();
        _affix_and_export SDL_GetKeyName           => [ SDL_Keycode() ], String;
        _affix_and_export SDL_GetKeyFromName       => [String], SDL_Keycode();
        _affix_and_export SDL_StartTextInput       => [ Pointer [ SDL_Window() ] ], Bool;
        _enum_and_export SDL_TextInputType => [
            'SDL_TEXTINPUT_TYPE_TEXT',                 'SDL_TEXTINPUT_TYPE_TEXT_NAME',
            'SDL_TEXTINPUT_TYPE_TEXT_EMAIL',           'SDL_TEXTINPUT_TYPE_TEXT_USERNAME',
            'SDL_TEXTINPUT_TYPE_TEXT_PASSWORD_HIDDEN', 'SDL_TEXTINPUT_TYPE_TEXT_PASSWORD_VISIBLE',
            'SDL_TEXTINPUT_TYPE_NUMBER',               'SDL_TEXTINPUT_TYPE_NUMBER_PASSWORD_HIDDEN',
            'SDL_TEXTINPUT_TYPE_NUMBER_PASSWORD_VISIBLE'
        ];
        _enum_and_export SDL_Capitalization =>
            [ 'SDL_CAPITALIZE_NONE', 'SDL_CAPITALIZE_SENTENCES', 'SDL_CAPITALIZE_WORDS', 'SDL_CAPITALIZE_LETTERS' ];
        _affix_and_export SDL_StartTextInputWithProperties => [ Pointer [ SDL_Window() ], SDL_PropertiesID() ], Bool;
        _const_and_export SDL_PROP_TEXTINPUT_TYPE_NUMBER              => 'SDL.textinput.type';
        _const_and_export SDL_PROP_TEXTINPUT_CAPITALIZATION_NUMBER    => 'SDL.textinput.capitalization';
        _const_and_export SDL_PROP_TEXTINPUT_AUTOCORRECT_BOOLEAN      => 'SDL.textinput.autocorrect';
        _const_and_export SDL_PROP_TEXTINPUT_MULTILINE_BOOLEAN        => 'SDL.textinput.multiline';
        _const_and_export SDL_PROP_TEXTINPUT_ANDROID_INPUTTYPE_NUMBER => 'SDL.textinput.android.inputtype';
        _affix_and_export SDL_TextInputActive          => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_StopTextInput            => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_ClearComposition         => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_SetTextInputArea         => [ Pointer [ SDL_Window() ], Pointer [ SDL_Rect() ], Int ], Bool;
        _affix_and_export SDL_GetTextInputArea         => [ Pointer [ SDL_Window() ], Pointer [ SDL_Rect() ], Pointer [Int] ], Bool;
        _affix_and_export SDL_HasScreenKeyboardSupport => [], Bool;
        _affix_and_export SDL_ScreenKeyboardShown      => [ Pointer [ SDL_Window() ] ], Bool;
    }

=head3 C<:keycode> - Keyboard Keycodes

Defines constants which identify keyboard keys and modifiers.

See L<SDL3: CategoryKeycode|https://wiki.libsdl.org/SDL3/CategoryKeycode>

=cut

    sub _keycode() {    # Based on sdl-main/include/sdl3/sdl_keycode.h
        state $done++ && return;
        #
        _scancode();
        _stdinc();
        #
        _typedef_and_export SDL_Keycode => UInt32;
        _const_and_export SDLK_EXTENDED_MASK => ( 1 << 29 );
        _const_and_export SDLK_SCANCODE_MASK => ( 1 << 30 );
        _func_and_export( SDL_SCANCODE_TO_KEYCODE => sub ($X) { ( $X | SDLK_SCANCODE_MASK() ) } );
        _const_and_export SDLK_UNKNOWN              => 0x00000000;
        _const_and_export SDLK_RETURN               => 0x0000000d;
        _const_and_export SDLK_ESCAPE               => 0x0000001b;
        _const_and_export SDLK_BACKSPACE            => 0x00000008;
        _const_and_export SDLK_TAB                  => 0x00000009;
        _const_and_export SDLK_SPACE                => 0x00000020;
        _const_and_export SDLK_EXCLAIM              => 0x00000021;
        _const_and_export SDLK_DBLAPOSTROPHE        => 0x00000022;
        _const_and_export SDLK_HASH                 => 0x00000023;
        _const_and_export SDLK_DOLLAR               => 0x00000024;
        _const_and_export SDLK_PERCENT              => 0x00000025;
        _const_and_export SDLK_AMPERSAND            => 0x00000026;
        _const_and_export SDLK_APOSTROPHE           => 0x00000027;
        _const_and_export SDLK_LEFTPAREN            => 0x00000028;
        _const_and_export SDLK_RIGHTPAREN           => 0x00000029;
        _const_and_export SDLK_ASTERISK             => 0x0000002a;
        _const_and_export SDLK_PLUS                 => 0x0000002b;
        _const_and_export SDLK_COMMA                => 0x0000002c;
        _const_and_export SDLK_MINUS                => 0x0000002d;
        _const_and_export SDLK_PERIOD               => 0x0000002e;
        _const_and_export SDLK_SLASH                => 0x0000002f;
        _const_and_export SDLK_0                    => 0x00000030;
        _const_and_export SDLK_1                    => 0x00000031;
        _const_and_export SDLK_2                    => 0x00000032;
        _const_and_export SDLK_3                    => 0x00000033;
        _const_and_export SDLK_4                    => 0x00000034;
        _const_and_export SDLK_5                    => 0x00000035;
        _const_and_export SDLK_6                    => 0x00000036;
        _const_and_export SDLK_7                    => 0x00000037;
        _const_and_export SDLK_8                    => 0x00000038;
        _const_and_export SDLK_9                    => 0x00000039;
        _const_and_export SDLK_COLON                => 0x0000003a;
        _const_and_export SDLK_SEMICOLON            => 0x0000003b;
        _const_and_export SDLK_LESS                 => 0x0000003c;
        _const_and_export SDLK_EQUALS               => 0x0000003d;
        _const_and_export SDLK_GREATER              => 0x0000003e;
        _const_and_export SDLK_QUESTION             => 0x0000003f;
        _const_and_export SDLK_AT                   => 0x00000040;
        _const_and_export SDLK_LEFTBRACKET          => 0x0000005b;
        _const_and_export SDLK_BACKSLASH            => 0x0000005c;
        _const_and_export SDLK_RIGHTBRACKET         => 0x0000005d;
        _const_and_export SDLK_CARET                => 0x0000005e;
        _const_and_export SDLK_UNDERSCORE           => 0x0000005f;
        _const_and_export SDLK_GRAVE                => 0x00000060;
        _const_and_export SDLK_A                    => 0x00000061;
        _const_and_export SDLK_B                    => 0x00000062;
        _const_and_export SDLK_C                    => 0x00000063;
        _const_and_export SDLK_D                    => 0x00000064;
        _const_and_export SDLK_E                    => 0x00000065;
        _const_and_export SDLK_F                    => 0x00000066;
        _const_and_export SDLK_G                    => 0x00000067;
        _const_and_export SDLK_H                    => 0x00000068;
        _const_and_export SDLK_I                    => 0x00000069;
        _const_and_export SDLK_J                    => 0x0000006a;
        _const_and_export SDLK_K                    => 0x0000006b;
        _const_and_export SDLK_L                    => 0x0000006c;
        _const_and_export SDLK_M                    => 0x0000006d;
        _const_and_export SDLK_N                    => 0x0000006e;
        _const_and_export SDLK_O                    => 0x0000006f;
        _const_and_export SDLK_P                    => 0x00000070;
        _const_and_export SDLK_Q                    => 0x00000071;
        _const_and_export SDLK_R                    => 0x00000072;
        _const_and_export SDLK_S                    => 0x00000073;
        _const_and_export SDLK_T                    => 0x00000074;
        _const_and_export SDLK_U                    => 0x00000075;
        _const_and_export SDLK_V                    => 0x00000076;
        _const_and_export SDLK_W                    => 0x00000077;
        _const_and_export SDLK_X                    => 0x00000078;
        _const_and_export SDLK_Y                    => 0x00000079;
        _const_and_export SDLK_Z                    => 0x0000007a;
        _const_and_export SDLK_LEFTBRACE            => 0x0000007b;
        _const_and_export SDLK_PIPE                 => 0x0000007c;
        _const_and_export SDLK_RIGHTBRACE           => 0x0000007d;
        _const_and_export SDLK_TILDE                => 0x0000007e;
        _const_and_export SDLK_DELETE               => 0x0000007f;
        _const_and_export SDLK_PLUSMINUS            => 0x000000b1;
        _const_and_export SDLK_CAPSLOCK             => 0x40000039;
        _const_and_export SDLK_F1                   => 0x4000003a;
        _const_and_export SDLK_F2                   => 0x4000003b;
        _const_and_export SDLK_F3                   => 0x4000003c;
        _const_and_export SDLK_F4                   => 0x4000003d;
        _const_and_export SDLK_F5                   => 0x4000003e;
        _const_and_export SDLK_F6                   => 0x4000003f;
        _const_and_export SDLK_F7                   => 0x40000040;
        _const_and_export SDLK_F8                   => 0x40000041;
        _const_and_export SDLK_F9                   => 0x40000042;
        _const_and_export SDLK_F10                  => 0x40000043;
        _const_and_export SDLK_F11                  => 0x40000044;
        _const_and_export SDLK_F12                  => 0x40000045;
        _const_and_export SDLK_PRINTSCREEN          => 0x40000046;
        _const_and_export SDLK_SCROLLLOCK           => 0x40000047;
        _const_and_export SDLK_PAUSE                => 0x40000048;
        _const_and_export SDLK_INSERT               => 0x40000049;
        _const_and_export SDLK_HOME                 => 0x4000004a;
        _const_and_export SDLK_PAGEUP               => 0x4000004b;
        _const_and_export SDLK_END                  => 0x4000004d;
        _const_and_export SDLK_PAGEDOWN             => 0x4000004e;
        _const_and_export SDLK_RIGHT                => 0x4000004f;
        _const_and_export SDLK_LEFT                 => 0x40000050;
        _const_and_export SDLK_DOWN                 => 0x40000051;
        _const_and_export SDLK_UP                   => 0x40000052;
        _const_and_export SDLK_NUMLOCKCLEAR         => 0x40000053;
        _const_and_export SDLK_KP_DIVIDE            => 0x40000054;
        _const_and_export SDLK_KP_MULTIPLY          => 0x40000055;
        _const_and_export SDLK_KP_MINUS             => 0x40000056;
        _const_and_export SDLK_KP_PLUS              => 0x40000057;
        _const_and_export SDLK_KP_ENTER             => 0x40000058;
        _const_and_export SDLK_KP_1                 => 0x40000059;
        _const_and_export SDLK_KP_2                 => 0x4000005a;
        _const_and_export SDLK_KP_3                 => 0x4000005b;
        _const_and_export SDLK_KP_4                 => 0x4000005c;
        _const_and_export SDLK_KP_5                 => 0x4000005d;
        _const_and_export SDLK_KP_6                 => 0x4000005e;
        _const_and_export SDLK_KP_7                 => 0x4000005f;
        _const_and_export SDLK_KP_8                 => 0x40000060;
        _const_and_export SDLK_KP_9                 => 0x40000061;
        _const_and_export SDLK_KP_0                 => 0x40000062;
        _const_and_export SDLK_KP_PERIOD            => 0x40000063;
        _const_and_export SDLK_APPLICATION          => 0x40000065;
        _const_and_export SDLK_POWER                => 0x40000066;
        _const_and_export SDLK_KP_EQUALS            => 0x40000067;
        _const_and_export SDLK_F13                  => 0x40000068;
        _const_and_export SDLK_F14                  => 0x40000069;
        _const_and_export SDLK_F15                  => 0x4000006a;
        _const_and_export SDLK_F16                  => 0x4000006b;
        _const_and_export SDLK_F17                  => 0x4000006c;
        _const_and_export SDLK_F18                  => 0x4000006d;
        _const_and_export SDLK_F19                  => 0x4000006e;
        _const_and_export SDLK_F20                  => 0x4000006f;
        _const_and_export SDLK_F21                  => 0x40000070;
        _const_and_export SDLK_F22                  => 0x40000071;
        _const_and_export SDLK_F23                  => 0x40000072;
        _const_and_export SDLK_F24                  => 0x40000073;
        _const_and_export SDLK_EXECUTE              => 0x40000074;
        _const_and_export SDLK_HELP                 => 0x40000075;
        _const_and_export SDLK_MENU                 => 0x40000076;
        _const_and_export SDLK_SELECT               => 0x40000077;
        _const_and_export SDLK_STOP                 => 0x40000078;
        _const_and_export SDLK_AGAIN                => 0x40000079;
        _const_and_export SDLK_UNDO                 => 0x4000007a;
        _const_and_export SDLK_CUT                  => 0x4000007b;
        _const_and_export SDLK_COPY                 => 0x4000007c;
        _const_and_export SDLK_PASTE                => 0x4000007d;
        _const_and_export SDLK_FIND                 => 0x4000007e;
        _const_and_export SDLK_MUTE                 => 0x4000007f;
        _const_and_export SDLK_VOLUMEUP             => 0x40000080;
        _const_and_export SDLK_VOLUMEDOWN           => 0x40000081;
        _const_and_export SDLK_KP_COMMA             => 0x40000085;
        _const_and_export SDLK_KP_EQUALSAS400       => 0x40000086;
        _const_and_export SDLK_ALTERASE             => 0x40000099;
        _const_and_export SDLK_SYSREQ               => 0x4000009a;
        _const_and_export SDLK_CANCEL               => 0x4000009b;
        _const_and_export SDLK_CLEAR                => 0x4000009c;
        _const_and_export SDLK_PRIOR                => 0x4000009d;
        _const_and_export SDLK_RETURN2              => 0x4000009e;
        _const_and_export SDLK_SEPARATOR            => 0x4000009f;
        _const_and_export SDLK_OUT                  => 0x400000a0;
        _const_and_export SDLK_OPER                 => 0x400000a1;
        _const_and_export SDLK_CLEARAGAIN           => 0x400000a2;
        _const_and_export SDLK_CRSEL                => 0x400000a3;
        _const_and_export SDLK_EXSEL                => 0x400000a4;
        _const_and_export SDLK_KP_00                => 0x400000b0;
        _const_and_export SDLK_KP_000               => 0x400000b1;
        _const_and_export SDLK_THOUSANDSSEPARATOR   => 0x400000b2;
        _const_and_export SDLK_DECIMALSEPARATOR     => 0x400000b3;
        _const_and_export SDLK_CURRENCYUNIT         => 0x400000b4;
        _const_and_export SDLK_CURRENCYSUBUNIT      => 0x400000b5;
        _const_and_export SDLK_KP_LEFTPAREN         => 0x400000b6;
        _const_and_export SDLK_KP_RIGHTPAREN        => 0x400000b7;
        _const_and_export SDLK_KP_LEFTBRACE         => 0x400000b8;
        _const_and_export SDLK_KP_RIGHTBRACE        => 0x400000b9;
        _const_and_export SDLK_KP_TAB               => 0x400000ba;
        _const_and_export SDLK_KP_BACKSPACE         => 0x400000bb;
        _const_and_export SDLK_KP_A                 => 0x400000bc;
        _const_and_export SDLK_KP_B                 => 0x400000bd;
        _const_and_export SDLK_KP_C                 => 0x400000be;
        _const_and_export SDLK_KP_D                 => 0x400000bf;
        _const_and_export SDLK_KP_E                 => 0x400000c0;
        _const_and_export SDLK_KP_F                 => 0x400000c1;
        _const_and_export SDLK_KP_XOR               => 0x400000c2;
        _const_and_export SDLK_KP_POWER             => 0x400000c3;
        _const_and_export SDLK_KP_PERCENT           => 0x400000c4;
        _const_and_export SDLK_KP_LESS              => 0x400000c5;
        _const_and_export SDLK_KP_GREATER           => 0x400000c6;
        _const_and_export SDLK_KP_AMPERSAND         => 0x400000c7;
        _const_and_export SDLK_KP_DBLAMPERSAND      => 0x400000c8;
        _const_and_export SDLK_KP_VERTICALBAR       => 0x400000c9;
        _const_and_export SDLK_KP_DBLVERTICALBAR    => 0x400000ca;
        _const_and_export SDLK_KP_COLON             => 0x400000cb;
        _const_and_export SDLK_KP_HASH              => 0x400000cc;
        _const_and_export SDLK_KP_SPACE             => 0x400000cd;
        _const_and_export SDLK_KP_AT                => 0x400000ce;
        _const_and_export SDLK_KP_EXCLAM            => 0x400000cf;
        _const_and_export SDLK_KP_MEMSTORE          => 0x400000d0;
        _const_and_export SDLK_KP_MEMRECALL         => 0x400000d1;
        _const_and_export SDLK_KP_MEMCLEAR          => 0x400000d2;
        _const_and_export SDLK_KP_MEMADD            => 0x400000d3;
        _const_and_export SDLK_KP_MEMSUBTRACT       => 0x400000d4;
        _const_and_export SDLK_KP_MEMMULTIPLY       => 0x400000d5;
        _const_and_export SDLK_KP_MEMDIVIDE         => 0x400000d6;
        _const_and_export SDLK_KP_PLUSMINUS         => 0x400000d7;
        _const_and_export SDLK_KP_CLEAR             => 0x400000d8;
        _const_and_export SDLK_KP_CLEARENTRY        => 0x400000d9;
        _const_and_export SDLK_KP_BINARY            => 0x400000da;
        _const_and_export SDLK_KP_OCTAL             => 0x400000db;
        _const_and_export SDLK_KP_DECIMAL           => 0x400000dc;
        _const_and_export SDLK_KP_HEXADECIMAL       => 0x400000dd;
        _const_and_export SDLK_LCTRL                => 0x400000e0;
        _const_and_export SDLK_LSHIFT               => 0x400000e1;
        _const_and_export SDLK_LALT                 => 0x400000e2;
        _const_and_export SDLK_LGUI                 => 0x400000e3;
        _const_and_export SDLK_RCTRL                => 0x400000e4;
        _const_and_export SDLK_RSHIFT               => 0x400000e5;
        _const_and_export SDLK_RALT                 => 0x400000e6;
        _const_and_export SDLK_RGUI                 => 0x400000e7;
        _const_and_export SDLK_MODE                 => 0x40000101;
        _const_and_export SDLK_SLEEP                => 0x40000102;
        _const_and_export SDLK_WAKE                 => 0x40000103;
        _const_and_export SDLK_CHANNEL_INCREMENT    => 0x40000104;
        _const_and_export SDLK_CHANNEL_DECREMENT    => 0x40000105;
        _const_and_export SDLK_MEDIA_PLAY           => 0x40000106;
        _const_and_export SDLK_MEDIA_PAUSE          => 0x40000107;
        _const_and_export SDLK_MEDIA_RECORD         => 0x40000108;
        _const_and_export SDLK_MEDIA_FAST_FORWARD   => 0x40000109;
        _const_and_export SDLK_MEDIA_REWIND         => 0x4000010a;
        _const_and_export SDLK_MEDIA_NEXT_TRACK     => 0x4000010b;
        _const_and_export SDLK_MEDIA_PREVIOUS_TRACK => 0x4000010c;
        _const_and_export SDLK_MEDIA_STOP           => 0x4000010d;
        _const_and_export SDLK_MEDIA_EJECT          => 0x4000010e;
        _const_and_export SDLK_MEDIA_PLAY_PAUSE     => 0x4000010f;
        _const_and_export SDLK_MEDIA_SELECT         => 0x40000110;
        _const_and_export SDLK_AC_NEW               => 0x40000111;
        _const_and_export SDLK_AC_OPEN              => 0x40000112;
        _const_and_export SDLK_AC_CLOSE             => 0x40000113;
        _const_and_export SDLK_AC_EXIT              => 0x40000114;
        _const_and_export SDLK_AC_SAVE              => 0x40000115;
        _const_and_export SDLK_AC_PRINT             => 0x40000116;
        _const_and_export SDLK_AC_PROPERTIES        => 0x40000117;
        _const_and_export SDLK_AC_SEARCH            => 0x40000118;
        _const_and_export SDLK_AC_HOME              => 0x40000119;
        _const_and_export SDLK_AC_BACK              => 0x4000011a;
        _const_and_export SDLK_AC_FORWARD           => 0x4000011b;
        _const_and_export SDLK_AC_STOP              => 0x4000011c;
        _const_and_export SDLK_AC_REFRESH           => 0x4000011d;
        _const_and_export SDLK_AC_BOOKMARKS         => 0x4000011e;
        _const_and_export SDLK_SOFTLEFT             => 0x4000011f;
        _const_and_export SDLK_SOFTRIGHT            => 0x40000120;
        _const_and_export SDLK_CALL                 => 0x40000121;
        _const_and_export SDLK_ENDCALL              => 0x40000122;
        _const_and_export SDLK_LEFT_TAB             => 0x20000001;
        _const_and_export SDLK_LEVEL5_SHIFT         => 0x20000002;
        _const_and_export SDLK_MULTI_KEY_COMPOSE    => 0x20000003;
        _const_and_export SDLK_LMETA                => 0x20000004;
        _const_and_export SDLK_RMETA                => 0x20000005;
        _const_and_export SDLK_LHYPER               => 0x20000006;
        _const_and_export SDLK_RHYPER               => 0x20000007;
        _typedef_and_export SDL_Keymod => UInt16;
        _const_and_export SDL_KMOD_NONE   => 0x0000;
        _const_and_export SDL_KMOD_LSHIFT => 0x0001;
        _const_and_export SDL_KMOD_RSHIFT => 0x0002;
        _const_and_export SDL_KMOD_LEVEL5 => 0x0004;
        _const_and_export SDL_KMOD_LCTRL  => 0x0040;
        _const_and_export SDL_KMOD_RCTRL  => 0x0080;
        _const_and_export SDL_KMOD_LALT   => 0x0100;
        _const_and_export SDL_KMOD_RALT   => 0x0200;
        _const_and_export SDL_KMOD_LGUI   => 0x0400;
        _const_and_export SDL_KMOD_RGUI   => 0x0800;
        _const_and_export SDL_KMOD_NUM    => 0x1000;
        _const_and_export SDL_KMOD_CAPS   => 0x2000;
        _const_and_export SDL_KMOD_MODE   => 0x4000;
        _const_and_export SDL_KMOD_SCROLL => 0x8000;
        _const_and_export SDL_KMOD_CTRL   => ( 0x0040 | 0x0080 );
        _const_and_export SDL_KMOD_SHIFT  => ( 0x0001 | 0x0002 );
        _const_and_export SDL_KMOD_ALT    => ( 0x0100 | 0x0200 );
        _const_and_export SDL_KMOD_GUI    => ( 0x0400 | 0x0800 );
    }

=head3 C<:loadso> - Shared Object/DLL Management

System-dependent library loading routines.

See L<SDL3: CategorySharedObject|https://wiki.libsdl.org/SDL3/CategorySharedObject>

=cut

    sub _loadso() {
        state $done++ && return;
        #
        _error();
        _stdinc();
        #
        _typedef_and_export SDL_SharedObject => Void;
        #
        _affix_and_export SDL_LoadObject   => [String], Pointer [ SDL_SharedObject() ];
        _affix_and_export SDL_LoadFunction => [ Pointer [ SDL_SharedObject() ], String ], Pointer [ SDL_FunctionPointer() ];
        _affix_and_export SDL_UnloadObject => [ Pointer [ SDL_SharedObject() ] ], Void;
    }

=head3 C<:locale> - Locale Info

A struct to provide locale data.

This provides a way to get a list of preferred locales (language plus country) for the user. There is exactly one
function: L<SDL_GetPreferredLocales()|https://wiki.libsdl.org/SDL3/SDL_GetPreferredLocales>, which handles all the
heavy lifting, and offers documentation on all the strange ways humans might have configured their language settings.

See L<SDL3: CategoryLocale|https://wiki.libsdl.org/SDL3/CategoryLocale>

=cut

    sub _locale() {
        state $done++ && return;
        #
        _error();
        _stdinc();
        #
        _typedef_and_export SDL_Locale => Struct [ language => String, country => String ];
        _affix_and_export SDL_GetPreferredLocales => [ Pointer [Int] ], Pointer [ Pointer [ SDL_Locale() ] ];
    }

=head3 C<:log> - Log Handling

Simple log messages with priorities and categories. A message's C<SDL_LogPriority> signifies how important the message
is. A message's C<SDL_LogCategory> signifies from what domain it belongs to. Every category has a minimum priority
specified: when a message belongs to that category, it will only be sent out if it has that minimum priority or higher.

See L<SDL3: CategoryLog|https://wiki.libsdl.org/SDL3/CategoryLog>

=cut

    sub _log() {
        state $done++ && return;
        #
        _stdinc();
        #
        _enum_and_export SDL_LogCategory => [
            'SDL_LOG_CATEGORY_APPLICATION', 'SDL_LOG_CATEGORY_ERROR',     'SDL_LOG_CATEGORY_ASSERT',     'SDL_LOG_CATEGORY_SYSTEM',
            'SDL_LOG_CATEGORY_AUDIO',       'SDL_LOG_CATEGORY_VIDEO',     'SDL_LOG_CATEGORY_RENDER',     'SDL_LOG_CATEGORY_INPUT',
            'SDL_LOG_CATEGORY_TEST',        'SDL_LOG_CATEGORY_GPU',       'SDL_LOG_CATEGORY_RESERVED2',  'SDL_LOG_CATEGORY_RESERVED3',
            'SDL_LOG_CATEGORY_RESERVED4',   'SDL_LOG_CATEGORY_RESERVED5', 'SDL_LOG_CATEGORY_RESERVED6',  'SDL_LOG_CATEGORY_RESERVED7',
            'SDL_LOG_CATEGORY_RESERVED8',   'SDL_LOG_CATEGORY_RESERVED9', 'SDL_LOG_CATEGORY_RESERVED10', 'SDL_LOG_CATEGORY_CUSTOM'
        ];
        _enum_and_export SDL_LogPriority => [
            'SDL_LOG_PRIORITY_INVALID', 'SDL_LOG_PRIORITY_TRACE', 'SDL_LOG_PRIORITY_VERBOSE', 'SDL_LOG_PRIORITY_DEBUG',
            'SDL_LOG_PRIORITY_INFO',    'SDL_LOG_PRIORITY_WARN',  'SDL_LOG_PRIORITY_ERROR',   'SDL_LOG_PRIORITY_CRITICAL',
            'SDL_LOG_PRIORITY_COUNT'
        ];
        _affix_and_export SDL_SetLogPriorities     => [ SDL_LogPriority() ], Void;
        _affix_and_export SDL_SetLogPriority       => [ Int, SDL_LogPriority() ], Void;
        _affix_and_export SDL_GetLogPriority       => [Int], SDL_LogPriority();
        _affix_and_export SDL_ResetLogPriorities   => [], Void;
        _affix_and_export SDL_SetLogPriorityPrefix => [ SDL_LogPriority(), String ], Bool;

        #~ ...oy.
        #~ _affix_and_export SDL_Log                  => [ String, VarArgs ], Void;
        #~ _affix_and_export SDL_LogTrace             => [ Int, String, VarArgs ], Void;
        #~ _affix_and_export SDL_LogVerbose           => [ Int, String, VarArgs ], Void;
        #~ _affix_and_export SDL_LogDebug             => [ Int, String, VarArgs ], Void;
        #~ _affix_and_export SDL_LogInfo              => [ Int, String, VarArgs ], Void;
        #~ _affix_and_export SDL_LogWarn              => [ Int, String, VarArgs ], Void;
        #~ _affix_and_export SDL_LogError             => [ Int, String, VarArgs ], Void;
        #~ _affix_and_export SDL_LogCritical          => [ Int, String, VarArgs ], Void;
        #~ _affix_and_export SDL_LogMessage           => [ Int, SDL_LogPriority(), String, VarArgs ], Void;
        _affix_and_export SDL_Log         => [String], Void;
        _affix_and_export SDL_LogTrace    => [ Int, String ], Void;
        _affix_and_export SDL_LogVerbose  => [ Int, String ], Void;
        _affix_and_export SDL_LogDebug    => [ Int, String ], Void;
        _affix_and_export SDL_LogInfo     => [ Int, String ], Void;
        _affix_and_export SDL_LogWarn     => [ Int, String ], Void;
        _affix_and_export SDL_LogError    => [ Int, String ], Void;
        _affix_and_export SDL_LogCritical => [ Int, String ], Void;
        _affix_and_export SDL_LogMessage  => [ Int, SDL_LogPriority(), String ], Void;
        _typedef_and_export SDL_LogOutputFunction => Callback [ [ Pointer [Void], Int, SDL_LogPriority(), String ] => Void ];
        _affix_and_export SDL_GetDefaultLogOutputFunction => [], SDL_LogOutputFunction();
        _affix_and_export SDL_GetLogOutputFunction        => [ Pointer [ SDL_LogOutputFunction() ], Pointer [ Pointer [Void] ] ], Void;
        _affix_and_export SDL_SetLogOutputFunction        => [ SDL_LogOutputFunction(), Pointer [Void] ], Void;
    }

=head3 C<:main> - Application entry points

This is a special import tag that informs SDL to use its new callback based App system.

You B<must> define L<SDL_AppInit|https://wiki.libsdl.org/SDL3/SDL_AppInit>,
L<SDL_AppEvent|https://wiki.libsdl.org/SDL3/SDL_AppEvent>,
L<SDL_AppIterate|https://wiki.libsdl.org/SDL3/SDL_AppIterate>, and
L<SDL_AppQuit|https://wiki.libsdl.org/SDL3/SDL_AppQuit> in your code.

See F<eg/hello_world.pl> for an example and L<SDL3: CategoryMain|https://wiki.libsdl.org/SDL3/CategoryMain>.

=cut

    sub _main() {
        state $done++ && return;
        #
        _error();
        _events();
        _platform_defines();
        _stdinc();
        #
        _typedef_and_export SDL_main_func => Callback [ [ Int, Pointer [String] ] => Int ];
        _affix_and_export SDL_SetMainReady => [], Void;
        _affix_and_export SDL_RunApp => [ Int, Pointer [String], SDL_main_func(), Pointer [Void] ], Int;
        _affix_and_export
            SDL_EnterAppMainCallbacks =>
            [ Int, Pointer [String], SDL_AppInit_func(), SDL_AppIterate_func(), SDL_AppEvent_func(), SDL_AppQuit_func() ],
            Int;
        _affix_and_export SDL_RegisterApp        => [ String, UInt32, Pointer [Void] ], Bool;
        _affix_and_export SDL_UnregisterApp      => [], Void;
        _affix_and_export SDL_GDKSuspendComplete => [], Void;
    }

=head3 C<:messagebox> - Message Boxes

SDL offers a simple message box API, which is useful for simple alerts, such as informing the user when something fatal
happens at startup without the need to build a UI for it (or informing the user _before_ your UI is ready).

See L<SDL3: CategoryMessagebox|https://wiki.libsdl.org/SDL3/CategoryMessagebox>

=cut

    sub _messagebox() {
        state $done++ && return;
        #
        _error();
        _stdinc();
        _video();
        #
        _typedef_and_export SDL_MessageBoxFlags => UInt32;
        _const_and_export SDL_MESSAGEBOX_ERROR                 => 0x00000010;
        _const_and_export SDL_MESSAGEBOX_WARNING               => 0x00000020;
        _const_and_export SDL_MESSAGEBOX_INFORMATION           => 0x00000040;
        _const_and_export SDL_MESSAGEBOX_BUTTONS_LEFT_TO_RIGHT => 0x00000080;
        _const_and_export SDL_MESSAGEBOX_BUTTONS_RIGHT_TO_LEFT => 0x00000100;
        _typedef_and_export SDL_MessageBoxButtonFlags => UInt32;
        _const_and_export SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT => 0x00000001;
        _const_and_export SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT => 0x00000002;
        _typedef_and_export SDL_MessageBoxButtonData => Struct [ flags => SDL_MessageBoxButtonFlags(), buttonID => Int, text => String ];
        _typedef_and_export SDL_MessageBoxColor => Struct [ r => UInt8, g => UInt8, b => UInt8 ];
        _enum_and_export SDL_MessageBoxColorType => [
            'SDL_MESSAGEBOX_COLOR_BACKGROUND',      'SDL_MESSAGEBOX_COLOR_TEXT',
            'SDL_MESSAGEBOX_COLOR_BUTTON_BORDER',   'SDL_MESSAGEBOX_COLOR_BUTTON_BACKGROUND',
            'SDL_MESSAGEBOX_COLOR_BUTTON_SELECTED', 'SDL_MESSAGEBOX_COLOR_COUNT'
        ];
        _typedef_and_export SDL_MessageBoxColorScheme => Struct [
            colors => Array [ SDL_MessageBoxColor(), 5 ]    # SDL_MESSAGEBOX_COLOR_COUNT
        ];
        _typedef_and_export SDL_MessageBoxData => Struct [
            flags       => SDL_MessageBoxFlags(),
            window      => Pointer [ SDL_Window() ],
            title       => String,
            message     => String,
            numbuttons  => Int,
            buttons     => Pointer [ SDL_MessageBoxButtonData() ],
            colorScheme => Pointer [ SDL_MessageBoxColorScheme() ]
        ];
        _affix_and_export SDL_ShowMessageBox => [ Pointer [ SDL_MessageBoxData() ], Pointer [Int] ], Bool;
        _affix_and_export SDL_ShowSimpleMessageBox => [ SDL_MessageBoxFlags(), String, String, Pointer [ SDL_Window() ] ], Bool;
    }

=head3 C<:metal> - Metal support

Functions to creating Metal layers and views on SDL windows.

This provides some platform-specific glue for Apple platforms. Most macOS and iOS apps can use SDL without these
functions, but this API they can be useful for specific OS-level integration tasks.

See L<SDL3: CategoryMetal|https://wiki.libsdl.org/SDL3/CategoryMetal>

=cut

    sub _metal() {    # Based on sdl-main/include/sdl3/sdl_metal.h
        state $done++ && return;
        _video();
        #
        _typedef_and_export SDL_MetalView => Pointer [Void];
        _affix_and_export SDL_Metal_CreateView  => [ Pointer [ SDL_Window() ] ], SDL_MetalView();
        _affix_and_export SDL_Metal_DestroyView => [ SDL_MetalView() ], Void;
        _affix_and_export SDL_Metal_GetLayer    => [ SDL_MetalView() ], Pointer [Void];
    }

=head3 C<:misc> - Miscellaneous

SDL API functions that don't fit elsewhere.

See L<SDL3: CategoryMisc|https://wiki.libsdl.org/SDL3/CategoryMisc>

=cut

    sub _misc() {    # Based on sdl-main/include/sdl3/sdl_misc.h
        state $done++ && return;
        _error();
        #
        _affix_and_export 'SDL_OpenURL', [String], Bool;
    }

=head3 C<:mouse> - Mouse Support

Any GUI application has to deal with the mouse, and SDL provides functions to manage mouse input and the displayed
cursor.

See L<SDL3: CategoryMouse|https://wiki.libsdl.org/SDL3/CategoryMouse>

=cut

    sub _mouse() {
        state $done++ && return;
        _error();
        _stdinc();
        _surface();
        _video();
        #
        _typedef_and_export SDL_MouseID => UInt32;
        _typedef_and_export SDL_Cursor  => Void;
        _enum_and_export SDL_SystemCursor => [
            'SDL_SYSTEM_CURSOR_DEFAULT',   'SDL_SYSTEM_CURSOR_TEXT',        'SDL_SYSTEM_CURSOR_WAIT',        'SDL_SYSTEM_CURSOR_CROSSHAIR',
            'SDL_SYSTEM_CURSOR_PROGRESS',  'SDL_SYSTEM_CURSOR_NWSE_RESIZE', 'SDL_SYSTEM_CURSOR_NESW_RESIZE', 'SDL_SYSTEM_CURSOR_EW_RESIZE',
            'SDL_SYSTEM_CURSOR_NS_RESIZE', 'SDL_SYSTEM_CURSOR_MOVE',        'SDL_SYSTEM_CURSOR_NOT_ALLOWED', 'SDL_SYSTEM_CURSOR_POINTER',
            'SDL_SYSTEM_CURSOR_NW_RESIZE', 'SDL_SYSTEM_CURSOR_N_RESIZE',    'SDL_SYSTEM_CURSOR_NE_RESIZE',   'SDL_SYSTEM_CURSOR_E_RESIZE',
            'SDL_SYSTEM_CURSOR_SE_RESIZE', 'SDL_SYSTEM_CURSOR_S_RESIZE',    'SDL_SYSTEM_CURSOR_SW_RESIZE',   'SDL_SYSTEM_CURSOR_W_RESIZE',
            'SDL_SYSTEM_CURSOR_COUNT'
        ];
        _enum_and_export SDL_MouseWheelDirection => [ 'SDL_MOUSEWHEEL_NORMAL', 'SDL_MOUSEWHEEL_FLIPPED' ];
        _typedef_and_export SDL_CursorFrameInfo  => Struct [ surface => Pointer [ SDL_Surface() ], duration => UInt32 ];
        _typedef_and_export SDL_MouseButtonFlags => UInt32;
        _const_and_export SDL_BUTTON_LEFT   => 1;
        _const_and_export SDL_BUTTON_MIDDLE => 2;
        _const_and_export SDL_BUTTON_RIGHT  => 3;
        _const_and_export SDL_BUTTON_X1     => 4;
        _const_and_export SDL_BUTTON_X2     => 5;
        _func_and_export SDL_BUTTON_MASK => sub ($X) { ( 1 << ( ($X) - 1 ) ) };
        _const_and_export SDL_BUTTON_LMASK  => 1 << ( 1 - 1 );
        _const_and_export SDL_BUTTON_MMASK  => 1 << ( 2 - 1 );
        _const_and_export SDL_BUTTON_RMASK  => 1 << ( 3 - 1 );
        _const_and_export SDL_BUTTON_X1MASK => 1 << ( 4 - 1 );
        _const_and_export SDL_BUTTON_X2MASK => 1 << ( 5 - 1 );
        _typedef_and_export SDL_MouseMotionTransformCallback =>
            Callback [ [ Pointer [Void], UInt64, Pointer [ SDL_Window() ], SDL_MouseID(), Pointer [Float], Pointer [Float] ] => Void ];
        _affix_and_export SDL_HasMouse              => [], Bool;
        _affix_and_export SDL_GetMice               => [ Pointer [Int] ], Pointer [ SDL_MouseID() ];
        _affix_and_export SDL_GetMouseNameForID     => [ SDL_MouseID() ], String;
        _affix_and_export SDL_GetMouseFocus         => [], Pointer [ SDL_Window() ];
        _affix_and_export SDL_GetMouseState         => [ Pointer [Float], Pointer [Float] ], SDL_MouseButtonFlags();
        _affix_and_export SDL_GetGlobalMouseState   => [ Pointer [Float], Pointer [Float] ], SDL_MouseButtonFlags();
        _affix_and_export SDL_GetRelativeMouseState => [ Pointer [Float], Pointer [Float] ], SDL_MouseButtonFlags();
        _affix_and_export SDL_WarpMouseInWindow     => [ Pointer [ SDL_Window() ], Float, Float ], Void;
        _affix_and_export SDL_WarpMouseGlobal       => [ Float, Float ], Bool;

        #~ _affix_and_export SDL_SetRelativeMouseTransform  => [ SDL_MouseMotionTransformCallback(), Pointer [Void] ], Bool;
        _affix_and_export SDL_SetWindowRelativeMouseMode => [ Pointer [ SDL_Window() ], Bool ], Bool;
        _affix_and_export SDL_GetWindowRelativeMouseMode => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_CaptureMouse               => [Bool], Bool;
        _affix_and_export SDL_CreateCursor               => [ Pointer [UInt8], Pointer [UInt8], Int, Int, Int, Int ], Pointer [ SDL_Cursor() ];
        _affix_and_export SDL_CreateColorCursor          => [ Pointer [ SDL_Surface() ], Int, Int ], Pointer [ SDL_Cursor() ];

        #~ _affix_and_export
        #~ SDL_CreateAnimatedCursor => [ Pointer [ SDL_CursorFrameInfo() ], Int, Int, Int ],
        #~ Pointer [ SDL_Cursor() ];
        _affix_and_export SDL_CreateSystemCursor => [ SDL_SystemCursor() ], Pointer [ SDL_Cursor() ];
        _affix_and_export SDL_SetCursor          => [ Pointer [ SDL_Cursor() ] ], Bool;
        _affix_and_export SDL_GetCursor          => [], Pointer [ SDL_Cursor() ];
        _affix_and_export SDL_GetDefaultCursor   => [], Pointer [ SDL_Cursor() ];
        _affix_and_export SDL_DestroyCursor      => [ Pointer [ SDL_Cursor() ] ], Void;
        _affix_and_export SDL_ShowCursor         => [], Bool;
        _affix_and_export SDL_HideCursor         => [], Bool;
        _affix_and_export SDL_CursorVisible      => [], Bool;
    }

=head3 C<:mutex> - Thread Synchronization Primitives

SDL offers several thread synchronization primitives. This document can't cover the complicated topic of thread safety,
but reading up on what each of these primitives are, why they are useful, and how to correctly use them is vital to
writing correct and safe multithreaded programs.

See L<SDL3: CategoryMutex|https://wiki.libsdl.org/SDL3/CategoryMutex>

=cut

    sub _mutex() {
        state $done++ && return;
        #
        _atomic();
        _error();
        _stdinc();
        _thread();
        #
        _typedef_and_export SDL_Mutex     => Void;
        _typedef_and_export SDL_RWLock    => Void;
        _typedef_and_export SDL_Semaphore => Void;
        _typedef_and_export SDL_Condition => Void;
        _affix_and_export SDL_CreateMutex             => [], Pointer [ SDL_Mutex() ];
        _affix_and_export SDL_LockMutex               => [ Pointer [ SDL_Mutex() ] ], Void;
        _affix_and_export SDL_TryLockMutex            => [ Pointer [ SDL_Mutex() ] ], Bool;
        _affix_and_export SDL_UnlockMutex             => [ Pointer [ SDL_Mutex() ] ], Void;
        _affix_and_export SDL_DestroyMutex            => [ Pointer [ SDL_Mutex() ] ], Void;
        _affix_and_export SDL_CreateRWLock            => [], Pointer [ SDL_RWLock() ];
        _affix_and_export SDL_LockRWLockForReading    => [ Pointer [ SDL_RWLock() ] ], Void;
        _affix_and_export SDL_LockRWLockForWriting    => [ Pointer [ SDL_RWLock() ] ], Void;
        _affix_and_export SDL_TryLockRWLockForReading => [ Pointer [ SDL_RWLock() ] ], Bool;
        _affix_and_export SDL_TryLockRWLockForWriting => [ Pointer [ SDL_RWLock() ] ], Bool;
        _affix_and_export SDL_UnlockRWLock            => [ Pointer [ SDL_RWLock() ] ], Void;
        _affix_and_export SDL_DestroyRWLock           => [ Pointer [ SDL_RWLock() ] ], Void;
        _affix_and_export SDL_CreateSemaphore         => [UInt32], Pointer [ SDL_Semaphore() ];
        _affix_and_export SDL_DestroySemaphore        => [ Pointer [ SDL_Semaphore() ] ], Void;
        _affix_and_export SDL_WaitSemaphore           => [ Pointer [ SDL_Semaphore() ] ], Void;
        _affix_and_export SDL_TryWaitSemaphore        => [ Pointer [ SDL_Semaphore() ] ], Bool;
        _affix_and_export SDL_WaitSemaphoreTimeout    => [ Pointer [ SDL_Semaphore() ], SInt32 ], Bool;
        _affix_and_export SDL_SignalSemaphore         => [ Pointer [ SDL_Semaphore() ] ], Void;
        _affix_and_export SDL_GetSemaphoreValue       => [ Pointer [ SDL_Semaphore() ] ], UInt32;
        _affix_and_export SDL_CreateCondition         => [], Pointer [ SDL_Condition() ];
        _affix_and_export SDL_DestroyCondition        => [ Pointer [ SDL_Condition() ] ], Void;
        _affix_and_export SDL_SignalCondition         => [ Pointer [ SDL_Condition() ] ], Void;
        _affix_and_export SDL_BroadcastCondition      => [ Pointer [ SDL_Condition() ] ], Void;
        _affix_and_export SDL_WaitCondition           => [ Pointer [ SDL_Condition() ], Pointer [ SDL_Mutex() ] ], Void;
        _affix_and_export SDL_WaitConditionTimeout    => [ Pointer [ SDL_Condition() ], Pointer [ SDL_Mutex() ], SInt32 ], Bool;
        _enum_and_export SDL_InitStatus =>
            [ 'SDL_INIT_STATUS_UNINITIALIZED', 'SDL_INIT_STATUS_INITIALIZING', 'SDL_INIT_STATUS_INITIALIZED', 'SDL_INIT_STATUS_UNINITIALIZING' ];
        _typedef_and_export SDL_InitState => Struct [ status => SDL_AtomicInt(), thread => SDL_ThreadID(), reserved => Pointer [Void] ];
        _affix_and_export SDL_ShouldInit     => [ Pointer [ SDL_InitState() ] ], Bool;
        _affix_and_export SDL_ShouldQuit     => [ Pointer [ SDL_InitState() ] ], Bool;
        _affix_and_export SDL_SetInitialized => [ Pointer [ SDL_InitState() ], Bool ], Void;
    }

    # This is on my TODO list...
    sub _opengl() {
        state $done++ && return;
        _platform();
    }

=head3 C<:pen> - Pen Support

SDL pen event handling.

SDL provides an API for pressure-sensitive pen (stylus and/or eraser) handling, e.g., for input and drawing tablets or
suitably equipped mobile / tablet devices.

See L<SDL3: CategoryPen|https://wiki.libsdl.org/SDL3/CategoryPen>

=cut

    sub _pen() {
        state $done++ && return;
        #
        _mouse();
        _stdinc();
        _touch();
        #
        _typedef_and_export SDL_PenID => UInt32;
        _const_and_export SDL_PEN_MOUSEID => -2;
        _const_and_export SDL_PEN_TOUCHID => -2;
        _typedef_and_export SDL_PenInputFlags => UInt32;
        _const_and_export SDL_PEN_INPUT_DOWN         => ( 1 << 0 );
        _const_and_export SDL_PEN_INPUT_BUTTON_1     => ( 1 << 1 );
        _const_and_export SDL_PEN_INPUT_BUTTON_2     => ( 1 << 2 );
        _const_and_export SDL_PEN_INPUT_BUTTON_3     => ( 1 << 3 );
        _const_and_export SDL_PEN_INPUT_BUTTON_4     => ( 1 << 4 );
        _const_and_export SDL_PEN_INPUT_BUTTON_5     => ( 1 << 5 );
        _const_and_export SDL_PEN_INPUT_ERASER_TIP   => ( 1 << 30 );
        _const_and_export SDL_PEN_INPUT_IN_PROXIMITY => ( 1 << 31 );
        _enum_and_export SDL_PenAxis => [
            'SDL_PEN_AXIS_PRESSURE', 'SDL_PEN_AXIS_XTILT',  'SDL_PEN_AXIS_YTILT',               'SDL_PEN_AXIS_DISTANCE',
            'SDL_PEN_AXIS_ROTATION', 'SDL_PEN_AXIS_SLIDER', 'SDL_PEN_AXIS_TANGENTIAL_PRESSURE', 'SDL_PEN_AXIS_COUNT'
        ];
        _enum_and_export SDL_PenDeviceType =>
            [ [ SDL_PEN_DEVICE_TYPE_INVALID => -1 ], 'SDL_PEN_DEVICE_TYPE_UNKNOWN', 'SDL_PEN_DEVICE_TYPE_DIRECT', 'SDL_PEN_DEVICE_TYPE_INDIRECT' ];

        #~ _affix_and_export SDL_GetPenDeviceType => [ SDL_PenID() ], SDL_PenDeviceType();
    }

=head3 C<:pixels> - Pixel Formats and Conversion Routines

SDL offers facilities for pixel management.

See L<SDL3: CategoryPixels|https://wiki.libsdl.org/SDL3/CategoryPixels>

=cut

    sub _pixels() {
        state $done++ && return;
        _error();
        _stdinc();
        #
        _const_and_export SDL_ALPHA_OPAQUE            => 255;
        _const_and_export SDL_ALPHA_OPAQUE_FLOAT      => 1.0;
        _const_and_export SDL_ALPHA_TRANSPARENT       => 0;
        _const_and_export SDL_ALPHA_TRANSPARENT_FLOAT => 0.0;
        _enum_and_export SDL_PixelType => [
            [ SDL_PIXELTYPE_UNKNOWN  => 0 ],
            [ SDL_PIXELTYPE_INDEX1   => 1 ],
            [ SDL_PIXELTYPE_INDEX4   => 2 ],
            [ SDL_PIXELTYPE_INDEX8   => 3 ],
            [ SDL_PIXELTYPE_PACKED8  => 4 ],
            [ SDL_PIXELTYPE_PACKED16 => 5 ],
            [ SDL_PIXELTYPE_PACKED32 => 6 ],
            [ SDL_PIXELTYPE_ARRAYU8  => 7 ],
            [ SDL_PIXELTYPE_ARRAYU16 => 8 ],
            [ SDL_PIXELTYPE_ARRAYU32 => 9 ],
            [ SDL_PIXELTYPE_ARRAYF16 => 10 ],
            [ SDL_PIXELTYPE_ARRAYF32 => 11 ],
            [ SDL_PIXELTYPE_INDEX2   => 12 ],
        ];
        _enum_and_export SDL_BitmapOrder => [qw[SDL_BITMAPORDER_NONE SDL_BITMAPORDER_4321 SDL_BITMAPORDER_1234]];
        _enum_and_export SDL_PackedOrder => [
            qw[SDL_PACKEDORDER_NONE
                SDL_PACKEDORDER_XRGB     SDL_PACKEDORDER_RGBX     SDL_PACKEDORDER_ARGB     SDL_PACKEDORDER_RGBA
                SDL_PACKEDORDER_XBGR     SDL_PACKEDORDER_BGRX     SDL_PACKEDORDER_ABGR     SDL_PACKEDORDER_BGRA]
        ];
        _enum_and_export SDL_ArrayOrder => [
            qw[
                SDL_ARRAYORDER_NONE    SDL_ARRAYORDER_RGB    SDL_ARRAYORDER_RGBA    SDL_ARRAYORDER_ARGB
                SDL_ARRAYORDER_BGR    SDL_ARRAYORDER_BGRA    SDL_ARRAYORDER_ABGR]
        ];
        _enum_and_export SDL_PackedLayout => [
            qw[
                SDL_PACKEDLAYOUT_NONE
                SDL_PACKEDLAYOUT_332        SDL_PACKEDLAYOUT_4444       SDL_PACKEDLAYOUT_1555
                SDL_PACKEDLAYOUT_5551       SDL_PACKEDLAYOUT_565        SDL_PACKEDLAYOUT_8888
                SDL_PACKEDLAYOUT_2101010    SDL_PACKEDLAYOUT_1010102
            ]
        ];
        _func_and_export( SDL_DEFINE_PIXELFOURCC => sub ( $A, $B, $C, $D ) { SDL_FOURCC( $A, $B, $C, $D ) } );
        _func_and_export(
            SDL_DEFINE_PIXELFORMAT => sub ( $type, $order, $layout, $bits, $bytes ) {
                ( ( 1 << 28 ) | ( ($type) << 24 ) | ( ($order) << 20 ) | ( ($layout) << 16 ) | ( ($bits) << 8 ) | ( ($bytes) << 0 ) )
            }
        );
        _func_and_export( SDL_PIXELFLAG    => sub ($format) { ( ( ($format) >> 28 ) & 0x0F ) } );
        _func_and_export( SDL_PIXELTYPE    => sub ($format) { ( ( ($format) >> 24 ) & 0x0F ) } );
        _func_and_export( SDL_PIXELORDER   => sub ($format) { ( ( ($format) >> 20 ) & 0x0F ) } );
        _func_and_export( SDL_PIXELLAYOUT  => sub ($format) { ( ( ($format) >> 16 ) & 0x0F ) } );
        _func_and_export( SDL_BITSPERPIXEL => sub ($format) { ( SDL_ISPIXELFORMAT_FOURCC($format) ? 0 : ( ( ($format) >> 8 ) & 0xFF ) ) } );
        _func_and_export(
            SDL_BYTESPERPIXEL => sub ($format) {
                (
                    SDL_ISPIXELFORMAT_FOURCC($format) ?
                        (
                        (
                            ( ($format) == SDL_PIXELFORMAT_YUY2() )     ||
                                ( ($format) == SDL_PIXELFORMAT_UYVY() ) ||
                                ( ($format) == SDL_PIXELFORMAT_YVYU() ) ||
                                ( ($format) == SDL_PIXELFORMAT_P010() )
                        ) ? 2 : 1
                        ) :
                        ( ( ($format) >> 0 ) & 0xFF )
                )
            }
        );
        _func_and_export(
            SDL_ISPIXELFORMAT_INDEXED => sub ($format) {
                (
                    !SDL_ISPIXELFORMAT_FOURCC($format) &&
                        ( ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_INDEX1() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_INDEX2() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_INDEX4() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_INDEX8() ) )
                )
            }
        );
        _func_and_export(
            SDL_ISPIXELFORMAT_PACKED => sub ($format) {
                (
                    !SDL_ISPIXELFORMAT_FOURCC($format) &&
                        ( ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_PACKED8() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_PACKED16() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_PACKED32() ) )
                )
            }
        );
        _func_and_export(
            SDL_ISPIXELFORMAT_ARRAY => sub ($format) {
                (
                    !SDL_ISPIXELFORMAT_FOURCC($format) &&
                        ( ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYU8() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYU16() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYU32() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYF16() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYF32() ) )
                )
            }
        );
        _func_and_export(
            SDL_ISPIXELFORMAT_10BIT => sub ($format) {
                ( !SDL_ISPIXELFORMAT_FOURCC($format) &&
                        ( ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_PACKED32() ) && ( SDL_PIXELLAYOUT($format) == SDL_PACKEDLAYOUT_2101010() ) ) )
            }
        );
        _func_and_export(
            SDL_ISPIXELFORMAT_FLOAT => sub ($format) {
                ( !SDL_ISPIXELFORMAT_FOURCC($format) &&
                        ( ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYF16() ) || ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYF32() ) ) )
            }
        );
        _func_and_export(
            SDL_ISPIXELFORMAT_ALPHA => sub ($format) {
                (
                    (
                        SDL_ISPIXELFORMAT_PACKED($format) &&
                            ( ( SDL_PIXELORDER($format) == SDL_PACKEDORDER_ARGB() ) ||
                            ( SDL_PIXELORDER($format) == SDL_PACKEDORDER_RGBA() ) ||
                            ( SDL_PIXELORDER($format) == SDL_PACKEDORDER_ABGR() ) ||
                            ( SDL_PIXELORDER($format) == SDL_PACKEDORDER_BGRA() ) )
                    ) ||
                        (
                        SDL_ISPIXELFORMAT_ARRAY($format) &&
                        ( ( SDL_PIXELORDER($format) == SDL_ARRAYORDER_ARGB() ) ||
                            ( SDL_PIXELORDER($format) == SDL_ARRAYORDER_RGBA() ) ||
                            ( SDL_PIXELORDER($format) == SDL_ARRAYORDER_ABGR() ) ||
                            ( SDL_PIXELORDER($format) == SDL_ARRAYORDER_BGRA() ) )
                        )
                )
            }
        );
        _func_and_export( SDL_ISPIXELFORMAT_FOURCC => sub ($format) { ( ($format) && ( SDL_PIXELFLAG($format) != 1 ) ) } );
        _enum_and_export SDL_PixelFormat => [
            [ SDL_PIXELFORMAT_UNKNOWN       => 0 ],          [ SDL_PIXELFORMAT_INDEX1LSB => 0x11100100 ], [ SDL_PIXELFORMAT_INDEX1MSB => 0x11200100 ],
            [ SDL_PIXELFORMAT_INDEX2LSB     => 0x1c100200 ], [ SDL_PIXELFORMAT_INDEX2MSB => 0x1c200200 ], [ SDL_PIXELFORMAT_INDEX4LSB => 0x12100400 ],
            [ SDL_PIXELFORMAT_INDEX4MSB     => 0x12200400 ], [ SDL_PIXELFORMAT_INDEX8    => 0x13000801 ], [ SDL_PIXELFORMAT_RGB332    => 0x14110801 ],
            [ SDL_PIXELFORMAT_XRGB4444      => 0x15120c02 ], [ SDL_PIXELFORMAT_XBGR4444  => 0x15520c02 ], [ SDL_PIXELFORMAT_XRGB1555  => 0x15130f02 ],
            [ SDL_PIXELFORMAT_XBGR1555      => 0x15530f02 ], [ SDL_PIXELFORMAT_ARGB4444  => 0x15321002 ], [ SDL_PIXELFORMAT_RGBA4444  => 0x15421002 ],
            [ SDL_PIXELFORMAT_ABGR4444      => 0x15721002 ], [ SDL_PIXELFORMAT_BGRA4444  => 0x15821002 ], [ SDL_PIXELFORMAT_ARGB1555  => 0x15331002 ],
            [ SDL_PIXELFORMAT_RGBA5551      => 0x15441002 ], [ SDL_PIXELFORMAT_ABGR1555  => 0x15731002 ], [ SDL_PIXELFORMAT_BGRA5551  => 0x15841002 ],
            [ SDL_PIXELFORMAT_RGB565        => 0x15151002 ], [ SDL_PIXELFORMAT_BGR565    => 0x15551002 ], [ SDL_PIXELFORMAT_RGB24     => 0x17101803 ],
            [ SDL_PIXELFORMAT_BGR24         => 0x17401803 ], [ SDL_PIXELFORMAT_XRGB8888  => 0x16161804 ], [ SDL_PIXELFORMAT_RGBX8888  => 0x16261804 ],
            [ SDL_PIXELFORMAT_XBGR8888      => 0x16561804 ], [ SDL_PIXELFORMAT_BGRX8888  => 0x16661804 ], [ SDL_PIXELFORMAT_ARGB8888  => 0x16362004 ],
            [ SDL_PIXELFORMAT_RGBA8888      => 0x16462004 ], [ SDL_PIXELFORMAT_ABGR8888  => 0x16762004 ], [ SDL_PIXELFORMAT_BGRA8888  => 0x16862004 ],
            [ SDL_PIXELFORMAT_XRGB2101010   => 0x16172004 ], [ SDL_PIXELFORMAT_XBGR2101010 => 0x16572004 ],
            [ SDL_PIXELFORMAT_ARGB2101010   => 0x16372004 ], [ SDL_PIXELFORMAT_ABGR2101010 => 0x16772004 ], [ SDL_PIXELFORMAT_RGB48  => 0x18103006 ],
            [ SDL_PIXELFORMAT_BGR48         => 0x18403006 ], [ SDL_PIXELFORMAT_RGBA64      => 0x18204008 ], [ SDL_PIXELFORMAT_ARGB64 => 0x18304008 ],
            [ SDL_PIXELFORMAT_BGRA64        => 0x18504008 ], [ SDL_PIXELFORMAT_ABGR64 => 0x18604008 ], [ SDL_PIXELFORMAT_RGB48_FLOAT => 0x1a103006 ],
            [ SDL_PIXELFORMAT_BGR48_FLOAT   => 0x1a403006 ], [ SDL_PIXELFORMAT_RGBA64_FLOAT  => 0x1a204008 ],
            [ SDL_PIXELFORMAT_ARGB64_FLOAT  => 0x1a304008 ], [ SDL_PIXELFORMAT_BGRA64_FLOAT  => 0x1a504008 ],
            [ SDL_PIXELFORMAT_ABGR64_FLOAT  => 0x1a604008 ], [ SDL_PIXELFORMAT_RGB96_FLOAT   => 0x1b10600c ],
            [ SDL_PIXELFORMAT_BGR96_FLOAT   => 0x1b40600c ], [ SDL_PIXELFORMAT_RGBA128_FLOAT => 0x1b208010 ],
            [ SDL_PIXELFORMAT_ARGB128_FLOAT => 0x1b308010 ], [ SDL_PIXELFORMAT_BGRA128_FLOAT => 0x1b508010 ],
            [ SDL_PIXELFORMAT_ABGR128_FLOAT => 0x1b608010 ], [ SDL_PIXELFORMAT_YV12          => 0x32315659 ], [ SDL_PIXELFORMAT_IYUV => 0x56555949 ],
            [ SDL_PIXELFORMAT_YUY2          => 0x32595559 ], [ SDL_PIXELFORMAT_UYVY          => 0x59565955 ], [ SDL_PIXELFORMAT_YVYU => 0x55595659 ],
            [ SDL_PIXELFORMAT_NV12          => 0x3231564e ], [ SDL_PIXELFORMAT_NV21          => 0x3132564e ], [ SDL_PIXELFORMAT_P010 => 0x30313050 ],
            [ SDL_PIXELFORMAT_EXTERNAL_OES  => 0x2053454f ], [ SDL_PIXELFORMAT_MJPG          => 0x47504a4d ],

            # Aliases for RGBA byte arrays of color data, for the current platform
            (
                $Config{byteorder} =~ /1$/ ?
                    (
                    [ SDL_PIXELFORMAT_RGBA32 => 'SDL_PIXELFORMAT_RGBA8888' ],
                    [ SDL_PIXELFORMAT_ARGB32 => 'SDL_PIXELFORMAT_ARGB8888' ],
                    [ SDL_PIXELFORMAT_BGRA32 => 'SDL_PIXELFORMAT_BGRA8888' ],
                    [ SDL_PIXELFORMAT_ABGR32 => 'SDL_PIXELFORMAT_ABGR8888' ],
                    [ SDL_PIXELFORMAT_RGBX32 => 'SDL_PIXELFORMAT_RGBX8888' ],
                    [ SDL_PIXELFORMAT_XRGB32 => 'SDL_PIXELFORMAT_XRGB8888' ],
                    [ SDL_PIXELFORMAT_BGRX32 => 'SDL_PIXELFORMAT_BGRX8888' ],
                    [ SDL_PIXELFORMAT_XBGR32 => 'SDL_PIXELFORMAT_XBGR8888' ]
                    ) :
                    (
                    [ SDL_PIXELFORMAT_RGBA32 => 'SDL_PIXELFORMAT_ABGR8888' ],
                    [ SDL_PIXELFORMAT_ARGB32 => 'SDL_PIXELFORMAT_BGRA8888' ],
                    [ SDL_PIXELFORMAT_BGRA32 => 'SDL_PIXELFORMAT_ARGB8888' ],
                    [ SDL_PIXELFORMAT_ABGR32 => 'SDL_PIXELFORMAT_RGBA8888' ],
                    [ SDL_PIXELFORMAT_RGBX32 => 'SDL_PIXELFORMAT_XBGR8888' ],
                    [ SDL_PIXELFORMAT_XRGB32 => 'SDL_PIXELFORMAT_BGRX8888' ],
                    [ SDL_PIXELFORMAT_BGRX32 => 'SDL_PIXELFORMAT_XRGB8888' ],
                    [ SDL_PIXELFORMAT_XBGR32 => 'SDL_PIXELFORMAT_RGBX8888' ]
                    )
            )
        ];
        _func_and_export(
            SDL_DEFINE_COLORSPACE => sub ( $type, $range, $primaries, $transfer, $matrix, $chroma ) {
                ( ( ($type) << 28 ) | ( ($range) << 24 ) | ( ($chroma) << 20 ) | ( ($primaries) << 10 ) | ( ($transfer) << 5 ) | ( ($matrix) << 0 ) )
            }
        );
        _func_and_export( SDL_COLORSPACETYPE      => sub ($cspace) { ( ( ($cspace) >> 28 ) & 0x0F ) } );
        _func_and_export( SDL_COLORSPACERANGE     => sub ($cspace) { ( ( ($cspace) >> 24 ) & 0x0F ) } );
        _func_and_export( SDL_COLORSPACECHROMA    => sub ($cspace) { ( ( ($cspace) >> 20 ) & 0x0F ) } );
        _func_and_export( SDL_COLORSPACEPRIMARIES => sub ($cspace) { ( ( ($cspace) >> 10 ) & 0x1F ) } );
        _func_and_export( SDL_COLORSPACETRANSFER  => sub ($cspace) { ( ( ($cspace) >> 5 ) & 0x1F ) } );
        _func_and_export( SDL_COLORSPACEMATRIX    => sub ($cspace) { ( ($cspace) & 0x1F ) } );
        _func_and_export(
            SDL_ISCOLORSPACE_MATRIX_BT601 => sub ($cspace) {
                ( SDL_COLORSPACEMATRIX($cspace) == SDL_MATRIX_COEFFICIENTS_BT601() ||
                        SDL_COLORSPACEMATRIX($cspace) == SDL_MATRIX_COEFFICIENTS_BT470BG() )
            }
        );
        _func_and_export( SDL_ISCOLORSPACE_MATRIX_BT709 => sub ($cspace) { ( SDL_COLORSPACEMATRIX($cspace) == SDL_MATRIX_COEFFICIENTS_BT709() ) } );
        _func_and_export(
            SDL_ISCOLORSPACE_MATRIX_BT2020_NCL => sub ($cspace) { ( SDL_COLORSPACEMATRIX($cspace) == SDL_MATRIX_COEFFICIENTS_BT2020_NCL() ) } );
        _func_and_export( SDL_ISCOLORSPACE_LIMITED_RANGE => sub ($cspace) { ( SDL_COLORSPACERANGE($cspace) != SDL_COLOR_RANGE_FULL() ) } );
        _func_and_export( SDL_ISCOLORSPACE_FULL_RANGE    => sub ($cspace) { ( SDL_COLORSPACERANGE($cspace) == SDL_COLOR_RANGE_FULL() ) } );
        _enum_and_export SDL_Colorspace => [
            [ SDL_COLORSPACE_UNKNOWN        => 0 ],
            [ SDL_COLORSPACE_SRGB           => 0x120005a0 ],
            [ SDL_COLORSPACE_SRGB_LINEAR    => 0x12000500 ],
            [ SDL_COLORSPACE_HDR10          => 0x12002600 ],
            [ SDL_COLORSPACE_JPEG           => 0x220004c6 ],
            [ SDL_COLORSPACE_BT601_LIMITED  => 0x211018c6 ],
            [ SDL_COLORSPACE_BT601_FULL     => 0x221018c6 ],
            [ SDL_COLORSPACE_BT709_LIMITED  => 0x21100421 ],
            [ SDL_COLORSPACE_BT709_FULL     => 0x22100421 ],
            [ SDL_COLORSPACE_BT2020_LIMITED => 0x21102609 ],
            [ SDL_COLORSPACE_BT2020_FULL    => 0x22102609 ],
            [ SDL_COLORSPACE_RGB_DEFAULT    => 'SDL_COLORSPACE_SRGB' ],
            [ SDL_COLORSPACE_YUV_DEFAULT    => 'SDL_COLORSPACE_BT601_LIMITED' ]
        ];
        _typedef_and_export SDL_Color   => Struct [ r       => UInt8, g      => UInt8, b => UInt8, a => UInt8 ];
        _typedef_and_export SDL_FColor  => Struct [ r       => Float, g      => Float, b => Float, a => Float ];
        _typedef_and_export SDL_Palette => Struct [ ncolors => Int,   colors => Pointer [ SDL_Color() ], version => UInt32, refcount => Int ];
        _typedef_and_export SDL_PixelFormatDetails => Struct [
            format          => SDL_PixelFormat(),
            bits_per_pixel  => UInt8,
            bytes_per_pixel => UInt8,
            padding         => Array [ UInt8, 2 ],
            Rmask           => UInt32,
            Gmask           => UInt32,
            Bmask           => UInt32,
            Amask           => UInt32,
            Rbits           => UInt8,
            Gbits           => UInt8,
            Bbits           => UInt8,
            Abits           => UInt8,
            Rshift          => UInt8,
            Gshift          => UInt8,
            Bshift          => UInt8,
            Ashift          => UInt8
        ];
        _affix_and_export SDL_GetPixelFormatName => [ SDL_PixelFormat() ], String;
        _affix_and_export
            SDL_GetMasksForPixelFormat =>
            [ SDL_PixelFormat(), Pointer [Int], Pointer [UInt32], Pointer [UInt32], Pointer [UInt32], Pointer [UInt32] ],
            Bool;
        _affix_and_export SDL_GetPixelFormatForMasks => [ Int, UInt32, UInt32, UInt32, UInt32 ], SDL_PixelFormat();
        _affix_and_export SDL_GetPixelFormatDetails  => [ SDL_PixelFormat() ], Pointer [ SDL_PixelFormatDetails() ];
        _affix_and_export SDL_CreatePalette          => [Int], Pointer [ SDL_Palette() ];
        _affix_and_export SDL_SetPaletteColors       => [ Pointer [ SDL_Palette() ], Pointer [ SDL_Color() ], Int, Int ], Bool;
        _affix_and_export SDL_DestroyPalette         => [ Pointer [ SDL_Palette() ] ], Void;
        _affix_and_export SDL_MapRGB => [ Pointer [ SDL_PixelFormatDetails() ], Pointer [ SDL_Palette() ], UInt8, UInt8, UInt8 ], UInt32;
        _affix_and_export
            SDL_MapRGBA => [ Pointer [ SDL_PixelFormatDetails() ], Pointer [ SDL_Palette() ], UInt8, UInt8, UInt8, UInt8 ],
            UInt32;
        _affix_and_export
            SDL_GetRGB =>
            [ UInt32, Pointer [ SDL_PixelFormatDetails() ], Pointer [ SDL_Palette() ], Pointer [UInt8], Pointer [UInt8], Pointer [UInt8] ],
            Void;
        _affix_and_export
            SDL_GetRGBA => [
            UInt32,
            Pointer [ SDL_PixelFormatDetails() ],
            Pointer [ SDL_Palette() ],
            Pointer [UInt8],
            Pointer [UInt8],
            Pointer [UInt8],
            Pointer [UInt8]
            ],
            Void;
    }

=head3 C<:platform> - Platform Detection

SDL provides a means to identify the app's platform, both at compile time and runtime.

See L<SDL3: CategoryPlatform|https://wiki.libsdl.org/SDL3/CategoryPlatform>

=cut

    sub _platform() {
        state $done++ && return;
        _platform_defines();
        #
        _affix_and_export 'SDL_GetPlatform', [], String;
    }

    sub _platform_defines() {
        state $done++ && return;

        # We don't need this
    }

=head3 C<:power> - Power Management Status

SDL power management routines.

Well, routine.

There is a single function in this category: L<SDL_GetPowerInfo()|https://wiki.libsdl.org/SDL3/SDL_GetPowerInfo>.

This function is useful for games on the go. This allows an app to know if it's running on a draining battery, which
can be useful if the app wants to reduce processing, or perhaps framerate, to extend the duration of the battery's
charge. Perhaps the app just wants to show a battery meter when fullscreen, or alert the user when the power is getting
extremely low, so they can save their game.

See L<SDL3: CategoryPower|https://wiki.libsdl.org/SDL3/CategoryPower>

=cut

    sub _power() {
        state $done++ && return;
        #
        _error();
        _stdinc();
        #
        _enum_and_export SDL_PowerState => [
            [ SDL_POWERSTATE_ERROR      => -1 ],
            [ SDL_POWERSTATE_UNKNOWN    =>  0 ],
            [ SDL_POWERSTATE_ON_BATTERY =>  1 ],
            [ SDL_POWERSTATE_NO_BATTERY =>  2 ],
            [ SDL_POWERSTATE_CHARGING   =>  3 ],
            [ SDL_POWERSTATE_CHARGED    =>  4 ],
        ];
        _affix_and_export SDL_GetPowerInfo => [ Pointer [Int], Pointer [Int] ], SDL_PowerState();
    }

=head3 C<:process> - Process Control

Process control support.

These functions provide a cross-platform way to spawn and manage OS-level processes.

See L<SDL3: CategoryProcess|https://wiki.libsdl.org/SDL3/CategoryProcess>

=cut

    sub _process() {
        state $done++ && return;
        #
        _error();
        _iostream();
        _properties();
        _stdinc();
        #
        _typedef_and_export SDL_Process => Void;
        _affix_and_export SDL_CreateProcess => [ Pointer [String], Bool ], Pointer [ SDL_Process() ];
        _enum_and_export SDL_ProcessIO =>
            [ 'SDL_PROCESS_STDIO_INHERITED', 'SDL_PROCESS_STDIO_NULL', 'SDL_PROCESS_STDIO_APP', 'SDL_PROCESS_STDIO_REDIRECT' ];
        _affix_and_export SDL_CreateProcessWithProperties => [ SDL_PropertiesID() ], Pointer [ SDL_Process() ];
        _const_and_export SDL_PROP_PROCESS_CREATE_ARGS_POINTER             => 'SDL.process.create.args';
        _const_and_export SDL_PROP_PROCESS_CREATE_ENVIRONMENT_POINTER      => 'SDL.process.create.environment';
        _const_and_export SDL_PROP_PROCESS_CREATE_WORKING_DIRECTORY_STRING => 'SDL.process.create.working_directory';
        _const_and_export SDL_PROP_PROCESS_CREATE_STDIN_NUMBER             => 'SDL.process.create.stdin_option';
        _const_and_export SDL_PROP_PROCESS_CREATE_STDIN_POINTER            => 'SDL.process.create.stdin_source';
        _const_and_export SDL_PROP_PROCESS_CREATE_STDOUT_NUMBER            => 'SDL.process.create.stdout_option';
        _const_and_export SDL_PROP_PROCESS_CREATE_STDOUT_POINTER           => 'SDL.process.create.stdout_source';
        _const_and_export SDL_PROP_PROCESS_CREATE_STDERR_NUMBER            => 'SDL.process.create.stderr_option';
        _const_and_export SDL_PROP_PROCESS_CREATE_STDERR_POINTER           => 'SDL.process.create.stderr_source';
        _const_and_export SDL_PROP_PROCESS_CREATE_STDERR_TO_STDOUT_BOOLEAN => 'SDL.process.create.stderr_to_stdout';
        _const_and_export SDL_PROP_PROCESS_CREATE_BACKGROUND_BOOLEAN       => 'SDL.process.create.background';
        _const_and_export SDL_PROP_PROCESS_CREATE_CMDLINE_STRING           => 'SDL.process.create.cmdline';
        _affix_and_export SDL_GetProcessProperties => [ Pointer [ SDL_Process() ] ], SDL_PropertiesID();
        _const_and_export SDL_PROP_PROCESS_PID_NUMBER         => 'SDL.process.pid';
        _const_and_export SDL_PROP_PROCESS_STDIN_POINTER      => 'SDL.process.stdin';
        _const_and_export SDL_PROP_PROCESS_STDOUT_POINTER     => 'SDL.process.stdout';
        _const_and_export SDL_PROP_PROCESS_STDERR_POINTER     => 'SDL.process.stderr';
        _const_and_export SDL_PROP_PROCESS_BACKGROUND_BOOLEAN => 'SDL.process.background';
        _affix_and_export SDL_ReadProcess      => [ Pointer [ SDL_Process() ], Pointer [Size_t], Pointer [Int] ], Pointer [Void];
        _affix_and_export SDL_GetProcessInput  => [ Pointer [ SDL_Process() ] ], Pointer [ SDL_IOStream() ];
        _affix_and_export SDL_GetProcessOutput => [ Pointer [ SDL_Process() ] ], Pointer [ SDL_IOStream() ];
        _affix_and_export SDL_KillProcess      => [ Pointer [ SDL_Process() ], Bool ], Bool;
        _affix_and_export SDL_WaitProcess      => [ Pointer [ SDL_Process() ], Bool, Pointer [Int] ], Bool;
        _affix_and_export SDL_DestroyProcess   => [ Pointer [ SDL_Process() ] ], Void;
    }

=head3 C<:properties> - Object Properties

A property is a variable that can be created and retrieved by name at runtime.

See L<SDL3: CategoryProperties|https://wiki.libsdl.org/SDL3/CategoryProperties>

=cut

    sub _properties() {
        state $done++ && return;
        #
        _error();
        _stdinc();
        #
        _typedef_and_export SDL_PropertiesID => UInt32;
        _enum_and_export SDL_PropertyType => [
            'SDL_PROPERTY_TYPE_INVALID', 'SDL_PROPERTY_TYPE_POINTER', 'SDL_PROPERTY_TYPE_STRING', 'SDL_PROPERTY_TYPE_NUMBER',
            'SDL_PROPERTY_TYPE_FLOAT',   'SDL_PROPERTY_TYPE_BOOLEAN'
        ];
        _const_and_export SDL_PROP_NAME_STRING => 'SDL.name';
        _affix_and_export SDL_GetGlobalProperties => [], SDL_PropertiesID();
        _affix_and_export SDL_CreateProperties    => [], SDL_PropertiesID();
        _affix_and_export SDL_CopyProperties      => [ SDL_PropertiesID(), SDL_PropertiesID() ], Bool;
        _affix_and_export SDL_LockProperties      => [ SDL_PropertiesID() ], Bool;
        _affix_and_export SDL_UnlockProperties    => [ SDL_PropertiesID() ], Void;
        _typedef_and_export SDL_CleanupPropertyCallback => Callback [ [ Pointer [Void], Pointer [Void] ] => Void ];
        _affix_and_export
            SDL_SetPointerPropertyWithCleanup => [ SDL_PropertiesID(), String, Pointer [Void], SDL_CleanupPropertyCallback(), Pointer [Void] ],
            Bool;
        _affix_and_export SDL_SetPointerProperty => [ SDL_PropertiesID(), String, Pointer [Void] ], Bool;
        _affix_and_export SDL_SetStringProperty  => [ SDL_PropertiesID(), String, String ], Bool;
        _affix_and_export SDL_SetNumberProperty  => [ SDL_PropertiesID(), String, SInt64 ], Bool;
        _affix_and_export SDL_SetFloatProperty   => [ SDL_PropertiesID(), String, Float ],  Bool;
        _affix_and_export SDL_SetBooleanProperty => [ SDL_PropertiesID(), String, Bool ],   Bool;
        _affix_and_export SDL_HasProperty        => [ SDL_PropertiesID(), String ], Bool;
        _affix_and_export SDL_GetPropertyType    => [ SDL_PropertiesID(), String ], SDL_PropertyType();
        _affix_and_export SDL_GetPointerProperty => [ SDL_PropertiesID(), String, Pointer [Void] ], Pointer [Void];
        _affix_and_export SDL_GetStringProperty  => [ SDL_PropertiesID(), String, String ], String;
        _affix_and_export SDL_GetNumberProperty  => [ SDL_PropertiesID(), String, SInt64 ], SInt64;
        _affix_and_export SDL_GetFloatProperty   => [ SDL_PropertiesID(), String, Float ],  Float;
        _affix_and_export SDL_GetBooleanProperty => [ SDL_PropertiesID(), String, Bool ],   Bool;
        _affix_and_export SDL_ClearProperty      => [ SDL_PropertiesID(), String ], Bool;
        _typedef_and_export SDL_EnumeratePropertiesCallback => Callback [ [ Pointer [Void], SDL_PropertiesID(), String ] => Void ];
        _affix_and_export
            SDL_EnumerateProperties => [ SDL_PropertiesID(), SDL_EnumeratePropertiesCallback(), Pointer [Void] ],
            Bool;
        _affix_and_export SDL_DestroyProperties => [ SDL_PropertiesID() ], Void;
    }

=head3 C<:rect> - Rectangle Functions

Some helper functions for managing rectangles and 2D points, in both integer and floating point versions.

See L<SDL3: CategoryRect|https://wiki.libsdl.org/SDL3/CategoryRect>

=cut

    sub _rect() {
        state $done++ && return;
        _error();
        _stdinc();
        #
        _typedef_and_export SDL_Point  => Struct [ x => Int,   y => Int ];
        _typedef_and_export SDL_FPoint => Struct [ x => Float, y => Float ];
        _typedef_and_export SDL_Rect   => Struct [ x => Int,   y => Int,   w => Int,   h => Int ];
        _typedef_and_export SDL_FRect  => Struct [ x => Float, y => Float, w => Float, h => Float ];
        _func_and_export SDL_PointInRect => sub ( $p, $r ) {
            return ( $p &&
                    $r                                  &&
                    ( $p->{x} >= $r->{x} )              &&
                    ( $p->{x} < ( $r->{x} + $r->{w} ) ) &&
                    ( $p->{y} >= $r->{y} )              &&
                    ( $p->{y} < ( $r->{y} + $r->{h} ) ) ) ? 1 : 0;
        };
        _func_and_export SDL_RectEmpty  => sub ($r) { ( ( !$r ) || ( $r->{w} <= 0 ) || ( $r->{h} <= 0 ) ) ? 1 : 0 };
        _func_and_export SDL_RectsEqual => sub ( $a, $b ) {
            return ( $a && $b && ( $a->{x} == $b->{x} ) && ( $a->{y} == $b->{y} ) && ( $a->{w} == $b->{w} ) && ( $a->{h} == $b->{h} ) ) ? 1 : 0;
        };
        _affix_and_export SDL_HasRectIntersection        => [ Pointer [ SDL_Rect() ], Pointer [ SDL_Rect() ] ], Bool;
        _affix_and_export SDL_GetRectIntersection        => [ Pointer [ SDL_Rect() ], Pointer [ SDL_Rect() ], Pointer [ SDL_Rect() ] ], Bool;
        _affix_and_export SDL_GetRectUnion               => [ Pointer [ SDL_Rect() ], Pointer [ SDL_Rect() ], Pointer [ SDL_Rect() ] ], Bool;
        _affix_and_export SDL_GetRectEnclosingPoints     => [ Pointer [ SDL_Point() ], Int, Pointer [ SDL_Rect() ], Pointer [ SDL_Rect() ] ], Bool;
        _affix_and_export SDL_GetRectAndLineIntersection => [ Pointer [ SDL_Rect() ], Pointer [ SDL_Rect() ], Pointer [ SDL_Rect() ] ], Bool;
        _func_and_export SDL_PointInRectFloat => sub ( $p, $r ) {
            return ( $p &&
                    $r                                   &&
                    ( $p->{x} >= $r->{x} )               &&
                    ( $p->{x} <= ( $r->{x} + $r->{w} ) ) &&
                    ( $p->{y} >= $r->{y} )               &&
                    ( $p->{y} <= ( $r->{y} + $r->{h} ) ) ) ? 1 : 0;
        };
        _func_and_export SDL_RectEmptyFloat => sub ($r) {
            return ( ( !$r ) || ( $r->{w} < 0.0 ) || ( $r->{h} < 0.0 ) ) ? 1 : 0;
        };
        _func_and_export SDL_RectsEqualEpsilon => sub ( $a, $b, $epsilon ) {
            return (
                $a && $b && (
                    ( $a == $b ) ||
                    ( ( SDL_fabsf( $a->{x} - $b->{x} ) <= $epsilon ) &&
                        ( SDL_fabsf( $a->{y} - $b->{y} ) <= $epsilon ) &&
                        ( SDL_fabsf( $a->{w} - $b->{w} ) <= $epsilon ) &&
                        ( SDL_fabsf( $a->{h} - $b->{h} ) <= $epsilon ) )
                )
            ) ? 1 : 0;
        };
        _func_and_export SDL_RectsEqualFloat => sub ( $a, $b ) {
            SDL_RectsEqualEpsilon( $a, $b, SDL_FLT_EPSILON() );
        };
        _affix_and_export SDL_HasRectIntersectionFloat    => [ Pointer [ SDL_FRect() ], Pointer [ SDL_FRect() ] ], Bool;
        _affix_and_export SDL_GetRectIntersectionFloat    => [ Pointer [ SDL_FRect() ], Pointer [ SDL_FRect() ], Pointer [ SDL_FRect() ] ], Bool;
        _affix_and_export SDL_GetRectUnionFloat           => [ Pointer [ SDL_FRect() ], Pointer [ SDL_FRect() ], Pointer [ SDL_FRect() ] ], Bool;
        _affix_and_export SDL_GetRectEnclosingPointsFloat => [ Pointer [ SDL_FRect() ], Int, Pointer [ SDL_FRect() ], Pointer [ SDL_FRect() ] ], Bool;
        _affix_and_export
            SDL_GetRectAndLineIntersectionFloat => [ Pointer [ SDL_FRect() ], Pointer [Float], Pointer [Float], Pointer [Float], Pointer [Float] ],
            Bool;
    }

=head3 C<:render> - 2D Accelerated Rendering

SDL 2D rendering functions.

See L<SDL3: CategoryRender|https://wiki.libsdl.org/SDL3/CategoryRender>

=cut

    sub _render() {
        state $done++ && return;
        #
        _blendmode();
        _error();
        _events();
        _gpu();
        _pixels();
        _properties();
        _rect();
        _stdinc();
        _surface();
        _video();
        #
        _const_and_export SDL_SOFTWARE_RENDERER => 'software';
        _const_and_export SDL_GPU_RENDERER      => 'gpu';
        _typedef_and_export SDL_Vertex => Struct [ position => SDL_FPoint(), color => SDL_FColor(), tex_coord => SDL_FPoint() ];
        _enum_and_export SDL_TextureAccess => [ 'SDL_TEXTUREACCESS_STATIC', 'SDL_TEXTUREACCESS_STREAMING', 'SDL_TEXTUREACCESS_TARGET' ];
        _enum_and_export SDL_TextureAddressMode =>
            [ [ SDL_TEXTURE_ADDRESS_INVALID => -1 ], 'SDL_TEXTURE_ADDRESS_AUTO', 'SDL_TEXTURE_ADDRESS_CLAMP', 'SDL_TEXTURE_ADDRESS_WRAP' ];
        _enum_and_export SDL_RendererLogicalPresentation => [
            'SDL_LOGICAL_PRESENTATION_DISABLED',  'SDL_LOGICAL_PRESENTATION_STRETCH',
            'SDL_LOGICAL_PRESENTATION_LETTERBOX', 'SDL_LOGICAL_PRESENTATION_OVERSCAN',
            'SDL_LOGICAL_PRESENTATION_INTEGER_SCALE'
        ];
        _typedef_and_export SDL_Renderer => Void;
        _typedef_and_export SDL_Texture  => Struct [ format => SDL_PixelFormat(), w => Int, h => Int, refcount => Int ];
        _affix_and_export SDL_GetNumRenderDrivers => [], Int;
        _affix_and_export SDL_GetRenderDriver => [Int], String;
        _affix_and_export
            SDL_CreateWindowAndRenderer =>
            [ String, Int, Int, SDL_WindowFlags(), Pointer [ Pointer [ SDL_Window() ] ], Pointer [ Pointer [ SDL_Renderer() ] ] ],
            Bool;
        _affix_and_export SDL_CreateRenderer => [ Pointer [ SDL_Window() ], String ], Pointer [ SDL_Renderer() ];
        _affix_and_export SDL_CreateRendererWithProperties => [ SDL_PropertiesID() ], Pointer [ SDL_Renderer() ];
        _const_and_export SDL_PROP_RENDERER_CREATE_NAME_STRING                    => 'SDL.renderer.create.name';
        _const_and_export SDL_PROP_RENDERER_CREATE_WINDOW_POINTER                 => 'SDL.renderer.create.window';
        _const_and_export SDL_PROP_RENDERER_CREATE_SURFACE_POINTER                => 'SDL.renderer.create.surface';
        _const_and_export SDL_PROP_RENDERER_CREATE_OUTPUT_COLORSPACE_NUMBER       => 'SDL.renderer.create.output_colorspace';
        _const_and_export SDL_PROP_RENDERER_CREATE_PRESENT_VSYNC_NUMBER           => 'SDL.renderer.create.present_vsync';
        _const_and_export SDL_PROP_RENDERER_CREATE_GPU_DEVICE_POINTER             => 'SDL.renderer.create.gpu.device';
        _const_and_export SDL_PROP_RENDERER_CREATE_GPU_SHADERS_SPIRV_BOOLEAN      => 'SDL.renderer.create.gpu.shaders_spirv';
        _const_and_export SDL_PROP_RENDERER_CREATE_GPU_SHADERS_DXIL_BOOLEAN       => 'SDL.renderer.create.gpu.shaders_dxil';
        _const_and_export SDL_PROP_RENDERER_CREATE_GPU_SHADERS_MSL_BOOLEAN        => 'SDL.renderer.create.gpu.shaders_msl';
        _const_and_export SDL_PROP_RENDERER_CREATE_VULKAN_INSTANCE_POINTER        => 'SDL.renderer.create.vulkan.instance';
        _const_and_export SDL_PROP_RENDERER_CREATE_VULKAN_SURFACE_NUMBER          => 'SDL.renderer.create.vulkan.surface';
        _const_and_export SDL_PROP_RENDERER_CREATE_VULKAN_PHYSICAL_DEVICE_POINTER => 'SDL.renderer.create.vulkan.physical_device';
        _const_and_export SDL_PROP_RENDERER_CREATE_VULKAN_DEVICE_POINTER          => 'SDL.renderer.create.vulkan.device';
        _const_and_export SDL_PROP_RENDERER_CREATE_VULKAN_GRAPHICS_QUEUE_FAMILY_INDEX_NUMBER =>
            'SDL.renderer.create.vulkan.graphics_queue_family_index';
        _const_and_export SDL_PROP_RENDERER_CREATE_VULKAN_PRESENT_QUEUE_FAMILY_INDEX_NUMBER =>
            'SDL.renderer.create.vulkan.present_queue_family_index';

        #~ _affix_and_export
        #~ SDL_CreateGPURenderer => [ Pointer [ SDL_GPUDevice() ], Pointer [ SDL_Window() ] ],
        #~ Pointer [ SDL_Renderer() ];
        #~ _affix_and_export SDL_GetGPURendererDevice   => [ Pointer [ SDL_Renderer() ] ], Pointer [ SDL_GPUDevice() ];
        _affix_and_export SDL_CreateSoftwareRenderer => [ Pointer [ SDL_Surface() ] ],  Pointer [ SDL_Renderer() ];
        _affix_and_export SDL_GetRenderer            => [ Pointer [ SDL_Window() ] ],   Pointer [ SDL_Renderer() ];
        _affix_and_export SDL_GetRenderWindow        => [ Pointer [ SDL_Renderer() ] ], Pointer [ SDL_Window() ];
        _affix_and_export SDL_GetRendererName        => [ Pointer [ SDL_Renderer() ] ], String;
        _affix_and_export SDL_GetRendererProperties  => [ Pointer [ SDL_Renderer() ] ], SDL_PropertiesID();
        _const_and_export SDL_PROP_RENDERER_NAME_STRING                               => 'SDL.renderer.name';
        _const_and_export SDL_PROP_RENDERER_WINDOW_POINTER                            => 'SDL.renderer.window';
        _const_and_export SDL_PROP_RENDERER_SURFACE_POINTER                           => 'SDL.renderer.surface';
        _const_and_export SDL_PROP_RENDERER_VSYNC_NUMBER                              => 'SDL.renderer.vsync';
        _const_and_export SDL_PROP_RENDERER_MAX_TEXTURE_SIZE_NUMBER                   => 'SDL.renderer.max_texture_size';
        _const_and_export SDL_PROP_RENDERER_TEXTURE_FORMATS_POINTER                   => 'SDL.renderer.texture_formats';
        _const_and_export SDL_PROP_RENDERER_TEXTURE_WRAPPING_BOOLEAN                  => 'SDL.renderer.texture_wrapping';
        _const_and_export SDL_PROP_RENDERER_OUTPUT_COLORSPACE_NUMBER                  => 'SDL.renderer.output_colorspace';
        _const_and_export SDL_PROP_RENDERER_HDR_ENABLED_BOOLEAN                       => 'SDL.renderer.HDR_enabled';
        _const_and_export SDL_PROP_RENDERER_SDR_WHITE_POINT_FLOAT                     => 'SDL.renderer.SDR_white_point';
        _const_and_export SDL_PROP_RENDERER_HDR_HEADROOM_FLOAT                        => 'SDL.renderer.HDR_headroom';
        _const_and_export SDL_PROP_RENDERER_D3D9_DEVICE_POINTER                       => 'SDL.renderer.d3d9.device';
        _const_and_export SDL_PROP_RENDERER_D3D11_DEVICE_POINTER                      => 'SDL.renderer.d3d11.device';
        _const_and_export SDL_PROP_RENDERER_D3D11_SWAPCHAIN_POINTER                   => 'SDL.renderer.d3d11.swap_chain';
        _const_and_export SDL_PROP_RENDERER_D3D12_DEVICE_POINTER                      => 'SDL.renderer.d3d12.device';
        _const_and_export SDL_PROP_RENDERER_D3D12_SWAPCHAIN_POINTER                   => 'SDL.renderer.d3d12.swap_chain';
        _const_and_export SDL_PROP_RENDERER_D3D12_COMMAND_QUEUE_POINTER               => 'SDL.renderer.d3d12.command_queue';
        _const_and_export SDL_PROP_RENDERER_VULKAN_INSTANCE_POINTER                   => 'SDL.renderer.vulkan.instance';
        _const_and_export SDL_PROP_RENDERER_VULKAN_SURFACE_NUMBER                     => 'SDL.renderer.vulkan.surface';
        _const_and_export SDL_PROP_RENDERER_VULKAN_PHYSICAL_DEVICE_POINTER            => 'SDL.renderer.vulkan.physical_device';
        _const_and_export SDL_PROP_RENDERER_VULKAN_DEVICE_POINTER                     => 'SDL.renderer.vulkan.device';
        _const_and_export SDL_PROP_RENDERER_VULKAN_GRAPHICS_QUEUE_FAMILY_INDEX_NUMBER => 'SDL.renderer.vulkan.graphics_queue_family_index';
        _const_and_export SDL_PROP_RENDERER_VULKAN_PRESENT_QUEUE_FAMILY_INDEX_NUMBER  => 'SDL.renderer.vulkan.present_queue_family_index';
        _const_and_export SDL_PROP_RENDERER_VULKAN_SWAPCHAIN_IMAGE_COUNT_NUMBER       => 'SDL.renderer.vulkan.swapchain_image_count';
        _const_and_export SDL_PROP_RENDERER_GPU_DEVICE_POINTER                        => 'SDL.renderer.gpu.device';
        _affix_and_export SDL_GetRenderOutputSize        => [ Pointer [ SDL_Renderer() ], Pointer [Int], Pointer [Int] ], Bool;
        _affix_and_export SDL_GetCurrentRenderOutputSize => [ Pointer [ SDL_Renderer() ], Pointer [Int], Pointer [Int] ], Bool;
        _affix_and_export
            SDL_CreateTexture => [ Pointer [ SDL_Renderer() ], SDL_PixelFormat(), SDL_TextureAccess(), Int, Int ],
            Pointer [ SDL_Texture() ];
        _affix_and_export
            SDL_CreateTextureFromSurface => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_Surface() ] ],
            Pointer [ SDL_Texture() ];
        _affix_and_export
            SDL_CreateTextureWithProperties => [ Pointer [ SDL_Renderer() ], SDL_PropertiesID() ],
            Pointer [ SDL_Texture() ];
        _const_and_export SDL_PROP_TEXTURE_CREATE_COLORSPACE_NUMBER           => 'SDL.texture.create.colorspace';
        _const_and_export SDL_PROP_TEXTURE_CREATE_FORMAT_NUMBER               => 'SDL.texture.create.format';
        _const_and_export SDL_PROP_TEXTURE_CREATE_ACCESS_NUMBER               => 'SDL.texture.create.access';
        _const_and_export SDL_PROP_TEXTURE_CREATE_WIDTH_NUMBER                => 'SDL.texture.create.width';
        _const_and_export SDL_PROP_TEXTURE_CREATE_HEIGHT_NUMBER               => 'SDL.texture.create.height';
        _const_and_export SDL_PROP_TEXTURE_CREATE_PALETTE_POINTER             => 'SDL.texture.create.palette';
        _const_and_export SDL_PROP_TEXTURE_CREATE_SDR_WHITE_POINT_FLOAT       => 'SDL.texture.create.SDR_white_point';
        _const_and_export SDL_PROP_TEXTURE_CREATE_HDR_HEADROOM_FLOAT          => 'SDL.texture.create.HDR_headroom';
        _const_and_export SDL_PROP_TEXTURE_CREATE_D3D11_TEXTURE_POINTER       => 'SDL.texture.create.d3d11.texture';
        _const_and_export SDL_PROP_TEXTURE_CREATE_D3D11_TEXTURE_U_POINTER     => 'SDL.texture.create.d3d11.texture_u';
        _const_and_export SDL_PROP_TEXTURE_CREATE_D3D11_TEXTURE_V_POINTER     => 'SDL.texture.create.d3d11.texture_v';
        _const_and_export SDL_PROP_TEXTURE_CREATE_D3D12_TEXTURE_POINTER       => 'SDL.texture.create.d3d12.texture';
        _const_and_export SDL_PROP_TEXTURE_CREATE_D3D12_TEXTURE_U_POINTER     => 'SDL.texture.create.d3d12.texture_u';
        _const_and_export SDL_PROP_TEXTURE_CREATE_D3D12_TEXTURE_V_POINTER     => 'SDL.texture.create.d3d12.texture_v';
        _const_and_export SDL_PROP_TEXTURE_CREATE_METAL_PIXELBUFFER_POINTER   => 'SDL.texture.create.metal.pixelbuffer';
        _const_and_export SDL_PROP_TEXTURE_CREATE_OPENGL_TEXTURE_NUMBER       => 'SDL.texture.create.opengl.texture';
        _const_and_export SDL_PROP_TEXTURE_CREATE_OPENGL_TEXTURE_UV_NUMBER    => 'SDL.texture.create.opengl.texture_uv';
        _const_and_export SDL_PROP_TEXTURE_CREATE_OPENGL_TEXTURE_U_NUMBER     => 'SDL.texture.create.opengl.texture_u';
        _const_and_export SDL_PROP_TEXTURE_CREATE_OPENGL_TEXTURE_V_NUMBER     => 'SDL.texture.create.opengl.texture_v';
        _const_and_export SDL_PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_NUMBER    => 'SDL.texture.create.opengles2.texture';
        _const_and_export SDL_PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_UV_NUMBER => 'SDL.texture.create.opengles2.texture_uv';
        _const_and_export SDL_PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_U_NUMBER  => 'SDL.texture.create.opengles2.texture_u';
        _const_and_export SDL_PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_V_NUMBER  => 'SDL.texture.create.opengles2.texture_v';
        _const_and_export SDL_PROP_TEXTURE_CREATE_VULKAN_TEXTURE_NUMBER       => 'SDL.texture.create.vulkan.texture';
        _const_and_export SDL_PROP_TEXTURE_CREATE_GPU_TEXTURE_POINTER         => 'SDL.texture.create.gpu.texture';
        _const_and_export SDL_PROP_TEXTURE_CREATE_GPU_TEXTURE_UV_POINTER      => 'SDL.texture.create.gpu.texture_uv';
        _const_and_export SDL_PROP_TEXTURE_CREATE_GPU_TEXTURE_U_POINTER       => 'SDL.texture.create.gpu.texture_u';
        _const_and_export SDL_PROP_TEXTURE_CREATE_GPU_TEXTURE_V_POINTER       => 'SDL.texture.create.gpu.texture_v';
        _affix_and_export SDL_GetTextureProperties => [ Pointer [ SDL_Texture() ] ], SDL_PropertiesID();
        _const_and_export SDL_PROP_TEXTURE_COLORSPACE_NUMBER               => 'SDL.texture.colorspace';
        _const_and_export SDL_PROP_TEXTURE_FORMAT_NUMBER                   => 'SDL.texture.format';
        _const_and_export SDL_PROP_TEXTURE_ACCESS_NUMBER                   => 'SDL.texture.access';
        _const_and_export SDL_PROP_TEXTURE_WIDTH_NUMBER                    => 'SDL.texture.width';
        _const_and_export SDL_PROP_TEXTURE_HEIGHT_NUMBER                   => 'SDL.texture.height';
        _const_and_export SDL_PROP_TEXTURE_SDR_WHITE_POINT_FLOAT           => 'SDL.texture.SDR_white_point';
        _const_and_export SDL_PROP_TEXTURE_HDR_HEADROOM_FLOAT              => 'SDL.texture.HDR_headroom';
        _const_and_export SDL_PROP_TEXTURE_D3D11_TEXTURE_POINTER           => 'SDL.texture.d3d11.texture';
        _const_and_export SDL_PROP_TEXTURE_D3D11_TEXTURE_U_POINTER         => 'SDL.texture.d3d11.texture_u';
        _const_and_export SDL_PROP_TEXTURE_D3D11_TEXTURE_V_POINTER         => 'SDL.texture.d3d11.texture_v';
        _const_and_export SDL_PROP_TEXTURE_D3D12_TEXTURE_POINTER           => 'SDL.texture.d3d12.texture';
        _const_and_export SDL_PROP_TEXTURE_D3D12_TEXTURE_U_POINTER         => 'SDL.texture.d3d12.texture_u';
        _const_and_export SDL_PROP_TEXTURE_D3D12_TEXTURE_V_POINTER         => 'SDL.texture.d3d12.texture_v';
        _const_and_export SDL_PROP_TEXTURE_OPENGL_TEXTURE_NUMBER           => 'SDL.texture.opengl.texture';
        _const_and_export SDL_PROP_TEXTURE_OPENGL_TEXTURE_UV_NUMBER        => 'SDL.texture.opengl.texture_uv';
        _const_and_export SDL_PROP_TEXTURE_OPENGL_TEXTURE_U_NUMBER         => 'SDL.texture.opengl.texture_u';
        _const_and_export SDL_PROP_TEXTURE_OPENGL_TEXTURE_V_NUMBER         => 'SDL.texture.opengl.texture_v';
        _const_and_export SDL_PROP_TEXTURE_OPENGL_TEXTURE_TARGET_NUMBER    => 'SDL.texture.opengl.target';
        _const_and_export SDL_PROP_TEXTURE_OPENGL_TEX_W_FLOAT              => 'SDL.texture.opengl.tex_w';
        _const_and_export SDL_PROP_TEXTURE_OPENGL_TEX_H_FLOAT              => 'SDL.texture.opengl.tex_h';
        _const_and_export SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_NUMBER        => 'SDL.texture.opengles2.texture';
        _const_and_export SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_UV_NUMBER     => 'SDL.texture.opengles2.texture_uv';
        _const_and_export SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_U_NUMBER      => 'SDL.texture.opengles2.texture_u';
        _const_and_export SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_V_NUMBER      => 'SDL.texture.opengles2.texture_v';
        _const_and_export SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_TARGET_NUMBER => 'SDL.texture.opengles2.target';
        _const_and_export SDL_PROP_TEXTURE_VULKAN_TEXTURE_NUMBER           => 'SDL.texture.vulkan.texture';
        _const_and_export SDL_PROP_TEXTURE_GPU_TEXTURE_POINTER             => 'SDL.texture.gpu.texture';
        _const_and_export SDL_PROP_TEXTURE_GPU_TEXTURE_UV_POINTER          => 'SDL.texture.gpu.texture_uv';
        _const_and_export SDL_PROP_TEXTURE_GPU_TEXTURE_U_POINTER           => 'SDL.texture.gpu.texture_u';
        _const_and_export SDL_PROP_TEXTURE_GPU_TEXTURE_V_POINTER           => 'SDL.texture.gpu.texture_v';
        _affix_and_export SDL_GetRendererFromTexture => [ Pointer [ SDL_Texture() ] ], Pointer [ SDL_Renderer() ];
        _affix_and_export SDL_GetTextureSize => [ Pointer [ SDL_Texture() ], Pointer [Float], Pointer [Float] ], Bool;

        #~ _affix_and_export SDL_SetTexturePalette       => [ Pointer [ SDL_Texture() ], Pointer [ SDL_Palette() ] ], Bool;
        #~ _affix_and_export SDL_GetTexturePalette       => [ Pointer [ SDL_Texture() ] ], Pointer [ SDL_Palette() ];
        _affix_and_export SDL_SetTextureColorMod      => [ Pointer [ SDL_Texture() ], UInt8, UInt8, UInt8 ], Bool;
        _affix_and_export SDL_SetTextureColorModFloat => [ Pointer [ SDL_Texture() ], Float, Float, Float ], Bool;
        _affix_and_export
            SDL_GetTextureColorMod => [ Pointer [ SDL_Texture() ], Pointer [UInt8], Pointer [UInt8], Pointer [UInt8] ],
            Bool;
        _affix_and_export
            SDL_GetTextureColorModFloat => [ Pointer [ SDL_Texture() ], Pointer [Float], Pointer [Float], Pointer [Float] ],
            Bool;
        _affix_and_export SDL_SetTextureAlphaMod      => [ Pointer [ SDL_Texture() ], UInt8 ], Bool;
        _affix_and_export SDL_SetTextureAlphaModFloat => [ Pointer [ SDL_Texture() ], Float ], Bool;
        _affix_and_export SDL_GetTextureAlphaMod      => [ Pointer [ SDL_Texture() ], Pointer [UInt8] ], Bool;
        _affix_and_export SDL_GetTextureAlphaModFloat => [ Pointer [ SDL_Texture() ], Pointer [Float] ], Bool;
        _affix_and_export SDL_SetTextureBlendMode     => [ Pointer [ SDL_Texture() ], SDL_BlendMode() ], Bool;
        _affix_and_export SDL_GetTextureBlendMode     => [ Pointer [ SDL_Texture() ], Pointer [ SDL_BlendMode() ] ], Bool;
        _affix_and_export SDL_SetTextureScaleMode     => [ Pointer [ SDL_Texture() ], SDL_ScaleMode() ], Bool;
        _affix_and_export SDL_GetTextureScaleMode     => [ Pointer [ SDL_Texture() ], Pointer [ SDL_ScaleMode() ] ], Bool;
        _affix_and_export
            SDL_UpdateTexture => [ Pointer [ SDL_Texture() ], Pointer [ SDL_Rect() ], Pointer [Void], Int ],
            Bool;
        _affix_and_export
            SDL_UpdateYUVTexture =>
            [ Pointer [ SDL_Texture() ], Pointer [ SDL_Rect() ], Pointer [UInt8], Int, Pointer [UInt8], Int, Pointer [UInt8], Int ],
            Bool;
        _affix_and_export
            SDL_UpdateNVTexture => [ Pointer [ SDL_Texture() ], Pointer [ SDL_Rect() ], Pointer [UInt8], Int, Pointer [UInt8], Int ],
            Bool;
        _affix_and_export
            SDL_LockTexture => [ Pointer [ SDL_Texture() ], Pointer [ SDL_Rect() ], Pointer [ Pointer [Void] ], Pointer [Int] ],
            Bool;
        _affix_and_export
            SDL_LockTextureToSurface => [ Pointer [ SDL_Texture() ], Pointer [ SDL_Rect() ], Pointer [ Pointer [ SDL_Surface() ] ] ],
            Bool;
        _affix_and_export SDL_UnlockTexture   => [ Pointer [ SDL_Texture() ] ], Void;
        _affix_and_export SDL_SetRenderTarget => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_Texture() ] ], Bool;
        _affix_and_export SDL_GetRenderTarget => [ Pointer [ SDL_Renderer() ] ], Pointer [ SDL_Texture() ];
        _affix_and_export
            SDL_SetRenderLogicalPresentation => [ Pointer [ SDL_Renderer() ], Int, Int, SDL_RendererLogicalPresentation() ],
            Bool;
        _affix_and_export
            SDL_GetRenderLogicalPresentation =>
            [ Pointer [ SDL_Renderer() ], Pointer [Int], Pointer [Int], Pointer [ SDL_RendererLogicalPresentation() ] ],
            Bool;
        _affix_and_export SDL_GetRenderLogicalPresentationRect => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_FRect() ] ], Bool;
        _affix_and_export
            SDL_RenderCoordinatesFromWindow => [ Pointer [ SDL_Renderer() ], Float, Float, Pointer [Float], Pointer [Float] ],
            Bool;
        _affix_and_export
            SDL_RenderCoordinatesToWindow => [ Pointer [ SDL_Renderer() ], Float, Float, Pointer [Float], Pointer [Float] ],
            Bool;
        _affix_and_export
            SDL_ConvertEventToRenderCoordinates => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_Event() ] ],
            Bool;
        _affix_and_export SDL_SetRenderViewport       => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_Rect() ] ], Bool;
        _affix_and_export SDL_GetRenderViewport       => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_Rect() ] ], Bool;
        _affix_and_export SDL_RenderViewportSet       => [ Pointer [ SDL_Renderer() ] ], Bool;
        _affix_and_export SDL_GetRenderSafeArea       => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_Rect() ] ], Bool;
        _affix_and_export SDL_SetRenderClipRect       => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_Rect() ] ], Bool;
        _affix_and_export SDL_GetRenderClipRect       => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_Rect() ] ], Bool;
        _affix_and_export SDL_RenderClipEnabled       => [ Pointer [ SDL_Renderer() ] ], Bool;
        _affix_and_export SDL_SetRenderScale          => [ Pointer [ SDL_Renderer() ], Float, Float ], Bool;
        _affix_and_export SDL_GetRenderScale          => [ Pointer [ SDL_Renderer() ], Pointer [Float], Pointer [Float] ], Bool;
        _affix_and_export SDL_SetRenderDrawColor      => [ Pointer [ SDL_Renderer() ], UInt8, UInt8, UInt8, UInt8 ], Bool;
        _affix_and_export SDL_SetRenderDrawColorFloat => [ Pointer [ SDL_Renderer() ], Float, Float, Float, Float ], Bool;
        _affix_and_export
            SDL_GetRenderDrawColor => [ Pointer [ SDL_Renderer() ], Pointer [UInt8], Pointer [UInt8], Pointer [UInt8], Pointer [UInt8] ],
            Bool;
        _affix_and_export
            SDL_GetRenderDrawColorFloat => [ Pointer [ SDL_Renderer() ], Pointer [Float], Pointer [Float], Pointer [Float], Pointer [Float] ],
            Bool;
        _affix_and_export SDL_SetRenderColorScale    => [ Pointer [ SDL_Renderer() ], Float ], Bool;
        _affix_and_export SDL_GetRenderColorScale    => [ Pointer [ SDL_Renderer() ], Pointer [Float] ], Bool;
        _affix_and_export SDL_SetRenderDrawBlendMode => [ Pointer [ SDL_Renderer() ], SDL_BlendMode() ], Bool;
        _affix_and_export SDL_GetRenderDrawBlendMode => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_BlendMode() ] ], Bool;
        _affix_and_export SDL_RenderClear            => [ Pointer [ SDL_Renderer() ] ], Bool;
        _affix_and_export SDL_RenderPoint            => [ Pointer [ SDL_Renderer() ], Float, Float ], Bool;
        _affix_and_export SDL_RenderPoints           => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_FPoint() ], Int ], Bool;
        _affix_and_export SDL_RenderLine             => [ Pointer [ SDL_Renderer() ], Float, Float, Float, Float ], Bool;
        _affix_and_export SDL_RenderLines            => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_FPoint() ], Int ], Bool;
        _affix_and_export SDL_RenderRect             => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_FRect() ] ], Bool;
        _affix_and_export SDL_RenderRects            => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_FRect() ], Int ], Bool;
        _affix_and_export SDL_RenderFillRect         => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_FRect() ] ], Bool;
        _affix_and_export SDL_RenderFillRects        => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_FRect() ], Int ], Bool;
        _affix_and_export
            SDL_RenderTexture => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_Texture() ], Pointer [ SDL_FRect() ], Pointer [ SDL_FRect() ] ],
            Bool;
        _affix_and_export
            SDL_RenderTextureRotated => [
            Pointer [ SDL_Renderer() ],
            Pointer [ SDL_Texture() ],
            Pointer [ SDL_FRect() ],
            Pointer [ SDL_FRect() ],
            Double,
            Pointer [ SDL_FPoint() ],
            SDL_FlipMode()
            ],
            Bool;
        _affix_and_export
            SDL_RenderTextureAffine => [
            Pointer [ SDL_Renderer() ],
            Pointer [ SDL_Texture() ],
            Pointer [ SDL_FRect() ],
            Pointer [ SDL_FPoint() ],
            Pointer [ SDL_FPoint() ],
            Pointer [ SDL_FPoint() ]
            ],
            Bool;
        _affix_and_export
            SDL_RenderTextureTiled =>
            [ Pointer [ SDL_Renderer() ], Pointer [ SDL_Texture() ], Pointer [ SDL_FRect() ], Float, Pointer [ SDL_FRect() ] ],
            Bool;
        _affix_and_export
            SDL_RenderTexture9Grid => [
            Pointer [ SDL_Renderer() ],
            Pointer [ SDL_Texture() ],
            Pointer [ SDL_FRect() ],
            Float, Float, Float, Float, Float, Pointer [ SDL_FRect() ]
            ],
            Bool;

        #~ _affix_and_export
        #~ SDL_RenderTexture9GridTiled => [
        #~ Pointer [ SDL_Renderer() ],
        #~ Pointer [ SDL_Texture() ],
        #~ Pointer [ SDL_FRect() ],
        #~ Float, Float, Float, Float, Float, Pointer [ SDL_FRect() ], Float
        #~ ],
        #~ Bool;
        _affix_and_export
            SDL_RenderGeometry => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_Texture() ], Pointer [ SDL_Vertex() ], Int, Pointer [Int], Int ],
            Bool;
        _affix_and_export
            SDL_RenderGeometryRaw => [
            Pointer [ SDL_Renderer() ],
            Pointer [ SDL_Texture() ],
            Pointer [Float],
            Int, Pointer [ SDL_FColor() ],
            Int, Pointer [Float],
            Int, Int, Pointer [Void],
            Int, Int
            ],
            Bool;

        #~ _affix_and_export
        #~ SDL_SetRenderTextureAddressMode => [ Pointer [ SDL_Renderer() ], SDL_TextureAddressMode(), SDL_TextureAddressMode() ],
        #~ Bool;
        #~ _affix_and_export
        #~ SDL_GetRenderTextureAddressMode =>
        #~ [ Pointer [ SDL_Renderer() ], Pointer [ SDL_TextureAddressMode() ], Pointer [ SDL_TextureAddressMode() ] ],
        #~ Bool;
        _affix_and_export SDL_RenderReadPixels             => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_Rect() ] ], Pointer [ SDL_Surface() ];
        _affix_and_export SDL_RenderPresent                => [ Pointer [ SDL_Renderer() ] ], Bool;
        _affix_and_export SDL_DestroyTexture               => [ Pointer [ SDL_Texture() ] ],  Void;
        _affix_and_export SDL_DestroyRenderer              => [ Pointer [ SDL_Renderer() ] ], Void;
        _affix_and_export SDL_FlushRenderer                => [ Pointer [ SDL_Renderer() ] ], Bool;
        _affix_and_export SDL_GetRenderMetalLayer          => [ Pointer [ SDL_Renderer() ] ], Pointer [Void];
        _affix_and_export SDL_GetRenderMetalCommandEncoder => [ Pointer [ SDL_Renderer() ] ], Pointer [Void];
        _affix_and_export SDL_AddVulkanRenderSemaphores    => [ Pointer [ SDL_Renderer() ], UInt32, SInt64, SInt64 ], Bool;
        _affix_and_export SDL_SetRenderVSync               => [ Pointer [ SDL_Renderer() ], Int ], Bool;
        _const_and_export SDL_RENDERER_VSYNC_DISABLED => 0;
        _const_and_export SDL_RENDERER_VSYNC_ADAPTIVE => -1;
        _affix_and_export SDL_GetRenderVSync => [ Pointer [ SDL_Renderer() ], Pointer [Int] ], Bool;
        _const_and_export SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE => 8;
        _affix_and_export SDL_RenderDebugText => [ Pointer [ SDL_Renderer() ], Float, Float, String ], Bool;

        #~ _affix_and_export SDL_RenderDebugTextFormat      => [ Pointer [ SDL_Renderer() ], Float, Float, String, VarArgs ], Bool;
        #~ _affix_and_export SDL_SetDefaultTextureScaleMode => [ Pointer [ SDL_Renderer() ], SDL_ScaleMode() ], Bool;
        #~ _affix_and_export SDL_GetDefaultTextureScaleMode => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_ScaleMode() ] ], Bool;
        _typedef_and_export SDL_GPURenderStateCreateInfo => Struct [
            fragment_shader      => Pointer [ SDL_GPUShader() ],
            num_sampler_bindings => SInt32,
            sampler_bindings     => Pointer [ SDL_GPUTextureSamplerBinding() ],
            num_storage_textures => SInt32,
            storage_textures     => Pointer [ Pointer [ SDL_GPUTexture() ] ],
            num_storage_buffers  => SInt32,
            storage_buffers      => Pointer [ Pointer [ SDL_GPUBuffer() ] ],
            props                => SDL_PropertiesID()
        ];
        _typedef_and_export SDL_GPURenderState => Void;

        #~ _affix_and_export
        #~ SDL_CreateGPURenderState => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_GPURenderStateCreateInfo() ] ],
        #~ Pointer [ SDL_GPURenderState() ];
        #~ _affix_and_export
        #~ SDL_SetGPURenderStateFragmentUniforms => [ Pointer [ SDL_GPURenderState() ], UInt32, Pointer [Void], UInt32 ],
        #~ Bool;
        #~ _affix_and_export SDL_SetGPURenderState => [ Pointer [ SDL_Renderer() ], Pointer [ SDL_GPURenderState() ] ], Bool;
        #~ _affix_and_export SDL_DestroyGPURenderState => [ Pointer [ SDL_GPURenderState() ] ], Void;
    }

=head3 C<:scancode> - Keyboard Scancodes

The SDL keyboard scancode representation.

An SDL scancode is the physical representation of a key on the keyboard, independent of language and keyboard mapping.

See L<SDL3: CategoryScancode|https://wiki.libsdl.org/SDL3/CategoryScancode>

=cut

    sub _scancode() {
        state $done++ && return;
        _enum_and_export SDL_Scancode => [
            [ SDL_SCANCODE_A => 4 ],  [ SDL_SCANCODE_B => 5 ],  [ SDL_SCANCODE_C => 6 ],  [ SDL_SCANCODE_D => 7 ],  [ SDL_SCANCODE_E => 8 ],
            [ SDL_SCANCODE_F => 9 ],  [ SDL_SCANCODE_G => 10 ], [ SDL_SCANCODE_H => 11 ], [ SDL_SCANCODE_I => 12 ], [ SDL_SCANCODE_J => 13 ],
            [ SDL_SCANCODE_K => 14 ], [ SDL_SCANCODE_L => 15 ], [ SDL_SCANCODE_M => 16 ], [ SDL_SCANCODE_N => 17 ], [ SDL_SCANCODE_O => 18 ],
            [ SDL_SCANCODE_P => 19 ], [ SDL_SCANCODE_Q => 20 ], [ SDL_SCANCODE_R => 21 ], [ SDL_SCANCODE_S => 22 ], [ SDL_SCANCODE_T => 23 ],
            [ SDL_SCANCODE_U => 24 ], [ SDL_SCANCODE_V => 25 ], [ SDL_SCANCODE_W => 26 ], [ SDL_SCANCODE_X => 27 ], [ SDL_SCANCODE_Y => 28 ],
            [ SDL_SCANCODE_Z => 29 ],
            #
            [ SDL_SCANCODE_1 => 30 ], [ SDL_SCANCODE_2 => 31 ], [ SDL_SCANCODE_3 => 32 ], [ SDL_SCANCODE_4 => 33 ], [ SDL_SCANCODE_5 => 34 ],
            [ SDL_SCANCODE_6 => 35 ], [ SDL_SCANCODE_7 => 36 ], [ SDL_SCANCODE_8 => 37 ], [ SDL_SCANCODE_9 => 38 ], [ SDL_SCANCODE_0 => 39 ],
            #
            [ SDL_SCANCODE_RETURN => 40 ], [ SDL_SCANCODE_ESCAPE => 41 ], [ SDL_SCANCODE_BACKSPACE => 42 ], [ SDL_SCANCODE_TAB => 43 ],
            [ SDL_SCANCODE_SPACE  => 44 ],
            #
            [ SDL_SCANCODE_MINUS     => 45 ], [ SDL_SCANCODE_EQUALS => 46 ], [ SDL_SCANCODE_LEFTBRACKET => 47 ], [ SDL_SCANCODE_RIGHTBRACKET => 48 ],
            [ SDL_SCANCODE_BACKSLASH => 49 ],    # Located at the lower left of the return key on ISO

            # keyboards and at the right end of the QWERTY row on ANSI keyboards. Produces REVERSE
            # SOLIDUS (backslash) and VERTICAL LINE in a US layout, REVERSE SOLIDUS and VERTICAL
            # LINE in a UK Mac layout, NUMBER SIGN and TILDE in a UK Windows layout, DOLLAR SIGN
            # and POUND SIGN in a Swiss German layout, NUMBER SIGN and APOSTROPHE in a German
            # layout, GRAVE ACCENT and POUND SIGN in a French Mac layout, and ASTERISK and MICRO
            # SIGN in a  French Windows layout.
            [ SDL_SCANCODE_NONUSHASH => 50 ],    # ISO USB keyboards actually use this code instead

            # of 49 for the same key, but all OSes I've seen treat the two codes identically. So,
            # as an implementor, unless your keyboard generates both of those codes and your OS
            # treats them differently, you should generate SDL_SCANCODE_BACKSLASH instead of this
            # code. As a user, you should not rely on this code because SDL will never generate it
            # with most (all?) keyboards.
            [ SDL_SCANCODE_SEMICOLON => 51 ], [ SDL_SCANCODE_APOSTROPHE => 52 ],
            [ SDL_SCANCODE_GRAVE     => 53 ],    # Located in the top left corner (on both ANSI and

            # ISO keyboards). Produces GRAVE ACCENT and TILDE in a US Windows layout and in US and
            # UK Mac layouts on ANSI keyboards, GRAVE ACCENT and NOT SIGN in a UK Windows layout,
            # SECTION SIGN and PLUS-MINUS SIGN in US and UK Mac layouts on ISO keyboards, SECTION
            # SIGN and DEGREE SIGN in a Swiss German layout (Mac: only on ISO keyboards),
            # CIRCUMFLEX ACCENT and DEGREE SIGN in a German layout (Mac: only on ISO keyboards),
            # SUPERSCRIPT TWO and TILDE in a French Windows layout, COMMERCIAL AT and NUMBER SIGN
            # in a French Mac layout on ISO keyboards, and LESS-THAN SIGN and GREATER-THAN SIGN in
            # a Swiss German, German, or French Mac layout on ANSI keyboards.
            [ SDL_SCANCODE_COMMA => 54 ], [ SDL_SCANCODE_PERIOD => 55 ], [ SDL_SCANCODE_SLASH => 56 ],
            #
            [ SDL_SCANCODE_CAPSLOCK => 57 ],
            #
            [ SDL_SCANCODE_F1    => 58 ], [ SDL_SCANCODE_F2 => 59 ], [ SDL_SCANCODE_F3 => 60 ], [ SDL_SCANCODE_F4 => 61 ], [ SDL_SCANCODE_F5  => 62 ],
            [ SDL_SCANCODE_F6    => 63 ], [ SDL_SCANCODE_F7 => 64 ], [ SDL_SCANCODE_F8 => 65 ], [ SDL_SCANCODE_F9 => 66 ], [ SDL_SCANCODE_F10 => 67 ],
            [ SDL_SCANCODE_F11   => 68 ], [ SDL_SCANCODE_F12    => 69 ], [ SDL_SCANCODE_PRINTSCREEN => 70 ], [ SDL_SCANCODE_SCROLLLOCK => 71 ],
            [ SDL_SCANCODE_PAUSE => 72 ], [ SDL_SCANCODE_INSERT => 73 ],   # insert on PC, help on some Mac keyboards (but does send code 73, not 117)
            [ SDL_SCANCODE_HOME      => 74 ], [ SDL_SCANCODE_PAGEUP       => 75 ], [ SDL_SCANCODE_DELETE => 76 ], [ SDL_SCANCODE_END  => 77 ],
            [ SDL_SCANCODE_PAGEDOWN  => 78 ], [ SDL_SCANCODE_RIGHT        => 79 ], [ SDL_SCANCODE_LEFT   => 80 ], [ SDL_SCANCODE_DOWN => 81 ],
            [ SDL_SCANCODE_UP        => 82 ], [ SDL_SCANCODE_NUMLOCKCLEAR => 83 ],    # num lock on PC, clear on Mac keyboards
            [ SDL_SCANCODE_KP_DIVIDE => 84 ], [ SDL_SCANCODE_KP_MULTIPLY  => 85 ], [ SDL_SCANCODE_KP_MINUS => 86 ], [ SDL_SCANCODE_KP_PLUS   => 87 ],
            [ SDL_SCANCODE_KP_ENTER  => 88 ], [ SDL_SCANCODE_KP_1         => 89 ], [ SDL_SCANCODE_KP_2     => 90 ], [ SDL_SCANCODE_KP_3      => 91 ],
            [ SDL_SCANCODE_KP_4      => 92 ], [ SDL_SCANCODE_KP_5         => 93 ], [ SDL_SCANCODE_KP_6     => 94 ], [ SDL_SCANCODE_KP_7      => 95 ],
            [ SDL_SCANCODE_KP_8      => 96 ], [ SDL_SCANCODE_KP_9         => 97 ], [ SDL_SCANCODE_KP_0     => 98 ], [ SDL_SCANCODE_KP_PERIOD => 99 ],
            [ SDL_SCANCODE_NONUSBACKSLASH => 100 ],                                   # This is the additional key that ISO keyboards

            # have over ANSI ones, located between left shift and Z. Produces GRAVE ACCENT and
            # TILDE in a US or UK Mac layout, REVERSE SOLIDUS (backslash) and VERTICAL LINE in a US
            # or UK Windows layout, and LESS-THAN SIGN and GREATER-THAN SIGN in a Swiss German,
            # German, or French layout.
            [ SDL_SCANCODE_APPLICATION => 101 ],    # windows contextual menu, compose
            [ SDL_SCANCODE_POWER       => 102 ],    # The USB document says this is a status flag,

            # not a physical key - but some Mac keyboards
            # do have a power key.
            [ SDL_SCANCODE_KP_EQUALS => 103 ], [ SDL_SCANCODE_F13     => 104 ], [ SDL_SCANCODE_F14  => 105 ], [ SDL_SCANCODE_F15 => 106 ],
            [ SDL_SCANCODE_F16       => 107 ], [ SDL_SCANCODE_F17     => 108 ], [ SDL_SCANCODE_F18  => 109 ], [ SDL_SCANCODE_F19 => 110 ],
            [ SDL_SCANCODE_F20       => 111 ], [ SDL_SCANCODE_F21     => 112 ], [ SDL_SCANCODE_F22  => 113 ], [ SDL_SCANCODE_F23 => 114 ],
            [ SDL_SCANCODE_F24       => 115 ], [ SDL_SCANCODE_EXECUTE => 116 ], [ SDL_SCANCODE_HELP => 117 ],    # AL Integrated Help Center
            [ SDL_SCANCODE_MENU      => 118 ],                                                                   # Menu (show menu)
            [ SDL_SCANCODE_SELECT    => 119 ], [ SDL_SCANCODE_STOP => 120 ],                                     # AC Stop
            [ SDL_SCANCODE_AGAIN     => 121 ],                                                                   # AC Redo/Repeat
            [ SDL_SCANCODE_UNDO      => 122 ],                                                                   # AC Undo
            [ SDL_SCANCODE_CUT       => 123 ],                                                                   # AC Cut
            [ SDL_SCANCODE_COPY      => 124 ],                                                                   # AC Copy
            [ SDL_SCANCODE_PASTE     => 125 ],                                                                   # AC Paste
            [ SDL_SCANCODE_FIND      => 126 ],                                                                   # AC Find
            [ SDL_SCANCODE_MUTE      => 127 ], [ SDL_SCANCODE_VOLUMEUP => 128 ], [ SDL_SCANCODE_VOLUMEDOWN => 129 ],

            # not sure whether there's a reason to enable these
            #     [SDL_SCANCODE_LOCKINGCAPSLOCK => 130],
            #     [SDL_SCANCODE_LOCKINGNUMLOCK => 131],
            #     [SDL_SCANCODE_LOCKINGSCROLLLOCK => 132],
            [ SDL_SCANCODE_KP_COMMA => 133 ], [ SDL_SCANCODE_KP_EQUALSAS400 => 134 ],
            #
            [ SDL_SCANCODE_INTERNATIONAL1 => 135 ],                                            # used on Asian keyboards, see footnotes in USB doc
            [ SDL_SCANCODE_INTERNATIONAL2 => 136 ], [ SDL_SCANCODE_INTERNATIONAL3 => 137 ],    # Yen
            [ SDL_SCANCODE_INTERNATIONAL4 => 138 ], [ SDL_SCANCODE_INTERNATIONAL5 => 139 ], [ SDL_SCANCODE_INTERNATIONAL6 => 140 ],
            [ SDL_SCANCODE_INTERNATIONAL7 => 141 ], [ SDL_SCANCODE_INTERNATIONAL8 => 142 ], [ SDL_SCANCODE_INTERNATIONAL9 => 143 ],
            [ SDL_SCANCODE_LANG1          => 144 ],                                            # Hangul/English toggle
            [ SDL_SCANCODE_LANG2          => 145 ],                                            # Hanja conversion
            [ SDL_SCANCODE_LANG3          => 146 ],                                            # Katakana
            [ SDL_SCANCODE_LANG4          => 147 ],                                            # Hiragana
            [ SDL_SCANCODE_LANG5          => 148 ],                                            # Zenkaku/Hankaku
            [ SDL_SCANCODE_LANG6          => 149 ],                                            # reserved
            [ SDL_SCANCODE_LANG7          => 150 ],                                            # reserved
            [ SDL_SCANCODE_LANG8          => 151 ],                                            # reserved
            [ SDL_SCANCODE_LANG9          => 152 ],                                            # reserved

            #
            [ SDL_SCANCODE_ALTERASE => 153 ],                                                  # Erase-Eaze
            [ SDL_SCANCODE_SYSREQ   => 154 ], [ SDL_SCANCODE_CANCEL => 155 ],                  # AC Cancel
            [ SDL_SCANCODE_CLEAR    => 156 ], [ SDL_SCANCODE_PRIOR  => 157 ], [ SDL_SCANCODE_RETURN2    => 158 ], [ SDL_SCANCODE_SEPARATOR => 159 ],
            [ SDL_SCANCODE_OUT      => 160 ], [ SDL_SCANCODE_OPER   => 161 ], [ SDL_SCANCODE_CLEARAGAIN => 162 ], [ SDL_SCANCODE_CRSEL     => 163 ],
            [ SDL_SCANCODE_EXSEL    => 164 ],
            #
            [ SDL_SCANCODE_KP_00             => 176 ], [ SDL_SCANCODE_KP_000        => 177 ], [ SDL_SCANCODE_THOUSANDSSEPARATOR => 178 ],
            [ SDL_SCANCODE_DECIMALSEPARATOR  => 179 ], [ SDL_SCANCODE_CURRENCYUNIT  => 180 ], [ SDL_SCANCODE_CURRENCYSUBUNIT    => 181 ],
            [ SDL_SCANCODE_KP_LEFTPAREN      => 182 ], [ SDL_SCANCODE_KP_RIGHTPAREN => 183 ], [ SDL_SCANCODE_KP_LEFTBRACE       => 184 ],
            [ SDL_SCANCODE_KP_RIGHTBRACE     => 185 ], [ SDL_SCANCODE_KP_TAB        => 186 ], [ SDL_SCANCODE_KP_BACKSPACE       => 187 ],
            [ SDL_SCANCODE_KP_A              => 188 ], [ SDL_SCANCODE_KP_B => 189 ], [ SDL_SCANCODE_KP_C   => 190 ], [ SDL_SCANCODE_KP_D     => 191 ],
            [ SDL_SCANCODE_KP_E              => 192 ], [ SDL_SCANCODE_KP_F => 193 ], [ SDL_SCANCODE_KP_XOR => 194 ], [ SDL_SCANCODE_KP_POWER => 195 ],
            [ SDL_SCANCODE_KP_PERCENT        => 196 ], [ SDL_SCANCODE_KP_LESS         => 197 ], [ SDL_SCANCODE_KP_GREATER     => 198 ],
            [ SDL_SCANCODE_KP_AMPERSAND      => 199 ], [ SDL_SCANCODE_KP_DBLAMPERSAND => 200 ], [ SDL_SCANCODE_KP_VERTICALBAR => 201 ],
            [ SDL_SCANCODE_KP_DBLVERTICALBAR => 202 ], [ SDL_SCANCODE_KP_COLON        => 203 ], [ SDL_SCANCODE_KP_HASH        => 204 ],
            [ SDL_SCANCODE_KP_SPACE => 205 ], [ SDL_SCANCODE_KP_AT => 206 ], [ SDL_SCANCODE_KP_EXCLAM => 207 ], [ SDL_SCANCODE_KP_MEMSTORE => 208 ],
            [ SDL_SCANCODE_KP_MEMRECALL   => 209 ], [ SDL_SCANCODE_KP_MEMCLEAR    => 210 ], [ SDL_SCANCODE_KP_MEMADD     => 211 ],
            [ SDL_SCANCODE_KP_MEMSUBTRACT => 212 ], [ SDL_SCANCODE_KP_MEMMULTIPLY => 213 ], [ SDL_SCANCODE_KP_MEMDIVIDE  => 214 ],
            [ SDL_SCANCODE_KP_PLUSMINUS   => 215 ], [ SDL_SCANCODE_KP_CLEAR       => 216 ], [ SDL_SCANCODE_KP_CLEARENTRY => 217 ],
            [ SDL_SCANCODE_KP_BINARY      => 218 ], [ SDL_SCANCODE_KP_OCTAL       => 219 ], [ SDL_SCANCODE_KP_DECIMAL    => 220 ],
            [ SDL_SCANCODE_KP_HEXADECIMAL => 221 ],
            #
            [ SDL_SCANCODE_LCTRL => 224 ], [ SDL_SCANCODE_LSHIFT => 225 ], [ SDL_SCANCODE_LALT => 226 ],    # alt, option
            [ SDL_SCANCODE_LGUI  => 227 ],                                                                  # windows, command (apple), meta
            [ SDL_SCANCODE_RCTRL => 228 ], [ SDL_SCANCODE_RSHIFT => 229 ], [ SDL_SCANCODE_RALT => 230 ],    # alt gr, option
            [ SDL_SCANCODE_RGUI  => 231 ],                                                                  # windows, command (apple), meta

            #
            [ SDL_SCANCODE_MODE => 257 ],    # I'm not sure if this is really not covered by any of

            # the above, but since there's a special SDL_KMOD_MODE for it I'm adding it here
            #
            # These values are mapped from usage page 0x0C (USB consumer page).
            #
            # There are way more keys in the spec than we can represent in the current scancode
            # range, so pick the ones that commonly come up in real world usage.
            [ SDL_SCANCODE_SLEEP                => 258 ],    # Sleep
            [ SDL_SCANCODE_WAKE                 => 259 ],    # Wake
            [ SDL_SCANCODE_CHANNEL_INCREMENT    => 260 ],    # Channel Increment
            [ SDL_SCANCODE_CHANNEL_DECREMENT    => 261 ],    # Channel Decrement
            [ SDL_SCANCODE_MEDIA_PLAY           => 262 ],    # Play
            [ SDL_SCANCODE_MEDIA_PAUSE          => 263 ],    # Pause
            [ SDL_SCANCODE_MEDIA_RECORD         => 264 ],    # Record
            [ SDL_SCANCODE_MEDIA_FAST_FORWARD   => 265 ],    # Fast Forward
            [ SDL_SCANCODE_MEDIA_REWIND         => 266 ],    # Rewind
            [ SDL_SCANCODE_MEDIA_NEXT_TRACK     => 267 ],    # Next Track
            [ SDL_SCANCODE_MEDIA_PREVIOUS_TRACK => 268 ],    # Previous Track
            [ SDL_SCANCODE_MEDIA_STOP           => 269 ],    # Stop
            [ SDL_SCANCODE_MEDIA_EJECT          => 270 ],    # Eject
            [ SDL_SCANCODE_MEDIA_PLAY_PAUSE     => 271 ],    # Play / Pause
            [ SDL_SCANCODE_MEDIA_SELECT         => 272 ],    # Media Select
            [ SDL_SCANCODE_AC_NEW               => 273 ],    # AC New
            [ SDL_SCANCODE_AC_OPEN              => 274 ],    # AC Open
            [ SDL_SCANCODE_AC_CLOSE             => 275 ],    # AC Close
            [ SDL_SCANCODE_AC_EXIT              => 276 ],    # AC Exit
            [ SDL_SCANCODE_AC_SAVE              => 277 ],    # AC Save
            [ SDL_SCANCODE_AC_PRINT             => 278 ],    # AC Print
            [ SDL_SCANCODE_AC_PROPERTIES        => 279 ],    # AC Properties
            [ SDL_SCANCODE_AC_SEARCH            => 280 ],    # AC Search
            [ SDL_SCANCODE_AC_HOME              => 281 ],    # AC Home
            [ SDL_SCANCODE_AC_BACK              => 282 ],    # AC Back
            [ SDL_SCANCODE_AC_FORWARD           => 283 ],    # AC Forward
            [ SDL_SCANCODE_AC_STOP              => 284 ],    # AC Stop
            [ SDL_SCANCODE_AC_REFRESH           => 285 ],    # AC Refresh
            [ SDL_SCANCODE_AC_BOOKMARKS         => 286 ],    # AC Bookmarks

            # These are values that are often used on mobile phones.
            [ SDL_SCANCODE_SOFTLEFT => 287 ],                # Usually situated below the display on phones and

            #  used as a multi-function feature key for selecting
            #  a software defined function shown on the bottom left
            #  of the display.
            [ SDL_SCANCODE_SOFTRIGHT => 288 ],    # Usually situated below the display on phones and

            #  used as a multi-function feature key for selecting
            #  a software defined function shown on the bottom right
            #  of the display.
            [ SDL_SCANCODE_CALL    => 289 ],    # Used for accepting phone calls.
            [ SDL_SCANCODE_ENDCALL => 290 ],    # Used for rejecting phone calls.

            # Add any other keys here.
            [ SDL_SCANCODE_RESERVED => 400 ],    # 400-500 reserved for dynamic keycodes
            [ SDL_SCANCODE_COUNT    => 512 ]     # not a key, just marks the number of scancodes for array bounds
        ];
    }

=head3 C<:sensor> - Sensors

SDL sensor management.

These APIs grant access to gyros and accelerometers on various platforms.

See L<SDL3: CategorySensor|https://wiki.libsdl.org/SDL3/CategorySensor>

=cut

    sub _sensor() {
        state $done++ && return;
        _error();
        _properties();
        _stdinc();
        #
        _typedef_and_export SDL_Sensor   => Void;
        _typedef_and_export SDL_SensorID => UInt32;
        _const_and_export SDL_STANDARD_GRAVITY => 9.80665;
        _enum_and_export SDL_SensorType => [
            [ SDL_SENSOR_INVALID => -1 ], 'SDL_SENSOR_UNKNOWN', 'SDL_SENSOR_ACCEL',   'SDL_SENSOR_GYRO',
            'SDL_SENSOR_ACCEL_L',         'SDL_SENSOR_GYRO_L',  'SDL_SENSOR_ACCEL_R', 'SDL_SENSOR_GYRO_R',
            'SDL_SENSOR_COUNT'
        ];
        _affix_and_export SDL_GetSensors                    => [ Pointer [Int] ], Pointer [ SDL_SensorID() ];
        _affix_and_export SDL_GetSensorNameForID            => [ SDL_SensorID() ], String;
        _affix_and_export SDL_GetSensorTypeForID            => [ SDL_SensorID() ], SDL_SensorType();
        _affix_and_export SDL_GetSensorNonPortableTypeForID => [ SDL_SensorID() ], Int;
        _affix_and_export SDL_OpenSensor                    => [ SDL_SensorID() ], Pointer [ SDL_Sensor() ];
        _affix_and_export SDL_GetSensorFromID               => [ SDL_SensorID() ], Pointer [ SDL_Sensor() ];
        _affix_and_export SDL_GetSensorProperties           => [ Pointer [ SDL_Sensor() ] ], SDL_PropertiesID();
        _affix_and_export SDL_GetSensorName                 => [ Pointer [ SDL_Sensor() ] ], String;
        _affix_and_export SDL_GetSensorType                 => [ Pointer [ SDL_Sensor() ] ], SDL_SensorType();
        _affix_and_export SDL_GetSensorNonPortableType      => [ Pointer [ SDL_Sensor() ] ], Int;
        _affix_and_export SDL_GetSensorID                   => [ Pointer [ SDL_Sensor() ] ], SDL_SensorID();
        _affix_and_export SDL_GetSensorData                 => [ Pointer [ SDL_Sensor() ], Pointer [Float], Int ], Bool;
        _affix_and_export SDL_CloseSensor                   => [ Pointer [ SDL_Sensor() ] ], Void;
        _affix_and_export SDL_UpdateSensors                 => [], Void;
    }

=head3 C<:storage> - Storage Abstraction

The storage API is a high-level API designed to abstract away the portability issues that come up when using something
lower-level.

See L<SDL3: CategoryStorage|https://wiki.libsdl.org/SDL3/CategoryStorage>

=cut

    sub _storage() {
        state $done++ && return;
        _error();
        _filesystem();
        _properties();
        _stdinc();
        #
        _typedef_and_export SDL_Storage => Void;
        _typedef_and_export SDL_StorageInterface => Struct [
            version         => UInt32,
            close           => Callback [ [ Pointer [Void] ]                                                           => Bool ],
            ready           => Callback [ [ Pointer [Void] ]                                                           => Bool ],
            enumerate       => Callback [ [ Pointer [Void], String, SDL_EnumerateDirectoryCallback(), Pointer [Void] ] => Bool ],
            info            => Callback [ [ Pointer [Void], String, Pointer [ SDL_PathInfo() ] ]                       => Bool ],
            read_file       => Callback [ [ Pointer [Void], String, Pointer [Void], UInt64 ]                           => Bool ],
            write_file      => Callback [ [ Pointer [Void], String, Pointer [Void], UInt64 ]                           => Bool ],
            mkdir           => Callback [ [ Pointer [Void], String ]                                                   => Bool ],
            remove          => Callback [ [ Pointer [Void], String ]                                                   => Bool ],
            rename          => Callback [ [ Pointer [Void], String, String ]                                           => Bool ],
            copy            => Callback [ [ Pointer [Void], String, String ]                                           => Bool ],
            space_remaining => Callback [ [ Pointer [Void] ]                                                           => UInt64 ]
        ];
        _affix_and_export SDL_OpenTitleStorage       => [ String, SDL_PropertiesID() ], Pointer [ SDL_Storage() ];
        _affix_and_export SDL_OpenUserStorage        => [ String, String, SDL_PropertiesID() ], Pointer [ SDL_Storage() ];
        _affix_and_export SDL_OpenFileStorage        => [String], Pointer [ SDL_Storage() ];
        _affix_and_export SDL_OpenStorage            => [ Pointer [ SDL_StorageInterface() ], Pointer [Void] ], Pointer [ SDL_Storage() ];
        _affix_and_export SDL_CloseStorage           => [ Pointer [ SDL_Storage() ] ], Bool;
        _affix_and_export SDL_StorageReady           => [ Pointer [ SDL_Storage() ] ], Bool;
        _affix_and_export SDL_GetStorageFileSize     => [ Pointer [ SDL_Storage() ], String, Pointer [UInt64] ], Bool;
        _affix_and_export SDL_ReadStorageFile        => [ Pointer [ SDL_Storage() ], String, Pointer [Void], UInt64 ], Bool;
        _affix_and_export SDL_WriteStorageFile       => [ Pointer [ SDL_Storage() ], String, Pointer [Void], UInt64 ], Bool;
        _affix_and_export SDL_CreateStorageDirectory => [ Pointer [ SDL_Storage() ], String ], Bool;
        _affix_and_export
            SDL_EnumerateStorageDirectory => [ Pointer [ SDL_Storage() ], String, SDL_EnumerateDirectoryCallback(), Pointer [Void] ],
            Bool;
        _affix_and_export SDL_RemoveStoragePath        => [ Pointer [ SDL_Storage() ], String ], Bool;
        _affix_and_export SDL_RenameStoragePath        => [ Pointer [ SDL_Storage() ], String, String ], Bool;
        _affix_and_export SDL_CopyStorageFile          => [ Pointer [ SDL_Storage() ], String, String ], Bool;
        _affix_and_export SDL_GetStoragePathInfo       => [ Pointer [ SDL_Storage() ], String, Pointer [ SDL_PathInfo() ] ], Bool;
        _affix_and_export SDL_GetStorageSpaceRemaining => [ Pointer [ SDL_Storage() ] ], UInt64;
        _affix_and_export
            SDL_GlobStorageDirectory => [ Pointer [ SDL_Storage() ], String, String, SDL_GlobFlags(), Pointer [Int] ],
            Pointer [String];
    }

=head3 C<:surface> - Surface Creation and Simple Drawing

SDL surfaces are buffers of pixels in system RAM. These are useful for passing around and manipulating images that are
not stored in GPU memory.

See L<SDL3: CategorySurface|https://wiki.libsdl.org/SDL3/CategorySurface>

=cut

    sub _surface() {
        state $done++ && return;
        _blendmode();
        _error();
        _iostream();
        _pixels();
        _properties();
        _rect();
        _stdinc();
        #
        _typedef_and_export SDL_SurfaceFlags => UInt32;
        _const_and_export SDL_SURFACE_PREALLOCATED => 0x00000001;
        _const_and_export SDL_SURFACE_LOCK_NEEDED  => 0x00000002;
        _const_and_export SDL_SURFACE_LOCKED       => 0x00000004;
        _const_and_export SDL_SURFACE_SIMD_ALIGNED => 0x00000008;
        _func_and_export( SDL_MUSTLOCK => sub ($S) { ( ( ($S)->flags & SDL_SURFACE_LOCK_NEEDED() ) == SDL_SURFACE_LOCK_NEEDED() ) } );
        _enum_and_export SDL_ScaleMode =>
            [ [ SDL_SCALEMODE_INVALID => -1 ], 'SDL_SCALEMODE_NEAREST', 'SDL_SCALEMODE_LINEAR', 'SDL_SCALEMODE_PIXELART' ];
        _enum_and_export SDL_FlipMode => [
            'SDL_FLIP_NONE',     'SDL_FLIP_HORIZONTAL',
            'SDL_FLIP_VERTICAL', [ SDL_FLIP_HORIZONTAL_AND_VERTICAL => ('SDL_FLIP_HORIZONTAL | SDL_FLIP_VERTICAL') ]
        ];
        _typedef_and_export SDL_Surface => Struct [
            flags    => SDL_SurfaceFlags(),
            format   => SDL_PixelFormat(),
            w        => Int,
            h        => Int,
            pitch    => Int,
            pixels   => Pointer [Void],
            refcount => Int,
            reserved => Pointer [Void]
        ];
        _affix_and_export SDL_CreateSurface        => [ Int, Int, SDL_PixelFormat() ], Pointer [ SDL_Surface() ];
        _affix_and_export SDL_CreateSurfaceFrom    => [ Int, Int, SDL_PixelFormat(), Pointer [Void], Int ], Pointer [ SDL_Surface() ];
        _affix_and_export SDL_DestroySurface       => [ Pointer [ SDL_Surface() ] ], Void;
        _affix_and_export SDL_GetSurfaceProperties => [ Pointer [ SDL_Surface() ] ], SDL_PropertiesID();
        _const_and_export SDL_PROP_SURFACE_SDR_WHITE_POINT_FLOAT   => 'SDL.surface.SDR_white_point';
        _const_and_export SDL_PROP_SURFACE_HDR_HEADROOM_FLOAT      => 'SDL.surface.HDR_headroom';
        _const_and_export SDL_PROP_SURFACE_TONEMAP_OPERATOR_STRING => 'SDL.surface.tonemap';
        _const_and_export SDL_PROP_SURFACE_HOTSPOT_X_NUMBER        => 'SDL.surface.hotspot.x';
        _const_and_export SDL_PROP_SURFACE_HOTSPOT_Y_NUMBER        => 'SDL.surface.hotspot.y';
        _affix_and_export SDL_SetSurfaceColorspace         => [ Pointer [ SDL_Surface() ], SDL_Colorspace() ], Bool;
        _affix_and_export SDL_GetSurfaceColorspace         => [ Pointer [ SDL_Surface() ] ], SDL_Colorspace();
        _affix_and_export SDL_CreateSurfacePalette         => [ Pointer [ SDL_Surface() ] ], Pointer [ SDL_Palette() ];
        _affix_and_export SDL_SetSurfacePalette            => [ Pointer [ SDL_Surface() ], Pointer [ SDL_Palette() ] ], Bool;
        _affix_and_export SDL_GetSurfacePalette            => [ Pointer [ SDL_Surface() ] ], Pointer [ SDL_Palette() ];
        _affix_and_export SDL_AddSurfaceAlternateImage     => [ Pointer [ SDL_Surface() ], Pointer [ SDL_Surface() ] ], Bool;
        _affix_and_export SDL_SurfaceHasAlternateImages    => [ Pointer [ SDL_Surface() ] ], Bool;
        _affix_and_export SDL_GetSurfaceImages             => [ Pointer [ SDL_Surface() ], Pointer [Int] ], Pointer [ Pointer [ SDL_Surface() ] ];
        _affix_and_export SDL_RemoveSurfaceAlternateImages => [ Pointer [ SDL_Surface() ] ], Void;
        _affix_and_export SDL_LockSurface                  => [ Pointer [ SDL_Surface() ] ], Bool;
        _affix_and_export SDL_UnlockSurface                => [ Pointer [ SDL_Surface() ] ], Void;

        #~ _affix_and_export SDL_LoadSurface_IO               => [ Pointer [ SDL_IOStream() ], Bool ], Pointer [ SDL_Surface() ];
        #_affix_and_export SDL_LoadSurface                  => [String], Pointer [ SDL_Surface() ];
        #~ _affix_and_export SDL_LoadBMP_IO                   => [ Pointer [ SDL_IOStream() ], Bool ], Pointer [ SDL_Surface() ];
        #~ _affix_and_export SDL_LoadBMP                      => [String], Pointer [ SDL_Surface() ];
        #~ _affix_and_export SDL_SaveBMP_IO                   => [ Pointer [ SDL_Surface() ], Pointer [ SDL_IOStream() ], Bool ], Bool;
        #~ _affix_and_export SDL_SaveBMP                      => [ Pointer [ SDL_Surface() ], String ], Bool;
        #~ _affix_and_export SDL_LoadPNG_IO                   => [ Pointer [ SDL_IOStream() ], Bool ],  Pointer [ SDL_Surface() ];
        #~ _affix_and_export SDL_LoadPNG                      => [String], Pointer [ SDL_Surface() ]
        #~ _affix_and_export SDL_SavePNG_IO                   => [ Pointer [ SDL_Surface() ], Pointer [ SDL_IOStream() ], Bool ], Bool;
        #~ _affix_and_export SDL_SavePNG                      => [ Pointer [ SDL_Surface() ], String ], Bool;
        _affix_and_export SDL_SetSurfaceRLE      => [ Pointer [ SDL_Surface() ], Bool ], Bool;
        _affix_and_export SDL_SurfaceHasRLE      => [ Pointer [ SDL_Surface() ] ], Bool;
        _affix_and_export SDL_SetSurfaceColorKey => [ Pointer [ SDL_Surface() ], Bool, UInt32 ], Bool;
        _affix_and_export SDL_SurfaceHasColorKey => [ Pointer [ SDL_Surface() ] ], Bool;
        _affix_and_export SDL_GetSurfaceColorKey => [ Pointer [ SDL_Surface() ], Pointer [UInt32] ], Bool;
        _affix_and_export SDL_SetSurfaceColorMod => [ Pointer [ SDL_Surface() ], UInt8, UInt8, UInt8 ], Bool;
        _affix_and_export
            SDL_GetSurfaceColorMod => [ Pointer [ SDL_Surface() ], Pointer [UInt8], Pointer [UInt8], Pointer [UInt8] ],
            Bool;
        _affix_and_export SDL_SetSurfaceAlphaMod  => [ Pointer [ SDL_Surface() ], UInt8 ], Bool;
        _affix_and_export SDL_GetSurfaceAlphaMod  => [ Pointer [ SDL_Surface() ], Pointer [UInt8] ], Bool;
        _affix_and_export SDL_SetSurfaceBlendMode => [ Pointer [ SDL_Surface() ], SDL_BlendMode() ], Bool;
        _affix_and_export SDL_GetSurfaceBlendMode => [ Pointer [ SDL_Surface() ], Pointer [ SDL_BlendMode() ] ], Bool;
        _affix_and_export SDL_SetSurfaceClipRect  => [ Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ] ],      Bool;
        _affix_and_export SDL_GetSurfaceClipRect  => [ Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ] ],      Bool;
        _affix_and_export SDL_FlipSurface         => [ Pointer [ SDL_Surface() ], SDL_FlipMode() ], Bool;

        #~ _affix_and_export SDL_RotateSurface       => [ Pointer [ SDL_Surface() ], Float ], Pointer [ SDL_Surface() ];
        _affix_and_export SDL_DuplicateSurface => [ Pointer [ SDL_Surface() ] ], Pointer [ SDL_Surface() ];
        _affix_and_export SDL_ScaleSurface     => [ Pointer [ SDL_Surface() ], Int, Int, SDL_ScaleMode() ], Pointer [ SDL_Surface() ];
        _affix_and_export SDL_ConvertSurface   => [ Pointer [ SDL_Surface() ], SDL_PixelFormat() ], Pointer [ SDL_Surface() ];
        _affix_and_export
            SDL_ConvertSurfaceAndColorspace =>
            [ Pointer [ SDL_Surface() ], SDL_PixelFormat(), Pointer [ SDL_Palette() ], SDL_Colorspace(), SDL_PropertiesID() ],
            Pointer [ SDL_Surface() ];
        _affix_and_export
            SDL_ConvertPixels => [ Int, Int, SDL_PixelFormat(), Pointer [Void], Int, SDL_PixelFormat(), Pointer [Void], Int ],
            Bool;
        _affix_and_export
            SDL_ConvertPixelsAndColorspace => [
            Int, Int,               SDL_PixelFormat(), SDL_Colorspace(),   SDL_PropertiesID(), Pointer [Void],
            Int, SDL_PixelFormat(), SDL_Colorspace(),  SDL_PropertiesID(), Pointer [Void],     Int
            ],
            Bool;
        _affix_and_export
            SDL_PremultiplyAlpha => [ Int, Int, SDL_PixelFormat(), Pointer [Void], Int, SDL_PixelFormat(), Pointer [Void], Int, Bool ],
            Bool;
        _affix_and_export SDL_PremultiplySurfaceAlpha => [ Pointer [ SDL_Surface() ], Bool ], Bool;
        _affix_and_export SDL_ClearSurface            => [ Pointer [ SDL_Surface() ], Float, Float, Float, Float ], Bool;
        _affix_and_export SDL_FillSurfaceRect         => [ Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ], UInt32 ], Bool;
        _affix_and_export SDL_FillSurfaceRects        => [ Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ], Int, UInt32 ], Bool;
        _affix_and_export
            SDL_BlitSurface => [ Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ], Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ] ],
            Bool;
        _affix_and_export
            SDL_BlitSurfaceUnchecked => [ Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ], Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ] ],
            Bool;
        _affix_and_export
            SDL_BlitSurfaceScaled =>
            [ Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ], Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ], SDL_ScaleMode() ],
            Bool;
        _affix_and_export
            SDL_BlitSurfaceUncheckedScaled =>
            [ Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ], Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ], SDL_ScaleMode() ],
            Bool;
        _affix_and_export
            SDL_StretchSurface =>
            [ Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ], Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ], SDL_ScaleMode() ],
            Bool;
        _affix_and_export
            SDL_BlitSurfaceTiled => [ Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ], Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ] ],
            Bool;
        _affix_and_export
            SDL_BlitSurfaceTiledWithScale =>
            [ Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ], Float, SDL_ScaleMode(), Pointer [ SDL_Surface() ], Pointer [ SDL_Rect() ] ],
            Bool;
        _affix_and_export
            SDL_BlitSurface9Grid => [
            Pointer [ SDL_Surface() ],
            Pointer [ SDL_Rect() ],
            Int, Int, Int, Int, Float, SDL_ScaleMode(),
            Pointer [ SDL_Surface() ],
            Pointer [ SDL_Rect() ]
            ],
            Bool;
        _affix_and_export SDL_MapSurfaceRGB => [ Pointer [ SDL_Surface() ], UInt8, UInt8, UInt8 ], UInt32;
        _affix_and_export SDL_MapSurfaceRGBA => [ Pointer [ SDL_Surface() ], UInt8, UInt8, UInt8, UInt8 ], UInt32;
        _affix_and_export
            SDL_ReadSurfacePixel => [ Pointer [ SDL_Surface() ], Int, Int, Pointer [UInt8], Pointer [UInt8], Pointer [UInt8], Pointer [UInt8] ],
            Bool;
        _affix_and_export
            SDL_ReadSurfacePixelFloat => [ Pointer [ SDL_Surface() ], Int, Int, Pointer [Float], Pointer [Float], Pointer [Float], Pointer [Float] ],
            Bool;
        _affix_and_export SDL_WriteSurfacePixel      => [ Pointer [ SDL_Surface() ], Int, Int, UInt8, UInt8, UInt8, UInt8 ], Bool;
        _affix_and_export SDL_WriteSurfacePixelFloat => [ Pointer [ SDL_Surface() ], Int, Int, Float, Float, Float, Float ], Bool;
    }

=head3 C<:stdinc> - Standard Library Functionality

SDL provides its own implementation of some of the most important C runtime functions. Using these functions allows an
app to have access to common C functionality without depending on a specific C runtime (or a C runtime at all).

See L<SDL3: CategoryStdinc|https://wiki.libsdl.org/SDL3/CategoryStdinc>

=cut

    sub _stdinc() {
        state $done++ && return;
        _error();
        #
        _affix_and_export SDL_malloc  => [Size_t], Pointer [Void];
        _affix_and_export SDL_calloc  => [ Size_t, Size_t ], Pointer [Void];
        _affix_and_export SDL_realloc => [ Pointer [Void], Size_t ], Pointer [Void];
        _affix_and_export SDL_free    => [ Pointer [Void] ], Void;
        _typedef_and_export SDL_malloc_func  => Callback [ [Size_t]                   => Pointer [Void] ];
        _typedef_and_export SDL_calloc_func  => Callback [ [ Size_t, Size_t ]         => Pointer [Void] ];
        _typedef_and_export SDL_realloc_func => Callback [ [ Pointer [Void], Size_t ] => Pointer [Void] ];
        _typedef_and_export SDL_free_func    => Callback [ [ Pointer [Void] ]         => Void ];
        _affix_and_export
            SDL_GetOriginalMemoryFunctions =>
            [ Pointer [ SDL_malloc_func() ], Pointer [ SDL_calloc_func() ], Pointer [ SDL_realloc_func() ], Pointer [ SDL_free_func() ] ],
            Void;
        _affix_and_export
            SDL_GetMemoryFunctions =>
            [ Pointer [ SDL_malloc_func() ], Pointer [ SDL_calloc_func() ], Pointer [ SDL_realloc_func() ], Pointer [ SDL_free_func() ] ],
            Void;
        _affix_and_export
            SDL_SetMemoryFunctions =>
            [ Pointer [ SDL_malloc_func() ], Pointer [ SDL_calloc_func() ], Pointer [ SDL_realloc_func() ], Pointer [ SDL_free_func() ] ],
            Void;
        _affix_and_export SDL_aligned_alloc     => [ Size_t, Size_t ], Pointer [Void];
        _affix_and_export SDL_aligned_free      => [ Pointer [Void] ], Void;
        _affix_and_export SDL_GetNumAllocations => [], Int;
        _typedef_and_export SDL_Environment => Pointer [Void];
        _affix_and_export SDL_GetEnvironment => [], SDL_Environment();
        _affix_and_export
            SDL_CreateEnvironment => [Bool],
            SDL_Environment();
        _affix_and_export SDL_GetEnvironmentVariable   => [ SDL_Environment(), String ], String;
        _affix_and_export SDL_GetEnvironmentVariables  => [ SDL_Environment() ], Pointer [String];
        _affix_and_export SDL_SetEnvironmentVariable   => [ SDL_Environment(), String, String, Bool ], Bool;
        _affix_and_export SDL_UnsetEnvironmentVariable => [ SDL_Environment(), String ], Bool;
        _affix_and_export SDL_DestroyEnvironment       => [ SDL_Environment() ], Void;
        _affix_and_export SDL_getenv                   => [String], String;
        _affix_and_export SDL_getenv_unsafe            => [String], String;
        _affix_and_export SDL_setenv_unsafe            => [ String, String, Int ], Int;
        _affix_and_export SDL_unsetenv_unsafe          => [String], Int;
        _typedef_and_export SDL_CompareCallback => Callback [ [ Pointer [Void], Pointer [Void] ] => Int ];
        _affix_and_export SDL_qsort => [ Pointer [Void], Size_t, Size_t, SDL_CompareCallback() ], Void;
        _affix_and_export SDL_bsearch => [ Pointer [Void], Pointer [Void], Size_t, Size_t, SDL_CompareCallback() ], Pointer [Void];
        _typedef_and_export SDL_CompareCallback_r => Callback [ [ Pointer [Void], Pointer [Void], Pointer [Void] ] => Int ];
        _affix_and_export SDL_qsort_r => [ Pointer [Void], Size_t, Size_t, SDL_CompareCallback_r(), Pointer [Void] ], Void;
        _affix_and_export
            SDL_bsearch_r => [ Pointer [Void], Pointer [Void], Size_t, Size_t, SDL_CompareCallback_r(), Pointer [Void] ],
            Pointer [Void];
        _affix_and_export SDL_abs => [Int], Int;
        _func_and_export SDL_min   => sub ( $x, $y ) { ( ( ($x) < ($y) ) ? ($x) : ($y) ) };
        _func_and_export SDL_max   => sub ( $x, $y ) { ( ( ($x) > ($y) ) ? ($x) : ($y) ) };
        _func_and_export SDL_clamp => sub ( $x, $a, $b ) { ( ( ($x) < ($a) ) ? ($a) : ( ( ($x) > ($b) ) ? ($b) : ($x) ) ) };
        _affix_and_export SDL_isalpha     => [Int], Int;
        _affix_and_export SDL_isalnum     => [Int], Int;
        _affix_and_export SDL_isblank     => [Int], Int;
        _affix_and_export SDL_iscntrl     => [Int], Int;
        _affix_and_export SDL_isdigit     => [Int], Int;
        _affix_and_export SDL_isxdigit    => [Int], Int;
        _affix_and_export SDL_ispunct     => [Int], Int;
        _affix_and_export SDL_isspace     => [Int], Int;
        _affix_and_export SDL_isupper     => [Int], Int;
        _affix_and_export SDL_islower     => [Int], Int;
        _affix_and_export SDL_isprint     => [Int], Int;
        _affix_and_export SDL_isgraph     => [Int], Int;
        _affix_and_export SDL_toupper     => [Int], Int;
        _affix_and_export SDL_tolower     => [Int], Int;
        _affix_and_export SDL_crc16       => [ UInt16, Pointer [Void], Size_t ], UInt16;
        _affix_and_export SDL_crc32       => [ UInt32, Pointer [Void], Size_t ], UInt32;
        _affix_and_export SDL_murmur3_32  => [ Pointer [Void], Size_t, UInt32 ], UInt32;
        _affix_and_export SDL_memcpy      => [ Pointer [Void], Pointer [Void], Size_t ], Pointer [Void];
        _affix_and_export SDL_memmove     => [ Pointer [Void], Pointer [Void], Size_t ], Pointer [Void];
        _affix_and_export SDL_memset      => [ Pointer [Void], Int,    Size_t ], Pointer [Void];
        _affix_and_export SDL_memset4     => [ Pointer [Void], UInt32, Size_t ], Pointer [Void];
        _affix_and_export SDL_memcmp      => [ Pointer [Void], Pointer [Void], Size_t ], Int;
        _affix_and_export SDL_wcslen      => [ Pointer [WChar] ], Size_t;
        _affix_and_export SDL_wcsnlen     => [ Pointer [WChar], Size_t ], Size_t;
        _affix_and_export SDL_wcslcpy     => [ Pointer [WChar], WString, Size_t ], Size_t;
        _affix_and_export SDL_wcslcat     => [ Pointer [WChar], WString, Size_t ], Size_t;
        _affix_and_export SDL_wcsdup      => [WString], WString;
        _affix_and_export SDL_wcsstr      => [ WString, WString ], WString;
        _affix_and_export SDL_wcsnstr     => [ WString, WString, Size_t ], WString;
        _affix_and_export SDL_wcscmp      => [ WString, WString ], Int;
        _affix_and_export SDL_wcsncmp     => [ WString, WString, Size_t ], Int;
        _affix_and_export SDL_wcscasecmp  => [ WString, WString ], Int;
        _affix_and_export SDL_wcsncasecmp => [ WString, WString, Size_t ], Int;
        _affix_and_export SDL_wcstol      => [ WString, Pointer [ Pointer [WChar] ], Int ], Long;
        _affix_and_export SDL_strlen      => [String], Size_t;
        _affix_and_export SDL_strnlen     => [ String, Size_t ], Size_t;
        _affix_and_export SDL_strlcpy     => [ Pointer [UInt8], String, Size_t ], Size_t;
        _affix_and_export SDL_utf8strlcpy => [ Pointer [UInt8], String, Size_t ], Size_t;
        _affix_and_export SDL_strlcat     => [ Pointer [UInt8], String, Size_t ], Size_t;
        _affix_and_export SDL_strdup      => [String], String;
        _affix_and_export SDL_strndup     => [ String, Size_t ], String;
        _affix_and_export SDL_strrev      => [ Pointer [UInt8] ], String;
        _affix_and_export SDL_strupr      => [ Pointer [UInt8] ], String;
        _affix_and_export SDL_strlwr      => [ Pointer [UInt8] ], String;
        _affix_and_export SDL_strchr      => [ String, Int ],    String;
        _affix_and_export SDL_strrchr     => [ String, Int ],    String;
        _affix_and_export SDL_strstr      => [ String, String ], String;
        _affix_and_export SDL_strnstr     => [ String, String, Size_t ], String;
        _affix_and_export SDL_strcasestr  => [ String, String ], String;
        _affix_and_export SDL_strtok_r    => [ Pointer [UInt8], String, Pointer [ Pointer [UInt8] ] ], String;
        _affix_and_export SDL_utf8strlen  => [String], Size_t;
        _affix_and_export SDL_utf8strnlen => [ String, Size_t ], Size_t;
        _affix_and_export SDL_itoa        => [ Int,       Pointer [UInt8], Int ], String;
        _affix_and_export SDL_uitoa       => [ UInt,      Pointer [UInt8], Int ], String;
        _affix_and_export SDL_ltoa        => [ Long,      Pointer [UInt8], Int ], String;
        _affix_and_export SDL_ultoa       => [ ULong,     Pointer [UInt8], Int ], String;
        _affix_and_export SDL_lltoa       => [ LongLong,  Pointer [UInt8], Int ], String;
        _affix_and_export SDL_ulltoa      => [ ULongLong, Pointer [UInt8], Int ], String;
        _affix_and_export SDL_atoi        => [String], Int;
        _affix_and_export SDL_atof        => [String], Double;
        _affix_and_export SDL_strtol      => [ String, Pointer [ Pointer [UInt8] ], Int ], Long;
        _affix_and_export SDL_strtoul     => [ String, Pointer [ Pointer [UInt8] ], Int ], ULong;
        _affix_and_export SDL_strtoll     => [ String, Pointer [ Pointer [UInt8] ], Int ], LongLong;
        _affix_and_export SDL_strtoull    => [ String, Pointer [ Pointer [UInt8] ], Int ], ULongLong;
        _affix_and_export SDL_strtod      => [ String, Pointer [ Pointer [UInt8] ] ], Double;
        _affix_and_export SDL_strcmp      => [ String, String ], Int;
        _affix_and_export SDL_strncmp     => [ String, String, Size_t ], Int;
        _affix_and_export SDL_strcasecmp  => [ String, String ], Int;
        _affix_and_export SDL_strncasecmp => [ String, String, Size_t ], Int;
        _affix_and_export SDL_strpbrk     => [ String, String ], String;
        _const_and_export SDL_INVALID_UNICODE_CODEPOINT => 0xFFFD;
        _affix_and_export SDL_StepUTF8     => [ Pointer [String], Pointer [Size_t] ], UInt32;
        _affix_and_export SDL_StepBackUTF8 => [ String, Pointer [String] ], UInt32;
        _affix_and_export SDL_UCS4ToUTF8   => [ UInt32, Pointer [UInt8] ],  String;

        #~ _affix_and_export SDL_sscanf       => [ String, String, VarArgs ],            Int;
        _affix_and_export SDL_vsscanf => [ String, String, Pointer [Void] ], Int;

        #~ _affix_and_export SDL_snprintf     => [ Pointer [UInt8], Size_t, String, VarArgs ], Int;
        #~ _affix_and_export SDL_swprintf     => [ Pointer [WChar], Size_t, WString, VarArgs ], Int;
        _affix_and_export SDL_vsnprintf => [ Pointer [UInt8], Size_t, String,  Pointer [Void] ], Int;
        _affix_and_export SDL_vswprintf => [ Pointer [WChar], Size_t, WString, Pointer [Void] ], Int;

        #~ _affix_and_export SDL_asprintf     => [ Pointer [ Pointer [UInt8] ], String, VarArgs ], Int;
        _affix_and_export SDL_vasprintf   => [ Pointer [ Pointer [UInt8] ], String, Pointer [Void] ], Int;
        _affix_and_export SDL_srand       => [UInt64], Void;
        _affix_and_export SDL_rand        => [SInt32], SInt32;
        _affix_and_export SDL_randf       => [], Float;
        _affix_and_export SDL_rand_bits   => [], UInt32;
        _affix_and_export SDL_rand_r      => [ Pointer [UInt64], SInt32 ], SInt32;
        _affix_and_export SDL_randf_r     => [ Pointer [UInt64] ], Float;
        _affix_and_export SDL_rand_bits_r => [ Pointer [UInt64] ], UInt32;
        _const_and_export SDL_PI_D => 3.141592653589793238462643383279502884;
        _const_and_export SDL_PI_F => 3.141592653589793238462643383279502884;
        _affix_and_export SDL_acos      => [Double], Double;
        _affix_and_export SDL_acosf     => [Float],  Float;
        _affix_and_export SDL_asin      => [Double], Double;
        _affix_and_export SDL_asinf     => [Float],  Float;
        _affix_and_export SDL_atan      => [Double], Double;
        _affix_and_export SDL_atanf     => [Float],  Float;
        _affix_and_export SDL_atan2     => [ Double, Double ], Double;
        _affix_and_export SDL_atan2f    => [ Float, Float ],   Float;
        _affix_and_export SDL_ceil      => [Double], Double;
        _affix_and_export SDL_ceilf     => [Float],  Float;
        _affix_and_export SDL_copysign  => [ Double, Double ], Double;
        _affix_and_export SDL_copysignf => [ Float, Float ],   Float;
        _affix_and_export SDL_cos       => [Double], Double;
        _affix_and_export SDL_cosf      => [Float],  Float;
        _affix_and_export SDL_exp       => [Double], Double;
        _affix_and_export SDL_expf      => [Float],  Float;
        _affix_and_export SDL_fabs      => [Double], Double;
        _affix_and_export SDL_fabsf     => [Float],  Float;
        _affix_and_export SDL_floor     => [Double], Double;
        _affix_and_export SDL_floorf    => [Float],  Float;
        _affix_and_export SDL_trunc     => [Double], Double;
        _affix_and_export SDL_truncf    => [Float],  Float;
        _affix_and_export SDL_fmod      => [ Double, Double ], Double;
        _affix_and_export SDL_fmodf     => [ Float, Float ],   Float;
        _affix_and_export SDL_isinf     => [Double], Int;
        _affix_and_export SDL_isinff    => [Float],  Int;
        _affix_and_export SDL_isnan     => [Double], Int;
        _affix_and_export SDL_isnanf    => [Float],  Int;
        _affix_and_export SDL_log       => [Double], Double;
        _affix_and_export SDL_logf      => [Float],  Float;
        _affix_and_export SDL_log10     => [Double], Double;
        _affix_and_export SDL_log10f    => [Float],  Float;
        _affix_and_export SDL_modf      => [ Double, Pointer [Double] ], Double;
        _affix_and_export SDL_modff     => [ Float, Pointer [Float] ],   Float;
        _affix_and_export SDL_pow       => [ Double, Double ], Double;
        _affix_and_export SDL_powf      => [ Float, Float ],   Float;
        _affix_and_export SDL_round     => [Double], Double;
        _affix_and_export SDL_roundf    => [Float],  Float;
        _affix_and_export SDL_lround    => [Double], Long;
        _affix_and_export SDL_lroundf   => [Float],  Long;
        _affix_and_export SDL_scalbn    => [ Double, Int ], Double;
        _affix_and_export SDL_scalbnf   => [ Float, Int ],  Float;
        _affix_and_export SDL_sin       => [Double], Double;
        _affix_and_export SDL_sinf      => [Float],  Float;
        _affix_and_export SDL_sqrt      => [Double], Double;
        _affix_and_export SDL_sqrtf     => [Float],  Float;
        _affix_and_export SDL_tan       => [Double], Double;
        _affix_and_export SDL_tanf      => [Float],  Float;
        _typedef_and_export SDL_iconv_t => Pointer [Void];
        _affix_and_export SDL_iconv_open => [ String, String ], SDL_iconv_t();
        _affix_and_export SDL_iconv_close => [ SDL_iconv_t() ], Int;
        _affix_and_export
            SDL_iconv => [ SDL_iconv_t(), Pointer [ Pointer [UInt8] ], Pointer [Size_t], Pointer [ Pointer [UInt8] ], Pointer [Size_t] ],
            Size_t;
        _const_and_export SDL_ICONV_ERROR  => -1;
        _const_and_export SDL_ICONV_E2BIG  => -2;
        _const_and_export SDL_ICONV_EILSEQ => -3;
        _const_and_export SDL_ICONV_EINVAL => -4;
        #
        _affix_and_export SDL_iconv_string => [ String, String, String, Size_t ], Pointer [UInt8];
        _func_and_export SDL_iconv_utf8_locale => sub ($S) { SDL_iconv_string( '',      'UTF-8', $S, SDL_strlen($S) + 1 ) };
        _func_and_export SDL_iconv_utf8_ucs2   => sub ($S) { SDL_iconv_string( 'UCS-2', 'UTF-8', $S, SDL_strlen($S) + 1 ) };
        _func_and_export SDL_iconv_utf8_ucs4   => sub ($S) { SDL_iconv_string( 'UCS-4', 'UTF-8', $S, SDL_strlen($S) + 1 ) };
        _func_and_export SDL_iconv_wchar_utf8 => sub ($S) { SDL_iconv_string( 'UTF-8', 'WCHAR_T', $S, ( SDL_wcslen($S) + 1 ) * length( pack 'P' ) ) };
        #
        my $max_size_t = ( 2**( $Config{ptrsize} * 8 ) ) - 1;
        _func_and_export SDL_size_mul_check_overflow => sub ( $a, $b, $ret ) {
            return 0 if ( $a != 0 && $b > $max_size_t / $a );
            $$ret = $a * $b;
            return 1;
        };
        _func_and_export SDL_size_add_check_overflow => sub ( $a, $b, $ret ) {
            return 0 if ( $b > $max_size_t - $a );
            $$ret = $a + $b;
            return 1;
        };
        #
        _typedef_and_export SDL_FunctionPointer => Callback [ [] => Void ];
    }

=head3 C<:system> - Platform-specific Functionality

Platform-specific SDL API functions. These are functions that deal with needs of specific operating systems, that
didn't make sense to offer as platform-independent, generic APIs.

Most apps can make do without these functions, but they can be useful for integrating with other parts of a specific
system, adding platform-specific polish to an app, or solving problems that only affect one target.

See L<SDL3: CategorySystem|https://wiki.libsdl.org/SDL3/CategorySystem>

=cut

    sub _system() {
        state $done++ && return;
        #
        _error();
        _keyboard();
        _stdinc();
        _video();

        # if defined(SDL_PLATFORM_WINDOWS)
        if ( $^O eq 'MSWin32' ) {
            _typedef_and_export MSG                    => Void;
            _typedef_and_export SDL_WindowsMessageHook => Callback [ [ Pointer [Void], Pointer [ MSG() ] ] => Bool ];
            _affix_and_export SDL_SetWindowsMessageHook => [ SDL_WindowsMessageHook(), Pointer [Void] ], Void;
        }

        # if defined(SDL_PLATFORM_WIN32) || defined(SDL_PLATFORM_WINGDK)
        if ( $^O eq 'MSWin32' ) {
            _affix_and_export SDL_GetDirect3D9AdapterIndex => [ SDL_DisplayID() ], Int;
            _affix_and_export SDL_GetDXGIOutputInfo => [ SDL_DisplayID(), Pointer [Int], Pointer [Int] ], Bool;
        }

        # Unconditional in header, though usually implies X11 support
        _typedef_and_export XEvent           => Void;
        _typedef_and_export SDL_X11EventHook => Callback [ [ Pointer [Void], Pointer [ XEvent() ] ] => Bool ];
        _affix_and_export SDL_SetX11EventHook => [ SDL_X11EventHook(), Pointer [Void] ], Void;

        # ifdef SDL_PLATFORM_LINUX
        if ( $^O eq 'linux' ) {
            _affix_and_export SDL_SetLinuxThreadPriority => [ SInt64, Int ], Bool;
            _affix_and_export SDL_SetLinuxThreadPriorityAndPolicy => [ SInt64, Int, Int ], Bool;
        }

        # ifdef SDL_PLATFORM_IOS
        if ( $^O eq 'darwin' && 0 ) {    # Perl on iOS? Yeah, right...
            _typedef_and_export SDL_iOSAnimationCallback => Callback [ [ Pointer [Void] ] => Void ];
            _affix_and_export
                SDL_SetiOSAnimationCallback => [ Pointer [ SDL_Window() ], Int, SDL_iOSAnimationCallback(), Pointer [Void] ],
                Bool;
            _affix_and_export SDL_SetiOSEventPump => [Bool], Void;
        }

        # ifdef SDL_PLATFORM_ANDROID
        if ( $^O eq 'android' ) {
            _affix_and_export SDL_GetAndroidJNIEnv      => [], Pointer [Void];
            _affix_and_export SDL_GetAndroidActivity    => [], Pointer [Void];
            _affix_and_export SDL_GetAndroidSDKVersion  => [], Int;
            _affix_and_export SDL_IsChromebook          => [], Bool;
            _affix_and_export SDL_IsDeXMode             => [], Bool;
            _affix_and_export SDL_SendAndroidBackButton => [], Void;
            _const_and_export SDL_ANDROID_EXTERNAL_STORAGE_READ  => 0x01;
            _const_and_export SDL_ANDROID_EXTERNAL_STORAGE_WRITE => 0x02;
            _affix_and_export SDL_GetAndroidInternalStoragePath  => [], String;
            _affix_and_export SDL_GetAndroidExternalStorageState => [], UInt32;
            _affix_and_export SDL_GetAndroidExternalStoragePath  => [], String;
            _affix_and_export SDL_GetAndroidCachePath            => [], String;
            _typedef_and_export SDL_RequestAndroidPermissionCallback => Callback [ [ Pointer [Void], String, Bool ] => Void ];
            _affix_and_export
                SDL_RequestAndroidPermission => [ String, SDL_RequestAndroidPermissionCallback(), Pointer [Void] ],
                Bool;
            _affix_and_export SDL_ShowAndroidToast => [ String, Int, Int, Int, Int ], Bool;
            _affix_and_export SDL_SendAndroidMessage => [ UInt32, Int ], Bool;
        }

        # General
        _affix_and_export SDL_IsTablet => [], Bool;
        _affix_and_export SDL_IsTV     => [], Bool;
        _enum_and_export SDL_Sandbox =>
            [ 'SDL_SANDBOX_NONE', 'SDL_SANDBOX_UNKNOWN_CONTAINER', 'SDL_SANDBOX_FLATPAK', 'SDL_SANDBOX_SNAP', 'SDL_SANDBOX_MACOS' ];
        _affix_and_export SDL_GetSandbox                           => [], SDL_Sandbox();
        _affix_and_export SDL_OnApplicationWillTerminate           => [], Void;
        _affix_and_export SDL_OnApplicationDidReceiveMemoryWarning => [], Void;
        _affix_and_export SDL_OnApplicationWillEnterBackground     => [], Void;
        _affix_and_export SDL_OnApplicationDidEnterBackground      => [], Void;
        _affix_and_export SDL_OnApplicationWillEnterForeground     => [], Void;
        _affix_and_export SDL_OnApplicationDidEnterForeground      => [], Void;

        # ifdef SDL_PLATFORM_IOS
        if ( $^O eq 'darwin' && 0 ) {
            _affix_and_export SDL_OnApplicationDidChangeStatusBarOrientation => [], Void;
        }

        # ifdef SDL_PLATFORM_GDK
        # Note: No standard Perl $^O for GDK, usually handled via custom build flags
        if (0) {
            _typedef_and_export XTaskQueueHandle => Pointer [Void];
            _typedef_and_export XUserHandle      => Pointer [Void];
            _affix_and_export SDL_GetGDKTaskQueue   => [ Pointer [ XTaskQueueHandle() ] ], Bool;
            _affix_and_export SDL_GetGDKDefaultUser => [ Pointer [ XUserHandle() ] ],      Bool;
        }
    }

=head3 C<:thread> - Thread Management

SDL offers cross-platform thread management functions. These are mostly concerned with starting threads, setting their
priority, and dealing with their termination.

See L<SDL3: CategoryThread|https://wiki.libsdl.org/SDL3/CategoryThread>

=cut

    sub _thread () {
        state $done++ && return;
        #
        _error();
        _properties();
        _stdinc();
        _atomic();
        #
        _typedef_and_export SDL_TLSID => SDL_AtomicInt();
        _enum_and_export SDL_ThreadPriority =>
            [ 'SDL_THREAD_PRIORITY_LOW', 'SDL_THREAD_PRIORITY_NORMAL', 'SDL_THREAD_PRIORITY_HIGH', 'SDL_THREAD_PRIORITY_TIME_CRITICAL' ];
        _enum_and_export SDL_ThreadState => [ 'SDL_THREAD_UNKNOWN', 'SDL_THREAD_ALIVE', 'SDL_THREAD_DETACHED', 'SDL_THREAD_COMPLETE' ];
        _typedef_and_export SDL_ThreadFunction => Callback [ [ Pointer [Void] ] => Int ];
        _typedef_and_export SDL_Thread         => Void;
        _typedef_and_export SDL_ThreadID       => UInt64;
        _affix_and_export
            SDL_CreateThreadRuntime => [ SDL_ThreadFunction(), String, Pointer [Void], Pointer [Void], Pointer [Void] ],
            Pointer [ SDL_Thread() ];
        _func_and_export SDL_CreateThread => sub ( $fn, $name, $data ) {
            SDL_CreateThreadRuntime( $fn, $name, $data, SDL_BeginThreadFunction(), SDL_EndThreadFunction() );

            # Since SDL_CreateThread is defined as a preprocessor macro wrapping
            # SDL_CreateThreadRuntime in the C header, I have bound
            # SDL_CreateThreadRuntime but aliased it to SDL_CreateThread. Callers will need
            # to pass undef (NULL) for the two function pointer arguments (pfnBeginThread,
            # pfnEndThread) which are used internally by the CRT.
        };
        _affix_and_export
            SDL_CreateThreadWithPropertiesRuntime => [ SDL_PropertiesID(), Pointer [Void], Pointer [Void] ],
            Pointer [ SDL_Thread() ];
        _func_and_export SDL_CreateThreadWithProperties => sub ($props) {
            SDL_CreateThreadWithPropertiesRuntime( $props, SDL_BeginThreadFunction(), SDL_EndThreadFunction() );
        };
        _const_and_export SDL_PROP_THREAD_CREATE_ENTRY_FUNCTION_POINTER => 'SDL.thread.create.entry_function';
        _const_and_export SDL_PROP_THREAD_CREATE_NAME_STRING            => 'SDL.thread.create.name';
        _const_and_export SDL_PROP_THREAD_CREATE_USERDATA_POINTER       => 'SDL.thread.create.userdata';
        _const_and_export SDL_PROP_THREAD_CREATE_STACKSIZE_NUMBER       => 'SDL.thread.create.stacksize';
        _affix_and_export SDL_GetThreadName            => [ Pointer [ SDL_Thread() ] ], String;
        _affix_and_export SDL_GetCurrentThreadID       => [], SDL_ThreadID();
        _affix_and_export SDL_GetThreadID              => [ Pointer [ SDL_Thread() ] ], SDL_ThreadID();
        _affix_and_export SDL_SetCurrentThreadPriority => [ SDL_ThreadPriority() ], Bool;
        _affix_and_export SDL_WaitThread               => [ Pointer [ SDL_Thread() ], Pointer [Int] ], Void;
        _affix_and_export SDL_GetThreadState           => [ Pointer [ SDL_Thread() ] ], SDL_ThreadState();
        _affix_and_export SDL_DetachThread             => [ Pointer [ SDL_Thread() ] ], Void;
        _affix_and_export SDL_GetTLS                   => [ Pointer [ SDL_TLSID() ] ],  Pointer [Void];
        _typedef_and_export SDL_TLSDestructorCallback => Callback [ [ Pointer [Void] ] => Void ];
        _affix_and_export SDL_SetTLS => [ Pointer [ SDL_TLSID() ], Pointer [Void], SDL_TLSDestructorCallback() ], Bool;
        _affix_and_export SDL_CleanupTLS => [], Void;
    }

=head3 C<:time> - Date and Time

SDL realtime clock and date/time routines.

There are two data types that are used in this category: L<SDL_Time|https://wiki.libsdl.org/SDL3/SDL_Time>, which
represents the nanoseconds since a specific moment (an "epoch"), and
L<SDL_DateTime|https://wiki.libsdl.org/SDL3/SDL_DateTime>, which breaks time down into human-understandable components:
years, months, days, hours, etc.

Much of the functionality is involved in converting those two types to other useful forms.

See L<SDL3: CategoryTime|https://wiki.libsdl.org/SDL3/CategoryTime>

=cut

    sub _time () {
        state $done++ && return;
        #
        _error();
        _stdinc();
        #
        _typedef_and_export SDL_DateTime => Struct [
            year        => Int,
            month       => Int,
            day         => Int,
            hour        => Int,
            minute      => Int,
            second      => Int,
            nanosecond  => Int,
            day_of_week => Int,
            utc_offset  => Int
        ];
        _enum_and_export SDL_DateFormat => [ 'SDL_DATE_FORMAT_YYYYMMDD', 'SDL_DATE_FORMAT_DDMMYYYY', 'SDL_DATE_FORMAT_MMDDYYYY' ];
        _enum_and_export SDL_TimeFormat => [ 'SDL_TIME_FORMAT_24HR', 'SDL_TIME_FORMAT_12HR' ];
        _typedef_and_export SDL_Time => SInt64;
        _affix_and_export
            SDL_GetDateTimeLocalePreferences => [ Pointer [ SDL_DateFormat() ], Pointer [ SDL_TimeFormat() ] ],
            Bool;
        _affix_and_export SDL_GetCurrentTime  => [ Pointer [ SDL_Time() ] ], Bool;
        _affix_and_export SDL_TimeToDateTime  => [ SDL_Time(), Pointer [ SDL_DateTime() ], Bool ], Bool;
        _affix_and_export SDL_DateTimeToTime  => [ Pointer [ SDL_DateTime() ], Pointer [ SDL_Time() ] ], Bool;
        _affix_and_export SDL_TimeToWindows   => [ SDL_Time(), Pointer [UInt32], Pointer [UInt32] ], Void;
        _affix_and_export SDL_TimeFromWindows => [ UInt32, UInt32 ], SDL_Time();
        _affix_and_export SDL_GetDaysInMonth  => [ Int, Int ],       Int;
        _affix_and_export SDL_GetDayOfYear    => [ Int, Int, Int ], Int;
        _affix_and_export SDL_GetDayOfWeek    => [ Int, Int, Int ], Int;
    }

=head3 C<:timer> - Timer Support

SDL provides time management functionality. It is useful for dealing with (usually) small durations of time.

See L<SDL3: CategoryTimer|https://wiki.libsdl.org/SDL3/CategoryTimer>

=cut

    sub _timer() {
        state $done++ && return;
        #
        _error();
        _stdinc();
        #
        _const_and_export SDL_MS_PER_SECOND => 1000;
        _const_and_export SDL_US_PER_SECOND => 1000000;
        _const_and_export SDL_NS_PER_SECOND => 1000000000;
        _const_and_export SDL_NS_PER_MS     => 1000000;
        _const_and_export SDL_NS_PER_US     => 1000;
        _func_and_export( SDL_SECONDS_TO_NS => sub ($S) { ( ( ($S) ) * SDL_NS_PER_SECOND() ) } );
        _func_and_export( SDL_NS_TO_SECONDS => sub ($NS) { ( ($NS) / SDL_NS_PER_SECOND() ) } );
        _func_and_export( SDL_MS_TO_NS      => sub ($MS) { ( ( ($MS) ) * SDL_NS_PER_MS() ) } );
        _func_and_export( SDL_NS_TO_MS      => sub ($NS) { ( ($NS) / SDL_NS_PER_MS() ) } );
        _func_and_export( SDL_US_TO_NS      => sub ($US) { ( ( ($US) ) * SDL_NS_PER_US() ) } );
        _func_and_export( SDL_NS_TO_US      => sub ($NS) { ( ($NS) / SDL_NS_PER_US() ) } );
        _affix_and_export 'SDL_GetTicks',                [],       UInt64;
        _affix_and_export 'SDL_GetTicksNS',              [],       UInt64;
        _affix_and_export 'SDL_GetPerformanceCounter',   [],       UInt64;
        _affix_and_export 'SDL_GetPerformanceFrequency', [],       UInt64;
        _affix_and_export 'SDL_Delay',                   [UInt32], Void;
        _affix_and_export 'SDL_DelayNS',                 [UInt64], Void;
        _affix_and_export 'SDL_DelayPrecise',            [UInt64], Void;
        _typedef_and_export SDL_TimerID       => UInt32;
        _typedef_and_export SDL_TimerCallback => Callback [ [ Pointer [Void], SDL_TimerID(), UInt32 ] => UInt32 ];
        _affix_and_export SDL_AddTimer => [ UInt32, SDL_TimerCallback(), Pointer [Void] ], SDL_TimerID();
        _typedef_and_export SDL_NSTimerCallback => Callback [ [ Pointer [Void], SDL_TimerID(), UInt64 ] => UInt64 ];
        _affix_and_export SDL_AddTimerNS => [ UInt64, SDL_NSTimerCallback(), Pointer [Void] ], SDL_TimerID();
        _affix_and_export SDL_RemoveTimer => [ SDL_TimerID() ], Bool;
    }

=head3 C<:touch> - Touch Support

SDL offers touch input, on platforms that support it. It can manage multiple touch devices and track multiple fingers
on those devices.

See L<SDL3: CategoryTouch|https://wiki.libsdl.org/SDL3/CategoryTouch>

=cut

    sub _touch() {
        state $done++ && return;
        _error();
        _mouse();
        _stdinc();
        #
        _typedef_and_export SDL_TouchID  => UInt64;
        _typedef_and_export SDL_FingerID => UInt64;
        _enum_and_export SDL_TouchDeviceType => [
            [ SDL_TOUCH_DEVICE_INVALID => -1 ],   'SDL_TOUCH_DEVICE_DIRECT',
            'SDL_TOUCH_DEVICE_INDIRECT_ABSOLUTE', 'SDL_TOUCH_DEVICE_INDIRECT_RELATIVE'
        ];
        _typedef_and_export SDL_Finger => Struct [ id => SDL_FingerID(), x => Float, y => Float, pressure => Float ];
        _const_and_export SDL_TOUCH_MOUSEID => -1;
        _const_and_export SDL_MOUSE_TOUCHID => -1;
        _affix_and_export SDL_GetTouchDevices    => [ Pointer [ SDL_TouchID() ] ], Pointer [Int];
        _affix_and_export SDL_GetTouchDeviceName => [ SDL_TouchID() ], String;
        _affix_and_export SDL_GetTouchDeviceType => [ SDL_TouchID() ], SDL_TouchDeviceType();
        _affix_and_export SDL_GetTouchFingers    => [ SDL_TouchID(), Pointer [Int] ], Pointer [ Pointer [ SDL_Finger() ] ];
    }

=head3 C<:tray> - System Tray

SDL offers a way to add items to the "system tray" (more correctly called the "notification area" on Windows). On
platforms that offer this concept, an SDL app can add a tray icon, submenus, checkboxes, and clickable entries, and
register a callback that is fired when the user clicks on these pieces.

See L<SDL3: CategoryTray|https://wiki.libsdl.org/SDL3/CategoryTray>

=cut

    sub _tray () {
        state $done++ && return;
        #
        _error();
        _stdinc();
        _surface();
        _video();
        #
        _typedef_and_export SDL_Tray           => Void;
        _typedef_and_export SDL_TrayMenu       => Void;
        _typedef_and_export SDL_TrayEntry      => Void;
        _typedef_and_export SDL_TrayEntryFlags => UInt32;
        _const_and_export SDL_TRAYENTRY_BUTTON   => 0x00000001;
        _const_and_export SDL_TRAYENTRY_CHECKBOX => 0x00000002;
        _const_and_export SDL_TRAYENTRY_SUBMENU  => 0x00000004;
        _const_and_export SDL_TRAYENTRY_DISABLED => 0x80000000;
        _const_and_export SDL_TRAYENTRY_CHECKED  => 0x40000000;
        _typedef_and_export SDL_TrayCallback => Callback [ [ Pointer [Void], Pointer [ SDL_TrayEntry() ] ] => Void ];
        _affix_and_export SDL_CreateTray        => [ Pointer [ SDL_Surface() ], String ], Pointer [ SDL_Tray() ];
        _affix_and_export SDL_SetTrayIcon       => [ Pointer [ SDL_Tray() ], Pointer [ SDL_Surface() ] ], Void;
        _affix_and_export SDL_SetTrayTooltip    => [ Pointer [ SDL_Tray() ], String ], Void;
        _affix_and_export SDL_CreateTrayMenu    => [ Pointer [ SDL_Tray() ] ],      Pointer [ SDL_TrayMenu() ];
        _affix_and_export SDL_CreateTraySubmenu => [ Pointer [ SDL_TrayEntry() ] ], Pointer [ SDL_TrayMenu() ];
        _affix_and_export SDL_GetTrayMenu       => [ Pointer [ SDL_Tray() ] ],      Pointer [ SDL_TrayMenu() ];
        _affix_and_export SDL_GetTraySubmenu    => [ Pointer [ SDL_TrayEntry() ] ], Pointer [ SDL_TrayMenu() ];
        _affix_and_export
            SDL_GetTrayEntries => [ Pointer [ SDL_TrayMenu() ], Pointer [Int] ],
            Pointer [ Pointer [ SDL_TrayEntry() ] ];
        _affix_and_export SDL_RemoveTrayEntry => [ Pointer [ SDL_TrayEntry() ] ], Void;
        _affix_and_export
            SDL_InsertTrayEntryAt => [ Pointer [ SDL_TrayMenu() ], Int, String, SDL_TrayEntryFlags() ],
            Pointer [ SDL_TrayEntry() ];
        _affix_and_export SDL_SetTrayEntryLabel   => [ Pointer [ SDL_TrayEntry() ], String ], Void;
        _affix_and_export SDL_GetTrayEntryLabel   => [ Pointer [ SDL_TrayEntry() ] ], String;
        _affix_and_export SDL_SetTrayEntryChecked => [ Pointer [ SDL_TrayEntry() ], Bool ], Void;
        _affix_and_export SDL_GetTrayEntryChecked => [ Pointer [ SDL_TrayEntry() ] ], Bool;
        _affix_and_export SDL_SetTrayEntryEnabled => [ Pointer [ SDL_TrayEntry() ], Bool ], Void;
        _affix_and_export SDL_GetTrayEntryEnabled => [ Pointer [ SDL_TrayEntry() ] ], Bool;
        _affix_and_export
            SDL_SetTrayEntryCallback => [ Pointer [ SDL_TrayEntry() ], SDL_TrayCallback(), Pointer [Void] ],
            Void;
        _affix_and_export SDL_ClickTrayEntry         => [ Pointer [ SDL_TrayEntry() ] ], Void;
        _affix_and_export SDL_DestroyTray            => [ Pointer [ SDL_Tray() ] ],      Void;
        _affix_and_export SDL_GetTrayEntryParent     => [ Pointer [ SDL_TrayEntry() ] ], Pointer [ SDL_TrayMenu() ];
        _affix_and_export SDL_GetTrayMenuParentEntry => [ Pointer [ SDL_TrayMenu() ] ],  Pointer [ SDL_TrayEntry() ];
        _affix_and_export SDL_GetTrayMenuParentTray  => [ Pointer [ SDL_TrayMenu() ] ],  Pointer [ SDL_Tray() ];
        _affix_and_export SDL_UpdateTrays            => [], Void;
    }

=head3 C<:version> - Querying SDL Version

Functionality to query the current SDL version, both as headers the app was compiled against, and a library the app is
linked to.

See L<SDL3: CategoryVersion|https://wiki.libsdl.org/SDL3/CategoryVersion>

=cut

    sub _version() {
        state $done++ && return;
        #
        _stdinc();
        #
        _affix_and_export 'SDL_GetVersion',  [], Int;
        _affix_and_export 'SDL_GetRevision', [], Int;
        _func_and_export SDL_MAJOR_VERSION    => sub () { state $i //= SDL_VERSIONNUM_MAJOR( SDL_GetVersion() ); $i };
        _func_and_export SDL_MINOR_VERSION    => sub () { state $i //= SDL_VERSIONNUM_MINOR( SDL_GetVersion() ); $i };
        _func_and_export SDL_MICRO_VERSION    => sub () { state $i //= SDL_VERSIONNUM_MICRO( SDL_GetVersion() ); $i };
        _func_and_export SDL_VERSIONNUM       => sub ( $major, $minor, $patch ) { ( ($major) * 1000000 + ($minor) * 1000 + ($patch) ) };
        _func_and_export SDL_VERSIONNUM_MAJOR => sub ($version) { int( ($version) / 1000000 ) };
        _func_and_export SDL_VERSIONNUM_MINOR => sub ($version) { int( ( ($version) / 1000 ) % 1000 ) };
        _func_and_export SDL_VERSIONNUM_MICRO => sub ($version) { int( ($version) % 1000 ) };
        _const_and_export SDL_VERSION => SDL_VERSIONNUM( SDL_MAJOR_VERSION(), SDL_MINOR_VERSION(), SDL_MICRO_VERSION() );
        _func_and_export SDL_VERSION_ATLEAST => sub ( $X, $Y, $Z ) { ( SDL_VERSION() >= SDL_VERSIONNUM( $X, $Y, $Z ) ); };
    }

=head3 C<:video> - Display and Window Management

SDL's video subsystem is largely interested in abstracting window management from the underlying operating system. You
can create windows, manage them in various ways, set them fullscreen, and get events when interesting things happen
with them, such as the mouse or keyboard interacting with a window.

See L<SDL3: CategoryVideo|https://wiki.libsdl.org/SDL3/CategoryVideo>

=cut

    sub _video() {
        state $done++ && return;
        _error();
        _pixels();
        _properties();
        _rect();
        _stdinc();
        _surface();
        #
        _typedef_and_export SDL_DisplayID => UInt32;
        _typedef_and_export SDL_WindowID  => UInt32;
        _const_and_export SDL_PROP_GLOBAL_VIDEO_WAYLAND_WL_DISPLAY_POINTER => 'SDL.video.wayland.wl_display';
        _enum_and_export SDL_SystemTheme => [qw[SDL_SYSTEM_THEME_UNKNOWN SDL_SYSTEM_THEME_LIGHT SDL_SYSTEM_THEME_DARK]];
        _typedef_and_export 'SDL_DisplayModeData' => Pointer [Void];
        _typedef_and_export SDL_DisplayMode => Struct [
            displayID                => SDL_DisplayID(),
            format                   => SDL_PixelFormat(),
            w                        => Int,
            h                        => Int,
            pixel_density            => Float,
            refresh_rate             => Float,
            refresh_rate_numerator   => Int,
            refresh_rate_denominator => Int,
            internal                 => Pointer [ SDL_DisplayModeData() ]
        ];
        _enum_and_export SDL_DisplayOrientation => [
            'SDL_ORIENTATION_UNKNOWN', 'SDL_ORIENTATION_LANDSCAPE', 'SDL_ORIENTATION_LANDSCAPE_FLIPPED', 'SDL_ORIENTATION_PORTRAIT',
            'SDL_ORIENTATION_PORTRAIT_FLIPPED'
        ];
        _typedef_and_export SDL_Window => Void;    # opaque

        #
        _typedef_and_export SDL_WindowFlags => UInt64;
        _const_and_export SDL_WINDOW_FULLSCREEN          => 0x0000000000000001;
        _const_and_export SDL_WINDOW_OPENGL              => 0x0000000000000002;
        _const_and_export SDL_WINDOW_OCCLUDED            => 0x0000000000000004;
        _const_and_export SDL_WINDOW_HIDDEN              => 0x0000000000000008;
        _const_and_export SDL_WINDOW_BORDERLESS          => 0x0000000000000010;
        _const_and_export SDL_WINDOW_RESIZABLE           => 0x0000000000000020;
        _const_and_export SDL_WINDOW_MINIMIZED           => 0x0000000000000040;
        _const_and_export SDL_WINDOW_MAXIMIZED           => 0x0000000000000080;
        _const_and_export SDL_WINDOW_MOUSE_GRABBED       => 0x0000000000000100;
        _const_and_export SDL_WINDOW_INPUT_FOCUS         => 0x0000000000000200;
        _const_and_export SDL_WINDOW_MOUSE_FOCUS         => 0x0000000000000400;
        _const_and_export SDL_WINDOW_EXTERNAL            => 0x0000000000000800;
        _const_and_export SDL_WINDOW_MODAL               => 0x0000000000001000;
        _const_and_export SDL_WINDOW_HIGH_PIXEL_DENSITY  => 0x0000000000002000;
        _const_and_export SDL_WINDOW_MOUSE_CAPTURE       => 0x0000000000004000;
        _const_and_export SDL_WINDOW_MOUSE_RELATIVE_MODE => 0x0000000000008000;
        _const_and_export SDL_WINDOW_ALWAYS_ON_TOP       => 0x0000000000010000;
        _const_and_export SDL_WINDOW_UTILITY             => 0x0000000000020000;
        _const_and_export SDL_WINDOW_TOOLTIP             => 0x0000000000040000;
        _const_and_export SDL_WINDOW_POPUP_MENU          => 0x0000000000080000;
        _const_and_export SDL_WINDOW_KEYBOARD_GRABBED    => 0x0000000000100000;
        _const_and_export SDL_WINDOW_VULKAN              => 0x0000000010000000;
        _const_and_export SDL_WINDOW_METAL               => 0x0000000020000000;
        _const_and_export SDL_WINDOW_TRANSPARENT         => 0x0000000040000000;
        _const_and_export SDL_WINDOW_NOT_FOCUSABLE       => 0x0000000080000000;
        #
        _const_and_export SDL_WINDOWPOS_UNDEFINED_MASK => 0x1FFF0000;
        _func_and_export( SDL_WINDOWPOS_UNDEFINED_DISPLAY => sub ($X) { ( SDL_WINDOWPOS_UNDEFINED_MASK() | ($X) ) } );
        _const_and_export SDL_WINDOWPOS_UNDEFINED => SDL_WINDOWPOS_UNDEFINED_DISPLAY(0);
        _func_and_export( SDL_WINDOWPOS_ISUNDEFINED => sub ($X) { ( ( ($X) & 0xFFFF0000 ) == SDL_WINDOWPOS_UNDEFINED_MASK() ) } );
        _const_and_export SDL_WINDOWPOS_CENTERED_MASK => 0x2FFF0000;
        _func_and_export( SDL_WINDOWPOS_CENTERED_DISPLAY => sub ($X) { ( SDL_WINDOWPOS_CENTERED_MASK() | ($X) ) } );
        _const_and_export SDL_WINDOWPOS_CENTERED => SDL_WINDOWPOS_CENTERED_DISPLAY(0);
        _func_and_export( SDL_WINDOWPOS_ISCENTERED => sub ($X) { ( ( ($X) & 0xFFFF0000 ) == SDL_WINDOWPOS_CENTERED_MASK() ) } );
        #
        _enum_and_export SDL_FlashOperation => [qw[SDL_FLASH_CANCEL SDL_FLASH_BRIEFLY SDL_FLASH_UNTIL_FOCUSED]];
        #
        _enum_and_export SDL_ProgressState => [
            [ SDL_PROGRESS_STATE_INVALID => -1 ], qw[SDL_PROGRESS_STATE_NONE SDL_PROGRESS_STATE_INDETERMINATE SDL_PROGRESS_STATE_NORMAL
                SDL_PROGRESS_STATE_PAUSED SDL_PROGRESS_STATE_ERROR]
        ];

        # Defined in src\video\openvr\SDL_openvrvideo.c as
        # struct SDL_GLContextState {
        #     HGLRC hglrc;
        # };
        _typedef_and_export SDL_GLContextState         => Struct [ hglrc => Pointer [Void] ];
        _typedef_and_export SDL_GLContext              => Pointer [ SDL_GLContextState() ];
        _typedef_and_export SDL_EGLDisplay             => Pointer [Void];
        _typedef_and_export SDL_EGLConfig              => Pointer [Void];
        _typedef_and_export SDL_EGLSurface             => Pointer [Void];
        _typedef_and_export SDL_EGLAttrib              => Pointer [Void];
        _typedef_and_export SDL_EGLint                 => Int;
        _typedef_and_export SDL_EGLAttribArrayCallback => Callback [ [ Pointer [Void] ]                                    => SDL_EGLAttrib() ];
        _typedef_and_export SDL_EGLIntArrayCallback    => Callback [ [ Pointer [Void], SDL_EGLDisplay(), SDL_EGLConfig() ] => SDL_EGLint() ];
        _enum_and_export SDL_GLAttr => [
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
                SDL_GL_CONTEXT_FLAGS
                SDL_GL_CONTEXT_PROFILE_MASK
                SDL_GL_SHARE_WITH_CURRENT_CONTEXT
                SDL_GL_FRAMEBUFFER_SRGB_CAPABLE
                SDL_GL_CONTEXT_RELEASE_BEHAVIOR
                SDL_GL_CONTEXT_RESET_NOTIFICATION
                SDL_GL_CONTEXT_NO_ERROR
                SDL_GL_FLOATBUFFERS
                SDL_GL_EGL_PLATFORM
            ]
        ];
        #
        _typedef_and_export SDL_GLProfile => UInt32;
        _const_and_export SDL_GL_CONTEXT_PROFILE_CORE          => 0x0001;
        _const_and_export SDL_GL_CONTEXT_PROFILE_COMPATIBILITY => 0x0002;
        _const_and_export SDL_GL_CONTEXT_PROFILE_ES            => 0x0004;
        #
        _typedef_and_export SDL_GLContextFlag => UInt32;
        _const_and_export SDL_GL_CONTEXT_DEBUG_FLAG              => 0x0001;
        _const_and_export SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG => 0x0002;
        _const_and_export SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG      => 0x0004;
        _const_and_export SDL_GL_CONTEXT_RESET_ISOLATION_FLAG    => 0x0008;
        #
        _typedef_and_export SDL_GLContextReleaseFlag => UInt32;
        _const_and_export SDL_GL_CONTEXT_RELEASE_BEHAVIOR_NONE  => 0x0000;
        _const_and_export SDL_GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH => 0x0001;
        #
        _typedef_and_export SDL_GLContextResetNotification => UInt32;
        _const_and_export SDL_GL_CONTEXT_RESET_NO_NOTIFICATION => 0x0000;
        _const_and_export SDL_GL_CONTEXT_RESET_LOSE_CONTEXT    => 0x0001;
        #
        _affix_and_export SDL_GetNumVideoDrivers    => [], Int;
        _affix_and_export SDL_GetVideoDriver        => [Int], String;
        _affix_and_export SDL_GetCurrentVideoDriver => [], String;
        _affix_and_export SDL_GetSystemTheme        => [], SDL_SystemTheme();
        _affix_and_export SDL_GetDisplays           => [ Pointer [Int] ], Pointer [ SDL_DisplayID() ];
        _affix_and_export SDL_GetPrimaryDisplay     => [], SDL_DisplayID();
        #
        _affix_and_export SDL_GetDisplayProperties => [ SDL_DisplayID() ], SDL_PropertiesID();
        _const_and_export SDL_PROP_DISPLAY_HDR_ENABLED_BOOLEAN             => 'SDL.display.HDR_enabled';
        _const_and_export SDL_PROP_DISPLAY_KMSDRM_PANEL_ORIENTATION_NUMBER => 'SDL.display.KMSDRM.panel_orientation';
        _const_and_export SDL_PROP_DISPLAY_WAYLAND_WL_OUTPUT_POINTER       => 'SDL.display.wayland.wl_output';
        _const_and_export SDL_PROP_DISPLAY_WINDOWS_HMONITOR_POINTER        => 'SDL.display.windows.hmonitor';
        #
        _affix_and_export SDL_GetDisplayName                  => [ SDL_DisplayID() ], String;
        _affix_and_export SDL_GetDisplayBounds                => [ SDL_DisplayID(), Pointer [ SDL_Rect() ] ], Bool;
        _affix_and_export SDL_GetDisplayUsableBounds          => [ SDL_DisplayID(), Pointer [ SDL_Rect() ] ], Bool;
        _affix_and_export SDL_GetNaturalDisplayOrientation    => [ SDL_DisplayID() ], SDL_DisplayOrientation();
        _affix_and_export SDL_GetCurrentDisplayOrientation    => [ SDL_DisplayID() ], SDL_DisplayOrientation();
        _affix_and_export SDL_GetDisplayContentScale          => [ SDL_DisplayID() ], Float;
        _affix_and_export SDL_GetFullscreenDisplayModes       => [ SDL_DisplayID(), Pointer [Int] ], Pointer [ Pointer [ SDL_DisplayMode() ] ];
        _affix_and_export SDL_GetClosestFullscreenDisplayMode => [ SDL_DisplayID(), Int, Int, Float, Bool, SDL_DisplayMode() ], Bool;
        _affix_and_export SDL_GetDesktopDisplayMode           => [ SDL_DisplayID() ], Pointer [ SDL_DisplayMode() ];
        _affix_and_export SDL_GetCurrentDisplayMode           => [ SDL_DisplayID() ], Pointer [ SDL_DisplayMode() ];
        _affix_and_export SDL_GetDisplayForPoint              => [ Pointer [ SDL_Point() ] ],  SDL_DisplayID();
        _affix_and_export SDL_GetDisplayForRect               => [ Pointer [ SDL_Point() ] ],  SDL_DisplayID();
        _affix_and_export SDL_GetDisplayForWindow             => [ Pointer [ SDL_Window() ] ], SDL_DisplayID();
        _affix_and_export SDL_GetWindowPixelDensity           => [ Pointer [ SDL_Window() ] ], Float;
        _affix_and_export SDL_GetWindowDisplayScale           => [ Pointer [ SDL_Window() ] ], Float;
        _affix_and_export SDL_SetWindowFullscreenMode         => [ Pointer [ SDL_Window() ], Pointer [ SDL_DisplayMode() ] ], Bool;
        _affix_and_export SDL_GetWindowFullscreenMode         => [ Pointer [ SDL_Window() ] ], Pointer [ SDL_DisplayMode() ];
        _affix_and_export SDL_GetWindowICCProfile             => [ Pointer [ SDL_Window() ], Pointer [Size_t] ], Pointer [Void];
        _affix_and_export SDL_GetWindowPixelFormat            => [ Pointer [ SDL_Window() ] ], SDL_PixelFormat();
        _affix_and_export SDL_GetWindows                      => [ Pointer [Int] ], Pointer [ Pointer [ SDL_Window() ] ];
        _affix_and_export SDL_CreateWindow                    => [ String, Int, Int, SDL_WindowFlags() ], Pointer [ SDL_Window() ];
        _affix_and_export SDL_CreatePopupWindow => [ Pointer [ SDL_Window() ], Int, Int, Int, Int, SDL_WindowFlags() ], Pointer [ SDL_Window() ];
        _affix_and_export SDL_CreateWindowWithProperties => [ SDL_PropertiesID() ], Pointer [ SDL_Window() ];
        #
        _affix_and_export SDL_GetWindowID         => [ Pointer [ SDL_Window() ] ], SDL_WindowID();
        _affix_and_export SDL_GetWindowFromID     => [ SDL_WindowID() ], Pointer [ SDL_Window() ];
        _affix_and_export SDL_GetWindowParent     => [ Pointer [ SDL_Window() ] ], Pointer [ SDL_Window() ];
        _affix_and_export SDL_GetWindowProperties => [ Pointer [ SDL_Window() ] ], SDL_PropertiesID();
        #
        _const_and_export SDL_PROP_WINDOW_CREATE_ALWAYS_ON_TOP_BOOLEAN               => 'SDL.window.create.always_on_top';
        _const_and_export SDL_PROP_WINDOW_CREATE_BORDERLESS_BOOLEAN                  => 'SDL.window.create.borderless';
        _const_and_export SDL_PROP_WINDOW_CREATE_CONSTRAIN_POPUP_BOOLEAN             => 'SDL.window.create.constrain_popup';
        _const_and_export SDL_PROP_WINDOW_CREATE_FOCUSABLE_BOOLEAN                   => 'SDL.window.create.focusable';
        _const_and_export SDL_PROP_WINDOW_CREATE_EXTERNAL_GRAPHICS_CONTEXT_BOOLEAN   => 'SDL.window.create.external_graphics_context';
        _const_and_export SDL_PROP_WINDOW_CREATE_FLAGS_NUMBER                        => 'SDL.window.create.flags';
        _const_and_export SDL_PROP_WINDOW_CREATE_FULLSCREEN_BOOLEAN                  => 'SDL.window.create.fullscreen';
        _const_and_export SDL_PROP_WINDOW_CREATE_HEIGHT_NUMBER                       => 'SDL.window.create.height';
        _const_and_export SDL_PROP_WINDOW_CREATE_HIDDEN_BOOLEAN                      => 'SDL.window.create.hidden';
        _const_and_export SDL_PROP_WINDOW_CREATE_HIGH_PIXEL_DENSITY_BOOLEAN          => 'SDL.window.create.high_pixel_density';
        _const_and_export SDL_PROP_WINDOW_CREATE_MAXIMIZED_BOOLEAN                   => 'SDL.window.create.maximized';
        _const_and_export SDL_PROP_WINDOW_CREATE_MENU_BOOLEAN                        => 'SDL.window.create.menu';
        _const_and_export SDL_PROP_WINDOW_CREATE_METAL_BOOLEAN                       => 'SDL.window.create.metal';
        _const_and_export SDL_PROP_WINDOW_CREATE_MINIMIZED_BOOLEAN                   => 'SDL.window.create.minimized';
        _const_and_export SDL_PROP_WINDOW_CREATE_MODAL_BOOLEAN                       => 'SDL.window.create.modal';
        _const_and_export SDL_PROP_WINDOW_CREATE_MOUSE_GRABBED_BOOLEAN               => 'SDL.window.create.mouse_grabbed';
        _const_and_export SDL_PROP_WINDOW_CREATE_OPENGL_BOOLEAN                      => 'SDL.window.create.opengl';
        _const_and_export SDL_PROP_WINDOW_CREATE_PARENT_POINTER                      => 'SDL.window.create.parent';
        _const_and_export SDL_PROP_WINDOW_CREATE_RESIZABLE_BOOLEAN                   => 'SDL.window.create.resizable';
        _const_and_export SDL_PROP_WINDOW_CREATE_TITLE_STRING                        => 'SDL.window.create.title';
        _const_and_export SDL_PROP_WINDOW_CREATE_TRANSPARENT_BOOLEAN                 => 'SDL.window.create.transparent';
        _const_and_export SDL_PROP_WINDOW_CREATE_TOOLTIP_BOOLEAN                     => 'SDL.window.create.tooltip';
        _const_and_export SDL_PROP_WINDOW_CREATE_UTILITY_BOOLEAN                     => 'SDL.window.create.utility';
        _const_and_export SDL_PROP_WINDOW_CREATE_VULKAN_BOOLEAN                      => 'SDL.window.create.vulkan';
        _const_and_export SDL_PROP_WINDOW_CREATE_WIDTH_NUMBER                        => 'SDL.window.create.width';
        _const_and_export SDL_PROP_WINDOW_CREATE_X_NUMBER                            => 'SDL.window.create.x';
        _const_and_export SDL_PROP_WINDOW_CREATE_Y_NUMBER                            => 'SDL.window.create.y';
        _const_and_export SDL_PROP_WINDOW_CREATE_COCOA_WINDOW_POINTER                => 'SDL.window.create.cocoa.window';
        _const_and_export SDL_PROP_WINDOW_CREATE_COCOA_VIEW_POINTER                  => 'SDL.window.create.cocoa.view';
        _const_and_export SDL_PROP_WINDOW_CREATE_WINDOWSCENE_POINTER                 => 'SDL.window.create.uikit.windowscene';
        _const_and_export SDL_PROP_WINDOW_CREATE_WAYLAND_SURFACE_ROLE_CUSTOM_BOOLEAN => 'SDL.window.create.wayland.surface_role_custom';
        _const_and_export SDL_PROP_WINDOW_CREATE_WAYLAND_CREATE_EGL_WINDOW_BOOLEAN   => 'SDL.window.create.wayland.create_egl_window';
        _const_and_export SDL_PROP_WINDOW_CREATE_WAYLAND_WL_SURFACE_POINTER          => 'SDL.window.create.wayland.wl_surface';
        _const_and_export SDL_PROP_WINDOW_CREATE_WIN32_HWND_POINTER                  => 'SDL.window.create.win32.hwnd';
        _const_and_export SDL_PROP_WINDOW_CREATE_WIN32_PIXEL_FORMAT_HWND_POINTER     => 'SDL.window.create.win32.pixel_format_hwnd';
        _const_and_export SDL_PROP_WINDOW_CREATE_X11_WINDOW_NUMBER                   => 'SDL.window.create.x11.window';
        _const_and_export SDL_PROP_WINDOW_CREATE_EMSCRIPTEN_CANVAS_ID_STRING         => 'SDL.window.create.emscripten.canvas_id';
        _const_and_export SDL_PROP_WINDOW_CREATE_EMSCRIPTEN_FILL_DOCUMENT_BOOLEAN    => 'SDL.window.create.emscripten.fill_document';
        _const_and_export SDL_PROP_WINDOW_CREATE_EMSCRIPTEN_KEYBOARD_ELEMENT_STRING  => 'SDL.window.create.emscripten.keyboard_element';
        #
        _const_and_export SDL_PROP_WINDOW_SHAPE_POINTER                             => 'SDL.window.shape';
        _const_and_export SDL_PROP_WINDOW_HDR_ENABLED_BOOLEAN                       => 'SDL.window.HDR_enabled';
        _const_and_export SDL_PROP_WINDOW_SDR_WHITE_LEVEL_FLOAT                     => 'SDL.window.SDR_white_level';
        _const_and_export SDL_PROP_WINDOW_HDR_HEADROOM_FLOAT                        => 'SDL.window.HDR_headroom';
        _const_and_export SDL_PROP_WINDOW_ANDROID_WINDOW_POINTER                    => 'SDL.window.android.window';
        _const_and_export SDL_PROP_WINDOW_ANDROID_SURFACE_POINTER                   => 'SDL.window.android.surface';
        _const_and_export SDL_PROP_WINDOW_UIKIT_WINDOW_POINTER                      => 'SDL.window.uikit.window';
        _const_and_export SDL_PROP_WINDOW_UIKIT_METAL_VIEW_TAG_NUMBER               => 'SDL.window.uikit.metal_view_tag';
        _const_and_export SDL_PROP_WINDOW_UIKIT_OPENGL_FRAMEBUFFER_NUMBER           => 'SDL.window.uikit.opengl.framebuffer';
        _const_and_export SDL_PROP_WINDOW_UIKIT_OPENGL_RENDERBUFFER_NUMBER          => 'SDL.window.uikit.opengl.renderbuffer';
        _const_and_export SDL_PROP_WINDOW_UIKIT_OPENGL_RESOLVE_FRAMEBUFFER_NUMBER   => 'SDL.window.uikit.opengl.resolve_framebuffer';
        _const_and_export SDL_PROP_WINDOW_KMSDRM_DEVICE_INDEX_NUMBER                => 'SDL.window.kmsdrm.dev_index';
        _const_and_export SDL_PROP_WINDOW_KMSDRM_DRM_FD_NUMBER                      => 'SDL.window.kmsdrm.drm_fd';
        _const_and_export SDL_PROP_WINDOW_KMSDRM_GBM_DEVICE_POINTER                 => 'SDL.window.kmsdrm.gbm_dev';
        _const_and_export SDL_PROP_WINDOW_COCOA_WINDOW_POINTER                      => 'SDL.window.cocoa.window';
        _const_and_export SDL_PROP_WINDOW_COCOA_METAL_VIEW_TAG_NUMBER               => 'SDL.window.cocoa.metal_view_tag';
        _const_and_export SDL_PROP_WINDOW_OPENVR_OVERLAY_ID_NUMBER                  => 'SDL.window.openvr.overlay_id';
        _const_and_export SDL_PROP_WINDOW_VIVANTE_DISPLAY_POINTER                   => 'SDL.window.vivante.display';
        _const_and_export SDL_PROP_WINDOW_VIVANTE_WINDOW_POINTER                    => 'SDL.window.vivante.window';
        _const_and_export SDL_PROP_WINDOW_VIVANTE_SURFACE_POINTER                   => 'SDL.window.vivante.surface';
        _const_and_export SDL_PROP_WINDOW_WIN32_HWND_POINTER                        => 'SDL.window.win32.hwnd';
        _const_and_export SDL_PROP_WINDOW_WIN32_HDC_POINTER                         => 'SDL.window.win32.hdc';
        _const_and_export SDL_PROP_WINDOW_WIN32_INSTANCE_POINTER                    => 'SDL.window.win32.instance';
        _const_and_export SDL_PROP_WINDOW_WAYLAND_DISPLAY_POINTER                   => 'SDL.window.wayland.display';
        _const_and_export SDL_PROP_WINDOW_WAYLAND_SURFACE_POINTER                   => 'SDL.window.wayland.surface';
        _const_and_export SDL_PROP_WINDOW_WAYLAND_VIEWPORT_POINTER                  => 'SDL.window.wayland.viewport';
        _const_and_export SDL_PROP_WINDOW_WAYLAND_EGL_WINDOW_POINTER                => 'SDL.window.wayland.egl_window';
        _const_and_export SDL_PROP_WINDOW_WAYLAND_XDG_SURFACE_POINTER               => 'SDL.window.wayland.xdg_surface';
        _const_and_export SDL_PROP_WINDOW_WAYLAND_XDG_TOPLEVEL_POINTER              => 'SDL.window.wayland.xdg_toplevel';
        _const_and_export SDL_PROP_WINDOW_WAYLAND_XDG_TOPLEVEL_EXPORT_HANDLE_STRING => 'SDL.window.wayland.xdg_toplevel_export_handle';
        _const_and_export SDL_PROP_WINDOW_WAYLAND_XDG_POPUP_POINTER                 => 'SDL.window.wayland.xdg_popup';
        _const_and_export SDL_PROP_WINDOW_WAYLAND_XDG_POSITIONER_POINTER            => 'SDL.window.wayland.xdg_positioner';
        _const_and_export SDL_PROP_WINDOW_X11_DISPLAY_POINTER                       => 'SDL.window.x11.display';
        _const_and_export SDL_PROP_WINDOW_X11_SCREEN_NUMBER                         => 'SDL.window.x11.screen';
        _const_and_export SDL_PROP_WINDOW_X11_WINDOW_NUMBER                         => 'SDL.window.x11.window';
        _const_and_export SDL_PROP_WINDOW_EMSCRIPTEN_CANVAS_ID_STRING               => 'SDL.window.emscripten.canvas_id';
        _const_and_export SDL_PROP_WINDOW_EMSCRIPTEN_FILL_DOCUMENT_BOOLEAN          => 'SDL.window.emscripten.fill_document';
        _const_and_export SDL_PROP_WINDOW_EMSCRIPTEN_KEYBOARD_ELEMENT_STRING        => 'SDL.window.emscripten.keyboard_element';
        #
        _affix_and_export SDL_GetWindowFlags        => [ Pointer [ SDL_Window() ] ], SDL_WindowFlags();
        _affix_and_export SDL_SetWindowTitle        => [ Pointer [ SDL_Window() ], String ], Bool;
        _affix_and_export SDL_GetWindowTitle        => [ Pointer [ SDL_Window() ] ], String;
        _affix_and_export SDL_SetWindowIcon         => [ Pointer [ SDL_Window() ], Pointer [ SDL_Surface() ] ], Bool;
        _affix_and_export SDL_SetWindowPosition     => [ Pointer [ SDL_Window() ], Int, Int ], Bool;
        _affix_and_export SDL_GetWindowPosition     => [ Pointer [ SDL_Window() ], Pointer [Int], Pointer [Int] ], Bool;
        _affix_and_export SDL_SetWindowSize         => [ Pointer [ SDL_Window() ], Int, Int, ], Bool;
        _affix_and_export SDL_GetWindowSize         => [ Pointer [ SDL_Window() ], Pointer [Int], Pointer [Int] ], Bool;
        _affix_and_export SDL_GetWindowSafeArea     => [ Pointer [ SDL_Window() ], Pointer [ SDL_Rect() ] ], Bool;
        _affix_and_export SDL_SetWindowAspectRatio  => [ Pointer [ SDL_Window() ], Float, Float ], Bool;
        _affix_and_export SDL_GetWindowAspectRatio  => [ Pointer [ SDL_Window() ], Pointer [Float], Pointer [Float] ], Bool;
        _affix_and_export SDL_GetWindowBordersSize  => [ Pointer [ SDL_Window() ], Pointer [Int], Pointer [Int], Pointer [Int], Pointer [Int] ], Bool;
        _affix_and_export SDL_GetWindowSizeInPixels => [ Pointer [ SDL_Window() ], Pointer [Int], Pointer [Int] ], Bool;
        _affix_and_export SDL_SetWindowMinimumSize  => [ Pointer [ SDL_Window() ], Int, Int ], Bool;
        _affix_and_export SDL_GetWindowMinimumSize  => [ Pointer [ SDL_Window() ], Pointer [Int], Pointer [Int] ], Bool;
        _affix_and_export SDL_SetWindowMaximumSize  => [ Pointer [ SDL_Window() ], Int, Int ], Bool;
        _affix_and_export SDL_GetWindowMaximumSize  => [ Pointer [ SDL_Window() ], Pointer [Int], Pointer [Int] ], Bool;
        _affix_and_export SDL_SetWindowBordered     => [ Pointer [ SDL_Window() ], Bool ], Bool;
        _affix_and_export SDL_SetWindowResizable    => [ Pointer [ SDL_Window() ], Bool ], Bool;
        _affix_and_export SDL_SetWindowAlwaysOnTop  => [ Pointer [ SDL_Window() ], Bool ], Bool;
        _affix_and_export SDL_ShowWindow            => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_HideWindow            => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_RaiseWindow           => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_MaximizeWindow        => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_MinimizeWindow        => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_RestoreWindow         => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_SetWindowFullscreen   => [ Pointer [ SDL_Window() ], Bool ], Bool;
        _affix_and_export SDL_SyncWindow            => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_WindowHasSurface      => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_GetWindowSurface      => [ Pointer [ SDL_Window() ] ], Pointer [ SDL_Surface() ];
        _affix_and_export SDL_SetWindowSurfaceVSync => [ Pointer [ SDL_Window() ], Int ], Bool;
        #
        _const_and_export SDL_WINDOW_SURFACE_VSYNC_DISABLED => 0;
        _const_and_export SDL_WINDOW_SURFACE_VSYNC_ADAPTIVE => (-1);
        #
        _affix_and_export SDL_GetWindowSurfaceVSync    => [ Pointer [ SDL_Window() ], Pointer [Int] ], Bool;
        _affix_and_export SDL_UpdateWindowSurface      => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_UpdateWindowSurfaceRects => [ Pointer [ SDL_Window() ], Pointer [ SDL_Rect() ], Int ], Bool;
        _affix_and_export SDL_DestroyWindowSurface     => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_SetWindowKeyboardGrab    => [ Pointer [ SDL_Window() ], Bool ], Bool;
        _affix_and_export SDL_SetWindowMouseGrab       => [ Pointer [ SDL_Window() ], Bool ], Bool;
        _affix_and_export SDL_GetWindowKeyboardGrab    => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_GetWindowMouseGrab       => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_GetGrabbedWindow         => [], Pointer [ SDL_Window() ];
        _affix_and_export SDL_SetWindowMouseRect       => [ Pointer [ SDL_Window() ], Pointer [ SDL_Rect() ] ], Bool;
        _affix_and_export SDL_GetWindowMouseRect       => [ Pointer [ SDL_Window() ] ], Pointer [ SDL_Rect() ];
        _affix_and_export SDL_SetWindowOpacity         => [ Pointer [ SDL_Window() ], Float ], Bool;
        _affix_and_export SDL_GetWindowOpacity         => [ Pointer [ SDL_Window() ] ], Float;
        _affix_and_export SDL_SetWindowParent          => [ Pointer [ SDL_Window() ], Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_SetWindowModal           => [ Pointer [ SDL_Window() ], Bool ], Bool;
        _affix_and_export SDL_SetWindowFocusable       => [ Pointer [ SDL_Window() ], Bool ], Bool;
        _affix_and_export SDL_ShowWindowSystemMenu     => [ Pointer [ SDL_Window() ], Int, Int ], Bool;
        #
        _enum_and_export SDL_HitTestResult => [
            qw[
                SDL_HITTEST_NORMAL              SDL_HITTEST_DRAGGABLE
                SDL_HITTEST_RESIZE_TOPLEFT      SDL_HITTEST_RESIZE_TOP      SDL_HITTEST_RESIZE_TOPRIGHT     SDL_HITTEST_RESIZE_RIGHT
                SDL_HITTEST_RESIZE_BOTTOMRIGHT  SDL_HITTEST_RESIZE_BOTTOM   SDL_HITTEST_RESIZE_BOTTOMLEFT   SDL_HITTEST_RESIZE_LEFT
            ]
        ];
        #
        _typedef_and_export SDL_HitTest => Callback [ [ Pointer [ SDL_Window() ], Pointer [ SDL_Point() ], Pointer [Void] ] => SDL_HitTestResult() ];
        _affix_and_export SDL_SetWindowHitTest => [ Pointer [ SDL_Window() ], SDL_HitTest(), Pointer [Void] ], Bool;
        _affix_and_export SDL_SetWindowShape   => [ Pointer [ SDL_Window() ], Pointer [ SDL_Surface() ] ], Bool;
        _affix_and_export SDL_FlashWindow      => [ Pointer [ SDL_Window() ], SDL_FlashOperation() ], Bool;

        #~ _affix_and_export SDL_SetWindowProgressState => [ Pointer [ SDL_Window() ], SDL_ProgressState() ],  Bool;
        #~ _affix_and_export SDL_GetWindowProgressState => [ Pointer [ SDL_Window() ] ], SDL_ProgressState();
        #~ _affix_and_export SDL_SetWindowProgressValue => [ Pointer [ SDL_Window() ], Float ], Bool;
        #~ _affix_and_export SDL_GetWindowProgressValue => [ Pointer [ SDL_Window() ] ], Float;
        _affix_and_export SDL_DestroyWindow         => [ Pointer [ SDL_Window() ] ], Void;
        _affix_and_export SDL_ScreenSaverEnabled    => [], Bool;
        _affix_and_export SDL_EnableScreenSaver     => [], Bool;
        _affix_and_export SDL_DisableScreenSaver    => [], Bool;
        _affix_and_export SDL_GL_LoadLibrary        => [String], Bool;
        _affix_and_export SDL_GL_GetProcAddress     => [String], SDL_FunctionPointer();
        _affix_and_export SDL_EGL_GetProcAddress    => [String], SDL_FunctionPointer();
        _affix_and_export SDL_GL_UnloadLibrary      => [], Void;
        _affix_and_export SDL_GL_ExtensionSupported => [String], Bool;
        _affix_and_export SDL_GL_ResetAttributes    => [], Void;
        _affix_and_export SDL_GL_SetAttribute       => [ SDL_GLAttr() ], Bool;
        _affix_and_export SDL_GL_GetAttribute       => [ SDL_GLAttr(), Pointer [Int] ], Bool;
        _affix_and_export SDL_GL_CreateContext      => [ Pointer [ SDL_Window() ] ], SDL_GLContext();
        _affix_and_export SDL_GL_MakeCurrent        => [ Pointer [ SDL_Window(), SDL_GLContext() ] ], Bool;
        _affix_and_export SDL_GL_GetCurrentWindow   => [], Pointer [ SDL_Window() ];
        _affix_and_export SDL_GL_GetCurrentContext  => [], SDL_GLContext();
        _affix_and_export SDL_EGL_GetCurrentDisplay => [], SDL_EGLDisplay();
        _affix_and_export SDL_EGL_GetCurrentConfig  => [], SDL_EGLConfig();
        _affix_and_export SDL_EGL_GetWindowSurface  => [ Pointer [ SDL_Window() ] ], SDL_EGLSurface();
        _affix_and_export
            SDL_EGL_SetAttributeCallbacks => [ SDL_EGLAttribArrayCallback(), SDL_EGLIntArrayCallback(), SDL_EGLIntArrayCallback(), Pointer [Void] ],
            Void;
        _affix_and_export SDL_GL_SetSwapInterval => [Int], Bool;
        _affix_and_export SDL_GL_GetSwapInterval => [ Pointer [Int] ], Bool;
        _affix_and_export SDL_GL_SwapWindow      => [ Pointer [ SDL_Window() ] ], Bool;
        _affix_and_export SDL_GL_DestroyContext  => [ SDL_GLContext() ], Bool;
    }

=head3 C<:vulkan> - Vulkan Support

Functions for creating Vulkan surfaces on SDL windows.

See L<SDL3: CategoryVulkan|https://wiki.libsdl.org/SDL3/CategoryVulkan>

=cut

    sub _vulkan () {
        state $done++ && return;
        #
        _error();
        _stdinc();
        _video();

        # opaque pointers
        typedef VkInstance            => Pointer [Void];
        typedef VkAllocationCallbacks => Pointer [Void];
        typedef VkSurfaceKHR          => Pointer [Void];
        typedef VkPhysicalDevice      => Pointer [Void];
        #
        _affix_and_export 'SDL_Vulkan_LoadLibrary',              [String]             => Bool;
        _affix_and_export 'SDL_Vulkan_GetVkGetInstanceProcAddr', []                   => SDL_FunctionPointer();
        _affix_and_export 'SDL_Vulkan_UnloadLibrary',            []                   => Void;
        _affix_and_export 'SDL_Vulkan_GetInstanceExtensions',    [ Pointer [UInt32] ] => Pointer [String];
        _affix_and_export 'SDL_Vulkan_CreateSurface',            [ SDL_Window(), VkInstance(), VkAllocationCallbacks(), VkSurfaceKHR() ] => Bool;
        _affix_and_export 'SDL_Vulkan_DestroySurface',           [ VkInstance(), VkSurfaceKHR(), VkAllocationCallbacks() ]               => Void;
        _affix_and_export 'SDL_Vulkan_GetPresentationSupport',   [ VkInstance(), VkPhysicalDevice(), UInt32 ]                            => Bool;
    }

    END {    # For :main
        return if $? != 0;    # Don't run hook, we're crashing or exiting with an error
        $main_hook // return;
        my $SDL_AppInit    = $main_hook->can('SDL_AppInit')    // sub { SDL_Log('Missing SDL_AppInit callback for :main');    SDL_APP_FAILURE() };
        my $SDL_AppEvent   = $main_hook->can('SDL_AppEvent')   // sub { SDL_Log('Missing SDL_AppEvent callback for :main');   SDL_APP_FAILURE() };
        my $SDL_AppIterate = $main_hook->can('SDL_AppIterate') // sub { SDL_Log('Missing SDL_AppIterate callback for :main'); SDL_APP_FAILURE() };
        my $SDL_AppQuit    = $main_hook->can('SDL_AppQuit')    // sub { SDL_Log('Missing SDL_AppQuit callback for :main');    SDL_APP_FAILURE() };
        SDL_EnterAppMainCallbacks( scalar(@ARGV), \@ARGV, $SDL_AppInit, $SDL_AppIterate, $SDL_AppEvent, $SDL_AppQuit );
    }
}
1;

=head1 See Also

The project's repo: L<https://github.com/Perl-SDL3/SDL3.pm>

The SDL3 Wiki: L<https://wiki.libsdl.org/SDL3/FrontPage>

=head1 LICENSE

This software is Copyright (c) 2025 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

See the F<LICENSE> file for full text.

=head1 AUTHOR

Sanko Robinson <sanko@cpan.org>

=begin stopwords


=end stopwords

=cut
