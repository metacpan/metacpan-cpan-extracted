use strict;
use warnings;
use lib '../lib';
use SDL2::FFI qw[SDL_Log :init :version :audio SDL_GetTicks SDL_Delay SDL_TRUE];
use SDL2::Mixer qw[:all];
use experimental 'signatures';
use Getopt::Long qw[GetOptions :config no_ignore_case bundling];
$|++;
#
my $audio_open = 0;
my $music;    # SDL2::Mixer::Music;
my $next_track = 0;

sub cleanup ($exitcode) {
    if ( Mix_PlayingMusic() ) {
        Mix_FadeOutMusic(1500);
        SDL_Delay(1500);
    }
    if ($music) {
        Mix_FreeMusic($music);
        undef $music;
    }
    if ($audio_open) {
        Mix_CloseAudio();
        $audio_open = 0;
    }
    SDL_Quit();
    exit $exitcode;
}

sub usage() {
    SDL_Log(
        'Usage: %s [-i] [-l] [-8] [-f32] [-r rate] [-c channels] [-b buffers] [-v N] [-rwops] <musicfile>',
        $0
    );
}

sub menu() {
    print 'Available commands: (p)ause (r)esume (h)alt volume(v#) > ';
    my $buff = <STDIN>;
    chomp $buff;
    length $buff || return;
    ( $buff, my $etc ) = substr $buff, 0, 2;
    Mix_SetMusicPosition(0)  if $buff eq 0;
    Mix_SetMusicPosition(10) if $buff eq 1;
    Mix_SetMusicPosition(20) if $buff eq 2;
    Mix_SetMusicPosition(30) if $buff eq 3;
    Mix_SetMusicPosition(40) if $buff eq 4;
    Mix_PauseMusic()         if lc $buff eq 'p';
    Mix_ResumeMusic()        if lc $buff eq 'r';
    Mix_HaltMusic()          if lc $buff eq 'h';
    Mix_VolumeMusic($etc)    if lc $buff eq 'v';
    printf(
        "Music playing: %s Paused: %s\n",
        Mix_PlayingMusic() ? 'yes' : 'no',
        Mix_PausedMusic()  ? 'yes' : 'no'
    );
}
$SIG{INT} = sub { $next_track++ };
#
my $audio_volume = MIX_MAX_VOLUME;
my $looping      = 0;
my $interactive  = 0;
my $rwops        = 0;

# Initialize variables
my $audio_rate     = MIX_DEFAULT_FREQUENCY;
my $audio_format   = MIX_DEFAULT_FORMAT;
my $audio_channels = MIX_DEFAULT_CHANNELS;
my $audio_buffers  = 4096;

# Check command line usage
GetOptions(
    'rate|r=s'      => \$audio_rate,
    'm'             => sub { $audio_channels = 1 },
    'channels|c=i'  => \$audio_channels,
    'buffers|b=i'   => \$audio_buffers,
    'volume|v=i'    => \$audio_volume,
    'loops|l=i'     => \$looping,
    'interactive|i' => \$interactive,
    '8'             => sub { $audio_format = AUDIO_U8 },
    'f32'           => sub { $audio_format = AUDIO_F32 },
    'rwops'         => \$rwops
);
my @files = @ARGV;
scalar @files || die usage();

# Initialize the SDL library
if ( SDL_Init(SDL_INIT_AUDIO) < 0 ) {
    SDL_Log( 'Couldn\'t initialize SDL: %s', SDL_GetError() );
    exit 255;
}

# Open the audio device
if ( Mix_OpenAudio( $audio_rate, $audio_format, $audio_channels, $audio_buffers ) < 0 ) {
    SDL_Log( 'Couldn\'t open audio: %s', SDL_GetError() );
    exit 2;
}
else {
    Mix_QuerySpec( \$audio_rate, \$audio_format, \$audio_channels );
    SDL_Log(
        'Opened audio at %d Hz %d bit%s %s %d bytes audio buffer',
        $audio_rate,
        ( $audio_format & 0xFF ),
        ( SDL_AUDIO_ISFLOAT($audio_format) ? ' (float)' : '' ),
        ( $audio_channels > 2 ) ? 'surround' : ( $audio_channels > 1 ) ? 'stereo' : 'mono',
        $audio_buffers
    );
}
$audio_open = 1;

# Set the music volume
Mix_VolumeMusic($audio_volume);

# Set the external music player, if any
Mix_SetMusicCMD( $ENV{MUSIC_CMD} );
for my $file (@files) {
    $next_track = 0;

    # Load the requested music file
    $music
        = $rwops ? Mix_LoadMUS_RW( SDL_RWFromFile( $file, 'rb' ), SDL_TRUE ) : Mix_LoadMUS($file);
    #
    my $typ = 'NONE';
    {
        my $type = Mix_GetMusicType($music);
        $typ = 'CMD'        if $type == MUS_CMD;
        $typ = 'WAV'        if $type == MUS_WAV;
        $typ = 'MOD'        if $type == MUS_MOD || $type == MUS_MODPLUG_UNUSED;
        $typ = 'FLAC'       if $type == MUS_FLAC;
        $typ = 'MIDI'       if $type == MUS_MID;
        $typ = 'OGG Vorbis' if $type == MUS_OGG;
        $typ = 'MP3'        if $type == MUS_MP3 || $type == MUS_MP3_MAD_UNUSED;
        $typ = 'OPUS'       if $type == MUS_OPUS;
    }
    SDL_Log( 'Detected music type: %s', $typ );
    #
    if ( SDL_MIXER_VERSION_ATLEAST( 2, 0, 5 ) ) {
        my $tag_title = Mix_GetMusicTitleTag($music);
        SDL_Log( 'Title: %s', $tag_title ) if defined $tag_title && length $tag_title;
        my $tag_artist = Mix_GetMusicArtistTag($music);
        SDL_Log( 'Artist: %s', $tag_artist ) if defined $tag_artist && length $tag_artist;
        my $tag_album = Mix_GetMusicAlbumTag($music);
        SDL_Log( 'Album: %s', $tag_album ) if defined $tag_album && length $tag_album;
        my $tag_copyright = Mix_GetMusicCopyrightTag($music);
        SDL_Log( 'Copyright: %s', $tag_copyright )
            if defined $tag_copyright && length $tag_copyright;
        my $loop_start  = Mix_GetMusicLoopStartTime($music);
        my $loop_end    = Mix_GetMusicLoopEndTime($music);
        my $loop_length = Mix_GetMusicLoopLengthTime($music);

        # Play and then exit
        SDL_Log( "Playing %s, duration %f\n", $file, Mix_MusicDuration($music) );
        if ( $loop_start > 0.0 && $loop_end > 0.0 && $loop_length > 0.0 ) {
            SDL_Log( "Loop points: start %g s, end %g s, length %g s\n",
                $loop_start, $loop_end, $loop_length );
        }
    }
    Mix_FadeInMusic( $music, $looping, 2000 );
    while ( !$next_track && ( Mix_PlayingMusic() || Mix_PausedMusic() ) ) {
        if ($interactive) { menu(); }
        else {
            my $current_position = Mix_GetMusicPosition($music);
            if ( $current_position >= 0.0 ) {
                printf( "Position: %g seconds             \r", $current_position );
            }
            SDL_Delay(100);
        }
    }
    Mix_FreeMusic($music);
    undef $music;

    # If the user presses Ctrl-C more than once, exit.
    SDL_Delay(500);
    last if $next_track > 1;
}
cleanup(0);
