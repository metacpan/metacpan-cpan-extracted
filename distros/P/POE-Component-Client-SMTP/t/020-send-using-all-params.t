#!/usr/bin/env perl

# Copyright (c) 2005-2009 George Nistorica
# All rights reserved.
# This file is part of POE::Component::Client::SMTP
# POE::Component::Client::SMTP is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# 	$Id: 020-send-using-all-params.t,v 1.7 2009/09/02 08:23:37 UltraDM Exp $

use strict;
use warnings;

use lib q{./lib};
use Test::More tests => 7;    # including use_ok
use Data::Dumper;
use Carp;

BEGIN { use_ok(q{IO::Socket::INET}); }
BEGIN { use_ok(q{POE}); }
BEGIN { use_ok(q{POE::Wheel::ListenAccept}); }
BEGIN { use_ok(q{POE::Component::Server::TCP}); }
BEGIN { use_ok(q{POE::Component::Client::SMTP}); }

my $test = q{undef};

my $smtp_message;
my @recipients;
my $from;
my $debug = 0;

$smtp_message = create_smtp_message();
@recipients   = qw(
  george@localhost
);
$from = q{george@localhost};
my $myhostname         = q{george};
my $poco_said_hostname = undef;

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
      . qq{250 8BITMIME},
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

is( $test,               1,           q{All Params} );
is( $poco_said_hostname, $myhostname, q{MyHostname} );
diag(q{All Params});

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
        q{Port}         => $port,
        q{Body}         => $smtp_message,
        q{Context}      => q{test context},
        q{Timeout}      => 20,
        q{MyHostname}   => $myhostname,             # to test
        q{Alias}        => q{poco_smtp_alias},
    );
}

sub stop_session {

    # stop server
    $_[KERNEL]->call( q{smtp_server} => q{shutdown} );
}

sub smtp_send_success {
    my ( $arg0, $arg1 ) = @_[ ARG0, ARG1 ];
    print q{ARG0, }, Dumper($arg0), qq{\nARG1, }, Dumper($arg1) if $debug;
    $test = 1;
}

sub smtp_send_failure {
    my ( $arg0, $arg1 ) = @_[ ARG0, ARG1 ];
    print q{ARG0, }, Dumper($arg0), qq{\nARG1, }, Dumper($arg1) if $debug;
    $test = 0;
}

sub create_smtp_message {
    my $body = <<EOB;
To: George Nistorica <george\@localhost>
Bcc: George Nistorica <george\@localhost>
CC: Alter Ego <root\@localhost>
From: Charlie Root <root\@localhost>
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
    my ( $heap, $input ) = @_[ HEAP, ARG0 ];

    if ( $input =~ /^(helo|ehlo|mail from:|rcpt to:|data|\.|quit)/io ) {
        if ( $input =~ /^(ehlo|helo)\s(.*)$/io ) {
            $poco_said_hostname = $2 if defined $2;
        }
        print qq{$input\n} if $debug;
        $heap->{'client'}->put( shift @smtp_server_responses );
    }
}

sub handle_client_connect {
    $_[HEAP]->{'client'}->put( shift @smtp_server_responses );
}

sub handle_client_disconnect {
}

sub handle_client_error {
}

sub handle_client_flush {
}

