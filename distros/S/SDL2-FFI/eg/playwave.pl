use strict;
use warnings;
use lib '../lib';
use SDL2::FFI qw[SDL_Log :init :version :audio SDL_GetTicks SDL_Delay];
use SDL2::Mixer qw[:all];
use experimental 'signatures';
use Getopt::Long qw[GetOptions :config no_ignore_case bundling];

# Various mixer tests. Define the ones you want.
my %tests = (
    TEST_MIX_DECODERS        => 1,
    TEST_MIX_VERSIONS        => 1,
    TEST_MIX_CHANNELFINISHED => 1,
    TEST_MIX_PANNING         => 1,
    TEST_MIX_DISTANCE        => 0,
    TEST_MIX_POSITION        => 0
);
#
my $wave;
#
if ( $tests{TEST_MIX_POSITION} ) {
    if ( $tests{TEST_MIX_PANNING} ) {
        die 'TEST_MIX_POSITION interferes with TEST_MIX_PANNING.';
    }
    if ( $tests{TEST_MIX_DISTANCE} ) {
        die 'TEST_MIX_POSITION interferes with TEST_MIX_DISTANCE.';
    }
}

sub output_test_warnings() {
    SDL_Log('Warning: TEST_MIX_CHANNELFINISHED is enabled.') if $tests{TEST_MIX_CHANNELFINISHED};
    SDL_Log('Warning: TEST_MIX_PANNING is enabled.')         if $tests{TEST_MIX_PANNING};
    SDL_Log('Warning: TEST_MIX_VERSIONS is enabled.')        if $tests{TEST_MIX_VERSIONS};
    SDL_Log('Warning: TEST_MIX_DISTANCE is enabled.')        if $tests{TEST_MIX_DISTANCE};
    SDL_Log('Warning: TEST_MIX_POSITION is enabled.')        if $tests{TEST_MIX_POSITION};
}
my $audio_open = 0;

sub report_decoders() {
    my ( $i, $total );
    SDL_Log('Supported decoders...');
    $total = Mix_GetNumChunkDecoders();
    for my $i ( 0 .. $total ) {
        SDL_Log( ' - chunk decoder: %s', Mix_GetChunkDecoder($i) );
    }
    $total = Mix_GetNumMusicDecoders();
    for my $i ( 0 .. $total ) {
        SDL_Log( ' - music decoder: %s', Mix_GetMusicDecoder($i) );
    }
}

sub output_versions ( $libname, $linked ) {
    SDL_Log( "This program was dynamically linked to %s v%d.%d.%d.",
        $libname, $linked->major, $linked->minor, $linked->patch );
}

sub test_versions() {
    my $linked = SDL2::Version->new;
    SDL_GetVersion($linked);
    output_versions( 'SDL', $linked );
    $linked = Mix_Linked_Version();
    output_versions( 'SDL_mixer', $linked );
}
my $channel_is_done = 0;

sub channel_complete_callback ($chan) {
    my $done_chunk = Mix_GetChunk($chan);
    SDL_Log( 'We were just alerted that Mixer channel #%d is done which %s correct.',
        $chan, ( $wave->abuf ~~ $done_chunk->abuf ) ? 'is' : 'is NOT' );
    $channel_is_done = 1;
}

# rcg06192001 abstract this out for testing purposes
sub still_playing() {
    return $tests{TEST_MIX_CHANNELFINISHED} ? !$channel_is_done : Mix_Playing(0);
}

sub do_panning_update() {
    CORE::state $leftvol             = 128;
    CORE::state $rightvol            = 128;
    CORE::state $leftincr            = -1;
    CORE::state $rightincr           = 1;
    CORE::state $panningok           = 1;
    CORE::state $next_panning_update = 0;
    if ( ($panningok) && ( SDL_GetTicks() >= $next_panning_update ) ) {
        $panningok = Mix_SetPanning( 0, $leftvol, $rightvol );
        if ( !$panningok ) {
            SDL_Log( 'Mix_SetPanning(0, %d, %d) failed!', $leftvol, $rightvol );
            SDL_Log( 'Reason: [%s].', Mix_GetError() );
        }
        if ( ( $leftvol == 255 ) || ( $leftvol == 0 ) ) {
            if ( $leftvol == 255 ) {
                SDL_Log('All the way in the left speaker.');
            }
            $leftincr *= -1;
        }
        if ( ( $rightvol == 255 ) || ( $rightvol == 0 ) ) {
            if ( $rightvol == 255 ) {
                SDL_Log('All the way in the right speaker.');
            }
            $rightincr *= -1;
        }
        $leftvol  += $leftincr;
        $rightvol += $rightincr;
        $next_panning_update = SDL_GetTicks() + 10;
    }
}

