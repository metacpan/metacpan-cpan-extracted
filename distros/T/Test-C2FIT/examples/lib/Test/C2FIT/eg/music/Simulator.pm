# Simulator.pm
#
# Copyright (c) 2002 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>

package Test::C2FIT::eg::music::Simulator;

use strict;
use Test::C2FIT::eg::music::MusicLibrary;
use Test::C2FIT::eg::music::MusicPlayer;
use Test::C2FIT::eg::music::Dialog;

use vars qw($system $time
  $nextSearchComplete $nextPlayStarted $nextPlayComplete);

$system = new Test::C2FIT::eg::music::Simulator();
$time = time();    # 10000;		#HACK start with a fixed time()

$nextSearchComplete = 0;
$nextPlayStarted    = 0;
$nextPlayComplete   = 0;

sub new {
    my $pkg = shift;

    return bless {@_}, $pkg;
}

sub nextEvent {
    my $self = shift;
    my ($bound) = shift;

    my $result = $bound;
    $result = sooner( $result, $nextSearchComplete );
    $result = sooner( $result, $nextPlayStarted );
    $result = sooner( $result, $nextPlayComplete );
    return $result;
}

sub sooner {
    my ( $soon, $event ) = @_;

    return ( $event > $time && $event < $soon ) ? $event : $soon;
}

sub perform {
    my $self = shift;

    Test::C2FIT::eg::music::MusicLibrary::searchComplete()
      if $time == $nextSearchComplete;
    Test::C2FIT::eg::music::MusicPlayer::playStarted()
      if $time == $nextPlayStarted;
    Test::C2FIT::eg::music::MusicPlayer::playComplete()
      if $time == $nextPlayComplete;
}

sub advance {
    my $self = shift;
    my ($future) = @_;

    #DEBUG print "advancing: $future ", (caller(1))[3], "\n";

    while ( $time < $future ) {
        $time = $self->nextEvent($future);
        $self->perform();
    }
}

sub schedule {
    my $self = shift;
    my ($seconds) = @_;
    return $time + ( $self->_round($seconds) );
}

sub delay {
    my $self = shift;
    my ($seconds) = @_;

    $seconds = $self->_round($seconds);

    $self->advance( $self->schedule($seconds) );
}

sub waitSearchComplete {
    my $self = shift;

    $self->advance($nextSearchComplete);
}

sub waitPlayStarted {
    my $self = shift;

    $self->advance($nextPlayStarted);
}

sub waitPlayComplete {
    my $self = shift;

    $self->advance($nextPlayComplete);
}

sub failLoadJam {
    my $self = shift;

    $Test::C2FIT::ActionFixture::actor =
      new Test::C2FIT::eg::music::Dialog( "load jamed",
        $Test::C2FIT::ActionFixture::actor );
}

sub _round {
    my $self    = shift;
    my $seconds = shift;

    return int( $seconds + 0.5 );

    my $roundDown = int($seconds);

    my $fractionalPart = $seconds - $roundDown;

    # warn "Seconds: $seconds, Down: $roundDown, Fract: $fractionalPart";

    return 1;
    return ( $fractionalPart >= .5 ? $seconds + 1 : $seconds );

}

1;

__END__

// Copyright (c) 2002 Cunningham & Cunningham, Inc.
// Released under the terms of the GNU General Public License version 2 or later.

package eg.music;

import fit.*;
import java.util.Date;

public class Simulator {

    // This discrete event simulator supports three events
    // each of which is open coded in the body of the simulator.

    static Simulator system = new Simulator();
    static long time = new Date().getTime();

    public static long nextSearchComplete = 0;
    public static long nextPlayStarted = 0;
    public static long nextPlayComplete = 0;

    long nextEvent(long bound) {
        long result = bound;
        result = sooner(result, nextSearchComplete);
        result = sooner(result, nextPlayStarted);
        result = sooner(result, nextPlayComplete);
        return result;
    }

    long sooner (long soon, long event) {
        return event > time && event < soon ? event : soon;
    }

    void perform() {
        if (time == nextSearchComplete)     {MusicLibrary.searchComplete();}
        if (time == nextPlayStarted)        {MusicPlayer.playStarted();}
        if (time == nextPlayComplete)       {MusicPlayer.playComplete();}
    }

    void advance (long future) {
        while (time < future) {
            time = nextEvent(future);
            perform();
        }
    }

    static long schedule(double seconds){
        return time + (long)(1000 * seconds);
    }

    void delay (double seconds) {
        advance(schedule(seconds));
    }

    public void waitSearchComplete() {
        advance(nextSearchComplete);
    }

    public void waitPlayStarted() {
        advance(nextPlayStarted);
    }

    public void waitPlayComplete() {
        advance(nextPlayComplete);
    }

    public void failLoadJam() {
        ActionFixture.actor = new Dialog("load jamed", ActionFixture.actor);
    }


}
