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

package POE::Component::Client::MPD::Collection;
# ABSTRACT: module handling collection commands
$POE::Component::Client::MPD::Collection::VERSION = '2.001';
use Moose;
use MooseX::Has::Sugar;
use POE;

use POE::Component::Client::MPD::Message;

has mpd => ( ro, required, weak_ref, );# isa=>'POE::Component::Client::MPD' );


# -- Collection: retrieving songs & directories


sub _do_all_items {
    my ($self, $msg) = @_;
    my $path = $msg->params->[0] // ''; # FIXME: padre//

    $msg->_set_commands ( [ qq{listallinfo "$path"} ] );
    $msg->_set_cooking  ( 'as_items' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_all_items_simple {
    my ($self, $msg) = @_;
    my $path = $msg->params->[0] // ''; # FIXME: padre//

    $msg->_set_commands ( [ qq{listall "$path"} ] );
    $msg->_set_cooking  ( 'as_items' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_items_in_dir {
    my ($self, $msg) = @_;
    my $path = $msg->params->[0] // ''; # FIXME: padre//

    $msg->_set_commands ( [ qq{lsinfo "$path"} ] );
    $msg->_set_cooking  ( 'as_items' );
    $self->mpd->_send_to_mpd( $msg );
}



# -- Collection: retrieving the whole collection

# event: coll.all_songs()
# FIXME?


sub _do_all_albums {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'list album' ] );
    $msg->_set_cooking  ( 'strip_first' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_all_artists {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'list artist' ] );
    $msg->_set_cooking  ( 'strip_first' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_all_titles {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'list title' ] );
    $msg->_set_cooking  ( 'strip_first' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_all_files {
    my ($self, $msg) = @_;

    $msg->_set_commands ( [ 'list filename' ] );
    $msg->_set_cooking  ( 'strip_first' );
    $self->mpd->_send_to_mpd( $msg );
}


# -- Collection: picking songs


sub _do_song {
    my ($self, $msg) = @_;
    my $what = $msg->params->[0];

    $msg->_set_commands ( [ qq{find filename "$what"} ] );
    $msg->_set_cooking  ( 'as_items' );
    $msg->_set_transform( 'as_scalar' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_songs_with_filename_partial {
    my ($self, $msg) = @_;
    my $what = $msg->params->[0];

    $msg->_set_commands ( [ qq{search filename "$what"} ] );
    $msg->_set_cooking  ( 'as_items' );
    $self->mpd->_send_to_mpd( $msg );
}


# -- Collection: songs, albums & artists relations


sub _do_albums_by_artist {
    my ($self, $msg) = @_;
    my $what = $msg->params->[0];

    $msg->_set_commands ( [ qq{list album "$what"} ] );
    $msg->_set_cooking  ( 'strip_first' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_songs_by_artist {
    my ($self, $msg) = @_;
    my $what = $msg->params->[0];

    $msg->_set_commands ( [ qq{find artist "$what"} ] );
    $msg->_set_cooking  ( 'as_items' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_songs_by_artist_partial {
    my ($self, $msg) = @_;
    my $what = $msg->params->[0];

    $msg->_set_commands ( [ qq{search artist "$what"} ] );
    $msg->_set_cooking  ( 'as_items' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_songs_from_album {
    my ($self, $msg) = @_;
    my $what = $msg->params->[0];

    $msg->_set_commands ( [ qq{find album "$what"} ] );
    $msg->_set_cooking  ( 'as_items' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_songs_from_album_partial {
    my ($self, $msg) = @_;
    my $what = $msg->params->[0];

    $msg->_set_commands ( [ qq{search album "$what"} ] );
    $msg->_set_cooking  ( 'as_items' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_songs_with_title {
    my ($self, $msg) = @_;
    my $what = $msg->params->[0];

    $msg->_set_commands ( [ qq{find title "$what"} ] );
    $msg->_set_cooking  ( 'as_items' );
    $self->mpd->_send_to_mpd( $msg );
}



sub _do_songs_with_title_partial {
    my ($self, $msg) = @_;
    my $what = $msg->params->[0];

    $msg->_set_commands ( [ qq{search title "$what"} ] );
    $msg->_set_cooking  ( 'as_items' );
    $self->mpd->_send_to_mpd( $msg );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

POE::Component::Client::MPD::Collection - module handling collection commands

=head1 VERSION

version 2.001

=head1 DESCRIPTION

L<POE::Component::Client::MPD::Collection> is responsible for handling
general purpose commands. They are in a dedicated module to achieve
easier code maintenance.

To achieve those commands, send the corresponding event to the
L<POE::Component::Client::MPD> session you created: it will be
responsible for dispatching the event where it is needed. Under no
circumstance should you call directly subs or methods from this
module directly.

Read L<POE::Component::Client::MPD>'s pod to learn how to deal with
answers from those commands.

Following is a list of collection-related events accepted by POCOCM.

=head1 RETRIEVING SONGS & DIRECTORIES

=head2 coll.all_items( [$path] )

Return all L<Audio::MPD::Common::Item>s (both songs & directories)
currently known by mpd.

If C<$path> is supplied (relative to mpd root), restrict the retrieval to
songs and dirs in this directory.

=head2 coll.all_items_simple( [$path] )

Return all L<Audio::MPD::Common::Item>s (both songs & directories)
currently known by mpd.

If C<$path> is supplied (relative to mpd root), restrict the retrieval
to songs and dirs in this directory.

B</!\ Warning>: the L<Audio::MPD::Common::Item::Song> objects will only
have their attribute file filled. Any other attribute will be empty, so
don't use this sub for any other thing than a quick scan!

=head2 coll.items_in_dir( [$path] )

Return the items in the given C<$path>. If no C<$path> supplied, do it on mpd's
root directory.

Note that this sub does not work recusrively on all directories.

=head1 RETRIEVING THE WHOLE COLLECTION

=head2 coll.all_albums( )

Return the list of all albums (strings) currently known by mpd.

=head2 coll.all_artists( )

Return the list of all artists (strings) currently known by mpd.

=head2 coll.all_titles( )

Return the list of all titles (strings) currently known by mpd.

=head2 coll.all_files( )

Return a mpd_result event with the list of all filenames (strings)
currently known by mpd.

=head1 PICKING A SONG

=head2 coll.song( $path )

Return the L<Audio::MPD::Common::Item::Song> which correspond to
C<$path>.

=head2 coll.songs_with_filename_partial( $string )

Return the L<Audio::MPD::Common::Item::Song>s containing C<$string> in
their path.

=head1 SONGS, ALBUMS & ARTISTS RELATIONS

=head2 coll.albums_by_artist( $artist )

Return all albums (strings) performed by C<$artist> or where C<$artist>
participated.

=head2 coll.songs_by_artist( $artist )

Return all L<Audio::MPD::Common::Item::Song>s performed by C<$artist>.

=head2 coll.songs_by_artist_partial( $artist )

Return all L<Audio::MPD::Common::Item::Song>s performed by C<$artist>.

=head2 coll.songs_from_album( $album )

Return all L<Audio::MPD::Common::Item::Song>s appearing in C<$album>.

=head2 coll.songs_from_album_partial( $string )

Return all L<Audio::MPD::Common::Item::Song>s appearing in album
containing C<$string>.

=head2 coll.songs_with_title( $title )

Return all L<Audio::MPD::Common::Item::Song>s which title is exactly
C<$title>.

=head2 coll.songs_with_title_partial( $string )

Return all L<Audio::MPD::Common::Item::Song>s where C<$string> is part
of the title.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
