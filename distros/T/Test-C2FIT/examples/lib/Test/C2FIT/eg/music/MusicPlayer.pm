# MusicPlayer.pm
#
# Copyright (c) 2002 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>

package Test::C2FIT::eg::music::MusicPlayer;

use strict;
use vars qw($playing $paused);

$playing = undef;
$paused  = 0;

sub play {
    my ($music) = @_;
    my $seconds;

    if ( 0 == $paused ) {
        $Test::C2FIT::eg::music::Music::status = "loading";
        $seconds = ( $playing && $music == $playing ) ? 0.3 : 2.5;
        $Test::C2FIT::eg::music::Simulator::nextPlayStarted =
          Test::C2FIT::eg::music::Simulator->schedule($seconds);
    }
    else {
        $Test::C2FIT::eg::music::Music::status               = "playing";
        $Test::C2FIT::eg::music::Simulator::nextPlayComplete =
          Test::C2FIT::eg::music::Simulator->schedule($paused);
        $paused = 0;
    }
}

sub playing {
    my $self = shift;
    return $playing;
}

sub pause {
    $Test::C2FIT::eg::music::Music::status = "pause";
    if ( $playing && $paused == 0 ) {
        $paused =
          ( $Test::C2FIT::eg::music::Simulator::nextPlayComplete -
              $Test::C2FIT::eg::music::Simulator::time );
        $Test::C2FIT::eg::music::Simulator::nextPlayComplete = 0;
    }
}

sub stop {
    $Test::C2FIT::eg::music::Simulator::nextPlayStarted  = 0;
    $Test::C2FIT::eg::music::Simulator::nextPlayComplete = 0;
    playComplete();
}

# Status

sub secondsRemaining {
    return $paused if $paused;
    return ( $Test::C2FIT::eg::music::Simulator::nextPlayComplete -
          $Test::C2FIT::eg::music::Simulator::time )
      if $playing;
    return 0;
}

sub minutesRemaining {
    return int( secondsRemaining() / 0.6 + 0.5 ) / 100;
}

# Events

sub playStarted {
    $Test::C2FIT::eg::music::Music::status = "playing";
    $playing = Test::C2FIT::eg::music::MusicLibrary::looking();
    $Test::C2FIT::eg::music::Simulator::nextPlayComplete =
      Test::C2FIT::eg::music::Simulator->schedule( $playing->seconds() );
}

sub playComplete {
    $Test::C2FIT::eg::music::Music::status = "ready";
    $playing                               = undef;
}

1;

__END__

// Copyright (c) 2002 Cunningham & Cunningham, Inc.
// Read license.txt in this directory.

package eg.music;

public class MusicPlayer {

    static Music playing = null;
    static double paused = 0;

    // Controls /////////////////////////////////

    static void play(Music m) {
        if (paused == 0) {
            Music.status = "loading";
            double seconds = m == playing ? 0.3 : 2.5 ;
            Simulator.nextPlayStarted = Simulator.schedule(seconds);
        } else {
            Music.status = "playing";
            Simulator.nextPlayComplete = Simulator.schedule(paused);
            paused = 0;
        }
    }

    static void pause() {
        Music.status = "pause";
        if (playing != null && paused == 0) {
            paused = (Simulator.nextPlayComplete - Simulator.time) / 1000.0;
            Simulator.nextPlayComplete = 0;
        }
    }

    static void stop() {
        Simulator.nextPlayStarted = 0;
        Simulator.nextPlayComplete = 0;
        playComplete();
    }

    // Status ///////////////////////////////////

    static double secondsRemaining() {
        if (paused != 0) {
            return paused;
        } else if (playing != null) {
            return (Simulator.nextPlayComplete - Simulator.time) / 1000.0;
        } else {
            return 0;
        }
    }

    static double minutesRemaining() {
        return Math.round(secondsRemaining() / .6) / 100.0;
    }

    // Events ///////////////////////////////////

    static void playStarted() {
        Music.status = "playing";
        playing = MusicLibrary.looking;
        Simulator.nextPlayComplete = Simulator.schedule(playing.seconds);
    }

    static void playComplete() {
        Music.status = "ready";
        playing = null;
    }
}

