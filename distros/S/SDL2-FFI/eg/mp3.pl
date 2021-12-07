use strict;
use lib '../lib';
use experimental 'signatures';
$|++;
#
#use Carp::Always;
use SDL2::FFI
    qw[:init :audio SDL_Log SDL_RWFromFile SDL_QuitRequested SDL_Delay SDL_AddTimer SDL_PollEvent SDL_GetError /Timer/];
use SDL2::Mixer qw[:all];
#
{
    use Path::Tiny;
    my $wav = '/home/sanko/Projects/SDL2.pm/t/etc/sample.wav';
    if ( SDL_Init( SDL_INIT_AUDIO | SDL_INIT_TIMER ) < 0 ) {
        printf("Failed to init SDL\n");
        exit(1);
    }
    Mix_OpenAudio( 22050, AUDIO_S16SYS, 2, 640 );

    #warn Mix_RegisterEffect(
    #    MIX_CHANNEL_POST,
    #    sub {
    #        use Data::Dump;
    #        ddx \@_;
    #        warn 'this';
    #    },
    #    sub ( $chan, $chunk, $len, $args ) {
    #        warn 'that';
    #        $$chunk = [ map { int rand $_ } 0 .. $len ];
    #    },
    #    { time => 'now' }
    #) if 0;
    my $done  = 0;
    my $chunk = Mix_LoadWAV($wav);
    my $prev  = Mix_VolumeChunk( $chunk, 3 );
    Mix_PlayChannel( 1, $chunk, 1 );    # Play on channel 1 and loop once

    #my $timer = SDL_AddTimer(
    #    1,
    #    sub {
    #        #use Data::Dump;
    #        #ddx \@_;
    #        #warn sprintf 'Timer saved us! %d | %d', $done, SDL2::FFI::SDL_GetTicks();
    #        $done++;
    #        100;
    #    }
    #);    # Just in case
    #my $timer2 = SDL_AddTimer(
    #    1,
    #    sub {
    #        use Data::Dump;
    #        ddx \@_;
    #        warn 'tick ' . $_[0];
    #        return $_[0] * 10;
    #    },
    #    [qw[this that the other]]
    #);
    #my $blah = SDL_AddTimer(
    #    20,
    #    sub {
    #        warn 'tock';
    #        return 0;
    #        return shift;
    #    }
    #);    # Just in caseb
    #SDL_RemoveTimer($blah);
    Mix_SetPostMix(
        sub {
            my ( $udata, $stream, $len ) = @_;
            for my $index ( 0 .. $len - 1 ) {
                $$stream->[$index] = int rand $$stream->[$index];
            }
        },
        { amp => 10 }
    );
    Mix_HookMusicFinished(
        sub {
            SDL_Log('Mix_HookMusicFinished( ... )');
        }
    );
    Mix_ChannelFinished(
        sub {
            SDL_Log('Mix_ChannelFinished( ... )');
            $done++;
        }
    );
    SDL_Delay(1) while !$done;
    Mix_HaltChannel(1);

    #SDL_RemoveTimer($timer);
    #SDL_RemoveTimer($timer2);
    #SDL_RemoveTimer($blah);
}

sub LeftString {    #($stream, $len, $ref) {
    use Data::Dump;
    ddx \@_;
    $_[0] = 'done!';
}
__END__
my $fun = 0;
if (0) {
    SDL_AddTimer(
        10,
        sub {
            $fun++;

            #use Data::Dump;
            #ddx \@_;
            warn 'one';
            return int rand 100;
        },
        { test => 'time' }
    ) if 1;
    SDL_AddTimer(
        10,
        sub {
            $fun++;

            #use Data::Dump;
            #ddx \@_;
            return shift;
            warn 'two';
            return int rand 100;
        },
        { test => 'time' }
    ) if 1;
}

#_AddTimer(100, sub { warn 'ping';});
#setCallback(sub { warn 1;}, sub { warn 2;}, sub {warn 3}, sub { warn 4; $fun++ });
#setCallback( 'fred::callback1', 'fred::callback2', 'fred::callback3', $code );
#warn main::bindX();
use Data::Dump;
warn $fun;
$|++;
my @delay;
{
    my $PI = 3.1415926;

    # Amplitude for signal, roughly 50% of max (32768) or -6db
    my $amplitude   = 16384;
    my $freq        = 440000;    # Frequency in Hertz ('A4' note)
    my $sample_rate = 44100;

    # define time increment for calculating the wave
    my $increment = 1 / $sample_rate;
    my $t         = 0;

    #while (1) { # do this perpetually
    for ( 0 .. 2560 ) {
        $t += $increment;    # Time in seconds
        my $signal = $amplitude * sin( $freq * 2 * $PI * $t );

        #warn $signal;
        push @delay, $signal;

        #pack("v", $signal);
    }
}

#do something non-interrupt able
#use Sys::SigAction qw( set_sig_handler );
#{
#warn $$;
#Sys::SigAction::set_sig_handler( 'TERM' , sub { warn 'DUMMY ' . $$ } );
#... do stuff non-interrupt able
#} #signal handler is reset when $h goes out of scope
#
my $result = 0;
my $flags  = MIX_INIT_MP3;
if ( SDL_Init( SDL_INIT_AUDIO | SDL_INIT_TIMER ) < 0 ) {
    printf("Failed to init SDL\n");
    exit(1);
}
if ( $flags != ( $result = Mix_Init($flags) ) ) {
    printf "Could not initialize mixer (result: %d).\n", $result;
    printf "Mix_Init: %s\n",                             Mix_GetError();
    exit 1;
}
Mix_OpenAudio( 22050, AUDIO_S16SYS, 2, 640 );
my $music = Mix_LoadMUS('sound25.mp3');
my $done  = 0;
if (0) {
    Mix_SetPostMix(
        sub {
            my ( $udata, $stream, $len ) = @_;
            $$stream->[$_] += rand $udata->{amp} for 0 .. $len;
        },
        { amp => 10 }
    );
}
if (0) {
    my @ff = map { $_ * rand(2) } 0 .. 1000;    # Some predefined music
    @ff = ( @ff, reverse @ff );
    Mix_HookMusic(
        sub {
            my ( $udata, $stream, $len ) = @_;

            # fill buffer with...uh...music...
            $$stream->[$_] = $ff[ ( $_ + $udata->{pos} ) % ( scalar @ff ) ] // 0 for 0 .. $len;

            # set udata for next time
            $udata->{pos} += $len;
        },
        { pos => 0 }
    );
}
Mix_ChannelFinished(
    sub {
        my ($channel) = @_;
        printf( "channel %d finished playing.\n", $channel );
    }
);
Mix_HaltChannel($_) for 0 .. 100;

Mix_RegisterEffect(MIX_CHANNEL_POST, sub { warn 'this'; }, sub {warn 'that'}, {time => 'now'});


#Mix_SetPostMix(undef);
Mix_PlayMusic( $music, 3 );
my $event = SDL2::Event->new;
SDL_AddTimer( 100, sub { $done++ if !Mix_PlayingMusic(); return shift; } );
while ( !$done ) {

    #while ( SDL_PollEvent( $event ) ) {
    #    warn $event->user->data1;
    #}
    SDL_Delay(1);

    #ddx Mix_GetMusicHookData();
    #last if !Mix_Playing(-1);
    #last if !Mix_PlayingMusic();
}
warn;
Mix_FreeMusic($music);
warn;
SDL_Quit();
