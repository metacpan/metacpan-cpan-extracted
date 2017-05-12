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
plan tests => 23;

# launch fake mpd
POE::Component::Client::MPD->spawn;

# launch the tests
my @songs   = qw{
    title.ogg dir1/title-artist-album.ogg
    dir1/title-artist.ogg dir2/album.ogg
};
POE::Component::Client::MPD::Test->new( { tests => [
    # [ 'event', [ $arg1, $arg2, ... ], $sleep, \&check_results ]

    # delete / deleteid
    # should come first to be sure songid #0 is really here.
    [ 'pl.clear',              [], 0, \&check_success ],
    [ 'pl.add',           \@songs, 0, \&check_success ],
    [ 'status',                [], 0, \&get_nb        ],
    [ 'pl.delete',          [1,2], 0, \&check_success ],
    [ 'status',                [], 0, \&check_del     ],
    [ 'status',                [], 0, \&get_nb        ],
    [ 'pl.deleteid',          [1], 0, \&check_success ],
    [ 'status',                [], 0, \&check_delid   ],

    # add
    [ 'pl.clear',              [], 0, \&check_success ],
    [ 'status',                [], 0, \&get_nb        ],
    [ 'pl.add',   [ 'title.ogg' ], 0, \&check_success ],
    [ 'pl.add',           \@songs, 0, \&check_success ],
    [ 'status',                [], 0, \&check_add     ],

    # clear
    [ 'pl.add',           \@songs, 0, \&check_success ],
    [ 'pl.clear',              [], 0, \&check_success ],
    [ 'status',                [], 0, \&check_clear   ],

    # crop
    [ 'pl.add',           \@songs, 0, \&check_success ],
    [ 'play',                 [1], 0, \&check_success ], # to set song
    [ 'stop',                  [], 0, \&check_success ],
    # test hangs - dunno why
    #[ 'pl.crop',               [], 1, \&check_success ],
    #[ 'status',                [], 0, \&check_crop    ],
] } );
POE::Kernel->run;
exit;

#--

my $nb;

sub check_success {
    my ($msg) = @_;
    is($msg->status, 1, "command '" . $msg->request . "' returned an ok status");
}

sub get_nb      { check_success($_[0]); $nb = $_[1]->playlistlength }
sub check_add   { check_success($_[0]); is($_[1]->playlistlength, $nb+5, 'add() songs'); }
sub check_del   { check_success($_[0]); is($_[1]->playlistlength, $nb-2, 'delete() songs'); }
sub check_delid { check_success($_[0]); is($_[1]->playlistlength, $nb-1, 'deleteid() songs'); }
sub check_clear { check_success($_[0]); is($_[1]->playlistlength, 0, 'clear() leaves 0 song'); }
sub check_crop  { check_success($_[0]); is($_[1]->playlistlength, 1, 'crop() leaves only 1 song'); }
