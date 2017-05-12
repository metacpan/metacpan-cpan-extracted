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
plan tests => 20;

# launch fake mpd
POE::Component::Client::MPD->spawn;

# launch the tests
my @songs   = qw{
    title.ogg dir1/title-artist-album.ogg
    dir1/title-artist.ogg dir2/album.ogg
};
POE::Component::Client::MPD::Test->new( { tests => [

    # [ 'event', [ $arg1, $arg2, ... ], $sleep, \&check_results ]

    # pl.swapid
    # test should come first to know the song id
    [ 'pl.clear',         [], 0, \&check_success ],
    [ 'pl.add',      \@songs, 0, \&check_success ],
    [ 'pl.swapid',     [1,3], 0, \&check_success ],
    [ 'pl.as_items',      [], 0, \&check_2ndpos  ],
    [ 'pl.swapid',     [1,3], 0, \&check_success ],

    # pl.moveid
    # test should come second to know the song id
    [ 'pl.moveid',     [1,2], 0, \&check_success ],
    [ 'pl.as_items',      [], 0, \&check_2ndpos  ],
    [ 'pl.moveid',     [1,0], 0, \&check_success ],

    # pl.swap
    [ 'pl.swap',       [0,2], 0, \&check_success ],
    [ 'pl.as_items',      [], 0, \&check_2ndpos  ],
    [ 'pl.swap',       [0,2], 0, \&check_success ],

    # pl.move
    [ 'pl.move',       [0,2], 0, \&check_success ],
    [ 'pl.as_items',      [], 0, \&check_2ndpos  ],

    # pl.shuffle
    [ 'status',           [], 0, \&get_plvers    ],
    [ 'pl.shuffle',       [], 0, \&check_success ],
    [ 'status',           [], 0, \&check_shuffle ],
] } );
POE::Kernel->run;
exit;

#--

my $plvers;

sub get_plvers { $plvers=$_[1]->playlist; }

sub check_success {
    my ($msg) = @_;
    is($msg->status, 1, "command '" . $msg->request . "' returned an ok status");
}

sub check_shuffle {
    my ($msg, $status) = @_;
    check_success($msg);
    is($status->playlist, $plvers+1, 'shuffle() changes playlist version');
}

sub check_2ndpos {
    my ($msg, $items) = @_;
    check_success($msg);
    is($items->[2]->title, 'ok-title', 'swap[id()] / swap[id()] changes songs');
}
