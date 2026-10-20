use v5.40;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use SDL3 qw[:all];
no warnings qw[experimental::builtin];

BEGIN {
    try {
        builtin::load_module('SDL3::Mixer');
        SDL3::Mixer->import(qw[:all]);
    }
    catch ($e) {
        plan skip_all => 'SDL3::Mixer is not available: ' . $e;
    }
}

# Force dummy audio driver
SDL_SetHint( SDL_HINT_AUDIO_DRIVER, 'dummy' );
subtest 'Version & Metadata' => sub {
    imported_ok qw[MIX_Version MIX_MAJOR_VERSION MIX_MINOR_VERSION MIX_MICRO_VERSION MIX_VERSION_ATLEAST];
    my $ver = MIX_Version();
    ok $ver > 0, "MIX_Version returned: $ver";
    is MIX_MAJOR_VERSION(), 3, 'Major version is 3';
    ok MIX_VERSION_ATLEAST( 3, 0, 0 ), 'MIX_VERSION_ATLEAST(3, 0, 0)';
};
subtest 'Lifecycle & Decoders' => sub {
    imported_ok qw[
        SDL_Init SDL_Quit SDL_INIT_AUDIO
        MIX_Init MIX_Quit MIX_GetNumAudioDecoders MIX_GetAudioDecoder
    ];
    ok SDL_Init(SDL_INIT_AUDIO), 'SDL_Init(SDL_INIT_AUDIO)';
    ok MIX_Init(),               'MIX_Init()';
    my $num = MIX_GetNumAudioDecoders();
    ok $num >= 0, "Available decoders count: $num";

    if ( $num > 0 ) {
        my $decoder = MIX_GetAudioDecoder(0);
        ok defined($decoder), "First audio decoder: $decoder";
    }
    MIX_Quit();
    SDL_Quit();
};
subtest 'Mixer, Tracks & Groups' => sub {
    imported_ok qw[
        SDL_Init SDL_Quit SDL_INIT_AUDIO
        MIX_Init MIX_Quit MIX_CreateMixer MIX_DestroyMixer
        MIX_SetMixerGain MIX_GetMixerGain MIX_LockMixer MIX_UnlockMixer
        MIX_CreateTrack MIX_DestroyTrack MIX_CreateGroup MIX_DestroyGroup MIX_SetTrackGroup
    ];
    SDL_Init(SDL_INIT_AUDIO);
    MIX_Init();

    # Specify the audio format for the memory mixer
    my $mixer = MIX_CreateMixer( { format => SDL_AUDIO_S16LE(), channels => 2, freq => 44100 } );
    ok $mixer, 'MIX_CreateMixer created mixer instance';
    if ($mixer) {

        # Gain / Volume
        ok MIX_SetMixerGain( $mixer, 0.75 ), 'MIX_SetMixerGain(0.75)';
        my $gain = MIX_GetMixerGain($mixer);
        is sprintf( "%.2f", $gain ), '0.75', 'MIX_GetMixerGain matches set value';

        # Locking
        MIX_LockMixer($mixer);
        MIX_UnlockMixer($mixer);
        pass 'MIX_LockMixer / MIX_UnlockMixer executed cleanly';

        # Tracks and Groups
        my $track = MIX_CreateTrack($mixer);
        ok $track, 'MIX_CreateTrack created track';
        my $group = MIX_CreateGroup($mixer);
        ok $group, 'MIX_CreateGroup created group';
        if ( $track && $group ) {
            ok MIX_SetTrackGroup( $track, $group ), 'MIX_SetTrackGroup assigned track to group';
        }
        MIX_DestroyTrack($track) if $track;
        MIX_DestroyGroup($group) if $group;
        MIX_DestroyMixer($mixer);
        pass 'Cleaned up track, group, and mixer';
    }
    MIX_Quit();
    SDL_Quit();
};
#
done_testing;
