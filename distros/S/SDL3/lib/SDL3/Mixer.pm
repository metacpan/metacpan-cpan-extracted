package SDL3::Mixer v0.0.7 {
    use v5.40;
    use base 'Exporter';
    use Affix qw[:all];
    use Alien::SDL3;
    use SDL3   qw[:all];            # Needs core types...
    use Carp   qw[confess croak];
    use Config qw[%Config];

=encoding utf-8

=head1 NAME

SDL3::Mixer - Audio File support for SDL3

=head1 SYNOPSIS

    use v5.40;
    use SDL3        qw[:all :main];
    use SDL3::Mixer qw[:all];

    #
    my ( $window, $renderer );

    #
    sub SDL_AppInit( $appstate, $argc, @argv ) {
        return SDL_APP_FAILURE unless SDL_Init(SDL_INIT_VIDEO);
        return SDL_APP_FAILURE unless SDL_CreateWindowAndRenderer( 'Doooooo', 640, 480, SDL_WINDOW_RESIZABLE, $window, $renderer );
        return SDL_APP_FAILURE unless MIX_Init();

        # Create a mixer on the default audio device. Don't care about the specific audio format.
        my $mixer = MIX_CreateMixerDevice( SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, undef ) || return SDL_APP_FAILURE;
        my $audio = MIX_CreateSineWaveAudio( $mixer, 300, 0.25, -1 )                  || return SDL_APP_FAILURE;
        my $track = MIX_CreateTrack($mixer)                                           || return SDL_APP_FAILURE;
        MIX_SetTrackAudio( $track, $audio );
        MIX_PlayTrack( $track, 0 );
        return SDL_APP_CONTINUE;
    }

    sub SDL_AppEvent( $appstate, $event ) { $event->{type} == SDL_EVENT_QUIT ? SDL_APP_SUCCESS : SDL_APP_CONTINUE }

    sub SDL_AppIterate($appstate) {    # Does nothing...
        SDL_RenderClear($renderer);
        SDL_RenderPresent($renderer);
        return SDL_APP_CONTINUE;
    }

    sub SDL_AppQuit( $appstate, $result ) { MIX_Quit() }

=head1 DESCRIPTION

C<SDL3::Mixer> is a library to make complicated audio processing tasks easier.

It offers audio file decoding, mixing multiple sounds together, basic 3D positional audio, and various audio effects.

It can mix sound to multiple audio devices in real time, or generate mixed audio data to a memory buffer for any other
use. It can do both at the same time!

To use the library, first call C<MIX_Init( )>. Then create a mixer with C<MIX_CreateMixerDevice( ... )> (or
C<MIX_CreateMixer( ... )> to render to memory).

Once you have a mixer, you can load sound data with C<MIX_LoadAudio( ... )>, C<MIX_LoadAudio_IO( ... )> , or
C<MIX_LoadAudioWithProperties( ... )>. Data gets loaded once and can be played over and over.

When loading audio, SDL_mixer can parse out several metadata tag formats, such as ID3 and APE tags, and exposes this
information through the C<MIX_GetAudioProperties( ... )> function.

To play audio, you create a track with C<MIX_CreateTrack( [...] )>. You need one track for each sound that will be
played simultaneously; think of tracks as individual sliders on a mixer board. You might have loaded hundreds of audio
files, but you probably only have a handful of tracks that you assign those loaded files to when they are ready to
play, and reuse those tracks with different audio later. Tracks take their input from a C<MIX_Audio> (static data to be
played multiple times) or an C<SDL_AudioStream> (streaming PCM audio the app supplies, possibly as needed). A third
option is to supply an C<SDL_IOStream>, to load and decode on the fly, which might be more efficient for background
music that is only used once, etc.

Assign input to a C<MIX_Track> with C<MIX_SetTrackAudio( ... )>, C<MIX_SetTrackAudioStream( ... )>, or
C<MIX_SetTrackIOStream( ... )>.

Once a track has an input, start it playing with MIX_PlayTrack(). There are many options to this function to dictate
mixing features: looping, fades, etc.

Tracks can be tagged with arbitrary strings, like "music" or "ingame" or "ui". These tags can be used to start, stop,
and pause a selection of tracks at the same moment.

All significant portions of the mixing pipeline have callbacks, so that an app can hook in to the appropriate locations
to examine or modify audio data as it passes through the mixer: a "raw" callback for raw PCM data decoded from an audio
file without any modifications, a "cooked" callback for that same data after all transformations (fade, positioning,
etc) have been processed, a "stopped" callback for when the track finishes mixing, a "postmix" callback for the final
mixed audio about to be sent to the audio hardware to play. Additionally, you can use MIX_Group objects to mix a subset
of playing tracks and access the data before it is mixed in with other tracks. All of this is optional, but allows for
powerful access and control of the mixing process.

C<SDL::Mixer> can also be used for decoding audio files without actually rendering a mix. This is done with
C<MIX_AudioDecoder>. Even though C<SDL_mixer> handles decoding transparently when used as the audio engine for an app,
and probably won't need this interface in that normal scenario, this can be useful when using a different audio library
to access many file formats.

This library offers several features on top of mixing sounds together: a track can have its own gain, to adjust its
volume, in addition to a master gain applied as well. One can set the "frequency ratio" of a track or the final mixed
output, to speed it up or slow it down, which also adjusts its pitch. A channel map can also be applied per-track, to
change what speaker a given channel of audio is output to.

Almost all timing in SDL_mixer is in sample frames. Stereo PCM audio data in Sint16 format takes 4 bytes per sample
frame (2 bytes per sample times 2 channels), for example. This allows everything in SDL_mixer to run at sample-perfect
accuracy, and it lets it run without concern for wall clock time--you can produce audio faster than real-time, if
desired. The problem, though, is different pieces of audio at different sample rates will produce a different number of
sample frames for the same length of time. To deal with this, conversion routines are offered: C<MIX_TrackMSToFrames(
... )>, C<MIX_TrackFramesToMS( ... )>, etc. Functions that operate on multiple tracks at once will deal with time in
milliseconds, so it can do these conversions internally; be sure to read the documentation for these small quirks!

C<SDL::Mixer> offers basic positional audio: a simple 3D positioning API through C<MIX_SetTrack3DPosition( ... )> and
C<MIX_SetTrackStereo( ... )>. The former will do simple distance attenuation and spatialization--on a stereo setup, you
will hear sounds move from left to right--and on a surround-sound configuration, individual tracks can move around the
user. The latter, C<MIX_SetTrackStereo( ... )>, will force a sound to the Front Left and Front Right speakers and let
the app pan it left and right as desired. Either effect can be useful for different situations. C<SDL::Mixer> is not
meant to be a full 3D audio engine, but rather Good Enough for many purposes; if something more powerful in terms of 3D
audio is needed, consider a proper 3D library like OpenAL.

There are a few examples in this distribution's C<eg/mixer> directory.

=head2 Features

Each feature listed below is a tag you may use.

=head3 C<:all> - SDL3_mixer Audio Functions

This binds all functions, defines all types, and imports them into your package.

See L<the SDL3_mixer Wiki|https://wiki.libsdl.org/SDL3_mixer/FrontPage> for documentation of the functions and types
you will have access to with this import tag.

=cut

    my $alien = Alien::SDL3->new;
    my $info  = $alien->alt('libsdl3_mixer')->package_info;
    croak 'SDL3_mixer is not installed' unless $info;
    my ($lib) = @{ $info->libfiles };
    $ENV{PATH} = join( $Config{path_sep}, ( map { @{ $_->bindirs // [] } } $info ), $ENV{PATH} // '' );
    our ( %EXPORT_TAGS, @EXPORT_OK );

    sub import ( $pkg, @wants ) {
        {
            no strict 'refs';
            (s[^:][_]r)->() for @wants;
        }
        require List::Util;
        @EXPORT_OK = sort map {@$_} values %EXPORT_TAGS;
        $EXPORT_TAGS{all} = [@EXPORT_OK];
        __PACKAGE__->export_to_level( 1, $pkg, @wants );
    }

    sub _affix_and_export ( $name, $args, $ret ) {
        my ( $n, $r ) = ref $name ? @$name : ( $name, $name );
        confess "Failed to affix $n" unless affix( $lib, $name, $args, $ret );
        push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $n;
    }

    sub _const_and_export ( $name, $value ) {
        no strict 'refs';
        *{$name} = sub () {$value};
        push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $name;
    }

    sub _func_and_export ( $name, $sub ) {
        no strict 'refs';
        *{$name} = $sub;
        push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $name;
    }

    sub _typedef_and_export ( $name, $type //= () ) {
        no strict 'refs';
        if ( defined $type ) {
            typedef $name, $type;
        }
        else {
            typedef $name;
        }
        push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $name;
    }

    sub _mixer () {
        state $done++ && return;
        _typedef_and_export MIX_Mixer        => Void;
        _typedef_and_export MIX_Audio        => Void;
        _typedef_and_export MIX_Track        => Void;
        _typedef_and_export MIX_Group        => Void;
        _typedef_and_export MIX_AudioDecoder => Void;
        _affix_and_export MIX_Version => [], Int;
        _func_and_export MIX_MAJOR_VERSION    => sub () { SDL3::SDL_VERSIONNUM_MAJOR( MIX_Version() ) };
        _func_and_export MIX_MINOR_VERSION    => sub () { SDL3::SDL_VERSIONNUM_MINOR( MIX_Version() ) };
        _func_and_export MIX_MICRO_VERSION    => sub () { SDL3::SDL_VERSIONNUM_MICRO( MIX_Version() ) };
        _func_and_export MIX_VERSION          => sub () { SDL3::SDL_VERSIONNUM( MIX_MAJOR_VERSION(), MIX_MINOR_VERSION(), MIX_MICRO_VERSION() ) };
        _func_and_export MIX_VERSIONNUM       => sub ( $major, $minor, $patch ) { ( ($major) * 1000000 + ($minor) * 1000 + ($patch) ) };
        _func_and_export MIX_VERSIONNUM_MAJOR => sub ($version) { int( ($version) / 1000000 ) };
        _func_and_export MIX_VERSIONNUM_MINOR => sub ($version) { int( ( ($version) / 1000 ) % 1000 ) };
        _func_and_export MIX_VERSIONNUM_MICRO => sub ($version) { int( ($version) % 1000 ) };
        _func_and_export MIX_VERSION_ATLEAST  => sub ( $X, $Y, $Z ) { ( MIX_VERSION() >= MIX_VERSIONNUM( $X, $Y, $Z ) ) };
        _affix_and_export MIX_Init                => [], Bool;
        _affix_and_export MIX_Quit                => [], Void;
        _affix_and_export MIX_GetNumAudioDecoders => [], Int;
        _affix_and_export MIX_GetAudioDecoder     => [Int], String;
        _affix_and_export MIX_CreateMixerDevice   => [ UInt32, Pointer [Void] ], Pointer [ MIX_Mixer() ];
        _affix_and_export MIX_CreateMixer         => [ Pointer [ SDL3::SDL_AudioSpec() ] ], Pointer [ MIX_Mixer() ];
        _affix_and_export MIX_DestroyMixer        => [ Pointer [ MIX_Mixer() ] ],           Void;
        _affix_and_export MIX_GetMixerProperties  => [ Pointer [ MIX_Mixer() ] ],           SDL3::SDL_PropertiesID();
        _const_and_export MIX_PROP_MIXER_DEVICE_NUMBER => 'SDL_mixer.mixer.device';
        _affix_and_export MIX_GetMixerFormat  => [ Pointer [ MIX_Mixer() ], Pointer [ SDL3::SDL_AudioSpec() ] ], Bool;
        _affix_and_export MIX_LockMixer       => [ Pointer [ MIX_Mixer() ] ], Void;
        _affix_and_export MIX_UnlockMixer     => [ Pointer [ MIX_Mixer() ] ], Void;
        _affix_and_export MIX_LoadAudio_IO    => [ Pointer [ MIX_Mixer() ], Pointer [ SDL3::SDL_IOStream() ], Bool, Bool ], Pointer [ MIX_Audio() ];
        _affix_and_export MIX_LoadAudio       => [ Pointer [ MIX_Mixer() ], String, Bool ], Pointer [ MIX_Audio() ];
        _affix_and_export MIX_LoadAudioNoCopy => [ Pointer [ MIX_Mixer() ], Pointer [Void], Size_t, Bool ], Pointer [ MIX_Audio() ];
        _affix_and_export MIX_LoadAudioWithProperties => [ SDL3::SDL_PropertiesID() ], Pointer [ MIX_Audio() ];
        _const_and_export MIX_PROP_AUDIO_LOAD_IOSTREAM_POINTER           => 'SDL_mixer.audio.load.iostream';
        _const_and_export MIX_PROP_AUDIO_LOAD_CLOSEIO_BOOLEAN            => 'SDL_mixer.audio.load.closeio';
        _const_and_export MIX_PROP_AUDIO_LOAD_PREDECODE_BOOLEAN          => 'SDL_mixer.audio.load.predecode';
        _const_and_export MIX_PROP_AUDIO_LOAD_PREFERRED_MIXER_POINTER    => 'SDL_mixer.audio.load.preferred_mixer';
        _const_and_export MIX_PROP_AUDIO_LOAD_SKIP_METADATA_TAGS_BOOLEAN => 'SDL_mixer.audio.load.skip_metadata_tags';
        _const_and_export MIX_PROP_AUDIO_LOAD_IGNORE_LOOPS_BOOLEAN       => 'SDL_mixer.audio.load.ignore_loops';
        _const_and_export MIX_PROP_AUDIO_DECODER_STRING                  => 'SDL_mixer.audio.decoder';
        _affix_and_export
            MIX_LoadRawAudio_IO => [ Pointer [ MIX_Mixer() ], Pointer [ SDL3::SDL_IOStream() ], Pointer [ SDL3::SDL_AudioSpec() ], Bool ],
            Pointer [ MIX_Audio() ];
        _affix_and_export
            MIX_LoadRawAudio => [ Pointer [ MIX_Mixer() ], Pointer [Void], Size_t, Pointer [ SDL3::SDL_AudioSpec() ] ],
            Pointer [ MIX_Audio() ];
        _affix_and_export
            MIX_LoadRawAudioNoCopy => [ Pointer [ MIX_Mixer() ], Pointer [Void], Size_t, Pointer [ SDL3::SDL_AudioSpec() ], Bool ],
            Pointer [ MIX_Audio() ];
        _affix_and_export MIX_CreateSineWaveAudio => [ Pointer [ MIX_Audio() ], Int, Float, SInt64 ], Pointer [ MIX_Audio() ];
        _affix_and_export MIX_GetAudioProperties => [ Pointer [ MIX_Audio() ] ], SDL3::SDL_PropertiesID();
        _const_and_export MIX_PROP_METADATA_TITLE_STRING              => 'SDL_mixer.metadata.title';
        _const_and_export MIX_PROP_METADATA_ARTIST_STRING             => 'SDL_mixer.metadata.artist';
        _const_and_export MIX_PROP_METADATA_ALBUM_STRING              => 'SDL_mixer.metadata.album';
        _const_and_export MIX_PROP_METADATA_COPYRIGHT_STRING          => 'SDL_mixer.metadata.copyright';
        _const_and_export MIX_PROP_METADATA_TRACK_NUMBER              => 'SDL_mixer.metadata.track';
        _const_and_export MIX_PROP_METADATA_TOTAL_TRACKS_NUMBER       => 'SDL_mixer.metadata.total_tracks';
        _const_and_export MIX_PROP_METADATA_YEAR_NUMBER               => 'SDL_mixer.metadata.year';
        _const_and_export MIX_PROP_METADATA_DURATION_FRAMES_NUMBER    => 'SDL_mixer.metadata.duration_frames';
        _const_and_export MIX_PROP_METADATA_DURATION_INFINITE_BOOLEAN => 'SDL_mixer.metadata.duration_infinite';
        _affix_and_export MIX_GetAudioDuration => [ Pointer [ MIX_Audio() ] ], SInt64;
        _const_and_export MIX_DURATION_UNKNOWN  => -1;
        _const_and_export MIX_DURATION_INFINITE => -2;
        _affix_and_export MIX_GetAudioFormat      => [ Pointer [ MIX_Audio() ], Pointer [ SDL3::SDL_AudioSpec() ] ], Bool;
        _affix_and_export MIX_DestroyAudio        => [ Pointer [ MIX_Audio() ] ], Void;
        _affix_and_export MIX_CreateTrack         => [ Pointer [ MIX_Mixer() ] ], Pointer [ MIX_Track() ];
        _affix_and_export MIX_DestroyTrack        => [ Pointer [ MIX_Track() ] ], Void;
        _affix_and_export MIX_GetTrackProperties  => [ Pointer [ MIX_Track() ] ], SDL3::SDL_PropertiesID();
        _affix_and_export MIX_GetTrackMixer       => [ Pointer [ MIX_Track() ] ], Pointer [ MIX_Mixer() ];
        _affix_and_export MIX_SetTrackAudio       => [ Pointer [ MIX_Track() ], Pointer [ MIX_Audio() ] ],             Bool;
        _affix_and_export MIX_SetTrackAudioStream => [ Pointer [ MIX_Track() ], Pointer [ SDL3::SDL_AudioStream() ] ], Bool;
        _affix_and_export MIX_SetTrackIOStream    => [ Pointer [ MIX_Track() ], Pointer [ SDL3::SDL_IOStream() ], Bool ], Bool;
        _affix_and_export
            MIX_SetTrackRawIOStream => [ Pointer [ MIX_Track() ], Pointer [ SDL3::SDL_IOStream() ], Pointer [ SDL3::SDL_AudioSpec() ], Bool ],
            Bool;
        _affix_and_export MIX_TagTrack                 => [ Pointer [ MIX_Track() ], String ], Bool;
        _affix_and_export MIX_UntagTrack               => [ Pointer [ MIX_Track() ], String ], Void;
        _affix_and_export MIX_GetTrackTags             => [ Pointer [ MIX_Track() ], Pointer [Int] ], Pointer [String];
        _affix_and_export MIX_GetTaggedTracks          => [ Pointer [ MIX_Mixer() ], String, Pointer [Int] ], Pointer [ Pointer [ MIX_Track() ] ];
        _affix_and_export MIX_SetTrackPlaybackPosition => [ Pointer [ MIX_Track() ], SInt64 ], Bool;
        _affix_and_export MIX_GetTrackPlaybackPosition => [ Pointer [ MIX_Track() ] ], SInt64;
        _affix_and_export MIX_GetTrackFadeFrames       => [ Pointer [ MIX_Track() ] ], SInt64;
        _affix_and_export MIX_GetTrackLoops            => [ Pointer [ MIX_Track() ] ], Int;
        _affix_and_export MIX_SetTrackLoops            => [ Pointer [ MIX_Track() ], Int ], Bool;
        _affix_and_export MIX_GetTrackAudio            => [ Pointer [ MIX_Track() ] ], Pointer [ MIX_Audio() ];
        _affix_and_export MIX_GetTrackAudioStream      => [ Pointer [ MIX_Track() ] ], Pointer [ SDL3::SDL_AudioStream() ];
        _affix_and_export MIX_GetTrackRemaining        => [ Pointer [ MIX_Track() ] ], SInt64;
        _affix_and_export MIX_TrackMSToFrames          => [ Pointer [ MIX_Track() ], SInt64 ], SInt64;
        _affix_and_export MIX_TrackFramesToMS          => [ Pointer [ MIX_Track() ], SInt64 ], SInt64;
        _affix_and_export MIX_AudioMSToFrames          => [ Pointer [ MIX_Audio() ], SInt64 ], SInt64;
        _affix_and_export MIX_AudioFramesToMS          => [ Pointer [ MIX_Audio() ], SInt64 ], SInt64;
        _affix_and_export MIX_MSToFrames               => [ Int, SInt64 ], SInt64;
        _affix_and_export MIX_FramesToMS               => [ Int, SInt64 ], SInt64;
        _affix_and_export MIX_PlayTrack                => [ Pointer [ MIX_Track() ], SDL3::SDL_PropertiesID() ], Bool;
        _const_and_export MIX_PROP_PLAY_LOOPS_NUMBER                       => 'SDL_mixer.play.loops';
        _const_and_export MIX_PROP_PLAY_MAX_FRAME_NUMBER                   => 'SDL_mixer.play.max_frame';
        _const_and_export MIX_PROP_PLAY_MAX_MILLISECONDS_NUMBER            => 'SDL_mixer.play.max_milliseconds';
        _const_and_export MIX_PROP_PLAY_START_FRAME_NUMBER                 => 'SDL_mixer.play.start_frame';
        _const_and_export MIX_PROP_PLAY_START_MILLISECOND_NUMBER           => 'SDL_mixer.play.start_millisecond';
        _const_and_export MIX_PROP_PLAY_START_ORDER_NUMBER                 => 'SDL_mixer.play.start_order';
        _const_and_export MIX_PROP_PLAY_LOOP_START_FRAME_NUMBER            => 'SDL_mixer.play.loop_start_frame';
        _const_and_export MIX_PROP_PLAY_LOOP_START_MILLISECOND_NUMBER      => 'SDL_mixer.play.loop_start_millisecond';
        _const_and_export MIX_PROP_PLAY_FADE_IN_FRAMES_NUMBER              => 'SDL_mixer.play.fade_in_frames';
        _const_and_export MIX_PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER        => 'SDL_mixer.play.fade_in_milliseconds';
        _const_and_export MIX_PROP_PLAY_FADE_IN_START_GAIN_FLOAT           => 'SDL_mixer.play.fade_in_start_gain';
        _const_and_export MIX_PROP_PLAY_APPEND_SILENCE_FRAMES_NUMBER       => 'SDL_mixer.play.append_silence_frames';
        _const_and_export MIX_PROP_PLAY_APPEND_SILENCE_MILLISECONDS_NUMBER => 'SDL_mixer.play.append_silence_milliseconds';
        _const_and_export MIX_PROP_PLAY_HALT_WHEN_EXHAUSTED_BOOLEAN        => 'SDL_mixer.play.halt_when_exhausted';
        _affix_and_export MIX_PlayTag                  => [ Pointer [ MIX_Mixer() ], String, SDL3::SDL_PropertiesID() ], Bool;
        _affix_and_export MIX_PlayAudio                => [ Pointer [ MIX_Mixer() ], Pointer [ MIX_Audio() ] ], Bool;
        _affix_and_export MIX_StopTrack                => [ Pointer [ MIX_Track() ], SInt64 ], Bool;
        _affix_and_export MIX_StopAllTracks            => [ Pointer [ MIX_Mixer() ], SInt64 ], Bool;
        _affix_and_export MIX_StopTag                  => [ Pointer [ MIX_Mixer() ], String, SInt64 ], Bool;
        _affix_and_export MIX_PauseTrack               => [ Pointer [ MIX_Track() ] ], Bool;
        _affix_and_export MIX_PauseAllTracks           => [ Pointer [ MIX_Mixer() ] ], Bool;
        _affix_and_export MIX_PauseTag                 => [ Pointer [ MIX_Mixer() ], String ], Bool;
        _affix_and_export MIX_ResumeTrack              => [ Pointer [ MIX_Track() ] ], Bool;
        _affix_and_export MIX_ResumeAllTracks          => [ Pointer [ MIX_Mixer() ] ], Bool;
        _affix_and_export MIX_ResumeTag                => [ Pointer [ MIX_Mixer() ], String ], Bool;
        _affix_and_export MIX_TrackPlaying             => [ Pointer [ MIX_Track() ] ], Bool;
        _affix_and_export MIX_TrackPaused              => [ Pointer [ MIX_Track() ] ], Bool;
        _affix_and_export MIX_SetMixerGain             => [ Pointer [ MIX_Mixer() ], Float ], Bool;
        _affix_and_export MIX_GetMixerGain             => [ Pointer [ MIX_Mixer() ] ], Float;
        _affix_and_export MIX_SetTrackGain             => [ Pointer [ MIX_Track() ], Float ], Bool;
        _affix_and_export MIX_GetTrackGain             => [ Pointer [ MIX_Track() ] ], Float;
        _affix_and_export MIX_SetTagGain               => [ Pointer [ MIX_Mixer() ], String, Float ], Bool;
        _affix_and_export MIX_SetMixerFrequencyRatio   => [ Pointer [ MIX_Mixer() ], Float ], Bool;
        _affix_and_export MIX_GetMixerFrequencyRatio   => [ Pointer [ MIX_Mixer() ] ], Float;
        _affix_and_export MIX_SetTrackFrequencyRatio   => [ Pointer [ MIX_Track() ], Float ], Bool;
        _affix_and_export MIX_GetTrackFrequencyRatio   => [ Pointer [ MIX_Track() ] ], Float;
        _affix_and_export MIX_SetTrackOutputChannelMap => [ Pointer [ MIX_Track() ], Pointer [Int], Int ], Bool;
        _typedef_and_export MIX_StereoGains => Struct [ left => Float, right => Float ];
        _affix_and_export MIX_SetTrackStereo => [ Pointer [ MIX_Track() ], Pointer [ MIX_StereoGains() ] ], Bool;
        _typedef_and_export MIX_Point3D => Struct [ x => Float, y => Float, z => Float ];
        _affix_and_export MIX_SetTrack3DPosition => [ Pointer [ MIX_Track() ], Pointer [ MIX_Point3D() ] ], Bool;
        _affix_and_export MIX_GetTrack3DPosition => [ Pointer [ MIX_Track() ], Pointer [ MIX_Point3D() ] ], Bool;
        _affix_and_export MIX_CreateGroup        => [ Pointer [ MIX_Mixer() ] ], Pointer [ MIX_Group() ];
        _affix_and_export MIX_DestroyGroup       => [ Pointer [ MIX_Group() ] ], Void;
        _affix_and_export MIX_GetGroupProperties => [ Pointer [ MIX_Group() ] ], SDL3::SDL_PropertiesID();
        _affix_and_export MIX_GetGroupMixer      => [ Pointer [ MIX_Group() ] ], Pointer [ MIX_Mixer() ];
        _affix_and_export MIX_SetTrackGroup      => [ Pointer [ MIX_Track() ], Pointer [ MIX_Group() ] ], Bool;
        _typedef_and_export MIX_TrackStoppedCallback => Callback [ [ Pointer [Void], Pointer [ MIX_Track() ] ] => Void ];
        _affix_and_export MIX_SetTrackStoppedCallback => [ Pointer [ MIX_Track() ], MIX_TrackStoppedCallback(), Pointer [Void] ], Bool;
        _typedef_and_export MIX_TrackMixCallback =>
            Callback [ [ Pointer [Void], Pointer [ MIX_Track() ], Pointer [ SDL3::SDL_AudioSpec() ], Pointer [Float], Int ] => Void ];
        _affix_and_export MIX_SetTrackRawCallback    => [ Pointer [ MIX_Track() ], MIX_TrackMixCallback(), Pointer [Void] ], Bool;
        _affix_and_export MIX_SetTrackCookedCallback => [ Pointer [ MIX_Track() ], MIX_TrackMixCallback(), Pointer [Void] ], Bool;
        _typedef_and_export MIX_GroupMixCallback =>
            Callback [ [ Pointer [Void], Pointer [ MIX_Group() ], Pointer [ SDL3::SDL_AudioSpec() ], Pointer [Float], Int ] => Void ];
        _affix_and_export MIX_SetGroupPostMixCallback => [ Pointer [ MIX_Group() ], MIX_GroupMixCallback(), Pointer [Void] ], Bool;
        _typedef_and_export MIX_PostMixCallback =>
            Callback [ [ Pointer [Void], Pointer [ MIX_Mixer() ], Pointer [ SDL3::SDL_AudioSpec() ], Pointer [Float], Int ] => Void ];
        _affix_and_export MIX_SetPostMixCallback => [ Pointer [ MIX_Mixer() ], MIX_PostMixCallback(), Pointer [Void] ], Bool;
        _affix_and_export MIX_Generate           => [ Pointer [ MIX_Mixer() ], Pointer [Void], Int ], Int;
        _affix_and_export MIX_CreateAudioDecoder => [ String, SDL3::SDL_PropertiesID() ], Pointer [ MIX_AudioDecoder() ];
        _affix_and_export
            MIX_CreateAudioDecoder_IO => [ Pointer [ SDL3::SDL_IOStream() ], Bool, SDL3::SDL_PropertiesID() ],
            Pointer [ MIX_AudioDecoder() ];
        _affix_and_export MIX_DestroyAudioDecoder       => [ Pointer [ MIX_AudioDecoder() ] ], Void;
        _affix_and_export MIX_GetAudioDecoderProperties => [ Pointer [ MIX_AudioDecoder() ] ], SDL3::SDL_PropertiesID();
        _affix_and_export MIX_GetAudioDecoderFormat     => [ Pointer [ MIX_AudioDecoder() ], Pointer [ SDL3::SDL_AudioSpec() ] ], Bool;
        _affix_and_export MIX_DecodeAudio => [ Pointer [ MIX_AudioDecoder() ], Pointer [Void], Int, Pointer [ SDL3::SDL_AudioSpec() ] ], Int;
    }

    sub _all () {
        state $done++ && return;
        _mixer();
    }
}
1;

=head1 See Also

The project's repo: L<https://github.com/Perl-SDL3/>

The SDL3_mixer Wiki: L<https://wiki.libsdl.org/SDL3_mixer/FrontPage>

L<SDL3>

L<Affix>

=head1 LICENSE

This software is Copyright (c) 2026 by Sanko Robinson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

See the F<LICENSE> file for full text.

=head1 AUTHOR

Sanko Robinson L<https://github.com/sanko>

=begin stopwords


=end stopwords

=cut
