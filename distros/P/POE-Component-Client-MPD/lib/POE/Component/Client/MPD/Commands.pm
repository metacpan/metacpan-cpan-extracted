#
# This file is part of POE-Component-Client-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package POE::Component::Client::MPD::Commands;
# ABSTRACT: module handling basic mpd commands
$POE::Component::Client::MPD::Commands::VERSION = '2.001';
use Moose;
use MooseX::Has::Sugar;
use POE;
use Readonly;

use POE::Component::Client::MPD::Message;

Readonly my $K => $poe_kernel;


# -- attributes

has mpd => ( ro, required, weak_ref, );# isa=>'POE::Component::Client::MPD' );


# -- MPD interaction: general commands


sub _do_version {
    my ($self, $msg) = @_;
    $msg->set_status(1);
    $K->post( $msg->_from, 'mpd_result', $msg, $self->mpd->version );
}



sub _do_password {
    my ($self, $msg) = @_;
    my $pw = $msg->params->[0];
    $msg->_set_commands( [ qq{password $pw} ] );
    $msg->_set_cooking ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_kill {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'kill' ] );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
    $K->delay_set('disconnect'=>1);
}



sub _do_updatedb {
    my ($self, $msg) = @_;
    my $path = $msg->params->[0] // '';  # FIXME: padre//

    $msg->_set_commands( [ qq{update "$path"} ] );
    $msg->_set_cooking ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_urlhandlers {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'urlhandlers' ] );
    $msg->_set_cooking  ( 'strip_first' );
    $self->mpd->_send_to_mpd( $msg );
}


# -- MPD interaction: handling volume & output



