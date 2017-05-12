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

use List::AllUtils qw{ any };
use POE;
use POE::Component::Client::MPD;
use POE::Component::Client::MPD::Test;
use Test::More;

# are we able to test module?
eval 'use Test::Corpus::Audio::MPD';
plan skip_all => $@ if $@ =~ s/\n+Compilation failed.*//s;
plan tests => 12;

# launch fake mpd
POE::Component::Client::MPD->spawn;

# launch the tests
POE::Component::Client::MPD::Test->new( { tests => [
    # [ 'event', [ $arg1, $arg2, ... ], $sleep, \&check_results ]

    # all_albums
    [ 'coll.all_albums',  [], 0, \&check_all_albums  ],

    # all_artists
    [ 'coll.all_artists', [], 0, \&check_all_artists ],

    # all_titles
    [ 'coll.all_titles',  [], 0, \&check_all_titles  ],

    # all_files
    [ 'coll.all_files',   [], 0, \&check_all_files   ],
] } );
POE::Kernel->run;
exit;

#--

sub check_success {
    my ($msg) = @_;
    is($msg->status, 1, "command '" . $msg->request . "' returned an ok status");
}

sub check_all_albums {
    my ($msg, $items) = @_;
    check_success($msg);
    # mpd 0.14 returns empty strings too
    is(scalar @$items, 2, 'all_albums() return the albums');
    is($items->[1], 'our album', 'all_albums() return strings');
}

sub check_all_artists {
    my ($msg, $items) = @_;
    check_success($msg);
    # mpd 0.14 returns empty strings too
    is(scalar @$items, 2, 'all_artists() return the artists');
    ok( any { $_ eq 'dir1-artist' } @$items, 'all_artists() return strings');
}

sub check_all_titles {
    my ($msg, $items) = @_;
    check_success($msg);
    # mpd 0.14 returns empty strings too
    is(scalar @$items, 4, 'all_titles() return the titles');
    ok( any { /-title$/ } @$items, 'all_titles() return strings');
}


sub check_all_files {
    my ($msg, $items) = @_;
    check_success($msg);
    is(scalar @$items, 5, 'all_files() return the pathes');
    like($items->[0], qr/\.ogg$/, 'all_files() return strings');
}