sub do_distance_update() {
    CORE::state $distance             = 1;
    CORE::state $distincr             = 1;
    CORE::state $distanceok           = 1;
    CORE::state $next_distance_update = 0;
    if ( ($distanceok) && ( SDL_GetTicks() >= $next_distance_update ) ) {
        $distanceok = Mix_SetDistance( 0, $distance );
        if ( !$distanceok ) {
            SDL_Log( 'Mix_SetDistance(0, %d) failed!', $distance );
            SDL_Log( 'Reason: [%s].',                  Mix_GetError() );
        }
        if ( $distance == 0 ) {
            SDL_Log('Distance at nearest point.');
            $distincr *= -1;
        }
        elsif ( $distance == 255 ) {
            SDL_Log('Distance at furthest point.');
            $distincr *= -1;
        }
        $distance += $distincr;
        $next_distance_update = SDL_GetTicks() + 15;
    }
}

sub do_position_update() {
    CORE::state $distance             = 1;
    CORE::state $distincr             = 1;
    CORE::state $angle                = 0;
    CORE::state $angleincr            = 1;
    CORE::state $positionok           = 1;
    CORE::state $next_position_update = 0;
    if ( ($positionok) && ( SDL_GetTicks() >= $next_position_update ) ) {
        $positionok = Mix_SetPosition( 0, $angle, $distance );
        if ( !$positionok ) {
            SDL_Log( 'Mix_SetPosition(0, %d, %d) failed!', $angle, $distance );
            SDL_Log( 'Reason: [%s].', Mix_GetError() );
        }
        if ( $angle == 0 ) {
            SDL_Log('Due north; now rotating clockwise...');
            $angleincr = 1;
        }
        elsif ( $angle == 360 ) {
            SDL_Log('Due north; now rotating counter-clockwise...');
            $angleincr = -1;
        }
        $distance += $distincr;
        if ( $distance < 0 ) {
            $distance = 0;
            $distincr = 3;
            SDL_Log('Distance is very, very near. Stepping away by threes...');
        }
        elsif ( $distance > 255 ) {
            $distance = 255;
            $distincr = -3;
            SDL_Log('Distance is very, very far. Stepping towards by threes...');
        }
        $angle += $angleincr;
        $next_position_update = SDL_GetTicks() + 30;
    }
}

#endif
sub cleanup ($exitcode) {
    if ($wave) {
        Mix_FreeChunk($wave);
        undef $wave;
    }
    if ($audio_open) {
        Mix_CloseAudio();
        $audio_open = 0;
    }
    SDL_Quit();
    exit $exitcode;
}

sub usage () {
    SDL_Log( 'Usage: %s [-8] [-f32] [-r rate] [-c channels] [-f] [-F] [-l] [-m] <wavefile>', $0 );
}