sub _do_volume {
    my ($self, $msg) = @_;

    my $volume;
    if ( $msg->params->[0] =~ /^(-|\+)(\d+)/ ) {
        my ($op, $delta) = ($1, $2);
        if ( not defined $msg->_data ) {
            # no status yet - fire an event
            $msg->_set_post( 'volume' );
            $self->mpd->_dispatch('status', $msg);
            return;
        }

        # already got a status result
        my $curvol = $msg->_data->volume;
        $volume = $op eq '+' ? $curvol + $delta : $curvol - $delta;
    } else {
        $volume = $msg->params->[0];
    }

    $msg->_set_commands ( [ "setvol $volume" ] );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_output_enable {
    my ($self, $msg) = @_;
    my $output = $msg->params->[0];

    $msg->_set_commands ( [ "enableoutput $output" ] );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_output_disable {
    my ($self, $msg) = @_;
    my $output = $msg->params->[0];

    $msg->_set_commands ( [ "disableoutput $output" ] );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



# -- MPD interaction: retrieving info from current state


sub _do_stats {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'stats' ] );
    $msg->_set_cooking  ( 'as_kv' );
    $msg->_set_transform( 'as_stats' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_status {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'status' ] );
    $msg->_set_cooking  ( 'as_kv' );
    $msg->_set_transform( 'as_status' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_current {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'currentsong' ] );
    $msg->_set_cooking  ( 'as_items' );
    $msg->_set_transform( 'as_scalar' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_song {
    my ($self, $msg) = @_;
    my $song = $msg->params->[0];

    $msg->_set_commands ( [ defined $song ? "playlistinfo $song" : 'currentsong' ] );
    $msg->_set_cooking  ( 'as_items' );
    $msg->_set_transform( 'as_scalar' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_songid {
    my ($self, $msg) = @_;
    my $song = $msg->params->[0];

    $msg->_set_commands ( [ defined $song ? "playlistid $song" : 'currentsong' ] );
    $msg->_set_cooking  ( 'as_items' );
    $msg->_set_transform( 'as_scalar' );
    $self->mpd->_send_to_mpd( $msg );
}


# -- MPD interaction: altering settings



sub _do_repeat {
    my ($self, $msg) = @_;

    my $mode = $msg->params->[0];
    if ( defined $mode )  {
        $mode = $mode ? 1 : 0;   # force integer
    } else {
        if ( not defined $msg->_data ) {
            # no status yet - fire an event
            $msg->_set_post( 'repeat' );
            $self->mpd->_dispatch('status', $msg);
            return;
        }

        $mode = $msg->_data->repeat ? 0 : 1; # negate current value
    }

    $msg->_set_cooking ( 'raw' );
    $msg->_set_commands( [ "repeat $mode" ] );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_fade {
    my ($self, $msg) = @_;
    my $seconds = $msg->params->[0] // 0;  # FIXME: padre//

    $msg->_set_commands ( [ "crossfade $seconds" ] );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_random {
    my ($self, $msg) = @_;

    my $mode = $msg->params->[0];
    if ( defined $mode )  {
        $mode = $mode ? 1 : 0;   # force integer
    } else {
        if ( not defined $msg->_data ) {
            # no status yet - fire an event
            $msg->_set_post( 'random' );
            $self->mpd->_dispatch('status', $msg);
            return;
        }

        $mode = $msg->_data->random ? 0 : 1; # negate current value
    }

    $msg->_set_cooking ( 'raw' );
    $msg->_set_commands( [ "random $mode" ] );
    $self->mpd->_send_to_mpd( $msg );
}


# -- MPD interaction: controlling playback


sub _do_play {
    my ($self, $msg) = @_;

    my $number = $msg->params->[0] // ''; # FIXME: padre//
    $msg->_set_commands ( [ "play $number" ] );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_playid {
    my ($self, $msg) = @_;

    my $number = $msg->params->[0] // ''; # FIXME: padre//
    $msg->_set_commands ( [ "playid $number" ] );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_pause {
    my ($self, $msg) = @_;

    my $state = $msg->params->[0] // '';  # FIXME: padre//
    $msg->_set_commands ( [ "pause $state" ] );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_stop {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'stop' ] );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_next {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'next' ] );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_prev {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'previous' ] );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_seek {
    my ($self, $msg) = @_;

    my ($time, $song) = @{ $msg->params }[0,1];
    $time ||= 0; $time = int $time;
    if ( not defined $song )  {
        if ( not defined $msg->_data ) {
            # no status yet - fire an event
            $msg->_set_post( 'seek' );
            $self->mpd->_dispatch('status', $msg);
            return;
        }

        $song = $msg->_data->song;
    }

    $msg->_set_cooking ( 'raw' );
    $msg->_set_commands( [ "seek $song $time" ] );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_seekid {
    my ($self, $msg) = @_;

    my ($time, $songid) = @{ $msg->params }[0,1];
    $time ||= 0; $time = int $time;
    if ( not defined $songid )  {
        if ( not defined $msg->_data ) {
            # no status yet - fire an event
            $msg->_set_post( 'seekid' );
            $self->mpd->_dispatch('status', $msg);
            return;
        }

        $songid = $msg->_data->songid;
    }

    $msg->_set_cooking ( 'raw' );
    $msg->_set_commands( [ "seekid $songid $time" ] );
    $self->mpd->_send_to_mpd( $msg );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

POE::Component::Client::MPD::Commands - module handling basic mpd commands

=head1 VERSION

version 2.001

=head1 DESCRIPTION

L<POE::Component::Client::MPD::Commands> is responsible for handling
general purpose commands. They are in a dedicated module to achieve
easier code maintenance.

To achieve those commands, send the corresponding event to the POCOCM
session you created: it will be responsible for dispatching the event
where it is needed. Under no circumstance should you call directly subs
or methods from this module directly.

Read POCOCM's pod to learn how to deal with answers from those commands.

Following is a list of general purpose events accepted by POCOCM.

=head1 CONTROLLING THE SERVER

=head2 version( )

Return mpd's version number as advertised during connection. Note that
mpd returns B<protocol> version when connected. This protocol version can
differ from the real mpd version. eg, mpd version 0.13.2 is "speaking"
and thus advertising version 0.13.0.

=head2 password( $password )

Sends a connection password to mpd. Used internally on connect, but can
be called whenever if you're feeling like it.

=head2 kill( )

Kill the mpd server, and request the pococm to be shutdown.

=head2 updatedb( [$path] )

Force mpd to rescan its collection. If C<$path> (relative to MPD's music
directory) is supplied, MPD will only scan it - otherwise, MPD will
rescan its whole collection.

=head2 urlhandlers( )

Return an array of supported URL schemes.

=head1 HANDLING VOLUME & OUTPUT

=head2 volume( $volume )

Sets the audio output volume percentage to absolute C<$volume>. If
C<$volume> is prefixed by '+' or '-' then the volume is changed
relatively by that value.

=head2 output_enable( $output )

Enable the specified audio output. C<$output> is the ID of the audio
output.

=head2 output_disable( $output )

Disable the specified audio output. C<$output> is the ID of the audio output.

=head1 RETRIEVING INFO FROM CURRENT STATE

=head2 stats( )

Return an L<Audio::MPD::Common::Stats> object with the current
statistics of MPD.

=head2 status( )

Return an L<Audio::MPD::Common::Status> object with the current
status of MPD.

=head2 current( )

Return an L<Audio::MPD::Common::Item::Song> representing the song
currently playing.

=head2 song( [$song] )

Return an L<Audio::MPD::Common::Item::Song> representing the song number
C<$song>. If C<$song> is not supplied, returns the current song.

=head2 songid( [$songid] )

Return an L<Audio::MPD::Common::Item::Song> representing the song id
C<$songid>. If C<$songid> is not supplied, returns the current song.

=head1 ALTERING MPD SETTINGS

=head2 repeat( [$repeat] )

Set the repeat mode to C<$repeat> (1 or 0). If C<$repeat> is not
specified then the repeat mode is toggled.

=head2 fade( [$seconds] )

Enable crossfading and set the duration of crossfade between songs. If
C<$seconds> is not specified or C<$seconds> is 0, then crossfading is
disabled.

=head2 random( [$random] )

Set the random mode to C<$random> (1 or 0). If C<$random> is not
specified then the random mode is toggled.

=head1 CONTROLLING PLAYBACK

=head2 play( [$song] )

Begin playing playlist at song number C<$song>. If no argument supplied,
resume playing.

=head2 playid( [$song] )

Begin playing playlist at song ID C<$song>. If no argument supplied,
resume playing.

=head2 pause( [$sate] )

Pause playback. If C<$state> is 0 then the current track is unpaused, if
C<$state> is 1 then the current track is paused.

Note that if C<$state> is not given, pause state will be toggled.

=head2 stop( )

Stop playback.

=head2 next( )

Play next song in playlist.

=head2 prev( )

Play previous song in playlist.

=head2 seek( $time, [$song] )

Seek to C<$time> seconds in song number C<$song>. If C<$song> number is
not specified then the perl module will try and seek to C<$time> in the
current song.

=head2 seekid( $time, [$songid] )

Seek to C<$time> seconds in song ID C<$songid>. If C<$songid> number is
not specified then the perl module will try and seek to C<$time> in the
current song.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
