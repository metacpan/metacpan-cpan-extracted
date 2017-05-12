# Browser.pm
#
# Copyright (c) 2002 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>

package Test::C2FIT::eg::music::Browser;

use base qw(Test::C2FIT::Fixture);
use strict;
use Test::C2FIT::eg::music::MusicLibrary;
use Test::C2FIT::eg::music::MusicPlayer;

sub library {
    my $self = shift;
    my ($path) = @_;

    Test::C2FIT::eg::music::MusicLibrary->load($path);
}

sub totalSongs {
    my $self = shift;

    return scalar @Test::C2FIT::eg::music::MusicLibrary::library;
}

sub playing {
    my $self = shift;

    return Test::C2FIT::eg::music::MusicPlayer::playing()->title();
}

sub select {
    my $self = shift;
    my ($index) = @_;

    Test::C2FIT::eg::music::MusicLibrary::select(
        $Test::C2FIT::eg::music::MusicLibrary::library[ $index - 1 ] );
}

sub title {
    my $self = shift;

    return Test::C2FIT::eg::music::MusicLibrary::looking()->title();
}

sub artist {
    my $self = shift;

    return Test::C2FIT::eg::music::MusicLibrary::looking()->artist();
}

sub album {
    my $self = shift;

    return Test::C2FIT::eg::music::MusicLibrary::looking()->album();
}

sub year {
    my $self = shift;

    return Test::C2FIT::eg::music::MusicLibrary::looking()->year();
}

sub time {
    my $self = shift;

    return Test::C2FIT::eg::music::MusicLibrary::looking()->time();
}

sub track {
    my $self = shift;

    return Test::C2FIT::eg::music::MusicLibrary::looking()->track();
}

# Search buttons

sub sameAlbum {
    my $self = shift;

    Test::C2FIT::eg::music::MusicLibrary::findAlbum(
        Test::C2FIT::eg::music::MusicLibrary::looking()->album() );
}

sub sameArtist {
    my $self = shift;

    Test::C2FIT::eg::music::MusicLibrary::findArtist(
        Test::C2FIT::eg::music::MusicLibrary::looking()->artist() );
}

sub sameGenre {
    my $self = shift;

    Test::C2FIT::eg::music::MusicLibrary::findGenre(
        Test::C2FIT::eg::music::MusicLibrary::looking()->genre() );
}

sub sameYear {
    my $self = shift;

    Test::C2FIT::eg::music::MusicLibrary::findYear(
        Test::C2FIT::eg::music::MusicLibrary::looking()->year() );
}

sub selectedSongs {
    return Test::C2FIT::eg::music::MusicLibrary::displayCount();
}

sub showAll {
    Test::C2FIT::eg::music::MusicLibrary::findAll();
}

# Play buttons

sub play {
    Test::C2FIT::eg::music::MusicPlayer::play(
        Test::C2FIT::eg::music::MusicLibrary::looking() );
}

sub pause {
    Test::C2FIT::eg::music::MusicPlayer::pause();
}

sub status {
    my $self = shift;

    return $Test::C2FIT::eg::music::Music::status;
}

sub remaining {
    my $self = shift;

    return Test::C2FIT::eg::music::MusicPlayer::minutesRemaining();
}

1;

__END__

// Copyright (c) 2002 Cunningham & Cunningham, Inc.
// Released under the terms of the GNU General Public License version 2 or later.

package eg.music;

import fit.*;

public class Browser extends Fixture {


    // Library //////////////////////////////////

    public void library (String path) throws Exception {
        MusicLibrary.load(path);
    }

    public int totalSongs() {
        return MusicLibrary.library.length;
    }

    // Select Detail ////////////////////////////

    public String playing () {
        return MusicPlayer.playing.title;
    }

    public void select (int i) {
        MusicLibrary.select(MusicLibrary.library[i-1]);
    }

    public String title() {
        return MusicLibrary.looking.title;
    }

    public String artist() {
        return MusicLibrary.looking.artist;
    }

    public String album() {
        return MusicLibrary.looking.album;
    }

    public int year() {
        return MusicLibrary.looking.year;
    }

    public double time() {
        return MusicLibrary.looking.time();
    }

    public String track() {
        return MusicLibrary.looking.track();
    }

    // Search Buttons ///////////////////////////

    public void sameAlbum() {
        MusicLibrary.findAlbum(MusicLibrary.looking.album);
    }

    public void sameArtist() {
        MusicLibrary.findArtist(MusicLibrary.looking.artist);
    }

    public void sameGenre() {
        MusicLibrary.findGenre(MusicLibrary.looking.genre);
    }

    public void sameYear() {
        MusicLibrary.findYear(MusicLibrary.looking.year);
    }

    public int selectedSongs() {
        return MusicLibrary.displayCount();
    }

    public void showAll() {
        MusicLibrary.findAll();
    }

    // Play Buttons /////////////////////////////

    public void play() {
        MusicPlayer.play(MusicLibrary.looking);
    }

    public void pause() {
        MusicPlayer.pause();
    }

    public String status() {
        return Music.status;
    }

    public double remaining() {
        return MusicPlayer.minutesRemaining();
    }

}
