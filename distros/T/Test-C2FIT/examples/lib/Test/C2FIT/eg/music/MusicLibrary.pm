# MusicLibrary.pm
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::eg::music::MusicLibrary;

use strict;

use vars qw($looking @library);
use Test::C2FIT::eg::music::Music;
use Test::C2FIT::eg::music::Simulator;
use File::Basename qw(dirname basename);

$looking = undef;
@library = ();

sub load {
    my $self = shift;
    my ($name) = @_;

    my @dirs = qw(music eg src src/eg);
    push( @dirs, dirname($name) );

    my $fn = basename($name);

    for my $dir (@dirs) {
        $name = "$dir/$fn";
        last if -f "$name" && -r "$name";
    }

    open( MUSIC, "$name" ) or die "$name: $!\n";
    my $ignore = <MUSIC>;    # ignore header line
    while (<MUSIC>) {
        chomp;
        push @library, Test::C2FIT::eg::music::Music::parse($_);
    }
    close(MUSIC);
}

sub library {
    return @library;
}

sub select {
    my ($m) = @_;
    $looking = $m;
}

sub search {
    my ($seconds) = @_;
    $Test::C2FIT::eg::music::status                        = "searching";
    $Test::C2FIT::eg::music::Simulator::nextSearchComplete =
      Test::C2FIT::eg::music::Simulator->schedule($seconds);
}

sub searchComplete {
    $Test::C2FIT::eg::music::status =
      defined($Test::C2FIT::eg::music::playing) ? "playing" : "ready";
}

sub findAll {
    search(3.2);
    foreach my $music (@library) {
        $music->{'selected'} = 1;
    }
}

sub findArtist {
    my ($artist) = @_;
    search(2.3);
    foreach my $music (@library) {
        $music->{'selected'} = $music->{'artist'} eq $artist;
    }
}

sub findAlbum {
    my ($album) = @_;
    search(1.1);
    foreach my $music (@library) {
        $music->{'selected'} = $music->{'album'} eq $album;
    }
}

sub findGenre {
    my ($genre) = @_;
    search(0.2);
    foreach my $music (@library) {
        $music->{'selected'} = $music->{'genre'} eq $genre;
    }
}

sub findYear {
    my ($year) = @_;
    search(0.8);
    foreach my $music (@library) {
        $music->{'selected'} = $music->{'year'} eq $year;
    }
}

sub displayCount {
    my $count = 0;
    foreach my $music (@library) {
        $count += $music->{'selected'};
    }
    return $count;
}

sub displayContents {
    my @displayed = ();
    foreach my $music (@library) {
        push @displayed, $music if $music->{'selected'};
    }
    return [@displayed];
}

sub looking {
    return $looking;
}

1;

__END__

// Copyright (c) 2002 Cunningham & Cunningham, Inc.
// Read license.txt in this directory.

package eg.music;

import java.io.*;
import java.util.*;

public class MusicLibrary {
    static Music looking = null;
    static Music library[] = {};

    static void load(String name) throws Exception {
        List music = new ArrayList();
        BufferedReader in = new BufferedReader(new FileReader(name));
        in.readLine(); // skip column headings
        while(in.ready()) {
            music.add(Music.parse(in.readLine()));
        }
        in.close();
        library = (Music[])music.toArray(library);
    }

    static void select(Music m) {
        looking = m;
    }

    static void search(double seconds){
        Music.status = "searching";
        Simulator.nextSearchComplete = Simulator.schedule(seconds);
    }

    static void searchComplete() {
        Music.status = MusicPlayer.playing == null ? "ready" : "playing";
    }

    static void findAll() {
        search(3.2);
        for (int i=0; i<library.length; i++) {
            library[i].selected = true;
        }
    }

    static void findArtist(String a) {
        search(2.3);
        for (int i=0; i<library.length; i++) {
            library[i].selected = library[i].artist.equals(a);
        }
    }

    static void findAlbum(String a) {
        search(1.1);
        for (int i=0; i<library.length; i++) {
            library[i].selected = library[i].album.equals(a);
        }
    }

    static void findGenre(String a) {
        search(0.2);
        for (int i=0; i<library.length; i++) {
            library[i].selected = library[i].genre.equals(a);
        }
    }

    static void findYear(int a) {
        search(0.8);
        for (int i=0; i<library.length; i++) {
            library[i].selected = library[i].year == a;
        }
    }

    static int displayCount() {
        int count = 0;
        for (int i=0; i<library.length; i++) {
            count += (library[i].selected ? 1 : 0);
        }
        return count;
    }

    static Music[] displayContents () {
        Music displayed[] = new Music[displayCount()];
        for (int i=0, j=0; i<library.length; i++) {
            if (library[i].selected) {
                displayed[j++] = library[i];
            }
        }
        return displayed;
    }

}
