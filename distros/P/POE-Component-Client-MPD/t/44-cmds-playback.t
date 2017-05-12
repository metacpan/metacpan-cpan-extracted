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
plan tests => 63;

# launch fake mpd
POE::Component::Client::MPD->spawn;

# launch the tests
my @songs   = qw{
    title.ogg dir1/title-artist-album.ogg
    dir1/title-artist.ogg dir2/album.ogg
};
POE::Component::Client::MPD::Test->new( { tests => [
    # [ 'event', [ $arg1, $arg2, ... ], $sleep, \&check_results ]

    #[ $PLAYLIST, 'pl.clear', [],      0, &check_success          ],
    [ 'pl.add',   \@songs, 0, \&check_success ],

    # play
    [ 'play',     [],      0, \&check_success ],
    [ 'status',   [],      0, \&check_play1   ],
    [ 'play',     [2],     0, \&check_success ],
    [ 'status',   [],      0, \&check_play2   ],

    # playid
    [ 'play',     [0],     0, \&check_success ],
    [ 'pause',    [],      0, \&check_success ],
    [ 'playid',   [],      0, \&check_success ],
    [ 'status',   [],      0, \&check_playid1 ],
    [ 'playid',   [1],     0, \&check_success ],
    [ 'status',   [],      0, \&check_playid2 ],

    # pause
    [ 'pause',    [1],     0, \&check_success ],
    [ 'status',   [],      0, \&check_pause1  ],
    [ 'pause',    [0],     0, \&check_success ],
    [ 'status',   [],      0, \&check_pause2  ],
    [ 'pause',    [],      0, \&check_success ],
    [ 'status',   [],      0, \&check_pause3  ],
    [ 'pause',    [],      0, \&check_success ],
    [ 'status',   [],      0, \&check_pause4  ],

    # stop
    [ 'stop',     [],      0, \&check_success ],
    [ 'status',   [],      0, \&check_stop    ],

    # prev / next
    [ 'play',     [1],     0, \&check_success ],
    [ 'pause',    [],      0, \&check_success ],
    [ 'next',     [],      0, \&check_success ],
    [ 'status',   [],      0, \&check_prev    ],
    [ 'prev',     [],      0, \&check_success ],
    [ 'status',   [],      0, \&check_next    ],

    # seek
    [ 'seek',     [1,2],   0, \&check_success ],
    [ 'pause',    [1],     1, \&check_success ],
    [ 'status',   [],      0, \&check_seek1   ],
    [ 'seek',     [],      0, \&check_success ],
    [ 'pause',    [1],     1, \&check_success ],
    [ 'status',   [],      0, \&check_seek2   ],
    [ 'seek',     [1],     0, \&check_success ],
    [ 'pause',    [1],     1, \&check_success ],
    [ 'status',   [],      0, \&check_seek3   ],

    # seekid
    [ 'seekid',   [1,1],   0, \&check_success ],
    [ 'status',   [],      0, \&check_seekid1 ],
    [ 'seekid',   [],      0, \&check_success ],
    [ 'pause',    [1],     1, \&check_success ],
    [ 'status',   [],      0, \&check_seekid2 ],
    [ 'seekid',   [1],     0, \&check_success ],
    [ 'pause',    [1],     1, \&check_success ],
    [ 'status',   [],      0, \&check_seekid3 ],
] } );
POE::Kernel->run;
exit;

#--

sub check_success {
    my ($msg) = @_;
    is($msg->status, 1, "command '" . $msg->request . "' returned an ok status");
}

sub check_play1   {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        is($_[1]->state,  'play',  'play() starts playback');
    }
}
sub check_play2   {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        is($_[1]->song,   2,       'play() can start playback at a given song');
    }
}
sub check_playid1 {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        is($_[1]->state,  'play',  'playid() starts playback');
    }
}
sub check_playid2 {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        is($_[1]->songid, 1,       'playid() can start playback at a given song');
    }
}
sub check_pause1  {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        is($status->state,  'pause', 'pause() forces playback pause');
    }
}
sub check_pause2  {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        is($status->state,  'play',  'pause() forces playback resume');
    }
}
sub check_pause3  {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        is($status->state,  'pause', 'pause() toggles to pause');
    }
}
sub check_pause4  {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        is($status->state,  'play',  'pause() toggles to play');
    }
}
sub check_stop    { check_success($_[0]); is($_[1]->state,  'stop',  'stop() forces full stop'); }
sub check_prev    { check_success($_[0]); is($_[1]->song,   2,       'next() changes track to next one'); }
sub check_next    { check_success($_[0]); is($_[1]->song,   1,       'prev() changes track to previous one'); }
sub check_seek1 {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 2;
        is($status->song, 2, 'seek() can change the current track');
        is($status->time->sofar_secs, 1, 'seek() seeks in the song');
    }
}
sub check_seek2 {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        is($_[1]->time->sofar_secs, 0, 'seek() defaults to beginning of song');
    }
}
sub check_seek3 {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        is($_[1]->time->sofar_secs, 1, 'seek() defaults to current song ');
    }
}
sub check_seekid1 {
    my ($msg, $status) = @_;
    check_success($msg);
    is($status->songid, 1, 'seekid() can change the current track');
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        is($status->time->sofar_secs, 1, 'seekid() seeks in the song');
    }
}
sub check_seekid2 {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        is($_[1]->time->sofar_secs, 0, 'seekid() defaults to beginning of song');
    }
}
sub check_seekid3 {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        is($_[1]->time->sofar_secs, 1, 'seekid() defaults to current song');
    }
}
