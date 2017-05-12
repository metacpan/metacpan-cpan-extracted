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
plan tests => 14;

# launch fake mpd
POE::Component::Client::MPD->spawn;

# launch the tests
my @songs   = qw{
    title.ogg dir1/title-artist-album.ogg
    dir1/title-artist.ogg dir2/album.ogg
};
POE::Component::Client::MPD::Test->new( { tests => [
    # [ 'event', [ $arg1, $arg2, ... ], $sleep, \&check_results ]

    [ 'pl.clear',                [], 0, \&check_success       ],
    [ 'pl.add',             \@songs, 0, \&check_success       ],

    # pl.as_items
    [ 'pl.as_items',             [], 0, \&check_as_items      ],

    # pl.items_changed_since
    [ 'pl.items_changed_since', [0], 0, \&check_items_changed ],

] } );
POE::Kernel->run;
exit;

#--

sub check_success {
    my ($msg) = @_;
    is($msg->status, 1, "command '" . $msg->request . "' returned an ok status");
}

sub check_as_items {
    my ($msg, $items) = @_;
    check_success($msg);
    isa_ok($_, 'Audio::MPD::Common::Item::Song', 'pl.as_items() return') for @$items;
    is($items->[0]->title, 'ok-title', 'first song reported first');
}

sub check_items_changed {
    my ($msg, $items) = @_;
    check_success($msg);
    isa_ok($_, 'Audio::MPD::Common::Item::Song', 'items_changed_since() return') for @$items;
    is($items->[0]->title, 'ok-title', 'first song reported first');
}
