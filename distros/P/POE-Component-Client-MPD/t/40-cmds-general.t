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
plan tests => 10;

# launch fake mpd
POE::Component::Client::MPD->spawn;

# launch the tests
POE::Component::Client::MPD::Test->new( { tests => [
    # [ 'event', [ $arg1, $arg2, ... ], $sleep, \&check_results ]

    # updatedb
    [ 'updatedb',    [],       1, \&check_success     ],
    [ 'stats',       [],       0, \&check_update      ],
    [ 'updatedb',    ['dir1'], 0, \&check_success     ],
    [ 'stats',       [],       0, \&check_update      ],

    # version
    # needs to be *after* updatedb, so version messages can be treated
    # by socket.
    [ 'version',     [],       0, \&check_version     ],

    # urlhandlers
    [ 'urlhandlers', [],       0, \&check_urlhandlers ],
] } );
POE::Kernel->run;
exit;

#--

sub check_success {
    my ($msg) = @_;
    is($msg->status, 1, "command '" . $msg->request . "' returned an ok status");
}

sub check_update  {
    my ($msg, $stats) = @_;
    check_success($msg);
    isnt( $stats->db_update,  0, 'database has been updated' );
}

sub check_urlhandlers {
    my ($msg, $handlers) = @_;
    check_success($msg);
    ok( scalar @$handlers >= 1, 'at least one url handler supported' );
}

sub check_version {
    my ($msg, $vers) = @_;
    SKIP: {
        my $output = qx{echo | nc -w1 localhost 6600 2>/dev/null};
        skip 'need netcat installed', 2 unless $output =~ /^OK .* ([\d.]+)\n/;
        check_success($msg);
        is($vers, $1, 'mpd version grabbed during connection is correct');
    }
}

