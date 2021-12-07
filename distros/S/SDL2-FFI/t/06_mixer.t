use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Class qw[isa_ok can_ok];
use Test2::Tools::Exception qw[try_ok];
use Test2::Tools::ClassicCompare qw[is_deeply];
use Path::Tiny;
use lib -d '../t' ? './lib' : 't/lib';
use lib '../lib', 'lib';
#
use SDL2::FFI qw[:init :audio SDL_RWFromFile /Timer/ SDL_Delay];
use SDL2::Mixer qw[:all];
#
$|++;
#
my $mp3 = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.mp3' )->absolute;
my $wav = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.wav' )->absolute;
#
my $compile_version = SDL2::Version->new();
my $link_version    = Mix_Linked_Version();
SDL_MIXER_VERSION($compile_version);
diag sprintf 'compiled with SDL_mixer version: %d.%d.%d', $compile_version->major,
    $compile_version->minor, $compile_version->patch;
diag sprintf 'running with SDL_mixer version: %d.%d.%d', $link_version->major,
    $link_version->minor, $link_version->patch;
is SDL_MIXER_VERSION_ATLEAST( 1, 0, 0 ), 1, 'SDL_MIXER_VERSION_ATLEAST( 1, 0, 0 ) == 1';
is SDL_MIXER_VERSION_ATLEAST( $link_version->major, $link_version->minor, $link_version->patch ), 1,
    sprintf( 'SDL_MIXER_VERSION_ATLEAST( %d, %d, %d ) == 1',
    $link_version->major, $link_version->minor, $link_version->patch );
is SDL_MIXER_VERSION_ATLEAST(
    $link_version->major, $link_version->minor, $link_version->patch + 1
    ),
    !1,
    sprintf( 'SDL_MIXER_VERSION_ATLEAST( %d, %d, %d ) != 1',
    $link_version->major, $link_version->minor, $link_version->patch + 1 );
