#!/bin/env perl
use strict;
use warnings;

# Copyright (c) 2005 - 2009 George Nistorica
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# The program tests the scenarios when the SMTP server drops the
# connection or answers something while data is being transmited by
# the component

# Scenarios:
# TODO: server closes connection during DATA transmitting
# TODO: server sends a SMTP response during DATA transmitting

use lib q{lib};
use Test::More;
eval { require POE::Component::Server::TCP; };
if ($@) {
    plan skip_all => q{POE::Component::Server::TCP is not installed};
}
else {
    plan tests => 1;
}
use Data::Dumper;
use Carp;
use Socket;
use POE;
use POE::Filter::Line;
use POE::Component::Client::SMTP;

my $DEBUG = 0;

my $test = {
    q{check_one_failure_event}   => undef,
    q{check_one_success_event}   => undef,
    q{check_server_closed_is_ok} => undef,
};

my $config = {
    q{smtp_port} => 25252,
    q{smtp_host} => q{localhost},
};

diag( q{Using POE::Component::Client::SMTP version: }
      . $POE::Component::Client::SMTP::VERSION );

POE::Session->create(
    q{package_states} => [
        q{main} => [
            q{_start},            q{_stop},
            q{start_smtp_server}, q{smtp_success_event},
            q{smtp_failure_event},
        ],
    ],
    q{heap} => $config,
);

POE::Kernel->run();

is( $test->{'check_one_success_event'}, 1, q{Just one Success Event received} );

exit 0;

sub _start {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    $kernel->alias_set(q{Main_Session});
    $kernel->yield(q{start_smtp_server});

    return;
}

sub _stop {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    return;
}

sub start_smtp_server {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    # start smtp server
    $heap->{'server_id'} = POE::Component::Server::TCP->new(
        q{Address}               => $heap->{'smtp_host'},
        q{Port}                  => $heap->{'smtp_port'},
        q{Alias}                 => q{SMTP_Server},
        q{ClientConnected}       => \&client_connected,
        q{ClientDisconnected}    => \&client_disconnected,
        q{ClientError}           => \&client_error,
        q{ClientFilter}          => POE::Filter::Line->new(),
        q{ClientInput}           => \&client_input,
        q{ClientShutdownOnError} => 1,
        q{Domain}                => AF_INET,
        q{Error}                 => \&smtp_server_error,
        q{Concurrency}           => 1,
    );
    POE::Component::Client::SMTP->send(
        q{From}         => q{george@localhost},
        q{To}           => q{george@localhost},
        q{MessageFile}  => q{t/email_message_dot_test.txt},
        q{Server}       => $heap->{'smtp_host'},
        q{Port}         => $heap->{'smtp_port'},
        q{Alias}        => q{SMTP_Client},
        q{SMTP_Success} => q{smtp_success_event},
        q{SMTP_Failure} => q{smtp_failure_event},

        # keep the transaction log, to inspect when debugging.
        q{TransactionLog} => 1,
    );
}

sub client_connected {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    warn q{client_connected} if $DEBUG;
    $heap->{'client'}->put(q{250});
}

sub client_disconnected {
    warn q{client_disconnected} if $DEBUG;
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    # SMTP client has disconnected, shutting down the TCP server
    $kernel->post( q{SMTP_Server}, q{shutdown} );
    return;
}

sub client_error {
    warn q{client_error}                                      if $DEBUG;
    warn q{Most likely an 'client_disconnected' will follow'} if $DEBUG;
}

sub client_input {
    warn q{client_input} if $DEBUG;
    my ( $kernel, $heap, $input ) = @_[ KERNEL, HEAP, ARG0 ];
    warn qq{INPUT: "$input"} if ( $DEBUG > 1 );
    if ( $input =~ /DATA/o ) {

        # client will send DATA,
    }

    # sending responses during the DATA transmission. The TCP server
    # should be quiet while getting DATA from the client.
    warn qq{Going to send: "250"} if $DEBUG > 1;
    $heap->{'client'}->put(q{250});

}

sub smtp_server_error {
    warn q{smtp_server_error} if $DEBUG;
}

sub smtp_success_event {
    warn q{smtp_success_event} if $DEBUG;
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    # check to see if there's only one success event emitted by the
    # PoCo
    if ( not defined $test->{'check_one_success_event'} ) {
        $test->{'check_one_success_event'} = 1;
    }
    elsif ( defined $test->{'check_one_success_event'}
        and $test->{'check_one_success_event'} )
    {
        $test->{'check_one_success_event'} = 0;
    }

    # display the transaction log?
    if ( $DEBUG > 1 ) {
	print q{Transaction log: '} . Dumper( $_[ARG1] ) . q{'};
    }

    return;
}

sub smtp_failure_event {
    warn q{smtp_failure_event} if $DEBUG;
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    return;
}
