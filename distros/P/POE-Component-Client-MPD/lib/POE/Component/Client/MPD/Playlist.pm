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

package POE::Component::Client::MPD::Playlist;
# ABSTRACT: module handling playlist commands
$POE::Component::Client::MPD::Playlist::VERSION = '2.001';
use Moose;
use MooseX::Has::Sugar;
use POE;
use Readonly;

use POE::Component::Client::MPD::Message;


# -- attributes

has mpd => ( ro, required, weak_ref, );# isa=>'POE::Component::Client::MPD' );


# -- Playlist: retrieving information


sub _do_as_items {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'playlistinfo' ] );
    $msg->_set_cooking  ( 'as_items' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_items_changed_since {
    my ($self, $msg) = @_;
    my $plid = $msg->params->[0];

    $msg->_set_commands ( [ "plchanges $plid" ] );
    $msg->_set_cooking  ( 'as_items' );
    $self->mpd->_send_to_mpd( $msg );
}


# -- Playlist: adding / removing songs



sub _do_add {
    my ($self, $msg) = @_;

    my $args   = $msg->params;
    my @pathes = @$args;         # args of the poe event
    my @commands = (             # build the commands
        'command_list_begin',
        map( qq{add "$_"}, @pathes ),
        'command_list_end',
    );
    $msg->_set_commands ( \@commands );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_delete {
    my ($self, $msg) = @_;

    my $args    = $msg->params;
    my @numbers = @$args;
    my @commands = (              # build the commands
        'command_list_begin',
        map( qq{delete $_}, reverse sort {$a<=>$b} @numbers ),
        'command_list_end',
    );
    $msg->_set_commands ( \@commands );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_deleteid {
    my ($self, $msg) = @_;

    my $args    = $msg->params;
    my @songids = @$args;
    my @commands = (              # build the commands
        'command_list_begin',
        map( qq{deleteid $_}, @songids ),
        'command_list_end',
    );
    $msg->_set_commands ( \@commands );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_clear {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'clear' ] );
    $msg->_set_cooking  ( 'raw' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_crop {
    my ($self, $msg) = @_;

    if ( not defined $msg->_data ) {
        # no status yet - fire an event
        $msg->_set_post( 'pl.crop' );
        $self->mpd->_dispatch('status', $msg);
        return;
    }

    # now we know what to remove
    my $cur = $msg->_data->song;
    my $len = $msg->_data->playlistlength - 1;
    my @commands = (
        'command_list_begin',
        map( { $_ != $cur ? "delete $_" : '' } reverse 0..$len ),
        'command_list_end'
    );

    $msg->_set_cooking  ( 'raw' );
    $msg->_set_commands ( \@commands );
    $self->mpd->_send_to_mpd( $msg );
}


# -- Playlist: changing playlist order



sub _do_shuffle {
    my ($self, $msg) = @_;

    $msg->_set_cooking  ( 'raw' );
    $msg->_set_commands ( [ 'shuffle' ] );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_swap {
    my ($self, $msg) = @_;
    my ($from, $to) = @{ $msg->params }[0,1];

    $msg->_set_cooking  ( 'raw' );
    $msg->_set_commands ( [ "swap $from $to" ] );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_swapid {
    my ($self, $msg) = @_;
    my ($from, $to) = @{ $msg->params }[0,1];

    $msg->_set_cooking  ( 'raw' );
    $msg->_set_commands ( [ "swapid $from $to" ] );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_move {
    my ($self, $msg) = @_;
    my ($song, $pos) = @{ $msg->params }[0,1];

    $msg->_set_cooking  ( 'raw' );
    $msg->_set_commands ( [ "move $song $pos" ] );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_moveid {
    my ($self, $msg) = @_;
    my ($songid, $pos) = @{ $msg->params }[0,1];

    $msg->_set_cooking  ( 'raw' );
    $msg->_set_commands ( [ "moveid $songid $pos" ] );
    $self->mpd->_send_to_mpd( $msg );
}


# -- Playlist: managing playlists



sub _do_load {
    my ($self, $msg) = @_;
    my $playlist = $msg->params->[0];

    $msg->_set_cooking  ( 'raw' );
    $msg->_set_commands ( [ qq{load "$playlist"} ] );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_save {
    my ($self, $msg) = @_;
    my $playlist = $msg->params->[0];

    $msg->_set_cooking  ( 'raw' );
    $msg->_set_commands ( [ qq{save "$playlist"} ] );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_rm {
    my ($self, $msg) = @_;
    my $playlist = $msg->params->[0];

    $msg->_set_cooking  ( 'raw' );
    $msg->_set_commands ( [ qq{rm "$playlist"} ] );
    $self->mpd->_send_to_mpd( $msg );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

POE::Component::Client::MPD::Playlist - module handling playlist commands

=head1 VERSION

version 2.001

=head1 DESCRIPTION

L<POE::Component::Client::MPD::Playlist> is responsible for handling
general purpose commands. They are in a dedicated module to achieve
easier code maintenance.

To achieve those commands, send the corresponding event to the POCOCM
session you created: it will be responsible for dispatching the event
where it is needed. Under no circumstance should you call directly subs
or methods from this module directly.

Read L<POCOCM|POE::Component::Client::MPD>'s pod to learn how to deal
with answers from those commands.

Following is a list of playlist-related events accepted by POCOCM.

=head1 RETRIEVING INFORMATION

=head2 pl.as_items( )

Return an array of L<Audio::MPD::Common::Item::Song>s, one for each of
the songs in the current playlist.

=head2 pl.items_changed_since( $plversion )

Return a list with all the songs (as L<Audio::MPD::Common::Item::Song>
objects) added to the playlist since playlist C<$plversion>.

=head1 ADDING / REMOVING SONGS

=head2 pl.add( $path, $path, ... )

Add the songs identified by C<$path> (relative to MPD's music directory)
to the current playlist.

=head2 pl.delete( $number, $number, ... )

Remove song C<$number> (starting from 0) from the current playlist.

=head2 pl.deleteid( $songid, $songid, ... )

Remove the specified C<$songid> (as assigned by mpd when inserted in
playlist) from the current playlist.

=head2 pl.clear( )

Remove all the songs from the current playlist.

=head2 pl.crop( )

Remove all of the songs from the current playlist *except* the current one.

=head1 CHANGING PLAYLIST ORDER

=head2 pl.shuffle( )

Shuffle the current playlist.

=head2 pl.swap( $song1, $song2 )

Swap positions of song number C<$song1> and C<$song2> in the current
playlist.

=head2 pl.swapid( $songid1, $songid2 )

Swap positions of song id C<$songid1> and C<$songid2> in the current
playlist.

=head2 pl.move( $song, $newpos )

Move song number C<$song> to the position C<$newpos>.

=head2 pl.moveid( $songid, $newpos )

Move song id C<$songid> to the position C<$newpos>.

=head1 MANAGING PLAYLISTS

=head2 pl.load( $playlist )

Load list of songs from specified C<$playlist> file.

=head2 pl.save( $playlist )

Save the current playlist to a file called C<$playlist> in MPD's
playlist directory.

=head2 pl.rm( $playlist )

Delete playlist named C<$playlist> from MPD's playlist directory.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