# Actually, it's meant to be an example of how to manipulate a voice
# without having to use the mixer effects API. This is more processing
# up front, but no extra during the mixing process. Also, in a case like
# this, when you need to touch the whole sample at once, it's the only
# option you've got. And, with the effects API, you are altering a copy of
# the original sample for each playback, and thus, your changes aren't
# permanent; here, you've got a reversed sample, and that's that until
# you either reverse it again, or reload it.
#
sub flip_sample ($wave) {
    my ( $format, $channels, $i, $incr );
    my $start = $wave->abuf;
    my $end   = $wave->abuf + $wave->alen;
    Mix_QuerySpec( undef, \$format, \$channels );
    $incr = ( $format & 0xFF ) * $channels;
    $end -= $incr;
    if ( $incr == 8 ) {
        for ( my $i = $wave->alen / 2; $i >= 0; $i -= 1 ) {
            my $tmp = $start;
            $start = $end;
            $end   = $tmp;
            $start++;
            $end--;
        }
    }
    elsif ( $incr == 16 ) {
        for ( my $i = $wave->alen / 2; $i >= 0; $i -= 2 ) {
            my $tmp = $start;
            $start = $end;
            $end   = $tmp;
            $start += 2;
            $end   -= 2;
        }
    }
    elsif ( $incr == 32 ) {
        for ( my $i = $wave->alen / 2; $i >= 0; $i -= 4 ) {
            my $tmp = $start;
            $start = $end;
            $end   = $tmp;
            $start += 4;
            $end   -= 4;
        }
    }
    else {
        SDL_Log('Unhandled format in sample flipping.');
        return;
    }
}
#
my $loops          = -1;
my $reverse_stereo = 0;
my $reverse_sample = 0;
#
output_test_warnings();

# Initialize variables
my $audio_rate     = MIX_DEFAULT_FREQUENCY;
my $audio_format   = MIX_DEFAULT_FORMAT;
my $audio_channels = MIX_DEFAULT_CHANNELS;
GetOptions(
    'rate|r=s'     => \$audio_rate,
    'm'            => sub { $audio_channels = 1 },
    'channels|c=i' => \$audio_channels,
    'loops|l=i'    => \$loops,                       #sub { $loops          = -1 },
    '8'            => sub { $audio_format = AUDIO_U8 },
    'f32'          => sub { $audio_format = AUDIO_F32 },
    'f'            => \$reverse_stereo,              # rcg06122001 flip stereo
    'F'            => \$reverse_sample,              # rcg06172001 flip sample
);
($wave) = @ARGV;
$wave // die usage();

# Initialize the SDL library
if ( SDL_Init(SDL_INIT_AUDIO) < 0 ) {
    SDL_Log( 'Couldn\'t initialize SDL: %s', SDL_GetError() );
    exit 255;
}

# Open the audio device
if ( Mix_OpenAudio( $audio_rate, $audio_format, $audio_channels, 4096 ) < 0 ) {
    SDL_Log( 'Couldn\'t open audio: %s', SDL_GetError() );
    cleanup(2);
}
else {
    Mix_QuerySpec( \$audio_rate, \$audio_format, \$audio_channels );
    SDL_Log(
        'Opened audio at %d Hz %d bit%s %s',
        $audio_rate,
        ( $audio_format & 0xFF ),
        ( SDL_AUDIO_ISFLOAT($audio_format) ? " (float)" : "" ),
        ( $audio_channels > 2 ) ? "surround" : ( $audio_channels > 1 ) ? "stereo" : "mono"
    );
    if ($loops) {
        SDL_Log(" (looping)\n");
    }
}
$audio_open = 1;
test_versions();
report_decoders();

# Load the requested wave file
$wave = Mix_LoadWAV($wave);
if ( !defined $wave ) {
    SDL_Log( "Couldn't load %s: %s\n", $wave, SDL_GetError() );
    cleanup(2);
}
if ($reverse_sample) {
    flip_sample($wave);
}
Mix_ChannelFinished( \&channel_complete_callback );
if ( ( !Mix_SetReverseStereo( MIX_CHANNEL_POST, $reverse_stereo ) ) && ($reverse_stereo) ) {
    SDL_Log("Failed to set up reverse stereo effect!\n");
    SDL_Log( "Reason: [%s].\n", Mix_GetError() );
}

# Play and then exit
Mix_PlayChannel( 0, $wave, $loops );
while ( still_playing() ) {
    do_panning_update()  if $tests{TEST_MIX_PANNING};     # rcg06132001
    do_distance_update() if $tests{TEST_MIX_DISTANCE};    # rcg06192001
    do_position_update() if $tests{TEST_MIX_POSITION};    # rcg06202001
    SDL_Delay(1);
}
cleanup(0);
