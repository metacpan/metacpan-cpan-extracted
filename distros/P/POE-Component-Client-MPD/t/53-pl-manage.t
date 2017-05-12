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

plan tests => 11;

# launch fake mpd
POE::Component::Client::MPD->spawn;

# launch the tests
POE::Component::Client::MPD::Test->new( { tests => [
    # [ 'event', [ $arg1, $arg2, ... ], $sleep, \&check_results ]

    # load
    [ 'pl.clear',             [], 0, \&check_success ],
    [ 'pl.load',        ['test'], 0, \&check_success ],
    [ 'pl.as_items',          [], 0, \&check_load    ],

    # save
    [ 'pl.save',     ['test-jq'], 0, \&check_success ],
    [ 'status',               [], 0, \&check_save    ],

    # rm
    [ 'pl.rm',       ['test-jq'], 0, \&check_success ],
    [ 'status',               [], 0, \&check_rm      ],
] } );
POE::Kernel->run;
exit;

#--

sub check_success {
    my ($msg) = @_;
    is($msg->status, 1, "command '" . $msg->request . "' returned an ok status");
}

sub check_load {
    my ($msg, $items) = @_;
    check_success($msg);
    is(scalar @$items, 1, 'pl.load() adds songs');
    is($items->[0]->title, 'ok-title', 'pl.load() adds the correct songs');
}

sub check_save {
    my ($msg, $status) = @_;
    check_success($msg);
    my $pdir = playlist_dir();
    ok(-f "$pdir/test-jq.m3u", 'pl.save() creates a playlist');
}

sub check_rm {
    my ($msg, $status) = @_;
    check_success($msg);
    my $pdir = playlist_dir();
    ok(! -f "$pdir/test-jq.m3u", 'rm() removes a playlist');
}
