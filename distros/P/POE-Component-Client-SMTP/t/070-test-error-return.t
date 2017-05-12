#!/usr/bin/env perl
use strict;
use warnings;

# Copyright (c) 2006 - 2009 George Nistorica
# All rights reserved.
# This file is part of POE::Component::Client::SMTP
# POE::Component::Client::SMTP is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# 	$Id: 070-test-error-return.t,v 1.5 2009/09/02 08:23:37 UltraDM Exp $

use lib q{../lib};
use Test::More;    # including use_ok
use Data::Dumper;
use Socket;
use Carp;
use POE;
use POE::Component::Client::SMTP;

eval { require POE::Component::Server::TCP; };
if ($@) {
    plan skip_all => q{POE::Component::Server::TCP is not installed};
}
else {
    plan tests => 1;
}

my $test = q{undef};

my $smtp_message;
my @recipients;
my $from;
my $debug = 0;

$smtp_message = create_smtp_message();
my $recipient = q{george@localhost};
$from = q{george@localhost};

##### SMTP server vars
my $port                  = 25252;
my $EOL                   = qq{\015\012};
my @smtp_server_responses = (
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

POE::Component::Server::TCP->new(
    q{Port}                  => $port,
    q{Address}               => q{localhost},
    q{Domain}                => AF_INET,
    q{Alias}                 => q{smtp_server},
    q{Error}                 => \&error_handler,               # Optional.
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

POE::Session->create(
    q{inline_states} => {
        q{_start}             => \&start_session,
        q{_stop}              => \&stop_session,
        q{send_mail}          => \&spawn_pococlsmt,
        q{pococlsmtp_success} => \&smtp_send_success,
        q{pococlsmtp_failure} => \&smtp_send_failure,
    },
);

POE::Kernel->run();

is( $test, 1, q{Wheel::SocketFactory Error} );

sub start_session {
    $_[KERNEL]->yield(q{send_mail});
}

sub spawn_pococlsmt {
    POE::Component::Client::SMTP->send(
        q{From}         => $from,
        q{To}           => \@recipients,
        q{SMTP_Success} => q{pococlsmtp_success},
        q{SMTP_Failure} => q{pococlsmtp_failure},
        q{Server}       => q{localhost},
        q{Port}    => ( $port + 1 ),  # this should make the component to try to
                                      # connect to the wrong port
        q{Body}    => $smtp_message,
        q{Context} => q{test context},
    );
}

sub stop_session {

    # stop server
    $_[KERNEL]->call( q{smtp_server} => q{shutdown} );
}

sub smtp_send_success {
    my ( $arg0, $arg1 ) = @_[ ARG0, ARG1 ];
    print q{ARG0, }, Dumper($arg0), qq{\nARG1, }, Dumper($arg1) if $debug;
    $test = 0;
    diag(q{Sending email unexpectedly succeeded!});
}

sub smtp_send_failure {
    my ( $arg0, $arg1 ) = @_[ ARG0, ARG1 ];
    print q{ARG0, }, Dumper($arg0), qq{\nARG1, }, Dumper($arg1) if $debug;
    if ( ref( $arg1->{q{POE::Wheel::SocketFactory}} ) eq q{ARRAY} ) {
        $test = 1;
    }
    else {
        $test = 0;
    }
}

sub create_smtp_message {
    my $body = <<EOB;
To: George Nistorica <george\@localhost>
From: Charlie Root <george\@localhost>
Subject: Email test

Sent with $POE::Component::Client::SMTP::VERSION
EOB

    return $body;
}

sub error_handler {
    my ( $syscall_name, $error_number, $error_string ) = @_[ ARG0, ARG1, ARG2 ];
    die qq{SYSCALL: $syscall_name, ERRNO: $error_number, ERRSTR: $error_string};
}

sub handle_client_input {
    my ( $kernel, $heap, $input ) = @_[ KERNEL, HEAP, ARG0 ];

    if ( $input =~ /^(helo|ehlo|mail from:|rcpt to:|data|\.|quit)/io ) {
        print qq{$input\n} if $debug;
        $heap->{q{client}}->put( shift @smtp_server_responses );
    }
}

sub handle_client_connect {
    $_[HEAP]->{q{client}}->put( shift @smtp_server_responses );
}

sub handle_client_disconnect {
}

sub handle_client_error {
}

sub handle_client_flush {
}

