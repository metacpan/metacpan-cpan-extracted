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
plan tests => 30;

# launch fake mpd
POE::Component::Client::MPD->spawn;

# launch the tests
my @songs   = qw{ title.ogg dir1/title-artist-album.ogg dir1/title-artist.ogg };
POE::Component::Client::MPD::Test->new( { tests => [
    # [ 'event', [ $arg1, $arg2, ... ], $sleep, \&check_results ]

    # stats
    [ 'updatedb', [],      0, \&check_success      ],
    [ 'pl.add',   \@songs, 0, \&check_success      ],
    [ 'stats',    [],      0, \&check_stats        ],

    # status
    [ 'play',     [],      0, \&check_success      ],
    [ 'pause',    [],      0, \&check_success      ],
    [ 'status',   [],      0, \&check_status       ],

    # current
    [ 'current',  [],      0, \&check_current      ],

    # song
    [ 'song',     [1],     0, \&check_song         ],
    [ 'song',     [],      0, \&check_song_current ],

    # songid (use the same checkers as song)
    [ 'songid',   [2],     0, \&check_song         ],
    [ 'songid',   [],      0, \&check_song_current ],
] } );
POE::Kernel->run;
exit;


#--

sub check_success {
    my ($msg) = @_;
    is($msg->status, 1, "command '" . $msg->request . "' returned an ok status");
}

sub check_stats {
    my ($msg, $stats) = @_;
    check_success($msg);
    isa_ok($stats, 'Audio::MPD::Common::Stats', 'stats() return');
    is($stats->artists,         1, 'one artist in the database');
    is($stats->albums,          1, 'one album in the database');
    is($stats->songs,           5, '5 songs in the database');
    is($stats->playtime,        0, 'already played 0 seconds');
    cmp_ok($stats->db_playtime, '>=',  9, '>= 9 seconds worth of music in the db');
    cmp_ok($stats->db_playtime, '<=', 10, '<= 10 seconds worth of music in the db');
    isnt($stats->uptime,    undef, 'uptime is defined');
    isnt($stats->db_update,     0, 'database has been updated');
}

sub check_status {
    my ($msg, $status) = @_;
    check_success($msg);
    isa_ok( $status, 'Audio::MPD::Common::Status', 'status() return');
}

sub check_current {
    my ($msg, $song) = @_;
    check_success($msg);
    isa_ok($song, 'Audio::MPD::Common::Item::Song', 'current() return');
}

sub check_song {
    my ($msg, $song) = @_;
    check_success($msg);
    isa_ok($song,   'Audio::MPD::Common::Item::Song', 'song(id) return' );
    is($song->file, 'dir1/title-artist-album.ogg',    'song(id) returns the wanted song');
}

sub check_song_current {
    my ($msg, $song) = @_;
    check_success($msg);
    isa_ok($song,   'Audio::MPD::Common::Item::Song', 'song(id) return' );
    is($song->file, 'title.ogg',                      'song(id) defaults to current song' );
}
