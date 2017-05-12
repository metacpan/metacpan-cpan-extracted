#!/usr/bin/env perl
# Copyright (c) 2009 George Nistorica
# All rights reserved.
# This file is part of POE::Component::Client::SMTP
# POE::Component::Client::SMTP is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# The program tests whethet the PoCo correctly escapes a single dot
# found on a line in a message body when sending the email.

use strict;
use warnings;

use lib q{lib};

use Data::Dumper;
use Test::More tests => 1;

use POE;
use POE::Component::Server::TCP;
use POE::Component::Client::SMTP;

# print verbose messages
my $debug = 0;

# assume that test is successful
my $test_success = 1;

# Server didn't encountered the command "second line" which triggers
# the test
my $trigger = 0;

my $EOL            = qq{\015\012};
my @smtp_responses = (
    q{220 localhost ESMTP POE::Component::Client::SMTP Test Server},
    qq{250-localhost$EOL}
      . qq{250-PIPELINING$EOL}
      . qq{250-SIZE 250000000$EOL}
      . qq{250-VRFY$EOL}
      . qq{250-ETRN$EOL}
      . q{250 8BITMIME},
    q{250 Ok},                                 # mail from
    q{250 Ok},                                 # rcpt to:
    q{354 End data with <CR><LF>.<CR><LF>},    # data
    q{250 Ok: queued as 549B14484F},           # end data
    q{221 Bye},                                # quit

);

POE::Session->create(
    q{package_states} => [
        q{main} => [
            q{_start},            q{_stop},
            q{start_smtp_server}, q{start_smtp_client},
            q{success_event},     q{failure_event}
        ],
    ],
    q{heap} => {
        q{smtp_listen_port}    => q{31337},
        q{smtp_listen_address} => q{localhost},
        q{message_file}        => q{t/email_message_dot_test.txt},
    },
);

diag (q{Using POE::Component::Client::SMTP version: } . $POE::Component::Client::SMTP::VERSION );

POE::Kernel->run();
is( $test_success, 1, q{Single dot has been escaped from email file} );
exit 0;

sub _start {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    $kernel->alias_set(q{Main_Session});
    $kernel->yield(q{start_smtp_server});
    return 0;
}

sub _stop {
    return 0;
}

sub start_smtp_server {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    POE::Component::Server::TCP->new(
        q{Port}                  => $heap->{'smtp_listen_port'},
        q{Address}               => $heap->{'smtp_listen_address'},
        q{Alias}                 => q{SMTP_Server},
        q{Error}                 => \&error_handler,
        q{ClientInput}           => \&handle_client_input,
        q{ClientConnected}       => \&handle_client_connect,
        q{ClientDisconnected}    => \&handle_client_disconnect,
        q{ClientError}           => \&handle_client_error,
        q{ClientFlushed}         => \&handle_client_flush,
        q{ClientInputFilter}     => POE::Filter::Line->new(),
        q{ClientOutputFilter}    => POE::Filter::Line->new(),
        q{ClientShutdownOnError} => 1,
    );

    $kernel->yield(q{start_smtp_client});
    return 0;
}

# SMTP Server handlers

sub accept_handler {
    my ( $socket, $remote_address, $remote_port ) = @_[ ARG0, ARG1, ARG2 ];
    if ($debug) {
        diag(qq{$remote_address:$remote_port connected});
    }
}

sub error_handler {
    my ( $syscall_name, $error_number, $error_string ) = @_[ ARG0, ARG1, ARG2 ];
    diag(   q{Got an error: }
          . $syscall_name . q{:}
          . $error_number . q{:}
          . $error_string );
}

sub handle_client_input {
    my $heap         = $_[HEAP];
    my $input_record = $_[ARG0];
    if ($debug) {
        diag(qq{FROM CLIENT: "$input_record"});
    }
    if ( $input_record =~ /second\sline/io ) {
        $trigger = 1;
	diag ( q{Triggered, waiting for esacepd dot} ) if $debug;
    }
    else {
        if ( $trigger and $input_record =~ /^\.$/ ) {
            $test_success = 0;
        }
        if ($trigger) {
            $trigger = 0;
        }
    }

    # decide response to send back

    if (   $input_record =~ /^(helo|ehlo|mail from:|rcpt to:|data|quit)/io
        or $input_record =~ /^\.$/io )
    {
        my $response = shift @smtp_responses;
        if ($debug) {
            diag(qq{GOING TO SEND: "$response"});
        }
        $heap->{'client'}->put($response);
    }
    if ( $input_record =~ /quit/io ) {
        if ($debug) {
            diag( q{Shutting down status: } . $heap->{'shutdown'} );
        }
	# not really necessary
        $heap->{'shutdown'} = 1;
    }
}

sub handle_client_error {
    my ( $syscall_name, $error_number, $error_string ) = @_[ ARG0, ARG1, ARG2 ];
}

sub handle_client_connect {
    my $heap = $_[HEAP];
    $heap->{'client'}->put( shift @smtp_responses );
    return 0;
}

sub handle_client_disconnect {
}

sub handle_client_flush {
}

sub start_smtp_client {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    POE::Component::Client::SMTP->send(
        q{From}         => q{charlie@localhost},
        q{To}           => q{root@localhost},
        q{Server}       => $heap->{'smtp_listen_address'},
        q{Port}         => $heap->{'smtp_listen_port'},
        q{Timeout}      => 100,
        q{SMTP_Success} => q{success_event},
        q{SMTP_Failure} => q{failure_event},
        q{MessageFile}  => $heap->{'message_file'},
	q{TransactionLog} => 1,
    );
    return 0;
}

sub success_event {
    my ( $kernel, $arg0, $arg1 ) = @_[ KERNEL, ARG0, ARG1 ];
    diag ( q{Success event!}) if $debug;
    print Dumper($arg0) if $debug;
    print Dumper($arg1) if $debug;
    $kernel->post( q{SMTP_Server}, q{shutdown} );
    return 0;
}

sub failure_event {
    my ( $kernel, $arg0, $arg1 ) = @_[ KERNEL, ARG0, ARG1 ];
    diag( q{Failure event!} ) if $debug;
    print Dumper($arg0) if $debug;
    print Dumper($arg1) if $debug;
    $kernel->post( q{SMTP_Server}, q{shutdown} );
    return 0;
}

__END__
