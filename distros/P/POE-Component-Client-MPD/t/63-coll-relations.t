#!perl
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

use POE;
use POE::Component::Client::MPD;
use POE::Component::Client::MPD::Test;
use Test::More;

# are we able to test module?
eval 'use Test::Corpus::Audio::MPD';
plan skip_all => $@ if $@ =~ s/\n+Compilation failed.*//s;
plan tests => 38;

# launch fake mpd
POE::Component::Client::MPD->spawn;

# launch the tests
POE::Component::Client::MPD::Test->new( { tests => [
    # [ 'event', [ $arg1, $arg2, ... ], $sleep, \&check_results ]

    # albums_by_artist
    [ 'coll.albums_by_artist',         ['dir1-artist'], 0, \&check_albums_by_artist         ],

    # songs_by_artist
    [ 'coll.songs_by_artist',          ['dir1-artist'], 0, \&check_songs_by_artist          ],

    # songs_by_artist_partial
    [ 'coll.songs_by_artist_partial',       ['artist'], 0, \&check_songs_by_artist_partial  ],

    # songs_from_album
    [ 'coll.songs_from_album',           ['our album'], 0, \&check_songs_from_album         ],

    # songs_from_album_partial
    [ 'coll.songs_from_album_partial',       ['album'], 0, \&check_songs_from_album_partial ],

    # songs_with_title
    [ 'coll.songs_with_title',            ['ok-title'], 0, \&check_songs_with_title         ],

    # songs_with_title_partial
    [ 'coll.songs_with_title_partial',       ['title'], 0, \&check_songs_with_title_partial ],
] } );
POE::Kernel->run;
exit;

#--

sub check_success {
    my ($msg) = @_;
    is($msg->status, 1, "command '" . $msg->request . "' returned an ok status");
}

sub check_albums_by_artist {
    my ($msg, $items) = @_;
    check_success($msg);
    # mpd 0.14 returns empty strings too
    is(scalar @$items, 2, 'albums_by_artist() return the album');
    is($items->[1], 'our album', 'albums_by_artist() return plain strings');
}

sub check_songs_by_artist {
    my ($msg, $items) = @_;
    check_success($msg);
    is(scalar @$items, 3, 'songs_by_artist() return all the songs found' );
    isa_ok($_, 'Audio::MPD::Common::Item::Song', 'songs_by_artist() return') for @$items;
    is($items->[0]->artist, 'dir1-artist', 'songs_by_artist() return correct objects');
}

sub check_songs_by_artist_partial {
    my ($msg, $items) = @_;
    check_success($msg);
    is(scalar @$items, 3, 'songs_by_artist_partial() return all the songs found');
    isa_ok($_, 'Audio::MPD::Common::Item::Song', 'songs_by_artist_partial() return') for @$items;
    like($items->[0]->artist, qr/artist/, 'songs_by_artist_partial() return correct objects');
}


sub check_songs_from_album {
    my ($msg, $items) = @_;
    check_success($msg);
    is(scalar @$items, 3, 'songs_from_album() return all the songs found');
    isa_ok($_, 'Audio::MPD::Common::Item::Song', 'songs_from_album() return') for @$items;
    is($items->[0]->album, 'our album', 'songs_from_album() return correct objects' );
}

sub check_songs_from_album_partial {
    my ($msg, $items) = @_;
    check_success($msg);
    is(scalar @$items, 3, 'songs_from_album_partial() return all the songs found' );
    isa_ok($_, 'Audio::MPD::Common::Item::Song', 'songs_from_album_partial() return') for @$items;
    like($items->[0]->album, qr/album/, 'songs_from_album_partial() return correct objects');
}

sub check_songs_with_title {
    my ($msg, $items) = @_;
    check_success($msg);
    is(scalar @$items, 1, 'songs_with_title() return all the songs found');
    isa_ok($_, 'Audio::MPD::Common::Item::Song', 'songs_with_title() return') for @$items;
    is($items->[0]->title, 'ok-title', 'songs_with_title() return correct objects');
}

sub check_songs_with_title_partial {
    my ($msg, $items) = @_;
    check_success($msg);
    is(scalar @$items, 4, 'songs_with_title_partial() return all the songs found');
    isa_ok($_, 'Audio::MPD::Common::Item::Song', 'songs_with_title_partial() return') for @$items;
    like($items->[0]->title, qr/title/, 'songs_with_title_partial() return correct objects');
}

