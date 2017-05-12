#!/usr/bin/env perl

# Copyright (c) 2005-2009 George Nistorica
# All rights reserved.
# This file is part of POE::Component::Client::SMTP
# POE::Component::Client::SMTP is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# 	$Id: 025-timeout.t,v 1.1 2009/09/02 08:20:44 UltraDM Exp $

use strict;
use warnings;

use lib q{./lib};
use Test::More tests => 6;    # including use_ok

BEGIN { use_ok(q{IO::Socket::INET}); }
BEGIN { use_ok(q{POE}); }
BEGIN { use_ok(q{POE::Wheel::ListenAccept}); }
BEGIN { use_ok(q{POE::Component::Server::TCP}); }
BEGIN { use_ok(q{POE::Component::Client::SMTP}); }

my $smtp_port    = q{2525};
my $smtp_timeout = 3;

# Create the server session

POE::Component::Server::TCP->new(
    q{Alias}                 => q{TCP_Server},
    q{Port}                  => $smtp_port,
    q{Address}               => q{localhost},
    q{Domain}                => AF_INET,
    q{Error}                 => \&error_handler,
    q{ClientInput}           => \&handle_client_input,         # Required.
    q{ClientConnected}       => \&handle_client_connect,       # Optional.
    q{ClientDisconnected}    => \&handle_client_disconnect,    # Optional.
    q{ClientError}           => \&handle_client_error,         # Optional.
    q{ClientFlushed}         => \&handle_client_flush,         # Optional.
    q{ClientFilter}          => q{POE::Filter::Line},          # Optional.
    q{ClientInputFilter}     => q{POE::Filter::Line},          # Optional.
    q{ClientOutputFilter}    => q{POE::Filter::Line},          # Optional.
    q{ClientShutdownOnError} => 1,                             #
);

# Create the test session

POE::Session->create(
    q{package_states} => [
        q{main} => [
            q{_start},           q{_stop},
            q{spawn_pococlsmtp}, q{pococlsmtp_success},
            q{pococlsmtp_failure},
        ],
    ],
);
POE::Kernel->run();

exit 0;

# POE Session and SMTP handlers

sub _start {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    $kernel->alias_set(q{Main_Session});
    $kernel->yield(q{spawn_pococlsmtp});
    return;
}

sub _stop {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    return;
}

sub spawn_pococlsmtp {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    # Create the pococlsmtp session
    POE::Component::Client::SMTP->send(
        q{From}         => q{george@localhost},
        q{To}           => q{george@localhost},
        q{SMTP_Success} => q{pococlsmtp_success},
        q{SMTP_Failure} => q{pococlsmtp_failure},
        q{Server}       => q{localhost},
        q{Port}         => $smtp_port,
        q{Body}         => q{test},
        q{Timeout}      => $smtp_timeout,
        q{Alias}        => q{pococlsmtp_alias},

        #        q{Debug}        => 1,
    );
}

sub pococlsmtp_success {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    my ( $context, $smtp_transaction_log ) = @_[ ARG0, ARG1 ];
    fail(q{SMTP timeout after socket created - Got SMTP success});
    $kernel->call( q{TCP_Server}, q{shutdown} );
    return;
}

sub pococlsmtp_failure {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    my ( $context, $error_hash, $smtp_transaction_log, $friendly_message ) =
      @_[ ARG0, ARG1, ARG2, ARG3 ];

    if ( exists $error_hash->{'Timeout'} ) {
        is( $error_hash->{'Timeout'},
            $smtp_timeout, q{SMTP timeout after socket created} );
    }
    else {
        fail(q{SMTP timeout after socket created - Got another error});
        diag( q{Error: } . $friendly_message );
    }

    $kernel->call( q{TCP_Server}, q{shutdown} );
    return;
}

# Server handlers

sub error_handler {
    my ( $syscall_name, $error_number, $error_string ) = @_[ ARG0, ARG1, ARG2 ];
    die qq{SYSCALL: $syscall_name, ERRNO: $error_number, ERRSTR: $error_string};
}

sub handle_client_input {
    die q{Test failed miserably, we should not get any client input!};
}

sub handle_client_connect {

    # do nothing;
}

sub handle_client_disconnect {
}

sub handle_client_error {
}

sub handle_client_flush {
}
