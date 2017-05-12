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
plan skip_all=>$@ if $@ =~ s/\n+BEGIN failed--compilation aborted.*//s;
plan tests => 20;

# launch fake mpd
POE::Component::Client::MPD->spawn;

# launch the tests
my @songs   = qw{ title.ogg dir1/title-artist-album.ogg dir1/title-artist.ogg };
POE::Component::Client::MPD::Test->new( { tests => [
    # [ 'event', [ $arg1, $arg2, ... ], $sleep, \&check_results ]

    # volume
    [ 'volume', [10], 0,  \&check_success                  ],  # init to sthg we know
    [ 'volume', [4],  0,  \&check_success                  ],
    [ 'status', [],   0,  \&check_volume_absolute          ],

    [ 'volume', ['+5'], 1, \&check_success                 ],
    [ 'status', [],     0, \&check_volume_relative_pos     ],

    [ 'volume', ['-4'], 1, \&check_success                 ],
    [ 'status', [],     0, \&check_volume_relative_neg     ],

    # output_disable.
    [ 'pl.add',         \@songs, 0, \&check_success        ],
    [ 'play',           [],      0, \&check_success        ],
    [ 'output_disable', [0],     1, \&check_success        ],
    [ 'status',         [],      0, \&check_output_disable ],

    # enable_output.
    [ 'output_enable',  [0],     1, \&check_success        ],
    [ 'play',           [],      0, \&check_success        ],
    [ 'pause',          [],      0, \&check_success        ],
    [ 'status',         [],      0, \&check_output_enable  ],
] } );
POE::Kernel->run;
exit;

#--

sub check_success {
    my ($msg) = @_;
    is($msg->status, 1, "command '" . $msg->request . "' returned an ok status");
}

sub check_volume_absolute {
    my ($msg, $status) = @_;
    check_success($msg);
    is($status->volume, 4, 'setting volume');
}

sub check_volume_relative_pos {
    my ($msg, $status) = @_;
    check_success($msg);
    is($status->volume, 9, 'increasing volume');
}

sub check_volume_relative_neg {
    my ($msg, $status) = @_;
    check_success($msg);
    is($status->volume, 5, 'decreasing volume');
}

sub check_output_disable {
    my ($msg, $status) = @_;
    check_success($msg);
    SKIP: {
        skip "detection method doesn't always work - depends on timing", 1;
        like($status->error, qr/^problems/, 'disabling output' );
    }
}

sub check_output_enable {
    my ($msg, $status) = @_;
    check_success($msg);
    is($status->error, undef, 'enabling output' );
}