#
is Mix_Init(), 0, 'Mix_Init() == 0';
#
my $has_mp3  = Mix_Init(MIX_INIT_MP3) == MIX_INIT_MP3;
my $has_flac = Mix_Init(MIX_INIT_FLAC) == MIX_INIT_FLAC;
#
subtest 'MP3 tests' => sub {
    skip_all if !$has_mp3;
    is Mix_Init(MIX_INIT_MP3), MIX_INIT_MP3, 'Mix_Init( MIX_INIT_MP3 ) == MIX_INIT_MP3';
};
subtest 'FLAC tests' => sub {
    skip_all if !$has_flac;
    is Mix_Init(MIX_INIT_FLAC), MIX_INIT_FLAC, 'Mix_Init( MIX_INIT_FLAC ) == MIX_INIT_FLAC';
};
subtest 'Combined MP3 and FLAC tests' => sub {
    skip_all if !( $has_mp3 && $has_flac );
    is Mix_Init( MIX_INIT_MP3 | MIX_INIT_FLAC ), MIX_INIT_MP3 | MIX_INIT_FLAC,
        'Mix_Init( MIX_INIT_MP3|MIX_INIT_FLAC ) == MIX_INIT_MP3|MIX_INIT_FLAC';
};
todo 'These are platform specific and might fail depending on how SDL_mixer was built' => sub {
    #
    is SDL_Init(SDL_INIT_AUDIO), 0, 'SDL_Init( SDL_INIT_AUDIO ) == 0';
    is Mix_OpenAudio( 44100, MIX_DEFAULT_FORMAT, 2, 1024 ), 0,
        'Mix_OpenAudio( 44100, MIX_DEFAULT_FORMAT, 2, 1024 ) == 0';
    subtest 'Open audio devices' => sub {
        for my $i ( 0 .. SDL_GetNumAudioDevices(0) - 1 ) {
            is Mix_OpenAudioDevice( 44100, MIX_DEFAULT_FORMAT, 2, 1024, SDL_GetAudioDeviceName($i),
                0 ),
                0, sprintf 'Mix_OpenAudioDevice( ..., "%s", 0 ) == 0',
                SDL_GetAudioDeviceName( $i, 0 );
        }

        END {
            diag 'Closing audio sessions...';
            Mix_CloseAudio() for 0 .. Mix_QuerySpec( undef, undef, undef );
        }
    };
};
is Mix_AllocateChannels(16), 16, 'Mix_AllocateChannels( 16 ) == 16';
is Mix_AllocateChannels(-1), 16, 'Mix_AllocateChannels( -1 ) == 16 (no change)';
todo 'These are platform specific and might fail depending on how SDL_mixer was built' => sub {

    # get and print the audio format in use
    #int numtimesopened, frequency, channels;
    #Uint16 format;
    my $numtimesopened = Mix_QuerySpec( \my $frequency, \my $format, \my $channels );

    # XXX: Are we sure we can open *all* audio devices?
    # We called plain ol' Mix_OpenAudio( ... ) first so +1
    is $numtimesopened, SDL_GetNumAudioDevices(0) + 1,
        sprintf 'Mix_QuerySpec( ... ) claims we have %d open audio sessions', $numtimesopened;
    isa_ok Mix_LoadWAV_RW( SDL_RWFromFile( $wav, 'rb' ), 1 ), ['SDL2::Mixer::Chunk'],
        "Mix_LoadWAV_RW( SDL_RWFromFile( '$wav', 'rb' ), 1 ) returns a SDL2::Mixer::Chunk";
    isa_ok Mix_LoadWAV($wav), ['SDL2::Mixer::Chunk'],
        "Mix_LoadWAV( '$wav' ) returns a SDL2::Mixer::Chunk";
    subtest 'MP3 tests' => sub {
        skip_all if !$has_mp3;
        isa_ok Mix_LoadMUS($mp3), ['SDL2::Mixer::Music'],
            "Mix_LoadWAV( '$mp3' ) returns a SDL2::Mixer::Music";
        isa_ok Mix_LoadMUS_RW( SDL_RWFromFile( $mp3, 'rb' ), 1 ), ['SDL2::Mixer::Music'],
            "Mix_LoadMUS_RW(SDL_RWFromFile( '$mp3', 'rb' ), 1) returns a SDL2::Mixer::Music";
        isa_ok Mix_LoadMUSType_RW( SDL_RWFromFile( $mp3, 'rb' ), MUS_MP3, 1 ),
            ['SDL2::Mixer::Music'],
            "Mix_LoadMUSType_RW(SDL_RWFromFile( '$mp3', 'rb' ), MUS_MP3, 1) returns a SDL2::Mixer::Music";
    };
};
todo 'Loading music fails on some devices?!?' => sub {
    isa_ok Mix_LoadMUSType_RW( SDL_RWFromFile( $wav, 'rb' ), MUS_WAV, 1 ), ['SDL2::Mixer::Music'],
        "Mix_LoadMUSType_RW(SDL_RWFromFile( '$wav', 'rb' ), MUS_WAV, 1) returns a SDL2::Mixer::Music";
    subtest 'MP3 tests' => sub {
        skip_all if !$has_mp3;
        is Mix_LoadMUSType_RW( SDL_RWFromFile( $mp3, 'rb' ), MUS_WAV, 1 ), undef,
            "Mix_LoadMUSType_RW(SDL_RWFromFile( '$mp3', 'rb' ), MUS_WAV, 1) returns undef: " .
            Mix_GetError();
    };
    isa_ok Mix_QuickLoad_WAV( $wav->slurp_raw() ), ['SDL2::Mixer::Chunk'],
        'Mix_QuickLoad_WAV( ... ) returns SDL2::Mixer::Chunk';
    isa_ok Mix_QuickLoad_RAW( $wav->slurp_raw(), -s $wav ), ['SDL2::Mixer::Chunk'],
        'Mix_QuickLoad_RAW( ... ) returns SDL2::Mixer::Chunk';
};
#
my $chunk = Mix_QuickLoad_WAV( $wav->slurp_raw() );
is Mix_FreeChunk($chunk), undef, 'Mix_FreeChunk( ... ) returns void...';
subtest 'MP3 tests' => sub {
    skip_all if !$has_mp3;
    my $music = Mix_LoadMUS($mp3);
    is Mix_FreeMusic($music), undef, 'Mix_FreeMusic( ... ) returns void...';
};
#
diag sprintf 'There are %d sample chunk decoders available:', Mix_GetNumChunkDecoders();
for my $index ( 0 .. Mix_GetNumChunkDecoders() - 1 ) {

    # Mix_HasChunkDecoder( ... ) was defined in SDL_mixer 2.0.5
    my $has
        = SDL_MIXER_VERSION_ATLEAST( 2, 0, 5 ) ?
        Mix_HasChunkDecoder($index) ?
        'yes' :
            'no' :
        'unknown';
    diag sprintf '    - %-6s %s', Mix_GetChunkDecoder($index), $has;
}
diag sprintf 'There are %d music decoders available:', Mix_GetNumMusicDecoders();
for my $index ( 0 .. Mix_GetNumMusicDecoders() - 1 ) {

    # Mix_HasMusicDecoder( ... ) was defined in SDL_mixer 2.0.5
    my $has
        = SDL_MIXER_VERSION_ATLEAST( 2, 0, 5 ) ?
        Mix_HasMusicDecoder($index) ?
        'yes' :
            'no' :
        'unknown';
    diag sprintf '    - %-6s %s', Mix_GetMusicDecoder($index), $has;
}
subtest 'MP3 tests' => sub {
    skip_all if !$has_mp3;
    skip_all if !SDL_MIXER_VERSION_ATLEAST( 2, 0, 5 );
    diag Mix_GetMusicType( Mix_LoadMUS($mp3) );
    is Mix_GetMusicType( Mix_LoadMUS($mp3) ), MUS_MP3,
        'Mix_GetMusicType( Mix_LoadMUS($mp3) ) == MUS_MP3';
    is Mix_GetMusicTitle($mp3),        'Test', 'Mix_GetMusicTitle( ... )';
    is Mix_GetMusicTitleTag($mp3),     'Test', 'Mix_GetMusicTitleTag( ... )';
    is Mix_GetMusicArtistTag($mp3),    'Test', 'Mix_GetMusicArtistTag( ... )';
    is Mix_GetMusicAlbumTag($mp3),     'Test', 'Mix_GetMusicAlbumTag( ... )';
    is Mix_GetMusicCopyrightTag($mp3), 'Test', 'Mix_GetMusicCopyrightTag( ... )';
};
#
my $vol = Mix_VolumeMusic(5);
is Mix_VolumeMusic(1), 5, 'Mix_VolumeMusic( ... )';    # Set to 1 for "quiet" testing
if (0) {
    my $done = 0;
    Mix_SetPostMix(
        sub {
            my ( $udata, $stream, $len ) = @_;
            $$stream = [ map { int rand 5 } 0 .. $len - 1 ];    # hiss
            pass 'Mix_SetPostMix( ... ) callback';
            is_deeply $udata, { test => 'yep' }, '   userdata is correct';
            $done++;
        },
        { test => 'yep' }
    );
    Mix_PlayMusic( Mix_LoadMUS($wav), 1 );    # Only play it once
    my $timer = SDL_AddTimer( 5000,
        sub { fail 'Timer saved us from Mix_SetPostMix( ... ) failure!'; $done++; 0; } )
        ;                                     # Just in case
    SDL_Delay(1) while !$done;
    Mix_SetPostMix(undef);
    SDL_RemoveTimer($timer);
}
if (0) {
    my $done = 0;
    my @ff   = map { int rand(3) } 0 .. 5000;    # Some predefined music
    warn;
    Mix_HookMusic(
        sub {
            warn;
            my ( $udata, $stream, $len ) = @_;

            # fill buffer with... uh... music...
            $$stream->[$_] = $ff[ ( $_ + $udata->{pos} ) % ( scalar @ff ) ] // 0 for 0 .. $len - 1;

            # set udata for next time
            diag( $udata->{pos} );
            if ( $udata->{pos} >= 50000 ) {
                pass 'Mix_HookMusic( ... ) callback';
                ok $udata->{pos}, '   userdata is defined (and sticky)';
                $done++;
            }
            $udata->{pos} += $len;
        },
        { pos => 0 }
    );
    warn;
    Mix_PlayMusic( Mix_LoadMUS($wav), 1 );    # Only play it once
    warn;
    my $timer = SDL_AddTimer( 5000,
        sub { fail 'Timer saved us from Mix_HookMusic( ... ) failure'; $done++; 0; } )
        ;                                     # Just in case
    SDL_Delay(1) while !$done;
    warn;
    my $data = Mix_GetMusicHookData();
    warn;
    ok $data->{pos}, 'Mix_GetMusicHookData()';
    warn;
    Mix_HookMusic(undef);
    warn;
    SDL_RemoveTimer($timer);
    warn;
}
if (0) {
    warn '????????????????????????????????????????????????????????????';
    my $done = 0;
    Mix_HookMusicFinished(
        sub {
            warn '----------------------------------------------------------------------';
            ok 1, 'Mix_HookMusicFinished( ... ) callback triggered';
            $done++;
        }
    );
    Mix_PlayMusic( Mix_LoadMUS($wav), 1 );
    my $timer = SDL_AddTimer( 5000,
        sub { fail 'Timer saved us from Mix_HookMusicFinished( ... ) failure!'; $done++; 0; } )
        ;    # Just in case
    SDL_Delay(1) while !$done;
    Mix_HaltMusic();
    Mix_HookMusicFinished(undef);
    SDL_RemoveTimer($timer);
    warn;
}
if (0) {
    my $done = 0;
    Mix_ChannelFinished( sub { ok 1, 'Mix_ChannelFinished( ... ) callback triggered'; $done++; } );
    my $chunk = Mix_LoadWAV($wav);
    my $prev  = Mix_VolumeChunk( $chunk, 3 );
    Mix_PlayChannel( 1, $chunk, 1 );    # Play on channel 1 and loop once
    my $timer = SDL_AddTimer( 5000,
        sub { fail 'Timer saved us from Mix_ChannelFinished( ... ) failure!'; $done++; 0; } )
        ;                               # Just in case
    SDL_Delay(1) while !$done;
    Mix_HaltChannel(1);
    SDL_RemoveTimer($timer);
}
if (0) {
    Mix_RegisterEffect(
        MIX_CHANNEL_POST,
        sub { warn 'this'; },
        sub { warn 'that' },
        { time => 'now' }
    );
    my $done = 0;
    Mix_ChannelFinished( sub { ok 1, 'Mix_ChannelFinished( ... ) callback triggered'; $done++; } );
    my $chunk = Mix_LoadWAV($wav);
    my $prev  = Mix_VolumeChunk( $chunk, 3 );
    Mix_PlayChannel( 1, $chunk, 1 );    # Play on channel 1 and loop once
    my $timer = SDL_AddTimer( 5000,
        sub { fail 'Timer saved us from Mix_ChannelFinished(...) failure!'; $done++; 0; } )
        ;                               # Just in case
    SDL_Delay(1) while !$done;
    Mix_HaltChannel(1);
    SDL_RemoveTimer($timer);
}
#
diag 'Restore music volume level';
Mix_VolumeMusic($vol);
#
can_ok $_ for qw[
    SDL_MIXER_MAJOR_VERSION
    SDL_MIXER_MINOR_VERSION
    SDL_MIXER_PATCHLEVEL
    SDL_MIXER_VERSION
    SDL_MIXER_COMPILEDVERSION
    SDL_MIXER_VERSION_ATLEAST
    MIX_INIT_FLAC
    MIX_INIT_MOD
    MIX_INIT_MP3
    MIX_INIT_OGG
    MIX_INIT_MID
    MIX_INIT_OPUS
    MIX_CHANNELS
    MIX_DEFAULT_FREQUENCY
    MIX_DEFAULT_FORMAT
    MIX_DEFAULT_CHANNELS
    MIX_MAX_VOLUME
    MUS_NONE
    MUS_CMD
    MUS_WAV
    MUS_MOD
    MUS_MID
    MUS_OGG
    MUS_MP3
    MUS_MP3_MAD_UNUSED
    MUS_FLAC
    MUS_MODPLUG_UNUSED
    MUS_OPUS
];
#
done_testing;
