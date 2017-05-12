#!/usr/bin/env perl

use v5.10.2;
use strict;
use warnings;
use Net::DBus;
use Net::DBus::Reactor;
use Net::DBus::Dumper;
use Log::Any::Adapter;
use Log::Dispatch;
use Net::LCDproc;

no if $] >= 5.018, 'warnings', 'experimental::smartmatch';

my $log;
my $mediaplayer;
my $mpris;
my $lcdproc;
my $screen;
my $widget = {};

# map mpris playback states to icon names
my $icon = {
    Playing => 'PLAY',
    Paused  => 'PAUSE',
    Stopped => 'STOP',
};

sub start_logging {
    my $log =
      Log::Dispatch->new(outputs => [['Syslog', min_level => 'debug',]]);
    Log::Any::Adapter->set('Dispatch', dispatcher => $log);
    return $log;
}

sub get_metadata {

    my $raw_metadata =
      $mpris->Get('org.mpris.MediaPlayer2.Player', "Metadata");

    my $metadata = {
        artist     => ($raw_metadata->{'xesam:artist'}->[0] || 'unknown'),         # I am lazy
        album      => ($raw_metadata->{'xesam:album'} || 'unknown'),
        title      => $raw_metadata->{'xesam:title'},
        tracknum   => $raw_metadata->{'xesam:trackNumber'},
        length_sec => $raw_metadata->{'mpris:length'} / 1_000_000,
        playbackstatus =>
          $mpris->Get('org.mpris.MediaPlayer2.Player', 'PlaybackStatus'),
    };

    if ($metadata->{playbackstatus} eq 'Stopped') {
        $metadata->{artist_album_str} = 'Not Playing';
        $metadata->{track_str}        = '';
    } else {

        # space at the end because using marquee
        $metadata->{artist_album_str} = sprintf '%s :: %s :: ',
          $metadata->{artist}, $metadata->{album};
        $metadata->{track_str} = sprintf '%d. %s ',
          $metadata->{tracknum} // 0, $metadata->{title};
        $metadata->{position_sec} =
          $mpris->Get('org.mpris.MediaPlayer2.Player', "Position") / 1_000_000;
    }

    return $metadata;
}

sub get_mpris {
    my $bus = Net::DBus->session;

    # find a music player
    my $service = $bus->get_service("org.freedesktop.DBus");
    my $dbus    = $service->get_object("/org/freedesktop/DBus");
    foreach (@{$dbus->ListNames}) {
        next if not m/org\.mpris\.MediaPlayer2/;
        $log->info("Trying '$_'");
        my $mpris_service = $bus->get_service($_);
        $mpris = $mpris_service->get_object('/org/mpris/MediaPlayer2');
        $mediaplayer = $mpris->Get('org.mpris.MediaPlayer2', 'Identity');
        $log->info("Using $mediaplayer");
        last;
    }
}

sub calc_bar_length {
    my $metadata = shift;
    
    if (!$metadata->{length_sec}) {
        return 0;
    }

    if (!$metadata->{position_sec}) {
        return 0;
    }

    my $total_screen_length = $lcdproc->width * $lcdproc->cell_width;

    my $curr_pc = $metadata->{position_sec} / $metadata->{length_sec} * 100;
    $log->debug(sprintf 'Track progress: %.2f%%', $curr_pc);

    my $length = int($total_screen_length * ($curr_pc / 100));
    return $length;
}

sub setup_screen {

    my $server = shift @ARGV || 'localhost';
    $lcdproc = Net::LCDproc->new(server => $server);
    $screen = Net::LCDproc::Screen->new(id => 'mediaplayer');
    $lcdproc->add_screen($screen);

    my $metadata = get_metadata;

    $widget->{artist_album} = Net::LCDproc::Widget::Scroller->new(
        id        => 'artist_album',
        left      => 1,
        top       => 1,
        right     => $lcdproc->width,
        bottom    => 1,
        speed     => 5,
        direction => 'm',
        text      => $metadata->{artist_album_str},
    );
    $screen->add_widget($widget->{artist_album});

    $widget->{track} = Net::LCDproc::Widget::Scroller->new(
        id        => 'track',
        left      => 1,
        top       => 2,
        right     => $lcdproc->width,
        bottom    => 2,
        speed     => 5,
        direction => 'm',
        text      => $metadata->{track_str},
    );
    $screen->add_widget($widget->{track});

    $widget->{icon} = Net::LCDproc::Widget::Icon->new(
        id       => 'icon',
        x        => $lcdproc->width / 2,
        y        => 3,
        iconname => $icon->{$metadata->{playbackstatus}},
    );
    $screen->add_widget($widget->{icon});

    $widget->{progress} = Net::LCDproc::Widget::HBar->new(
        id     => 'progress',
        x      => 1,
        y      => 4,
        length => calc_bar_length($metadata),
    );
    $screen->add_widget($widget->{progress});

}

sub update_status {
    my ($changed) = shift;

    # TODO if the metadata changes, it get passed from dbus
    my $metadata = get_metadata;
    my $playbackstatus =
      $mpris->Get('org.mpris.MediaPlayer2.Player', 'PlaybackStatus');

    given ($playbackstatus) {
        when ('Stopped') {
            $widget->{artist_album}->text('Nothing playing');
        }
        when ('Paused') {

            # icon
        }
        default {
            my $length = calc_bar_length($metadata);
            $widget->{progress}->length($length);
        }
    }

    if ($changed) {
        $log->debug('Something changed so updating EVERYTHING');

        if ($metadata) {
            $widget->{track}->text($metadata->{track_str});
            $widget->{artist_album}->text($metadata->{artist_album_str});
            $widget->{icon}->iconname($icon->{$metadata->{playbackstatus}}),;
        }
    }

    $lcdproc->update;
}

$log = start_logging;
get_mpris;
setup_screen;
say "Starting main loop. Check your syslog";

my $reactor = Net::DBus::Reactor->main;

# a better program might care *what* changed
$mpris->connect_to_signal('PropertiesChanged', \&update_status);
my $timer = $reactor->add_timeout(1000, \&update_status);

$reactor->run;
